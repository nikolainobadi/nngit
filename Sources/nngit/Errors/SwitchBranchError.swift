//
//  SwitchBranchError.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Foundation

enum SwitchBranchError: Error, LocalizedError {
    case noAvailableBranches
    
    var errorDescription: String? {
        switch self {
        case .noAvailableBranches:
            return "No available branches to switch to. All branches are currently checked out or there is only one branch."
        }
    }
}