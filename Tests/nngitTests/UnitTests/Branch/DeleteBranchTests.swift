//
//  DeleteBranchTests.swift
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
struct DeleteBranchTests {
    @Test("prunes origin when flag provided")
    func prunesWithFlag() throws {
        let pruneCmd = makeGitCommand(.pruneOrigin, path: nil)
        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
        let results = [
            "true",                           // git rev-parse --is-inside-work-tree
            "Test User",                      // git config user.name
            "test@example.com",               // git config user.email
            "Test User,test@example.com",     // git log -1 --pretty=format:'%an,%ae' foo
            "",                               // git branch -d foo
            "origin",                         // git remote  
            ""                                // git remote prune origin
        ]

        let shell = MockShell(results: results, shouldThrowError: false)
        let picker = MockPicker(selectionResponses: ["Select which branches to delete": 0])
        let branch = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [branch])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try runCommand(context: context, additionalArgs: ["--prune-origin"])

        #expect(shell.executedCommands.contains(pruneCmd))
        #expect(shell.executedCommands.contains(deleteFoo))
    }

    @Test("uses config to automatically prune")
    func prunesWithConfig() throws {
        let pruneCmd = makeGitCommand(.pruneOrigin, path: nil)
        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
        let results = [
            "true",     // localGitCheck
            "",         // deleteBranch
            "origin",   // checkForRemote
            ""          // pruneOrigin
        ]
        var config = GitConfig.defaultConfig
        config.behaviors.pruneWhenDeleting = true
        let shell = MockShell(results: results)
        let picker = MockPicker(
            permissionResponses: [:],
            requiredInputResponses: [:],
            selectionResponses: ["Select which branches to delete": 0]
        )
        let branch = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [branch])
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        _ = try Nngit.testRun(context: context, args: ["delete-branch", "--include-all"])

        #expect(shell.executedCommands.contains(pruneCmd))
        #expect(shell.executedCommands.contains(deleteFoo))
    }

    @Test("does not prune without flag or config")
    func noPruneByDefault() throws {
        let pruneCmd = makeGitCommand(.pruneOrigin, path: nil)
        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
        let results = [
            "true",  // localGitCheck
            ""       // deleteBranch
        ]
        let shell = MockShell(results: results)
        let picker = MockPicker(
            permissionResponses: [:],
            requiredInputResponses: [:],
            selectionResponses: ["Select which branches to delete": 0]
        )
        let branch = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [branch])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        _ = try Nngit.testRun(context: context, args: ["delete-branch", "--include-all"])

        #expect(!shell.executedCommands.contains(pruneCmd))
        #expect(shell.executedCommands.contains(deleteFoo))
    }

    @Test("filters branches using search term")
    func filtersWithSearch() throws {
        let deleteFeature = makeGitCommand(.deleteBranch(name: "feature", forced: false), path: nil)
        let results = [
            "true",  // localGitCheck
            ""       // deleteFeature
        ]
        let shell = MockShell(results: results)
        let picker = MockPicker(
            permissionResponses: [:],
            requiredInputResponses: [:],
            selectionResponses: ["Select which branches to delete": 0]
        )
        let branch1 = GitBranch(name: "main", isMerged: true, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branch3 = GitBranch(name: "bugfix", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [branch1, branch2, branch3])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try Nngit.testRun(context: context, args: ["delete-branch", "fea", "--include-all"])

        #expect(shell.executedCommands.contains(deleteFeature))
        #expect(!shell.executedCommands.contains(makeGitCommand(.deleteBranch(name: "bugfix", forced: false), path: nil)))
    }

    @Test("filters branches by author")
    func filtersByAuthor() throws {
        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
        let results = [
            "true",  // localGitCheck
            "John Doe",  // git config user.name
            "john@example.com",  // git config user.email
            "John Doe,john@example.com",  // git log -1 foo
            "Jane Smith,jane@example.com",  // git log -1 bar
            ""  // deleteFoo
        ]
        let shell = MockShell(results: results)
        let picker = MockPicker(
            permissionResponses: [:],
            requiredInputResponses: [:],
            selectionResponses: ["Select which branches to delete": 0]
        )
        let foo = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let bar = GitBranch(name: "bar", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [foo, bar])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try Nngit.testRun(context: context, args: ["delete-branch"])

        #expect(shell.executedCommands.contains(deleteFoo))
        #expect(!shell.executedCommands.contains(makeGitCommand(.deleteBranch(name: "bar", forced: false), path: nil)))
    }

    @Test("includes branches from all authors with flag")
    func includeAllFlag() throws {
        let deleteBar = makeGitCommand(.deleteBranch(name: "bar", forced: false), path: nil)
        let results = [
            "true",  // localGitCheck
            ""       // deleteBar
        ]
        let shell = MockShell(results: results)
        let picker = MockPicker(
            permissionResponses: [:],
            requiredInputResponses: [:],
            selectionResponses: ["Select which branches to delete": 1]
        )
        let foo = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let bar = GitBranch(name: "bar", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [foo, bar])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try Nngit.testRun(context: context, args: ["delete-branch", "--include-all"])

        #expect(shell.executedCommands.contains(deleteBar))
        #expect(!shell.executedCommands.contains(where: { $0.contains("git log -1") }))
    }

    @Test("deletes all merged branches with flag")
    func deleteAllMerged() throws {
        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
        let deleteBar = makeGitCommand(.deleteBranch(name: "bar", forced: false), path: nil)
        let results = [
            "true",  // localGitCheck
            "",      // deleteFoo
            ""       // deleteBar
        ]
        let shell = MockShell(results: results)
        let picker = MockPicker()
        let foo = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let bar = GitBranch(name: "bar", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [foo, bar])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try Nngit.testRun(context: context, args: ["delete-branch", "--all-merged"])

        #expect(shell.executedCommands.contains(deleteFoo))
        #expect(shell.executedCommands.contains(deleteBar))
    }
}


// MARK: - Run Method
private extension DeleteBranchTests {
    func runCommand(context: MockContext, additionalArgs: [String] = []) throws {
        try Nngit.testRun(context: context, args: ["delete-branch"] + additionalArgs)
    }
}
