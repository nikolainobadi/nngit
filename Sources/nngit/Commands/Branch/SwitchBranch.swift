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
    /// Command that helps switching between local or remote branches.
    struct SwitchBranch: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Lists branches from the specified location and allows selecting one to switch to."
        )

        @Argument(help: "Name (or partial name) of the branch to switch to")
        var search: String?

        @Option(name: .shortAndLong, help: "Where to search for branches: local, remote, or both")
        var branchLocation: BranchLocation = .local

        @Option(name: .long, parsing: .upToNextOption,
                help: "Additional author names or emails to include when filtering branches")
        var includeAuthor: [String] = []

        @Flag(name: .long, help: "Include branches from all authors when listing")
        var includeAll: Bool = false

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            try shell.verifyLocalGitExists()
            let branchLoader = Nngit.makeBranchLoader()
            let config = try Nngit.makeConfigLoader().loadConfig(picker: picker)
            var branchNames = try branchLoader.loadBranchNames(from: branchLocation, shell: shell)

            if !includeAll {
                branchNames = branchLoader.filterBranchNamesByAuthor(branchNames, shell: shell, includeAuthor: includeAuthor)
            }

            if let search,
               !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                branchNames = branchLoader.filterBranchNamesBySearch(branchNames, search: search)

                if branchNames.isEmpty {
                    print("No branches found matching '\(search)'")
                    return
                }
                if branchNames.contains(where: { $0 == search || $0 == "* " + search }) {
                    let exactName = branchNames.first(where: { $0 == search || $0 == "* " + search })!
                    let clean = exactName.hasPrefix("*") ? String(exactName.dropFirst(2)) : exactName
                    try shell.runGitCommandWithOutput(.switchBranch(branchName: clean), path: nil)
                    return
                }
            }

            let branchList = try branchLoader.loadBranches(
                for: branchNames,
                shell: shell,
                mainBranchName: config.defaultBranch,
                loadMergeStatus: config.loadMergeStatusWhenLoadingBranches,
                loadCreationDate: config.loadCreationDateWhenLoadingBranches,
                loadSyncStatus: config.loadSyncStatusWhenLoadingBranches
            )
            let currentBranch = branchList.first(where: { $0.isCurrentBranch })
            let availableBranches = branchList.filter { !$0.isCurrentBranch }

            var details = ""

            if let currentBranch {
                details = "(switching from \(currentBranch.name))"
            }

            let selectedBranch = try picker.requiredSingleSelection("Select a branch \(details)", items: availableBranches)

            try shell.runGitCommandWithOutput(.switchBranch(branchName: selectedBranch.name), path: nil)
        }
    }
}


// MARK: - Extension Dependencies
extension BranchLocation: ExpressibleByArgument { }
extension GitBranch: DisplayablePickerItem {
    var displayName: String {
        let mergeStatus = isMerged ? "merged" : "unmerged"
        let sync = syncStatus.rawValue
        return "\(name) (\(mergeStatus), \(sync))"
    }
}
