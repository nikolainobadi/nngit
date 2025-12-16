//
//  NewBranchManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import GitShellKit
import NnShellTesting
import SwiftPickerTesting
@testable import nngit

struct NewBranchManagerTests {
    @Test("Pushes changes when branch is ahead and user confirms.")
    func handleRemoteRepositoryAheadUserConfirms() throws {
        let currentBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .ahead)
        let permissionResponses = [aheadPrompt(for: "main"): true]
        let (sut, shell, picker) = makeSUT(localBranches: [currentBranch], permissionResponses: permissionResponses)
        
        try sut.handleRemoteRepository()
        
        #expect(shell.executedCommands.contains("git push"))
        #expect(picker.capturedPermissionPrompts.count == 1)
    }
    
    @Test("Throws error when branch is ahead and user denies push.")
    func handleRemoteRepositoryAheadUserDenies() throws {
        let currentBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .ahead)
        let permissionResponses = [aheadPrompt(for: "main"): false]
        let (sut, shell, picker) = makeSUT(localBranches: [currentBranch], permissionResponses: permissionResponses)
        
        #expect(throws: (any Error).self) {
            try sut.handleRemoteRepository()
        }
        
        #expect(!shell.executedCommands.contains("git push"))
        #expect(picker.capturedPermissionPrompts.count == 1)
    }
    
    @Test("Merges changes when branch is behind and user selects merge.")
    func handleRemoteRepositoryBehindUserSelectsMerge() throws {
        let currentBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .behind)
        let selectionResponses = [defaultBranchBehindPrompt("main"): 0] // First option (merge)
        let (sut, shell, _) = makeSUT(localBranches: [currentBranch], selectionResponses: selectionResponses)
        
        try sut.handleRemoteRepository()
        
        #expect(shell.executedCommands.contains("git pull"))
    }
    
    @Test("Rebases changes when branch is behind and user selects rebase.")
    func handleRemoteRepositoryBehindUserSelectsRebase() throws {
        let currentBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .behind)
        let selectionResponses = [defaultBranchBehindPrompt("main"): 1] // Second option (rebase)
        let (sut, shell, _) = makeSUT(localBranches: [currentBranch], selectionResponses: selectionResponses)
        
        try sut.handleRemoteRepository()
        
        #expect(shell.executedCommands.contains("git pull --rebase"))
    }
    
    @Test("Works with custom default branch name.")
    func handleRemoteRepositoryCustomDefaultBranch() throws {
        let currentBranch = GitBranch(name: "develop", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .ahead)
        let permissionResponses = [aheadPrompt(for: "develop"): true]
        let (sut, shell, picker) = makeSUT(localBranches: [currentBranch], defaultBranch: "develop", permissionResponses: permissionResponses)
        
        try sut.handleRemoteRepository()
        
        #expect(shell.executedCommands.contains("git push"))
        #expect(picker.capturedPermissionPrompts.contains(aheadPrompt(for: "develop")))
    }
    
    @Test("Throws error when branch has diverged.")
    func handleRemoteRepositoryDiverged() throws {
        let currentBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .diverged)
        let (sut, shell, _) = makeSUT(localBranches: [currentBranch])
        
        #expect(throws: NewBranchError.self) {
            try sut.handleRemoteRepository()
        }
        
        #expect(shell.executedCommands.isEmpty)
    }
    
    @Test("Throws error when branch status is undetermined.")
    func handleRemoteRepositoryUndetermined() throws {
        let currentBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let (sut, shell, _) = makeSUT(localBranches: [currentBranch])
        
        #expect(throws: NewBranchError.self) {
            try sut.handleRemoteRepository()
        }
        
        #expect(shell.executedCommands.isEmpty)
    }
    
    @Test("Allows new branch creation when default branch has no remote branch.")
    func handleRemoteRepositoryNoRemoteBranchDefaultBranch() throws {
        let currentBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .noRemoteBranch)
        let (sut, shell, _) = makeSUT(localBranches: [currentBranch])
        
        try sut.handleRemoteRepository()
        
        #expect(shell.executedCommands.isEmpty)
    }
    
    @Test("Allows new branch creation when non-default branch has no remote.")
    func handleRemoteRepositoryNoRemoteBranchNonDefaultBranch() throws {
        let currentBranch = GitBranch(name: "feature-branch", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .noRemoteBranch)
        let (sut, shell, _) = makeSUT(localBranches: [currentBranch])
        
        try sut.handleRemoteRepository()
        
        #expect(shell.executedCommands.isEmpty)
    }
    
    @Test("Pushes changes when non-default branch is ahead and user confirms.")
    func handleRemoteRepositoryNonDefaultBranchAheadUserConfirms() throws {
        let currentBranch = GitBranch(name: "feature-branch", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .ahead)
        let permissionResponses = [aheadPrompt(for: "feature-branch"): true]
        let (sut, shell, picker) = makeSUT(localBranches: [currentBranch], permissionResponses: permissionResponses)
        
        try sut.handleRemoteRepository()
        
        #expect(shell.executedCommands.contains("git push"))
        #expect(picker.capturedPermissionPrompts.count == 1)
    }
    
    @Test("Throws error when non-default branch is ahead and user denies push.")
    func handleRemoteRepositoryNonDefaultBranchAheadUserDenies() throws {
        let currentBranch = GitBranch(name: "feature-branch", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .ahead)
        let permissionResponses = [aheadPrompt(for: "feature-branch"): false]
        let (sut, shell, picker) = makeSUT(localBranches: [currentBranch], permissionResponses: permissionResponses)
        
        #expect(throws: (any Error).self) {
            try sut.handleRemoteRepository()
        }
        
        #expect(!shell.executedCommands.contains("git push"))
        #expect(picker.capturedPermissionPrompts.count == 1)
    }
    
    @Test("Rebases non-default branch when behind and user confirms.")
    func handleRemoteRepositoryNonDefaultBranchBehindUserConfirms() throws {
        let currentBranch = GitBranch(name: "feature-branch", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .behind)
        let permissionResponses = [nonDefaultBehindPrompt("feature-branch"): true]
        let (sut, shell, picker) = makeSUT(localBranches: [currentBranch], permissionResponses: permissionResponses)
        
        try sut.handleRemoteRepository()
        
        #expect(shell.executedCommands.contains("git pull --rebase"))
        #expect(picker.capturedPermissionPrompts.count == 1)
    }
    
    @Test("Throws error when non-default branch is behind and user denies rebase.")
    func handleRemoteRepositoryNonDefaultBranchBehindUserDenies() throws {
        let currentBranch = GitBranch(name: "feature-branch", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .behind)
        let permissionResponses = [nonDefaultBehindPrompt("feature-branch"): false]
        let (sut, shell, picker) = makeSUT(localBranches: [currentBranch], permissionResponses: permissionResponses)
        
        #expect(throws: (any Error).self) {
            try sut.handleRemoteRepository()
        }
        
        #expect(!shell.executedCommands.contains("git pull --rebase"))
        #expect(picker.capturedPermissionPrompts.count == 1)
    }
    
    @Test("Allows new branch creation when branch is in sync.")
    func handleRemoteRepositoryBranchInSync() throws {
        let currentBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .nsync)
        let (sut, shell, _) = makeSUT(localBranches: [currentBranch])
        
        try sut.handleRemoteRepository()
        
        #expect(shell.executedCommands.isEmpty)
    }
    
    @Test("Allows new branch creation when non-default branch is in sync.")
    func handleRemoteRepositoryNonDefaultBranchInSync() throws {
        let currentBranch = GitBranch(name: "feature-branch", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .nsync)
        let (sut, shell, _) = makeSUT(localBranches: [currentBranch])
        
        try sut.handleRemoteRepository()
        
        #expect(shell.executedCommands.isEmpty)
    }
    
    @Test("Throws error when no current branch is found.")
    func handleRemoteRepositoryNoCurrentBranch() throws {
        let (sut, shell, _) = makeSUT(localBranches: [])
        
        #expect(throws: NewBranchError.noCurrentBranch) {
            try sut.handleRemoteRepository()
        }
        
        #expect(shell.executedCommands.isEmpty)
    }
}

// MARK: - SUT
private extension NewBranchManagerTests {
    func makeSUT(localBranches: [GitBranch] = [], defaultBranch: String = "main", permissionResponses: [String: Bool] = [:], selectionResponses: [String: Int] = [:]) -> (sut: NewBranchManager, shell: MockShell, picker: MockSwiftPicker) {
        let shell = MockShell()
        let picker = makePicker(permissionResponses: permissionResponses, selectionResponses: selectionResponses)
        let branchLoader = StubBranchLoader(remoteBranches: [], localBranches: localBranches, branchNames: nil, filteredResults: nil)
        let config = GitConfig(defaultBranch: defaultBranch)
        let sut = NewBranchManager(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
        
        return (sut, shell, picker)
    }
}


// MARK: - Test Helpers
private extension NewBranchManagerTests {
    func makePicker(permissionResponses: [String: Bool] = [:], selectionResponses: [String: Int] = [:]) -> MockSwiftPicker {
        let permissionResult = MockPermissionResult(defaultValue: true, type: .dictionary(permissionResponses))
        let selectionResult = MockSelectionResult(
            defaultSingle: .index(0),
            defaultMulti: .none,
            singleType: .dictionary(
                Dictionary(uniqueKeysWithValues: selectionResponses.map { ($0.key, .index($0.value)) })
            ),
            multiType: .ordered([])
        )
        
        return MockSwiftPicker(
            inputResult: .init(),
            permissionResult: permissionResult,
            selectionResult: selectionResult,
            treeNavigationResult: .init()
        )
    }
    
    func aheadPrompt(for branchName: String) -> String {
        return "Your \(branchName) branch has unpushed changes. Would you like to push them before creating a new branch?"
    }
    
    func defaultBranchBehindPrompt(_ defaultBranch: String) -> String {
        return "Your \(defaultBranch) branch is behind the remote. You must sync before creating a new branch:"
    }
    
    func nonDefaultBehindPrompt(_ branchName: String) -> String {
        return "Your \(branchName) branch is behind the remote. You must rebase before creating a new branch. Continue?"
    }
}
