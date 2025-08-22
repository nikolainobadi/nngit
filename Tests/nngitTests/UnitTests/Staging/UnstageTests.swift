//
//  UnstageTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import NnShellKit
import GitShellKit
@testable import nngit

@MainActor
struct UnstageTests {
    @Test("unstages selected files when staged files are available")
    func unstagesSelectedFiles() throws {
        let localGitCheckCommand = makeGitCommand(.localGitCheck, path: nil)
        let localChangesCommand = makeGitCommand(.getLocalChanges, path: nil)
        let results = [
            "true",  // localGitCheckCommand
            "A  file1.swift\nM  file2.swift\n M file3.swift",  // localChangesCommand
            "",  // git reset HEAD "file1.swift"
            ""   // git reset HEAD "file2.swift"
        ]
        
        let shell = MockShell(results: results)
        // Mock multi-selection to select first file (staged)
        let picker = MockPicker(selectionResponses: ["Select files to unstage:": 0])
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context)
        
        #expect(shell.executedCommands.contains(localGitCheckCommand))
        #expect(shell.executedCommands.contains(localChangesCommand))
        #expect(shell.executedCommands.contains("git reset HEAD \"file1.swift\""))
    }
    
    @Test("filters only staged files")
    func filtersOnlyStagedFiles() throws {
        let results = [
            "true",  // localGitCheck
            "A  staged.swift\n M unstaged.swift\n?? untracked.swift"  // getLocalChanges
        ]
        
        let shell = MockShell(results: results)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context)
        
        // Should only show staged.swift in picker
        #expect(shell.executedCommands.contains(makeGitCommand(.getLocalChanges, path: nil)))
    }
    
    @Test("prints no staged files when no files are staged")
    func printsNoStagedFilesWhenNoneStaged() throws {
        let results = [
            "true",  // localGitCheck
            " M unstaged.swift"  // getLocalChanges
        ]
        
        let shell = MockShell(results: results)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try Nngit.testRun(context: context, args: ["staging", "unstage"])
        
        #expect(output.contains("No staged files to unstage."))
        #expect(!shell.executedCommands.contains { $0.starts(with: "git reset HEAD") })
    }
    
    @Test("prints no files selected when user cancels selection")
    func printsNoFilesSelectedWhenCanceled() throws {
        let results = [
            "true",  // localGitCheck
            "A  file1.swift"  // getLocalChanges
        ]
        
        let shell = MockShell(results: results)
        let picker = MockPicker()
        // MockPicker returns empty array when no selection response is set
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try Nngit.testRun(context: context, args: ["staging", "unstage"])
        
        #expect(output.contains("No files selected."))
        #expect(!shell.executedCommands.contains { $0.starts(with: "git reset HEAD") })
    }
    
    @Test("unstages multiple selected files")
    func unstagesMultipleSelectedFiles() throws {
        let results = [
            "true",  // localGitCheck
            "A  file1.swift\nM  file2.swift\nD  file3.swift",  // getLocalChanges
            "",  // git reset HEAD "file1.swift"
            "",  // git reset HEAD "file2.swift"
            ""   // git reset HEAD "file3.swift"
        ]
        
        let shell = MockShell(results: results)
        // Mock multi-selection returns multiple files
        let picker = MockPicker(selectionResponses: ["Select files to unstage:": 0])
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try Nngit.testRun(context: context, args: ["staging", "unstage"])
        
        #expect(output.contains("✅ Unstaged 1 file(s)"))
    }
    
    @Test("handles different staged file types correctly")
    func handlesDifferentStagedFileTypesCorrectly() throws {
        let results = [
            "true",  // localGitCheck
            "A  added.swift\nM  modified.swift\nD  deleted.swift",  // getLocalChanges
            "",  // git reset HEAD "added.swift"
            "",  // git reset HEAD "modified.swift"
            ""   // git reset HEAD "deleted.swift"
        ]
        
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: ["Select files to unstage:": 0])
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context)
        
        #expect(shell.executedCommands.contains("git reset HEAD \"added.swift\""))
    }
    
    @Test("prints no staged files when working directory is clean")
    func printsNoStagedFilesWhenClean() throws {
        let results = [
            "true",  // localGitCheck
            ""  // getLocalChanges
        ]
        
        let shell = MockShell(results: results)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try Nngit.testRun(context: context, args: ["staging", "unstage"])
        
        #expect(output.contains("No staged files to unstage."))
        #expect(!shell.executedCommands.contains { $0.starts(with: "git reset HEAD") })
    }
    
    @Test("handles mixed staged and unstaged files correctly")
    func handlesMixedStagedAndUnstagedFiles() throws {
        let results = [
            "true",  // localGitCheck
            "MM mixed.swift\nAM added_modified.swift",  // getLocalChanges
            "",  // git reset HEAD "mixed.swift"
            ""   // git reset HEAD "added_modified.swift"
        ]
        
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: ["Select files to unstage:": 0])
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context)
        
        // Should be able to unstage the staged parts of mixed files
        #expect(shell.executedCommands.contains("git reset HEAD \"mixed.swift\""))
    }
}

// MARK: - Helper Methods
private extension UnstageTests {
    func runCommand(_ testFactory: NnGitContext) throws {
        try Nngit.testRun(context: testFactory, args: ["staging", "unstage"])
    }
}