//
//  GitConfigLoader.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import NnConfigKit
import SwiftPicker

struct GitConfigLoader {
    private let manager = NnConfigManager<GitConfig>(projectName: "nngit")
}


// MARK: - Actions
extension GitConfigLoader {
    func save(_ config: GitConfig) throws {
        try manager.saveConfig(config)
    }
    
    func loadConfig(picker: Picker) throws -> GitConfig {
        do {
            return try load()
        } catch {
            var defaultBranchName = "main"
            var issueNumberPrefix: String?
            var shouldRebaseWhenCreatingNewBranchesFromDefaultBranch: Bool
            
            if !picker.getPermission("Is your default branch called 'main'?") {
                defaultBranchName = try picker.getRequiredInput("Enter the name of your default branch.")
            }
            
            if picker.getPermission("Would you like to add an issue number prefix?") {
                issueNumberPrefix = try picker.getRequiredInput("Enter the issue number prefix.")
            }
            
            shouldRebaseWhenCreatingNewBranchesFromDefaultBranch = picker.getPermission("Include rebase prompt when creating new branches from \(defaultBranchName)?")
            
            let newConfig = GitConfig(defaultBranch: defaultBranchName, issueNumberPrefix: issueNumberPrefix, rebaseWhenBranchingFromDefaultBranch: shouldRebaseWhenCreatingNewBranchesFromDefaultBranch)
            
            try save(newConfig)
            
            return newConfig
        }
    }
}

private extension GitConfigLoader {
    func load() throws -> GitConfig {
        return try manager.loadConfig()
    }
}
