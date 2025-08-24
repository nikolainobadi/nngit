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

final class AddGitFileManagerTests {
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
}
    

// MARK: - Tests
extension AddGitFileManagerTests {
    @Test("Successfully adds GitFile with all parameters provided and direct path.")
    func addGitFileWithAllParametersDirectPath() throws {
        let sourcePath = try createTempFile(named: "test.txt")
        let (sut, configLoader, _) = makeSUT()
        
        try sut.addGitFile(
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
        let (sut, configLoader, _) = makeSUT(copyPath: copyPath)
        
        try sut.addGitFile(
            sourcePath: sourcePath,
            fileName: "test.txt",
            nickname: "Test File",
            useDirectPath: false
        )
        
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.fileName == "test.txt")
        #expect(addedFile.nickname == "Test File")
        #expect(addedFile.localPath == copyPath)
    }
    
    @Test("Prompts for source path when not provided.")
    func addGitFilePromptsForSourcePath() throws {
        let sourcePath = try createTempFile(named: "prompted.txt", content: "content")
        let (sut, configLoader, _) = makeSUT(requiredInputResponses: ["Enter path to template file:": sourcePath])
        
        try sut.addGitFile(
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
        let (sut, _, _) = makeSUT()
        
        #expect(throws: AddGitFileError.sourceFileNotFound("nonexistent.txt")) {
            try sut.addGitFile(
                sourcePath: "nonexistent.txt",
                fileName: "test.txt",
                nickname: "Test",
                useDirectPath: true
            )
        }
    }
    
    @Test("Throws error when prompted source file does not exist.")
    func addGitFileThrowsWhenPromptedSourceFileNotFound() {
        let (sut, _, _) = makeSUT(requiredInputResponses: ["Enter path to template file:": "nonexistent.txt"])

        #expect(throws: AddGitFileError.sourceFileNotFound("nonexistent.txt")) {
            try sut.addGitFile(
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
        let (sut, configLoader, _) = makeSUT(requiredInputResponses: ["Output filename (leave blank for 'source.txt'):": ""])
        
        try sut.addGitFile(
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
        let (sut, configLoader, _) = makeSUT(requiredInputResponses: ["Output filename (leave blank for 'source.txt'):": "custom.txt"])
        
        try sut.addGitFile(
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
        let (sut, configLoader, _) = makeSUT(requiredInputResponses: ["Display name (leave blank for 'test.txt'):": ""])
        
        try sut.addGitFile(
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
        let (sut, configLoader, _) = makeSUT(requiredInputResponses: ["Display name (leave blank for 'test.txt'):": "Custom Name"])
        
        try sut.addGitFile(
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
        let (sut, configLoader, _) = makeSUT(copyPath: copyPath)
        
        try sut.addGitFile(
            sourcePath: sourcePath,
            fileName: "copied.txt",
            nickname: "Copied File",
            useDirectPath: false
        )
        
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.localPath == copyPath)
    }
    
    @Test("Propagates errors from config loader.")
    func addGitFilePropagatesConfigLoaderErrors() throws {
        let sourcePath = try createTempFile(named: "test.txt", content: "content")
        let (sut, _, _) = makeSUT(shouldThrowOnAdd: true)
        
        #expect(throws: MockGitConfigLoader.TestError.configError) {
            try sut.addGitFile(
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
        let (sut, _, _) = makeSUT(shouldThrowOnCopy: true)
        
        #expect(throws: MockGitConfigLoader.TestError.fileCreatorError) {
            try sut.addGitFile(
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
    func makeSUT(copyPath: String? = nil, requiredInputResponses: [String: String] = [:], shouldThrowOnAdd: Bool = false, shouldThrowOnCopy: Bool = false) -> (sut: AddGitFileManager, configLoader: MockGitConfigLoader, fileCreator: MockGitFileCreator) {
        let configLoader = MockGitConfigLoader(shouldThrowOnAdd: shouldThrowOnAdd)
        let fileCreator = MockGitFileCreator(copyResult: copyPath, shouldThrowOnCopy: shouldThrowOnCopy)
        let picker = MockPicker(requiredInputResponses: requiredInputResponses)
        let sut = AddGitFileManager(configLoader: configLoader, fileCreator: fileCreator, picker: picker)
        
        return (sut, configLoader, fileCreator)
    }
    
    func tempPath(for fileName: String) -> String {
        return tempDirectory.appendingPathComponent(fileName).path
    }
    
    func createTempFile(named name: String, content: String = "test content") throws -> String {
        let path = tempDirectory.appendingPathComponent(name).path
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }
}

