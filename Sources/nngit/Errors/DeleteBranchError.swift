//
//  DeleteBranchError.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Foundation

enum DeleteBranchError: Error, LocalizedError {
    case noEligibleBranches
    
    var errorDescription: String? {
        switch self {
        case .noEligibleBranches:
            return "No branches available for deletion. All branches are either the current branch or the default branch."
        }
    }
}