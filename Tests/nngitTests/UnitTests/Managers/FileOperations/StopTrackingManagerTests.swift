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

@Suite("StopTrackingManager Tests", .serialized)
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
        // Mock tracker to return no unwanted files
        let mockTracker = MockGitFileTracker(unwantedFiles: [])
        let (sut, _, _, tracker) = makeSUTWithMockTracker(results: ["true"], tracker: mockTracker)
        
        // Create temporary gitignore
        let tempDir = createTemporaryDirectoryWithGitignore("*.log")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        try sut.stopTrackingIgnoredFiles()
        
        #expect(tracker.loadUnwantedFilesCallCount == 1)
    }
    
    @Test("Stops tracking all files when user selects stop all option.")
    func stopTrackingIgnoredFiles_stopAllFiles() throws {
        // Response index 0 = "Stop tracking all files"
        let selectionResponses = ["What would you like to do?": 0]
        let mockTracker = MockGitFileTracker(unwantedFiles: ["file1.log", "file2.log", ".env"])
        let (sut, _, _, tracker) = makeSUTWithMockTracker(
            results: ["true", "", "", ""],
            selectionResponses: selectionResponses,
            tracker: mockTracker
        )
        
        // Create temporary gitignore
        let tempDir = createTemporaryDirectoryWithGitignore("*.log\n.env")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        try sut.stopTrackingIgnoredFiles()
        
        #expect(tracker.stopTrackingFileCallCount == 3)
        #expect(tracker.stoppedTrackingFiles.contains("file1.log"))
        #expect(tracker.stoppedTrackingFiles.contains("file2.log"))
        #expect(tracker.stoppedTrackingFiles.contains(".env"))
    }
    
    @Test("Stops tracking selected files when user chooses specific selection.")
    func stopTrackingIgnoredFiles_selectSpecificFiles() throws {
        // Response index 1 = "Select specific files to stop tracking"
        let selectionResponses = [
            "What would you like to do?": 1,
            "Select files to stop tracking:": 0 // Will select first file due to MockPicker implementation
        ]
        let mockTracker = MockGitFileTracker(unwantedFiles: ["file1.log", "file2.log", ".env"])
        let (sut, _, _, tracker) = makeSUTWithMockTracker(
            results: ["true", "", "", ""],
            selectionResponses: selectionResponses,
            tracker: mockTracker
        )
        
        // Create temporary gitignore
        let tempDir = createTemporaryDirectoryWithGitignore("*.log\n.env")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        try sut.stopTrackingIgnoredFiles()
        
        #expect(tracker.stopTrackingFileCallCount == 1)
        #expect(tracker.stoppedTrackingFiles.contains("file1.log"))
    }
    
    @Test("Returns early when user selects no files in specific selection.")
    func stopTrackingIgnoredFiles_selectNoFiles() throws {
        // Index 1 = "Select specific files", but no selectionResponses for multiSelection means empty return
        let selectionResponses = ["What would you like to do?": 1]
        let mockTracker = MockGitFileTracker(unwantedFiles: ["file1.log", "file2.log"])
        let (sut, _, _, tracker) = makeSUTWithMockTracker(
            results: ["true"],
            selectionResponses: selectionResponses,
            tracker: mockTracker
        )
        
        // Create temporary gitignore
        let tempDir = createTemporaryDirectoryWithGitignore("*.log")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        try sut.stopTrackingIgnoredFiles()
        
        #expect(tracker.stopTrackingFileCallCount == 0)
    }
    
    @Test("Returns early when user cancels operation.")
    func stopTrackingIgnoredFiles_userCancels() throws {
        // Response index 2 = "Cancel"
        let selectionResponses = ["What would you like to do?": 2]
        let mockTracker = MockGitFileTracker(unwantedFiles: ["file1.log", "file2.log"])
        let (sut, _, _, tracker) = makeSUTWithMockTracker(
            results: ["true"],
            selectionResponses: selectionResponses,
            tracker: mockTracker
        )
        
        // Create temporary gitignore
        let tempDir = createTemporaryDirectoryWithGitignore("*.log")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        try sut.stopTrackingIgnoredFiles()
        
        #expect(tracker.stopTrackingFileCallCount == 0)
    }
    
    @Test("Handles errors when stopping individual files.")
    func stopTrackingIgnoredFiles_handlesIndividualErrors() throws {
        // Response index 0 = "Stop tracking all files"
        let selectionResponses = ["What would you like to do?": 0]
        let mockTracker = MockGitFileTracker(
            unwantedFiles: ["file1.log", "file2.log", "file3.log"],
            filesToFailStopping: ["file2.log"] // This file will fail
        )
        let (sut, _, _, tracker) = makeSUTWithMockTracker(
            results: ["true", "", "", ""],
            selectionResponses: selectionResponses,
            tracker: mockTracker
        )
        
        // Create temporary gitignore
        let tempDir = createTemporaryDirectoryWithGitignore("*.log")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        try sut.stopTrackingIgnoredFiles()
        
        #expect(tracker.stopTrackingFileCallCount == 3)
        #expect(tracker.stoppedTrackingFiles.contains("file1.log"))
        #expect(!tracker.stoppedTrackingFiles.contains("file2.log")) // Should not be in success list
        #expect(tracker.stoppedTrackingFiles.contains("file3.log"))
    }
    
    @Test("Reads gitignore file contents correctly.")
    func stopTrackingIgnoredFiles_readsGitignoreCorrectly() throws {
        // Response index 2 = "Cancel"
        let selectionResponses = ["What would you like to do?": 2]
        let mockTracker = MockGitFileTracker(unwantedFiles: [])
        let (sut, _, _, tracker) = makeSUTWithMockTracker(
            results: ["true"],
            selectionResponses: selectionResponses,
            tracker: mockTracker
        )
        
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
        
        #expect(tracker.loadUnwantedFilesCallCount == 1)
        #expect(tracker.lastGitignoreContent == gitignoreContent)
    }
}


// MARK: - SUT Factory
private extension StopTrackingManagerTests {
    func makeSUT() -> (sut: StopTrackingManager, shell: MockShell) {
        // Provide enough mock results to handle any shell commands that might be called
        let safeResults = Array(repeating: "", count: 10)
        let shell = MockShell(results: safeResults)
        let picker = MockPicker()
        let tracker = DefaultGitFileTracker(shell: shell)
        let sut = StopTrackingManager(shell: shell, picker: picker, tracker: tracker)
        
        return (sut, shell)
    }
    
    func makeSUTWithResults(_ results: [String]) -> (sut: StopTrackingManager, shell: MockShell) {
        // Provide enough mock results to handle any shell commands that might be called
        let safeResults = results + Array(repeating: "", count: 10)
        let shell = MockShell(results: safeResults)
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
        selectionResponses: [String: Int] = [:],
        tracker: MockGitFileTracker
    ) -> (sut: StopTrackingManager, shell: MockShell, picker: MockPicker, tracker: MockGitFileTracker) {
        // Provide enough mock results to handle any shell commands that might be called
        let safeResults = results + Array(repeating: "", count: 10)
        let shell = MockShell(results: safeResults)
        let picker = MockPicker(selectionResponses: selectionResponses)
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

