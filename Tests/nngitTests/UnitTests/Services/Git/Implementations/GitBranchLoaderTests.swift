//
//  GitBranchLoaderTests.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import GitShellKit
@testable import nngit

struct GitBranchLoaderTests {
    
    @Test("loadBranches with nil names returns all local branches")
    func loadBranchesWithNilNames() throws {
        let localBranches = [
            GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .nsync),
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .ahead),
            GitBranch(name: "bugfix", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .nsync)
        ]
        
        let loader = StubBranchLoader(localBranches: localBranches)
        let result = try loader.loadBranches(for: nil, mainBranchName: "main")
        
        #expect(result.count == 3)
        #expect(result.map { $0.name }.contains("main"))
        #expect(result.map { $0.name }.contains("feature"))
        #expect(result.map { $0.name }.contains("bugfix"))
    }
    
    @Test("loadBranches with specific names filters branches correctly")
    func loadBranchesWithSpecificNames() throws {
        let localBranches = [
            GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .nsync),
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .ahead),
            GitBranch(name: "bugfix", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .nsync)
        ]
        
        let loader = StubBranchLoader(localBranches: localBranches)
        let result = try loader.loadBranches(for: ["feature", "main"], mainBranchName: "main")
        
        #expect(result.count == 2)
        #expect(result.map { $0.name }.contains("main"))
        #expect(result.map { $0.name }.contains("feature"))
        #expect(!result.map { $0.name }.contains("bugfix"))
    }
    
    @Test("loadBranches with empty names array returns empty result")
    func loadBranchesWithEmptyNames() throws {
        let localBranches = [
            GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .nsync),
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .ahead)
        ]

        let loader = StubBranchLoader(localBranches: localBranches)
        let result = try loader.loadBranches(for: [], mainBranchName: "main")

        #expect(result.count == 0)
    }

    @Test("loadBranchNames from remote location filters out branches with local counterparts")
    func loadBranchNamesRemoteFiltersLocalCounterparts() throws {
        let remoteBranches = ["origin/main", "origin/feature", "origin/develop", "origin/hotfix"]
        let localBranches = ["main", "develop"]
        let loader = StubBranchLoader(
            remoteBranches: remoteBranches,
            localBranchNames: localBranches
        )

        let result = try loader.loadBranchNames(from: .remote)

        // Should only return remote branches without local counterparts
        #expect(result.count == 2)
        #expect(result.contains("origin/feature"))
        #expect(result.contains("origin/hotfix"))
        #expect(!result.contains("origin/main"))    // Has local counterpart
        #expect(!result.contains("origin/develop")) // Has local counterpart
    }

    @Test("loadBranchNames from local location returns local branches")
    func loadBranchNamesLocalReturnsLocal() throws {
        let localBranches = [
            GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .nsync),
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .ahead)
        ]
        let loader = StubBranchLoader(localBranches: localBranches)

        let result = try loader.loadBranchNames(from: .local)

        #expect(result.count == 2)
        #expect(result.contains("* main"))
        #expect(result.contains("feature"))
    }

    @Test("loadBranchNames from both location returns all branches")
    func loadBranchNamesBothReturnsAll() throws {
        let remoteBranches = ["origin/feature", "origin/hotfix"]
        let localBranches = [
            GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .nsync),
            GitBranch(name: "develop", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .ahead)
        ]
        let loader = StubBranchLoader(remoteBranches: remoteBranches, localBranches: localBranches)

        let result = try loader.loadBranchNames(from: .both)

        #expect(result.count == 4)
        #expect(result.contains("origin/feature"))
        #expect(result.contains("origin/hotfix"))
        #expect(result.contains("main"))
        #expect(result.contains("develop"))
    }

    @Test("Remote filtering handles various remote prefixes correctly")
    func remoteBranchFilteringHandlesVariousPrefixes() throws {
        let remoteBranches = ["origin/feature", "upstream/develop", "fork/hotfix"]
        let localBranches = ["main", "feature"] // Only "feature" has remote counterpart
        let loader = StubBranchLoader(
            remoteBranches: remoteBranches,
            localBranchNames: localBranches
        )

        let result = try loader.loadBranchNames(from: .remote)

        #expect(result.count == 2)
        #expect(result.contains("upstream/develop"))
        #expect(result.contains("fork/hotfix"))
        #expect(!result.contains("origin/feature")) // Has local counterpart
    }
}