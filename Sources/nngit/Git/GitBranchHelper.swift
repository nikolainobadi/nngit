//
//  GitBranchHelper.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import GitShellKit
import SwiftPicker

/// Helper utility for common branch operations and workflows.
struct GitBranchHelper {
    private let shell: GitShell
    
    init(shell: GitShell) {
        self.shell = shell
    }
}

// MARK: - Branch Operations
extension GitBranchHelper {
    /// Rebases the default branch if configured and the user approves.
    ///
    /// This method checks if:
    /// 1. A remote repository exists
    /// 2. The current branch is the default branch
    /// 3. Rebase behavior is enabled in the configuration
    ///
    /// If all conditions are met, it prompts the user and performs a rebase if approved.
    ///
    /// - Parameters:
    ///   - config: The Git configuration containing behavior settings
    ///   - picker: The command line picker for user interaction
    func rebaseIfNecessary(config: GitConfig, picker: CommandLinePicker) throws {
        guard try shell.remoteExists(path: nil) else {
            return
        }
        
        let currentBranch = try shell.runWithOutput(makeGitCommand(.getCurrentBranchName, path: nil)).trimmingCharacters(in: .whitespacesAndNewlines)
        let isOnMainBranch = currentBranch.lowercased() == config.branches.defaultBranch.lowercased()
        
        guard isOnMainBranch && config.behaviors.rebaseWhenBranchingFromDefault else {
            return
        }
        
        if picker.getPermission("Would you like to rebase before creating your new branch?") {
            try shell.runWithOutput("git pull --rebase")
        }
    }
}