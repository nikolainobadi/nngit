import Testing
import GitShellKit
import NnShellTesting
import SwiftPickerTesting
@testable import nngit

@MainActor
struct EditConfigTests {
    @Test("updates config using arguments")
    func updatesWithArguments() throws {
        let localCheck = makeGitCommand(.localGitCheck, path: nil)
        let initial = GitConfig.defaultConfig
        let loader = StubConfigLoader(initialConfig: initial)
        let picker = makePicker()
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
        let picker = makePicker(
            inputResponses: ["Enter a new default branch name (leave blank to keep 'main')": "develop"],
            permissionResponses: ["Save these changes?": true]
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
    
    private func makePicker(
        inputResponses: [String: String] = [:],
        permissionResponses: [String: Bool] = [:]
    ) -> MockSwiftPicker {
        let inputResult = MockInputResult(defaultValue: "", type: .dictionary(inputResponses))
        let permissionResult = MockPermissionResult(defaultValue: true, type: .dictionary(permissionResponses))
        
        return MockSwiftPicker(
            inputResult: inputResult,
            permissionResult: permissionResult,
            selectionResult: .init(),
            treeNavigationResult: .init()
        )
    }
}
