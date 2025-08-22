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
    @Test("Loads all files from git status successfully")
    func loadAllFilesSuccess() throws {
        let shell = MockShell(results: ["M  modified.txt\nA  added.txt\n?? untracked.txt"])
        let manager = makeSUT(shell: shell)
        let result = try manager.loadAllFiles()
        
        #expect(result.count == 3)
        #expect(result.contains { $0.path == "modified.txt" })
        #expect(result.contains { $0.path == "added.txt" })
        #expect(result.contains { $0.path == "untracked.txt" })
    }
    
    @Test("Returns empty array when no files")
    func loadAllFilesEmpty() throws {
        let shell = MockShell(results: [""])
        let manager = makeSUT(shell: shell)
        let result = try manager.loadAllFiles()
        
        #expect(result.isEmpty)
    }
    
    @Test("Filters files that can be staged")
    func filterUnstageableFilesSuccess() {
        let manager = makeSUT()
        let files = [
            FileStatus(path: "modified.txt", stagedStatus: .modified, unstagedStatus: .modified),
            FileStatus(path: "added.txt", stagedStatus: .added, unstagedStatus: .none),
            FileStatus(path: "untracked.txt", stagedStatus: .none, unstagedStatus: .untracked),
            FileStatus(path: "staged_only.txt", stagedStatus: .modified, unstagedStatus: .none)
        ]
        let result = manager.filterUnstageableFiles(files)
        
        #expect(result.count == 2)
        #expect(result.contains { $0.path == "modified.txt" })
        #expect(result.contains { $0.path == "untracked.txt" })
        #expect(!result.contains { $0.path == "added.txt" })
        #expect(!result.contains { $0.path == "staged_only.txt" })
    }
    
    @Test("Returns empty array when no files can be staged")
    func filterUnstageableFilesNone() {
        let manager = makeSUT()
        let files = [
            FileStatus(path: "staged_only.txt", stagedStatus: .modified, unstagedStatus: .none)
        ]
        let result = manager.filterUnstageableFiles(files)
        
        #expect(result.isEmpty)
    }
    
    @Test("Selects files to stage using picker")
    func selectFilesToStageSuccess() {
        let picker = MockPicker(selectionResponses: ["Select files to stage:": 0])
        let manager = makeSUT(picker: picker)
        let files = [
            FileStatus(path: "file1.txt", stagedStatus: .none, unstagedStatus: .modified),
            FileStatus(path: "file2.txt", stagedStatus: .none, unstagedStatus: .untracked)
        ]
        let result = manager.selectFilesToStage(files)
        
        #expect(result.count == 1)
        #expect(result[0].path == "file1.txt")
    }
    
    @Test("Returns empty array when no files selected")
    func selectFilesToStageNone() {
        let picker = MockPicker()
        let manager = makeSUT(picker: picker)
        let files = [
            FileStatus(path: "file1.txt", stagedStatus: .none, unstagedStatus: .modified)
        ]
        let result = manager.selectFilesToStage(files)
        
        #expect(result.isEmpty)
    }
    
    @Test("Stages files successfully")
    func stageFilesSuccess() throws {
        let shell = MockShell()
        let manager = makeSUT(shell: shell)
        let files = [
            FileStatus(path: "file1.txt", stagedStatus: .none, unstagedStatus: .modified),
            FileStatus(path: "file with spaces.txt", stagedStatus: .none, unstagedStatus: .untracked)
        ]
        try manager.stageFiles(files)
        
        #expect(shell.executedCommands.contains("git add \"file1.txt\""))
        #expect(shell.executedCommands.contains("git add \"file with spaces.txt\""))
    }
    
    @Test("Stages no files when array is empty")
    func stageFilesEmpty() throws {
        let shell = MockShell()
        let manager = makeSUT(shell: shell)
        let files: [FileStatus] = []
        try manager.stageFiles(files)
        
        #expect(shell.executedCommands.isEmpty)
    }
    
    @Test("Executes complete stage workflow successfully")
    func executeStageWorkflowSuccess() throws {
        let shell = MockShell(results: [" M modified.txt\n?? untracked.txt", ""])
        let picker = MockPicker(selectionResponses: ["Select files to stage:": 0])
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeStageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(shell.executedCommands.contains("git add \"modified.txt\""))
    }
    
    @Test("Executes workflow with no stageable files")
    func executeStageWorkflowNoStageableFiles() throws {
        let shell = MockShell(results: ["A  already_staged.txt"])
        let picker = MockPicker()
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeStageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(!shell.executedCommands.contains { $0.contains("git add") })
    }
    
    @Test("Executes workflow with no files selected")
    func executeStageWorkflowNoSelection() throws {
        let shell = MockShell(results: ["M  modified.txt"])
        let picker = MockPicker()
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeStageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(!shell.executedCommands.contains { $0.contains("git add") })
    }
    
    @Test("Executes workflow with multiple files selected")
    func executeStageWorkflowMultipleFiles() throws {
        let shell = MockShell(results: [" M file1.txt\n?? file2.txt\n M file3.txt", ""])
        let picker = MockPicker(selectionResponses: ["Select files to stage:": 0]) // MockPicker only selects first item
        let manager = makeSUT(shell: shell, picker: picker)
        try manager.executeStageWorkflow()
        
        #expect(shell.executedCommands.contains("git status --porcelain"))
        #expect(shell.executedCommands.contains("git add \"file1.txt\""))
    }
    
    @Test("Handles files with special characters")
    func stageFilesWithSpecialCharacters() throws {
        let shell = MockShell()
        let manager = makeSUT(shell: shell)
        let files = [
            FileStatus(path: "file with spaces.txt", stagedStatus: .none, unstagedStatus: .modified),
            FileStatus(path: "file'with'quotes.txt", stagedStatus: .none, unstagedStatus: .untracked),
            FileStatus(path: "file&with&ampersand.txt", stagedStatus: .none, unstagedStatus: .modified)
        ]
        try manager.stageFiles(files)
        
        #expect(shell.executedCommands.contains("git add \"file with spaces.txt\""))
        #expect(shell.executedCommands.contains("git add \"file'with'quotes.txt\""))
        #expect(shell.executedCommands.contains("git add \"file&with&ampersand.txt\""))
    }
    
    @Test("Filters untracked files correctly")
    func filterUnstageableFilesUntracked() {
        let manager = makeSUT()
        let files = [
            FileStatus(path: "untracked.txt", stagedStatus: nil, unstagedStatus: .untracked),
            FileStatus(path: "ignored.txt", stagedStatus: nil, unstagedStatus: .ignored)
        ]
        let result = manager.filterUnstageableFiles(files)
        
        #expect(result.count == 2)  // Both untracked and ignored have hasUnstaged = true
        #expect(result.contains { $0.path == "untracked.txt" })
        #expect(result.contains { $0.path == "ignored.txt" })
    }
}


// MARK: - SUT
private extension StageManagerTests {
    func makeSUT(shell: MockShell = MockShell(), picker: MockPicker = MockPicker()) -> StageManager {
        
        return .init(shell: shell, picker: picker)
    }
}