import Testing
import SwiftPicker
import GitShellKit
@testable import nngit

@MainActor
struct NewBranchTests {
    @Test("creates branch with provided name and no prefix when remote missing")
    func createsWithNameNoPrefix() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let checkRemote = makeGitCommand(.checkForRemote, path: nil)
        let newBranchCmd = makeGitCommand(.newBranch(branchName: "foo"), path: nil)
        let loader = StubNewBranchConfigLoader(initialConfig: .defaultConfig)
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            checkRemote: "",
            newBranchCmd: ""
        ])
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["new-branch", "foo"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(checkRemote))
        #expect(shell.commands.contains(newBranchCmd))
        #expect(output.contains("✅ Created and switched to branch: foo"))
    }

    @Test("rebases when remote exists and on default branch with permission")
    func rebasesBeforeBranching() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let checkRemote = makeGitCommand(.checkForRemote, path: nil)
        let currentBranchCmd = makeGitCommand(.getCurrentBranchName, path: nil)
        let pullRebase = "git pull --rebase"
        let newBranchCmd = makeGitCommand(.newBranch(branchName: "bar"), path: nil)
        var config = GitConfig.defaultConfig
        config.behaviors.rebaseWhenBranchingFromDefault = true
        let loader = StubNewBranchConfigLoader(initialConfig: config)
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            checkRemote: "origin",
            currentBranchCmd: "main",
            pullRebase: "",
            newBranchCmd: ""
        ])
        let picker = MockPicker()
        picker.permissionResponses["Would you like to rebase before creating your new branch?"] = true
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        _ = try Nngit.testRun(context: context, args: ["new-branch", "bar"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(checkRemote))
        #expect(shell.commands.contains(currentBranchCmd))
        #expect(shell.commands.contains(pullRebase))
        #expect(shell.commands.contains(newBranchCmd))
    }

    @Test("uses branch prefix requiring issue and prompts for missing issue number")
    func appliesPrefixAndPromptsIssue() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let checkRemote = makeGitCommand(.checkForRemote, path: nil)
        let newBranchCmd = makeGitCommand(.newBranch(branchName: "feat/42/test-branch"), path: nil)
        var config = GitConfig.defaultConfig
        config.branchPrefixes = [BranchPrefix(name: "feat", requiresIssueNumber: true)]
        let loader = StubNewBranchConfigLoader(initialConfig: config)
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            checkRemote: "",
            newBranchCmd: ""
        ])
        let picker = MockPicker()
        picker.selectionResponses["Select a branch prefix"] = 0
        picker.requiredInputResponses["Enter an issue number"] = "42"
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["new-branch", "test-branch"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(checkRemote))
        #expect(picker.requiredPermissions.isEmpty)
        #expect(shell.commands.contains(newBranchCmd))
        #expect(output.contains("✅ Created and switched to branch: feat/42/test-branch"))
    }

    @Test("creates branch with no prefix when flag is used")
    func usesNoPrefixFlag() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let checkRemote = makeGitCommand(.checkForRemote, path: nil)
        let newBranchCmd = makeGitCommand(.newBranch(branchName: "foo"), path: nil)
        var config = GitConfig.defaultConfig
        config.branchPrefixes = [BranchPrefix(name: "feat", requiresIssueNumber: false)]
        let loader = StubNewBranchConfigLoader(initialConfig: config)
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            checkRemote: "",
            newBranchCmd: ""
        ])
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["new-branch", "foo", "--no-prefix"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(checkRemote))
        #expect(shell.commands.contains(newBranchCmd))
        #expect(output.contains("✅ Created and switched to branch: foo"))
    }

    @Test("allows selecting no prefix when prompted")
    func selectsNoPrefixFromPicker() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let checkRemote = makeGitCommand(.checkForRemote, path: nil)
        let newBranchCmd = makeGitCommand(.newBranch(branchName: "bar"), path: nil)
        var config = GitConfig.defaultConfig
        config.branchPrefixes = [BranchPrefix(name: "feat", requiresIssueNumber: false)]
        let loader = StubNewBranchConfigLoader(initialConfig: config)
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            checkRemote: "",
            newBranchCmd: ""
        ])
        let picker = MockPicker()
        picker.selectionResponses["Select a branch prefix"] = 1
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["new-branch", "bar"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(checkRemote))
        #expect(shell.commands.contains(newBranchCmd))
        #expect(output.contains("✅ Created and switched to branch: bar"))
    }
    
    @Test("adds created branch to myBranches array and saves config")
    func addsBranchToMyBranchesArray() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let checkRemote = makeGitCommand(.checkForRemote, path: nil)
        let newBranchCmd = makeGitCommand(.newBranch(branchName: "test-branch"), path: nil)
        let loader = StubNewBranchConfigLoader(initialConfig: .defaultConfig)
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            checkRemote: "",
            newBranchCmd: ""
        ])
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, configLoader: loader)

        _ = try Nngit.testRun(context: context, args: ["new-branch", "test-branch"])
        
        // Verify the config was saved with the new branch
        #expect(loader.savedConfig != nil)
        let savedConfig = try #require(loader.savedConfig)
        #expect(savedConfig.myBranches.count == 1)
        #expect(savedConfig.myBranches[0].name == "test-branch")
        #expect(savedConfig.myBranches[0].description == "test-branch")
    }
}

// MARK: - Helpers
private class StubNewBranchConfigLoader: GitConfigLoader {
    private let initialConfig: GitConfig
    var savedConfig: GitConfig?
    
    init(initialConfig: GitConfig) { self.initialConfig = initialConfig }
    func loadConfig(picker: Picker) throws -> GitConfig { initialConfig }
    func save(_ config: GitConfig) throws { 
        savedConfig = config
    }
}