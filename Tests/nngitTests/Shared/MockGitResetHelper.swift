//
//  MockGitResetHelper.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

@testable import nngit
import GitShellKit

class MockGitResetHelper: GitResetHelper {
    private(set) var selectCommitForResetResult: (count: Int, commits: [CommitInfo])?
    private(set) var selectCommitForResetCalled = false
    
    private(set) var prepareResetResult: [CommitInfo] = []
    private(set) var prepareResetCalled = false
    private(set) var prepareResetCount: Int?
    
    private(set) var verifyAuthorPermissionsResult = true
    private(set) var verifyAuthorPermissionsCalled = false
    private(set) var verifyAuthorPermissionsCommits: [CommitInfo]?
    private(set) var verifyAuthorPermissionsForce: Bool?
    
    private(set) var displayCommitsCalled = false
    private(set) var displayCommitsCommits: [CommitInfo]?
    private(set) var displayCommitsAction: String?
    
    private(set) var confirmResetCalled = false
    private(set) var confirmResetCount: Int?
    private(set) var confirmResetType: String?
    
    init(selectCommitForResetResult: (count: Int, commits: [CommitInfo])? = nil,
         prepareResetResult: [CommitInfo] = [],
         verifyAuthorPermissionsResult: Bool = true) {
        self.selectCommitForResetResult = selectCommitForResetResult
        self.prepareResetResult = prepareResetResult
        self.verifyAuthorPermissionsResult = verifyAuthorPermissionsResult
    }
    
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
