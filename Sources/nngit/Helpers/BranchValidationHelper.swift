//
//  BranchValidationHelper.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import GitShellKit

/// Helper utility for validating branch collections in branch operations
struct BranchValidationHelper {
    
    /// Validates that there are available branches for switching operations
    /// - Parameter availableBranches: The branches available for switching
    /// - Throws: BranchOperationError.noBranchesAvailable(.switching) if empty
    static func validateBranchesForSwitching(_ availableBranches: [GitBranch]) throws {
        guard !availableBranches.isEmpty else {
            throw BranchOperationError.noBranchesAvailable(operation: .switching)
        }
    }
    
    /// Validates that there are eligible branches for deletion operations
    /// - Parameter eligibleBranches: The branches eligible for deletion
    /// - Throws: BranchOperationError.noBranchesAvailable(.deletion) if empty
    static func validateBranchesForDeletion(_ eligibleBranches: [GitBranch]) throws {
        guard !eligibleBranches.isEmpty else {
            throw BranchOperationError.noBranchesAvailable(operation: .deletion)
        }
    }
    
    /// Validates that there are eligible branch names for deletion operations
    /// - Parameter eligibleBranchNames: The branch names eligible for deletion
    /// - Throws: BranchOperationError.noBranchesAvailable(.deletion) if empty
    static func validateBranchNamesForDeletion(_ eligibleBranchNames: [String]) throws {
        guard !eligibleBranchNames.isEmpty else {
            throw BranchOperationError.noBranchesAvailable(operation: .deletion)
        }
    }
}
