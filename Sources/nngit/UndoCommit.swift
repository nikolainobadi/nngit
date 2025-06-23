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
        
        func run() throws {
            let picker = Nngit.makePicker()
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
                try picker.requiredPermission("\nSome of the commits were created by other authors. Are you sure you want to discard them?")
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
