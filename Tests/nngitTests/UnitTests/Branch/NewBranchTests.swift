//
//  NewBranchTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import NnShellKit
import SwiftPicker
import GitShellKit
@testable import nngit

@MainActor
struct NewBranchTests {
    @Test("creates branch with provided name when remote missing")
    func createsWithNameNoRemote() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let checkRemote = makeGitCommand(.checkForRemote, path: nil)
        let newBranchCmd = makeGitCommand(.newBranch(branchName: "foo"), path: nil)
        let loader = StubConfigLoader(initialConfig: .defaultConfig)
        let shell = MockShell(results: [
            "true",  // localGitCheck
            "",      // checkRemote
            ""       // newBranchCmd
        ])
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["new-branch", "foo"])
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(checkRemote))
        #expect(shell.executedCommands.contains(newBranchCmd))
        #expect(output.contains("✅ Created and switched to branch: foo"))
    }

    @Test("rebases when remote exists and on default branch with permission")
    func rebasesBeforeBranching() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let checkRemote = makeGitCommand(.checkForRemote, path: nil)
        let currentBranchCmd = makeGitCommand(.getCurrentBranchName, path: nil)
        let pullRebase = "git pull --rebase"
        let newBranchCmd = makeGitCommand(.newBranch(branchName: "bar"), path: nil)
        var config = GitConfig.defaultConfig
        config.behaviors.rebaseWhenBranchingFromDefault = true
        let loader = StubConfigLoader(initialConfig: config)
        let shell = MockShell(results: [
            "true",    // localGitCheck
            "origin",  // checkRemote
            "main",    // currentBranchCmd
            "",        // pullRebase
            ""         // newBranchCmd
        ])
        let picker = MockPicker(
            permissionResponses: ["Would you like to rebase before creating your new branch?": true],
            requiredInputResponses: [:],
            selectionResponses: [:]
        )
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        _ = try Nngit.testRun(context: context, args: ["new-branch", "bar"])
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(checkRemote))
        #expect(shell.executedCommands.contains(currentBranchCmd))
        #expect(shell.executedCommands.contains(pullRebase))
        #expect(shell.executedCommands.contains(newBranchCmd))
    }

    @Test("prompts for branch name when not provided")
    func promptsForBranchName() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let checkRemote = makeGitCommand(.checkForRemote, path: nil)
        let newBranchCmd = makeGitCommand(.newBranch(branchName: "prompted-branch"), path: nil)
        let loader = StubConfigLoader(initialConfig: .defaultConfig)
        let shell = MockShell(results: [
            "true",  // localGitCheck
            "",      // checkRemote
            ""       // newBranchCmd
        ])
        let picker = MockPicker(
            permissionResponses: [:],
            requiredInputResponses: ["Enter the name of your new branch.": "prompted-branch"],
            selectionResponses: [:]
        )
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["new-branch"])
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(checkRemote))
        #expect(shell.executedCommands.contains(newBranchCmd))
        #expect(output.contains("✅ Created and switched to branch: prompted-branch"))
    }

}
