//
//  StubBranchLoader.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/21/25.
//

import GitShellKit
@testable import nngit

final class StubBranchLoader: GitBranchLoader {
    private let remoteBranches: [String]
    private let localBranches: [GitBranch]
    
    init(remoteBranches: [String] = [], localBranches: [GitBranch] = []) {
        self.remoteBranches = remoteBranches
        self.localBranches = localBranches
    }
    
    func loadBranchNames(from location: BranchLocation, shell: GitShell) throws -> [String] {
        switch location {
        case .local:
            return localBranches.map { $0.isCurrentBranch ? "* \($0.name)" : $0.name }
        case .remote:
            return remoteBranches
        case .both:
            return remoteBranches + localBranches.map { $0.name }
        }
    }

    func loadBranches(
        for names: [String],
        shell: GitShell,
        mainBranchName: String,
        loadMergeStatus: Bool,
        loadCreationDate: Bool,
        loadSyncStatus: Bool
    ) throws -> [GitBranch] {
        return localBranches.filter { branch in
            names.contains(branch.name) || names.contains("* \(branch.name)")
        }
    }
}
