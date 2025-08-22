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
    @Test("Loads all files from git status successfully")
    func loadAllFilesSuccess() throws {
        let shell = MockShell(results: ["A  added.txt\n M modified.txt\n?? untracked.txt"])
        let manager = makeSUT(shell: shell)
        let result = try manager.loadAllFiles()
        
        #expect(result.count == 3)
        #expect(result.contains { $0.path == "added.txt" })
        #expect(result.contains { $0.path == "modified.txt" })
        #expect(result.contains { $0.path == "untracked.txt" })
    }
    
    @Test("Returns empty array when no files")
    func loadAllFilesEmpty() throws {
        let shell = MockShell(results: [""])
        let manager = makeSUT(shell: shell)
        let result = try manager.loadAllFiles()
        
        #expect(result.isEmpty)
    }
    
    @Test("Filters files that are staged")
    func filterStagedFilesSuccess() {
        let manager = makeSUT()
        let files = [
            FileStatus(path: "staged.txt", stagedStatus: .added, unstagedStatus: .none),
            FileStatus(path: "modified.txt", stagedStatus: .modified, unstagedStatus: .modified),
            FileStatus(path: "untracked.txt", stagedStatus: .none, unstagedStatus: .untracked),
            FileStatus(path: "unstaged_only.txt", stagedStatus: .none, unstagedStatus: .modified)
        ]
        let result = manager.filterStagedFiles(files)
        
        #expect(result.count == 2)
        #expect(result.contains { $0.path == "staged.txt" })
        #expect(result.contains { $0.path == "modified.txt" })
        #expect(!result.contains { $0.path == "untracked.txt" })
        #expect(!result.contains { $0.path == "unstaged_only.txt" })
    }
    
    @Test("Returns empty array when no files are staged")
    func filterStagedFilesNone() {
        let manager = makeSUT()
        let files = [
            FileStatus(path: "untracked.txt", stagedStatus: .none, unstagedStatus: .untracked),
            FileStatus(path: "unstaged.txt", stagedStatus: .none, unstagedStatus: .modified)
        ]
        let result = manager.filterStagedFiles(files)
        
        #expect(result.isEmpty)
    }
    
    @Test("Selects files to unstage using picker")
    func selectFilesToUnstageSuccess() {
        let picker = MockPicker(selectionResponses: ["Select files to unstage:": 0])
        let manager = makeSUT(picker: picker)
        let files = [
            FileStatus(path: "file1.txt", stagedStatus: .added, unstagedStatus: .none),
            FileStatus(path: "file2.txt", stagedStatus: .modified, unstagedStatus: .none)
        ]
        let result = manager.selectFilesToUnstage(files)
        
        #expect(result.count == 1)
        #expect(result[0].path == "file1.txt")
    }
    
    @Test("Returns empty array when no files selected")
    func selectFilesToUnstageNone() {
        let picker = MockPicker()
        let manager = makeSUT(picker: picker)
        let files = [
            FileStatus(path: "file1.txt", stagedStatus: .added, unstagedStatus: .none)
        ]
        let result = manager.selectFilesToUnstage(files)
        
        #expect(result.isEmpty)
    }
    
    @Test("Unstages files successfully")
    func unstageFilesSuccess() throws {
        let shell = MockShell()
        let manager = makeSUT(shell: shell)
        let files = [
            FileStatus(path: "file1.txt", stagedStatus: .added, unstagedStatus: .none),
            FileStatus(path: "file with spaces.txt", stagedStatus: .modified, unstagedStatus: .none)
        ]
        try manager.unstageFiles(files)
        
        #expect(shell.executedCommands.contains("git reset HEAD \"file1.txt\""))
        #expect(shell.executedCommands.contains("git reset HEAD \"file with spaces.txt\""))
    }
    
    @Test("Unstages no files when array is empty")
    func unstageFilesEmpty() throws {
        let shell = MockShell()
        let manager = makeSUT(shell: shell)
        let files: [FileStatus] = []
        try manager.unstageFiles(files)
        
        #expect(shell.executedCommands.isEmpty)
    }
    
    @Test("Executes complete unstage workflow successfully")
    func executeUnstageWorkflowSuccess() throws {
        let shell = MockShell(results: ["A  added.txt\nM  modified.txt", ""])
        let picker = MockPicker(selectionResponses: ["Select files to unstage:": 0])
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeUnstageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(shell.executedCommands.contains("git reset HEAD \"added.txt\""))
    }
    
    @Test("Executes workflow with no staged files")
    func executeUnstageWorkflowNoStagedFiles() throws {
        let shell = MockShell(results: [" M modified.txt\n?? untracked.txt"])
        let picker = MockPicker()
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeUnstageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(!shell.executedCommands.contains { $0.contains("git reset HEAD") })
    }
    
    @Test("Executes workflow with no files selected")
    func executeUnstageWorkflowNoSelection() throws {
        let shell = MockShell(results: ["A  added.txt"])
        let picker = MockPicker()
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeUnstageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(!shell.executedCommands.contains { $0.contains("git reset HEAD") })
    }
    
    @Test("Executes workflow with multiple staged files")
    func executeUnstageWorkflowMultipleFiles() throws {
        let shell = MockShell(results: ["A  file1.txt\nM  file2.txt\nD  file3.txt", ""])
        let picker = MockPicker(selectionResponses: ["Select files to unstage:": 0]) // MockPicker only selects first item
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeUnstageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(shell.executedCommands.contains("git reset HEAD \"file1.txt\""))
    }
    
    @Test("Handles files with special characters")
    func unstageFilesWithSpecialCharacters() throws {
        let shell = MockShell()
        let manager = makeSUT(shell: shell)
        let files = [
            FileStatus(path: "file with spaces.txt", stagedStatus: .added, unstagedStatus: .none),
            FileStatus(path: "file'with'quotes.txt", stagedStatus: .modified, unstagedStatus: .none),
            FileStatus(path: "file&with&ampersand.txt", stagedStatus: .deleted, unstagedStatus: .none)
        ]
        try manager.unstageFiles(files)
        
        #expect(shell.executedCommands.contains("git reset HEAD \"file with spaces.txt\""))
        #expect(shell.executedCommands.contains("git reset HEAD \"file'with'quotes.txt\""))
        #expect(shell.executedCommands.contains("git reset HEAD \"file&with&ampersand.txt\""))
    }
    
    @Test("Filters mixed staged and unstaged files correctly")
    func filterStagedFilesMixed() {
        let manager = makeSUT()
        let files = [
            FileStatus(path: "both.txt", stagedStatus: .modified, unstagedStatus: .modified),
            FileStatus(path: "staged_only.txt", stagedStatus: .added, unstagedStatus: .none),
            FileStatus(path: "unstaged_only.txt", stagedStatus: .none, unstagedStatus: .modified),
            FileStatus(path: "deleted.txt", stagedStatus: .deleted, unstagedStatus: .none)
        ]
        let result = manager.filterStagedFiles(files)
        
        #expect(result.count == 3)
        #expect(result.contains { $0.path == "both.txt" })
        #expect(result.contains { $0.path == "staged_only.txt" })
        #expect(result.contains { $0.path == "deleted.txt" })
        #expect(!result.contains { $0.path == "unstaged_only.txt" })
    }
}


// MARK: - SUT
private extension UnstageManagerTests {
    func makeSUT(shell: MockShell = MockShell(), picker: MockPicker = MockPicker()) -> UnstageManager {
        
        return .init(shell: shell, picker: picker)
    }
}