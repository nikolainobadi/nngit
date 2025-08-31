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
        let picker = MockPicker(permissionResponses: ["Do you want to proceed with deleting these 2 merged branches?": true])  // User confirms deletion
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: nil as String?, allMerged: true)
        
        #expect(shell.executedCommands.contains("git branch -d feature"))
        #expect(shell.executedCommands.contains("git branch -d develop"))
        #expect(!shell.executedCommands.contains { $0.contains("unmerged") })
    }
    
    @Test("Throws error when no eligible branches exist.")
    func deleteBranchesNoEligible() throws {
        let branchLoader = StubBranchLoader(branchNames: ["main"])
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, branchLoader: branchLoader, config: config)
        
        #expect(throws: DeleteBranchError.noEligibleBranches) {
            try manager.deleteBranches(search: nil as String?, allMerged: false)
        }
        
        #expect(!shell.executedCommands.contains { $0.contains("git branch") })
    }
    
    @Test("Excludes current branch from eligible branches.")
    func deleteBranchesExcludesCurrentBranch() throws {
        // Branch names from git include "*" prefix for current branch
        let developBranch = GitBranch(name: "develop", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branchLoader = StubBranchLoader(
            localBranches: [developBranch],
            branchNames: ["main", "* feature", "develop"]
        )
        let picker = MockPicker(
            permissionResponses: ["This branch has NOT been merged into main. Are you sure you want to delete it?": true],
            selectionResponses: ["Select which branches to delete": 0]  // Select develop
        )
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: nil as String?, allMerged: false)
        
        // Only develop should be available and deleted (main is default, feature is current)
        #expect(shell.executedCommands.contains("git branch -D develop"))
        #expect(!shell.executedCommands.contains { $0.contains("feature") })
        #expect(!shell.executedCommands.contains { $0.contains("main") })
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
    
    @Test("Cancels deletion when user denies confirmation for allMerged.")
    func deleteBranchesAllMergedUserDenies() throws {
        let branches = [
            GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "develop", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        let branchLoader = StubBranchLoader(localBranches: branches, branchNames: ["main", "feature", "develop"])
        let picker = MockPicker(permissionResponses: ["Do you want to proceed with deleting these 2 merged branches?": false])  // User denies deletion
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: nil as String?, allMerged: true)
        
        // No branches should be deleted when user denies
        #expect(!shell.executedCommands.contains { $0.contains("git branch") })
    }
    
    @Test("Excludes current branch from allMerged deletion.")
    func deleteBranchesAllMergedExcludesCurrentBranch() throws {
        // Create branches where develop is current (marked with *) but also merged
        let developBranch = GitBranch(name: "develop", isMerged: true, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let featureBranch = GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branches = [developBranch, featureBranch]
        
        let branchLoader = StubBranchLoader(localBranches: branches, branchNames: ["main", "* develop", "feature"])
        let picker = MockPicker(permissionResponses: ["Do you want to proceed with deleting these 1 merged branches?": true])
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: nil as String?, allMerged: true)
        
        // Only feature should be deleted, not develop (current branch)
        #expect(shell.executedCommands.contains("git branch -d feature"))
        #expect(!shell.executedCommands.contains { $0.contains("develop") })
    }
    
    @Test("Displays truncated list when more than 10 branches for allMerged.")
    func deleteBranchesAllMergedManyBranches() throws {
        // Create 15 merged branches
        var branches: [GitBranch] = []
        var branchNames = ["main"]
        for i in 1...15 {
            let branch = GitBranch(name: "feature-\(i)", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
            branches.append(branch)
            branchNames.append("feature-\(i)")
        }
        
        let branchLoader = StubBranchLoader(localBranches: branches, branchNames: branchNames)
        let picker = MockPicker(permissionResponses: ["Do you want to proceed with deleting these 15 merged branches?": true])  // User confirms deletion
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: nil as String?, allMerged: true)
        
        // All 15 branches should be deleted
        for i in 1...15 {
            #expect(shell.executedCommands.contains("git branch -d feature-\(i)"))
        }
    }
    
    @Test("Throws error when only current branch exists.")
    func deleteBranchesOnlyCurrentBranch() throws {
        let branchLoader = StubBranchLoader(branchNames: ["* main"])
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, branchLoader: branchLoader, config: config)
        
        #expect(throws: DeleteBranchError.noEligibleBranches) {
            try manager.deleteBranches(search: nil as String?, allMerged: false)
        }
        
        #expect(!shell.executedCommands.contains { $0.contains("git branch") })
    }
    
    @Test("Throws error when only default and current branches exist.")
    func deleteBranchesOnlyDefaultAndCurrent() throws {
        let branchLoader = StubBranchLoader(branchNames: ["main", "* feature"])
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, branchLoader: branchLoader, config: config)
        
        #expect(throws: DeleteBranchError.noEligibleBranches) {
            try manager.deleteBranches(search: nil as String?, allMerged: false)
        }
        
        #expect(!shell.executedCommands.contains { $0.contains("git branch") })
    }
    
    @Test("Throws error when all branches are filtered out after loading.")
    func deleteBranchesAllFilteredOut() throws {
        // This simulates a case where branches pass initial filtering but fail after loadBranchData
        // (e.g., all branches are marked as current in the loaded data)
        let branches: [GitBranch] = []  // Empty after loading
        let branchLoader = StubBranchLoader(localBranches: branches, branchNames: ["main", "feature"])
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, branchLoader: branchLoader, config: config)
        
        #expect(throws: DeleteBranchError.noEligibleBranches) {
            try manager.deleteBranches(search: nil as String?, allMerged: false)
        }
        
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