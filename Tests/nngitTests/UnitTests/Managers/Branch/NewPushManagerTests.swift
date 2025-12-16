//
//  NewPushManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/25/25.
//

import Testing
import GitShellKit
import NnShellTesting
import SwiftPickerTesting
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
        #expect(picker.capturedPermissionPrompts.isEmpty)
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
        #expect(picker.capturedPermissionPrompts.isEmpty)
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
        #expect(picker.capturedPermissionPrompts.isEmpty)
    }
    
    @Test("Pushes branch successfully when user confirms despite being behind.")
    func pushNewBranchBehindUserConfirms() throws {
        let permissionResponses = [behindWarningPrompt(behind: 2, defaultBranch: "main"): true]
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
        #expect(picker.capturedPermissionPrompts.contains(behindWarningPrompt(behind: 2, defaultBranch: "main")))
    }
    
    @Test("Throws error when user denies push while behind default branch.")
    func pushNewBranchBehindUserDenies() throws {
        let permissionResponses = [behindWarningPrompt(behind: 3, defaultBranch: "main"): false]
        let results = [
            "origin",           // checkForRemote (remote exists)
            "feature-branch",   // getCurrentBranchName
            "",                 // fetchOrigin
            "",                 // listRemoteBranches
            "",                 // getLocalChanges
            "2\t3"              // compareBranchAndRemote (ahead 2, behind 3)
            // No pushNewRemote - should not reach this step
        ]
        let (sut, shell, picker) = makeSUT(permissionResponses: permissionResponses, shellResults: results)
        
        #expect(throws: (any Error).self) {
            try sut.pushNewBranch()
        }
        
        #expect(shell.executedCommands.contains("git fetch origin"))
        #expect(!shell.executedCommands.contains("git push -u origin feature-branch"))
        #expect(picker.capturedPermissionPrompts.contains(behindWarningPrompt(behind: 3, defaultBranch: "main")))
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
        #expect(picker.capturedPermissionPrompts.isEmpty)
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
        #expect(picker.capturedPermissionPrompts.isEmpty)
    }
}


// MARK: - SUT
extension NewPushManagerTests {
    func makeSUT(
        defaultBranch: String = "main",
        permissionResponses: [String: Bool] = [:],
        shellResults: [String] = []
    ) -> (sut: NewPushManager, shell: MockShell, picker: MockSwiftPicker) {
        let shell = MockShell(results: shellResults)
        let picker = makePicker(permissionResponses: permissionResponses)
        let configLoader = StubConfigLoader(initialConfig: GitConfig(defaultBranch: defaultBranch))
        let sut = NewPushManager(shell: shell, picker: picker, configLoader: configLoader)
        
        return (sut, shell, picker)
    }
}


// MARK: - Test Helpers
private extension NewPushManagerTests {
    func makePicker(permissionResponses: [String: Bool] = [:]) -> MockSwiftPicker {
        let permissionResult = MockPermissionResult(defaultValue: true, type: .dictionary(permissionResponses))
        let selectionResult = MockSelectionResult(
            defaultSingle: .index(0),
            defaultMulti: .none,
            singleType: .ordered([]),
            multiType: .ordered([])
        )
        
        return MockSwiftPicker(
            inputResult: .init(),
            permissionResult: permissionResult,
            selectionResult: selectionResult,
            treeNavigationResult: .init()
        )
    }
    
    func behindWarningPrompt(behind: Int, defaultBranch: String) -> String {
        return "⚠️  Warning: Your branch is \(behind) commit(s) behind '\(defaultBranch)'. Consider rebasing before pushing to avoid potential conflicts. Continue with push anyway?"
    }
}
