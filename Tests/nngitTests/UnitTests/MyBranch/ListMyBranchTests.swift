import Testing
import SwiftPicker
import GitShellKit
@testable import nngit

@MainActor
struct ListMyBranchTests {
    @Test("lists branches with default formatting")
    func listsDefault() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let getCurrentBranch = makeGitCommand(.getCurrentBranchName, path: nil)
        var config = GitConfig.defaultConfig
        config.myBranches = [
            MyBranch(name: "feature-1", description: "First feature"),
            MyBranch(name: "main", description: "main"), // Same as branch name
            MyBranch(name: "feature-2", description: "Second feature")
        ]
        
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature-1", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branch3 = GitBranch(name: "feature-2", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(branches: [branch1, branch2, branch3])
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            getCurrentBranch: "main"
        ])
        
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "list"])

        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(getCurrentBranch))
        #expect(output.contains("Tracked MyBranches (3):"))
        #expect(output.contains("feature-1 - First feature"))
        #expect(output.contains("feature-2 - Second feature"))
        #expect(output.contains("main (current)")) // Current branch indicator
    }
    
    @Test("lists branches names only")
    func listsNamesOnly() throws {
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

        let output = try Nngit.testRun(context: context, args: ["my-branches", "list", "--names-only"])

        #expect(output.contains("Tracked MyBranches (2):"))
        #expect(output.contains("  feature-1"))
        #expect(output.contains("  feature-2"))
        #expect(!output.contains("First feature")) // Should not show descriptions
        #expect(!output.contains("Second feature"))
    }
    
    @Test("lists branches with detailed information")
    func listsDetailed() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let getCurrentBranch = makeGitCommand(.getCurrentBranchName, path: nil)
        var config = GitConfig.defaultConfig
        config.myBranches = [
            MyBranch(name: "feature-1", description: "First feature"),
            MyBranch(name: "main", description: "main") // Same as branch name
        ]
        
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature-1", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(branches: [branch1, branch2])
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            getCurrentBranch: "main"
        ])
        
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "list", "--detailed"])

        #expect(output.contains("Tracked MyBranches (2):"))
        #expect(output.contains("📋 feature-1"))
        #expect(output.contains("Description: First feature"))
        #expect(output.contains("Added to MyBranches:"))
        #expect(output.contains("📋 main (current)"))
    }
    
    @Test("shows deleted branch status")
    func showsDeletedBranchStatus() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let getCurrentBranch = makeGitCommand(.getCurrentBranchName, path: nil)
        var config = GitConfig.defaultConfig
        config.myBranches = [
            MyBranch(name: "feature-1", description: "First feature"),
            MyBranch(name: "deleted-branch", description: "Gone branch")
        ]
        
        // Only feature-1 exists in git, deleted-branch is missing
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature-1", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(branches: [branch1, branch2])
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            getCurrentBranch: "main"
        ])
        
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "list"])

        #expect(output.contains("feature-1 - First feature"))
        #expect(output.contains("deleted-branch - Gone branch (deleted)"))
    }
    
    @Test("handles empty MyBranches gracefully")
    func handlesEmptyMyBranches() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let config = GitConfig.defaultConfig // Empty myBranches by default
        let shell = MockGitShell(responses: [
            localGitCheck: "true"
        ])
        
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "list"])

        #expect(output.contains("No branches are currently tracked in MyBranches."))
        #expect(output.contains("Use 'nngit my-branches add' to start tracking branches."))
    }
    
    @Test("sorts branches alphabetically")
    func sortsBranchesAlphabetically() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let getCurrentBranch = makeGitCommand(.getCurrentBranchName, path: nil)
        var config = GitConfig.defaultConfig
        config.myBranches = [
            MyBranch(name: "zebra-branch"),
            MyBranch(name: "alpha-branch"),
            MyBranch(name: "main")
        ]
        
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "alpha-branch", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branch3 = GitBranch(name: "zebra-branch", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(branches: [branch1, branch2, branch3])
        
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            getCurrentBranch: "main"
        ])
        
        let picker = MockPicker()
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["my-branches", "list", "--names-only"])

        let lines = output.components(separatedBy: .newlines)
        let branchLines = lines.filter { $0.hasPrefix("  ") }
        
        // Should be sorted alphabetically
        #expect(branchLines.count == 3)
        #expect(branchLines[0].contains("alpha-branch"))
        #expect(branchLines[1].contains("main"))
        #expect(branchLines[2].contains("zebra-branch"))
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
