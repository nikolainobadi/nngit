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
    
    @Test("Handles no eligible branches")
    func deleteBranchesNoEligible() throws {
        let branchLoader = StubBranchLoader(branchNames: ["main"])
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: nil as String?, allMerged: false)
        
        #expect(!shell.executedCommands.contains { $0.contains("git branch") })
    }
    
    @Test("Excludes current branch from eligible branches.")
    func deleteBranchesExcludesCurrentBranch() throws {
        // Branch names from git include "*" prefix for current branch
        let branchLoader = StubBranchLoader(branchNames: ["main", "* feature", "develop"])
        let picker = MockPicker()  // No selection needed as current branch should be filtered
        let shell = MockShell()
        let config = makeConfig(defaultBranch: "main")
        let manager = makeSUT(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
        
        try manager.deleteBranches(search: nil as String?, allMerged: false)
        
        // Only develop should be available (main is default, feature is current)
        #expect(!shell.executedCommands.contains { $0.contains("feature") })
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