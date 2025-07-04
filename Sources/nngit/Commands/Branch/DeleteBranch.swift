//
//  DeleteBranch.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    /// Command that allows selecting and deleting local branches.
    struct DeleteBranch: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Lists all available local branches, deletes the selected branches, and optionally prunes the remote origin."
        )

        @Flag(name: .long, help: "Prune 'origin' after deleting branches.")
        var pruneOrigin: Bool = false

        @Flag(name: .long, help: "Include branches from all authors when listing")
        var includeAll: Bool = false

        @Flag(name: .long, help: "Delete all merged branches without prompting")
        var allMerged: Bool = false

        @Option(name: .customLong("load-merge-status"),
                help: "Load merge status when listing branches (true/false)")
        var loadMergeStatus: Bool?

        @Option(name: .customLong("load-creation-date"),
                help: "Load branch creation date when listing branches (true/false)")
        var loadCreationDate: Bool?

        @Option(name: .customLong("load-sync-status"),
                help: "Load sync status when listing branches (true/false)")
        var loadSyncStatus: Bool?

        @Argument(help: "Name (or partial name) of the branch to delete")
        var search: String?

        @Option(name: .long, parsing: .upToNextOption,
                help: "Additional author names or emails to include when filtering branches")
        var includeAuthor: [String] = []
        
        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let configLoader = Nngit.makeConfigLoader()

            try shell.verifyLocalGitExists()

            let config = try configLoader.loadConfig(picker: picker)
            let branchLoader = Nngit.makeBranchLoader()
            var branchNames = try loadEligibleBranchNames(shell: shell, config: config)

            let loadMerge = loadMergeStatus ?? config.loadMergeStatusWhenLoadingBranches
            let loadCreation = loadCreationDate ?? config.loadCreationDateWhenLoadingBranches
            let loadSync = loadSyncStatus ?? config.loadSyncStatusWhenLoadingBranches

            if !includeAll {
                branchNames = branchLoader.filterBranchNamesByAuthor(branchNames, shell: shell, includeAuthor: includeAuthor)
            }

            if let search,
               !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                branchNames = branchLoader.filterBranchNamesBySearch(branchNames, search: search)
                guard !branchNames.isEmpty else {
                    print("No branches found matching '\(search)'")
                    return
                }
            }

            let eligibleBranches = try branchLoader.loadBranches(
                for: branchNames,
                shell: shell,
                mainBranchName: config.defaultBranch,
                loadMergeStatus: loadMerge,
                loadCreationDate: loadCreation,
                loadSyncStatus: loadSync
            )

            let branchesToDelete: [GitBranch]
            if allMerged {
                branchesToDelete = eligibleBranches.filter { $0.isMerged }
                if branchesToDelete.isEmpty {
                    print("No merged branches found")
                    return
                }
            } else {
                branchesToDelete = picker.multiSelection("Select which branches to delete", items: eligibleBranches)
            }
        
            for branch in branchesToDelete {
                if branch.isMerged {
                    try deleteBranch(branch, shell: shell)
                } else {
                    try picker.requiredPermission(
                        "This branch has NOT been merged into \(config.defaultBranch.yellow). Are you sure you want to delete it?"
                    )
                    try deleteBranch(branch, shell: shell, forced: true)
                }
                print("✅ Deleted branch: \(branch.name)")
            }
            
            if (pruneOrigin || config.pruneWhenDeletingBranches) && (try? shell.remoteExists(path: nil)) == true {
                let _ = try shell.runWithOutput(makeGitCommand(.pruneOrigin, path: nil))
            }
        }
    }
}

extension Nngit.DeleteBranch {
    /// Returns a list of branch names eligible for deletion.
    func loadEligibleBranchNames(shell: GitShell, config: GitConfig) throws -> [String] {
        let loader = Nngit.makeBranchLoader()
        return try loader.loadBranchNames(from: .local, shell: shell)
            .filter { name in
                let clean = name.hasPrefix("*") ? String(name.dropFirst(2)) : name
                return clean.lowercased() != config.defaultBranch.lowercased()
            }
    }

    /// Returns a list of branches eligible for deletion.
    func loadEligibleBranches(shell: GitShell, config: GitConfig) throws -> [GitBranch] {
        let names = try loadEligibleBranchNames(shell: shell, config: config)
        let loader = Nngit.makeBranchLoader()
        return try loader.loadBranches(
            for: names,
            shell: shell,
            mainBranchName: config.defaultBranch,
            loadMergeStatus: config.loadMergeStatusWhenLoadingBranches,
            loadCreationDate: config.loadCreationDateWhenLoadingBranches,
            loadSyncStatus: config.loadSyncStatusWhenLoadingBranches
        )
        .filter { !$0.isCurrentBranch }
    }

    /// Deletes the given branch using `git branch -d` or `-D` when forced.
    func deleteBranch(_ branch: GitBranch, shell: GitShell, forced: Bool = false) throws {
        let _ = try shell.runWithOutput(makeGitCommand(.deleteBranch(name: branch.name, forced: forced), path: nil))
    }
}
