import Testing
import NnShellKit
import SwiftPicker
import GitShellKit
@testable import nngit

@MainActor
struct DeleteBranchTests {
    @Test("prunes origin when flag provided")
    func prunesWithFlag() throws {
        let pruneCmd = makeGitCommand(.pruneOrigin, path: nil)
        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
        let results = [
            "true",                           // git rev-parse --is-inside-work-tree
            "Test User",                      // git config user.name
            "test@example.com",               // git config user.email
            "Test User,test@example.com",     // git log -1 --pretty=format:'%an,%ae' foo
            "",                               // git branch -d foo
            "origin",                         // git remote  
            ""                                // git remote prune origin
        ]

        let shell = MockShell(results: results, shouldThrowError: false)
        let picker = MockPicker(selectionResponses: ["Select which branches to delete": 0])
        let branch = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(localBranches: [branch])
        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)

        try runCommand(context: context, additionalArgs: ["--prune-origin"])

        #expect(shell.executedCommands.contains(pruneCmd))
        #expect(shell.executedCommands.contains(deleteFoo))
    }

//    @Test("uses config to automatically prune")
//    func prunesWithConfig() throws {
//        let pruneCmd = makeGitCommand(.pruneOrigin, path: nil)
//        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            makeGitCommand(.checkForRemote, path: nil): "origin",
//            pruneCmd: "",
//            deleteFoo: ""
//        ]
//        var config = GitConfig.defaultConfig
//        config.behaviors.pruneWhenDeleting = true
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        picker.selectionResponses["Select which branches to delete"] = 0
//        let branch = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
//        let loader = StubBranchLoader(branches: [branch])
//        let configLoader = StubConfigLoader(initialConfig: config)
//        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)
//
//        _ = try Nngit.testRun(context: context, args: ["delete-branch"])
//
//        #expect(shell.commands.contains(pruneCmd))
//        #expect(shell.commands.contains(deleteFoo))
//    }
//
//    @Test("does not prune without flag or config")
//    func noPruneByDefault() throws {
//        let pruneCmd = makeGitCommand(.pruneOrigin, path: nil)
//        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            deleteFoo: ""
//        ]
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        picker.selectionResponses["Select which branches to delete"] = 0
//        let branch = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
//        let loader = StubBranchLoader(branches: [branch])
//        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
//        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)
//
//        _ = try Nngit.testRun(context: context, args: ["delete-branch"])
//
//        #expect(!shell.commands.contains(pruneCmd))
//        #expect(shell.commands.contains(deleteFoo))
//    }
//
//    @Test("filters branches using search term")
//    func filtersWithSearch() throws {
//        let deleteFeature = makeGitCommand(.deleteBranch(name: "feature", forced: false), path: nil)
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            "git config user.name": "John Doe",
//            "git config user.email": "john@example.com",
//            "git log -1 --pretty=format:'%an,%ae' feature": "John Doe,john@example.com",
//            "git log -1 --pretty=format:'%an,%ae' bugfix": "John Doe,john@example.com",
//            deleteFeature: ""
//        ]
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        picker.selectionResponses["Select which branches to delete"] = 0
//        let branch1 = GitBranch(name: "main", isMerged: true, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
//        let branch2 = GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
//        let branch3 = GitBranch(name: "bugfix", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
//        let loader = StubBranchLoader(branches: [branch1, branch2, branch3])
//        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
//        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)
//
//        try Nngit.testRun(context: context, args: ["delete-branch", "fea"])
//
//        #expect(shell.commands.contains(deleteFeature))
//        #expect(!shell.commands.contains(makeGitCommand(.deleteBranch(name: "bugfix", forced: false), path: nil)))
//    }
//
//    @Test("filters branches by author")
//    func filtersByAuthor() throws {
//        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            "git config user.name": "John Doe",
//            "git config user.email": "john@example.com",
//            "git log -1 --pretty=format:'%an,%ae' foo": "John Doe,john@example.com",
//            "git log -1 --pretty=format:'%an,%ae' bar": "Jane Smith,jane@example.com",
//            deleteFoo: ""
//        ]
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        picker.selectionResponses["Select which branches to delete"] = 0
//        let foo = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
//        let bar = GitBranch(name: "bar", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
//        let loader = StubBranchLoader(branches: [foo, bar])
//        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
//        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)
//
//        try Nngit.testRun(context: context, args: ["delete-branch"])
//
//        #expect(shell.commands.contains(deleteFoo))
//        #expect(!shell.commands.contains(makeGitCommand(.deleteBranch(name: "bar", forced: false), path: nil)))
//    }
//
//    @Test("includes branches from all authors with flag")
//    func includeAllFlag() throws {
//        let deleteBar = makeGitCommand(.deleteBranch(name: "bar", forced: false), path: nil)
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            deleteBar: ""
//        ]
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        picker.selectionResponses["Select which branches to delete"] = 1
//        let foo = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
//        let bar = GitBranch(name: "bar", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
//        let loader = StubBranchLoader(branches: [foo, bar])
//        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
//        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)
//
//        try Nngit.testRun(context: context, args: ["delete-branch", "--include-all"])
//
//        #expect(shell.commands.contains(deleteBar))
//        #expect(!shell.commands.contains(where: { $0.contains("git log -1") }))
//    }
//
//    @Test("deletes all merged branches with flag")
//    func deleteAllMerged() throws {
//        let deleteFoo = makeGitCommand(.deleteBranch(name: "foo", forced: false), path: nil)
//        let deleteBar = makeGitCommand(.deleteBranch(name: "bar", forced: false), path: nil)
//        let responses = [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            deleteFoo: "",
//            deleteBar: ""
//        ]
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        let foo = GitBranch(name: "foo", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
//        let bar = GitBranch(name: "bar", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
//        let loader = StubBranchLoader(branches: [foo, bar])
//        let configLoader = StubConfigLoader(initialConfig: .defaultConfig)
//        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: loader)
//
//        try Nngit.testRun(context: context, args: ["delete-branch", "--all-merged"])
//
//        #expect(shell.commands.contains(deleteFoo))
//        #expect(shell.commands.contains(deleteBar))
//    }
//    
//    @Test("uses MyBranch array for selection when available")
//    func usesMyBranchesForSelection() throws {
//        let getCurrentBranch = makeGitCommand(.getCurrentBranchName, path: nil)
//        let deleteFeature = makeGitCommand(.deleteBranch(name: "feature-branch", forced: false), path: nil)
//        
//        // Create config with MyBranches
//        var config = GitConfig.defaultConfig
//        config.myBranches = [
//            MyBranch(name: "feature-branch", description: "My feature"),
//            MyBranch(name: "main", description: "Main branch"), // Should be filtered out as default
//            MyBranch(name: "deleted-branch", description: "Gone") // Should be filtered out as non-existent
//        ]
//        
//        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
//        let branch2 = GitBranch(name: "feature-branch", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
//        let branchLoader = StubBranchLoader(branches: [branch1, branch2])
//        
//        let shell = MockGitShell(responses: [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            getCurrentBranch: "main",
//            deleteFeature: ""
//        ])
//        
//        let picker = MockPicker()
//        picker.selectionResponses["Select which tracked branches to delete"] = 0 // Select first MyBranch
//        
//        let configLoader = StubConfigLoader(initialConfig: config)
//        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)
//
//        _ = try Nngit.testRun(context: context, args: ["delete-branch"])
//
//        #expect(shell.commands.contains(getCurrentBranch))
//        #expect(shell.commands.contains(deleteFeature))
//        
//        // Verify the deleted branch was removed from myBranches
//        #expect(configLoader.savedConfig != nil)
//        let savedConfig = try #require(configLoader.savedConfig)
//        #expect(savedConfig.myBranches.count == 2) // One branch deleted
//        #expect(!savedConfig.myBranches.contains { $0.name == "feature-branch" })
//    }
//    
//    @Test("removes deleted branches from myBranches array in normal mode")
//    func removesDeletedBranchesFromMyBranchesInNormalMode() throws {
//        let deleteFeature = makeGitCommand(.deleteBranch(name: "feature-branch", forced: false), path: nil)
//        
//        // Create config with MyBranches - using search to trigger normal mode
//        var config = GitConfig.defaultConfig
//        config.myBranches = [
//            MyBranch(name: "feature-branch", description: "My feature"),
//            MyBranch(name: "other-branch", description: "Other branch")
//        ]
//        
//        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
//        let branch2 = GitBranch(name: "feature-branch", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
//        let branchLoader = StubBranchLoader(branches: [branch1, branch2])
//        
//        let shell = MockGitShell(responses: [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            "git config user.name": "John Doe",
//            "git config user.email": "john@example.com",
//            "git log -1 --pretty=format:'%an,%ae' feature-branch": "John Doe,john@example.com",
//            deleteFeature: ""
//        ])
//        
//        let picker = MockPicker()
//        picker.selectionResponses["Select which branches to delete"] = 0 // Select the branch
//        
//        let configLoader = StubConfigLoader(initialConfig: config)
//        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)
//
//        _ = try Nngit.testRun(context: context, args: ["delete-branch", "feature"]) // Search triggers normal mode
//
//        #expect(shell.commands.contains(deleteFeature))
//        
//        // Verify the deleted branch was removed from myBranches
//        #expect(configLoader.savedConfig != nil)
//        let savedConfig = try #require(configLoader.savedConfig)
//        #expect(savedConfig.myBranches.count == 1) // One branch deleted
//        #expect(!savedConfig.myBranches.contains { $0.name == "feature-branch" })
//        #expect(savedConfig.myBranches.contains { $0.name == "other-branch" })
//    }
//    
//    @Test("falls back to normal behavior when MyBranch conditions not met")
//    func fallsBackWhenMyBranchConditionsNotMet() throws {
//        let deleteFeature = makeGitCommand(.deleteBranch(name: "feature", forced: false), path: nil)
//        
//        // Config with MyBranches but using --include-all should fall back
//        var config = GitConfig.defaultConfig
//        config.myBranches = [MyBranch(name: "feature", description: "My feature")]
//        
//        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
//        let branch2 = GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
//        let branchLoader = StubBranchLoader(branches: [branch1, branch2])
//        
//        let shell = MockGitShell(responses: [
//            makeGitCommand(.localGitCheck, path: nil): "true",
//            deleteFeature: ""
//        ])
//        
//        let picker = MockPicker()
//        picker.selectionResponses["Select which branches to delete"] = 0
//        
//        let configLoader = StubConfigLoader(initialConfig: config)
//        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)
//
//        _ = try Nngit.testRun(context: context, args: ["delete-branch", "--include-all"])
//
//        #expect(shell.commands.contains(deleteFeature))
//        // Should not use MyBranches picker message - verified by testing normal flow
//        #expect(!shell.commands.contains(where: { $0.contains("git log -1") }))
//    }
}


// MARK: - Run Method
private extension DeleteBranchTests {
    func runCommand(context: MockContext, additionalArgs: [String] = []) throws {
        try Nngit.testRun(context: context, args: ["delete-branch"] + additionalArgs)
    }
}
