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
    @Test("Successfully checks out available remote branch")
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
    
    @Test("Handles no remote branches available")
    func executeCheckoutWorkflowNoRemoteBranches() throws {
        let shell = MockShell()
        let picker = MockPicker()
        let branchLoader = StubBranchLoader(remoteBranches: [], localBranches: [])
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeCheckoutWorkflow()
        
        #expect(!shell.executedCommands.contains { $0.contains("git checkout") })
    }
    
    @Test("Handles all remote branches already exist locally")
    func executeCheckoutWorkflowAllBranchesExistLocally() throws {
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
    
    @Test("Correctly filters and checks out non-existing local branches")
    func executeCheckoutWorkflowFiltersExistingBranches() throws {
        let shell = MockShell()
        let picker = MockPicker(selectionResponses: ["Select a remote branch to checkout": 0])
        let remoteBranches = ["origin/feature-1", "origin/feature-2", "origin/main"]
        let localBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(remoteBranches: remoteBranches, localBranches: [localBranch])
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeCheckoutWorkflow()
        
        // Should checkout feature-1 (first available branch after filtering out 'main')
        #expect(shell.executedCommands.contains("git checkout -b feature-1 origin/feature-1"))
    }
    
    @Test("Handles different user selections correctly")
    func executeCheckoutWorkflowDifferentSelections() throws {
        let shell = MockShell()
        let picker = MockPicker(selectionResponses: ["Select a remote branch to checkout": 1]) // Select second option
        let remoteBranches = ["origin/feature-1", "origin/feature-2", "origin/main"]
        let branchLoader = StubBranchLoader(remoteBranches: remoteBranches, localBranches: [])
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeCheckoutWorkflow()
        
        // Should checkout feature-2 (second branch in alphabetical order)
        #expect(shell.executedCommands.contains("git checkout -b feature-2 origin/feature-2"))
    }
    
    @Test("Handles remote branches with different prefixes")
    func executeCheckoutWorkflowMixedRemotePrefixes() throws {
        let shell = MockShell()
        let picker = MockPicker(selectionResponses: ["Select a remote branch to checkout": 0])
        let remoteBranches = ["upstream/feature-1", "origin/feature-2"]
        let branchLoader = StubBranchLoader(remoteBranches: remoteBranches, localBranches: [])
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeCheckoutWorkflow()
        
        // Should always use origin/ prefix in git command regardless of remote prefix
        #expect(shell.executedCommands.contains("git checkout -b feature-1 origin/feature-1"))
    }
    
    @Test("Sorts available branches alphabetically for selection")
    func executeCheckoutWorkflowSortsBranches() throws {
        let shell = MockShell()
        let picker = MockPicker(selectionResponses: ["Select a remote branch to checkout": 0]) // Select first after sorting
        let remoteBranches = ["origin/zebra", "origin/alpha", "origin/beta"]
        let branchLoader = StubBranchLoader(remoteBranches: remoteBranches, localBranches: [])
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeCheckoutWorkflow()
        
        // Should checkout 'alpha' as it's first alphabetically
        #expect(shell.executedCommands.contains("git checkout -b alpha origin/alpha"))
    }
    
    @Test("Handles branches with whitespace in names")
    func executeCheckoutWorkflowWithWhitespace() throws {
        let shell = MockShell()
        let picker = MockPicker(selectionResponses: ["Select a remote branch to checkout": 0])
        let remoteBranches = ["  origin/feature-branch  "] // Extra whitespace
        let branchLoader = StubBranchLoader(remoteBranches: remoteBranches, localBranches: [])
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeCheckoutWorkflow()
        
        #expect(shell.executedCommands.contains("git checkout -b feature-branch origin/feature-branch"))
    }
    
    @Test("Handles branch names without remote prefix")
    func executeCheckoutWorkflowNoPrefixBranches() throws {
        let shell = MockShell()
        let picker = MockPicker(selectionResponses: ["Select a remote branch to checkout": 0])
        let remoteBranches = ["feature-branch"] // No prefix
        let branchLoader = StubBranchLoader(remoteBranches: remoteBranches, localBranches: [])
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeCheckoutWorkflow()
        
        #expect(shell.executedCommands.contains("git checkout -b feature-branch origin/feature-branch"))
    }
}


// MARK: - SUT
private extension CheckoutRemoteManagerTests {
    func makeSUT(shell: MockShell = MockShell(), picker: MockPicker = MockPicker(), branchLoader: StubBranchLoader = StubBranchLoader()) -> CheckoutRemoteManager {
        
        return .init(shell: shell, picker: picker, branchLoader: branchLoader)
    }
}