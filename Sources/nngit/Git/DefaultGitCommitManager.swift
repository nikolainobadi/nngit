//
//  DefaultGitCommitManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/22/25.
//

import GitShellKit

/// Default implementation of ``GitCommitManager`` that communicates with git
/// via a ``GitShell`` instance.
struct DefaultGitCommitManager: GitCommitManager {
    /// Shell used to execute git commands.
    let shell: GitShell
    
    init(shell: GitShell) {
        self.shell = shell
    }
}


// MARK: - Actions
extension DefaultGitCommitManager {
    /// Retrieves metadata for the most recent commits.
    ///
    /// - Parameter count: Number of commits to fetch.
    /// - Returns: Array of ``CommitInfo`` objects describing each commit.
    func getCommitInfo(count: Int) throws -> [CommitInfo] {
        let currentUsername = try shell.runWithOutput("git config user.name")
        let command = "git log -n \(count) --pretty=format:'%h - %s (%an, %ar)'"
        let output = try shell.runWithOutput(command)
        return output.split(separator: "\n").map { parseCommitInfo(String($0), currentUsername: currentUsername) }
    }

    /// Performs a hard reset to discard the specified number of commits.
    ///
    /// - Parameter count: Number of commits to remove from the current branch.
    func undoCommits(count: Int) throws {
        let _ = try shell.runWithOutput("git reset --hard HEAD~\(count)")
    }
}


// MARK: - Private
private extension DefaultGitCommitManager {
    /// Parses a single line of git log output into ``CommitInfo``.
    ///
    /// - Parameters:
    ///   - log: A line from the formatted git log output.
    ///   - currentUsername: Name of the current git user used to determine
    ///     authorship.
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
