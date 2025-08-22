//
//  NewBranchManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import GitShellKit

/// Manager for handling new branch creation with remote synchronization checks.
struct NewBranchManager {
    private let shell: GitShell
    private let branchLoader: GitBranchLoader
    private let config: GitConfig
    
    init(shell: GitShell, branchLoader: GitBranchLoader, config: GitConfig) {
        self.shell = shell
        self.branchLoader = branchLoader
        self.config = config
    }
}


// MARK: - Branch Analysis
extension NewBranchManager {
    /// Gets the current branch name from the git repository.
    func getCurrentBranch() throws -> String? {
        let branchNames = try branchLoader.loadBranchNames(from: .local)
        let currentBranch = branchNames.first { $0.hasPrefix("*") }
        return currentBranch?.dropFirst(2).trimmingCharacters(in: .whitespaces)
    }
    
    /// Checks if the current branch is the default branch configured in GitConfig.
    func isCurrentBranchDefault() throws -> Bool {
        guard let currentBranch = try getCurrentBranch() else { return false }
        return currentBranch == config.defaultBranch
    }
    
    /// Gets the sync status of the current branch if it's the default branch.
    /// Returns nil if current branch is not the default branch.
    func getCurrentBranchSyncStatus() throws -> BranchSyncStatus? {
        guard try isCurrentBranchDefault(),
              let currentBranch = try getCurrentBranch(),
              let remoteExists = try? shell.remoteExists(path: nil),
              remoteExists else {
            return nil
        }
        
        return try branchLoader.getSyncStatus(
            branchName: currentBranch,
            comparingBranch: nil,
            remoteExists: remoteExists
        )
    }
    
    /// Handles remote repository synchronization when creating a new branch.
    /// Checks if current branch is the default branch and handles sync status.
    func handleRemoteRepository() throws {
        if try isCurrentBranchDefault() {
            if let syncStatus = try getCurrentBranchSyncStatus() {
                // TODO: Handle different sync statuses (ahead, behind, nsync, diverged)
                print("Current branch sync status: \(syncStatus.rawValue)")
            }
        }
    }
}
