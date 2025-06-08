//
//  GitBranch.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import Foundation

struct GitBranch {
    let id: String
    let name: String
    let isMerged: Bool
    let isCurrentBranch: Bool
    let creationDate: Date?
    let syncStatus: BranchSyncStatus
    
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
