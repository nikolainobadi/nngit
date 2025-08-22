//
//  NewBranchManagerTests.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import GitShellKit
import NnShellKit
@testable import nngit

@Suite
struct NewBranchManagerTests {
    
    @Test("getCurrentBranch returns current branch name")
    func getCurrentBranch() throws {
        let branchNames = ["  develop", "* main", "  feature"]
        let branchLoader = StubBranchLoader(branchNames: branchNames)
        let shell = MockShell(results: [])
        let config = GitConfig(defaultBranch: "main")
        let manager = NewBranchManager(shell: shell, branchLoader: branchLoader, config: config)
        
        let currentBranch = try manager.getCurrentBranch()
        
        #expect(currentBranch == "main")
    }
    
    @Test("getCurrentBranch returns nil when no current branch found")
    func getCurrentBranchReturnsNil() throws {
        let branchNames = ["  develop", "  main", "  feature"]
        let branchLoader = StubBranchLoader(branchNames: branchNames)
        let shell = MockShell(results: [])
        let config = GitConfig(defaultBranch: "main")
        let manager = NewBranchManager(shell: shell, branchLoader: branchLoader, config: config)
        
        let currentBranch = try manager.getCurrentBranch()
        
        #expect(currentBranch == nil)
    }
    
    @Test("isCurrentBranchDefault returns true when on default branch")
    func isCurrentBranchDefaultTrue() throws {
        let branchNames = ["  develop", "* main", "  feature"]
        let branchLoader = StubBranchLoader(branchNames: branchNames)
        let shell = MockShell(results: [])
        let config = GitConfig(defaultBranch: "main")
        let manager = NewBranchManager(shell: shell, branchLoader: branchLoader, config: config)
        
        let isDefault = try manager.isCurrentBranchDefault()
        
        #expect(isDefault == true)
    }
    
    @Test("isCurrentBranchDefault returns false when not on default branch")
    func isCurrentBranchDefaultFalse() throws {
        let branchNames = ["* develop", "  main", "  feature"]
        let branchLoader = StubBranchLoader(branchNames: branchNames)
        let shell = MockShell(results: [])
        let config = GitConfig(defaultBranch: "main")
        let manager = NewBranchManager(shell: shell, branchLoader: branchLoader, config: config)
        
        let isDefault = try manager.isCurrentBranchDefault()
        
        #expect(isDefault == false)
    }
    
    @Test("isCurrentBranchDefault returns false when no current branch")
    func isCurrentBranchDefaultNoCurrentBranch() throws {
        let branchNames = ["  develop", "  main", "  feature"]
        let branchLoader = StubBranchLoader(branchNames: branchNames)
        let shell = MockShell(results: [])
        let config = GitConfig(defaultBranch: "main")
        let manager = NewBranchManager(shell: shell, branchLoader: branchLoader, config: config)
        
        let isDefault = try manager.isCurrentBranchDefault()
        
        #expect(isDefault == false)
    }
    
    @Test("getCurrentBranchSyncStatus returns sync status when on default branch with remote")
    func getCurrentBranchSyncStatusWithRemote() throws {
        let branch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .ahead)
        let branchNames = ["* main", "  develop"]
        let branchLoader = StubBranchLoader(localBranches: [branch], branchNames: branchNames)
        let shell = MockShell(results: ["origin"]) // remoteExists returns "origin"
        let config = GitConfig(defaultBranch: "main")
        let manager = NewBranchManager(shell: shell, branchLoader: branchLoader, config: config)
        
        let syncStatus = try manager.getCurrentBranchSyncStatus()
        
        #expect(syncStatus == .ahead)
    }
    
    @Test("getCurrentBranchSyncStatus returns nil when not on default branch")
    func getCurrentBranchSyncStatusNotDefault() throws {
        let branch = GitBranch(name: "develop", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .ahead)
        let branchNames = ["* develop", "  main"]
        let branchLoader = StubBranchLoader(localBranches: [branch], branchNames: branchNames)
        let shell = MockShell(results: ["origin"]) // remoteExists returns "origin"
        let config = GitConfig(defaultBranch: "main")
        let manager = NewBranchManager(shell: shell, branchLoader: branchLoader, config: config)
        
        let syncStatus = try manager.getCurrentBranchSyncStatus()
        
        #expect(syncStatus == nil)
    }
    
    @Test("getCurrentBranchSyncStatus returns nil when no remote exists")
    func getCurrentBranchSyncStatusNoRemote() throws {
        let branch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .ahead)
        let branchNames = ["* main", "  develop"]
        let branchLoader = StubBranchLoader(localBranches: [branch], branchNames: branchNames)
        let shell = MockShell(results: []) // remoteExists fails (no results)
        let config = GitConfig(defaultBranch: "main")
        let manager = NewBranchManager(shell: shell, branchLoader: branchLoader, config: config)
        
        let syncStatus = try manager.getCurrentBranchSyncStatus()
        
        #expect(syncStatus == nil)
    }
    
    @Test("getCurrentBranchSyncStatus returns nil when no current branch")
    func getCurrentBranchSyncStatusNoCurrent() throws {
        let branchNames = ["  main", "  develop"]
        let branchLoader = StubBranchLoader(branchNames: branchNames)
        let shell = MockShell(results: ["origin"])
        let config = GitConfig(defaultBranch: "main")
        let manager = NewBranchManager(shell: shell, branchLoader: branchLoader, config: config)
        
        let syncStatus = try manager.getCurrentBranchSyncStatus()
        
        #expect(syncStatus == nil)
    }
    
    @Test("handleRemoteRepository prints sync status when on default branch")
    func handleRemoteRepositoryOnDefault() throws {
        let branch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .ahead)
        let branchNames = ["* main", "  develop"]
        let branchLoader = StubBranchLoader(localBranches: [branch], branchNames: branchNames)
        let shell = MockShell(results: ["origin"])
        let config = GitConfig(defaultBranch: "main")
        let manager = NewBranchManager(shell: shell, branchLoader: branchLoader, config: config)
        
        // This test verifies the method runs without throwing - the print output would be tested in integration tests
        #expect(throws: Never.self) {
            try manager.handleRemoteRepository()
        }
    }
    
    @Test("handleRemoteRepository does nothing when not on default branch")
    func handleRemoteRepositoryNotOnDefault() throws {
        let branch = GitBranch(name: "develop", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .ahead)
        let branchNames = ["* develop", "  main"]
        let branchLoader = StubBranchLoader(localBranches: [branch], branchNames: branchNames)
        let shell = MockShell(results: ["origin"])
        let config = GitConfig(defaultBranch: "main")
        let manager = NewBranchManager(shell: shell, branchLoader: branchLoader, config: config)
        
        // This test verifies the method runs without throwing when not on default branch
        #expect(throws: Never.self) {
            try manager.handleRemoteRepository()
        }
    }
}