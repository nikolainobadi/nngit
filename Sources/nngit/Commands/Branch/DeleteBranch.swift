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
            var eligibleBranches = try loadEligibleBranches(shell: shell, config: config)
            if !includeAll {
                eligibleBranches = branchLoader.filterBranchesByAuthor(eligibleBranches, shell: shell, includeAuthor: includeAuthor)
            }

            if let search,
               !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                eligibleBranches = branchLoader.filterBranchesBySearch(eligibleBranches, search: search)
                guard !eligibleBranches.isEmpty else {
                    print("No branches found matching '\(search)'")
                    return
                }
            }

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
    /// Returns a list of branches eligible for deletion.
    func loadEligibleBranches(shell: GitShell, config: GitConfig) throws -> [GitBranch] {
        let loader = Nngit.makeBranchLoader()
        // Exclude the current branch and the default branch from deletion candidates
        return try loader.loadBranches(from: .local, shell: shell, mainBranchName: config.defaultBranch)
            .filter { branch in
                !branch.isCurrentBranch &&
                branch.name.lowercased() != config.defaultBranch.lowercased()
            }
    }

    /// Deletes the given branch using `git branch -d` or `-D` when forced.
    func deleteBranch(_ branch: GitBranch, shell: GitShell, forced: Bool = false) throws {
        let _ = try shell.runWithOutput(makeGitCommand(.deleteBranch(name: branch.name, forced: forced), path: nil))
    }
}
