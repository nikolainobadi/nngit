//
//  UnregisterGitFileManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 9/2/25.
//

import Foundation
import SwiftPicker

/// Manager utility for handling git file unregistration workflows.
struct UnregisterGitFileManager {
    private let configLoader: GitConfigLoader
    private let fileCreator: GitFileCreator
    private let picker: CommandLinePicker
    
    init(configLoader: GitConfigLoader, fileCreator: GitFileCreator, picker: CommandLinePicker) {
        self.configLoader = configLoader
        self.fileCreator = fileCreator
        self.picker = picker
    }
}


// MARK: - Public Methods
extension UnregisterGitFileManager {
    /// Unregisters a git file from the configuration.
    /// - Parameters:
    ///   - templateName: Optional name or nickname of the template to unregister
    ///   - removeAll: If true, removes all registered git files
    func unregisterGitFile(templateName: String?, removeAll: Bool) throws {
        let config = try configLoader.loadConfig()
        
        guard !config.gitFiles.isEmpty else {
            throw UnregisterGitFileError.noRegisteredFiles
        }
        
        if removeAll {
            try handleRemoveAll(config: config)
        } else {
            try handleSingleFileRemoval(config: config, templateName: templateName)
        }
    }
}


// MARK: - Private Methods
private extension UnregisterGitFileManager {
    func handleRemoveAll(config: GitConfig) throws {
        print("Found \(config.gitFiles.count) registered git file(s):")
        for file in config.gitFiles {
            print("  - \(file.displayName)")
        }
        
        do {
            try picker.requiredPermission("Are you sure you want to remove all \(config.gitFiles.count) registered git files?")
        } catch {
            throw UnregisterGitFileError.deletionCancelled
        }
        
        let shouldDeleteTemplates = picker.getPermission("Delete template files from disk as well?")
        
        if shouldDeleteTemplates {
            for file in config.gitFiles {
                try deleteTemplateFileIfExists(file)
            }
        }
        
        // Remove all files from config
        var updatedConfig = config
        updatedConfig.gitFiles.removeAll()
        try configLoader.save(updatedConfig)
        
        print("✅ Removed all registered git files")
    }
    
    func handleSingleFileRemoval(config: GitConfig, templateName: String?) throws {
        let fileToRemove: GitFile
        
        if let templateName = templateName {
            // Find by name or nickname
            if let matchedFile = findGitFile(in: config.gitFiles, matching: templateName) {
                fileToRemove = matchedFile
            } else {
                throw UnregisterGitFileError.fileNotFound(templateName)
            }
        } else {
            // Interactive selection
            guard let selectedFile = picker.singleSelection("Select a git file to unregister:", items: config.gitFiles) else {
                throw UnregisterGitFileError.deletionCancelled
            }
            fileToRemove = selectedFile
        }
        
        // Confirm deletion
        do {
            try picker.requiredPermission("Remove git file '\(fileToRemove.displayName)'?")
        } catch {
            throw UnregisterGitFileError.deletionCancelled
        }
        
        // Ask about template file deletion
        let shouldDeleteTemplate = picker.getPermission("Delete template file from disk as well?")
        
        if shouldDeleteTemplate {
            try deleteTemplateFileIfExists(fileToRemove)
        }
        
        // Remove from config
        let removed = try configLoader.removeGitFile(named: fileToRemove.fileName)
        
        if removed {
            print("✅ Removed git file '\(fileToRemove.displayName)'")
        } else {
            // This shouldn't happen given our earlier checks, but handle it gracefully
            throw UnregisterGitFileError.fileNotFound(fileToRemove.fileName)
        }
    }
    
    func findGitFile(in files: [GitFile], matching searchTerm: String) -> GitFile? {
        // First try exact filename match
        if let file = files.first(where: { $0.fileName == searchTerm }) {
            return file
        }
        
        // Then try exact nickname match
        if let file = files.first(where: { $0.nickname == searchTerm }) {
            return file
        }
        
        // Then try case-insensitive filename match
        if let file = files.first(where: { $0.fileName.lowercased() == searchTerm.lowercased() }) {
            return file
        }
        
        // Finally try case-insensitive nickname match
        if let file = files.first(where: { $0.nickname.lowercased() == searchTerm.lowercased() }) {
            return file
        }
        
        return nil
    }
    
    func deleteTemplateFileIfExists(_ file: GitFile) throws {
        let fileManager = FileManager.default
        
        // Check if the file exists at the local path
        if fileManager.fileExists(atPath: file.localPath) {
            do {
                try fileManager.removeItem(atPath: file.localPath)
                print("  Deleted template file: \(file.localPath)")
            } catch {
                print("  Warning: Could not delete template file at \(file.localPath): \(error.localizedDescription)")
            }
        }
    }
}


// MARK: - Error Definition
enum UnregisterGitFileError: Error, Equatable {
    case noRegisteredFiles
    case fileNotFound(String)
    case deletionCancelled
}


// MARK: - CustomStringConvertible
extension UnregisterGitFileError: CustomStringConvertible {
    var description: String {
        switch self {
        case .noRegisteredFiles:
            return "No git files are currently registered"
        case .fileNotFound(let name):
            return "Git file '\(name)' not found"
        case .deletionCancelled:
            return "Deletion cancelled by user"
        }
    }
}