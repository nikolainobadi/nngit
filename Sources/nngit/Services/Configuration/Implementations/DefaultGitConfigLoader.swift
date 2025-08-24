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
    private let picker: CommandLinePicker
    
    init(picker: CommandLinePicker) {
        self.picker = picker
    }
}


// MARK: - Actions
extension DefaultGitConfigLoader {
    /// Persists the provided configuration to disk.
    func save(_ config: GitConfig) throws {
        try manager.saveConfig(config)
    }

    /// Loads the configuration from disk or creates a new one by prompting the user.
    func loadConfig() throws -> GitConfig {
        do {
            return try load()
        } catch {
            var defaultBranchName = "main"
            
            if !picker.getPermission("Is your default branch called 'main'?") {
                defaultBranchName = try picker.getRequiredInput("Enter the name of your default branch.")
            }
            
            let newConfig = GitConfig(defaultBranch: defaultBranchName, gitFiles: [])
            
            try save(newConfig)
            
            return newConfig
        }
    }
    
    /// Adds a GitFile to the configuration.
    func addGitFile(_ gitFile: GitFile) throws {
        var config = try loadConfig()
        
        if config.gitFiles.contains(where: { $0.fileName == gitFile.fileName }) {
            if !picker.getPermission("GitFile with name '\(gitFile.fileName)' already exists. Replace it?") {
                return
            }
            config.gitFiles.removeAll { $0.fileName == gitFile.fileName }
        }
        
        config.gitFiles.append(gitFile)
        try save(config)
    }
    
    /// Removes a GitFile from the configuration by fileName. Returns true if removed, false if not found.
    func removeGitFile(named fileName: String) throws -> Bool {
        var config = try loadConfig()
        let initialCount = config.gitFiles.count
        
        config.gitFiles.removeAll { $0.fileName == fileName }
        
        if config.gitFiles.count < initialCount {
            try save(config)
            return true
        }
        
        return false
    }
}


// MARK: - Private Methods
private extension DefaultGitConfigLoader {
    /// Helper method reading the configuration from ``NnConfigManager``.
    func load() throws -> GitConfig {
        return try manager.loadConfig()
    }
}
