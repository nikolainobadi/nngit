//
//  DiscardManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import GitShellKit
import NnShellKit
import SwiftPickerTesting
@testable import nngit

struct DiscardManagerTests {
    @Test("Successfully performs full discard for both scope")
    func performDiscardFullBoth() throws {
        let shell = MockShell(results: [
            "M  file1.txt\nA  file2.txt",  // containsChanges (getLocalChanges)
            "",                            // clearStagedFiles
            ""                             // clearUnstagedFiles
        ])
        let permissionMessage = "Are you sure you want to discard the changes you made in this branch? You cannot undo this action."
        let picker = makePicker(permissionResponses: [permissionMessage: true])
        let manager = makeSUT(shell: shell, picker: picker)
        
        try manager.performDiscard(scope: .both, files: false)
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(shell.executedCommands.contains("git reset --hard HEAD"))
        #expect(shell.executedCommands.contains("git clean -fd"))
        #expect(picker.capturedPermissionPrompts.contains(permissionMessage))
    }
    
    @Test("Successfully performs full discard for staged scope")
    func performDiscardFullStaged() throws {
        let shell = MockShell(results: [
            "M  file1.txt\nA  file2.txt",  // containsChanges
            ""                             // clearStagedFiles
        ])
        let permissionMessage = "Are you sure you want to discard the changes you made in this branch? You cannot undo this action."
        let picker = makePicker(permissionResponses: [permissionMessage: true])
        let manager = makeSUT(shell: shell, picker: picker)
        
        try manager.performDiscard(scope: .staged, files: false)
        
        #expect(shell.executedCommands.contains("git reset --hard HEAD"))
        #expect(!shell.executedCommands.contains("git clean -fd"))
        #expect(picker.capturedPermissionPrompts.contains(permissionMessage))
    }
    
    @Test("Successfully performs full discard for unstaged scope")
    func performDiscardFullUnstaged() throws {
        let shell = MockShell(results: [
            "M  file1.txt\nA  file2.txt",  // containsChanges
            ""                             // clearUnstagedFiles
        ])
        let permissionMessage = "Are you sure you want to discard the changes you made in this branch? You cannot undo this action."
        let picker = makePicker(permissionResponses: [permissionMessage: true])
        let manager = makeSUT(shell: shell, picker: picker)
        
        try manager.performDiscard(scope: .unstaged, files: false)
        
        #expect(!shell.executedCommands.contains("git reset --hard HEAD"))
        #expect(shell.executedCommands.contains("git clean -fd"))
        #expect(picker.capturedPermissionPrompts.contains(permissionMessage))
    }
    
    @Test("Handles no changes detected")
    func performDiscardNoChanges() throws {
        let shell = MockShell(results: [
            ""  // containsChanges (empty)
        ])
        let picker = makePicker()
        let manager = makeSUT(shell: shell, picker: picker)
        
        try manager.performDiscard(scope: .both, files: false)
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(picker.capturedPermissionPrompts.isEmpty)
    }
    
    @Test("Handles user cancellation in full discard")
    func performDiscardUserCancellation() throws {
        let shell = MockShell(results: [
            "M  file1.txt"  // containsChanges
        ])
        let permissionMessage = "Are you sure you want to discard the changes you made in this branch? You cannot undo this action."
        let picker = makePicker(permissionResponses: [permissionMessage: false])
        let manager = makeSUT(shell: shell, picker: picker)
        
        #expect(throws: Error.self) {
            try manager.performDiscard(scope: .both, files: false)
        }
        
        #expect(picker.capturedPermissionPrompts.contains(permissionMessage))
        #expect(!shell.executedCommands.contains("git reset --hard HEAD"))
        #expect(!shell.executedCommands.contains("git clean -fd"))
    }
    
    @Test("Successfully performs file selection discard")
    func performDiscardFileSelection() throws {
        let shell = MockShell(results: [
            "MM file1.txt",                // containsChanges
            "MM file1.txt",                // handleFileSelection (getLocalChanges)
            "",                            // git reset HEAD for file1.txt
            ""                             // git checkout -- for file1.txt
        ])
        let selectionTitle = "Select files to discard changes from:"
        let permissionMessage = "Are you sure you want to discard changes in 1 selected file(s)? You cannot undo this action."
        let picker = makePicker(
            permissionResponses: [permissionMessage: true],
            multiSelectionPrompt: selectionTitle,
            multiSelectionIndices: [0]
        )
        let manager = makeSUT(shell: shell, picker: picker)
        
        try manager.performDiscard(scope: .both, files: true)
        
        #expect(shell.executedCommands.contains("git reset HEAD \"file1.txt\""))
        #expect(shell.executedCommands.contains("git checkout -- \"file1.txt\""))
        #expect(picker.capturedPermissionPrompts.contains(permissionMessage))
    }
    
    @Test("Handles no files match scope in file selection")
    func performDiscardFileSelectionNoMatch() throws {
        let shell = MockShell(results: [
            "M  file1.txt",  // containsChanges
            " M file2.txt"   // handleFileSelection - only unstaged files
        ])
        let picker = makePicker()
        let manager = makeSUT(shell: shell, picker: picker)
        
        try manager.performDiscard(scope: .staged, files: true)  // Looking for staged, but only unstaged available
        
        #expect(picker.capturedPermissionPrompts.isEmpty)
    }
    
    @Test("Handles user cancellation in file selection")
    func performDiscardFileSelectionCancellation() throws {
        let shell = MockShell(results: [
            "M  file1.txt",    // containsChanges
            "M  file1.txt"     // handleFileSelection
        ])
        let selectionTitle = "Select files to discard changes from:"
        let picker = makePicker(
            multiSelectionPrompt: selectionTitle
        )
        let manager = makeSUT(shell: shell, picker: picker)
        
        try manager.performDiscard(scope: .both, files: true)
        
        #expect(picker.capturedPermissionPrompts.isEmpty)  // Should not reach permission step
    }
    
    @Test("Handles untracked files correctly in file selection")
    func performDiscardFileSelectionUntracked() throws {
        let shell = MockShell(results: [
            "?? untracked.txt", // containsChanges
            "?? untracked.txt", // handleFileSelection
            ""                  // git clean -f for untracked file
        ])
        let selectionTitle = "Select files to discard changes from:"
        let permissionMessage = "Are you sure you want to discard changes in 1 selected file(s)? You cannot undo this action."
        let picker = makePicker(
            permissionResponses: [permissionMessage: true],
            multiSelectionPrompt: selectionTitle,
            multiSelectionIndices: [0]
        )
        let manager = makeSUT(shell: shell, picker: picker)
        
        try manager.performDiscard(scope: .unstaged, files: true)
        
        #expect(shell.executedCommands.contains("git clean -f \"untracked.txt\""))
        #expect(!shell.executedCommands.contains("git checkout -- \"untracked.txt\""))
    }
}


// MARK: - SUT
private extension DiscardManagerTests {
    func makeSUT(
        shell: GitShell = MockShell(),
        picker: MockSwiftPicker
    ) -> DiscardManager {
        return DiscardManager(shell: shell, picker: picker)
    }
    
    func makePicker(
        permissionResponses: [String: Bool] = [:],
        multiSelectionPrompt: String? = nil,
        multiSelectionIndices: [Int]? = nil
    ) -> MockSwiftPicker {
        let permissionResult = MockPermissionResult(defaultValue: true, type: .dictionary(permissionResponses))
        let selectionResult = MockSelectionResult(
            defaultSingle: .index(0),
            defaultMulti: .none,
            singleType: .ordered([]),
            multiType: multiSelectionPrompt.map { prompt in
                if let indices = multiSelectionIndices {
                    return .dictionary([prompt: .indices(indices)])
                }
                return .dictionary([prompt: .none])
            } ?? .ordered([])
        )
        
        return MockSwiftPicker(
            inputResult: .init(),
            permissionResult: permissionResult,
            selectionResult: selectionResult,
            treeNavigationResult: .init()
        )
    }
}
