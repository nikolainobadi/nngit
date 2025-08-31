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
    @Test("Successfully executes branch switching workflow")
    func switchBranchSuccess() throws {
        let branches = [
            GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        let branchLoader = StubBranchLoader(localBranches: branches)
        let picker = MockPicker(selectionResponses: ["Select a branch (switching from main)": 0])
        let shell = MockShell()
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        
        try manager.switchBranch(search: nil as String?)
        
        #expect(shell.executedCommands.contains("git checkout feature"))
    }
    
    @Test("Handles branch switching with search term")
    func switchBranchWithSearch() throws {
        let branches = [
            GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        let branchLoader = StubBranchLoader(localBranches: branches, filteredResults: ["feature"])
        let picker = MockPicker(selectionResponses: ["Select a branch (switching from main)": 0])
        let shell = MockShell()
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        
        try manager.switchBranch(search: "feat")
        
        #expect(shell.executedCommands.contains("git checkout feature"))
    }
    
    @Test("Handles exact branch name match")
    func switchBranchExactMatch() throws {
        let branchLoader = StubBranchLoader(branchNames: ["main", "feature"], filteredResults: ["feature"])
        let shell = MockShell()
        let manager = makeSUT(shell: shell, branchLoader: branchLoader)
        
        try manager.switchBranch(search: "feature")
        
        #expect(shell.executedCommands.contains("git checkout feature"))
    }
    
    @Test("Handles exact match with asterisk prefix")
    func switchBranchExactMatchWithAsterisk() throws {
        let branchLoader = StubBranchLoader(branchNames: ["main", "* feature"], filteredResults: ["* feature"])
        let shell = MockShell()
        let manager = makeSUT(shell: shell, branchLoader: branchLoader)
        
        try manager.switchBranch(search: "feature")
        
        #expect(shell.executedCommands.contains("git checkout feature"))
    }
    
    @Test("Handles no matches for search term")
    func switchBranchNoMatches() throws {
        let branchLoader = StubBranchLoader(branchNames: ["main", "feature"], filteredResults: [])
        let shell = MockShell()
        let manager = makeSUT(shell: shell, branchLoader: branchLoader)
        
        try manager.switchBranch(search: "nonexistent")
        
        #expect(!shell.executedCommands.contains { $0.contains("git checkout") })
    }
    
    @Test("Handles no current branch scenario")
    func switchBranchNoCurrent() throws {
        let branches = [
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "develop", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        let branchLoader = StubBranchLoader(localBranches: branches)
        let picker = MockPicker(selectionResponses: ["Select a branch ": 0])
        let shell = MockShell()
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        
        try manager.switchBranch(search: nil as String?)
        
        #expect(shell.executedCommands.contains("git checkout feature"))
    }
    
    @Test("Loads branch data correctly from configuration")
    func switchBranchLoadsCorrectData() throws {
        let branches = [
            GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        let branchLoader = StubBranchLoader(localBranches: branches)
        let picker = MockPicker(selectionResponses: ["Select a branch (switching from main)": 0])
        let shell = MockShell()
        let config = GitConfig.defaultConfig
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
        
        try manager.switchBranch(search: nil as String?)
        
        // Verify the workflow completed successfully
        #expect(shell.executedCommands.contains("git checkout feature"))
    }
    
    @Test("Separates current and available branches correctly")
    func switchBranchSeparatesBranches() throws {
        let branches = [
            GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "develop", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        let branchLoader = StubBranchLoader(localBranches: branches)
        let picker = MockPicker(selectionResponses: ["Select a branch (switching from main)": 1]) // Select develop
        let shell = MockShell()
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader)
        
        try manager.switchBranch(search: nil as String?)
        
        // Should switch to develop (second non-current branch)
        #expect(shell.executedCommands.contains("git checkout develop"))
    }
    
    @Test("Throws error when no available branches to switch to.")
    func switchBranchNoAvailableBranches() throws {
        let branches = [
            GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        ]
        let branchLoader = StubBranchLoader(localBranches: branches)
        let shell = MockShell()
        let manager = makeSUT(shell: shell, branchLoader: branchLoader)
        
        #expect(throws: BranchOperationError.noBranchesAvailable(operation: .switching)) {
            try manager.switchBranch(search: nil as String?)
        }
        
        // Should not execute any git checkout command
        #expect(!shell.executedCommands.contains { $0.contains("git checkout") })
    }
    
    @Test("Throws error when all branches are current.")
    func switchBranchAllBranchesCurrent() throws {
        // This is a theoretical edge case where somehow all branches are marked as current
        let branches = [
            GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        ]
        let branchLoader = StubBranchLoader(localBranches: branches)
        let shell = MockShell()
        let manager = makeSUT(shell: shell, branchLoader: branchLoader)
        
        #expect(throws: BranchOperationError.noBranchesAvailable(operation: .switching)) {
            try manager.switchBranch(search: nil as String?)
        }
        
        // Should not execute any git checkout command
        #expect(!shell.executedCommands.contains { $0.contains("git checkout") })
    }
}


// MARK: - SUT
private extension SwitchBranchManagerTests {
    func makeSUT(
        branchLocation: BranchLocation = .local,
        shell: MockShell = MockShell(),
        picker: MockPicker = MockPicker(),
        branchLoader: StubBranchLoader = StubBranchLoader(),
        config: GitConfig = GitConfig.defaultConfig
    ) -> SwitchBranchManager {
        
        return .init(
            branchLocation: branchLocation,
            shell: shell,
            picker: picker,
            branchLoader: branchLoader,
            config: config
        )
    }
}