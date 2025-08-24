//
//  DeleteBranchManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import GitShellKit
import SwiftPicker

/// Manager utility for handling branch deletion workflows and operations.
struct DeleteBranchManager {
    private let shell: GitShell
    private let picker: CommandLinePicker
    private let branchLoader: GitBranchLoader
    private let config: GitConfig
    
    init(shell: GitShell, picker: CommandLinePicker, branchLoader: GitBranchLoader, config: GitConfig) {
        self.shell = shell
        self.picker = picker
        self.branchLoader = branchLoader
        self.config = config
    }
}


// MARK: - Branch Deletion Operations
extension DeleteBranchManager {
    func deleteBranches(search: String?, allMerged: Bool) throws {
        let branchNames = try loadEligibleBranchNames()
        
        guard let filteredNames = try handleSearchAndFiltering(branchNames: branchNames, search: search) else {
            return
        }
        
        let eligibleBranches = try loadBranchData(branchNames: filteredNames)
        
        guard let branchesToDelete = selectBranchesToDelete(eligibleBranches: eligibleBranches, allMerged: allMerged) else {
            return
        }
        
        let _ = try performDeletion(branchesToDelete)
        try pruneOriginIfExists()
    }
}


// MARK: - Private Methods
private extension DeleteBranchManager {
    func loadEligibleBranchNames() throws -> [String] {
        return try branchLoader.loadBranchNames(from: .local)
            .filter { name in
                // Exclude current branch (marked with "*")
                if name.hasPrefix("*") {
                    return false
                }
                // Also exclude the default branch
                return name.lowercased() != config.defaultBranch.lowercased()
            }
    }
    
    func handleSearchAndFiltering(branchNames: [String], search: String?) throws -> [String]? {
        guard let search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return branchNames
        }
        
        let filteredNames = branchLoader.filterBranchNamesBySearch(branchNames, search: search)
        guard !filteredNames.isEmpty else {
            print("No branches found matching '\(search)'")
            return nil
        }
        
        return filteredNames
    }
    
    func loadBranchData(branchNames: [String]) throws -> [GitBranch] {
        return try branchLoader.loadBranches(
            for: branchNames,
            mainBranchName: config.defaultBranch
        ).filter { !$0.isCurrentBranch }  // Extra safety: filter out current branch
    }
    
    func selectBranchesToDelete(eligibleBranches: [GitBranch], allMerged: Bool) -> [GitBranch]? {
        if allMerged {
            let branchesToDelete = eligibleBranches.filter { $0.isMerged }
            if branchesToDelete.isEmpty {
                print("No merged branches found")
                return nil
            }
            
            // Display branches that will be deleted
            print("The following merged branches will be deleted:")
            let displayCount = min(branchesToDelete.count, 10)
            for i in 0..<displayCount {
                print("  - \(branchesToDelete[i].name)")
            }
            
            // If there are more than 10, show how many more
            if branchesToDelete.count > 10 {
                print("  ... and \(branchesToDelete.count - 10) more")
            }
            
            print("\nTotal branches to delete: \(branchesToDelete.count)")
            
            // Prompt for confirmation
            do {
                try picker.requiredPermission("Do you want to proceed with deleting these \(branchesToDelete.count) merged branches?")
            } catch {
                print("Deletion cancelled")
                return nil
            }
            
            return branchesToDelete
        } else {
            return picker.multiSelection("Select which branches to delete", items: eligibleBranches)
        }
    }
    
    func deleteBranch(_ branch: GitBranch, forced: Bool = false) throws {
        let _ = try shell.runWithOutput(makeGitCommand(.deleteBranch(name: branch.name, forced: forced), path: nil))
    }
    
    func performDeletion(_ branches: [GitBranch]) throws -> [String] {
        var deletedBranchNames: [String] = []
        
        for branch in branches {
            if branch.isMerged {
                try deleteBranch(branch)
                deletedBranchNames.append(branch.name)
            } else {
                try picker.requiredPermission(
                    "This branch has NOT been merged into \(config.defaultBranch.yellow). Are you sure you want to delete it?"
                )
                try deleteBranch(branch, forced: true)
                deletedBranchNames.append(branch.name)
            }
            print("✅ Deleted branch: \(branch.name)")
        }
        
        return deletedBranchNames
    }
    
    func pruneOriginIfExists() throws {
        if (try? shell.remoteExists(path: nil)) == true {
            let _ = try shell.runWithOutput(makeGitCommand(.pruneOrigin, path: nil))
        }
    }
}