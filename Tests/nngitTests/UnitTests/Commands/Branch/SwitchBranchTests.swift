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
        // Ensure consistent branch order by explicitly providing branch names
        let loader = StubBranchLoader(localBranches: [branch1, branch2, branch3], branchNames: ["* main", "dev", "feature"])
        let shell = MockShell(results: [
            "true",  // localGitCheck  
            ""  // switchCmd
        ])
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: GitConfig.defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try Nngit.testRun(context: context, args: ["switch-branch", "dev"])
        
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(switchCmd))
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
        let configLoader = StubConfigLoader(initialConfig: GitConfig.defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch", "xyz"])
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
        let configLoader = StubConfigLoader(initialConfig: GitConfig.defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try Nngit.testRun(context: context, args: ["switch-branch"])
        
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(switchCmd))
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
            ""       // switchCmd
        ])
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: GitConfig.defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try Nngit.testRun(context: context, args: ["switch-branch", "dev"])

        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(switchCmd))
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
            selectionResponses: ["Select a branch (switching from main)": 0]
        )
        let configLoader = StubConfigLoader(initialConfig: GitConfig.defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try Nngit.testRun(context: context, args: ["switch-branch"])

        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains(switchCmd))
    }

    @Test("Creates tracking branch when using --remote flag.")
    func remoteFlagCreatesTrackingBranch() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let mainBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let remoteBranch = GitBranch(name: "origin/feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(
            remoteBranches: ["origin/feature", "origin/main"],
            localBranches: [mainBranch, remoteBranch],
            localBranchNames: ["main"]
        )
        let shell = MockShell(results: [
            "true",  // localGitCheck
            ""       // git checkout -b feature origin/feature
        ])
        let picker = MockPicker(
            selectionResponses: ["Select a branch (switching from main)": 0]
        )
        let configLoader = StubConfigLoader(initialConfig: GitConfig.defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try Nngit.testRun(context: context, args: ["switch-branch", "--remote"])

        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains("git checkout -b feature origin/feature"))
    }

    @Test("Uses --branch-location remote equivalent behavior with --remote flag.")
    func remoteFlagEquivalentToBranchLocationRemote() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let mainBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let remoteBranch = GitBranch(name: "origin/develop", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(
            remoteBranches: ["origin/develop", "origin/main"],
            localBranches: [mainBranch, remoteBranch],
            localBranchNames: ["main"]
        )
        let shell = MockShell(results: [
            "true",  // localGitCheck
            ""       // git checkout -b develop origin/develop
        ])
        let picker = MockPicker(
            selectionResponses: ["Select a branch (switching from main)": 0]
        )
        let configLoader = StubConfigLoader(initialConfig: GitConfig.defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try Nngit.testRun(context: context, args: ["switch-branch", "--branch-location", "remote"])

        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains("git checkout -b develop origin/develop"))
    }

    @Test("Remote flag overrides branch-location option.")
    func remoteFlagOverridesBranchLocation() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let mainBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let remoteBranch = GitBranch(name: "origin/hotfix", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(
            remoteBranches: ["origin/hotfix", "origin/main"],
            localBranches: [mainBranch, remoteBranch],
            localBranchNames: ["main"]
        )
        let shell = MockShell(results: [
            "true",  // localGitCheck
            ""       // git checkout -b hotfix origin/hotfix
        ])
        let picker = MockPicker(
            selectionResponses: ["Select a branch (switching from main)": 0]
        )
        let configLoader = StubConfigLoader(initialConfig: GitConfig.defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        // --remote should override --branch-location local
        try Nngit.testRun(context: context, args: ["switch-branch", "--branch-location", "local", "--remote"])

        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains("git checkout -b hotfix origin/hotfix"))
    }
}
