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
    private let branchNames: [String]?
    private let filteredResults: [String]?
    
    init(remoteBranches: [String] = [], localBranches: [GitBranch] = [], branchNames: [String]? = nil, filteredResults: [String]? = nil) {
        self.remoteBranches = remoteBranches
        self.localBranches = localBranches
        self.branchNames = branchNames
        self.filteredResults = filteredResults
    }
    
    func loadBranchNames(from location: BranchLocation, shell: GitShell) throws -> [String] {
        if let branchNames = branchNames {
            return branchNames
        }
        
        switch location {
        case .local:
            return localBranches.map { $0.isCurrentBranch ? "* \($0.name)" : $0.name }
        case .remote:
            return remoteBranches
        case .both:
            return remoteBranches + localBranches.map { $0.name }
        }
    }

    func loadBranches(for names: [String], shell: GitShell, mainBranchName: String) throws -> [GitBranch] {
        return localBranches.filter { branch in
            names.contains(branch.name) || names.contains("* \(branch.name)")
        }
    }
    
    func getSyncStatus(branchName: String, comparingBranch: String?, shell: GitShell, remoteExists: Bool) throws -> BranchSyncStatus {
        // For testing, return the sync status from the predefined branches
        let cleanBranchName = branchName.hasPrefix("*") ? String(branchName.dropFirst(2)) : branchName
        return localBranches.first { $0.name == cleanBranchName }?.syncStatus ?? .undetermined
    }
    
    // Override extension methods to avoid shell commands in tests
    func filterBranchNamesByAuthor(_ names: [String], shell: GitShell, includeAuthor: [String]) -> [String] {
        // For testing, return all names (simulate that user owns all branches)
        return names
    }
    
    func filterBranchNamesBySearch(_ names: [String], search: String?) -> [String] {
        if let filteredResults = filteredResults {
            return filteredResults
        }
        
        guard let search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return names }
        return names.filter { $0.lowercased().contains(search.lowercased()) }
    }
    
    func filterBranchesByAuthor(_ branches: [GitBranch], shell: GitShell, includeAuthor: [String]) -> [GitBranch] {
        // For testing, return all branches (simulate that user owns all branches)
        return branches
    }
}
