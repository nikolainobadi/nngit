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

        @Option(name: .customLong("load-merge-status"),
                help: "Load merge status when listing branches (true/false)")
        var loadMergeStatus: Bool?

        @Option(name: .customLong("load-creation-date"),
                help: "Load branch creation date when listing branches (true/false)")
        var loadCreationDate: Bool?

        @Option(name: .customLong("load-sync-status"),
                help: "Load sync status when listing branches (true/false)")
        var loadSyncStatus: Bool?

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            try shell.verifyLocalGitExists()
            let branchLoader = Nngit.makeBranchLoader()
            let config = try Nngit.makeConfigLoader().loadConfig(picker: picker)
            
            // First, check if we should use MyBranches for selection
            if shouldUseMyBranches(config: config) {
                try runWithMyBranches(shell: shell, picker: picker, config: config)
                return
            }
            
            var branchNames = try branchLoader.loadBranchNames(from: branchLocation, shell: shell)

            let loadMerge = loadMergeStatus ?? config.loading.loadMergeStatus
            let loadCreation = loadCreationDate ?? config.loading.loadCreationDate
            let loadSync = loadSyncStatus ?? config.loading.loadSyncStatus

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
                mainBranchName: config.branches.defaultBranch,
                loadMergeStatus: loadMerge,
                loadCreationDate: loadCreation,
                loadSyncStatus: loadSync
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
        
        /// Determines if MyBranches should be used for branch selection
        private func shouldUseMyBranches(config: GitConfig) -> Bool {
            // Use MyBranches when:
            // - No specific search term provided
            // - Using local branches only
            // - Not including all authors
            // - MyBranches array is not empty
            return search == nil && 
                   branchLocation == .local && 
                   !includeAll && 
                   !config.myBranches.isEmpty
        }
        
        /// Runs branch switching using MyBranches array
        private func runWithMyBranches(shell: GitShell, picker: Picker, config: GitConfig) throws {
            // Get current branch to exclude it from selection
            let currentBranchName = try shell.runWithOutput(makeGitCommand(.getCurrentBranchName, path: nil))
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Filter MyBranches to exclude current branch and verify they exist
            let branchLoader = Nngit.makeBranchLoader()
            let existingBranches = try branchLoader.loadBranchNames(from: .local, shell: shell)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "* ", with: "") }
            
            let availableMyBranches = config.myBranches.filter { myBranch in
                myBranch.name != currentBranchName && existingBranches.contains(myBranch.name)
            }
            
            if availableMyBranches.isEmpty {
                print("No tracked branches available to switch to.")
                return
            }
            
            let selectedBranch = try picker.requiredSingleSelection("Select a branch", items: availableMyBranches)
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
