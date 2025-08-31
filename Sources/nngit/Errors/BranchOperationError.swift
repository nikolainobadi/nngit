//
//  BranchOperationError.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Foundation

enum BranchOperationError: Error, LocalizedError, Equatable {
    case noBranchesAvailable(operation: BranchOperation)
    
    enum BranchOperation: Equatable {
        case switching
        case deletion
    }
    
    var errorDescription: String? {
        switch self {
        case .noBranchesAvailable(.switching):
            return "No available branches to switch to. All branches are currently checked out or there is only one branch."
        case .noBranchesAvailable(.deletion):
            return "No branches available for deletion. All branches are either the current branch or the default branch."
        }
    }
}