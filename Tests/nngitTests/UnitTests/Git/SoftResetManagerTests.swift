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
    @Test("Handles commit selection with select flag")
    func handleCommitSelectionWithSelectSuccess() throws {
        let helper = MockGitResetHelper(selectCommitForResetResult: (count: 3, commits: mockCommits(count: 3)))
        let manager = makeSUT(helper: helper)
        let result = try manager.handleCommitSelection(select: true, number: 1)
        
        #expect(result?.count == 3)
        #expect(result?.commits.count == 3)
    }
    
    @Test("Handles commit selection with select flag cancelled")
    func handleCommitSelectionWithSelectCancelled() throws {
        let helper = MockGitResetHelper(selectCommitForResetResult: nil)
        let manager = makeSUT(helper: helper)
        let result = try manager.handleCommitSelection(select: true, number: 1)
        
        #expect(result == nil)
    }
    
    @Test("Handles commit selection with number")
    func handleCommitSelectionWithNumberSuccess() throws {
        let helper = MockGitResetHelper(prepareResetResult: mockCommits(count: 2))
        let manager = makeSUT(helper: helper)
        let result = try manager.handleCommitSelection(select: false, number: 2)
        
        #expect(result?.count == 2)
        #expect(result?.commits.count == 2)
    }
    
    @Test("Displays commits for soft reset")
    func displayCommitsForSoftResetSuccess() {
        let helper = MockGitResetHelper()
        let manager = makeSUT(helper: helper)
        let commits = mockCommits(count: 1)
        manager.displayCommitsForSoftReset(commits)
        
        #expect(helper.displayCommitsCommits?.count == commits.count)
        #expect(helper.displayCommitsAction == "moved back to staging area")
    }
    
    @Test("Verifies permissions with force flag")
    func verifyPermissionsWithForceSuccess() {
        let helper = MockGitResetHelper(verifyAuthorPermissionsResult: true)
        let manager = makeSUT(helper: helper)
        let commits = mockCommits(count: 1)
        let result = manager.verifyPermissions(commits: commits, force: true)
        
        #expect(result == true)
        #expect(helper.verifyAuthorPermissionsCommits?.count == commits.count)
        #expect(helper.verifyAuthorPermissionsForce == true)
    }
    
    @Test("Verifies permissions without force flag")
    func verifyPermissionsWithoutForceFailure() {
        let helper = MockGitResetHelper(verifyAuthorPermissionsResult: false)
        let manager = makeSUT(helper: helper)
        let commits = mockCommits(count: 1)
        let result = manager.verifyPermissions(commits: commits, force: false)
        
        #expect(result == false)
        #expect(helper.verifyAuthorPermissionsCommits?.count == commits.count)
        #expect(helper.verifyAuthorPermissionsForce == false)
    }
    
    @Test("Confirms soft reset successfully")
    func confirmSoftResetSuccess() throws {
        let helper = MockGitResetHelper()
        let manager = makeSUT(helper: helper)
        try manager.confirmSoftReset(count: 2)
        
        #expect(helper.confirmResetCount == 2)
        #expect(helper.confirmResetType == "soft")
    }
    
    @Test("Performs soft reset successfully")
    func performSoftResetSuccess() throws {
        let commitManager = MockCommitManager()
        let manager = makeSUT(commitManager: commitManager)
        try manager.performSoftReset(count: 3)
        
        #expect(commitManager.softResetCommitsCalled)
        #expect(commitManager.softResetCommitsCount == 3)
    }
    
    @Test("Executes complete soft reset workflow with number")
    func executeSoftResetWorkflowWithNumberSuccess() throws {
        let helper = MockGitResetHelper(prepareResetResult: mockCommits(count: 1), verifyAuthorPermissionsResult: true)
        let commitManager = MockCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        try manager.executeSoftResetWorkflow(select: false, number: 1, force: false)
        
        #expect(helper.prepareResetCount == 1)
        #expect(helper.displayCommitsCommits != nil)
        #expect(helper.verifyAuthorPermissionsCommits != nil)
        #expect(helper.confirmResetCount == 1)
        #expect(commitManager.softResetCommitsCalled)
    }
    
    @Test("Executes complete soft reset workflow with select")
    func executeSoftResetWorkflowWithSelectSuccess() throws {
        let helper = MockGitResetHelper(selectCommitForResetResult: (count: 2, commits: mockCommits(count: 2)), verifyAuthorPermissionsResult: true)
        let commitManager = MockCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        try manager.executeSoftResetWorkflow(select: true, number: 1, force: true)
        
        #expect(helper.displayCommitsCommits != nil)
        #expect(helper.verifyAuthorPermissionsCommits != nil)
        #expect(helper.verifyAuthorPermissionsForce == true)
        #expect(helper.confirmResetCount == 2)
        #expect(commitManager.softResetCommitsCalled)
    }
    
    @Test("Executes workflow with select cancelled")
    func executeSoftResetWorkflowSelectCancelled() throws {
        let helper = MockGitResetHelper(selectCommitForResetResult: nil)
        let commitManager = MockCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        try manager.executeSoftResetWorkflow(select: true, number: 1, force: false)
        
        #expect(helper.displayCommitsCommits == nil)
        #expect(helper.verifyAuthorPermissionsCommits == nil)
        #expect(helper.confirmResetCount == nil)
        #expect(!commitManager.softResetCommitsCalled)
    }
    
    @Test("Executes workflow with permission denied")
    func executeSoftResetWorkflowPermissionDenied() throws {
        let helper = MockGitResetHelper(prepareResetResult: mockCommits(count: 1), verifyAuthorPermissionsResult: false)
        let commitManager = MockCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        try manager.executeSoftResetWorkflow(select: false, number: 1, force: false)
        
        #expect(helper.prepareResetCount == 1)
        #expect(helper.displayCommitsCommits != nil)
        #expect(helper.verifyAuthorPermissionsCommits != nil)
        #expect(helper.confirmResetCount == nil)
        #expect(!commitManager.softResetCommitsCalled)
    }
    
    @Test("Handles zero commit count validation")
    func handleCommitSelectionZeroCount() throws {
        let helper = MockGitResetHelper()
        let manager = makeSUT(helper: helper)
        
        do {
            _ = try manager.handleCommitSelection(select: false, number: 0)
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            #expect(error is GitResetError)
        }
    }
    
    @Test("Handles negative commit count validation")
    func handleCommitSelectionNegativeCount() throws {
        let helper = MockGitResetHelper()
        let manager = makeSUT(helper: helper)
        
        do {
            _ = try manager.handleCommitSelection(select: false, number: -1)
            #expect(Bool(false), "Should have thrown an error")
        } catch {
            #expect(error is GitResetError)
        }
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