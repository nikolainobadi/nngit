//
//  SwitchBranchTests.swift
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
struct SwitchBranchTests {
    @Test("switches without prompting when exact branch name is provided")
    func switchesExactMatch() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let switchCmd = makeGitCommand(.switchBranch(branchName: "dev"), path: nil)
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "dev", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branch3 = GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [branch1, branch2, branch3])
        let shell = MockShell(results: [
            "true",  // localGitCheck  
            ""  // switchCmd
        ])
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch", "dev", "--include-all"])
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(switchCmd))
        #expect(output.isEmpty)
    }

    @Test("prints no branches found matching search term when none match")
    func printsNoMatchForSearch() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "dev", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [branch1, branch2])
        let shell = MockShell(results: [
            "true"  // localGitCheck
        ])
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch", "xyz", "--include-all"])
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(output.contains("No branches found matching 'xyz'"))
    }

    @Test("prompts to select branch when no search provided")
    func promptsAndSwitches() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let switchCmd = makeGitCommand(.switchBranch(branchName: "feature"), path: nil)
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [branch1, branch2])
        let shell = MockShell(results: [
            "true",  // localGitCheck
            ""  // switchCmd
        ])
        let picker = MockPicker(
            permissionResponses: [:],
            requiredInputResponses: [:],
            selectionResponses: ["Select a branch (switching from main)": 0]
        )
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch", "--include-all"])
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(switchCmd))
        #expect(output.isEmpty)
    }

    @Test("shows all branches when no git user is configured")
    func noUserConfigShowsAll() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let switchCmd = makeGitCommand(.switchBranch(branchName: "dev"), path: nil)
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "dev", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [branch1, branch2])
        let shell = MockShell(results: [
            "true",  // localGitCheck
            "",      // git config user.name
            "",      // git config --global user.name
            "",      // git config user.email
            "",      // git config --global user.email
            ""       // switchCmd
        ])
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch", "dev", "--include-all"])

        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(switchCmd))
        #expect(!shell.executedCommands.contains(where: { $0.contains("git log -1") }))
        #expect(output.isEmpty)
    }

    @Test("includes branches from all authors with flag")
    func includeAllFlag() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let switchCmd = makeGitCommand(.switchBranch(branchName: "dev"), path: nil)
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "dev", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [branch1, branch2])
        let shell = MockShell(results: [
            "true",  // localGitCheck
            ""       // switchCmd
        ])
        let picker = MockPicker(
            permissionResponses: [:],
            requiredInputResponses: [:],
            selectionResponses: ["Select a branch (switching from main)": 1]
        )
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch", "--include-all"])

        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(switchCmd))
        #expect(!shell.executedCommands.contains(where: { $0.contains("git log -1") }))
        #expect(output.isEmpty)
    }
}
