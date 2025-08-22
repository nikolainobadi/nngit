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
        let newBranchCmd = makeGitCommand(.newBranch(branchName: "foo"), path: nil)
        let shell = MockShell(results: [
            "true",  // localGitCheck
            ""       // newBranchCmd
        ])
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, configLoader: StubConfigLoader(initialConfig: .defaultConfig))

        let output = try Nngit.testRun(context: context, args: ["new-branch", "foo"])
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(newBranchCmd))
        #expect(output.contains("✅ Created and switched to branch: foo"))
    }


    @Test("prompts for branch name when not provided")
    func promptsForBranchName() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let newBranchCmd = makeGitCommand(.newBranch(branchName: "prompted-branch"), path: nil)
        let shell = MockShell(results: [
            "true",  // localGitCheck
            ""       // newBranchCmd
        ])
        let picker = MockPicker(
            permissionResponses: [:],
            requiredInputResponses: ["Enter the name of your new branch.": "prompted-branch"],
            selectionResponses: [:]
        )
        let context = MockContext(picker: picker, shell: shell, configLoader: StubConfigLoader(initialConfig: .defaultConfig))

        let output = try Nngit.testRun(context: context, args: ["new-branch"])
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(newBranchCmd))
        #expect(output.contains("✅ Created and switched to branch: prompted-branch"))
    }

}
