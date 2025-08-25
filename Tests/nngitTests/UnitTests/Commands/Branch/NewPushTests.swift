//
//  NewPushTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/25/25.
//

import Testing
import NnShellKit
import SwiftPicker
import GitShellKit
@testable import nngit

@MainActor
struct NewPushTests {
    @Test("Pushes new branch successfully when all checks pass.")
    func pushNewBranchSuccessful() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let getCurrentBranch = makeGitCommand(.getCurrentBranchName, path: nil)
        let fetchOrigin = makeGitCommand(.fetchOrigin, path: nil)
        let listRemoteBranches = makeGitCommand(.listRemoteBranches, path: nil)
        let getLocalChanges = makeGitCommand(.getLocalChanges, path: nil)
        let compareBranches = makeGitCommand(.compareBranchAndRemote(local: "feature-branch", remote: "origin/main"), path: nil)
        let pushNewRemote = makeGitCommand(.pushNewRemote(branchName: "feature-branch"), path: nil)
        
        let shell = MockShell(results: [
            "true",           // localGitCheck
            "origin",         // checkForRemote (remote exists)
            "feature-branch", // getCurrentBranch
            "",               // fetchOrigin
            "",               // listRemoteBranches
            "",               // getLocalChanges
            "0\t0",           // compareBranches
            ""                // pushNewRemote
        ])
        
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, configLoader: StubConfigLoader(initialConfig: .defaultConfig))

        let output = try Nngit.testRun(context: context, args: ["new-push"])
        
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(getCurrentBranch))
        #expect(shell.executedCommands.contains(fetchOrigin))
        #expect(shell.executedCommands.contains(listRemoteBranches))
        #expect(shell.executedCommands.contains(getLocalChanges))
        #expect(shell.executedCommands.contains(compareBranches))
        #expect(shell.executedCommands.contains(pushNewRemote))
        #expect(output.contains("🚀 Successfully pushed 'feature-branch' to remote and set upstream tracking."))
        #expect(picker.requiredPermissions.isEmpty)
    }
    
    @Test("Pushes branch successfully when on default branch.")
    func pushNewBranchOnDefaultBranch() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let getCurrentBranch = makeGitCommand(.getCurrentBranchName, path: nil)
        let fetchOrigin = makeGitCommand(.fetchOrigin, path: nil)
        let listRemoteBranches = makeGitCommand(.listRemoteBranches, path: nil)
        let pushNewRemote = makeGitCommand(.pushNewRemote(branchName: "main"), path: nil)
        
        let shell = MockShell(results: [
            "true",    // localGitCheck
            "origin",  // checkForRemote (remote exists)
            "main",    // getCurrentBranch
            "",        // fetchOrigin
            "",        // listRemoteBranches
            ""         // pushNewRemote
        ])
        
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, configLoader: StubConfigLoader(initialConfig: .defaultConfig))

        let output = try Nngit.testRun(context: context, args: ["new-push"])
        
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(getCurrentBranch))
        #expect(shell.executedCommands.contains(fetchOrigin))
        #expect(shell.executedCommands.contains(listRemoteBranches))
        #expect(shell.executedCommands.contains(pushNewRemote))
        #expect(output.contains("🚀 Successfully pushed 'main' to remote and set upstream tracking."))
        #expect(picker.requiredPermissions.isEmpty)
        // Should not check for conflicts when on default branch
        #expect(!shell.executedCommands.contains(makeGitCommand(.getLocalChanges, path: nil)))
    }
    
    @Test("Pushes branch successfully when user confirms despite being behind.")
    func pushNewBranchBehindUserConfirms() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let getCurrentBranch = makeGitCommand(.getCurrentBranchName, path: nil)
        let fetchOrigin = makeGitCommand(.fetchOrigin, path: nil)
        let listRemoteBranches = makeGitCommand(.listRemoteBranches, path: nil)
        let getLocalChanges = makeGitCommand(.getLocalChanges, path: nil)
        let compareBranches = makeGitCommand(.compareBranchAndRemote(local: "feature-branch", remote: "origin/main"), path: nil)
        let pushNewRemote = makeGitCommand(.pushNewRemote(branchName: "feature-branch"), path: nil)
        
        let shell = MockShell(results: [
            "true",           // localGitCheck
            "origin",         // checkForRemote (remote exists)
            "feature-branch", // getCurrentBranch
            "",               // fetchOrigin
            "",               // listRemoteBranches
            "",               // getLocalChanges
            "1\t2",           // compareBranches (ahead 1, behind 2)
            ""                // pushNewRemote
        ])
        
        let picker = MockPicker(
            permissionResponses: ["⚠️  Warning: Your branch is 2 commit(s) behind 'main'. Consider rebasing before pushing to avoid potential conflicts. Continue with push anyway?": true]
        )
        let context = MockContext(picker: picker, shell: shell, configLoader: StubConfigLoader(initialConfig: .defaultConfig))

        let output = try Nngit.testRun(context: context, args: ["new-push"])
        
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(getCurrentBranch))
        #expect(shell.executedCommands.contains(fetchOrigin))
        #expect(shell.executedCommands.contains(listRemoteBranches))
        #expect(shell.executedCommands.contains(getLocalChanges))
        #expect(shell.executedCommands.contains(compareBranches))
        #expect(shell.executedCommands.contains(pushNewRemote))
        #expect(output.contains("🚀 Successfully pushed 'feature-branch' to remote and set upstream tracking."))
        #expect(picker.requiredPermissions.contains("⚠️  Warning: Your branch is 2 commit(s) behind 'main'. Consider rebasing before pushing to avoid potential conflicts. Continue with push anyway?"))
    }
    
    @Test("Works with custom default branch name.")
    func pushNewBranchCustomDefaultBranch() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let getCurrentBranch = makeGitCommand(.getCurrentBranchName, path: nil)
        let fetchOrigin = makeGitCommand(.fetchOrigin, path: nil)
        let listRemoteBranches = makeGitCommand(.listRemoteBranches, path: nil)
        let getLocalChanges = makeGitCommand(.getLocalChanges, path: nil)
        let compareBranches = makeGitCommand(.compareBranchAndRemote(local: "feature-branch", remote: "origin/develop"), path: nil)
        let pushNewRemote = makeGitCommand(.pushNewRemote(branchName: "feature-branch"), path: nil)
        
        let shell = MockShell(results: [
            "true",           // localGitCheck
            "origin",         // checkForRemote (remote exists)
            "feature-branch", // getCurrentBranch
            "",               // fetchOrigin
            "",               // listRemoteBranches
            "",               // getLocalChanges
            "0\t0",           // compareBranches
            ""                // pushNewRemote
        ])
        
        let picker = MockPicker()
        let customConfig = GitConfig(defaultBranch: "develop")
        let context = MockContext(picker: picker, shell: shell, configLoader: StubConfigLoader(initialConfig: customConfig))

        let output = try Nngit.testRun(context: context, args: ["new-push"])
        
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(getCurrentBranch))
        #expect(shell.executedCommands.contains(fetchOrigin))
        #expect(shell.executedCommands.contains(listRemoteBranches))
        #expect(shell.executedCommands.contains(getLocalChanges))
        #expect(shell.executedCommands.contains(compareBranches))
        #expect(shell.executedCommands.contains(pushNewRemote))
        #expect(output.contains("🚀 Successfully pushed 'feature-branch' to remote and set upstream tracking."))
        #expect(picker.requiredPermissions.isEmpty)
    }
}