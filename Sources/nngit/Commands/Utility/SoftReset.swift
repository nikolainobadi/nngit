//
//  SoftReset.swift
//  nngit
//
//  Created by Claude on 7/9/25.
//

import ArgumentParser

extension Nngit {
    /// Command that soft resets one or more commits from the current branch.
    struct SoftReset: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Runs 'git reset --soft HEAD~N', moving commits back to staging area while preserving changes."
        )
        
        @Argument(help: "The number of commits to soft reset. (default is 1)")
        var number: Int = 1

        @Flag(name: .long, help: "Force soft resetting commits even if they were authored by others.")
        var force: Bool = false
        
        /// Executes the command using the shared context components.
        func run() throws {
            let manager = Nngit.makeCommitManager()
            let picker = Nngit.makePicker()
            
            guard number > 0 else {
                print("number of commits to soft reset must be greater than 0")
                return
            }
            
            let commitInfo = try manager.getCommitInfo(count: number)
            print("The following commits will be moved back to staging area:")
            commitInfo.forEach {
                print($0.coloredMessage)
            }
            
            if commitInfo.contains(where: { !$0.wasAuthoredByCurrentUser }) {
                if force {
                    print("\nWarning: soft resetting commits authored by others.")
                } else {
                    print("\nSome of the commits were created by other authors. Re-run this command with --force to soft reset them.")
                    return
                }
            }
            
            try picker.requiredPermission("Are you sure you want to soft reset \(number) commit(s)? The changes will be moved to staging area.")
            
            try manager.softResetCommits(count: number)
            print("✅ Soft reset \(number) commit(s). Changes are now staged.")
        }
    }
}


// MARK: - Extension Dependencies
private extension CommitInfo {
    var coloredMessage: String {
        let authorName = wasAuthoredByCurrentUser ? author.green : author.lightRed
        
        return "\(hash.yellow) | (\(authorName), \(date) - \(message.bold)"
    }
}