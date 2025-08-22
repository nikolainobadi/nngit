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
    @Test("Selects and deletes branch successfully")
    func selectsAndDeletesBranch() throws {
        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
        let pruneCmd = makeGitCommand(.pruneOrigin, path: nil)
        let results = [
            "true",    // localGitCheck
            "",        // deleteFoo
            "origin"   // checkForRemote
        ]
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: ["Select which branches to delete": 0])
        let branch = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [branch])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try runCommand(context: context)

        #expect(shell.executedCommands.contains(deleteFoo))
        #expect(shell.executedCommands.contains(pruneCmd))
    }

    @Test("Always prunes origin when remote exists")
    func alwaysPrunesOrigin() throws {
        let pruneCmd = makeGitCommand(.pruneOrigin, path: nil)
        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
        let results = [
            "true",    // localGitCheck
            "",        // deleteBranch
            "origin"   // checkForRemote
        ]
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: ["Select which branches to delete": 0])
        let branch = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [branch])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try runCommand(context: context)

        #expect(shell.executedCommands.contains(pruneCmd))
        #expect(shell.executedCommands.contains(deleteFoo))
    }

    @Test("Does not prune when no remote exists", .disabled())
    func noPruneWithoutRemote() throws {
        let pruneCmd = makeGitCommand(.pruneOrigin, path: nil)
        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
        let results = [
            "true",  // localGitCheck
            ""       // deleteBranch
        ]
        let shell = MockShell(results: results, shouldThrowError: true) // Will throw on remoteExists check
        let picker = MockPicker(selectionResponses: ["Select which branches to delete": 0])
        let branch = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [branch])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try runCommand(context: context)

        #expect(!shell.executedCommands.contains(pruneCmd))
        #expect(shell.executedCommands.contains(deleteFoo))
    }


    @Test("Filters branches using search term")
    func filtersWithSearch() throws {
        let deleteFeature = makeGitCommand(.deleteBranch(name: "feature", forced: false), path: nil)
        let results = [
            "true",    // localGitCheck
            "",        // deleteFeature
            "origin"   // checkForRemote
        ]
        let shell = MockShell(results: results)
        let picker = MockPicker(selectionResponses: ["Select which branches to delete": 0])
        let branch1 = GitBranch(name: "main", isMerged: true, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branch3 = GitBranch(name: "bugfix", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [branch1, branch2, branch3])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try Nngit.testRun(context: context, args: ["delete-branch", "fea"])

        #expect(shell.executedCommands.contains(deleteFeature))
        #expect(!shell.executedCommands.contains(makeGitCommand(.deleteBranch(name: "bugfix", forced: false), path: nil)))
    }



    @Test("Deletes all merged branches with flag")
    func deleteAllMerged() throws {
        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
        let deleteBar = makeGitCommand(.deleteBranch(name: "bar", forced: false), path: nil)
        let results = [
            "true",    // localGitCheck
            "",        // deleteFoo
            "",        // deleteBar
            "origin"   // checkForRemote
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
