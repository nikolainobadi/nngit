import Testing
import SwiftPicker
import GitShellKit
@testable import nngit

@MainActor
struct AddBranchPrefixTests {
    @Test("prompts for prefix name when argument is missing")
    func promptsForNameWhenArgumentMissing() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let picker = MockPicker()
        picker.requiredInputResponses["Enter a branch prefix name"] = "hotfix"
        picker.permissionResponses["Require an issue number when using this prefix?"] = true
        picker.permissionResponses["Add this branch prefix?"] = true
        let loader = StubConfigLoader(initialConfig: .defaultConfig)
        let shell = MockGitShell(responses: [localGitCheck: "true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["add-branch-prefix"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(picker.requiredPermissions.contains("Add this branch prefix?"))
        #expect(loader.savedConfigs.count == 1)
        let saved = loader.savedConfigs.first!.branchPrefixList.first!
        #expect(saved.name == "hotfix")
        #expect(saved.requiresIssueNumber)
        #expect(output.contains("Requires Issue Number: true"))
        #expect(output.contains("✅ Added branch prefix: hotfix"))
    }

    @Test("adds a new branch prefix requiring issue number when flag is set")
    func addsNewPrefixWithIssueRequirement() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let picker = MockPicker()
        picker.permissionResponses["Require an issue number when using this prefix?"] = false
        picker.permissionResponses["Add this branch prefix?"] = true
        let loader = StubConfigLoader(initialConfig: .defaultConfig)
        let shell = MockGitShell(responses: [localGitCheck: "true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["add-branch-prefix", "bugfix", "--requires-issue-number"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(picker.requiredPermissions.contains("Add this branch prefix?"))
        #expect(loader.savedConfigs.count == 1)
        let saved = loader.savedConfigs.first!
        #expect(saved.branchPrefixList.count == 1)
        #expect(saved.branchPrefixList[0].name == "bugfix")
        #expect(saved.branchPrefixList[0].requiresIssueNumber)
        #expect(output.contains("Name: bugfix"))
        #expect(output.contains("Requires Issue Number: true"))
        #expect(output.contains("✅ Added branch prefix: bugfix"))
    }

    @Test("warns and does not add when prefix already exists")
    func warnsForDuplicate() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let existing = BranchPrefix(name: "feature", requiresIssueNumber: false)
        var initial = GitConfig.defaultConfig
        initial.branchPrefixList = [existing]
        let loader = StubConfigLoader(initialConfig: initial)
        let picker = MockPicker()
        let shell = MockGitShell(responses: [localGitCheck: "true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["add-branch-prefix", "feature"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(output.contains("A branch prefix named 'feature' already exists."))
        #expect(loader.savedConfigs.isEmpty)
    }
}


// MARK: - Helpers
private class StubConfigLoader: GitConfigLoader {
    private(set) var savedConfigs: [GitConfig] = []
    private let initialConfig: GitConfig

    init(initialConfig: GitConfig) {
        self.initialConfig = initialConfig
    }

    func loadConfig(picker: Picker) throws -> GitConfig {
        return initialConfig
    }

    func save(_ config: GitConfig) throws {
        savedConfigs.append(config)
    }
}
