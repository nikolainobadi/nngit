//
//  NewBranchManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Foundation
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
            throw NewBranchError.noCurrentBranch
        }
        
        let branchStatus = try branchLoader.getSyncStatus(branchName: currentBranch.name, comparingBranch: nil)
        
        switch branchStatus {
        case .behind:
            try handleBehindBranch(currentBranch)
        case .ahead:
            try handleAheadBranch(currentBranch)
        case .nsync:
            break
        case .diverged:
            throw NewBranchError.branchDiverged
        case .undetermined:
            throw NewBranchError.branchStatusUndetermined
        case .noRemoteBranch:
            // Allow branch creation when there's no remote branch to compare with
            // This is valid for both default and feature branches
            break
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
        let branchName = isDefaultBranch(branch) ? config.defaultBranch : branch.name
        
        try picker.requiredPermission(
            "Your \(branchName) branch has unpushed changes. Would you like to push them before creating a new branch?"
        )
        
        try shell.runGitCommandWithOutput(.push, path: nil)
        print("✅ Pushed changes to \(branchName)")
    }
    
    func handleBehindBranch(_ branch: GitBranch) throws {
        if isDefaultBranch(branch) {
            let syncOption = try picker.requiredSingleSelection(
                "Your \(config.defaultBranch) branch is behind the remote. You must sync before creating a new branch:",
                items: [SyncOption.merge, SyncOption.rebase]
            )
            
            switch syncOption {
            case .merge:
                try shell.runGitCommandWithOutput(.pull(withRebase: false), path: nil)
                print("✅ Merged remote changes into \(config.defaultBranch)")
            case .rebase:
                try shell.runGitCommandWithOutput(.pull(withRebase: true), path: nil)
                print("✅ Rebased \(config.defaultBranch) onto remote changes")
            }
        } else {
            // Non-default branches behind remote must be rebased before creating new branches
            try picker.requiredPermission(
                "Your \(branch.name) branch is behind the remote. You must rebase before creating a new branch. Continue?"
            )
            
            try shell.runGitCommandWithOutput(.pull(withRebase: true), path: nil)
            print("✅ Rebased \(branch.name) onto remote changes")
        }
    }
}


// MARK: - Supporting Types
private extension NewBranchManager {
    enum SyncOption: DisplayablePickerItem {
        case merge
        case rebase
        
        var displayName: String {
            switch self {
            case .merge:
                return "Merge remote changes (git pull)"
            case .rebase:
                return "Rebase onto remote changes (git pull --rebase)"
            }
        }
    }
}
