//
//  HardReset.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/22/25.
//

import ArgumentParser

extension Nngit.Undo {
    /// Command that discards one or more commits from the current branch.
    struct HardReset: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "hard",
            abstract: "Runs 'git reset --hard HEAD~N', completely discarding commits and their changes. Use --select to choose from recent commits."
        )
        
        @Argument(help: "The number of commits to discard. (default is 1)")
        var number: Int = 1

        @Flag(name: .long, help: "Force discarding commits even if they were authored by others.")
        var force: Bool = false

        @Flag(name: .shortAndLong, help: "Select a commit from the last 7 commits to hard reset to.")
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
                helper.displayCommits(commitInfo, action: "discarded")
            } else {
                do {
                    commitInfo = try helper.prepareReset(count: number)
                    resetCount = number
                    helper.displayCommits(commitInfo, action: "discarded")
                } catch {
                    print(error)
                    return
                }
            }
            
            if !helper.verifyAuthorPermissions(commits: commitInfo, force: force) {
                return
            }
            
            try helper.confirmReset(count: resetCount, resetType: "hard")
            
            try manager.undoCommits(count: resetCount)
        }
    }
}
