//
//  NewPushManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/25/25.
//

import Testing
import NnShellKit
import SwiftPicker
import GitShellKit
@testable import nngit

struct NewPushManagerTests {
    @Test("Pushes new branch successfully when all checks pass.")
    func pushNewBranchSuccessful() throws {
        let results = [
            "origin",           // checkForRemote (remote exists)
            "feature-branch",   // getCurrentBranchName
            "",                 // fetchOrigin
            "",                 // listRemoteBranches
            "",                 // getLocalChanges
            "0\t0",             // compareBranchAndRemote
            ""                  // pushNewRemote
        ]
        let (sut, shell, picker) = makeSUT(shellResults: results)
        
        try sut.pushNewBranch()
        
        #expect(shell.executedCommands.contains("git fetch origin"))
        #expect(shell.executedCommands.contains("git push -u origin feature-branch"))
        #expect(picker.requiredPermissions.isEmpty)
    }
    
    @Test("Pushes branch successfully when on default branch.")
    func pushNewBranchOnDefaultBranch() throws {
        let results = [
            "origin",           // checkForRemote (remote exists)
            "main",             // getCurrentBranchName
            "",                 // fetchOrigin
            "",                 // listRemoteBranches
            ""                  // pushNewRemote
        ]
        let (sut, shell, picker) = makeSUT(defaultBranch: "main", shellResults: results)
        
        try sut.pushNewBranch()
        
        #expect(shell.executedCommands.contains("git fetch origin"))
        #expect(shell.executedCommands.contains("git push -u origin main"))
        #expect(picker.requiredPermissions.isEmpty)
        #expect(!shell.executedCommands.contains("git status --porcelain")) // Skip conflict checks for default branch
    }
    
    @Test("Pushes branch successfully when branch is in sync with default branch.")
    func pushNewBranchInSync() throws {
        let results = [
            "origin",           // checkForRemote (remote exists)
            "feature-branch",   // getCurrentBranchName
            "",                 // fetchOrigin
            "",                 // listRemoteBranches
            "",                 // getLocalChanges
            "0\t0",             // compareBranchAndRemote
            ""                  // pushNewRemote
        ]
        let (sut, shell, picker) = makeSUT(shellResults: results)
        
        try sut.pushNewBranch()
        
        #expect(shell.executedCommands.contains("git fetch origin"))
        #expect(shell.executedCommands.contains("git push -u origin feature-branch"))
        #expect(picker.requiredPermissions.isEmpty)
    }
    
    @Test("Pushes branch successfully when user confirms despite being behind.")
    func pushNewBranchBehindUserConfirms() throws {
        let permissionResponses = ["⚠️  Warning: Your branch is 2 commit(s) behind 'main'. Consider rebasing before pushing to avoid potential conflicts. Continue with push anyway?": true]
        let results = [
            "origin",           // checkForRemote (remote exists)
            "feature-branch",   // getCurrentBranchName
            "",                 // fetchOrigin
            "",                 // listRemoteBranches
            "",                 // getLocalChanges
            "1\t2",             // compareBranchAndRemote (ahead 1, behind 2)
            ""                  // pushNewRemote
        ]
        let (sut, shell, picker) = makeSUT(permissionResponses: permissionResponses, shellResults: results)
        
        try sut.pushNewBranch()
        
        #expect(shell.executedCommands.contains("git fetch origin"))
        #expect(shell.executedCommands.contains("git push -u origin feature-branch"))
        #expect(picker.requiredPermissions.contains("⚠️  Warning: Your branch is 2 commit(s) behind 'main'. Consider rebasing before pushing to avoid potential conflicts. Continue with push anyway?"))
    }
    
    @Test("Pushes branch successfully when ahead of default branch.")
    func pushNewBranchAhead() throws {
        let results = [
            "origin",           // checkForRemote (remote exists)
            "feature-branch",   // getCurrentBranchName
            "",                 // fetchOrigin
            "",                 // listRemoteBranches
            "",                 // getLocalChanges
            "3\t0",             // compareBranchAndRemote (ahead 3, behind 0)
            ""                  // pushNewRemote
        ]
        let (sut, shell, picker) = makeSUT(shellResults: results)
        
        try sut.pushNewBranch()
        
        #expect(shell.executedCommands.contains("git fetch origin"))
        #expect(shell.executedCommands.contains("git push -u origin feature-branch"))
        #expect(picker.requiredPermissions.isEmpty)
    }
    
    @Test("Works with custom default branch name.")
    func pushNewBranchCustomDefaultBranch() throws {
        let results = [
            "origin",           // checkForRemote (remote exists)
            "feature-branch",   // getCurrentBranchName
            "",                 // fetchOrigin
            "",                 // listRemoteBranches
            "",                 // getLocalChanges
            "0\t0",             // compareBranchAndRemote
            ""                  // pushNewRemote
        ]
        let (sut, shell, picker) = makeSUT(defaultBranch: "develop", shellResults: results)
        
        try sut.pushNewBranch()
        
        #expect(shell.executedCommands.contains("git fetch origin"))
        #expect(shell.executedCommands.contains("git push -u origin feature-branch"))
        #expect(picker.requiredPermissions.isEmpty)
    }
}


// MARK: - SUT
extension NewPushManagerTests {
    func makeSUT(
        defaultBranch: String = "main",
        permissionResponses: [String: Bool] = [:],
        shellResults: [String] = []
    ) -> (sut: NewPushManager, shell: MockShell, picker: MockPicker) {
        let shell = MockShell(results: shellResults)
        let picker = MockPicker(
            permissionResponses: permissionResponses,
            requiredInputResponses: [:],
            selectionResponses: [:]
        )
        let configLoader = StubConfigLoader(initialConfig: GitConfig(defaultBranch: defaultBranch))
        let sut = NewPushManager(shell: shell, picker: picker, configLoader: configLoader)
        
        return (sut, shell, picker)
    }
}