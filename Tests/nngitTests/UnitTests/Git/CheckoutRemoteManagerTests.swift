//
//  CheckoutRemoteManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import NnShellKit
import SwiftPicker
import GitShellKit
@testable import nngit

struct CheckoutRemoteManagerTests {
    @Test("Loads remote branch names successfully")
    func loadRemoteBranchNamesSuccess() throws {
        let remoteBranches = ["origin/feature-1", "origin/feature-2", "origin/main"]
        let branchLoader = StubBranchLoader(remoteBranches: remoteBranches)
        let manager = makeSUT(branchLoader: branchLoader)
        let result = try manager.loadRemoteBranchNames()
        
        #expect(result.count == 3)
        #expect(result.contains("origin/feature-1"))
        #expect(result.contains("origin/feature-2"))
        #expect(result.contains("origin/main"))
    }
    
    @Test("Returns empty array when no remote branches")
    func loadRemoteBranchNamesEmpty() throws {
        let branchLoader = StubBranchLoader(remoteBranches: [])
        let manager = makeSUT(branchLoader: branchLoader)
        let result = try manager.loadRemoteBranchNames()
        
        #expect(result.isEmpty)
    }
    
    @Test("Filters out branches that exist locally")
    func filterNonExistingLocalBranchesSuccess() throws {
        let remoteBranches = ["origin/feature-1", "origin/feature-2", "origin/main"]
        let localBranch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let localBranch2 = GitBranch(name: "feature-1", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(remoteBranches: remoteBranches, localBranches: [localBranch1, localBranch2])
        let manager = makeSUT(branchLoader: branchLoader)
        let result = try manager.filterNonExistingLocalBranches(remoteBranches: remoteBranches)
        
        #expect(result.count == 1)
        #expect(result.contains("feature-2"))
        #expect(!result.contains("main"))
        #expect(!result.contains("feature-1"))
    }
    
    @Test("Returns all remote branches when no local branches exist")
    func filterNonExistingLocalBranchesNoLocal() throws {
        let remoteBranches = ["origin/feature-1", "origin/feature-2"]
        let branchLoader = StubBranchLoader(remoteBranches: remoteBranches, localBranches: [])
        let manager = makeSUT(branchLoader: branchLoader)
        let result = try manager.filterNonExistingLocalBranches(remoteBranches: remoteBranches)
        
        #expect(result.count == 2)
        #expect(result.contains("feature-1"))
        #expect(result.contains("feature-2"))
    }
    
    @Test("Returns empty array when all remote branches exist locally")
    func filterNonExistingLocalBranchesAllExist() throws {
        let remoteBranches = ["origin/feature-1", "origin/main"]
        let localBranch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let localBranch2 = GitBranch(name: "feature-1", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(remoteBranches: remoteBranches, localBranches: [localBranch1, localBranch2])
        let manager = makeSUT(branchLoader: branchLoader)
        let result = try manager.filterNonExistingLocalBranches(remoteBranches: remoteBranches)
        
        #expect(result.isEmpty)
    }
    
    @Test("Cleans remote branch name with origin prefix")
    func cleanRemoteBranchNameOrigin() {
        let manager = makeSUT()
        let result = manager.cleanRemoteBranchName("origin/feature-branch")
        
        #expect(result == "feature-branch")
    }
    
    @Test("Cleans remote branch name with upstream prefix")
    func cleanRemoteBranchNameUpstream() {
        let manager = makeSUT()
        let result = manager.cleanRemoteBranchName("upstream/feature-branch")
        
        #expect(result == "feature-branch")
    }
    
    @Test("Returns original name when no prefix")
    func cleanRemoteBranchNameNoPrefix() {
        let manager = makeSUT()
        let result = manager.cleanRemoteBranchName("feature-branch")
        
        #expect(result == "feature-branch")
    }
    
    @Test("Handles branch name with whitespace")
    func cleanRemoteBranchNameWithWhitespace() {
        let manager = makeSUT()
        let result = manager.cleanRemoteBranchName("  origin/feature-branch  ")
        
        #expect(result == "feature-branch")
    }
    
    @Test("Selects remote branch successfully")
    func selectRemoteBranchSuccess() throws {
        let picker = MockPicker(selectionResponses: ["Select a remote branch to checkout": 0])
        let manager = makeSUT(picker: picker)
        let availableBranches = ["feature-1", "feature-2"]
        let result = try manager.selectRemoteBranch(availableBranches: availableBranches)
        
        #expect(result == "feature-1")
    }
    
    @Test("Selects correct branch by index")
    func selectRemoteBranchByIndex() throws {
        let picker = MockPicker(selectionResponses: ["Select a remote branch to checkout": 1])
        let manager = makeSUT(picker: picker)
        let availableBranches = ["feature-1", "feature-2", "feature-3"]
        let result = try manager.selectRemoteBranch(availableBranches: availableBranches)
        
        #expect(result == "feature-2")
    }
    
    @Test("Checks out remote branch successfully")
    func checkoutRemoteBranchSuccess() throws {
        let shell = MockShell()
        let manager = makeSUT(shell: shell)
        try manager.checkoutRemoteBranch(branchName: "feature-branch")
        
        #expect(shell.executedCommands.contains("git checkout -b feature-branch origin/feature-branch"))
    }
    
    @Test("Executes complete checkout workflow successfully")
    func executeCheckoutWorkflowSuccess() throws {
        let shell = MockShell()
        let picker = MockPicker(selectionResponses: ["Select a remote branch to checkout": 0])
        let remoteBranches = ["origin/feature-1", "origin/main"]
        let localBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(remoteBranches: remoteBranches, localBranches: [localBranch])
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeCheckoutWorkflow()
        
        #expect(shell.executedCommands.contains("git checkout -b feature-1 origin/feature-1"))
    }
    
    @Test("Executes workflow with no remote branches")
    func executeCheckoutWorkflowNoRemoteBranches() throws {
        let shell = MockShell()
        let picker = MockPicker()
        let branchLoader = StubBranchLoader(remoteBranches: [], localBranches: [])
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeCheckoutWorkflow()
        
        #expect(!shell.executedCommands.contains { $0.contains("git checkout") })
    }
    
    @Test("Executes workflow with all branches existing locally")
    func executeCheckoutWorkflowAllExistLocally() throws {
        let shell = MockShell()
        let picker = MockPicker()
        let remoteBranches = ["origin/feature-1", "origin/main"]
        let localBranch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let localBranch2 = GitBranch(name: "feature-1", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(remoteBranches: remoteBranches, localBranches: [localBranch1, localBranch2])
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeCheckoutWorkflow()
        
        #expect(!shell.executedCommands.contains { $0.contains("git checkout") })
    }
    
    @Test("Executes workflow with mixed remote prefixes")
    func executeCheckoutWorkflowMixedPrefixes() throws {
        let shell = MockShell()
        let picker = MockPicker(selectionResponses: ["Select a remote branch to checkout": 0])
        let remoteBranches = ["upstream/feature-1", "origin/feature-2"]
        let branchLoader = StubBranchLoader(remoteBranches: remoteBranches, localBranches: [])
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeCheckoutWorkflow()
        
        #expect(shell.executedCommands.contains("git checkout -b feature-1 origin/feature-1"))
    }
    
    @Test("Sorts available branches alphabetically")
    func filterNonExistingLocalBranchesSorted() throws {
        let remoteBranches = ["origin/zebra", "origin/alpha", "origin/beta"]
        let branchLoader = StubBranchLoader(remoteBranches: remoteBranches, localBranches: [])
        let manager = makeSUT(branchLoader: branchLoader)
        let result = try manager.filterNonExistingLocalBranches(remoteBranches: remoteBranches)
        
        #expect(result == ["alpha", "beta", "zebra"])
    }
}


// MARK: - SUT
private extension CheckoutRemoteManagerTests {
    func makeSUT(shell: MockShell = MockShell(), picker: MockPicker = MockPicker(), branchLoader: StubBranchLoader = StubBranchLoader()) -> CheckoutRemoteManager {
        
        return .init(shell: shell, picker: picker, branchLoader: branchLoader)
    }
}