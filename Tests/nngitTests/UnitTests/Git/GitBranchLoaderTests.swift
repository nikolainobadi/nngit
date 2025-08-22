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
}