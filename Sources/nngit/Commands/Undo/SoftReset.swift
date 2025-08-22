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
            let commitManager = Nngit.makeCommitManager()
            let manager = SoftResetManager(helper: helper, commitManager: commitManager)
            
            do {
                try manager.performSoftReset(select: select, number: number, force: force)
            } catch GitResetError.invalidCount {
                print("Number of commits to reset must be greater than 0")
            }
        }
    }
}
