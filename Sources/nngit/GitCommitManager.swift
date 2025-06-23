//
//  GitCommitManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/22/25.
//

protocol GitCommitManager {
    func getCommitInfo(count: Int) throws -> [CommitInfo]
    func undoCommits(count: Int) throws
}
