//
//  AddGitFileManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import Testing
import Foundation
import SwiftPicker
@testable import nngit

class AddGitFileManagerTests {
    private let tempDirectory: URL
    private let fileManager = FileManager.default
    
    init() {
        // Create unique temp directory for this test instance
        tempDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("AddGitFileManagerTests-\(UUID().uuidString)")
        try! fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    deinit {
        // Clean up entire temp directory
        try? fileManager.removeItem(at: tempDirectory)
    }
    
    // MARK: - Helper Methods
    private func createTempFile(named name: String, content: String = "test content") throws -> String {
        let path = tempDirectory.appendingPathComponent(name).path
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }
    
    private func tempPath(for fileName: String) -> String {
        return tempDirectory.appendingPathComponent(fileName).path
    }
    
    @Test("Successfully adds GitFile with all parameters provided and direct path.")
    func addGitFileWithAllParametersDirectPath() throws {
        let sourcePath = try createTempFile(named: "test.txt")
        
        let configLoader = MockGitConfigLoader()
        let fileCreator = MockGitFileCreator()
        let picker = MockPicker()
        let manager = makeSUT(configLoader: configLoader, fileCreator: fileCreator, picker: picker)
        
        try manager.addGitFile(
            sourcePath: sourcePath,
            fileName: "test.txt",
            nickname: "Test File",
            useDirectPath: true
        )
        
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.fileName == "test.txt")
        #expect(addedFile.nickname == "Test File")
        #expect(addedFile.localPath == sourcePath)
    }
    
    @Test("Successfully adds GitFile with all parameters provided and template copy.")
    func addGitFileWithAllParametersTemplateCopy() throws {
        let sourcePath = try createTempFile(named: "test.txt")
        let copyPath = "/templates/test.txt"
        
        let configLoader = MockGitConfigLoader()
        let fileCreator = MockGitFileCreator(copyResult: copyPath)
        let picker = MockPicker()
        let manager = makeSUT(configLoader: configLoader, fileCreator: fileCreator, picker: picker)
        
        try manager.addGitFile(
            sourcePath: sourcePath,
            fileName: "test.txt",
            nickname: "Test File",
            useDirectPath: false
        )
        
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.fileName == "test.txt")
        #expect(addedFile.nickname == "Test File")
        #expect(addedFile.localPath == copyPath)
        #expect(fileCreator.copiedSourcePath == sourcePath)
        #expect(fileCreator.copiedFileName == "test.txt")
    }
    
    @Test("Prompts for source path when not provided.")
    func addGitFilePromptsForSourcePath() throws {
        let sourcePath = try createTempFile(named: "prompted.txt", content: "content")
        
        let configLoader = MockGitConfigLoader()
        let fileCreator = MockGitFileCreator()
        let picker = MockPicker(requiredInputResponses: ["Enter path to template file:": sourcePath])
        let manager = makeSUT(configLoader: configLoader, fileCreator: fileCreator, picker: picker)
        
        try manager.addGitFile(
            sourcePath: nil,
            fileName: "prompted.txt",
            nickname: "Prompted File",
            useDirectPath: true
        )
        
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.fileName == "prompted.txt")
        #expect(addedFile.localPath == sourcePath)
    }
    
    @Test("Throws error when source file does not exist.")
    func addGitFileThrowsWhenSourceFileNotFound() {
        let configLoader = MockGitConfigLoader()
        let fileCreator = MockGitFileCreator()
        let picker = MockPicker()
        let manager = makeSUT(configLoader: configLoader, fileCreator: fileCreator, picker: picker)
        
        #expect(throws: AddGitFileError.sourceFileNotFound("nonexistent.txt")) {
            try manager.addGitFile(
                sourcePath: "nonexistent.txt",
                fileName: "test.txt",
                nickname: "Test",
                useDirectPath: true
            )
        }
    }
    
    @Test("Throws error when prompted source file does not exist.")
    func addGitFileThrowsWhenPromptedSourceFileNotFound() {
        let configLoader = MockGitConfigLoader()
        let fileCreator = MockGitFileCreator()
        let picker = MockPicker(requiredInputResponses: ["Enter path to template file:": "nonexistent.txt"])
        let manager = makeSUT(configLoader: configLoader, fileCreator: fileCreator, picker: picker)
        
        #expect(throws: AddGitFileError.sourceFileNotFound("nonexistent.txt")) {
            try manager.addGitFile(
                sourcePath: nil,
                fileName: "test.txt",
                nickname: "Test",
                useDirectPath: true
            )
        }
    }
    
    @Test("Uses source filename when fileName not provided.")
    func addGitFileUsesSourceFileNameWhenNotProvided() throws {
        let sourcePath = try createTempFile(named: "source.txt", content: "content")
        
        let configLoader = MockGitConfigLoader()
        let fileCreator = MockGitFileCreator()
        let picker = MockPicker(requiredInputResponses: ["Output filename (leave blank for 'source.txt'):": ""])
        let manager = makeSUT(configLoader: configLoader, fileCreator: fileCreator, picker: picker)
        
        try manager.addGitFile(
            sourcePath: sourcePath,
            fileName: nil,
            nickname: "Test",
            useDirectPath: true
        )
        
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.fileName == "source.txt")
    }
    
    @Test("Uses custom filename when prompted.")
    func addGitFileUsesCustomFileNameWhenPrompted() throws {
        let sourcePath = try createTempFile(named: "source.txt", content: "content")
        
        let configLoader = MockGitConfigLoader()
        let fileCreator = MockGitFileCreator()
        let picker = MockPicker(requiredInputResponses: ["Output filename (leave blank for 'source.txt'):": "custom.txt"])
        let manager = makeSUT(configLoader: configLoader, fileCreator: fileCreator, picker: picker)
        
        try manager.addGitFile(
            sourcePath: sourcePath,
            fileName: nil,
            nickname: "Test",
            useDirectPath: true
        )
        
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.fileName == "custom.txt")
    }
    
    @Test("Uses filename as nickname when nickname not provided.")
    func addGitFileUsesFileNameAsNicknameWhenNotProvided() throws {
        let sourcePath = try createTempFile(named: "test.txt", content: "content")
        
        let configLoader = MockGitConfigLoader()
        let fileCreator = MockGitFileCreator()
        let picker = MockPicker(requiredInputResponses: ["Display name (leave blank for 'test.txt'):": ""])
        let manager = makeSUT(configLoader: configLoader, fileCreator: fileCreator, picker: picker)
        
        try manager.addGitFile(
            sourcePath: sourcePath,
            fileName: "test.txt",
            nickname: nil,
            useDirectPath: true
        )
        
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.nickname == "test.txt")
    }
    
    @Test("Uses custom nickname when prompted.")
    func addGitFileUsesCustomNicknameWhenPrompted() throws {
        let sourcePath = try createTempFile(named: "test.txt", content: "content")
        
        let configLoader = MockGitConfigLoader()
        let fileCreator = MockGitFileCreator()
        let picker = MockPicker(requiredInputResponses: ["Display name (leave blank for 'test.txt'):": "Custom Name"])
        let manager = makeSUT(configLoader: configLoader, fileCreator: fileCreator, picker: picker)
        
        try manager.addGitFile(
            sourcePath: sourcePath,
            fileName: "test.txt",
            nickname: nil,
            useDirectPath: true
        )
        
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.nickname == "Custom Name")
    }
    
    @Test("Handles file copy operation when not using direct path.")
    func addGitFileHandlesFileCopyOperation() throws {
        let sourcePath = try createTempFile(named: "original.txt", content: "content")
        let copyPath = "/templates/copied.txt"
        
        let configLoader = MockGitConfigLoader()
        let fileCreator = MockGitFileCreator(copyResult: copyPath)
        let picker = MockPicker()
        let manager = makeSUT(configLoader: configLoader, fileCreator: fileCreator, picker: picker)
        
        try manager.addGitFile(
            sourcePath: sourcePath,
            fileName: "copied.txt",
            nickname: "Copied File",
            useDirectPath: false
        )
        
        #expect(fileCreator.copiedSourcePath == sourcePath)
        #expect(fileCreator.copiedFileName == "copied.txt")
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.localPath == copyPath)
    }
    
    @Test("Propagates errors from config loader.")
    func addGitFilePropagatesConfigLoaderErrors() throws {
        let sourcePath = try createTempFile(named: "test.txt", content: "content")
        
        let configLoader = MockGitConfigLoader(shouldThrowOnAdd: true)
        let fileCreator = MockGitFileCreator()
        let picker = MockPicker()
        let manager = makeSUT(configLoader: configLoader, fileCreator: fileCreator, picker: picker)
        
        #expect(throws: TestError.configError) {
            try manager.addGitFile(
                sourcePath: sourcePath,
                fileName: "test.txt",
                nickname: "Test",
                useDirectPath: true
            )
        }
    }
    
    @Test("Propagates errors from file creator.")
    func addGitFilePropagatesFileCreatorErrors() throws {
        let sourcePath = try createTempFile(named: "test.txt", content: "content")
        
        let configLoader = MockGitConfigLoader()
        let fileCreator = MockGitFileCreator(shouldThrowOnCopy: true)
        let picker = MockPicker()
        let manager = makeSUT(configLoader: configLoader, fileCreator: fileCreator, picker: picker)
        
        #expect(throws: TestError.fileCreatorError) {
            try manager.addGitFile(
                sourcePath: sourcePath,
                fileName: "test.txt",
                nickname: "Test",
                useDirectPath: false
            )
        }
    }
}


// MARK: - SUT
private extension AddGitFileManagerTests {
    func makeSUT(
        configLoader: MockGitConfigLoader = MockGitConfigLoader(),
        fileCreator: MockGitFileCreator = MockGitFileCreator(),
        picker: MockPicker = MockPicker()
    ) -> AddGitFileManager {
        return AddGitFileManager(
            configLoader: configLoader,
            fileCreator: fileCreator,
            picker: picker
        )
    }
}


// MARK: - Mock Implementations
private class MockGitConfigLoader: GitConfigLoader {
    private(set) var addedGitFile: GitFile?
    private let shouldThrowOnAdd: Bool
    
    init(shouldThrowOnAdd: Bool = false) {
        self.shouldThrowOnAdd = shouldThrowOnAdd
    }
    
    func save(_ config: GitConfig) throws {
        // Not needed for these tests
    }
    
    func loadConfig(picker: CommandLinePicker) throws -> GitConfig {
        // Not needed for these tests
        return GitConfig.defaultConfig
    }
    
    func addGitFile(_ gitFile: GitFile, picker: CommandLinePicker) throws {
        if shouldThrowOnAdd {
            throw TestError.configError
        }
        self.addedGitFile = gitFile
    }
    
    func removeGitFile(named fileName: String, picker: CommandLinePicker) throws -> Bool {
        // Not needed for these tests
        return true
    }
}

private class MockGitFileCreator: GitFileCreator {
    private(set) var copiedSourcePath: String?
    private(set) var copiedFileName: String?
    private let copyResult: String
    private let shouldThrowOnCopy: Bool
    
    init(copyResult: String = "/default/path", shouldThrowOnCopy: Bool = false) {
        self.copyResult = copyResult
        self.shouldThrowOnCopy = shouldThrowOnCopy
    }
    
    func createFile(named fileName: String, sourcePath: String, destinationPath: String?) throws {
        // Not needed for these tests
    }
    
    func createGitFiles(_ gitFiles: [GitFile], destinationPath: String?) throws {
        // Not needed for these tests
    }
    
    func copyToTemplatesDirectory(sourcePath: String, fileName: String, picker: CommandLinePicker) throws -> String {
        if shouldThrowOnCopy {
            throw TestError.fileCreatorError
        }
        self.copiedSourcePath = sourcePath
        self.copiedFileName = fileName
        return copyResult
    }
}

private enum TestError: Error {
    case configError
    case fileCreatorError
}