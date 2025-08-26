//
//  GitActivity.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import GitShellKit
import ArgumentParser

extension Nngit {
    struct GitActivity: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "activity",
            abstract: "Shows Git activity statistics for the specified number of days (defaults to today)."
        )

        @Option(name: .shortAndLong, help: "Number of days to analyze (default: 1 for today)")
        var days: Int = 1

        func run() throws {
            let shell = Nngit.makeShell()
            
            try shell.verifyLocalGitExists()
            
            guard days > 0 else {
                throw ValidationError("Days must be greater than 0")
            }
            
            let stats = try getGitActivityStats(shell: shell, days: days)
            print(stats.formatForDisplay(days: days))
        }
    }
}


// MARK: - Private Helpers
private extension Nngit.GitActivity {
    /// Retrieves Git activity statistics for the specified number of days
    func getGitActivityStats(shell: GitShell, days: Int) throws -> GitActivityStats {
        let sinceDate = days == 1 ? "midnight" : "\(days) days ago"
        let command = "git log --since=\"\(sinceDate)\" --pretty=format:\"%h %s\" --numstat"
        
        let output = try shell.runWithOutput(command)
        
        return parseGitLogOutput(output)
    }
    
    /// Parses git log output to extract activity statistics
    func parseGitLogOutput(_ output: String) -> GitActivityStats {
        let lines = output.split(separator: "\n").map(String.init)
        
        var commits = 0
        var filesChanged = 0
        var linesAdded = 0
        var linesDeleted = 0
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedLine.isEmpty {
                continue
            }
            
            // Check if this is a numstat line (format: "additions\tdeletions\tfilename")
            let components = trimmedLine.split(separator: "\t")
            if components.count == 3,
               let additions = Int(components[0]),
               let deletions = Int(components[1]) {
                // This is a file change line
                filesChanged += 1
                linesAdded += additions
                linesDeleted += deletions
            } else if !trimmedLine.isEmpty {
                // This is likely a commit line (starts with hash and commit message)
                // We count any non-empty, non-numstat line as a commit
                let firstChar = trimmedLine.first
                if let firstChar = firstChar, firstChar.isHexDigit {
                    commits += 1
                }
            }
        }
        
        return GitActivityStats(
            commits: commits,
            filesChanged: filesChanged,
            linesAdded: linesAdded,
            linesDeleted: linesDeleted
        )
    }
}


// MARK: - Character Extension
private extension Character {
    /// Checks if the character is a valid hexadecimal digit
    var isHexDigit: Bool {
        return self.isNumber || ("a"..."f").contains(self.lowercased().first!)
    }
}
