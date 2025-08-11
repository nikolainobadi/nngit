import Testing
import SwiftPicker
import GitShellKit
@testable import nngit

@MainActor
struct AddMyBranchTests {
    @Test("adds specific branch to MyBranches")
    func addsSpecificBranch() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let config = GitConfig.defaultConfig
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature-branch", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(branches: [branch1, branch2])
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true"
        ])
        
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "add", "feature-branch"])

        #expect(shell.commands.contains(localGitCheck))
        #expect(output.contains("✅ Added branch 'feature-branch' to MyBranches."))
        
        // Verify the branch was added to myBranches
        #expect(configLoader.savedConfig != nil)
        let savedConfig = try #require(configLoader.savedConfig)
        #expect(savedConfig.myBranches.count == 1)
        #expect(savedConfig.myBranches[0].name == "feature-branch")
        #expect(savedConfig.myBranches[0].description == "feature-branch")
    }
    
    @Test("adds specific branch with custom description")
    func addsSpecificBranchWithDescription() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let config = GitConfig.defaultConfig
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature-branch", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(branches: [branch1, branch2])
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true"
        ])
        
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "add", "feature-branch", "--description", "My awesome feature"])

        #expect(output.contains("✅ Added branch 'feature-branch' to MyBranches."))
        
        let savedConfig = try #require(configLoader.savedConfig)
        #expect(savedConfig.myBranches.count == 1)
        #expect(savedConfig.myBranches[0].name == "feature-branch")
        #expect(savedConfig.myBranches[0].description == "My awesome feature")
    }
    
    @Test("rejects non-existent branch")
    func rejectsNonExistentBranch() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let config = GitConfig.defaultConfig
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(branches: [branch1])
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true"
        ])
        
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "add", "non-existent"])

        #expect(output.contains("❌ Branch 'non-existent' does not exist locally."))
        #expect(configLoader.savedConfig == nil) // Should not save if branch doesn't exist
    }
    
    @Test("rejects already tracked branch")
    func rejectsAlreadyTrackedBranch() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        var config = GitConfig.defaultConfig
        config.myBranches = [MyBranch(name: "feature-branch", description: "Already tracked")]
        
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature-branch", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(branches: [branch1, branch2])
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true"
        ])
        
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "add", "feature-branch"])

        #expect(output.contains("Branch 'feature-branch' is already tracked in MyBranches."))
        #expect(configLoader.savedConfig == nil) // Should not save if already tracked
    }
    
    @Test("adds all branches with --all flag")
    func addsAllBranches() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        var config = GitConfig.defaultConfig
        config.myBranches = [MyBranch(name: "main", description: "Main branch")] // One already tracked
        
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature-1", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branch3 = GitBranch(name: "feature-2", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(branches: [branch1, branch2, branch3])
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true"
        ])
        
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "add", "--all"])

        #expect(output.contains("✅ Added 2 branches to MyBranches: feature-1, feature-2"))
        
        let savedConfig = try #require(configLoader.savedConfig)
        #expect(savedConfig.myBranches.count == 3) // 1 existing + 2 new
        #expect(savedConfig.myBranches.contains { $0.name == "feature-1" })
        #expect(savedConfig.myBranches.contains { $0.name == "feature-2" })
    }
    
    @Test("prompts for branch selection when no arguments provided")
    func promptsForBranchSelection() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let config = GitConfig.defaultConfig
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature-1", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branch3 = GitBranch(name: "feature-2", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(branches: [branch1, branch2, branch3])
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true"
        ])
        
        let picker = MockPicker()
        picker.selectionResponses["Select branches to add to MyBranches"] = 0 // Select first available branch
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "add"])

        #expect(output.contains("✅ Added 1 branches to MyBranches: main"))
        
        let savedConfig = try #require(configLoader.savedConfig)
        #expect(savedConfig.myBranches.count == 1)
        #expect(savedConfig.myBranches[0].name == "main")
    }
}

// MARK: - Helpers
private class StubBranchLoader: GitBranchLoader {
    private let branches: [GitBranch]
    init(branches: [GitBranch]) { self.branches = branches }
    
    func loadBranches(
        from location: BranchLocation,
        shell: GitShell,
        mainBranchName: String,
        loadMergeStatus: Bool,
        loadCreationDate: Bool,
        loadSyncStatus: Bool
    ) throws -> [GitBranch] { branches }

    func loadBranchNames(from location: BranchLocation, shell: GitShell) throws -> [String] {
        branches.map { $0.isCurrentBranch ? "* \($0.name)" : $0.name }
    }

    func loadBranches(
        for names: [String],
        shell: GitShell,
        mainBranchName: String,
        loadMergeStatus: Bool,
        loadCreationDate: Bool,
        loadSyncStatus: Bool
    ) throws -> [GitBranch] {
        branches.filter { names.contains($0.isCurrentBranch ? "* \($0.name)" : $0.name) }
    }
}

private class StubConfigLoader: GitConfigLoader {
    private let initialConfig: GitConfig
    var savedConfig: GitConfig?
    
    init(initialConfig: GitConfig) { self.initialConfig = initialConfig }
    func loadConfig(picker: Picker) throws -> GitConfig { initialConfig }
    func save(_ config: GitConfig) throws { 
        savedConfig = config
    }
}
