//
//  SoftResetManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import GitShellKit
@testable import nngit

struct SoftResetManagerTests {
    @Test("Successfully executes soft reset workflow with number")
    func performSoftResetWithNumberSuccess() throws {
        let helper = MockGitResetHelper(prepareResetResult: mockCommits(count: 2), verifyAuthorPermissionsResult: true)
        let commitManager = MockCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        try manager.performSoftReset(select: false, number: 2, force: false)
        
        #expect(helper.prepareResetCount == 2)
        #expect(helper.displayCommitsCommits != nil)
        #expect(helper.verifyAuthorPermissionsCommits != nil)
        #expect(helper.verifyAuthorPermissionsForce == false)
        #expect(helper.confirmResetCount == 2)
        #expect(helper.confirmResetType == "soft")
        #expect(commitManager.softResetCommitsCalled)
        #expect(commitManager.softResetCommitsCount == 2)
    }
    
    @Test("Successfully executes soft reset workflow with select")
    func performSoftResetWithSelectSuccess() throws {
        let helper = MockGitResetHelper(selectCommitForResetResult: (count: 3, commits: mockCommits(count: 3)), verifyAuthorPermissionsResult: true)
        let commitManager = MockCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        try manager.performSoftReset(select: true, number: 1, force: true)
        
        #expect(helper.displayCommitsCommits != nil)
        #expect(helper.verifyAuthorPermissionsCommits != nil)
        #expect(helper.verifyAuthorPermissionsForce == true)
        #expect(helper.confirmResetCount == 3)
        #expect(helper.confirmResetType == "soft")
        #expect(commitManager.softResetCommitsCalled)
        #expect(commitManager.softResetCommitsCount == 3)
    }
    
    @Test("Handles user cancellation during commit selection")
    func performSoftResetSelectCancelled() throws {
        let helper = MockGitResetHelper(selectCommitForResetResult: nil)
        let commitManager = MockCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        try manager.performSoftReset(select: true, number: 1, force: false)
        
        #expect(helper.displayCommitsCommits == nil)
        #expect(helper.verifyAuthorPermissionsCommits == nil)
        #expect(helper.confirmResetCount == nil)
        #expect(!commitManager.softResetCommitsCalled)
    }
    
    @Test("Handles permission denied without force flag")
    func performSoftResetPermissionDenied() throws {
        let helper = MockGitResetHelper(prepareResetResult: mockCommits(count: 1), verifyAuthorPermissionsResult: false)
        let commitManager = MockCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        try manager.performSoftReset(select: false, number: 1, force: false)
        
        #expect(helper.prepareResetCount == 1)
        #expect(helper.displayCommitsCommits != nil)
        #expect(helper.verifyAuthorPermissionsCommits != nil)
        #expect(helper.verifyAuthorPermissionsForce == false)
        #expect(helper.confirmResetCount == nil)
        #expect(!commitManager.softResetCommitsCalled)
    }
    
    @Test("Executes workflow with force flag overriding permissions")
    func performSoftResetWithForceFlag() throws {
        let helper = MockGitResetHelper(prepareResetResult: mockCommits(count: 1), verifyAuthorPermissionsResult: true)
        let commitManager = MockCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        try manager.performSoftReset(select: false, number: 1, force: true)
        
        #expect(helper.prepareResetCount == 1)
        #expect(helper.verifyAuthorPermissionsForce == true)
        #expect(helper.confirmResetCount == 1)
        #expect(commitManager.softResetCommitsCalled)
    }
    
    @Test("Handles invalid commit count (zero)")
    func performSoftResetInvalidCountZero() throws {
        let helper = MockGitResetHelper()
        let commitManager = MockCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        
        do {
            try manager.performSoftReset(select: false, number: 0, force: false)
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            #expect(error is GitResetError)
            #expect(!commitManager.softResetCommitsCalled)
        }
    }
    
    @Test("Handles invalid commit count (negative)")
    func performSoftResetInvalidCountNegative() throws {
        let helper = MockGitResetHelper()
        let commitManager = MockCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        
        do {
            try manager.performSoftReset(select: false, number: -1, force: false)
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            #expect(error is GitResetError)
            #expect(!commitManager.softResetCommitsCalled)
        }
    }
    
    @Test("Displays commits with correct action message")
    func performSoftResetDisplaysCommitsCorrectly() throws {
        let commits = mockCommits(count: 2)
        let helper = MockGitResetHelper(prepareResetResult: commits, verifyAuthorPermissionsResult: true)
        let commitManager = MockCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        try manager.performSoftReset(select: false, number: 2, force: false)
        
        #expect(helper.displayCommitsAction == "moved back to staging area")
        #expect(helper.displayCommitsCommits?.count == 2)
    }
    
    @Test("Executes complete workflow in correct order")
    func performSoftResetCorrectOrder() throws {
        let helper = MockGitResetHelper(prepareResetResult: mockCommits(count: 1), verifyAuthorPermissionsResult: true)
        let commitManager = MockCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        try manager.performSoftReset(select: false, number: 1, force: false)
        
        // Verify the workflow steps were executed
        #expect(helper.prepareResetCount == 1) // 1. Load commits
        #expect(helper.displayCommitsCommits != nil) // 2. Display commits
        #expect(helper.verifyAuthorPermissionsCommits != nil) // 3. Verify permissions
        #expect(helper.confirmResetCount == 1) // 4. Confirm reset
        #expect(commitManager.softResetCommitsCalled) // 5. Perform reset
    }
}


// MARK: - SUT
private extension SoftResetManagerTests {
    func makeSUT(helper: MockGitResetHelper = MockGitResetHelper(), commitManager: MockCommitManager = MockCommitManager()) -> SoftResetManager {
        
        return .init(helper: helper, commitManager: commitManager)
    }
    
    func mockCommits(count: Int) -> [CommitInfo] {
        return (1...count).map { i in
            CommitInfo(hash: "abc\(i)", message: "Commit \(i)", author: "Test User <test@example.com>", date: "1 hour ago", wasAuthoredByCurrentUser: true)
        }
    }
}