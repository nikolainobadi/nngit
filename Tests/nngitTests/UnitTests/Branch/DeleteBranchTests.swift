import Testing
import SwiftPicker
import GitShellKit
@testable import nngit

@MainActor
struct DeleteBranchTests {
    @Test("prunes origin when flag provided")
    func prunesWithFlag() throws {
        let pruneCmd = makeGitCommand(.pruneOrigin, path: nil)
        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            makeGitCommand(.checkForRemote, path: nil): "origin",
            pruneCmd: "",
            deleteFoo: ""
        ]
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select which branches to delete"] = 0
        let branch = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [branch])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try Nngit.testRun(context: context, args: ["delete-branch", "--prune-origin"])

        #expect(shell.commands.contains(pruneCmd))
        #expect(shell.commands.contains(deleteFoo))
    }

    @Test("uses config to automatically prune")
    func prunesWithConfig() throws {
        let pruneCmd = makeGitCommand(.pruneOrigin, path: nil)
        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            makeGitCommand(.checkForRemote, path: nil): "origin",
            pruneCmd: "",
            deleteFoo: ""
        ]
        var config = GitConfig.defaultConfig
        config.pruneWhenDeletingBranches = true
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select which branches to delete"] = 0
        let branch = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [branch])
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        _ = try Nngit.testRun(context: context, args: ["delete-branch"])

        #expect(shell.commands.contains(pruneCmd))
        #expect(shell.commands.contains(deleteFoo))
    }

    @Test("does not prune without flag or config")
    func noPruneByDefault() throws {
        let pruneCmd = makeGitCommand(.pruneOrigin, path: nil)
        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            deleteFoo: ""
        ]
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select which branches to delete"] = 0
        let branch = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [branch])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        _ = try Nngit.testRun(context: context, args: ["delete-branch"])

        #expect(!shell.commands.contains(pruneCmd))
        #expect(shell.commands.contains(deleteFoo))
    }
}

private class StubBranchLoader: GitBranchLoaderProtocol {
    private let branches: [GitBranch]
    init(branches: [GitBranch]) { self.branches = branches }
    func loadBranches(from location: BranchLocation, shell: GitShell) throws -> [GitBranch] { branches }
}

private class StubConfigLoader: GitConfigLoader {
    private let initialConfig: GitConfig
    init(initialConfig: GitConfig) { self.initialConfig = initialConfig }
    func loadConfig(picker: Picker) throws -> GitConfig { initialConfig }
    func save(_ config: GitConfig) throws { }
}
