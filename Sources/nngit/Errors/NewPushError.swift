//
//  NewPushError.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import Foundation

/// Errors that can occur during new push operations.
enum NewPushError: Error, LocalizedError {
    case noRemoteRepository
    case remoteBranchExists(String)
    case uncommittedChanges
    
    var errorDescription: String? {
        switch self {
        case .noRemoteRepository:
            return "No remote repository found. Add a remote origin first."
        case .remoteBranchExists(let branchName):
            return "Remote branch '\(branchName)' already exists. Use 'git push' instead."
        case .uncommittedChanges:
            return "You have uncommitted changes. Commit or stash them before pushing."
        }
    }
}