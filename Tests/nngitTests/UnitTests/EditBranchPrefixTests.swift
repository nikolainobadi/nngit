import Testing
import SwiftPicker
import GitShellKit
@testable import nngit

@MainActor
struct EditBranchPrefixTests {
    @Test("prints no branch prefixes exist when none are configured")
    func printsNoPrefixesWhenEmpty() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let loader = StubConfigLoader(initialConfig: .defaultConfig)
        let picker = MockPicker()
        let shell = MockGitShell(responses: [localGitCheck: "true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["edit-branch-prefix"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(output.contains("No branch prefixes exist."))
        #expect(loader.savedConfigs.isEmpty)
    }

    @Test("edits selected branch prefix and saves changes when confirmed")
    func editsSelectedPrefix() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let oldPrefix = BranchPrefix(name: "feature", requiresIssueNumber: false, issueNumberPrefix: nil)
        var initial = GitConfig.defaultConfig
        initial.branchPrefixList = [oldPrefix]
        let loader = StubConfigLoader(initialConfig: initial)
        let picker = MockPicker()
        picker.selectionResponses["Select a branch prefix to edit"] = 0
        picker.requiredInputResponses["Enter a new name for the prefix"] = "feat"
        picker.permissionResponses["Require an issue number when using this prefix?"] = true
        picker.requiredInputResponses["Enter a new issue number prefix (leave blank to keep existing or none)"] = "NEW-"
        picker.permissionResponses["Save these changes?"] = true
        let shell = MockGitShell(responses: [localGitCheck: "true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["edit-branch-prefix"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(picker.requiredPermissions.contains("Save these changes?"))
        #expect(loader.savedConfigs.count == 1)
        let saved = loader.savedConfigs.first!
        #expect(saved.branchPrefixList.count == 1)
        #expect(saved.branchPrefixList[0].name == "feat")
        #expect(saved.branchPrefixList[0].requiresIssueNumber)
        #expect(saved.branchPrefixList[0].issueNumberPrefix == "NEW-")
        #expect(output.contains("Current:"))
        #expect(output.contains("  Name: feature"))
        #expect(output.contains("  Requires Issue Number: false"))
        #expect(output.contains("  Issue Number Prefix: "))
        #expect(output.contains("Updated:"))
        #expect(output.contains("  Name: feat"))
        #expect(output.contains("  Requires Issue Number: true"))
        #expect(output.contains("  Issue Number Prefix: NEW-"))
        #expect(output.contains("✅ Updated branch prefix: feature -> feat"))
    }

    @Test("aborts when saving changes is denied")
    func abortsWhenSaveDenied() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let oldPrefix = BranchPrefix(name: "hotfix", requiresIssueNumber: true, issueNumberPrefix: nil)
        var initial = GitConfig.defaultConfig
        initial.branchPrefixList = [oldPrefix]
        let loader = StubConfigLoader(initialConfig: initial)
        let picker = MockPicker()
        picker.selectionResponses["Select a branch prefix to edit"] = 0
        picker.requiredInputResponses["Enter a new name for the prefix"] = "hot"
        picker.permissionResponses["Require an issue number when using this prefix?"] = false
        picker.permissionResponses["Save these changes?"] = false
        let shell = MockGitShell(responses: [localGitCheck: "true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        do {
            _ = try Nngit.testRun(context: context, args: ["edit-branch-prefix"])
            #expect(false)
        } catch {
            #expect(loader.savedConfigs.isEmpty)
        }
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