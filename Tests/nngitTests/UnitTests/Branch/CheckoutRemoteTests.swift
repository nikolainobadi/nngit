import Testing
import SwiftPicker
import GitShellKit
import NnShellKit
@testable import nngit

@MainActor
struct CheckoutRemoteTests {
    @Test("checks out remote branch and adds to MyBranches")
    func checksOutRemoteBranch() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let config = GitConfig.defaultConfig
        
        // Mock remote branches (including origin/ prefix as they come from git)
        let remoteBranch1 = "origin/feature-1"
        let remoteBranch2 = "origin/feature-2"  
        let remoteBranch3 = "origin/main"
        
        // Mock local branches - feature-1 already exists locally
        let localBranch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let localBranch2 = GitBranch(name: "feature-1", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        
        let branchLoader = StubBranchLoader(
            remoteBranches: [remoteBranch1, remoteBranch2, remoteBranch3], 
            localBranches: [localBranch1, localBranch2]
        )
        
        let shellResults = [
            "true",                                    // git rev-parse --is-inside-work-tree
            "Test User",                               // git config user.name
            "test@example.com",                        // git config user.email
            "Test User,test@example.com",              // git log -1 --pretty=format:'%an,%ae' origin/feature-1
            "Test User,test@example.com",              // git log -1 --pretty=format:'%an,%ae' origin/feature-2
            "Other User,other@example.com",            // git log -1 --pretty=format:'%an,%ae' origin/main
            "2025-08-21T10:00:00Z",                    // git log -1 --format=%cI origin/feature-1 (creation date)
            "2025-08-21T11:00:00Z",                    // git log -1 --format=%cI origin/feature-2 (creation date)
            "Switched to a new branch 'feature-2'"    // git checkout -b feature-2 origin/feature-2
        ]
        
        let picker = MockPicker(selectionResponses: [
            "Select a remote branch to checkout": 0 // Select feature-2
        ])
        
        let shell = MockShell(results: shellResults)
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)
        let output = try Nngit.testRun(context: context, args: ["checkout-remote"])

        #expect(shell.executedCommands.contains(localGitCheck) == true)
        #expect(shell.executedCommands.contains("git checkout -b feature-2 origin/feature-2") == true)
        #expect(output.contains("✅ Created and switched to local branch 'feature-2' tracking 'origin/feature-2'"))
    }
    
    @Test("handles case where no remote branches are found")
    func handlesNoRemoteBranches() throws {
        let config = GitConfig.defaultConfig
        let branchLoader = StubBranchLoader(remoteBranches: [], localBranches: [])
        let shellResults = [
            "true",
            "Test User",
            "test@example.com"
        ]
        
        let picker = MockPicker()
        let shell = MockShell(results: shellResults)
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["checkout-remote", "--no-filter"])

        #expect(output.contains("No remote branches found that you authored."))
        #expect(configLoader.savedConfig == nil) // Should not save config if no action taken
    }
    
    @Test("handles case where all remote branches exist locally")
    func handlesAllBranchesExistLocally() throws {
        let config = GitConfig.defaultConfig
        let remoteBranch1 = "origin/feature-1"
        let remoteBranch2 = "origin/main"
        let localBranch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let localBranch2 = GitBranch(name: "feature-1", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(
            remoteBranches: [remoteBranch1, remoteBranch2], 
            localBranches: [localBranch1, localBranch2]
        )
        
        let shellResults = [
            "true",
            "Test User",
            "test@example.com",
            "Test User,test@example.com",
            "Test User,test@example.com"
        ]
        
        let picker = MockPicker()
        let shell = MockShell(results: shellResults)
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)
        let output = try Nngit.testRun(context: context, args: ["checkout-remote"])

        #expect(output.contains("All your remote branches already exist locally."))
        #expect(output.contains("Use 'nngit switch-branch --branch-location remote' to switch to existing remote branches."))
        #expect(configLoader.savedConfig == nil) // Should not save config if no action taken
    }
    
    @Test("includes additional authors when specified")
    func includesAdditionalAuthors() throws {
        let config = GitConfig.defaultConfig
        let remoteBranch1 = "origin/feature-1" 
        let remoteBranch2 = "origin/feature-2"
        let branchLoader = StubBranchLoader(remoteBranches: [remoteBranch1, remoteBranch2], localBranches: [])
        let shellResults = [
            "true",
            "Test User",
            "test@example.com",
            "Other Author,other@example.com",
            "Test User,test@example.com",
            "Switched to a new branch 'feature-1'"
        ]
        
        let picker = MockPicker(selectionResponses: [
            "Select a remote branch to checkout": 0 // Select feature-1
        ])
        
        let shell = MockShell(results: shellResults)
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["checkout-remote", "--include-author", "Other Author"])

        #expect(shell.executedCommands.contains("git checkout -b feature-1 origin/feature-1") == true)
        #expect(output.contains("✅ Created and switched to local branch 'feature-1' tracking 'origin/feature-1'"))
    }
    
    @Test("handles different remote prefixes")
    func handlesDifferentRemotePrefixes() throws {
        let config = GitConfig.defaultConfig
        let remoteBranch1 = "upstream/feature-1"
        let remoteBranch2 = "origin/feature-2"
        let branchLoader = StubBranchLoader(remoteBranches: [remoteBranch1, remoteBranch2], localBranches: [])
        let shellResults = [
            "true",
            "Test User", 
            "test@example.com",
            "Test User,test@example.com",
            "Test User,test@example.com",
            "Switched to a new branch 'feature-1'"
        ]
        
        let picker = MockPicker(selectionResponses: [
            "Select a remote branch to checkout": 0 // Select feature-1
        ])
        
        let shell = MockShell(results: shellResults)
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["checkout-remote"])

        // Should present clean branch names without prefixes
        #expect(shell.executedCommands.contains("git checkout -b feature-1 origin/feature-1") == true)
        #expect(output.contains("✅ Created and switched to local branch 'feature-1' tracking 'origin/feature-1'"))
    }
    
    @Test("filters out branches from other authors")
    func filtersOtherAuthors() throws {
        let config = GitConfig.defaultConfig
        let remoteBranch1 = "origin/feature-1"
        let remoteBranch2 = "origin/feature-2"
        let branchLoader = StubBranchLoader(remoteBranches: [remoteBranch1, remoteBranch2], localBranches: [])
        let shellResults = [
            "true",
            "Test User",
            "test@example.com", 
            "Other User,other@example.com",
            "Test User,test@example.com",
            "Switched to a new branch 'feature-2'"
        ]
        
        let picker = MockPicker(selectionResponses: [
            "Select a remote branch to checkout": 0 // Only feature-2 should be available
        ])
        
        let shell = MockShell(results: shellResults)
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["checkout-remote"])

        #expect(shell.executedCommands.contains("git checkout -b feature-2 origin/feature-2") == true)
        #expect(output.contains("✅ Created and switched to local branch 'feature-2' tracking 'origin/feature-2'"))
    }
}
