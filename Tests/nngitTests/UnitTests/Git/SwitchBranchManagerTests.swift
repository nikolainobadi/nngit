//
//  SwitchBranchManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import NnShellKit
import SwiftPicker
import GitShellKit
@testable import nngit

struct SwitchBranchManagerTests {
    @Test("Returns original branches when no search term provided")
    func handleSearchAndFilteringNoSearch() throws {
        let manager = makeSUT()
        let branchNames = ["main", "feature", "develop"]
        let result = try manager.handleSearchAndFiltering(branchNames: branchNames, search: nil)
        
        #expect(result == branchNames)
    }
    
    @Test("Returns original branches when search term is empty")
    func handleSearchAndFilteringEmptySearch() throws {
        let manager = makeSUT()
        let branchNames = ["main", "feature", "develop"]
        let result = try manager.handleSearchAndFiltering(branchNames: branchNames, search: "   ")
        
        #expect(result == branchNames)
    }
    
    @Test("Filters branches by search term")
    func handleSearchAndFilteringWithSearch() throws {
        let branchLoader = StubBranchLoader(filteredResults: ["feature"])
        let manager = makeSUT(branchLoader: branchLoader)
        let branchNames = ["main", "feature", "develop"]
        let result = try manager.handleSearchAndFiltering(branchNames: branchNames, search: "feat")
        
        #expect(result == ["feature"])
    }
    
    @Test("Returns nil when no branches match search")
    func handleSearchAndFilteringNoMatches() throws {
        let branchLoader = StubBranchLoader(filteredResults: [])
        let manager = makeSUT(branchLoader: branchLoader)
        let branchNames = ["main", "feature", "develop"]
        let result = try manager.handleSearchAndFiltering(branchNames: branchNames, search: "nonexistent")
        
        #expect(result == nil)
    }
    
    @Test("Switches to exact match and returns nil")
    func handleSearchAndFilteringExactMatch() throws {
        let shell = MockShell()
        let branchLoader = StubBranchLoader(filteredResults: ["feature", "feature-branch"])
        let manager = makeSUT(shell: shell, branchLoader: branchLoader)
        let branchNames = ["main", "feature", "feature-branch"]
        let result = try manager.handleSearchAndFiltering(branchNames: branchNames, search: "feature")
        
        #expect(result == nil)
        #expect(shell.executedCommands.contains("git checkout feature"))
    }
    
    @Test("Switches to exact match with asterisk prefix")
    func handleSearchAndFilteringExactMatchWithAsterisk() throws {
        let shell = MockShell()
        let branchLoader = StubBranchLoader(filteredResults: ["* feature", "feature-branch"])
        let manager = makeSUT(shell: shell, branchLoader: branchLoader)
        let branchNames = ["* feature", "feature-branch"]
        let result = try manager.handleSearchAndFiltering(branchNames: branchNames, search: "feature")
        
        #expect(result == nil)
        #expect(shell.executedCommands.contains("git checkout feature"))
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
    
    @Test("Separates current and available branches")
    func prepareBranchSelectionSeparatesBranches() {
        let manager = makeSUT()
        let branches = makeBranches()
        let (current, available) = manager.prepareBranchSelection(branches: branches)
        
        #expect(current?.name == "main")
        #expect(current?.isCurrentBranch == true)
        #expect(available.count == 2)
        #expect(available.map(\.name).contains("feature"))
        #expect(available.map(\.name).contains("develop"))
        #expect(!available.contains { $0.isCurrentBranch })
    }
    
    @Test("Handles no current branch")
    func prepareBranchSelectionNoCurrent() {
        let manager = makeSUT()
        let branches = [
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "develop", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        let (current, available) = manager.prepareBranchSelection(branches: branches)
        
        #expect(current == nil)
        #expect(available.count == 2)
    }
    
    @Test("Selects and switches to branch with current branch details")
    func selectAndSwitchBranchWithCurrentBranch() throws {
        let shell = MockShell()
        let picker = MockPicker(selectionResponses: ["Select a branch (switching from main)": 0])
        let manager = makeSUT(shell: shell, picker: picker)
        let currentBranch = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let availableBranches = [
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        try manager.selectAndSwitchBranch(availableBranches: availableBranches, currentBranch: currentBranch)
        
        #expect(shell.executedCommands.contains("git checkout feature"))
    }
    
    @Test("Selects and switches to branch without current branch")
    func selectAndSwitchBranchWithoutCurrentBranch() throws {
        let shell = MockShell()
        let picker = MockPicker(selectionResponses: ["Select a branch ": 0])
        let manager = makeSUT(shell: shell, picker: picker)
        let availableBranches = [
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        try manager.selectAndSwitchBranch(availableBranches: availableBranches, currentBranch: nil)
        
        #expect(shell.executedCommands.contains("git checkout feature"))
    }
    
    @Test("Executes complete workflow successfully")
    func executeSwitchWorkflowSuccess() throws {
        let shell = MockShell()
        let picker = MockPicker(selectionResponses: ["Select a branch (switching from main)": 0])
        let branches = makeBranches()
        let branchLoader = StubBranchLoader(
            localBranches: branches,
            branchNames: ["main", "feature", "develop"],
            filteredResults: ["main", "feature", "develop"]
        )
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeSwitchWorkflow(search: nil)
        
        #expect(shell.executedCommands.contains("git checkout feature"))
    }
    
    @Test("Executes workflow with search term")
    func executeSwitchWorkflowWithSearch() throws {
        let shell = MockShell()
        let picker = MockPicker(selectionResponses: ["Select a branch (switching from main)": 0])
        let branches = [makeBranches()[1]] // Only feature branch
        let branchLoader = StubBranchLoader(
            localBranches: branches,
            branchNames: ["main", "feature", "develop"],
            filteredResults: ["feature"]
        )
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        try manager.executeSwitchWorkflow(search: "feat")
        
        #expect(shell.executedCommands.contains("git checkout feature"))
    }
    
    @Test("Executes workflow with exact match")
    func executeSwitchWorkflowExactMatch() throws {
        let shell = MockShell()
        let branchLoader = StubBranchLoader(
            branchNames: ["main", "feature", "develop"],
            filteredResults: ["feature"]
        )
        let manager = makeSUT(shell: shell, branchLoader: branchLoader)
        try manager.executeSwitchWorkflow(search: "feature")
        
        #expect(shell.executedCommands.contains("git checkout feature"))
    }
    
    @Test("Executes workflow with no matches")
    func executeSwitchWorkflowNoMatches() throws {
        let shell = MockShell()
        let branchLoader = StubBranchLoader(
            branchNames: ["main", "feature", "develop"],
            filteredResults: []
        )
        let manager = makeSUT(shell: shell, branchLoader: branchLoader)
        try manager.executeSwitchWorkflow(search: "nonexistent")
        
        #expect(!shell.executedCommands.contains { $0.contains("git checkout") })
    }
}


// MARK: - SUT
private extension SwitchBranchManagerTests {
    func makeSUT(branchLocation: BranchLocation = .local, shell: MockShell = MockShell(), picker: MockPicker = MockPicker(), branchLoader: StubBranchLoader = StubBranchLoader(), config: GitConfig = .defaultConfig) -> SwitchBranchManager {
        
        return .init(branchLocation: branchLocation, shell: shell, picker: picker, branchLoader: branchLoader, config: config)
    }
}


// MARK: - Private Methods
private extension SwitchBranchManagerTests {
    func makeBranches() -> [GitBranch] {
        return [
            GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "develop", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
    }
}
