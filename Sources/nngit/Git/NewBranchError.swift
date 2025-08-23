//
//  NewBranchError.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Foundation

enum NewBranchError: Error, LocalizedError {
    case branchDiverged
    case branchStatusUndetermined
    case noRemoteBranch
    
    var errorDescription: String? {
        switch self {
        case .branchDiverged:
            return "Cannot create new branch: Your branch has diverged from remote. Please resolve conflicts first."
        case .branchStatusUndetermined:
            return "Cannot create new branch: Unable to determine branch status. Please check your remote connection."
        case .noRemoteBranch:
            return "Cannot create new branch: No remote branch found for comparison."
        }
    }
}
