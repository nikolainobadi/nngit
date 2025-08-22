//
//  SoftResetManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import GitShellKit

/// Manager utility for handling soft reset workflows and operations.
struct SoftResetManager {
    private let helper: GitResetHelper
    private let commitManager: GitCommitManager
    
    init(helper: GitResetHelper, commitManager: GitCommitManager) {
        self.helper = helper
        self.commitManager = commitManager
    }
}


// MARK: - Soft Reset Operations
extension SoftResetManager {
    func performSoftReset(select: Bool, number: Int, force: Bool) throws {
        guard let result = try handleCommitSelection(select: select, number: number) else { return }
        let (resetCount, commitInfo) = (result.count, result.commits)
        
        displayCommitsForSoftReset(commitInfo)
        
        guard verifyPermissions(commits: commitInfo, force: force) else {
            return
        }
        
        try confirmSoftReset(count: resetCount)
        try performSoftReset(count: resetCount)
        
        print("✅ Soft reset \(resetCount) commit(s). Changes are now staged.")
    }
}


// MARK: - Private Methods
private extension SoftResetManager {
    func handleCommitSelection(select: Bool, number: Int) throws -> (count: Int, commits: [CommitInfo])? {
        if select {
            guard let result = try helper.selectCommitForReset() else { return nil }
            return (count: result.count, commits: result.commits)
        } else {
            let commitInfo = try helper.prepareReset(count: number)
            return (count: number, commits: commitInfo)
        }
    }
    
    func displayCommitsForSoftReset(_ commits: [CommitInfo]) {
        helper.displayCommits(commits, action: "moved back to staging area")
    }
    
    func verifyPermissions(commits: [CommitInfo], force: Bool) -> Bool {
        return helper.verifyAuthorPermissions(commits: commits, force: force)
    }
    
    func confirmSoftReset(count: Int) throws {
        try helper.confirmReset(count: count, resetType: "soft")
    }
    
    func performSoftReset(count: Int) throws {
        try commitManager.softResetCommits(count: count)
    }
}