//
//  NewBranchManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import GitShellKit
import SwiftPicker

/// Manager for handling new branch creation with remote synchronization checks.
struct NewBranchManager {
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


// MARK: - Branch Analysis
extension NewBranchManager {
    /// Handles remote repository synchronization when creating a new branch.
    /// Checks if current branch is the default branch and handles sync status.
    func handleRemoteRepository() throws {
        guard let currentBranch = try loadCurrentBranch() else {
            return // TODO: -
        }
        
        if isDefaultBranch(currentBranch) {
            let mainBranchStatus = try branchLoader.getSyncStatus(branchName: currentBranch.name, comparingBranch: nil, remoteExists: true)
            
            switch mainBranchStatus {
            case .behind:
                break
            case .ahead:
                try handleAheadBranch(currentBranch)
            case .nsync:
                break
            default:
                break
            }
        } else {
            // TODO: - check if a remote branch exists
            // if it does, get status
        }
    }
}


// MARK: - Private Methods
private extension NewBranchManager {
    func loadCurrentBranch() throws -> GitBranch? {
        return try branchLoader.loadBranches(for: nil, mainBranchName: config.defaultBranch).first(where: { $0.isCurrentBranch })
    }
    
    func isDefaultBranch(_ branch: GitBranch) -> Bool {
        return branch.name == config.defaultBranch
    }
    
    func handleAheadBranch(_ branch: GitBranch) throws {
        try picker.requiredPermission(
            "Your \(config.defaultBranch) branch has unpushed changes. Would you like to push them before creating a new branch?"
        )
        
        try shell.runGitCommandWithOutput(.push, path: nil)
        print("✅ Pushed changes to \(config.defaultBranch)")
    }
}
