//
//  HardResetManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Foundation

/// Manager utility for handling hard reset workflows and operations.
struct HardResetManager {
    private let helper: GitResetHelper
    private let commitManager: GitCommitManager
    
    init(helper: GitResetHelper, commitManager: GitCommitManager) {
        self.helper = helper
        self.commitManager = commitManager
    }
}


// MARK: - Hard Reset Operations
extension HardResetManager {
    func performHardReset(select: Bool, number: Int, force: Bool) throws {
        let (resetCount, commitInfo) = try prepareReset(select: select, number: number)
        
        guard let resetCount, let commitInfo else { return }
        
        helper.displayCommits(commitInfo, action: "discarded")
        
        if !helper.verifyAuthorPermissions(commits: commitInfo, force: force) {
            return
        }
        
        try helper.confirmReset(count: resetCount, resetType: "hard")
        
        try commitManager.undoCommits(count: resetCount)
    }
}


// MARK: - Private Methods
private extension HardResetManager {
    func prepareReset(select: Bool, number: Int) throws -> (count: Int?, commits: [CommitInfo]?) {
        if select {
            guard let result = try helper.selectCommitForReset() else {
                return (nil, nil)
            }
            return (result.count, result.commits)
        } else {
            if number < 1 {
                throw GitResetError.invalidCount
            }
            let commitInfo = try helper.prepareReset(count: number)
            return (number, commitInfo)
        }
    }
}