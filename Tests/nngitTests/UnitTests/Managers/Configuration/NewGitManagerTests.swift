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
        
        // Verify file was copied
        #expect(fileSystemManager.copiedFiles.count == 1)
        #expect(fileSystemManager.copiedFiles[0].from == templatePath)
        #expect(fileSystemManager.copiedFiles[0].to == "README.md")
    }
}


// MARK: - Helper Methods
private extension NewGitManagerTests {
    func makeSUT(config: GitConfig = GitConfig.defaultConfig) -> (
        sut: NewGitManager,
        configLoader: MockGitConfigLoader,
        shell: MockShell,
        fileSystemManager: MockFileSystemManager
    ) {
        let shell = MockShell(results: ["", "Initialized empty Git repository"])
        let picker = MockPicker(
            selectionResponses: ["Select template files to include:": 0]
        )
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

