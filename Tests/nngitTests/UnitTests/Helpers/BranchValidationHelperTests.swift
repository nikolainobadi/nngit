//
//  BranchValidationHelperTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import GitShellKit
@testable import nngit

struct BranchValidationHelperTests {
    
    // MARK: - validateBranchesForSwitching Tests
    
    @Test("Passes validation when branches are available for switching.")
    func validateBranchesForSwitchingSuccess() throws {
        let branches = [
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "develop", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        
        // Should not throw
        try BranchValidationHelper.validateBranchesForSwitching(branches)
    }
    
    @Test("Passes validation when single branch is available for switching.")
    func validateBranchesForSwitchingSingleBranch() throws {
        let branches = [
            GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        
        // Should not throw
        try BranchValidationHelper.validateBranchesForSwitching(branches)
    }
    
    @Test("Throws switching error when no branches are available.")
    func validateBranchesForSwitchingEmpty() throws {
        let branches: [GitBranch] = []
        
        #expect(throws: BranchOperationError.noBranchesAvailable(operation: .switching)) {
            try BranchValidationHelper.validateBranchesForSwitching(branches)
        }
    }
    
    // MARK: - validateBranchesForDeletion Tests
    
    @Test("Passes validation when branches are eligible for deletion.")
    func validateBranchesForDeletionSuccess() throws {
        let branches = [
            GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined),
            GitBranch(name: "develop", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        
        // Should not throw
        try BranchValidationHelper.validateBranchesForDeletion(branches)
    }
    
    @Test("Passes validation when single branch is eligible for deletion.")
    func validateBranchesForDeletionSingleBranch() throws {
        let branches = [
            GitBranch(name: "feature", isMerged: true, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        ]
        
        // Should not throw
        try BranchValidationHelper.validateBranchesForDeletion(branches)
    }
    
    @Test("Throws deletion error when no branches are eligible.")
    func validateBranchesForDeletionEmpty() throws {
        let branches: [GitBranch] = []
        
        #expect(throws: BranchOperationError.noBranchesAvailable(operation: .deletion)) {
            try BranchValidationHelper.validateBranchesForDeletion(branches)
        }
    }
    
    // MARK: - validateBranchNamesForDeletion Tests
    
    @Test("Passes validation when branch names are available for deletion.")
    func validateBranchNamesForDeletionSuccess() throws {
        let branchNames = ["feature", "develop", "hotfix"]
        
        // Should not throw
        try BranchValidationHelper.validateBranchNamesForDeletion(branchNames)
    }
    
    @Test("Passes validation when single branch name is available for deletion.")
    func validateBranchNamesForDeletionSingleName() throws {
        let branchNames = ["feature"]
        
        // Should not throw
        try BranchValidationHelper.validateBranchNamesForDeletion(branchNames)
    }
    
    @Test("Throws deletion error when no branch names are available.")
    func validateBranchNamesForDeletionEmpty() throws {
        let branchNames: [String] = []
        
        #expect(throws: BranchOperationError.noBranchesAvailable(operation: .deletion)) {
            try BranchValidationHelper.validateBranchNamesForDeletion(branchNames)
        }
    }
    
    // MARK: - Edge Cases and Error Message Validation
    
    @Test("Switching error contains correct operation context.")
    func validateSwitchingErrorContext() throws {
        let branches: [GitBranch] = []
        
        do {
            try BranchValidationHelper.validateBranchesForSwitching(branches)
            Issue.record("Expected error to be thrown")
        } catch let error as BranchOperationError {
            switch error {
            case .noBranchesAvailable(let operation):
                #expect(operation == .switching)
            }
        }
    }
    
    @Test("Deletion error contains correct operation context.")
    func validateDeletionErrorContext() throws {
        let branches: [GitBranch] = []
        
        do {
            try BranchValidationHelper.validateBranchesForDeletion(branches)
            Issue.record("Expected error to be thrown")
        } catch let error as BranchOperationError {
            switch error {
            case .noBranchesAvailable(let operation):
                #expect(operation == .deletion)
            }
        }
    }
    
    @Test("Branch names deletion error contains correct operation context.")
    func validateBranchNamesDeletionErrorContext() throws {
        let branchNames: [String] = []
        
        do {
            try BranchValidationHelper.validateBranchNamesForDeletion(branchNames)
            Issue.record("Expected error to be thrown")
        } catch let error as BranchOperationError {
            switch error {
            case .noBranchesAvailable(let operation):
                #expect(operation == .deletion)
            }
        }
    }
    
    @Test("Error messages are properly localized.")
    func validateErrorMessages() throws {
        let switchingError = BranchOperationError.noBranchesAvailable(operation: .switching)
        let deletionError = BranchOperationError.noBranchesAvailable(operation: .deletion)
        
        #expect(switchingError.errorDescription?.contains("switch") == true)
        #expect(deletionError.errorDescription?.contains("deletion") == true)
        #expect(switchingError.errorDescription != deletionError.errorDescription)
    }
}