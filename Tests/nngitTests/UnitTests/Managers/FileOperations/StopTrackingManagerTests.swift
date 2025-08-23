//
//  StopTrackingManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/23/25.
//

import Testing
import Foundation
import NnShellKit
import GitShellKit
@testable import nngit

@Suite("StopTrackingManager Tests")
struct StopTrackingManagerTests {
    
    // MARK: - stopTrackingIgnoredFiles Tests
    
    @Test("Throws error when not in git repository.")
    func stopTrackingIgnoredFiles_notInGitRepository() {
        let (sut, _) = makeSUTWithThrowingShell()
        
        #expect(throws: Error.self) {
            try sut.stopTrackingIgnoredFiles()
        }
    }
    
    @Test("Returns early when no gitignore file exists.")
    func stopTrackingIgnoredFiles_noGitignoreFile() throws {
        let (sut, _) = makeSUTWithResults(["true"]) // Simulate git repo exists
        
        // Create a temporary directory without .gitignore
        let tempDir = createTemporaryDirectory()
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        try sut.stopTrackingIgnoredFiles()
        
        // Should complete without throwing
        #expect(Bool(true))
    }
    
    @Test("Returns early when no files match gitignore patterns.")
    func stopTrackingIgnoredFiles_noMatchingFiles() throws {
        let (sut, _, _, tracker) = makeSUTWithMockTracker(results: ["true"])
        
        // Mock tracker to return no unwanted files
        let mockTracker = tracker as! MockGitFileTracker
        mockTracker.unwantedFiles = []
        
        // Create temporary gitignore
        let tempDir = createTemporaryDirectoryWithGitignore("*.log")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        try sut.stopTrackingIgnoredFiles()
        
        #expect(mockTracker.loadUnwantedFilesCallCount == 1)
    }
    
    @Test("Stops tracking all files when user selects stop all option.")
    func stopTrackingIgnoredFiles_stopAllFiles() throws {
        // Response index 0 = "Stop tracking all files"
        let selectionResponses = ["What would you like to do?": 0]
        let (sut, _, _, tracker) = makeSUTWithMockTracker(
            results: ["true", "", "", ""],
            selectionResponses: selectionResponses
        )
        
        let mockTracker = tracker as! MockGitFileTracker
        mockTracker.unwantedFiles = ["file1.log", "file2.log", ".env"]
        
        // Create temporary gitignore
        let tempDir = createTemporaryDirectoryWithGitignore("*.log\n.env")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        try sut.stopTrackingIgnoredFiles()
        
        #expect(mockTracker.stopTrackingFileCallCount == 3)
        #expect(mockTracker.stoppedTrackingFiles.contains("file1.log"))
        #expect(mockTracker.stoppedTrackingFiles.contains("file2.log"))
        #expect(mockTracker.stoppedTrackingFiles.contains(".env"))
    }
    
    @Test("Stops tracking selected files when user chooses specific selection.")
    func stopTrackingIgnoredFiles_selectSpecificFiles() throws {
        // Response index 1 = "Select specific files to stop tracking"
        let selectionResponses = [
            "What would you like to do?": 1,
            "Select files to stop tracking:": 0 // Will select first file due to MockPicker implementation
        ]
        let (sut, _, _, tracker) = makeSUTWithMockTracker(
            results: ["true", "", ""],
            selectionResponses: selectionResponses
        )
        
        let mockTracker = tracker as! MockGitFileTracker
        mockTracker.unwantedFiles = ["file1.log", "file2.log", ".env"]
        
        // Create temporary gitignore
        let tempDir = createTemporaryDirectoryWithGitignore("*.log\n.env")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        try sut.stopTrackingIgnoredFiles()
        
        #expect(mockTracker.stopTrackingFileCallCount == 1)
        #expect(mockTracker.stoppedTrackingFiles.contains("file1.log"))
    }
    
    @Test("Returns early when user selects no files in specific selection.")
    func stopTrackingIgnoredFiles_selectNoFiles() throws {
        // Index 1 = "Select specific files", but no selectionResponses for multiSelection means empty return
        let selectionResponses = ["What would you like to do?": 1]
        let (sut, _, _, tracker) = makeSUTWithMockTracker(
            results: ["true"],
            selectionResponses: selectionResponses
        )
        
        let mockTracker = tracker as! MockGitFileTracker
        mockTracker.unwantedFiles = ["file1.log", "file2.log"]
        
        // Create temporary gitignore
        let tempDir = createTemporaryDirectoryWithGitignore("*.log")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        try sut.stopTrackingIgnoredFiles()
        
        #expect(mockTracker.stopTrackingFileCallCount == 0)
    }
    
    @Test("Returns early when user cancels operation.")
    func stopTrackingIgnoredFiles_userCancels() throws {
        // Response index 2 = "Cancel"
        let selectionResponses = ["What would you like to do?": 2]
        let (sut, _, _, tracker) = makeSUTWithMockTracker(
            results: ["true"],
            selectionResponses: selectionResponses
        )
        
        let mockTracker = tracker as! MockGitFileTracker
        mockTracker.unwantedFiles = ["file1.log", "file2.log"]
        
        // Create temporary gitignore
        let tempDir = createTemporaryDirectoryWithGitignore("*.log")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        try sut.stopTrackingIgnoredFiles()
        
        #expect(mockTracker.stopTrackingFileCallCount == 0)
    }
    
    @Test("Handles errors when stopping individual files.")
    func stopTrackingIgnoredFiles_handlesIndividualErrors() throws {
        // Response index 0 = "Stop tracking all files"
        let selectionResponses = ["What would you like to do?": 0]
        let (sut, _, _, tracker) = makeSUTWithMockTracker(
            results: ["true", "", "", ""],
            selectionResponses: selectionResponses
        )
        
        let mockTracker = tracker as! MockGitFileTracker
        mockTracker.unwantedFiles = ["file1.log", "file2.log", "file3.log"]
        mockTracker.filesToFailStopping = ["file2.log"] // This file will fail
        
        // Create temporary gitignore
        let tempDir = createTemporaryDirectoryWithGitignore("*.log")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        try sut.stopTrackingIgnoredFiles()
        
        #expect(mockTracker.stopTrackingFileCallCount == 3)
        #expect(mockTracker.stoppedTrackingFiles.contains("file1.log"))
        #expect(!mockTracker.stoppedTrackingFiles.contains("file2.log")) // Should not be in success list
        #expect(mockTracker.stoppedTrackingFiles.contains("file3.log"))
    }
    
    @Test("Reads gitignore file contents correctly.")
    func stopTrackingIgnoredFiles_readsGitignoreCorrectly() throws {
        // Response index 2 = "Cancel"
        let selectionResponses = ["What would you like to do?": 2]
        let (sut, _, _, tracker) = makeSUTWithMockTracker(
            results: ["true"],
            selectionResponses: selectionResponses
        )
        
        let mockTracker = tracker as! MockGitFileTracker
        mockTracker.unwantedFiles = []
        
        let gitignoreContent = """
        *.log
        .env
        build/
        # Comment
        temp.*
        """
        
        // Create temporary gitignore with specific content
        let tempDir = createTemporaryDirectoryWithGitignore(gitignoreContent)
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        try sut.stopTrackingIgnoredFiles()
        
        #expect(mockTracker.loadUnwantedFilesCallCount == 1)
        #expect(mockTracker.lastGitignoreContent == gitignoreContent)
    }
}


// MARK: - SUT Factory
private extension StopTrackingManagerTests {
    func makeSUT() -> (sut: StopTrackingManager, shell: MockShell) {
        let shell = MockShell(results: [])
        let picker = MockPicker()
        let tracker = DefaultGitFileTracker(shell: shell)
        let sut = StopTrackingManager(shell: shell, picker: picker, tracker: tracker)
        
        return (sut, shell)
    }
    
    func makeSUTWithResults(_ results: [String]) -> (sut: StopTrackingManager, shell: MockShell) {
        let shell = MockShell(results: results)
        let picker = MockPicker()
        let tracker = DefaultGitFileTracker(shell: shell)
        let sut = StopTrackingManager(shell: shell, picker: picker, tracker: tracker)
        
        return (sut, shell)
    }
    
    func makeSUTWithThrowingShell() -> (sut: StopTrackingManager, shell: MockShell) {
        let shell = MockShell(results: [], shouldThrowError: true)
        let picker = MockPicker()
        let tracker = DefaultGitFileTracker(shell: shell)
        let sut = StopTrackingManager(shell: shell, picker: picker, tracker: tracker)
        
        return (sut, shell)
    }
    
    func makeSUTWithMockTracker(
        results: [String] = [],
        selectionResponses: [String: Int] = [:]
    ) -> (sut: StopTrackingManager, shell: MockShell, picker: MockPicker, tracker: GitFileTracker) {
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: selectionResponses)
        let tracker = MockGitFileTracker()
        let sut = StopTrackingManager(shell: shell, picker: picker, tracker: tracker)
        
        return (sut, shell, picker, tracker)
    }
}


// MARK: - Test Helpers
private extension StopTrackingManagerTests {
    func createTemporaryDirectory() -> String {
        let tempDir = NSTemporaryDirectory().appending("StopTrackingManagerTests_\(UUID().uuidString)")
        try! FileManager.default.createDirectory(atPath: tempDir, withIntermediateDirectories: true)
        return tempDir
    }
    
    func createTemporaryDirectoryWithGitignore(_ content: String) -> String {
        let tempDir = createTemporaryDirectory()
        let gitignorePath = tempDir.appending("/.gitignore")
        try! content.write(toFile: gitignorePath, atomically: true, encoding: .utf8)
        return tempDir
    }
}


// MARK: - Mock GitFileTracker
private class MockGitFileTracker: GitFileTracker {
    var unwantedFiles: [String] = []
    var stoppedTrackingFiles: [String] = []
    var filesToFailStopping: [String] = []
    var loadUnwantedFilesCallCount = 0
    var stopTrackingFileCallCount = 0
    var lastGitignoreContent: String?
    
    func loadUnwantedFiles(gitignore: String) -> [String] {
        loadUnwantedFilesCallCount += 1
        lastGitignoreContent = gitignore
        return unwantedFiles
    }
    
    func stopTrackingFile(file: String) throws {
        stopTrackingFileCallCount += 1
        
        if filesToFailStopping.contains(file) {
            throw TestError.stopTrackingFailed
        }
        
        stoppedTrackingFiles.append(file)
    }
    
    func containsUntrackedFiles() throws -> Bool {
        return true
    }
    
    enum TestError: Error {
        case stopTrackingFailed
        
        var localizedDescription: String {
            switch self {
            case .stopTrackingFailed:
                return "Failed to stop tracking file"
            }
        }
    }
}