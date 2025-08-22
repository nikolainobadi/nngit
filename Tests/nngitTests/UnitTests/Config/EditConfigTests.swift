import Testing
import SwiftPicker
import GitShellKit
import NnShellKit
@testable import nngit

@MainActor
struct EditConfigTests {
    @Test("updates config using arguments")
    func updatesWithArguments() throws {
        let localCheck = makeGitCommand(.localGitCheck, path: nil)
        let initial = GitConfig.defaultConfig
        let loader = StubConfigLoader(initialConfig: initial)
        let picker = MockPicker()
        let shell = MockShell(results: ["true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try runCommand(context: context, args: ["--default-branch", "dev"])

        #expect(shell.executedCommands.contains(localCheck))
        let saved = try #require(loader.savedConfig)
        #expect(saved.defaultBranch == "dev")
        #expect(output.contains("✅ Updated configuration"))
    }

    @Test("prompts for values when no arguments provided")
    func promptsForValues() throws {
        let localCheck = makeGitCommand(.localGitCheck, path: nil)
        let initial = GitConfig.defaultConfig
        let loader = StubConfigLoader(initialConfig: initial)
        let picker = MockPicker(
            permissionResponses: ["Save these changes?": true],
            requiredInputResponses: ["Enter a new default branch name (leave blank to keep 'main')": "develop"]
        )
        let shell = MockShell(results: ["true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try runCommand(context: context, args: [])

        #expect(shell.executedCommands.contains(localCheck))
        let saved = try #require(loader.savedConfig)
        #expect(saved.defaultBranch == "develop")
        #expect(output.contains("Current Default Branch:"))
        #expect(output.contains("Updated Default Branch:"))
        #expect(output.contains("✅ Updated configuration"))
    }

    private func runCommand(context: MockContext, args: [String]) throws -> String {
        return try Nngit.testRun(context: context, args: ["config"] + args)
    }
}