import Testing
import SwiftPicker
import GitShellKit
import NnShellKit
@testable import nngit

@MainActor
@Suite(.disabled())
struct CheckoutRemoteTests {
    @Test("Checks out remote branch successfully")
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
    
    @Test("Handles case where no remote branches are found")
    func handlesNoRemoteBranches() throws {
        let config = GitConfig.defaultConfig
        let branchLoader = StubBranchLoader(remoteBranches: [], localBranches: [])
        let shellResults = [
            "true"
        ]
        
        let picker = MockPicker()
        let shell = MockShell(results: shellResults)
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)

        let output = try Nngit.testRun(context: context, args: ["checkout-remote"])

        #expect(output.contains("No remote branches found."))
    }
    
    @Test("Handles case where all remote branches exist locally")
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
            "true"
        ]
        
        let picker = MockPicker()
        let shell = MockShell(results: shellResults)
        let configLoader = StubConfigLoader(initialConfig: config)
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, branchLoader: branchLoader)
        let output = try Nngit.testRun(context: context, args: ["checkout-remote"])

        #expect(output.contains("All remote branches already exist locally."))
        #expect(output.contains("Use 'nngit switch-branch --branch-location remote' to switch to existing remote branches."))
    }
    
    
    @Test("Handles different remote prefixes")
    func handlesDifferentRemotePrefixes() throws {
        let config = GitConfig.defaultConfig
        let remoteBranch1 = "upstream/feature-1"
        let remoteBranch2 = "origin/feature-2"
        let branchLoader = StubBranchLoader(remoteBranches: [remoteBranch1, remoteBranch2], localBranches: [])
        let shellResults = [
            "true",
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
}
