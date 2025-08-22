//
//  MockGitResetHelper.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

@testable import nngit
import GitShellKit

class MockGitResetHelper: GitResetHelper {
    var selectCommitForResetResult: (count: Int, commits: [CommitInfo])?
    var selectCommitForResetCalled = false
    
    var prepareResetResult: [CommitInfo] = []
    var prepareResetCalled = false
    var prepareResetCount: Int?
    
    var verifyAuthorPermissionsResult = true
    var verifyAuthorPermissionsCalled = false
    var verifyAuthorPermissionsCommits: [CommitInfo]?
    var verifyAuthorPermissionsForce: Bool?
    
    var displayCommitsCalled = false
    var displayCommitsCommits: [CommitInfo]?
    var displayCommitsAction: String?
    
    var confirmResetCalled = false
    var confirmResetCount: Int?
    var confirmResetType: String?
    
    func selectCommitForReset() throws -> (count: Int, commits: [CommitInfo])? {
        selectCommitForResetCalled = true
        return selectCommitForResetResult
    }
    
    func prepareReset(count: Int) throws -> [CommitInfo] {
        prepareResetCalled = true
        prepareResetCount = count
        
        if count <= 0 {
            throw GitResetError.invalidCount
        }
        
        return prepareResetResult
    }
    
    func verifyAuthorPermissions(commits: [CommitInfo], force: Bool) -> Bool {
        verifyAuthorPermissionsCalled = true
        verifyAuthorPermissionsCommits = commits
        verifyAuthorPermissionsForce = force
        return verifyAuthorPermissionsResult
    }
    
    func displayCommits(_ commits: [CommitInfo], action: String) {
        displayCommitsCalled = true
        displayCommitsCommits = commits
        displayCommitsAction = action
    }
    
    func confirmReset(count: Int, resetType: String) throws {
        confirmResetCalled = true
        confirmResetCount = count
        confirmResetType = resetType
    }
}