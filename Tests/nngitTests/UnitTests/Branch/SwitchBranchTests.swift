import Testing
import SwiftPicker
import GitShellKit
@testable import nngit

@MainActor
struct SwitchBranchTests {
    @Test("switches without prompting when exact branch name is provided")
    func switchesExactMatch() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let switchCmd = makeGitCommand(.switchBranch(branchName: "dev"), path: nil)
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "dev", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branch3 = GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [branch1, branch2, branch3])
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            "git config user.name": "John Doe",
            "git config user.email": "john@example.com",
            "git log -1 --pretty=format:'%an,%ae' dev": "John Doe,john@example.com",
            "git log -1 --pretty=format:'%an,%ae' feature": "Jane Smith,jane@example.com",
            switchCmd: ""
        ])
        let picker = MockPicker()
        let configLoader = StubSwitchBranchConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch", "dev"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(switchCmd))
        #expect(output.isEmpty)
    }

    @Test("prints no branches found matching search term when none match")
    func printsNoMatchForSearch() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "dev", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [branch1, branch2])
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            "git config user.name": "John Doe",
            "git config user.email": "john@example.com",
            "git log -1 --pretty=format:'%an,%ae' dev": "John Doe,john@example.com"
        ])
        let picker = MockPicker()
        let configLoader = StubSwitchBranchConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch", "xyz"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(output.contains("No branches found matching 'xyz'"))
    }

    @Test("prompts to select branch when no search provided")
    func promptsAndSwitches() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let switchCmd = makeGitCommand(.switchBranch(branchName: "feature"), path: nil)
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [branch1, branch2])
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            "git config user.name": "John Doe",
            "git config user.email": "john@example.com",
            "git log -1 --pretty=format:'%an,%ae' feature": "John Doe,john@example.com",
            switchCmd: ""
        ])
        let picker = MockPicker()
        picker.selectionResponses["Select a branch (switching from main)"] = 0
        let configLoader = StubSwitchBranchConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(switchCmd))
        #expect(output.isEmpty)
    }

    @Test("shows all branches when no git user is configured")
    func noUserConfigShowsAll() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let switchCmd = makeGitCommand(.switchBranch(branchName: "dev"), path: nil)
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "dev", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [branch1, branch2])
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            "git config user.name": "",
            "git config --global user.name": "",
            "git config user.email": "",
            "git config --global user.email": "",
            switchCmd: ""
        ])
        let picker = MockPicker()
        let configLoader = StubSwitchBranchConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch", "dev"])

        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(switchCmd))
        #expect(!shell.commands.contains(where: { $0.contains("git log -1") }))
        #expect(output.isEmpty)
    }

    @Test("includes branches from all authors with flag")
    func includeAllFlag() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let switchCmd = makeGitCommand(.switchBranch(branchName: "dev"), path: nil)
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "dev", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [branch1, branch2])
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            switchCmd: ""
        ])
        let picker = MockPicker()
        picker.selectionResponses["Select a branch (switching from main)"] = 1
        let configLoader = StubSwitchBranchConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch", "--include-all"])

        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(switchCmd))
        #expect(!shell.commands.contains(where: { $0.contains("git log -1") }))
        #expect(output.isEmpty)
    }
    
    @Test("uses MyBranch array for selection when available")
    func usesMyBranchesForSelection() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let getCurrentBranch = makeGitCommand(.getCurrentBranchName, path: nil)
        let switchCmd = makeGitCommand(.switchBranch(branchName: "feature-branch"), path: nil)
        
        // Create config with MyBranches
        var config = GitConfig.defaultConfig
        config.myBranches = [
            MyBranch(name: "feature-branch", description: "My feature"),
            MyBranch(name: "main", description: "Main branch"), // This should be filtered out as current
            MyBranch(name: "deleted-branch", description: "Gone") // This should be filtered out as non-existent
        ]
        let configLoader = StubSwitchBranchConfigLoader(initialConfig: config)
        
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature-branch", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(branches: [branch1, branch2])
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            getCurrentBranch: "main",
            switchCmd: ""
        ])
        
        let picker = MockPicker()
        picker.selectionResponses["Select a branch"] = 0 // Select first MyBranch
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch"])

        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(getCurrentBranch))
        #expect(shell.commands.contains(switchCmd))
        #expect(output.isEmpty)
    }
    
    @Test("falls back to normal behavior when MyBranch conditions not met")
    func fallsBackWhenMyBranchConditionsNotMet() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let switchCmd = makeGitCommand(.switchBranch(branchName: "feature"), path: nil)
        
        // Config with MyBranches but using remote location should fall back
        var config = GitConfig.defaultConfig
        config.myBranches = [MyBranch(name: "feature-branch", description: "My feature")]
        let configLoader = StubSwitchBranchConfigLoader(initialConfig: config)
        
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(branches: [branch1, branch2])
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            "git config user.name": "John Doe",
            "git config user.email": "john@example.com", 
            "git log -1 --pretty=format:'%an,%ae' feature": "John Doe,john@example.com",
            switchCmd: ""
        ])
        let picker = MockPicker()
        picker.selectionResponses["Select a branch (switching from main)"] = 0
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch", "--branch-location", "remote"])

        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(switchCmd))
        #expect(output.isEmpty)
    }
}

// MARK: - Helpers
private class StubBranchLoader: GitBranchLoader {
    private let branches: [GitBranch]

    init(branches: [GitBranch]) {
        self.branches = branches
    }

    func loadBranches(
        from location: BranchLocation,
        shell: GitShell,
        mainBranchName: String,
        loadMergeStatus: Bool,
        loadCreationDate: Bool,
        loadSyncStatus: Bool
    ) throws -> [GitBranch] {
        return branches
    }

    func loadBranchNames(from location: BranchLocation, shell: GitShell) throws -> [String] {
        return branches.map { $0.isCurrentBranch ? "* \($0.name)" : $0.name }
    }

    func loadBranches(
        for names: [String],
        shell: GitShell,
        mainBranchName: String,
        loadMergeStatus: Bool,
        loadCreationDate: Bool,
        loadSyncStatus: Bool
    ) throws -> [GitBranch] {
        return branches.filter { names.contains($0.isCurrentBranch ? "* \($0.name)" : $0.name) }
    }
}

private class StubSwitchBranchConfigLoader: GitConfigLoader {
    private let initialConfig: GitConfig
    
    init(initialConfig: GitConfig) {
        self.initialConfig = initialConfig
    }
    
    func loadConfig(picker: Picker) throws -> GitConfig {
        return initialConfig
    }
    
    func save(_ config: GitConfig) throws {
        // No-op for testing
    }
}
