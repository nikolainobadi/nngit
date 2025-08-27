//
//  NewGitManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import Testing
import Foundation
import SwiftPicker
import GitShellKit
import NnShellKit
@testable import nngit

final class NewGitManagerTests {
    private let tempDirectory: URL
    private let fileManager = FileManager.default
    
    init() {
        // Create unique temp directory for this test instance
        tempDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("NewGitManagerTests-\(UUID().uuidString)")
        try! fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    deinit {
        // Clean up entire temp directory
        try? fileManager.removeItem(at: tempDirectory)
    }
}


// MARK: - Tests
extension NewGitManagerTests {
    @Test("Successfully initializes git repository when no template files are configured.")
    func initializeGitWithoutTemplateFiles() throws {
        let (sut, _, shell, _) = makeSUT()
        
        try sut.initializeGitRepository()
        
        #expect(shell.executedCommands.contains("git init"))
        #expect(shell.executedCommands.contains("git add ."))
        #expect(shell.executedCommands.contains("git commit -m \"Initial commit from nngit\""))
    }
    
    @Test("Successfully initializes git with template files when files are configured.")
    func initializeGitWithTemplateFiles() throws {
        let templatePath = "/template/path/template.txt"
        let gitFile = GitFile(fileName: "README.md", nickname: "ReadMe", localPath: templatePath)
        let config = GitConfig(defaultBranch: "main", gitFiles: [gitFile])
        
        let (sut, _, shell, fileSystemManager) = makeSUT(config: config)
        
        // Set up mock file system
        fileSystemManager.addFile(path: templatePath, content: "template content")
        
        try sut.initializeGitRepository()
        
        #expect(shell.executedCommands.contains("git init"))
        #expect(shell.executedCommands.contains("git add ."))
        #expect(shell.executedCommands.contains("git commit -m \"Initial commit from nngit\""))
        
        // Verify file was copied
        #expect(fileSystemManager.copiedFiles.count == 1)
        #expect(fileSystemManager.copiedFiles[0].from == templatePath)
        #expect(fileSystemManager.copiedFiles[0].to == "README.md")
    }
    
    @Test("Successfully overwrites existing file when user confirms.")
    func initializeGitWithOverwriteConfirmation() throws {
        let templatePath = "/template/path/.gitignore"
        let gitFile = GitFile(fileName: ".gitignore", nickname: "GitIgnore", localPath: templatePath)
        let config = GitConfig(defaultBranch: "main", gitFiles: [gitFile])
        
        // Configure picker to select the template file and "Yes" for overwrite
        let selectionResponses = [
            "Select template files to include:": 0,  // Select the .gitignore template
            "File '.gitignore' already exists. Overwrite?": 0  // "Yes"
        ]
        let (sut, _, shell, fileSystemManager) = makeSUT(config: config, selectionResponses: selectionResponses)
        
        // Set up mock file system with both source and existing destination file
        fileSystemManager.addFile(path: templatePath, content: "# Template gitignore")
        fileSystemManager.addFile(path: ".gitignore", content: "# Existing gitignore")
        
        try sut.initializeGitRepository()
        
        #expect(shell.executedCommands.contains("git init"))
        #expect(shell.executedCommands.contains("git add ."))
        #expect(shell.executedCommands.contains("git commit -m \"Initial commit from nngit\""))
        
        // Verify the existing file was removed before copying
        #expect(fileSystemManager.removedFiles.count == 1)
        #expect(fileSystemManager.removedFiles[0] == ".gitignore")
        
        // Verify file was copied after removal
        #expect(fileSystemManager.copiedFiles.count == 1)
        #expect(fileSystemManager.copiedFiles[0].from == templatePath)
        #expect(fileSystemManager.copiedFiles[0].to == ".gitignore")
    }
    
    @Test("Skips file when user declines overwrite.")
    func initializeGitSkipsFileWhenOverwriteDeclined() throws {
        let templatePath = "/template/path/.gitignore"
        let gitFile = GitFile(fileName: ".gitignore", nickname: "GitIgnore", localPath: templatePath)
        let config = GitConfig(defaultBranch: "main", gitFiles: [gitFile])
        
        // Configure picker to select the template file and "No" for overwrite
        let selectionResponses = [
            "Select template files to include:": 0,  // Select the .gitignore template
            "File '.gitignore' already exists. Overwrite?": 1  // "No"
        ]
        let (sut, _, shell, fileSystemManager) = makeSUT(config: config, selectionResponses: selectionResponses)
        
        // Set up mock file system with both source and existing destination file
        fileSystemManager.addFile(path: templatePath, content: "# Template gitignore")
        fileSystemManager.addFile(path: ".gitignore", content: "# Existing gitignore")
        
        try sut.initializeGitRepository()
        
        #expect(shell.executedCommands.contains("git init"))
        #expect(shell.executedCommands.contains("git add ."))
        #expect(shell.executedCommands.contains("git commit -m \"Initial commit from nngit\""))
        
        // Verify no file was removed or copied
        #expect(fileSystemManager.removedFiles.isEmpty)
        #expect(fileSystemManager.copiedFiles.isEmpty)
    }
}


// MARK: - Helper Methods
private extension NewGitManagerTests {
    func makeSUT(
        config: GitConfig = GitConfig.defaultConfig,
        selectionResponses: [String: Int] = ["Select template files to include:": 0]
    ) -> (
        sut: NewGitManager,
        configLoader: MockGitConfigLoader,
        shell: MockShell,
        fileSystemManager: MockFileSystemManager
    ) {
        let shell = MockShell(results: ["", "Initialized empty Git repository"])
        let picker = MockPicker(selectionResponses: selectionResponses)
        let configLoader = MockGitConfigLoader(customConfig: config)
        let fileSystemManager = MockFileSystemManager()
        
        let sut = NewGitManager(
            shell: shell,
            picker: picker,
            configLoader: configLoader,
            fileSystemManager: fileSystemManager
        )
        
        return (sut, configLoader, shell, fileSystemManager)
    }
    
    func createTempFile(named fileName: String, content: String) throws -> String {
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL.path
    }
}

