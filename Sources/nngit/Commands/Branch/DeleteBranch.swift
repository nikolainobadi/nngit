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

            var config = try configLoader.loadConfig(picker: picker)
            
            // First, check if we should use MyBranches for selection
            if shouldUseMyBranches(config: config) {
                try runWithMyBranches(shell: shell, picker: picker, config: &config, configLoader: configLoader)
                return
            }
            
            let branchLoader = Nngit.makeBranchLoader()
            var branchNames = try loadEligibleBranchNames(shell: shell, config: config)

            let loadMerge = loadMergeStatus ?? config.loading.loadMergeStatus
            let loadCreation = loadCreationDate ?? config.loading.loadCreationDate
            let loadSync = loadSyncStatus ?? config.loading.loadSyncStatus

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
                mainBranchName: config.branches.defaultBranch,
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
        
            let deletedBranchNames = try deleteBranches(branchesToDelete, shell: shell, picker: picker, defaultBranch: config.branches.defaultBranch)
            
            // Remove deleted branches from myBranches array and save config
            if !deletedBranchNames.isEmpty && !config.myBranches.isEmpty {
                config.myBranches.removeAll { myBranch in
                    deletedBranchNames.contains(myBranch.name)
                }
                try configLoader.save(config)
            }
            
            if (pruneOrigin || config.behaviors.pruneWhenDeleting) && (try? shell.remoteExists(path: nil)) == true {
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
    
    /// Determines if MyBranches should be used for branch selection
    private func shouldUseMyBranches(config: GitConfig) -> Bool {
        // Use MyBranches when:
        // - No specific search term provided
        // - Not using includeAll flag
        // - Not using allMerged flag
        // - MyBranches array is not empty
        return search == nil &&
               !includeAll &&
               !allMerged &&
               !config.myBranches.isEmpty
    }
    
    /// Runs branch deletion using MyBranches array
    private func runWithMyBranches(shell: GitShell, picker: CommandLinePicker, config: inout GitConfig, configLoader: GitConfigLoader) throws {
        // Get current branch to exclude it from deletion
        let currentBranchName = try shell.runWithOutput(makeGitCommand(.getCurrentBranchName, path: nil))
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Filter MyBranches to exclude current branch and default branch, verify they exist
        let branchLoader = Nngit.makeBranchLoader()
        let existingBranches = try branchLoader.loadBranchNames(from: .local, shell: shell)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "* ", with: "") }
        
        let eligibleMyBranches = config.myBranches.filter { myBranch in
            myBranch.name != currentBranchName &&
            myBranch.name.lowercased() != config.branches.defaultBranch.lowercased() &&
            existingBranches.contains(myBranch.name)
        }
        
        if eligibleMyBranches.isEmpty {
            print("No tracked branches available to delete.")
            return
        }
        
        let branchesToDelete = picker.multiSelection("Select which tracked branches to delete", items: eligibleMyBranches)
        
        if branchesToDelete.isEmpty {
            return
        }
        
        // Convert MyBranch objects to GitBranch objects for deletion
        let loadMerge = loadMergeStatus ?? config.loading.loadMergeStatus
        let loadCreation = loadCreationDate ?? config.loading.loadCreationDate
        let loadSync = loadSyncStatus ?? config.loading.loadSyncStatus
        
        let gitBranches = try branchLoader.loadBranches(
            for: branchesToDelete.map { $0.name },
            shell: shell,
            mainBranchName: config.branches.defaultBranch,
            loadMergeStatus: loadMerge,
            loadCreationDate: loadCreation,
            loadSyncStatus: loadSync
        )
        
        let deletedBranchNames = try deleteBranches(gitBranches, shell: shell, picker: picker, defaultBranch: config.branches.defaultBranch)
        
        // Remove deleted branches from myBranches array and save config
        config.myBranches.removeAll { myBranch in
            deletedBranchNames.contains(myBranch.name)
        }
        try configLoader.save(config)
        
        if (pruneOrigin || config.behaviors.pruneWhenDeleting) && (try? shell.remoteExists(path: nil)) == true {
            let _ = try shell.runWithOutput(makeGitCommand(.pruneOrigin, path: nil))
        }
    }
}
