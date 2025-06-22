//
//  SwitchBranch.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import Foundation
import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    struct SwitchBranch: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Lists all local branches, allows selecting a branch to switch."
        )

        @Argument(help: "Name (or partial name) of the branch to switch to")
        var search: String?

        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let branchLoader = GitBranchLoader(shell: shell)
            let branchList = try branchLoader.loadLocalBranches(shell: shell)
            let currentBranch = branchList.first(where: { $0.isCurrentBranch })
            var availableBranches = branchList.filter({ !$0.isCurrentBranch})

            if let search,
               !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                if let exact = availableBranches.first(where: { $0.name == search }) {
                    try shell.runGitCommandWithOutput(.switchBranch(branchName: exact.name), path: nil)
                    return
                }

                availableBranches = availableBranches.filter { $0.name.lowercased().contains(search.lowercased()) }

                guard !availableBranches.isEmpty else {
                    print("No branches found matching '\(search)'")
                    return
                }
            }

            var details = ""

            if let currentBranch {
                details = "(switching from \(currentBranch.name))"
            }

            let selectedBranch = try picker.requiredSingleSelection("Select a branch \(details)", items: availableBranches)

            try shell.runGitCommandWithOutput(.switchBranch(branchName: selectedBranch.name), path: nil)
        }
    }
}

extension GitBranch: DisplayablePickerItem {
    var displayName: String {
        return name
    }
}
