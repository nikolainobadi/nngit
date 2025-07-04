import Testing
import SwiftPicker
import GitShellKit
@testable import nngit

@MainActor
struct EditConfigTests {
    @Test("updates config using arguments")
    func updatesWithArguments() throws {
        let localCheck = makeGitCommand(.localGitCheck, path: nil)
        let initial = GitConfig.defaultConfig
        let loader = StubConfigLoader(initialConfig: initial)
        let picker = MockPicker()
        let shell = MockGitShell(responses: [localCheck: "true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: [
            "edit-config",
            "--default-branch", "dev",
            "--rebase-when-branching", "false",
            "--prune-when-deleting", "true",
            "--load-merge-status", "false",
            "--load-creation-date", "false",
            "--load-sync-status", "false"
        ])

        #expect(shell.commands.contains(localCheck))
        #expect(loader.savedConfigs.count == 1)
        let saved = loader.savedConfigs.first!
        #expect(saved.defaultBranch == "dev")
        #expect(!saved.rebaseWhenBranchingFromDefaultBranch)
        #expect(saved.pruneWhenDeletingBranches)
        #expect(!saved.loadMergeStatusWhenLoadingBranches)
        #expect(!saved.loadCreationDateWhenLoadingBranches)
        #expect(!saved.loadSyncStatusWhenLoadingBranches)
        #expect(output.contains("✅ Updated configuration"))
    }

    @Test("prompts for values when no arguments provided")
    func promptsForValues() throws {
        let localCheck = makeGitCommand(.localGitCheck, path: nil)
        let initial = GitConfig.defaultConfig
        let loader = StubConfigLoader(initialConfig: initial)
        let picker = MockPicker()
        picker.selectionResponses["Select which values you would like to edit"] = 0
        picker.requiredInputResponses["Enter a new default branch name (leave blank to keep 'main')"] = "develop"
        picker.permissionResponses["Save these changes?"] = true
        let shell = MockGitShell(responses: [localCheck: "true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["edit-config"])

        #expect(shell.commands.contains(localCheck))
        #expect(loader.savedConfigs.count == 1)
        let saved = loader.savedConfigs.first!
        #expect(saved.defaultBranch == "develop")
        #expect(saved.rebaseWhenBranchingFromDefaultBranch == initial.rebaseWhenBranchingFromDefaultBranch)
        #expect(saved.pruneWhenDeletingBranches == initial.pruneWhenDeletingBranches)
        #expect(saved.loadMergeStatusWhenLoadingBranches == initial.loadMergeStatusWhenLoadingBranches)
        #expect(saved.loadCreationDateWhenLoadingBranches == initial.loadCreationDateWhenLoadingBranches)
        #expect(saved.loadSyncStatusWhenLoadingBranches == initial.loadSyncStatusWhenLoadingBranches)
        #expect(output.contains("Current:"))
        #expect(output.contains("Updated:"))
        #expect(picker.requiredPermissions.contains("Save these changes?"))
    }

    @Test("prints no changes when nothing updated")
    func printsNoChanges() throws {
        let localCheck = makeGitCommand(.localGitCheck, path: nil)
        let initial = GitConfig.defaultConfig
        let loader = StubConfigLoader(initialConfig: initial)
        let picker = MockPicker()
        let shell = MockGitShell(responses: [localCheck: "true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: [
            "edit-config",
            "--default-branch", initial.defaultBranch,
            "--rebase-when-branching", String(initial.rebaseWhenBranchingFromDefaultBranch),
            "--prune-when-deleting", String(initial.pruneWhenDeletingBranches),
            "--load-merge-status", String(initial.loadMergeStatusWhenLoadingBranches),
            "--load-creation-date", String(initial.loadCreationDateWhenLoadingBranches),
            "--load-sync-status", String(initial.loadSyncStatusWhenLoadingBranches)
        ])

        #expect(shell.commands.contains(localCheck))
        #expect(loader.savedConfigs.isEmpty)
        #expect(output.contains("No changes to save."))
    }
}

private class StubConfigLoader: GitConfigLoader {
    private(set) var savedConfigs: [GitConfig] = []
    private let initialConfig: GitConfig

    init(initialConfig: GitConfig) { self.initialConfig = initialConfig }

    func loadConfig(picker: Picker) throws -> GitConfig { initialConfig }

    func save(_ config: GitConfig) throws { savedConfigs.append(config) }
}
