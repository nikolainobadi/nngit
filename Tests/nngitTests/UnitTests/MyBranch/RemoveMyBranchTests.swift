import Testing
import SwiftPicker
import GitShellKit
@testable import nngit

@MainActor
struct RemoveMyBranchTests {
    @Test("removes specific branch from MyBranches")
    func removesSpecificBranch() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        var config = GitConfig.defaultConfig
        config.myBranches = [
            MyBranch(name: "feature-1", description: "First feature"),
            MyBranch(name: "feature-2", description: "Second feature")
        ]
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true"
        ])
        
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "remove", "feature-1"])

        #expect(shell.commands.contains(localGitCheck))
        #expect(output.contains("✅ Removed branch 'feature-1' from MyBranches."))
        
        // Verify the branch was removed from myBranches
        #expect(configLoader.savedConfig != nil)
        let savedConfig = try #require(configLoader.savedConfig)
        #expect(savedConfig.myBranches.count == 1)
        #expect(savedConfig.myBranches[0].name == "feature-2")
        #expect(!savedConfig.myBranches.contains { $0.name == "feature-1" })
    }
    
    @Test("rejects non-tracked branch")
    func rejectsNonTrackedBranch() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        var config = GitConfig.defaultConfig
        config.myBranches = [MyBranch(name: "feature-1", description: "First feature")]
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true"
        ])
        
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "remove", "non-tracked"])

        #expect(output.contains("❌ Branch 'non-tracked' is not tracked in MyBranches."))
        #expect(configLoader.savedConfig == nil) // Should not save if branch not tracked
    }
    
    @Test("removes all branches with --all flag")
    func removesAllBranches() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        var config = GitConfig.defaultConfig
        config.myBranches = [
            MyBranch(name: "feature-1", description: "First feature"),
            MyBranch(name: "feature-2", description: "Second feature"),
            MyBranch(name: "feature-3", description: "Third feature")
        ]
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true"
        ])
        
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "remove", "--all"])

        #expect(output.contains("✅ Removed all 3 branches from MyBranches."))
        
        let savedConfig = try #require(configLoader.savedConfig)
        #expect(savedConfig.myBranches.isEmpty)
    }
    
    @Test("prompts for branch selection when no arguments provided")
    func promptsForBranchSelection() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        var config = GitConfig.defaultConfig
        config.myBranches = [
            MyBranch(name: "feature-1", description: "First feature"),
            MyBranch(name: "feature-2", description: "Second feature")
        ]
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true"
        ])
        
        let picker = MockPicker()
        picker.selectionResponses["Select MyBranches to remove from tracking"] = 0 // Select first branch
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "remove"])

        #expect(output.contains("✅ Removed 1 branches from MyBranches: feature-1"))
        
        let savedConfig = try #require(configLoader.savedConfig)
        #expect(savedConfig.myBranches.count == 1)
        #expect(savedConfig.myBranches[0].name == "feature-2")
    }
    
    @Test("handles empty MyBranches gracefully")
    func handlesEmptyMyBranches() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        var config = GitConfig.defaultConfig // Empty myBranches by default
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true"
        ])
        
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "remove"])

        #expect(output.contains("No branches are currently tracked in MyBranches."))
        #expect(configLoader.savedConfig == nil) // Should not save if no branches to remove
    }
    
    @Test("handles no selection gracefully")
    func handlesNoSelectionGracefully() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        var config = GitConfig.defaultConfig
        config.myBranches = [MyBranch(name: "feature-1", description: "First feature")]
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true"
        ])
        
        let picker = MockPicker()
        // Don't set selectionResponses, so multiSelection returns empty array
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "remove"])

        #expect(output.contains("No branches selected."))
        #expect(configLoader.savedConfig == nil) // Should not save if no selection made
    }
}

// MARK: - Helpers
private class StubConfigLoader: GitConfigLoader {
    private let initialConfig: GitConfig
    var savedConfig: GitConfig?
    
    init(initialConfig: GitConfig) { self.initialConfig = initialConfig }
    func loadConfig(picker: Picker) throws -> GitConfig { initialConfig }
    func save(_ config: GitConfig) throws { 
        savedConfig = config
    }
}