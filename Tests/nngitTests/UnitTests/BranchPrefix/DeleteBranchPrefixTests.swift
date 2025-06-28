import Testing
import SwiftPicker
import GitShellKit
@testable import nngit

@MainActor
struct DeleteBranchPrefixTests {
    @Test("prints no branch prefixes exist when none are configured")
    func printsNoPrefixesWhenEmpty() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let loader = StubConfigLoader(initialConfig: .defaultConfig)
        let picker = MockPicker()
        let shell = MockGitShell(responses: [localGitCheck: "true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["delete-branch-prefix"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(output.contains("No branch prefixes exist."))
        #expect(loader.savedConfigs.isEmpty)
    }

    @Test("deletes selected branch prefix when confirmed")
    func deletesSelectedPrefix() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let prefix1 = BranchPrefix(name: "feature", requiresIssueNumber: false, issueNumberPrefix: nil)
        let prefix2 = BranchPrefix(name: "bugfix", requiresIssueNumber: true, issueNumberPrefix: nil)
        var initial = GitConfig.defaultConfig
        initial.branchPrefixList = [prefix1, prefix2]
        let loader = StubConfigLoader(initialConfig: initial)
        let picker = MockPicker()
        picker.selectionResponses["Select a branch prefix to delete"] = 1
        picker.permissionResponses["Delete branch prefix 'bugfix'?"] = true
        let shell = MockGitShell(responses: [localGitCheck: "true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["delete-branch-prefix"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(picker.requiredPermissions.contains("Delete branch prefix 'bugfix'?") )
        #expect(loader.savedConfigs.count == 1)
        let saved = loader.savedConfigs.first!
        #expect(saved.branchPrefixList.count == 1)
        #expect(saved.branchPrefixList.first!.name == "feature")
        #expect(output.contains("✅ Deleted branch prefix: bugfix"))
    }

    @Test("aborts deletion when permission denied")
    func abortsWhenPermissionDenied() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let prefix = BranchPrefix(name: "release", requiresIssueNumber: false, issueNumberPrefix: nil)
        var initial = GitConfig.defaultConfig
        initial.branchPrefixList = [prefix]
        let loader = StubConfigLoader(initialConfig: initial)
        let picker = MockPicker()
        picker.selectionResponses["Select a branch prefix to delete"] = 0
        picker.permissionResponses["Delete branch prefix 'release'?"] = false
        let shell = MockGitShell(responses: [localGitCheck: "true"])
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        do {
            _ = try Nngit.testRun(context: context, args: ["delete-branch-prefix"])
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