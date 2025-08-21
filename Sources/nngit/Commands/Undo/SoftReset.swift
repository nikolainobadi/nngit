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
            let manager = Nngit.makeCommitManager()
            let picker = Nngit.makePicker()
            
            let resetCount: Int
            let commitInfo: [CommitInfo]
            
            if select {
                // Selection mode: get last 7 commits and let user pick one
                commitInfo = try manager.getCommitInfo(count: 7)
                
                guard !commitInfo.isEmpty else {
                    print("No commits found to select from.")
                    return
                }
                
                let selectedCommit = try picker.requiredSingleSelection("Select a commit to soft reset to:", items: commitInfo)
                
                // Find the index of the selected commit (position determines reset count)
                guard let selectedIndex = commitInfo.firstIndex(where: { $0.hash == selectedCommit.hash }) else {
                    print("Error: Could not determine commit position.")
                    return
                }
                
                resetCount = selectedIndex + 1
                
                // Get the commits that will actually be reset
                let commitsToReset = Array(commitInfo.prefix(resetCount))
                print("The following \(resetCount) commit(s) will be moved back to staging area:")
                commitsToReset.forEach {
                    print($0.coloredMessage)
                }
            } else {
                // Original mode: use the number argument
                guard number > 0 else {
                    print("number of commits to soft reset must be greater than 0")
                    return
                }
                
                resetCount = number
                commitInfo = try manager.getCommitInfo(count: resetCount)
                print("The following commits will be moved back to staging area:")
                commitInfo.forEach {
                    print($0.coloredMessage)
                }
            }
            
            if commitInfo.contains(where: { !$0.wasAuthoredByCurrentUser }) {
                if force {
                    print("\nWarning: soft resetting commits authored by others.")
                } else {
                    print("\nSome of the commits were created by other authors. Re-run this command with --force to soft reset them.")
                    return
                }
            }
            
            try picker.requiredPermission("Are you sure you want to soft reset \(resetCount) commit(s)? The changes will be moved to staging area.")
            
            try manager.softResetCommits(count: resetCount)
            print("✅ Soft reset \(resetCount) commit(s). Changes are now staged.")
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
