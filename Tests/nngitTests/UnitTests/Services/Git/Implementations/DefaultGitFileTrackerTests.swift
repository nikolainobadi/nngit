//
//  DefaultGitFileTrackerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/23/25.
//

import Testing
import NnShellKit
import GitShellKit
import GitCommandGen
@testable import nngit

@Suite("DefaultGitFileTracker Tests")
struct DefaultGitFileTrackerTests {
    
    // MARK: - loadUnwantedFiles Tests
    
    @Test("Returns empty array when no tracked files exist.")
    func loadUnwantedFiles_noTrackedFiles() {
        let shell = MockShell(results: [""])
        let tracker = DefaultGitFileTracker(shell: shell)
        let gitignore = "*.log\nbuild/"
        
        let result = tracker.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.isEmpty)
        #expect(shell.executedCommands.contains("git ls-files"))
    }
    
    @Test("Returns empty array when no patterns match.")
    func loadUnwantedFiles_noMatches() {
        let shell = MockShell(results: ["src/main.swift\nREADME.md"])
        let tracker = DefaultGitFileTracker(shell: shell)
        let gitignore = "*.log\nbuild/"
        
        let result = tracker.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.isEmpty)
    }
    
    @Test("Identifies files matching simple patterns.")
    func loadUnwantedFiles_simplePatterns() {
        let shell = MockShell(results: ["debug.log\nerror.log\nsrc/main.swift"])
        let tracker = DefaultGitFileTracker(shell: shell)
        let gitignore = "*.log"
        
        let result = tracker.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.count == 2)
        #expect(result.contains("debug.log"))
        #expect(result.contains("error.log"))
    }
    
    @Test("Handles directory patterns correctly.")
    func loadUnwantedFiles_directoryPatterns() {
        let shell = MockShell(results: ["build/output.txt\nbuild/debug/app\nsrc/main.swift"])
        let tracker = DefaultGitFileTracker(shell: shell)
        let gitignore = "build/"
        
        let result = tracker.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.count == 2)
        #expect(result.contains("build/output.txt"))
        #expect(result.contains("build/debug/app"))
    }
    
    @Test("Handles patterns with wildcards.")
    func loadUnwantedFiles_wildcardPatterns() {
        let shell = MockShell(results: ["test_file.txt\ntest_data.json\nprod_file.txt"])
        let tracker = DefaultGitFileTracker(shell: shell)
        let gitignore = "test_*"
        
        let result = tracker.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.count == 2)
        #expect(result.contains("test_file.txt"))
        #expect(result.contains("test_data.json"))
    }
    
    @Test("Handles double wildcard patterns.")
    func loadUnwantedFiles_doubleWildcardPatterns() {
        let shell = MockShell(results: ["logs/debug.log\nlogs/2024/error.log\nsrc/main.swift"])
        let tracker = DefaultGitFileTracker(shell: shell)
        let gitignore = "logs/**/*.log"
        
        let result = tracker.loadUnwantedFiles(gitignore: gitignore)
        
        // The ** pattern means any number of directories, but "logs/debug.log" 
        // doesn't match "logs/**/*.log" because there's no intermediate directory
        #expect(result.count == 1)
        #expect(result.contains("logs/2024/error.log"))
        
        // Test with a pattern that matches both
        let gitignore2 = "logs/**"
        let shell2 = MockShell(results: ["logs/debug.log\nlogs/2024/error.log\nsrc/main.swift"])
        let tracker2 = DefaultGitFileTracker(shell: shell2)
        let result2 = tracker2.loadUnwantedFiles(gitignore: gitignore2)
        
        #expect(result2.count == 2)
        #expect(result2.contains("logs/debug.log"))
        #expect(result2.contains("logs/2024/error.log"))
    }
    
    @Test("Ignores comments and empty lines in gitignore.")
    func loadUnwantedFiles_ignoresCommentsAndEmptyLines() {
        let shell = MockShell(results: ["debug.log\nerror.log"])
        let tracker = DefaultGitFileTracker(shell: shell)
        let gitignore = """
        # This is a comment
        *.log
        
        # Another comment
        """
        
        let result = tracker.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.count == 2)
        #expect(result.contains("debug.log"))
        #expect(result.contains("error.log"))
    }
    
    @Test("Handles absolute path patterns.")
    func loadUnwantedFiles_absolutePathPatterns() {
        let shell = MockShell(results: ["config.json\nsrc/config.json"])
        let tracker = DefaultGitFileTracker(shell: shell)
        let gitignore = "/config.json"
        
        let result = tracker.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.count == 1)
        #expect(result.contains("config.json"))
    }
    
    @Test("Skips negation patterns.")
    func loadUnwantedFiles_negationPatterns() {
        let shell = MockShell(results: ["important.log\ndebug.log"])
        let tracker = DefaultGitFileTracker(shell: shell)
        let gitignore = """
        *.log
        !important.log
        """
        
        let result = tracker.loadUnwantedFiles(gitignore: gitignore)
        
        // The implementation currently returns false for negation patterns
        // This means files with negation won't be included in unwanted files
        #expect(result.count == 2)
        #expect(result.contains("debug.log"))
        #expect(result.contains("important.log"))
    }
    
    @Test("Handles question mark wildcards.")
    func loadUnwantedFiles_questionMarkWildcards() {
        let shell = MockShell(results: ["file1.txt\nfile2.txt\nfile10.txt"])
        let tracker = DefaultGitFileTracker(shell: shell)
        let gitignore = "file?.txt"
        
        let result = tracker.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.count == 2)
        #expect(result.contains("file1.txt"))
        #expect(result.contains("file2.txt"))
    }
    
    @Test("Handles multiple patterns.")
    func loadUnwantedFiles_multiplePatterns() {
        let shell = MockShell(results: ["debug.log\nbuild/output\ntemp.txt\ncache/data"])
        let tracker = DefaultGitFileTracker(shell: shell)
        let gitignore = """
        *.log
        build/
        temp.*
        cache/
        """
        
        let result = tracker.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.count == 4)
        #expect(result.contains("debug.log"))
        #expect(result.contains("build/output"))
        #expect(result.contains("temp.txt"))
        #expect(result.contains("cache/data"))
    }
    
    // MARK: - stopTrackingFile Tests
    
    @Test("Executes git rm --cached command with proper escaping.")
    func stopTrackingFile_executesCommand() throws {
        let shell = MockShell(results: [""])
        let tracker = DefaultGitFileTracker(shell: shell)
        let file = "src/secret.env"
        
        try tracker.stopTrackingFile(file: file)
        
        #expect(shell.executedCommands.contains("git rm --cached \"src/secret.env\""))
    }
    
    @Test("Handles files with spaces in the name.")
    func stopTrackingFile_filesWithSpaces() throws {
        let shell = MockShell(results: [""])
        let tracker = DefaultGitFileTracker(shell: shell)
        let file = "my file with spaces.txt"
        
        try tracker.stopTrackingFile(file: file)
        
        #expect(shell.executedCommands.contains("git rm --cached \"my file with spaces.txt\""))
    }
    
    @Test("Handles files with special characters.")
    func stopTrackingFile_filesWithSpecialCharacters() throws {
        let shell = MockShell(results: [""])
        let tracker = DefaultGitFileTracker(shell: shell)
        let file = "file$with@special#chars.txt"
        
        try tracker.stopTrackingFile(file: file)
        
        #expect(shell.executedCommands.contains("git rm --cached \"file$with@special#chars.txt\""))
    }
    
    @Test("Throws error when git command fails.")
    func stopTrackingFile_throwsOnError() {
        let shell = MockShell(results: [], shouldThrowError: true)
        let tracker = DefaultGitFileTracker(shell: shell)
        let file = "nonexistent.txt"
        
        #expect(throws: Error.self) {
            try tracker.stopTrackingFile(file: file)
        }
    }
    
    // MARK: - containsUntrackedFiles Tests
    
    @Test("Returns true when there are untracked changes.")
    func containsUntrackedFiles_hasChanges() throws {
        let gitStatusOutput = """
        M  src/main.swift
        ?? new_file.txt
        """
        let shell = MockShell(results: [gitStatusOutput])
        let tracker = DefaultGitFileTracker(shell: shell)
        
        let result = try tracker.containsUntrackedFiles()
        
        #expect(result == true)
        #expect(shell.executedCommands.contains(makeGitCommand(.getLocalChanges, path: nil)))
    }
    
    @Test("Returns false when there are no changes.")
    func containsUntrackedFiles_noChanges() throws {
        let shell = MockShell(results: [""])
        let tracker = DefaultGitFileTracker(shell: shell)
        
        let result = try tracker.containsUntrackedFiles()
        
        #expect(result == false)
        #expect(shell.executedCommands.contains(makeGitCommand(.getLocalChanges, path: nil)))
    }
    
    @Test("Returns true for staged changes only.")
    func containsUntrackedFiles_stagedChangesOnly() throws {
        let gitStatusOutput = "M  src/main.swift"
        let shell = MockShell(results: [gitStatusOutput])
        let tracker = DefaultGitFileTracker(shell: shell)
        
        let result = try tracker.containsUntrackedFiles()
        
        #expect(result == true)
        #expect(shell.executedCommands.contains(makeGitCommand(.getLocalChanges, path: nil)))
    }
    
    @Test("Returns true for untracked files only.")
    func containsUntrackedFiles_untrackedFilesOnly() throws {
        let gitStatusOutput = "?? new_file.txt"
        let shell = MockShell(results: [gitStatusOutput])
        let tracker = DefaultGitFileTracker(shell: shell)
        
        let result = try tracker.containsUntrackedFiles()
        
        #expect(result == true)
        #expect(shell.executedCommands.contains(makeGitCommand(.getLocalChanges, path: nil)))
    }
    
    @Test("Throws error when git command fails.")
    func containsUntrackedFiles_throwsOnError() {
        let shell = MockShell(results: [], shouldThrowError: true)
        let tracker = DefaultGitFileTracker(shell: shell)
        
        #expect(throws: Error.self) {
            try tracker.containsUntrackedFiles()
        }
    }
    
    // MARK: - Integration Tests
    
    @Test("Complete workflow for identifying and untracking files.")
    func integration_completeWorkflow() throws {
        // Setup shell with results for all operations
        let results = [
            // First call to git ls-files for loadUnwantedFiles
            """
            .env
            .DS_Store
            build/output.txt
            src/main.swift
            logs/debug.log
            """,
            // Results for stopTrackingFile calls (4 times)
            "", "", "", ""
        ]
        
        let shell = MockShell(results: results)
        let tracker = DefaultGitFileTracker(shell: shell)
        
        // Setup gitignore
        let gitignore = """
        .env
        .DS_Store
        build/
        *.log
        """
        
        // Get unwanted files
        let unwantedFiles = tracker.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(unwantedFiles.count == 4)
        #expect(unwantedFiles.contains(".env"))
        #expect(unwantedFiles.contains(".DS_Store"))
        #expect(unwantedFiles.contains("build/output.txt"))
        #expect(unwantedFiles.contains("logs/debug.log"))
        
        // Stop tracking each unwanted file
        for file in unwantedFiles {
            try tracker.stopTrackingFile(file: file)
        }
        
        // Verify all commands were executed
        #expect(shell.executedCommands.contains("git rm --cached \".env\""))
        #expect(shell.executedCommands.contains("git rm --cached \".DS_Store\""))
        #expect(shell.executedCommands.contains("git rm --cached \"build/output.txt\""))
        #expect(shell.executedCommands.contains("git rm --cached \"logs/debug.log\""))
    }
}