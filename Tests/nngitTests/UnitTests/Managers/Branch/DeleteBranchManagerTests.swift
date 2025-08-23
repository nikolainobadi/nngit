//
//  DeleteBranchManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import NnShellKit
import SwiftPicker
import GitShellKit
@testable import nngit

struct DeleteBranchManagerTests {
    @Test("Successfully executes complete delete workflow")
    func deleteBranchesSuccess() throws {
        let branches = [
            GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "develop", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        let branchLoader = StubBranchLoader(localBranches: branches, branchNames: ["main", "feature", "develop"])
        let picker = MockPicker(selectionResponses: ["Select which branches to delete": 0])
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: nil as String?, allMerged: false)
        
        #expect(shell.executedCommands.contains("git branch -d feature"))
    }
    
    @Test("Executes workflow with search term")
    func deleteBranchesWithSearch() throws {
        let branches = [
            GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        let branchLoader = StubBranchLoader(localBranches: branches, branchNames: ["main", "feature"], filteredResults: ["feature"])
        let picker = MockPicker(selectionResponses: ["Select which branches to delete": 0])
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: "feat", allMerged: false)
        
        #expect(shell.executedCommands.contains("git branch -d feature"))
    }
    
    @Test("Executes workflow with allMerged flag")
    func deleteBranchesAllMerged() throws {
        let branches = [
            GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "develop", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "unmerged", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        let branchLoader = StubBranchLoader(localBranches: branches, branchNames: ["main", "feature", "develop", "unmerged"])
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: nil as String?, allMerged: true)
        
        #expect(shell.executedCommands.contains("git branch -d feature"))
        #expect(shell.executedCommands.contains("git branch -d develop"))
        #expect(!shell.executedCommands.contains { $0.contains("unmerged") })
    }
    
    @Test("Handles no eligible branches")
    func deleteBranchesNoEligible() throws {
        let branchLoader = StubBranchLoader(branchNames: ["main"])
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: nil as String?, allMerged: false)
        
        #expect(!shell.executedCommands.contains { $0.contains("git branch") })
    }
    
    @Test("Handles no matches for search term")
    func deleteBranchesNoMatches() throws {
        let branchLoader = StubBranchLoader(branchNames: ["main", "feature"], filteredResults: [])
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: "nonexistent", allMerged: false)
        
        #expect(!shell.executedCommands.contains { $0.contains("git branch") })
    }
    
    @Test("Deletes unmerged branch with forced flag")
    func deleteBranchesUnmergedWithForce() throws {
        let branches = [
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        let branchLoader = StubBranchLoader(localBranches: branches, branchNames: ["main", "feature"])
        let picker = MockPicker(
            permissionResponses: ["This branch has NOT been merged into main. Are you sure you want to delete it?": true],
            selectionResponses: ["Select which branches to delete": 0]
        )
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: nil as String?, allMerged: false)
        
        #expect(shell.executedCommands.contains("git branch -D feature"))
    }
    
    @Test("Deletes merged branch without forced flag")
    func deleteBranchesMergedWithoutForce() throws {
        let branches = [
            GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        let branchLoader = StubBranchLoader(localBranches: branches, branchNames: ["main", "feature"])
        let picker = MockPicker(selectionResponses: ["Select which branches to delete": 0])
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: nil as String?, allMerged: false)
        
        #expect(shell.executedCommands.contains("git branch -d feature"))
    }
    
    @Test("Deletes selected branch from multiple available")
    func deleteBranchesFromMultiple() throws {
        let branches = [
            GitBranch(name: "merged", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "unmerged", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        let branchLoader = StubBranchLoader(localBranches: branches, branchNames: ["main", "merged", "unmerged"])
        let picker = MockPicker(selectionResponses: ["Select which branches to delete": 0]) // Selects first (merged)
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: nil as String?, allMerged: false)
        
        // Should delete the selected merged branch
        #expect(shell.executedCommands.contains("git branch -d merged"))
        #expect(!shell.executedCommands.contains { $0.contains("unmerged") })
    }
    
    @Test("Returns nil when no merged branches found")
    func deleteBranchesNoMerged() throws {
        let branches = [
            GitBranch(name: "unmerged", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        let branchLoader = StubBranchLoader(localBranches: branches, branchNames: ["main", "unmerged"])
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: nil as String?, allMerged: true)
        
        #expect(!shell.executedCommands.contains { $0.contains("git branch") })
    }
}


// MARK: - SUT
private extension DeleteBranchManagerTests {
    func makeSUT(
        shell: MockShell = MockShell(),
        picker: MockPicker = MockPicker(),
        branchLoader: StubBranchLoader = StubBranchLoader(),
        config: GitConfig = GitConfig.defaultConfig
    ) -> DeleteBranchManager {
        
        return .init(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
    }
    
    func makeConfig(defaultBranch: String) -> GitConfig {
        return GitConfig(defaultBranch: defaultBranch)
    }
}