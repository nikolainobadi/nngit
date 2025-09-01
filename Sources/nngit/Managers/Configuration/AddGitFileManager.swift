//
//  AddGitFileManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/31/25.
//

import Foundation
import SwiftPicker

/// Manager for adding registered template files to the current repository.
struct AddGitFileManager {
    private let configLoader: GitConfigLoader
    private let fileSystemManager: FileSystemManager
    private let picker: CommandLinePicker
    
    init(configLoader: GitConfigLoader, fileSystemManager: FileSystemManager, picker: CommandLinePicker) {
        self.configLoader = configLoader
        self.fileSystemManager = fileSystemManager
        self.picker = picker
    }
}


// MARK: - Main Workflow
extension AddGitFileManager {
    /// Adds a registered template file to the current repository.
    /// If templateName is provided, uses that specific file. Otherwise, prompts user to select from available files.
    func addGitFileToRepository(templateName: String?) throws {
        let config = try configLoader.loadConfig()
        
        guard !config.gitFiles.isEmpty else {
            throw AddGitFileError.noRegisteredFiles
        }
        
        let selectedGitFile: GitFile
        
        if let templateName = templateName {
            selectedGitFile = try selectByName(templateName: templateName, from: config.gitFiles)
        } else {
            selectedGitFile = try selectInteractively(from: config.gitFiles)
        }
        
        try addFileToRepository(gitFile: selectedGitFile)
    }
}


// MARK: - Selection Methods
private extension AddGitFileManager {
    /// Finds a GitFile by name or nickname.
    func selectByName(templateName: String, from gitFiles: [GitFile]) throws -> GitFile {
        // First try exact match by nickname
        if let found = gitFiles.first(where: { $0.nickname.lowercased() == templateName.lowercased() }) {
            return found
        }
        
        // Then try exact match by filename
        if let found = gitFiles.first(where: { $0.fileName.lowercased() == templateName.lowercased() }) {
            return found
        }
        
        // Finally try partial match by nickname
        let partialMatches = gitFiles.filter { 
            $0.nickname.lowercased().contains(templateName.lowercased()) ||
            $0.fileName.lowercased().contains(templateName.lowercased())
        }
        
        if partialMatches.isEmpty {
            throw AddGitFileError.templateNotFound(templateName)
        } else if partialMatches.count == 1 {
            return partialMatches[0]
        } else {
            // Multiple matches, let user select
            return try picker.requiredSingleSelection(
                "Multiple templates match '\(templateName)'. Select one:",
                items: partialMatches
            )
        }
    }
    
    /// Prompts user to select from available GitFiles.
    func selectInteractively(from gitFiles: [GitFile]) throws -> GitFile {
        return try picker.requiredSingleSelection(
            "Select a template file to add:",
            items: gitFiles
        )
    }
}


// MARK: - File Operations
private extension AddGitFileManager {
    /// Adds the selected GitFile to the current repository.
    func addFileToRepository(gitFile: GitFile) throws {
        let destinationPath = gitFile.fileName
        
        // Check if file already exists
        if fileSystemManager.fileExists(atPath: destinationPath) {
            let shouldOverwrite = picker.getPermission(
                "File '\(gitFile.fileName)' already exists. Overwrite it?"
            )
            
            guard shouldOverwrite else {
                print("Operation cancelled. File was not overwritten.")
                return
            }
        }
        
        // Copy the file from template location to current directory
        guard fileSystemManager.fileExists(atPath: gitFile.localPath) else {
            throw AddGitFileError.templateFileNotFound(gitFile.localPath)
        }
        
        try fileSystemManager.copyItem(
            atPath: gitFile.localPath,
            toPath: destinationPath
        )
        
        print("✅ Added '\(gitFile.fileName)' to current directory")
    }
}


// MARK: - Errors
enum AddGitFileError: Error, LocalizedError, Equatable {
    case noRegisteredFiles
    case templateNotFound(String)
    case templateFileNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .noRegisteredFiles:
            return "No template files have been registered. Use 'register-git-file' to register template files first."
        case .templateNotFound(let name):
            return "No template found matching '\(name)'. Use 'register-git-file' to see available templates or register new ones."
        case .templateFileNotFound(let path):
            return "Template file not found at '\(path)'. The registered template may have been moved or deleted."
        }
    }
}