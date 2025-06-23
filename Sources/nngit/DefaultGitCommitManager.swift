//
//  DefaultGitCommitManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/22/25.
//

import GitShellKit

struct DefaultGitCommitManager: GitCommitManager {
    let shell: GitShell
    
    init(shell: GitShell) {
        self.shell = shell
    }
}


// MARK: - Actions
extension DefaultGitCommitManager {
    func getCommitInfo(count: Int) throws -> [CommitInfo] {
        let currentUsername = try shell.runWithOutput("git config user.name")
        let command = "git log -n \(count) --pretty=format:'%h - %s (%an, %ar)'"
        let output = try shell.runWithOutput(command)
        return output.split(separator: "\n").map { parseCommitInfo(String($0), currentUsername: currentUsername) }
    }
    
    func undoCommits(count: Int) throws {
        let _ = try shell.runWithOutput("git reset --hard HEAD~\(count)")
    }
}


// MARK: - Private
private extension DefaultGitCommitManager {
    func parseCommitInfo(_ log: String, currentUsername: String) -> CommitInfo {
        let parts = log.split(separator: "-", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        let hash = parts[0]
        let remaining = parts[1]
        let messageParts = remaining.split(separator: "(", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        let message = messageParts[0]
        let authorAndDate = messageParts[1].dropLast()
        let authorAndDateParts = authorAndDate.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
        let author = authorAndDateParts[0]
        let date = authorAndDateParts[1]
        
        return .init(hash: hash, message: message, author: author, date: date, wasAuthoredByCurrentUser: author == currentUsername)
    }
}
