//
//  StopTrackingTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/23/25.
//

import Testing
import Foundation
import NnShellKit
import GitShellKit
import SwiftPicker
@testable import nngit

@MainActor
struct StopTrackingTests {
    @Test("Throws error when not in git repository.")
    func throwsErrorWhenNotInGitRepository() {
        let shell = MockShell(results: [], shouldThrowError: true)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        #expect(throws: Error.self) {
            try Nngit.testRun(context: context, args: ["stop-tracking"])
        }
        
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        #expect(shell.executedCommands.contains(localGitCheck))
    }
    
    @Test("Returns early when no gitignore file exists.")
    func returnsEarlyWhenNoGitignoreExists() throws {
        let results = ["true"] // localGitCheck passes
        let shell = MockShell(results: results)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        // Create a temporary directory without .gitignore for the test
        let tempDir = createTemporaryDirectory()
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        let output = try Nngit.testRun(context: context, args: ["stop-tracking"])
        
        #expect(output.contains("No .gitignore file found in the current directory."))
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        #expect(shell.executedCommands.contains(localGitCheck))
    }
    
    @Test("Returns early when no tracked files match gitignore patterns.")
    func returnsEarlyWhenNoFilesMatch() throws {
        let results = ["true"] // localGitCheck passes
        let shell = MockShell(results: results)
        let picker = MockPicker()
        
        // Use MockGitFileTracker that returns no unwanted files
        let mockTracker = MockGitFileTracker()
        mockTracker.unwantedFiles = []
        let context = MockContextWithTracker(picker: picker, shell: shell, tracker: mockTracker)
        
        // Create temporary gitignore file
        let tempDir = createTemporaryDirectoryWithGitignore("*.log")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        let output = try Nngit.testRun(context: context, args: ["stop-tracking"])
        
        #expect(output.contains("No tracked files match the gitignore patterns."))
        #expect(mockTracker.loadUnwantedFilesCallCount == 1)
    }
    
    @Test("Successfully stops tracking all files when user selects stop all option.")
    func stopsTrackingAllFiles() throws {
        let results = ["true"] // localGitCheck passes
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: ["What would you like to do?": 0])
        
        let mockTracker = MockGitFileTracker()
        mockTracker.unwantedFiles = ["file1.log", "file2.log", ".env"]
        let context = MockContextWithTracker(picker: picker, shell: shell, tracker: mockTracker)
        
        // Create temporary gitignore file
        let tempDir = createTemporaryDirectoryWithGitignore("*.log\n.env")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        let output = try Nngit.testRun(context: context, args: ["stop-tracking"])
        
        #expect(output.contains("Found 3 file(s) that match gitignore patterns but are still tracked."))
        #expect(output.contains("Stopping tracking for 3 file(s)..."))
        #expect(output.contains("✅ Successfully stopped tracking 3 file(s)"))
        #expect(output.contains("Remember to commit these changes to apply them to the repository."))
        #expect(mockTracker.stopTrackingFileCallCount == 3)
    }
    
    @Test("Successfully stops tracking selected files when user chooses specific selection.")
    func stopsTrackingSelectedFiles() throws {
        let results = ["true"] // localGitCheck passes
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: [
            "What would you like to do?": 1,
            "Select files to stop tracking:": 0
        ])
        
        let mockTracker = MockGitFileTracker()
        mockTracker.unwantedFiles = ["file1.log", "file2.log", ".env"]
        let context = MockContextWithTracker(picker: picker, shell: shell, tracker: mockTracker)
        
        // Create temporary gitignore file
        let tempDir = createTemporaryDirectoryWithGitignore("*.log\n.env")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        let output = try Nngit.testRun(context: context, args: ["stop-tracking"])
        
        #expect(output.contains("Found 3 file(s) that match gitignore patterns but are still tracked."))
        #expect(output.contains("Stopping tracking for 1 file(s)..."))
        #expect(output.contains("✅ Successfully stopped tracking 1 file(s)"))
        #expect(mockTracker.stopTrackingFileCallCount == 1)
        #expect(mockTracker.stoppedTrackingFiles.contains("file1.log"))
    }
    
    @Test("Returns early when user selects no files in specific selection.")
    func returnsEarlyWhenNoFilesSelected() throws {
        let results = ["true"] // localGitCheck passes
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: ["What would you like to do?": 1])
        
        let mockTracker = MockGitFileTracker()
        mockTracker.unwantedFiles = ["file1.log", "file2.log"]
        let context = MockContextWithTracker(picker: picker, shell: shell, tracker: mockTracker)
        
        // Create temporary gitignore file
        let tempDir = createTemporaryDirectoryWithGitignore("*.log")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        let output = try Nngit.testRun(context: context, args: ["stop-tracking"])
        
        #expect(output.contains("Found 2 file(s) that match gitignore patterns but are still tracked."))
        #expect(output.contains("No files selected."))
        #expect(mockTracker.stopTrackingFileCallCount == 0)
    }
    
    @Test("Returns early when user cancels operation.")
    func returnsEarlyWhenUserCancels() throws {
        let results = ["true"] // localGitCheck passes
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: ["What would you like to do?": 2])
        
        let mockTracker = MockGitFileTracker()
        mockTracker.unwantedFiles = ["file1.log", "file2.log"]
        let context = MockContextWithTracker(picker: picker, shell: shell, tracker: mockTracker)
        
        // Create temporary gitignore file
        let tempDir = createTemporaryDirectoryWithGitignore("*.log")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        let output = try Nngit.testRun(context: context, args: ["stop-tracking"])
        
        #expect(output.contains("Found 2 file(s) that match gitignore patterns but are still tracked."))
        #expect(output.contains("Operation cancelled."))
        #expect(mockTracker.stopTrackingFileCallCount == 0)
    }
    
    @Test("Handles individual file stop tracking errors gracefully.")
    func handlesIndividualErrors() throws {
        let results = ["true"] // localGitCheck passes
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: ["What would you like to do?": 0])
        
        let mockTracker = MockGitFileTracker()
        mockTracker.unwantedFiles = ["file1.log", "file2.log", "file3.log"]
        mockTracker.filesToFailStopping = ["file2.log"] // This file will fail
        let context = MockContextWithTracker(picker: picker, shell: shell, tracker: mockTracker)
        
        // Create temporary gitignore file
        let tempDir = createTemporaryDirectoryWithGitignore("*.log")
        let originalDir = FileManager.default.currentDirectoryPath
        FileManager.default.changeCurrentDirectoryPath(tempDir)
        
        defer {
            FileManager.default.changeCurrentDirectoryPath(originalDir)
            try? FileManager.default.removeItem(atPath: tempDir)
        }
        
        let output = try Nngit.testRun(context: context, args: ["stop-tracking"])
        
        #expect(output.contains("Found 3 file(s) that match gitignore patterns but are still tracked."))
        #expect(output.contains("Stopping tracking for 3 file(s)..."))
        #expect(output.contains("✅ Successfully stopped tracking 2 file(s)"))
        #expect(output.contains("❌ Failed to stop tracking 1 file(s)"))
        #expect(output.contains("✗ Failed to stop tracking file2.log:"))
        #expect(mockTracker.stopTrackingFileCallCount == 3)
        #expect(mockTracker.stoppedTrackingFiles.contains("file1.log"))
        #expect(!mockTracker.stoppedTrackingFiles.contains("file2.log"))
        #expect(mockTracker.stoppedTrackingFiles.contains("file3.log"))
    }
}


// MARK: - Helper Methods
private extension StopTrackingTests {
    func createTemporaryDirectory() -> String {
        let tempDir = NSTemporaryDirectory().appending("StopTrackingTests_\(UUID().uuidString)")
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


// MARK: - Mock Context with GitFileTracker
private class MockContextWithTracker {
    private let picker: MockPicker
    private let shell: MockShell
    private let tracker: GitFileTracker
    
    init(picker: MockPicker, shell: MockShell, tracker: GitFileTracker) {
        self.picker = picker
        self.shell = shell
        self.tracker = tracker
    }
}

extension MockContextWithTracker: NnGitContext {
    func makePicker() -> CommandLinePicker {
        return picker
    }
    
    func makeShell() -> GitShell {
        return shell
    }
    
    func makeFileTracker() -> GitFileTracker {
        return tracker
    }
    
    func makeCommitManager() -> GitCommitManager {
        return DefaultGitCommitManager(shell: shell)
    }
    
    func makeConfigLoader() -> GitConfigLoader {
        return StubConfigLoader(initialConfig: .defaultConfig)
    }
    
    func makeBranchLoader() -> GitBranchLoader {
        return StubBranchLoader(localBranches: [])
    }
    
    func makeResetHelper() -> GitResetHelper {
        return MockGitResetHelper()
    }
}


// MARK: - Mock GitFileTracker for Tests
private class MockGitFileTracker: GitFileTracker {
    var unwantedFiles: [String] = []
    var stoppedTrackingFiles: [String] = []
    var filesToFailStopping: [String] = []
    var loadUnwantedFilesCallCount = 0
    var stopTrackingFileCallCount = 0
    
    func loadUnwantedFiles(gitignore: String) -> [String] {
        loadUnwantedFilesCallCount += 1
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
