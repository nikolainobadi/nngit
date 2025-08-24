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
    @Test("Returns empty array when no tracked files exist.")
    func loadUnwantedFiles_noTrackedFiles() {
        let (sut, shell) = makeSUT(results: [""])
        let gitignore = "*.log\nbuild/"
        
        let result = sut.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.isEmpty)
        #expect(shell.executedCommands.contains("git ls-files"))
    }
    
    @Test("Returns empty array when no patterns match.")
    func loadUnwantedFiles_noMatches() {
        let (sut, _) = makeSUT(results: ["src/main.swift\nREADME.md"])
        let gitignore = "*.log\nbuild/"
        
        let result = sut.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.isEmpty)
    }
    
    @Test("Identifies files matching simple patterns.")
    func loadUnwantedFiles_simplePatterns() {
        let (sut, _) = makeSUT(results: ["debug.log\nerror.log\nsrc/main.swift"])
        let gitignore = "*.log"
        
        let result = sut.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.count == 2)
        #expect(result.contains("debug.log"))
        #expect(result.contains("error.log"))
    }
    
    @Test("Handles directory patterns correctly.")
    func loadUnwantedFiles_directoryPatterns() {
        let (sut, _) = makeSUT(results: ["build/output.txt\nbuild/debug/app\nsrc/main.swift"])
        let gitignore = "build/"
        
        let result = sut.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.count == 2)
        #expect(result.contains("build/output.txt"))
        #expect(result.contains("build/debug/app"))
    }
    
    @Test("Handles patterns with wildcards.")
    func loadUnwantedFiles_wildcardPatterns() {
        let (sut, _) = makeSUT(results: ["test_file.txt\ntest_data.json\nprod_file.txt"])
        let gitignore = "test_*"
        
        let result = sut.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.count == 2)
        #expect(result.contains("test_file.txt"))
        #expect(result.contains("test_data.json"))
    }
    
    @Test("Handles double wildcard patterns.")
    func loadUnwantedFiles_doubleWildcardPatterns() {
        let (sut, _) = makeSUT(results: ["logs/debug.log\nlogs/2024/error.log\nsrc/main.swift"])
        let gitignore = "logs/**/*.log"
        
        let result = sut.loadUnwantedFiles(gitignore: gitignore)
        
        // The ** pattern means any number of directories, but "logs/debug.log" 
        // doesn't match "logs/**/*.log" because there's no intermediate directory
        #expect(result.count == 1)
        #expect(result.contains("logs/2024/error.log"))
        
        // Test with a pattern that matches both
        let gitignore2 = "logs/**"
        let (sut2, _) = makeSUT(results: ["logs/debug.log\nlogs/2024/error.log\nsrc/main.swift"])
        let result2 = sut2.loadUnwantedFiles(gitignore: gitignore2)
        
        #expect(result2.count == 2)
        #expect(result2.contains("logs/debug.log"))
        #expect(result2.contains("logs/2024/error.log"))
    }
    
    @Test("Ignores comments and empty lines in gitignore.")
    func loadUnwantedFiles_ignoresCommentsAndEmptyLines() {
        let (sut, _) = makeSUT(results: ["debug.log\nerror.log"])
        let gitignore = """
        # This is a comment
        *.log
        
        # Another comment
        """
        
        let result = sut.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.count == 2)
        #expect(result.contains("debug.log"))
        #expect(result.contains("error.log"))
    }
    
    @Test("Handles absolute path patterns.")
    func loadUnwantedFiles_absolutePathPatterns() {
        let (sut, _) = makeSUT(results: ["config.json\nsrc/config.json"])
        let gitignore = "/config.json"
        
        let result = sut.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.count == 1)
        #expect(result.contains("config.json"))
    }
    
    @Test("Skips negation patterns.")
    func loadUnwantedFiles_negationPatterns() {
        let (sut, _) = makeSUT(results: ["important.log\ndebug.log"])
        let gitignore = """
        *.log
        !important.log
        """
        
        let result = sut.loadUnwantedFiles(gitignore: gitignore)
        
        // The implementation currently returns false for negation patterns
        // This means files with negation won't be included in unwanted files
        #expect(result.count == 2)
        #expect(result.contains("debug.log"))
        #expect(result.contains("important.log"))
    }
    
    @Test("Handles question mark wildcards.")
    func loadUnwantedFiles_questionMarkWildcards() {
        let (sut, _) = makeSUT(results: ["file1.txt\nfile2.txt\nfile10.txt"])
        let gitignore = "file?.txt"
        
        let result = sut.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.count == 2)
        #expect(result.contains("file1.txt"))
        #expect(result.contains("file2.txt"))
    }
    
    @Test("Handles multiple patterns.")
    func loadUnwantedFiles_multiplePatterns() {
        let (sut, _) = makeSUT(results: ["debug.log\nbuild/output\ntemp.txt\ncache/data"])
        let gitignore = """
        *.log
        build/
        temp.*
        cache/
        """
        
        let result = sut.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(result.count == 4)
        #expect(result.contains("debug.log"))
        #expect(result.contains("build/output"))
        #expect(result.contains("temp.txt"))
        #expect(result.contains("cache/data"))
    }
    
    // MARK: - stopTrackingFile Tests
    
    @Test("Executes git rm --cached command with proper escaping.")
    func stopTrackingFile_executesCommand() throws {
        let (sut, shell) = makeSUT(results: [""])
        let file = "src/secret.env"
        
        try sut.stopTrackingFile(file: file)
        
        #expect(shell.executedCommands.contains("git rm --cached \"src/secret.env\""))
    }
    
    @Test("Handles files with spaces in the name.")
    func stopTrackingFile_filesWithSpaces() throws {
        let (sut, shell) = makeSUT(results: [""])
        let file = "my file with spaces.txt"
        
        try sut.stopTrackingFile(file: file)
        
        #expect(shell.executedCommands.contains("git rm --cached \"my file with spaces.txt\""))
    }
    
    @Test("Handles files with special characters.")
    func stopTrackingFile_filesWithSpecialCharacters() throws {
        let (sut, shell) = makeSUT(results: [""])
        let file = "file$with@special#chars.txt"
        
        try sut.stopTrackingFile(file: file)
        
        #expect(shell.executedCommands.contains("git rm --cached \"file$with@special#chars.txt\""))
    }
    
    @Test("Throws error when git command fails.")
    func stopTrackingFile_throwsOnError() {
        let (sut, _) = makeSUT(results: [], shouldThrowError: true)
        let file = "nonexistent.txt"
        
        #expect(throws: Error.self) {
            try sut.stopTrackingFile(file: file)
        }
    }
    
    // MARK: - containsUntrackedFiles Tests
    
    @Test("Returns true when there are untracked changes.")
    func containsUntrackedFiles_hasChanges() throws {
        let gitStatusOutput = """
        M  src/main.swift
        ?? new_file.txt
        """
        let (sut, shell) = makeSUT(results: [gitStatusOutput])
        
        let result = try sut.containsUntrackedFiles()
        
        #expect(result == true)
        #expect(shell.executedCommands.contains(makeGitCommand(.getLocalChanges, path: nil)))
    }
    
    @Test("Returns false when there are no changes.")
    func containsUntrackedFiles_noChanges() throws {
        let (sut, shell) = makeSUT(results: [""])
        
        let result = try sut.containsUntrackedFiles()
        
        #expect(result == false)
        #expect(shell.executedCommands.contains(makeGitCommand(.getLocalChanges, path: nil)))
    }
    
    @Test("Returns true for staged changes only.")
    func containsUntrackedFiles_stagedChangesOnly() throws {
        let gitStatusOutput = "M  src/main.swift"
        let (sut, shell) = makeSUT(results: [gitStatusOutput])
        
        let result = try sut.containsUntrackedFiles()
        
        #expect(result == true)
        #expect(shell.executedCommands.contains(makeGitCommand(.getLocalChanges, path: nil)))
    }
    
    @Test("Returns true for untracked files only.")
    func containsUntrackedFiles_untrackedFilesOnly() throws {
        let gitStatusOutput = "?? new_file.txt"
        let (sut, shell) = makeSUT(results: [gitStatusOutput])
        
        let result = try sut.containsUntrackedFiles()
        
        #expect(result == true)
        #expect(shell.executedCommands.contains(makeGitCommand(.getLocalChanges, path: nil)))
    }
    
    @Test("Throws error when git command fails.")
    func containsUntrackedFiles_throwsOnError() {
        let (sut, _) = makeSUT(results: [], shouldThrowError: true)
        
        #expect(throws: Error.self) {
            try sut.containsUntrackedFiles()
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
        
        let (sut, shell) = makeSUT(results: results)
        
        // Setup gitignore
        let gitignore = """
        .env
        .DS_Store
        build/
        *.log
        """
        
        // Get unwanted files
        let unwantedFiles = sut.loadUnwantedFiles(gitignore: gitignore)
        
        #expect(unwantedFiles.count == 4)
        #expect(unwantedFiles.contains(".env"))
        #expect(unwantedFiles.contains(".DS_Store"))
        #expect(unwantedFiles.contains("build/output.txt"))
        #expect(unwantedFiles.contains("logs/debug.log"))
        
        // Stop tracking each unwanted file
        for file in unwantedFiles {
            try sut.stopTrackingFile(file: file)
        }
        
        // Verify all commands were executed
        #expect(shell.executedCommands.contains("git rm --cached \".env\""))
        #expect(shell.executedCommands.contains("git rm --cached \".DS_Store\""))
        #expect(shell.executedCommands.contains("git rm --cached \"build/output.txt\""))
        #expect(shell.executedCommands.contains("git rm --cached \"logs/debug.log\""))
    }
}


// MARK: - SUT
private extension DefaultGitFileTrackerTests {
    func makeSUT(results: [String] = [], shouldThrowError: Bool = false) -> (sut: DefaultGitFileTracker, shell: MockShell) {
        let shell = MockShell(results: results, shouldThrowError: shouldThrowError)
        let sut = DefaultGitFileTracker(shell: shell)
        
        return (sut, shell)
    }
}
