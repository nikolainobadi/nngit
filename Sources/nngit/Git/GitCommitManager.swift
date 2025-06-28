//
//  GitCommitManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/22/25.
//

/// Abstraction for interacting with git commits.
protocol GitCommitManager {
    /// Retrieves commit metadata for the specified number of commits.
    func getCommitInfo(count: Int) throws -> [CommitInfo]
    /// Performs a hard reset to remove the specified number of commits.
    func undoCommits(count: Int) throws
}
