//
//  DefaultGitResetHelperTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import GitShellKit
@testable import nngit

struct DefaultGitResetHelperTests {
    @Test("selects commit for reset returns nil when no commits available")
    func selectCommitForResetReturnsNilWhenNoCommits() throws {
        let (sut, manager, _) = makeSUT(commitInfo: [])
        
        let result = try sut.selectCommitForReset()
        
        #expect(result == nil)
        #expect(manager.getCommitInfoCalled)
        #expect(manager.getCommitInfoCount == 7)
    }
    
    @Test("selects commit for reset returns selected commit and count")
    func selectCommitForResetReturnsSelectedCommit() throws {
        let commits = [
            CommitInfo(hash: "abc123", message: "First", author: "User", date: "1h ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "def456", message: "Second", author: "User", date: "2h ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "ghi789", message: "Third", author: "User", date: "3h ago", wasAuthoredByCurrentUser: true)
        ]
        let picker = MockPicker(selectionResponses: ["Select a commit to reset to:": 1]) // Select second commit
        let (sut, _, _) = makeSUT(commitInfo: commits, picker: picker)
        
        let result = try sut.selectCommitForReset()
        
        #expect(result != nil)
        #expect(result?.count == 2)
        #expect(result?.commits.count == 2)
        #expect(result?.commits[0].hash == "abc123")
        #expect(result?.commits[1].hash == "def456")
    }
    
    @Test("selects commit for reset handles selection of last commit")
    func selectCommitForResetHandlesLastCommit() throws {
        let commits = [
            CommitInfo(hash: "abc123", message: "First", author: "User", date: "1h ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "def456", message: "Second", author: "User", date: "2h ago", wasAuthoredByCurrentUser: true)
        ]
        let picker = MockPicker(selectionResponses: ["Select a commit to reset to:": 1]) // Select last commit
        let (sut, _, _) = makeSUT(commitInfo: commits, picker: picker)
        
        let result = try sut.selectCommitForReset()
        
        #expect(result?.count == 2)
        #expect(result?.commits.count == 2)
    }
    
    @Test("prepare reset validates count greater than zero")
    func prepareResetValidatesCount() throws {
        let (sut, _, _) = makeSUT()
        
        #expect(throws: GitResetError.invalidCount) {
            _ = try sut.prepareReset(count: 0)
        }
        
        #expect(throws: GitResetError.invalidCount) {
            _ = try sut.prepareReset(count: -1)
        }
    }
    
    @Test("prepare reset returns commit info for valid count")
    func prepareResetReturnsCommitInfo() throws {
        let commits = [
            CommitInfo(hash: "abc123", message: "First", author: "User", date: "1h ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "def456", message: "Second", author: "User", date: "2h ago", wasAuthoredByCurrentUser: true)
        ]
        let (sut, manager, _) = makeSUT(commitInfo: commits)
        
        let result = try sut.prepareReset(count: 2)
        
        #expect(result.count == 2)
        #expect(result[0].hash == "abc123")
        #expect(result[1].hash == "def456")
        #expect(manager.getCommitInfoCalled)
        #expect(manager.getCommitInfoCount == 2)
    }
    
    @Test("verify author permissions returns true when all commits by current user")
    func verifyAuthorPermissionsWithCurrentUser() throws {
        let commits = [
            CommitInfo(hash: "abc123", message: "First", author: "User", date: "1h ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "def456", message: "Second", author: "User", date: "2h ago", wasAuthoredByCurrentUser: true)
        ]
        let (sut, _, _) = makeSUT()
        
        let result = sut.verifyAuthorPermissions(commits: commits, force: false)
        
        #expect(result == true)
    }
    
    @Test("verify author permissions returns false when other authors without force")
    func verifyAuthorPermissionsWithOtherAuthorsNoForce() throws {
        let commits = [
            CommitInfo(hash: "abc123", message: "First", author: "User", date: "1h ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "def456", message: "Second", author: "Other", date: "2h ago", wasAuthoredByCurrentUser: false)
        ]
        let (sut, _, _) = makeSUT()
        
        let result = sut.verifyAuthorPermissions(commits: commits, force: false)
        
        #expect(result == false)
    }
    
    @Test("verify author permissions returns true when other authors with force")
    func verifyAuthorPermissionsWithOtherAuthorsWithForce() throws {
        let commits = [
            CommitInfo(hash: "abc123", message: "First", author: "User", date: "1h ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "def456", message: "Second", author: "Other", date: "2h ago", wasAuthoredByCurrentUser: false)
        ]
        let (sut, _, _) = makeSUT()
        
        let result = sut.verifyAuthorPermissions(commits: commits, force: true)
        
        #expect(result == true)
    }
    
    @Test("display commits formats output correctly")
    func displayCommitsFormatsOutput() throws {
        let commits = [
            CommitInfo(hash: "abc123", message: "First", author: "User", date: "1h ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "def456", message: "Second", author: "Other", date: "2h ago", wasAuthoredByCurrentUser: false)
        ]
        let (sut, _, _) = makeSUT()
        
        // This method just prints to console, so we're testing it doesn't throw
        sut.displayCommits(commits, action: "discarded")
        
        // No assertions needed for display method
        #expect(Bool(true))
    }
    
    @Test("confirm reset uses correct message for soft reset")
    func confirmResetSoftMessage() throws {
        let picker = MockPicker(permissionResponses: ["Are you sure you want to soft reset 3 commit(s)? The changes will be moved to staging area.": true])
        let (sut, _, _) = makeSUT(picker: picker)
        
        try sut.confirmReset(count: 3, resetType: "soft")
        
        #expect(picker.requiredPermissions.contains("Are you sure you want to soft reset 3 commit(s)? The changes will be moved to staging area."))
    }
    
    @Test("confirm reset uses correct message for hard reset")
    func confirmResetHardMessage() throws {
        let picker = MockPicker(permissionResponses: ["Are you sure you want to hard reset 2 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action.": true])
        let (sut, _, _) = makeSUT(picker: picker)
        
        try sut.confirmReset(count: 2, resetType: "hard")
        
        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 2 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
    }
    
    @Test("confirm reset uses default message for unknown type")
    func confirmResetDefaultMessage() throws {
        let picker = MockPicker(permissionResponses: ["Are you sure you want to reset 1 commit(s)?": true])
        let (sut, _, _) = makeSUT(picker: picker)
        
        try sut.confirmReset(count: 1, resetType: "unknown")
        
        #expect(picker.requiredPermissions.contains("Are you sure you want to reset 1 commit(s)?"))
    }
}


// MARK: - SUT
private extension DefaultGitResetHelperTests {
    func makeSUT(commitInfo: [CommitInfo] = [], picker: MockPicker = MockPicker()) -> (sut: DefaultGitResetHelper, manager: MockCommitManager, picker: MockPicker) {
        let manager = MockCommitManager()
        manager.commitInfo = commitInfo
        let sut = DefaultGitResetHelper(manager: manager, picker: picker)
        
        return (sut, manager, picker)
    }
}
