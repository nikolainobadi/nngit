//
//  StageManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import NnShellKit
import SwiftPicker
import GitShellKit
@testable import nngit

struct StageManagerTests {
    @Test("Successfully stages available files")
    func executeStageWorkflowSuccess() throws {
        let shell = MockShell(results: [" M modified.txt\n?? untracked.txt", ""])
        let picker = MockPicker(selectionResponses: ["Select files to stage:": 0])
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeStageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(shell.executedCommands.contains("git add \"modified.txt\""))
    }
    
    @Test("Handles no files available to stage")
    func executeStageWorkflowNoFiles() throws {
        let shell = MockShell(results: [""]) // Empty git status
        let picker = MockPicker()
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeStageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(!shell.executedCommands.contains { $0.contains("git add") })
    }
    
    @Test("Handles only staged files (no stageable files)")
    func executeStageWorkflowOnlyStagedFiles() throws {
        let shell = MockShell(results: ["A  already_staged.txt"]) // Only staged files
        let picker = MockPicker()
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeStageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(!shell.executedCommands.contains { $0.contains("git add") })
    }
    
    @Test("Handles user cancellation (no selection)")
    func executeStageWorkflowNoSelection() throws {
        let shell = MockShell(results: [" M modified.txt"])
        let picker = MockPicker() // No selection responses = cancellation
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeStageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(!shell.executedCommands.contains { $0.contains("git add") })
    }
    
    @Test("Stages multiple files with user selection")
    func executeStageWorkflowMultipleFiles() throws {
        let shell = MockShell(results: [" M file1.txt\n?? file2.txt\n M file3.txt", ""])
        let picker = MockPicker(selectionResponses: ["Select files to stage:": 0]) // MockPicker only selects first
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeStageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(shell.executedCommands.contains("git add \"file1.txt\""))
    }
    
    @Test("Correctly filters stageable vs non-stageable files")
    func executeStageWorkflowFiltersCorrectly() throws {
        let shell = MockShell(results: ["A  staged.txt\n M modified.txt\n?? untracked.txt", ""])
        let picker = MockPicker(selectionResponses: ["Select files to stage:": 0])
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeStageWorkflow()
        
        // Should only offer modified.txt and untracked.txt for staging (not already staged files)
        #expect(shell.executedCommands.contains("git add \"modified.txt\""))
    }
    
    @Test("Handles files with special characters")
    func executeStageWorkflowSpecialCharacters() throws {
        let shell = MockShell(results: [" M \"file with spaces.txt\"\n?? \"file'with'quotes.txt\"", ""])
        let picker = MockPicker(selectionResponses: ["Select files to stage:": 0])
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeStageWorkflow()
        
        #expect(shell.executedCommands.contains { $0.contains("git add") && $0.contains("file with spaces.txt") })
    }
    
    @Test("Stages untracked files correctly")
    func executeStageWorkflowUntrackedFiles() throws {
        let shell = MockShell(results: ["?? new_file.txt\n?? another_new.txt", ""])
        let picker = MockPicker(selectionResponses: ["Select files to stage:": 0])
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeStageWorkflow()
        
        #expect(shell.executedCommands.contains("git add \"new_file.txt\""))
    }
    
    @Test("Handles mixed file statuses correctly")
    func executeStageWorkflowMixedStatuses() throws {
        let shell = MockShell(results: ["MM both_modified.txt\n M staged_modified.txt\nA  new_staged.txt\n?? untracked.txt", ""])
        let picker = MockPicker(selectionResponses: ["Select files to stage:": 0])
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeStageWorkflow()
        
        // Should stage the first available file (both_modified.txt has unstaged changes)
        #expect(shell.executedCommands.contains("git add \"both_modified.txt\""))
    }
    
    @Test("Handles git command execution correctly")
    func executeStageWorkflowGitCommands() throws {
        let shell = MockShell(results: [" M file1.txt\n M file2.txt", ""])
        let picker = MockPicker(selectionResponses: ["Select files to stage:": 0])
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeStageWorkflow()
        
        // Verify git status is called first
        #expect(shell.executedCommands.first == "git status --porcelain")
        // Verify git add is called with proper quoting
        #expect(shell.executedCommands.contains("git add \"file1.txt\""))
    }
}


// MARK: - SUT
private extension StageManagerTests {
    func makeSUT(shell: MockShell = MockShell(), picker: MockPicker = MockPicker()) -> StageManager {
        
        return .init(shell: shell, picker: picker)
    }
}