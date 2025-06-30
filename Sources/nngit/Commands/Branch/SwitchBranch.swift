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

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            try shell.verifyLocalGitExists()
            let branchLoader = Nngit.makeBranchLoader()
            let branchList = try branchLoader.loadBranches(from: branchLocation, shell: shell)
            let currentBranch = branchList.first(where: { $0.isCurrentBranch })
            var availableBranches = branchList.filter({ !$0.isCurrentBranch})

            let userName = (try? shell.runWithOutput("git config user.name").trimmingCharacters(in: .whitespacesAndNewlines))
                .flatMap { $0.isEmpty ? nil : $0 }
                ?? (try? shell.runWithOutput("git config --global user.name").trimmingCharacters(in: .whitespacesAndNewlines))
                .flatMap { $0.isEmpty ? nil : $0 }

            let userEmail = (try? shell.runWithOutput("git config user.email").trimmingCharacters(in: .whitespacesAndNewlines))
                .flatMap { $0.isEmpty ? nil : $0 }
                ?? (try? shell.runWithOutput("git config --global user.email").trimmingCharacters(in: .whitespacesAndNewlines))
                .flatMap { $0.isEmpty ? nil : $0 }

            var allowedAuthors = Set(includeAuthor)
            if let userName { allowedAuthors.insert(userName) }
            if let userEmail { allowedAuthors.insert(userEmail) }

            if !allowedAuthors.isEmpty {
                availableBranches = availableBranches.filter { branch in
                    if let output = try? shell.runWithOutput("git log -1 --pretty=format:'%an,%ae' \(branch.name)") {
                        let parts = output.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ",")
                        guard parts.count == 2 else { return false }
                        let authorName = String(parts[0])
                        let authorEmail = String(parts[1])
                        return allowedAuthors.contains(authorName) || allowedAuthors.contains(authorEmail)
                    }
                    return false
                }
            }

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


// MARK: - Extension Dependencies
extension BranchLocation: ExpressibleByArgument { }
extension GitBranch: DisplayablePickerItem {
    var displayName: String {
        let mergeStatus = isMerged ? "merged" : "unmerged"
        let sync = syncStatus.rawValue
        return "\(name) (\(mergeStatus), \(sync))"
    }
}
