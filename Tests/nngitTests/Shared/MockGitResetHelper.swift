//
//  MockGitResetHelper.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

@testable import nngit
import GitShellKit

final class MockGitResetHelper: GitResetHelper {
    private(set) var selectCommitForResetResult: (count: Int, commits: [CommitInfo])?
    
    private(set) var prepareResetResult: [CommitInfo] = []
    private(set) var prepareResetCount: Int?
    
    private(set) var verifyAuthorPermissionsResult = true
    private(set) var verifiedCommits: [CommitInfo]?
    private(set) var verifiedWithForce: Bool?
    
    private(set) var displayedCommits: [CommitInfo]?
    private(set) var displayedAction: String?
    
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
        return selectCommitForResetResult
    }
    
    func prepareReset(count: Int) throws -> [CommitInfo] {
        prepareResetCount = count
        
        if count <= 0 {
            throw GitResetError.invalidCount
        }
        
        return prepareResetResult
    }
    
    func verifyAuthorPermissions(commits: [CommitInfo], force: Bool) -> Bool {
        verifiedCommits = commits
        verifiedWithForce = force
        return verifyAuthorPermissionsResult
    }
    
    func displayCommits(_ commits: [CommitInfo], action: String) {
        displayedCommits = commits
        displayedAction = action
    }
    
    func confirmReset(count: Int, resetType: String) throws {
        confirmResetCount = count
        confirmResetType = resetType
    }
}
