//
//  GitResetHelper 2.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/21/25.
//

import GitShellKit

protocol GitResetHelper {
    func selectCommitForReset() throws -> (count: Int, commits: [CommitInfo])?
    func prepareReset(count: Int) throws -> [CommitInfo]
    func verifyAuthorPermissions(commits: [CommitInfo], force: Bool) -> Bool
    func displayCommits(_ commits: [CommitInfo], action: String)
    func confirmReset(count: Int, resetType: String) throws
}
