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
        let (sut, _, shell) = makeSUT()
        
        try sut.initializeGitRepository()
        
        #expect(shell.executedCommands.contains("git init"))
    }
    
    @Test("Successfully initializes git with template files when files are configured.")
    func initializeGitWithTemplateFiles() throws {
        let templatePath = try createTempFile(named: "template.txt", content: "template content")
        let gitFile = GitFile(fileName: "README.md", nickname: "ReadMe", localPath: templatePath)
        let config = GitConfig(defaultBranch: "main", gitFiles: [gitFile])
        
        let (sut, _, shell) = makeSUT(config: config)
        
        // Change to temp directory to test file operations
        let currentDirectory = fileManager.currentDirectoryPath
        fileManager.changeCurrentDirectoryPath(tempDirectory.path)
        defer { fileManager.changeCurrentDirectoryPath(currentDirectory) }
        
        try sut.initializeGitRepository()
        
        #expect(shell.executedCommands.contains("git init"))
        
        // Check if README.md file was created
        let readmePath = tempDirectory.appendingPathComponent("README.md").path
        #expect(fileManager.fileExists(atPath: readmePath))
    }
}


// MARK: - Helper Methods
private extension NewGitManagerTests {
    func makeSUT(config: GitConfig = GitConfig.defaultConfig) -> (
        sut: NewGitManager,
        configLoader: TestGitConfigLoader,
        shell: MockShell
    ) {
        let shell = MockShell(results: ["", "Initialized empty Git repository"])
        let picker = MockPicker(
            selectionResponses: ["Select template files to include:": 0]
        )
        let configLoader = TestGitConfigLoader(config: config)
        
        let sut = NewGitManager(
            shell: shell,
            picker: picker,
            configLoader: configLoader
        )
        
        return (sut, configLoader, shell)
    }
    
    func createTempFile(named fileName: String, content: String) throws -> String {
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        try content.write(to: fileURL, atomically: true, encoding: .utf8)
        return fileURL.path
    }
}


// MARK: - Test GitConfigLoader
private class TestGitConfigLoader: GitConfigLoader {
    private let config: GitConfig
    
    init(config: GitConfig) {
        self.config = config
    }
    
    func save(_ config: GitConfig) throws {
        // Not needed for these tests
    }
    
    func loadConfig() throws -> GitConfig {
        return config
    }
    
    func addGitFile(_ gitFile: GitFile) throws {
        // Not needed for these tests
    }
    
    func removeGitFile(named fileName: String) throws -> Bool {
        return true
    }
}