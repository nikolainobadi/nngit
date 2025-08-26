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
        
        @Flag(name: .shortAndLong, help: "Show day-by-day breakdown (only allowed when days > 1)")
        var verbose: Bool = false

        func run() throws {
            let shell = Nngit.makeShell()
            
            try shell.verifyLocalGitExists()
            
            guard days > 0 else {
                throw ValidationError("Days must be greater than 0")
            }
            
            guard !verbose || days > 1 else {
                throw ValidationError("Verbose flag is only allowed when analyzing more than 1 day")
            }
            
            let stats = try getGitActivityStats(shell: shell, days: days, verbose: verbose)
            print(stats.formatForDisplay(days: days, verbose: verbose))
        }
    }
}


// MARK: - Private Helpers
private extension Nngit.GitActivity {
    /// Retrieves Git activity statistics for the specified number of days
    func getGitActivityStats(shell: GitShell, days: Int, verbose: Bool) throws -> GitActivityStats {
        let sinceDate = days == 1 ? "midnight" : "\(days) days ago"
        
        if verbose && days > 1 {
            // For verbose mode, we need to get data with dates to group by day
            let command = "git log --since=\"\(sinceDate)\" --pretty=format:\"%h %s %ad\" --date=short --numstat"
            let output = try shell.runWithOutput(command)
            return parseGitLogOutputWithDates(output)
        } else {
            // Regular mode without dates
            let command = "git log --since=\"\(sinceDate)\" --pretty=format:\"%h %s\" --numstat"
            let output = try shell.runWithOutput(command)
            return parseGitLogOutput(output)
        }
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
    
    /// Parses git log output with dates to extract activity statistics and daily breakdown
    func parseGitLogOutputWithDates(_ output: String) -> GitActivityStats {
        let lines = output.split(separator: "\n").map(String.init)
        
        var totalCommits = 0
        var totalFilesChanged = 0
        var totalLinesAdded = 0
        var totalLinesDeleted = 0
        var dailyStats: [String: (commits: Int, files: Int, added: Int, deleted: Int)] = [:]
        var currentDate: String?
        
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
                totalFilesChanged += 1
                totalLinesAdded += additions
                totalLinesDeleted += deletions
                
                // Update daily stats if we have a current date
                if let date = currentDate {
                    var daily = dailyStats[date] ?? (commits: 0, files: 0, added: 0, deleted: 0)
                    daily.files += 1
                    daily.added += additions
                    daily.deleted += deletions
                    dailyStats[date] = daily
                }
            } else if !trimmedLine.isEmpty {
                // This is likely a commit line with date (format: "hash message date")
                let firstChar = trimmedLine.first
                if let firstChar = firstChar, firstChar.isHexDigit {
                    totalCommits += 1
                    
                    // Extract the date from the end of the line
                    let parts = trimmedLine.split(separator: " ")
                    if let lastPart = parts.last, lastPart.count == 10 && lastPart.contains("-") {
                        currentDate = String(lastPart)
                        
                        // Update daily commit count
                        var daily = dailyStats[currentDate!] ?? (commits: 0, files: 0, added: 0, deleted: 0)
                        daily.commits += 1
                        dailyStats[currentDate!] = daily
                    }
                }
            }
        }
        
        // Convert daily stats to DailyActivity array, sorted by date
        let dailyBreakdown: [DailyActivity] = dailyStats.keys.sorted().compactMap { date in
            guard let stats = dailyStats[date] else { return nil }
            return DailyActivity(
                date: date,
                commits: stats.commits,
                filesChanged: stats.files,
                linesAdded: stats.added,
                linesDeleted: stats.deleted
            )
        }
        
        return GitActivityStats(
            commits: totalCommits,
            filesChanged: totalFilesChanged,
            linesAdded: totalLinesAdded,
            linesDeleted: totalLinesDeleted,
            dailyBreakdown: dailyBreakdown
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
