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
    @Test("Loads eligible branch names excluding default branch")
    func loadEligibleBranchNamesSuccess() throws {
        let branchNames = ["* main", "feature", "develop"]
        let branchLoader = StubBranchLoader(branchNames: branchNames)
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(branchLoader: branchLoader, config: config)
        let result = try manager.loadEligibleBranchNames()
        
        #expect(result.count == 2)
        #expect(result.contains("feature"))
        #expect(result.contains("develop"))
        #expect(!result.contains("* main"))
        #expect(!result.contains("main"))
    }
    
    @Test("Returns original branch names when no search provided")
    func handleSearchAndFilteringNoSearch() throws {
        let manager = makeSUT()
        let branchNames = ["feature", "develop"]
        let result = try manager.handleSearchAndFiltering(branchNames: branchNames, search: nil)
        
        #expect(result == branchNames)
    }
    
    @Test("Returns original branch names when search is empty")
    func handleSearchAndFilteringEmptySearch() throws {
        let manager = makeSUT()
        let branchNames = ["feature", "develop"]
        let result = try manager.handleSearchAndFiltering(branchNames: branchNames, search: "   ")
        
        #expect(result == branchNames)
    }
    
    @Test("Filters branches by search term")
    func handleSearchAndFilteringWithSearch() throws {
        let branchLoader = StubBranchLoader(filteredResults: ["feature"])
        let manager = makeSUT(branchLoader: branchLoader)
        let branchNames = ["feature", "develop"]
        let result = try manager.handleSearchAndFiltering(branchNames: branchNames, search: "feat")
        
        #expect(result == ["feature"])
    }
    
    @Test("Returns nil when no branches match search")
    func handleSearchAndFilteringNoMatches() throws {
        let branchLoader = StubBranchLoader(filteredResults: [])
        let manager = makeSUT(branchLoader: branchLoader)
        let branchNames = ["feature", "develop"]
        let result = try manager.handleSearchAndFiltering(branchNames: branchNames, search: "nonexistent")
        
        #expect(result == nil)
    }
    
    @Test("Loads branch data with correct parameters")
    func loadBranchDataSuccess() throws {
        let branches = makeBranches()
        let branchLoader = StubBranchLoader(localBranches: branches)
        let config = GitConfig.defaultConfig
        let manager = makeSUT(branchLoader: branchLoader, config: config)
        let branchNames = ["main", "feature", "develop"]
        let result = try manager.loadBranchData(branchNames: branchNames)
        
        #expect(result.count == 3)
        #expect(result[0].name == "main")
        #expect(result[0].isCurrentBranch == true)
    }
    
    @Test("Selects all merged branches when allMerged flag is true")
    func selectBranchesToDeleteAllMerged() {
        let manager = makeSUT()
        let branches = makeBranches()
        let result = manager.selectBranchesToDelete(eligibleBranches: branches, allMerged: true)
        
        #expect(result?.count == 1)
        #expect(result?[0].name == "develop")
        #expect(result?[0].isMerged == true)
    }
    
    @Test("Returns nil when no merged branches found")
    func selectBranchesToDeleteNoMerged() {
        let manager = makeSUT()
        let branches = [
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        let result = manager.selectBranchesToDelete(eligibleBranches: branches, allMerged: true)
        
        #expect(result == nil)
    }
    
    @Test("Uses picker for multi-selection when allMerged is false")
    func selectBranchesToDeleteWithPicker() {
        let picker = MockPicker(selectionResponses: ["Select which branches to delete": 0])
        let manager = makeSUT(picker: picker)
        let branches = makeBranches()
        let result = manager.selectBranchesToDelete(eligibleBranches: branches, allMerged: false)
        
        #expect(result?.count == 1)
        #expect(result?[0].name == "main")
    }
    
    @Test("Deletes merged branch without forced flag")
    func deleteBranchMerged() throws {
        let shell = MockShell()
        let manager = makeSUT(shell: shell)
        let branch = GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        try manager.deleteBranch(branch)
        
        #expect(shell.executedCommands.contains("git branch -d feature"))
    }
    
    @Test("Deletes unmerged branch with forced flag")
    func deleteBranchUnmerged() throws {
        let shell = MockShell()
        let manager = makeSUT(shell: shell)
        let branch = GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        try manager.deleteBranch(branch, forced: true)
        
        #expect(shell.executedCommands.contains("git branch -D feature"))
    }
    
    @Test("Deletes multiple branches with mixed merge status")
    func deleteBranchesSuccess() throws {
        let shell = MockShell()
        let picker = MockPicker(permissionResponses: ["This branch has NOT been merged into main. Are you sure you want to delete it?": true])
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, picker: picker, config: config)
        let mergedBranch = GitBranch(name: "merged", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let unmergedBranch = GitBranch(name: "unmerged", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branches = [mergedBranch, unmergedBranch]
        let result = try manager.deleteBranches(branches)
        
        #expect(result.count == 2)
        #expect(result.contains("merged"))
        #expect(result.contains("unmerged"))
        #expect(shell.executedCommands.contains("git branch -d merged"))
        #expect(shell.executedCommands.contains("git branch -D unmerged"))
    }
    
    @Test("Prunes origin when remote exists")
    func pruneOriginIfExistsSuccess() throws {
        let shell = MockShell(results: ["origin"])
        let manager = makeSUT(shell: shell)
        try manager.pruneOriginIfExists()
        
        #expect(shell.executedCommands.contains("git remote prune origin"))
    }
    
    @Test("Does not prune when no remote exists")
    func pruneOriginIfExistsNoRemote() throws {
        let shell = MockShell()
        let manager = makeSUT(shell: shell)
        try manager.pruneOriginIfExists()
        
        #expect(!shell.executedCommands.contains("git remote prune origin"))
    }
    
    @Test("Executes complete delete workflow successfully")
    func executeDeleteWorkflowSuccess() throws {
        let shell = MockShell(results: ["", "origin", ""])
        let picker = MockPicker(selectionResponses: ["Select which branches to delete": 0])
        let mergedBranch = GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branches = [mergedBranch]
        let branchLoader = StubBranchLoader(
            localBranches: branches,
            branchNames: ["main", "feature"],
            filteredResults: ["main", "feature"]
        )
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeDeleteWorkflow(search: nil, allMerged: false)
        
        #expect(shell.executedCommands.contains("git branch -d feature"))
        #expect(shell.executedCommands.contains("git remote prune origin"))
    }
    
    @Test("Executes workflow with search term")
    func executeDeleteWorkflowWithSearch() throws {
        let shell = MockShell(results: ["", "origin", ""])
        let picker = MockPicker(selectionResponses: ["Select which branches to delete": 0])
        let mergedBranch = GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branches = [mergedBranch]
        let branchLoader = StubBranchLoader(
            localBranches: branches,
            branchNames: ["main", "feature"],
            filteredResults: ["feature"]
        )
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeDeleteWorkflow(search: "feat", allMerged: false)
        
        #expect(shell.executedCommands.contains("git branch -d feature"))
        #expect(shell.executedCommands.contains("git remote prune origin"))
    }
    
    @Test("Executes workflow with allMerged flag")
    func executeDeleteWorkflowAllMerged() throws {
        let shell = MockShell(results: ["", "origin", ""])
        let picker = MockPicker()
        let branches = makeBranches()
        let branchLoader = StubBranchLoader(
            localBranches: branches,
            branchNames: ["main", "feature", "develop"],
            filteredResults: ["main", "feature", "develop"]
        )
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeDeleteWorkflow(search: nil, allMerged: true)
        
        #expect(shell.executedCommands.contains("git branch -d develop"))
        #expect(!shell.executedCommands.contains("git branch -d feature"))
        #expect(shell.executedCommands.contains("git remote prune origin"))
    }
    
    @Test("Executes workflow with no matches")
    func executeDeleteWorkflowNoMatches() throws {
        let shell = MockShell()
        let picker = MockPicker()
        let branchLoader = StubBranchLoader(
            branchNames: ["main", "feature"],
            filteredResults: []
        )
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeDeleteWorkflow(search: "nonexistent", allMerged: false)
        
        #expect(!shell.executedCommands.contains { $0.contains("git branch -d") })
        #expect(!shell.executedCommands.contains("git remote prune origin"))
    }
}


// MARK: - SUT
private extension DeleteBranchManagerTests {
    func makeSUT(shell: MockShell = MockShell(), picker: MockPicker = MockPicker(), branchLoader: StubBranchLoader = StubBranchLoader(), config: GitConfig = .defaultConfig) -> DeleteBranchManager {
        
        return .init(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
    }
    
    func makeConfig(defaultBranch: String) -> GitConfig {
        var config = GitConfig.defaultConfig
        config.branches.defaultBranch = defaultBranch
        return config
    }
}


// MARK: - Private Methods
private extension DeleteBranchManagerTests {
    func makeBranches() -> [GitBranch] {
        return [
            GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "develop", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
    }
}
