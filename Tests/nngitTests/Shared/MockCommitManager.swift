//
//  MockCommitManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/21/25.
//

import GitShellKit
@testable import nngit

final class MockCommitManager: GitCommitManager {
    var commitInfo: [CommitInfo] = []
    var getCommitInfoCalled = false
    var getCommitInfoCount: Int?
    var undoCommitsCalled = false
    var undoCommitsCount: Int?
    var softResetCommitsCalled = false
    var softResetCommitsCount: Int?
    
    func getCommitInfo(count: Int) throws -> [CommitInfo] {
        getCommitInfoCalled = true
        getCommitInfoCount = count
        return Array(commitInfo.prefix(count))
    }
    
    func undoCommits(count: Int) throws {
        undoCommitsCalled = true
        undoCommitsCount = count
    }
    
    func softResetCommits(count: Int) throws {
        softResetCommitsCalled = true
        softResetCommitsCount = count
    }
}
