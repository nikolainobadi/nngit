//
//  DefaultGitResetHelper.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import SwiftPicker
import GitShellKit

struct DefaultGitResetHelper {
    private let manager: GitCommitManager
    private let picker: CommandLinePicker
    
    init(manager: GitCommitManager, picker: CommandLinePicker) {
        self.manager = manager
        self.picker = picker
    }
}


// MARK: - GitResetHelper
extension DefaultGitResetHelper: GitResetHelper {
    func selectCommitForReset() throws -> (count: Int, commits: [CommitInfo])? {
        let commitInfo = try manager.getCommitInfo(count: 7)
        
        guard !commitInfo.isEmpty else {
            print("No commits found to select from.")
            return nil
        }
        
        let selectedCommit = try picker.requiredSingleSelection("Select a commit to reset to:", items: commitInfo)
        
        guard let selectedIndex = commitInfo.firstIndex(where: { $0.hash == selectedCommit.hash }) else {
            print("Error: Could not determine commit position.")
            return nil
        }
        
        let resetCount = selectedIndex + 1
        let commitsToReset = Array(commitInfo.prefix(resetCount))
        
        return (resetCount, commitsToReset)
    }
    
    func prepareReset(count: Int) throws -> [CommitInfo] {
        guard count > 0 else {
            throw GitResetError.invalidCount
        }
        
        return try manager.getCommitInfo(count: count)
    }
    
    func verifyAuthorPermissions(commits: [CommitInfo], force: Bool) -> Bool {
        if commits.contains(where: { !$0.wasAuthoredByCurrentUser }) {
            if force {
                print("\nWarning: resetting commits authored by others.")
            } else {
                print("\nSome of the commits were created by other authors. Re-run this command with --force to reset them.")
                return false
            }
        }
        return true
    }
    
    func displayCommits(_ commits: [CommitInfo], action: String) {
        print("The following \(commits.count) commit(s) will be \(action):")
        commits.forEach {
            print($0.coloredMessage)
        }
    }
    
    func confirmReset(count: Int, resetType: String) throws {
        let message: String
        switch resetType {
        case "soft":
            message = "Are you sure you want to soft reset \(count) commit(s)? The changes will be moved to staging area."
        case "hard":
            message = "Are you sure you want to hard reset \(count) commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."
        default:
            message = "Are you sure you want to reset \(count) commit(s)?"
        }
        
        try picker.requiredPermission(message)
    }
}
