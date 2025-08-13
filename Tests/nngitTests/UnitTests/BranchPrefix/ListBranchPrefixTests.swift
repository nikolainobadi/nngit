import Testing
import SwiftPicker
import GitShellKit
@testable import nngit

@MainActor
struct ListBranchPrefixTests {
    @Test("prints no branch prefixes exist when none are configured")
    func printsNoPrefixesWhenEmpty() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let loader = StubConfigLoader(initialConfig: .defaultConfig)
        let picker = MockPicker()
        let shell = MockGitShell(responses: [localGitCheck: "true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["list-branch-prefix"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(output.contains("No branch prefixes exist."))
    }

    @Test("lists all saved branch prefixes with their requirement flags")
    func listsAllPrefixes() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let p1 = BranchPrefix(name: "feature", requiresIssueNumber: false)
        let p2 = BranchPrefix(name: "bugfix", requiresIssueNumber: true)
        var initial = GitConfig.defaultConfig
        initial.branchPrefixes = [p1, p2]
        let loader = StubConfigLoader(initialConfig: initial)
        let picker = MockPicker()
        let shell = MockGitShell(responses: [localGitCheck: "true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["list-branch-prefix"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(output.contains("Branch prefixes:"))
        #expect(output.contains("  - feature (requires issue number: no)"))
        #expect(output.contains("  - bugfix (requires issue number: yes)"))
    }
}

// MARK: - Helpers

private class StubConfigLoader: GitConfigLoader {
    private let initialConfig: GitConfig

    init(initialConfig: GitConfig) {
        self.initialConfig = initialConfig
    }

    func loadConfig(picker: CommandLinePicker) throws -> GitConfig {
        return initialConfig
    }

    func save(_ config: GitConfig) throws {
        // no-op
    }
}