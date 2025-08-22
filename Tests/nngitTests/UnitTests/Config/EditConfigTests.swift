//import Testing
//import SwiftPicker
//import GitShellKit
//@testable import nngit
//
//@MainActor
//struct EditConfigTests {
//    @Test("updates config using arguments")
//    func updatesWithArguments() throws {
//        let localCheck = makeGitCommand(.localGitCheck, path: nil)
//        let initial = GitConfig.defaultConfig
//        let loader = StubConfigLoader(initialConfig: initial)
//        let picker = MockPicker()
//        let shell = MockGitShell(responses: [localCheck: "true"])
//        let context = MockContext(picker: picker, shell: shell, configLoader: loader)
//
//        let output = try runCommand(context: context, args: [
//            "--default-branch", "dev",
//            "--rebase-when-branching", "false",
//            "--prune-when-deleting", "true",
//            "--load-merge-status", "false",
//            "--load-creation-date", "false",
//            "--load-sync-status", "false"
//        ])
//
//        #expect(shell.commands.contains(localCheck))
//        #expect(loader.savedConfigs.count == 1)
//        let saved = loader.savedConfigs.first!
//        #expect(saved.branches.defaultBranch == "dev")
//        #expect(!saved.behaviors.rebaseWhenBranchingFromDefault)
//        #expect(saved.behaviors.pruneWhenDeleting)
//        #expect(!saved.loading.loadMergeStatus)
//        #expect(!saved.loading.loadCreationDate)
//        #expect(!saved.loading.loadSyncStatus)
//        #expect(output.contains("✅ Updated configuration"))
//    }
//
//    @Test("prompts for values when no arguments provided")
//    func promptsForValues() throws {
//        let localCheck = makeGitCommand(.localGitCheck, path: nil)
//        let initial = GitConfig.defaultConfig
//        let loader = StubConfigLoader(initialConfig: initial)
//        let picker = MockPicker()
//        picker.selectionResponses["Select which values you would like to edit"] = 0
//        picker.requiredInputResponses["Enter a new default branch name (leave blank to keep 'main')"] = "develop"
//        picker.permissionResponses["Save these changes?"] = true
//        let shell = MockGitShell(responses: [localCheck: "true"])
//        let context = MockContext(picker: picker, shell: shell, configLoader: loader)
//
//        let output = try runCommand(context: context)
//
//        #expect(shell.commands.contains(localCheck))
//        #expect(loader.savedConfigs.count == 1)
//        let saved = loader.savedConfigs.first!
//        #expect(saved.branches.defaultBranch == "develop")
//        #expect(saved.behaviors.rebaseWhenBranchingFromDefault == initial.behaviors.rebaseWhenBranchingFromDefault)
//        #expect(saved.behaviors.pruneWhenDeleting == initial.behaviors.pruneWhenDeleting)
//        #expect(saved.loading.loadMergeStatus == initial.loading.loadMergeStatus)
//        #expect(saved.loading.loadCreationDate == initial.loading.loadCreationDate)
//        #expect(saved.loading.loadSyncStatus == initial.loading.loadSyncStatus)
//        #expect(output.contains("Current:"))
//        #expect(output.contains("Updated:"))
//        #expect(picker.requiredPermissions.contains("Save these changes?"))
//    }
//
//    @Test("prints no changes when nothing updated")
//    func printsNoChanges() throws {
//        let localCheck = makeGitCommand(.localGitCheck, path: nil)
//        let initial = GitConfig.defaultConfig
//        let loader = StubConfigLoader(initialConfig: initial)
//        let picker = MockPicker()
//        let shell = MockGitShell(responses: [localCheck: "true"])
//        let context = MockContext(picker: picker, shell: shell, configLoader: loader)
//
//        let output = try runCommand(context: context, args: [
//            "--default-branch", initial.branches.defaultBranch,
//            "--rebase-when-branching", String(initial.behaviors.rebaseWhenBranchingFromDefault),
//            "--prune-when-deleting", String(initial.behaviors.pruneWhenDeleting),
//            "--load-merge-status", String(initial.loading.loadMergeStatus),
//            "--load-creation-date", String(initial.loading.loadCreationDate),
//            "--load-sync-status", String(initial.loading.loadSyncStatus)
//        ])
//
//        #expect(shell.commands.contains(localCheck))
//        #expect(loader.savedConfigs.isEmpty)
//        #expect(output.contains("No changes to save."))
//    }
//}
//
//
//// MARK: - Helpers
//private extension EditConfigTests {
//    func runCommand(context: MockContext, args: [String] = []) throws -> String {
//        return try Nngit.testRun(context: context, args: ["config"] + args)
//    }
//    
//    final class StubConfigLoader: GitConfigLoader {
//        private let initialConfig: GitConfig
//        private(set) var savedConfigs: [GitConfig] = []
//
//        init(initialConfig: GitConfig) {
//            self.initialConfig = initialConfig
//        }
//
//        func loadConfig(picker: CommandLinePicker) throws -> GitConfig {
//            return initialConfig
//        }
//
//        func save(_ config: GitConfig) throws {
//            savedConfigs.append(config)
//        }
//    }
//}
