//
//  SoftReset.swift
//  nngit
//
//  Created by Nikolai Nobadi on 7/9/25.
//

import ArgumentParser

extension Nngit.Undo {
    /// Command that soft resets one or more commits from the current branch.
    struct Soft: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Runs 'git reset --soft HEAD~N', moving commits back to staging area while preserving changes. Use --select to choose from recent commits."
        )
        
        @Argument(help: "The number of commits to soft reset. (default is 1)")
        var number: Int = 1

        @Flag(name: .long, help: "Force soft resetting commits even if they were authored by others.")
        var force: Bool = false

        @Flag(name: .shortAndLong, help: "Select a commit from the last 7 commits to soft reset to.")
        var select: Bool = false
        
        /// Executes the command using the shared context components.
        func run() throws {
            let helper = Nngit.makeResetHelper()
            let manager = Nngit.makeCommitManager()
            
            let resetCount: Int
            let commitInfo: [CommitInfo]
            
            if select {
                guard let result = try helper.selectCommitForReset() else { return }
                (resetCount, commitInfo) = (result.count, result.commits)
                helper.displayCommits(commitInfo, action: "moved back to staging area")
            } else {
                do {
                    commitInfo = try helper.prepareReset(count: number)
                    resetCount = number
                    helper.displayCommits(commitInfo, action: "moved back to staging area")
                } catch {
                    print(error)
                    return
                }
            }
            
            if !helper.verifyAuthorPermissions(commits: commitInfo, force: force) {
                return
            }
            
            try helper.confirmReset(count: resetCount, resetType: "soft")
            
            try manager.softResetCommits(count: resetCount)
            print("✅ Soft reset \(resetCount) commit(s). Changes are now staged.")
        }
    }
}
