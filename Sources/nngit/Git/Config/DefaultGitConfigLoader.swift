//
//  DefaultGitConfigLoader.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import NnConfigKit
import SwiftPicker

/// Default implementation of ``GitConfigLoader`` backed by ``NnConfigManager``.
struct DefaultGitConfigLoader: GitConfigLoader {
    private let manager = NnConfigManager<GitConfig>(projectName: "nngit")
}


// MARK: - Actions
extension DefaultGitConfigLoader {
    /// Persists the provided configuration to disk.
    func save(_ config: GitConfig) throws {
        try manager.saveConfig(config)
    }

    /// Loads the configuration from disk or creates a new one by prompting the user.
    func loadConfig(picker: Picker) throws -> GitConfig {
        do {
            return try load()
        } catch {
            var defaultBranchName = "main"
            var shouldRebaseWhenCreatingNewBranchesFromDefaultBranch: Bool
            
            if !picker.getPermission("Is your default branch called 'main'?") {
                defaultBranchName = try picker.getRequiredInput("Enter the name of your default branch.")
            }
            
            shouldRebaseWhenCreatingNewBranchesFromDefaultBranch = picker.getPermission("Include rebase prompt when creating new branches from \(defaultBranchName)?")
            
            let newConfig = GitConfig(defaultBranch: defaultBranchName, branchPrefixList: [], rebaseWhenBranchingFromDefaultBranch: shouldRebaseWhenCreatingNewBranchesFromDefaultBranch)
            
            try save(newConfig)
            
            return newConfig
        }
    }
}

private extension DefaultGitConfigLoader {
    /// Helper method reading the configuration from ``NnConfigManager``.
    func load() throws -> GitConfig {
        return try manager.loadConfig()
    }
}
