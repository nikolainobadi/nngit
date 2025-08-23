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
        let currentUsername = try shell.runWithOutput("git config user.name").trimmingCharacters(in: .whitespacesAndNewlines)
        let currentEmail = try shell.runWithOutput("git config user.email").trimmingCharacters(in: .whitespacesAndNewlines)
        let command = "git log -n \(count) --pretty=format:'%h - %s (%an <%ae>, %ar)'"
        let output = try shell.runWithOutput(command)
        return output.split(separator: "\n").map { parseCommitInfo(String($0), currentUsername: currentUsername, currentEmail: currentEmail) }
    }

    /// Performs a hard reset to discard the specified number of commits.
    ///
    /// - Parameter count: Number of commits to remove from the current branch.
    func undoCommits(count: Int) throws {
        let _ = try shell.runWithOutput("git reset --hard HEAD~\(count)")
    }
    
    /// Performs a soft reset to move the specified number of commits back to staging area.
    ///
    /// - Parameter count: Number of commits to soft reset from the current branch.
    func softResetCommits(count: Int) throws {
        let _ = try shell.runWithOutput("git reset --soft HEAD~\(count)")
    }
}


// MARK: - Private
private extension DefaultGitCommitManager {
    /// Parses a single line of git log output into ``CommitInfo``.
    ///
    /// - Parameters:
    ///   - log: A line from the formatted git log output.
    ///   - currentUsername: Name of the current git user used to determine authorship.
    ///   - currentEmail: Email of the current git user used to determine authorship.
    func parseCommitInfo(_ log: String, currentUsername: String, currentEmail: String) -> CommitInfo {
        let parts = log.split(separator: "-", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        let hash = parts[0]
        let remaining = parts[1]
        let messageParts = remaining.split(separator: "(", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        let message = messageParts[0]
        let authorAndDate = messageParts[1].dropLast() // Remove closing parenthesis
        
        // Parse "Author Name <author@email.com>, relative date"
        let authorAndDateParts = authorAndDate.split(separator: ",", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
        let authorPart = authorAndDateParts[0] // "Author Name <author@email.com>"
        let date = authorAndDateParts[1]
        
        // Extract author name and email from "Author Name <author@email.com>"
        let (authorName, authorEmail) = parseAuthorAndEmail(authorPart)
        
        // Check if current user authored this commit by comparing both name and email (case-insensitive)
        let isCurrentUser = (!currentUsername.isEmpty && authorName.lowercased() == currentUsername.lowercased()) ||
                           (!currentEmail.isEmpty && authorEmail.lowercased() == currentEmail.lowercased())
        
        return .init(hash: hash, message: message, author: authorName, date: date, wasAuthoredByCurrentUser: isCurrentUser)
    }
    
    /// Parses author name and email from the format "Author Name <author@email.com>"
    ///
    /// - Parameter authorPart: The author portion from git log output
    /// - Returns: A tuple containing (authorName, authorEmail)
    func parseAuthorAndEmail(_ authorPart: String) -> (String, String) {
        if let emailStart = authorPart.lastIndex(of: "<"),
           let emailEnd = authorPart.lastIndex(of: ">") {
            let authorName = String(authorPart[..<emailStart]).trimmingCharacters(in: .whitespaces)
            let emailRange = authorPart.index(after: emailStart)..<emailEnd
            let authorEmail = String(authorPart[emailRange]).trimmingCharacters(in: .whitespaces)
            return (authorName, authorEmail)
        } else {
            // Fallback if email format is not found
            return (authorPart.trimmingCharacters(in: .whitespaces), "")
        }
    }
}
