//
//  NewBranchManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import NnShellKit
import SwiftPicker
import GitShellKit
@testable import nngit

struct NewBranchManagerTests {
    @Test("Pushes changes when branch is ahead and user confirms.")
    func handleRemoteRepositoryAheadUserConfirms() throws {
        let currentBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .ahead)
        let permissionResponses = ["Your main branch has unpushed changes. Would you like to push them before creating a new branch?": true]
        let (sut, shell, picker) = makeSUT(localBranches: [currentBranch], permissionResponses: permissionResponses)
        
        try sut.handleRemoteRepository()
        
        #expect(shell.executedCommands.contains("git push"))
        #expect(picker.requiredPermissions.count == 1)
    }
    
    @Test("Throws error when branch is ahead and user denies push.")
    func handleRemoteRepositoryAheadUserDenies() throws {
        let currentBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .ahead)
        let permissionResponses = ["Your main branch has unpushed changes. Would you like to push them before creating a new branch?": false]
        let (sut, shell, picker) = makeSUT(localBranches: [currentBranch], permissionResponses: permissionResponses)
        
        #expect(throws: (any Error).self) {
            try sut.handleRemoteRepository()
        }
        
        #expect(!shell.executedCommands.contains("git push"))
        #expect(picker.requiredPermissions.count == 1)
    }
    
    @Test("Merges changes when branch is behind and user selects merge.")
    func handleRemoteRepositoryBehindUserSelectsMerge() throws {
        let currentBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .behind)
        let selectionResponses = ["Your main branch is behind the remote. You must sync before creating a new branch:": 0] // First option (merge)
        let (sut, shell, _) = makeSUT(localBranches: [currentBranch], selectionResponses: selectionResponses)
        
        try sut.handleRemoteRepository()
        
        #expect(shell.executedCommands.contains("git pull"))
    }
    
    @Test("Rebases changes when branch is behind and user selects rebase.")
    func handleRemoteRepositoryBehindUserSelectsRebase() throws {
        let currentBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .behind)
        let selectionResponses = ["Your main branch is behind the remote. You must sync before creating a new branch:": 1] // Second option (rebase)
        let (sut, shell, _) = makeSUT(localBranches: [currentBranch], selectionResponses: selectionResponses)
        
        try sut.handleRemoteRepository()
        
        #expect(shell.executedCommands.contains("git pull --rebase"))
    }
    
    @Test("Works with custom default branch name.")
    func handleRemoteRepositoryCustomDefaultBranch() throws {
        let currentBranch = GitBranch(name: "develop", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .ahead)
        let permissionResponses = ["Your develop branch has unpushed changes. Would you like to push them before creating a new branch?": true]
        let (sut, shell, picker) = makeSUT(localBranches: [currentBranch], defaultBranch: "develop", permissionResponses: permissionResponses)
        
        try sut.handleRemoteRepository()
        
        #expect(shell.executedCommands.contains("git push"))
        #expect(picker.requiredPermissions.contains("Your develop branch has unpushed changes. Would you like to push them before creating a new branch?"))
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
    
    @Test("Throws error when no remote branch exists.")
    func handleRemoteRepositoryNoRemoteBranch() throws {
        let currentBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .noRemoteBranch)
        let (sut, shell, _) = makeSUT(localBranches: [currentBranch])
        
        #expect(throws: NewBranchError.self) {
            try sut.handleRemoteRepository()
        }
        
        #expect(shell.executedCommands.isEmpty)
    }
}

// MARK: - SUT
private extension NewBranchManagerTests {
    func makeSUT(
        localBranches: [GitBranch] = [],
        defaultBranch: String = "main",
        permissionResponses: [String: Bool] = [:],
        selectionResponses: [String: Int] = [:]
    ) -> (sut: NewBranchManager, shell: MockShell, picker: MockPicker) {
        let shell = MockShell()
        let picker = MockPicker(
            permissionResponses: permissionResponses,
            requiredInputResponses: [:],
            selectionResponses: selectionResponses
        )
        let branchLoader = StubBranchLoader(remoteBranches: [], localBranches: localBranches, branchNames: nil, filteredResults: nil)
        let config = GitConfig(defaultBranch: defaultBranch)
        let sut = NewBranchManager(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
        
        return (sut, shell, picker)
    }
}
