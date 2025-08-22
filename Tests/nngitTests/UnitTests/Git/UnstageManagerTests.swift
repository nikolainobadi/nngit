//
//  UnstageManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import NnShellKit
import SwiftPicker
import GitShellKit
@testable import nngit

struct UnstageManagerTests {
    @Test("Successfully unstages available files")
    func executeUnstageWorkflowSuccess() throws {
        let shell = MockShell(results: ["A  added.txt\nM  modified.txt", ""])
        let picker = MockPicker(selectionResponses: ["Select files to unstage:": 0])
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeUnstageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(shell.executedCommands.contains("git reset HEAD \"added.txt\""))
    }
    
    @Test("Handles no staged files available to unstage")
    func executeUnstageWorkflowNoStagedFiles() throws {
        let shell = MockShell(results: [" M modified.txt\n?? untracked.txt"])
        let picker = MockPicker()
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeUnstageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(!shell.executedCommands.contains { $0.contains("git reset HEAD") })
    }
    
    @Test("Handles only unstaged files (no stageable files)")
    func executeUnstageWorkflowOnlyUnstagedFiles() throws {
        let shell = MockShell(results: [" M unstaged_only.txt"])
        let picker = MockPicker()
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeUnstageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(!shell.executedCommands.contains { $0.contains("git reset HEAD") })
    }
    
    @Test("Handles user cancellation (no selection)")
    func executeUnstageWorkflowNoSelection() throws {
        let shell = MockShell(results: ["A  added.txt"])
        let picker = MockPicker() // No selection responses = cancellation
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeUnstageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(!shell.executedCommands.contains { $0.contains("git reset HEAD") })
    }
    
    @Test("Unstages multiple files with user selection")
    func executeUnstageWorkflowMultipleFiles() throws {
        let shell = MockShell(results: ["A  file1.txt\nM  file2.txt\nD  file3.txt", ""])
        let picker = MockPicker(selectionResponses: ["Select files to unstage:": 0]) // MockPicker only selects first
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeUnstageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(shell.executedCommands.contains("git reset HEAD \"file1.txt\""))
    }
    
    @Test("Correctly filters staged vs non-staged files")
    func executeUnstageWorkflowFiltersCorrectly() throws {
        let shell = MockShell(results: [" M unstaged.txt\nA  staged.txt\n?? untracked.txt", ""])
        let picker = MockPicker(selectionResponses: ["Select files to unstage:": 0])
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeUnstageWorkflow()
        
        // Should only offer staged.txt for unstaging (not unstaged or untracked files)
        #expect(shell.executedCommands.contains("git reset HEAD \"staged.txt\""))
    }
    
    @Test("Handles files with special characters")
    func executeUnstageWorkflowSpecialCharacters() throws {
        let shell = MockShell(results: ["A  \"file with spaces.txt\"\nM  \"file'with'quotes.txt\"", ""])
        let picker = MockPicker(selectionResponses: ["Select files to unstage:": 0])
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeUnstageWorkflow()
        
        #expect(shell.executedCommands.contains { $0.contains("git reset HEAD") && $0.contains("file with spaces.txt") })
    }
    
    @Test("Handles mixed file statuses correctly")
    func executeUnstageWorkflowMixedStatuses() throws {
        let shell = MockShell(results: ["MM both_modified.txt\nA  new_staged.txt\n M unstaged_only.txt\n?? untracked.txt", ""])
        let picker = MockPicker(selectionResponses: ["Select files to unstage:": 0])
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeUnstageWorkflow()
        
        // Should unstage the first available file (both_modified.txt has staged changes)
        #expect(shell.executedCommands.contains("git reset HEAD \"both_modified.txt\""))
    }
    
    @Test("Handles git command execution correctly")
    func executeUnstageWorkflowGitCommands() throws {
        let shell = MockShell(results: ["A  file1.txt\nM  file2.txt", ""])
        let picker = MockPicker(selectionResponses: ["Select files to unstage:": 0])
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeUnstageWorkflow()
        
        // Verify git status is called first
        #expect(shell.executedCommands.first == "git status --porcelain")
        // Verify git reset is called with proper quoting
        #expect(shell.executedCommands.contains("git reset HEAD \"file1.txt\""))
    }
}


// MARK: - SUT
private extension UnstageManagerTests {
    func makeSUT(shell: MockShell = MockShell(), picker: MockPicker = MockPicker()) -> UnstageManager {
        
        return .init(shell: shell, picker: picker)
    }
}