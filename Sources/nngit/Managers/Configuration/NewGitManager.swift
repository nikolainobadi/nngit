//
//  NewGitManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import Foundation
import SwiftPicker
import GitShellKit

/// Manager for handling Git repository initialization with template file selection.
struct NewGitManager {
    private let shell: GitShell
    private let picker: CommandLinePicker
    private let configLoader: GitConfigLoader
    private let fileSystemManager: FileSystemManager
    
    init(shell: GitShell, picker: CommandLinePicker, configLoader: GitConfigLoader, fileSystemManager: FileSystemManager) {
        self.shell = shell
        self.picker = picker
        self.configLoader = configLoader
        self.fileSystemManager = fileSystemManager
    }
}


// MARK: - Main Workflow
extension NewGitManager {
    /// Initializes a new Git repository and sets up selected template files.
    func initializeGitRepository() throws {
        let config = try configLoader.loadConfig()
        
        guard !config.gitFiles.isEmpty else {
            print("No template files configured. Use 'nngit add-git-file' to add templates first.")
            try initializeGit()
            return
        }
        
        let selectedFiles = try selectGitFiles(from: config.gitFiles)
        
        try initializeGit()
        try copySelectedFiles(selectedFiles)
        
        print("✅ Git repository initialized with \(selectedFiles.count) template file(s)")
    }
}


// MARK: - Git Operations
private extension NewGitManager {
    /// Initializes a new Git repository in the current directory.
    func initializeGit() throws {
        _ = try shell.runWithOutput("git init")
        print("📁 Initialized empty Git repository")
    }
}


// MARK: - File Selection and Management
private extension NewGitManager {
    /// Presents GitFiles to user for multi-selection.
    func selectGitFiles(from gitFiles: [GitFile]) throws -> [GitFile] {
        let displayItems = gitFiles.map { "\($0.nickname) (\($0.fileName))" }
        
        let selectedDisplayItems = picker.multiSelection(
            "Select template files to include:",
            items: displayItems
        )
        
        return selectedDisplayItems.compactMap { displayItem in
            gitFiles.first { "\($0.nickname) (\($0.fileName))" == displayItem }
        }
    }
    
    /// Copies the selected GitFiles to the current directory.
    func copySelectedFiles(_ gitFiles: [GitFile]) throws {
        for gitFile in gitFiles {
            try copyGitFile(gitFile)
        }
    }
    
    /// Copies a single GitFile to the current directory.
    func copyGitFile(_ gitFile: GitFile) throws {
        let sourcePath = gitFile.localPath
        let destinationPath = gitFile.fileName
        
        guard fileSystemManager.fileExists(atPath: sourcePath) else {
            throw NewGitError.templateFileNotFound(sourcePath)
        }
        
        if fileSystemManager.fileExists(atPath: destinationPath) {
            let options = ["Yes", "No"]
            let choice = picker.singleSelection(
                "File '\(destinationPath)' already exists. Overwrite?",
                items: options
            )
            
            if choice == "No" {
                print("⏭️  Skipped \(destinationPath)")
                return
            }
        }
        
        try fileSystemManager.copyItem(atPath: sourcePath, toPath: destinationPath)
        print("📄 Added \(destinationPath)")
    }
}


// MARK: - Errors
enum NewGitError: Error, Equatable {
    case gitAlreadyExists
    case templateFileNotFound(String)
    case fileCopyFailed(String)
}