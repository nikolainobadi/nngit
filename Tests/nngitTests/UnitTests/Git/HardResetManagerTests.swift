//
//  HardResetManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
@testable import nngit

struct HardResetManagerTests {
    @Test("Successfully executes hard reset workflow with number")
    func hardResetWithNumber() throws {
        let commitInfo = [
            CommitInfo(hash: "abc123", message: "Latest commit", author: "John <john@example.com>", date: "1 hour ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "def456", message: "Previous commit", author: "John <john@example.com>", date: "2 hours ago", wasAuthoredByCurrentUser: true)
        ]
        let helper = MockGitResetHelper(
            prepareResetResult: commitInfo,
            verifyAuthorPermissionsResult: true
        )
        let commitManager = TestCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        
        try manager.performHardReset(select: false, number: 2, force: false)
        
        let displayedCommitsCount = try #require(helper.displayCommitsCommits).count
        
        #expect(displayedCommitsCount == 2)
        #expect(helper.prepareResetCount == 2)
        #expect(helper.displayCommitsAction == "discarded")
        #expect(helper.verifyAuthorPermissionsCommits != nil)
        #expect(helper.verifyAuthorPermissionsForce == false)
        #expect(helper.confirmResetCount == 2)
        #expect(helper.confirmResetType == "hard")
        #expect(commitManager.undoCommitsCount == 2)
    }
    
    @Test("Successfully executes hard reset workflow with select")
    func hardResetWithSelect() throws {
        let commitInfo = [
            CommitInfo(hash: "abc123", message: "Selected commit", author: "John <john@example.com>", date: "1 hour ago", wasAuthoredByCurrentUser: true)
        ]
        let helper = MockGitResetHelper(
            selectCommitForResetResult: (count: 1, commits: commitInfo),
            verifyAuthorPermissionsResult: true
        )
        let commitManager = TestCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        
        try manager.performHardReset(select: true, number: 5, force: false)
        
        // When select is true, the helper's selectCommitForReset method is called
        #expect(helper.displayCommitsCommits?.count == 1)
        #expect(helper.displayCommitsAction == "discarded")
        #expect(helper.verifyAuthorPermissionsCommits != nil)
        #expect(helper.verifyAuthorPermissionsForce == false)
        #expect(helper.confirmResetCount == 1)
        #expect(helper.confirmResetType == "hard")
        #expect(commitManager.undoCommitsCount == 1)
    }
    
    @Test("Handles user cancellation during commit selection")
    func hardResetSelectCancelled() throws {
        let helper = MockGitResetHelper(selectCommitForResetResult: nil)
        let commitManager = TestCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        
        try manager.performHardReset(select: true, number: 1, force: false)
        
        // When selection is cancelled, no further operations occur
        #expect(helper.displayCommitsCommits == nil)
        #expect(helper.verifyAuthorPermissionsCommits == nil)
        #expect(helper.confirmResetCount == nil)
        #expect(commitManager.undoCommitsCount == nil)
    }
    
    @Test("Handles permission denied without force flag")
    func hardResetPermissionDenied() throws {
        let commitInfo = [
            CommitInfo(hash: "abc123", message: "Other's commit", author: "Jane <jane@example.com>", date: "1 hour ago", wasAuthoredByCurrentUser: false)
        ]
        let helper = MockGitResetHelper(
            prepareResetResult: commitInfo,
            verifyAuthorPermissionsResult: false
        )
        let commitManager = TestCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        
        try manager.performHardReset(select: false, number: 1, force: false)
        
        #expect(helper.prepareResetCount == 1)
        #expect(helper.displayCommitsCommits?.count == 1)
        #expect(helper.verifyAuthorPermissionsCommits != nil)
        #expect(helper.verifyAuthorPermissionsForce == false)
        #expect(helper.confirmResetCount == nil)
        #expect(commitManager.undoCommitsCount == nil)
    }
    
    @Test("Executes workflow with force flag overriding permissions")
    func hardResetWithForce() throws {
        let commitInfo = [
            CommitInfo(hash: "abc123", message: "Other's commit", author: "Jane <jane@example.com>", date: "1 hour ago", wasAuthoredByCurrentUser: false)
        ]
        let helper = MockGitResetHelper(
            prepareResetResult: commitInfo,
            verifyAuthorPermissionsResult: true
        )
        let commitManager = TestCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        
        try manager.performHardReset(select: false, number: 1, force: true)
        
        #expect(helper.prepareResetCount == 1)
        #expect(helper.displayCommitsCommits?.count == 1)
        #expect(helper.verifyAuthorPermissionsCommits != nil)
        #expect(helper.verifyAuthorPermissionsForce == true)
        #expect(helper.confirmResetCount == 1)
        #expect(helper.confirmResetType == "hard")
        #expect(commitManager.undoCommitsCount == 1)
    }
    
    @Test("Handles invalid commit count (zero)")
    func hardResetInvalidCountZero() throws {
        let helper = MockGitResetHelper()
        let commitManager = TestCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        
        #expect(throws: GitResetError.invalidCount) {
            try manager.performHardReset(select: false, number: 0, force: false)
        }
        
        #expect(helper.prepareResetCount == nil)
        #expect(helper.displayCommitsCommits == nil)
        #expect(commitManager.undoCommitsCount == nil)
    }
    
    @Test("Handles invalid commit count (negative)")
    func hardResetInvalidCountNegative() throws {
        let helper = MockGitResetHelper()
        let commitManager = TestCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        
        #expect(throws: GitResetError.invalidCount) {
            try manager.performHardReset(select: false, number: -1, force: false)
        }
        
        #expect(helper.prepareResetCount == nil)
        #expect(helper.displayCommitsCommits == nil)
        #expect(commitManager.undoCommitsCount == nil)
    }
    
    @Test("Displays commits with correct action message")
    func hardResetDisplaysCorrectAction() throws {
        let commitInfo = [
            CommitInfo(hash: "abc123", message: "Test commit", author: "John <john@example.com>", date: "1 hour ago", wasAuthoredByCurrentUser: true)
        ]
        let helper = MockGitResetHelper(
            prepareResetResult: commitInfo,
            verifyAuthorPermissionsResult: true
        )
        let commitManager = TestCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        
        try manager.performHardReset(select: false, number: 1, force: false)
        
        #expect(helper.displayCommitsAction == "discarded")
    }
    
    @Test("Executes complete workflow in correct order")
    func hardResetWorkflowOrder() throws {
        let commitInfo = [
            CommitInfo(hash: "abc123", message: "Test commit", author: "John <john@example.com>", date: "1 hour ago", wasAuthoredByCurrentUser: true)
        ]
        let helper = MockGitResetHelper(
            prepareResetResult: commitInfo,
            verifyAuthorPermissionsResult: true
        )
        let commitManager = TestCommitManager()
        let manager = makeSUT(helper: helper, commitManager: commitManager)
        
        try manager.performHardReset(select: false, number: 1, force: false)
        
        // Verify the workflow executed in the correct order
        #expect(helper.prepareResetCount == 1)
        #expect(helper.displayCommitsCommits?.count == 1)
        #expect(helper.verifyAuthorPermissionsCommits != nil)
        #expect(helper.confirmResetCount == 1)
        #expect(commitManager.undoCommitsCount == 1)
    }
}


// MARK: - SUT
private extension HardResetManagerTests {
    func makeSUT(
        helper: MockGitResetHelper = MockGitResetHelper(),
        commitManager: TestCommitManager = TestCommitManager()
    ) -> HardResetManager {
        return .init(helper: helper, commitManager: commitManager)
    }
}


// MARK: - Test Commit Manager
private final class TestCommitManager: GitCommitManager {
    private(set) var undoCommitsCount: Int?
    
    func getCommitInfo(count: Int) throws -> [CommitInfo] {
        return []
    }
    
    func undoCommits(count: Int) throws {
        undoCommitsCount = count
    }
    
    func softResetCommits(count: Int) throws {
        // Not used in hard reset
    }
}
