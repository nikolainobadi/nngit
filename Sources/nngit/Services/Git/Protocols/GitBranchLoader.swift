//
//  GitBranchLoader.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import GitShellKit

/// Protocol for loading Git branches, abstracted for testing.
protocol GitBranchLoader {
    /// Returns just the raw branch names from the given location.
    func loadBranchNames(from location: BranchLocation) throws -> [String]
    
    /// Creates ``GitBranch`` models using the provided branch names. If names is nil, loads all local branches.
    func loadBranches(for names: [String]?, mainBranchName: String) throws -> [GitBranch]
    
    /// Returns the synchronization status between a local branch and its remote counterpart.
    ///
    /// - Parameters:
    ///   - branchName: The local branch name to compare.
    ///   - comparingBranch: Optional remote branch name to compare against. When
    ///     `nil`, the same branch name on `origin` is used.
    /// - Returns: ``BranchSyncStatus`` describing whether the branch is ahead,
    ///   behind, or in sync with the remote.
    func getSyncStatus(branchName: String, comparingBranch: String?) throws -> BranchSyncStatus
}


// MARK: - Filtering Helpers
extension GitBranchLoader {
    /// Filters branch names by a search term, matching case-insensitively on the name.
    func filterBranchNamesBySearch(_ names: [String], search: String?) -> [String] {
        guard let search,
              !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return names }

        return names.filter { $0.lowercased().contains(search.lowercased()) }
    }
}
