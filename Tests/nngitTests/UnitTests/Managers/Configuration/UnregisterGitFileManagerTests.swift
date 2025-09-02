//
//  UnregisterGitFileManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 9/2/25.
//

import Testing
import Foundation
import SwiftPicker
@testable import nngit

final class UnregisterGitFileManagerTests {
    private let tempDirectory: URL
    private let fileManager = FileManager.default
    
    init() {
        // Create unique temp directory for this test instance
        tempDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("UnregisterGitFileManagerTests-\(UUID().uuidString)")
        try! fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    deinit {
        // Clean up entire temp directory
        try? fileManager.removeItem(at: tempDirectory)
    }
}


// MARK: - Tests
extension UnregisterGitFileManagerTests {
    @Test("Successfully unregisters file by exact filename match.")
    func unregisterByExactFilename() throws {
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt"),
            GitFile(fileName: "readme.md", nickname: "Readme", localPath: "/templates/readme.md")
        ]
        let (sut, configLoader, _, picker) = makeSUT(gitFiles: gitFiles)
        picker.addPermissionResponse("Remove git file 'Test File (test.txt)'?", response: true)
        picker.addBooleanResponse("Delete template file from disk as well?", response: false)
        
        try sut.unregisterGitFile(templateName: "test.txt", removeAll: false)
        
        #expect(configLoader.removedFileName == "test.txt")
    }
    
    @Test("Successfully unregisters file by nickname match.")
    func unregisterByNickname() throws {
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt"),
            GitFile(fileName: "readme.md", nickname: "Readme", localPath: "/templates/readme.md")
        ]
        let (sut, configLoader, _, picker) = makeSUT(gitFiles: gitFiles)
        picker.addPermissionResponse("Remove git file 'Readme (readme.md)'?", response: true)
        picker.addBooleanResponse("Delete template file from disk as well?", response: false)
        
        try sut.unregisterGitFile(templateName: "Readme", removeAll: false)
        
        #expect(configLoader.removedFileName == "readme.md")
    }
    
    @Test("Successfully unregisters file by case-insensitive filename match.")
    func unregisterByCaseInsensitiveFilename() throws {
        let gitFiles = [
            GitFile(fileName: "Test.TXT", nickname: "Test File", localPath: "/templates/Test.TXT")
        ]
        let (sut, configLoader, _, picker) = makeSUT(gitFiles: gitFiles)
        picker.addPermissionResponse("Remove git file 'Test File (Test.TXT)'?", response: true)
        picker.addBooleanResponse("Delete template file from disk as well?", response: false)
        
        try sut.unregisterGitFile(templateName: "test.txt", removeAll: false)
        
        #expect(configLoader.removedFileName == "Test.TXT")
    }
    
    @Test("Successfully unregisters file by case-insensitive nickname match.")
    func unregisterByCaseInsensitiveNickname() throws {
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt")
        ]
        let (sut, configLoader, _, picker) = makeSUT(gitFiles: gitFiles)
        picker.addPermissionResponse("Remove git file 'Test File (test.txt)'?", response: true)
        picker.addBooleanResponse("Delete template file from disk as well?", response: false)
        
        try sut.unregisterGitFile(templateName: "test file", removeAll: false)
        
        #expect(configLoader.removedFileName == "test.txt")
    }
    
    @Test("Prompts for selection when no template name provided.")
    func promptsForSelection() throws {
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt"),
            GitFile(fileName: "readme.md", nickname: "Readme", localPath: "/templates/readme.md")
        ]
        let (sut, configLoader, _, picker) = makeSUT(gitFiles: gitFiles)
        picker.addSelectionResponse("Select a git file to unregister:", response: 1) // Select second file
        picker.addPermissionResponse("Remove git file 'Readme (readme.md)'?", response: true)
        picker.addBooleanResponse("Delete template file from disk as well?", response: false)
        
        try sut.unregisterGitFile(templateName: nil, removeAll: false)
        
        #expect(configLoader.removedFileName == "readme.md")
    }
    
    @Test("Deletes template file from disk when requested.")
    func deletesTemplateFileWhenRequested() throws {
        let templatePath = tempDirectory.appendingPathComponent("test.txt")
        try "test content".write(to: templatePath, atomically: true, encoding: .utf8)
        
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: templatePath.path)
        ]
        let (sut, configLoader, _, picker) = makeSUT(gitFiles: gitFiles)
        picker.addPermissionResponse("Remove git file 'Test File (test.txt)'?", response: true)
        picker.addBooleanResponse("Delete template file from disk as well?", response: true)
        
        #expect(fileManager.fileExists(atPath: templatePath.path))
        
        try sut.unregisterGitFile(templateName: "test.txt", removeAll: false)
        
        #expect(configLoader.removedFileName == "test.txt")
        #expect(!fileManager.fileExists(atPath: templatePath.path))
    }
    
    @Test("Handles template file deletion failure gracefully.")
    func handlesTemplateDeletionFailure() throws {
        // Use a path that doesn't exist
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/nonexistent/path/test.txt")
        ]
        let (sut, configLoader, _, picker) = makeSUT(gitFiles: gitFiles)
        picker.addPermissionResponse("Remove git file 'Test File (test.txt)'?", response: true)
        picker.addBooleanResponse("Delete template file from disk as well?", response: true)
        
        // Should not throw even if file doesn't exist
        try sut.unregisterGitFile(templateName: "test.txt", removeAll: false)
        
        #expect(configLoader.removedFileName == "test.txt")
    }
    
    @Test("Successfully removes all files with --all flag.")
    func removesAllFiles() throws {
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt"),
            GitFile(fileName: "readme.md", nickname: "Readme", localPath: "/templates/readme.md"),
            GitFile(fileName: "config.json", nickname: "Config", localPath: "/templates/config.json")
        ]
        let (sut, configLoader, _, picker) = makeSUT(gitFiles: gitFiles)
        picker.addPermissionResponse("Are you sure you want to remove all 3 registered git files?", response: true)
        picker.addBooleanResponse("Delete template files from disk as well?", response: false)
        
        try sut.unregisterGitFile(templateName: nil, removeAll: true)
        
        let savedConfig = try #require(configLoader.savedConfig)
        #expect(savedConfig.gitFiles.isEmpty)
    }
    
    @Test("Removes all files and deletes templates when requested.")
    func removesAllFilesAndDeletesTemplates() throws {
        // Create actual template files
        let template1 = tempDirectory.appendingPathComponent("test.txt")
        let template2 = tempDirectory.appendingPathComponent("readme.md")
        try "content1".write(to: template1, atomically: true, encoding: .utf8)
        try "content2".write(to: template2, atomically: true, encoding: .utf8)
        
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: template1.path),
            GitFile(fileName: "readme.md", nickname: "Readme", localPath: template2.path)
        ]
        let (sut, configLoader, _, picker) = makeSUT(gitFiles: gitFiles)
        picker.addPermissionResponse("Are you sure you want to remove all 2 registered git files?", response: true)
        picker.addBooleanResponse("Delete template files from disk as well?", response: true)
        
        #expect(fileManager.fileExists(atPath: template1.path))
        #expect(fileManager.fileExists(atPath: template2.path))
        
        try sut.unregisterGitFile(templateName: nil, removeAll: true)
        
        let savedConfig = try #require(configLoader.savedConfig)
        #expect(savedConfig.gitFiles.isEmpty)
        #expect(!fileManager.fileExists(atPath: template1.path))
        #expect(!fileManager.fileExists(atPath: template2.path))
    }
    
    @Test("Throws error when no files are registered.")
    func throwsErrorWhenNoFiles() {
        let (sut, _, _, _) = makeSUT(gitFiles: [])
        
        #expect(throws: UnregisterGitFileError.noRegisteredFiles) {
            try sut.unregisterGitFile(templateName: "test.txt", removeAll: false)
        }
    }
    
    @Test("Throws error when specified file not found.")
    func throwsErrorWhenFileNotFound() {
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt")
        ]
        let (sut, _, _, _) = makeSUT(gitFiles: gitFiles)
        
        #expect(throws: UnregisterGitFileError.fileNotFound("nonexistent.txt")) {
            try sut.unregisterGitFile(templateName: "nonexistent.txt", removeAll: false)
        }
    }
    
    @Test("Throws error when user cancels single file deletion.")
    func throwsErrorOnSingleFileCancellation() {
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt")
        ]
        let (sut, _, _, picker) = makeSUT(gitFiles: gitFiles)
        picker.addPermissionResponse("Remove git file 'Test File (test.txt)'?", response: false)
        
        #expect(throws: UnregisterGitFileError.deletionCancelled) {
            try sut.unregisterGitFile(templateName: "test.txt", removeAll: false)
        }
    }
    
    @Test("Throws error when user cancels selection.")
    func throwsErrorOnSelectionCancellation() {
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt")
        ]
        let (sut, _, _, picker) = makeSUT(gitFiles: gitFiles)
        picker.addSelectionResponse("Select a git file to unregister:", response: nil) // Cancel selection
        
        #expect(throws: UnregisterGitFileError.deletionCancelled) {
            try sut.unregisterGitFile(templateName: nil, removeAll: false)
        }
    }
    
    @Test("Throws error when user cancels all files deletion.")
    func throwsErrorOnAllFilesCancellation() {
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt")
        ]
        let (sut, _, _, picker) = makeSUT(gitFiles: gitFiles)
        picker.addPermissionResponse("Are you sure you want to remove all 1 registered git files?", response: false)
        
        #expect(throws: UnregisterGitFileError.deletionCancelled) {
            try sut.unregisterGitFile(templateName: nil, removeAll: true)
        }
    }
    
    @Test("Handles missing config loader remove response correctly.")
    func handlesMissingConfigLoaderRemove() throws {
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt")
        ]
        let (sut, configLoader, _, picker) = makeSUT(gitFiles: gitFiles)
        configLoader.removeResult = false // Simulate remove returning false
        picker.addPermissionResponse("Remove git file 'Test File (test.txt)'?", response: true)
        picker.addBooleanResponse("Delete template file from disk as well?", response: false)
        
        #expect(throws: UnregisterGitFileError.fileNotFound("test.txt")) {
            try sut.unregisterGitFile(templateName: "test.txt", removeAll: false)
        }
    }
}


// MARK: - Helper Methods
private extension UnregisterGitFileManagerTests {
    func makeSUT(gitFiles: [GitFile] = []) -> (UnregisterGitFileManager, MockGitConfigLoader, MockGitFileCreator, MockPicker) {
        let configLoader = MockGitConfigLoader(mockGitFiles: gitFiles)
        let fileCreator = MockGitFileCreator()
        let picker = MockPicker()
        let sut = UnregisterGitFileManager(
            configLoader: configLoader,
            fileCreator: fileCreator,
            picker: picker
        )
        return (sut, configLoader, fileCreator, picker)
    }
}