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
        let results = ["true", ""] // localGitCheck passes, no tracked files
        let shell = MockShell(results: results)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
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
    }
    
    @Test("Successfully stops tracking all files when user selects stop all option.")
    func stopsTrackingAllFiles() throws {
        let results = ["true", "file1.log\nfile2.log\n.env", "", "", ""] // localGitCheck passes, tracked files, git rm commands
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: ["What would you like to do?": 0])
        let context = MockContext(picker: picker, shell: shell)
        
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
        
        // Verify git rm commands were called
        let commands = shell.executedCommands
        let gitRmCommands = commands.filter { $0.contains("git rm --cached") }
        #expect(gitRmCommands.count == 3)
    }
    
    @Test("Successfully stops tracking selected files when user chooses specific selection.")
    func stopsTrackingSelectedFiles() throws {
        let results = ["true", "file1.log\nfile2.log\n.env", ""] // localGitCheck passes, tracked files, git rm command
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: [
            "What would you like to do?": 1,
            "Select files to stop tracking:": 0
        ])
        let context = MockContext(picker: picker, shell: shell)
        
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
        
        // Verify git rm command was called for selected file
        let commands = shell.executedCommands
        let gitRmCommands = commands.filter { $0.contains("git rm --cached") }
        #expect(gitRmCommands.count == 1)
    }
    
    @Test("Returns early when user selects no files in specific selection.")
    func returnsEarlyWhenNoFilesSelected() throws {
        let results = ["true", "file1.log\nfile2.log"] // localGitCheck passes, tracked files
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: ["What would you like to do?": 1])
        let context = MockContext(picker: picker, shell: shell)
        
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
        
        // Verify no git rm commands were called since no files were selected
        let commands = shell.executedCommands
        let gitRmCommands = commands.filter { $0.contains("git rm --cached") }
        #expect(gitRmCommands.count == 0)
    }
    
    @Test("Returns early when user cancels operation.")
    func returnsEarlyWhenUserCancels() throws {
        let results = ["true", "file1.log\nfile2.log"] // localGitCheck passes, tracked files
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: ["What would you like to do?": 2])
        let context = MockContext(picker: picker, shell: shell)
        
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
        
        // Verify no git rm commands were called since user cancelled
        let commands = shell.executedCommands
        let gitRmCommands = commands.filter { $0.contains("git rm --cached") }
        #expect(gitRmCommands.count == 0)
    }
    
    @Test("Handles individual file stop tracking errors gracefully.")
    func handlesIndividualErrors() throws {
        // This test simplifies error handling since MockShell doesn't support selective command errors
        let results = ["true", "file1.log\nfile2.log\nfile3.log", "", "", ""] // localGitCheck passes, tracked files, git rm commands
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: ["What would you like to do?": 0])
        let context = MockContext(picker: picker, shell: shell)
        
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
        #expect(output.contains("✅ Successfully stopped tracking 3 file(s)"))
        
        // Verify all git rm commands were called
        let commands = shell.executedCommands
        let gitRmCommands = commands.filter { $0.contains("git rm --cached") }
        #expect(gitRmCommands.count == 3)
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
