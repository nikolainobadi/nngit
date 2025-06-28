//
//  GitBranch.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import Foundation

/// Represents a git branch along with metadata used throughout the tool.
struct GitBranch {
    let id: String
    let name: String
    let isMerged: Bool
    let isCurrentBranch: Bool
    let creationDate: Date?
    let syncStatus: BranchSyncStatus
    
    /// Creates a new ``GitBranch`` value.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for this branch model.
    ///   - name: Branch name as returned by git.
    ///   - isMerged: Indicates whether the branch is merged into the default branch.
    ///   - isCurrentBranch: Flag for the currently checked out branch.
    ///   - creationDate: Date the branch was created, if available.
    ///   - syncStatus: Synchronization state relative to its remote counterpart.
    init(id: String = UUID().uuidString, name: String, isMerged: Bool, isCurrentBranch: Bool, creationDate: Date?, syncStatus: BranchSyncStatus) {
        self.id = id
        self.name = name
        self.isMerged = isMerged
        self.isCurrentBranch = isCurrentBranch
        self.creationDate = creationDate
        self.syncStatus = syncStatus
    }
}


// MARK: - Dependencies
enum BranchSyncStatus: String, CaseIterable {
    case behind, ahead, nsync, diverged, undetermined, noRemoteBranch
}
