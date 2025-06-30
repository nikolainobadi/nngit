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

    @Test("filters branches using search term")
    func filtersWithSearch() throws {
        let deleteFeature = makeGitCommand(.deleteBranch(name: "feature", forced: false), path: nil)
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            "git config user.name": "John Doe",
            "git config user.email": "john@example.com",
            "git log -1 --pretty=format:'%an,%ae' feature": "John Doe,john@example.com",
            "git log -1 --pretty=format:'%an,%ae' bugfix": "John Doe,john@example.com",
            deleteFeature: ""
        ]
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select which branches to delete"] = 0
        let branch1 = GitBranch(name: "main", isMerged: true, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branch3 = GitBranch(name: "bugfix", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [branch1, branch2, branch3])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try Nngit.testRun(context: context, args: ["delete-branch", "fea"])

        #expect(shell.commands.contains(deleteFeature))
        #expect(!shell.commands.contains(makeGitCommand(.deleteBranch(name: "bugfix", forced: false), path: nil)))
    }

    @Test("filters branches by author")
    func filtersByAuthor() throws {
        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            "git config user.name": "John Doe",
            "git config user.email": "john@example.com",
            "git log -1 --pretty=format:'%an,%ae' foo": "John Doe,john@example.com",
            "git log -1 --pretty=format:'%an,%ae' bar": "Jane Smith,jane@example.com",
            deleteFoo: ""
        ]
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select which branches to delete"] = 0
        let foo = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let bar = GitBranch(name: "bar", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [foo, bar])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try Nngit.testRun(context: context, args: ["delete-branch"])

        #expect(shell.commands.contains(deleteFoo))
        #expect(!shell.commands.contains(makeGitCommand(.deleteBranch(name: "bar", forced: false), path: nil)))
    }

    @Test("includes branches from all authors with flag")
    func includeAllFlag() throws {
        let deleteBar = makeGitCommand(.deleteBranch(name: "bar", forced: false), path: nil)
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            deleteBar: ""
        ]
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select which branches to delete"] = 1
        let foo = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let bar = GitBranch(name: "bar", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [foo, bar])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try Nngit.testRun(context: context, args: ["delete-branch", "--include-all"])

        #expect(shell.commands.contains(deleteBar))
        #expect(!shell.commands.contains(where: { $0.contains("git log -1") }))
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
