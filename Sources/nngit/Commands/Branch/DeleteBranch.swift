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
            abstract: "Lists all available local branches, deletes the selected branches, and prunes the remote origin."
        )

        @Flag(name: .long, help: "Delete all merged branches without prompting")
        var allMerged: Bool = false

        @Argument(help: "Name (or partial name) of the branch to delete")
        var search: String?
        
        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            try shell.verifyLocalGitExists()
            let branchLoader = Nngit.makeBranchLoader()
            let config = try Nngit.makeConfigLoader().loadConfig(picker: picker)
            
            var branchNames = try loadEligibleBranchNames(shell: shell, config: config)

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
                mainBranchName: config.branches.defaultBranch,
                loadMergeStatus: true,
                loadCreationDate: true,
                loadSyncStatus: true
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
        
            let _ = try deleteBranches(branchesToDelete, shell: shell, picker: picker, defaultBranch: config.branches.defaultBranch)
            
            if (try? shell.remoteExists(path: nil)) == true {
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
                return clean.lowercased() != config.branches.defaultBranch.lowercased()
            }
    }

    /// Returns a list of branches eligible for deletion.
    func loadEligibleBranches(shell: GitShell, config: GitConfig) throws -> [GitBranch] {
        let names = try loadEligibleBranchNames(shell: shell, config: config)
        let loader = Nngit.makeBranchLoader()
        return try loader.loadBranches(
            for: names,
            shell: shell,
            mainBranchName: config.branches.defaultBranch,
            loadMergeStatus: config.loading.loadMergeStatus,
            loadCreationDate: config.loading.loadCreationDate,
            loadSyncStatus: config.loading.loadSyncStatus
        )
        .filter { !$0.isCurrentBranch }
    }

    /// Deletes the given branch using `git branch -d` or `-D` when forced.
    func deleteBranch(_ branch: GitBranch, shell: GitShell, forced: Bool = false) throws {
        let _ = try shell.runWithOutput(makeGitCommand(.deleteBranch(name: branch.name, forced: forced), path: nil))
    }
    
    /// Deletes multiple branches and returns the names of successfully deleted branches.
    func deleteBranches(_ branches: [GitBranch], shell: GitShell, picker: CommandLinePicker, defaultBranch: String) throws -> [String] {
        var deletedBranchNames: [String] = []
        
        for branch in branches {
            if branch.isMerged {
                try deleteBranch(branch, shell: shell)
                deletedBranchNames.append(branch.name)
            } else {
                try picker.requiredPermission(
                    "This branch has NOT been merged into \(defaultBranch.yellow). Are you sure you want to delete it?"
                )
                try deleteBranch(branch, shell: shell, forced: true)
                deletedBranchNames.append(branch.name)
            }
            print("✅ Deleted branch: \(branch.name)")
        }
        
        return deletedBranchNames
    }
    
}
