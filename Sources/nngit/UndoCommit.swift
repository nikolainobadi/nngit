//
//  UndoCommit.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/22/25.
//

import ArgumentParser

extension Nngit {
    struct UndoCommit: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Runs 'git reset --hard HEAD, essentially discarding any number of commits."
        )
        
        @Argument(help: "The number of commits to discard. (default is 1)")
        var number: Int = 1

        @Flag(name: .long, help: "Force discarding commits even if they were authored by others.")
        var force: Bool = false
        
        func run() throws {
            let manager = Nngit.makeCommitManager()
            
            guard number > 0 else {
                print("number of commits to undo must be greater than 1")
                return
            }
            
            let commitInfo = try manager.getCommitInfo(count: number)
            print("The following commits will be discarded:")
            commitInfo.forEach {
                print($0.coloredMessage)
            }
            
            if commitInfo.contains(where: { !$0.wasAuthoredByCurrentUser }) {
                if force {
                    print("\nWarning: discarding commits authored by others.")
                } else {
                    print("\nSome of the commits were created by other authors. Re-run this command with --force to discard them.")
                    return
                }
            }
            
            print("should undo \(number) commits by running the command: git reset --hard HEAD~\(number)")
            try manager.undoCommits(count: number)
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
