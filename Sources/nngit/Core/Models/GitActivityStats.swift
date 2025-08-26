//
//  GitActivityStats.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Foundation

/// Represents Git activity statistics for a specified time period.
struct GitActivityStats {
    /// Number of commits made in the time period
    let commits: Int
    
    /// Number of unique files changed
    let filesChanged: Int
    
    /// Total lines added across all commits
    let linesAdded: Int
    
    /// Total lines deleted across all commits
    let linesDeleted: Int
    
    /// Optional daily breakdown of activity
    let dailyBreakdown: [DailyActivity]?
    
    /// Computed property for total lines modified (added + deleted)
    var totalLinesModified: Int {
        linesAdded + linesDeleted
    }
    
    /// Creates a new GitActivityStats instance
    init(commits: Int = 0, filesChanged: Int = 0, linesAdded: Int = 0, linesDeleted: Int = 0, dailyBreakdown: [DailyActivity]? = nil) {
        self.commits = commits
        self.filesChanged = filesChanged
        self.linesAdded = linesAdded
        self.linesDeleted = linesDeleted
        self.dailyBreakdown = dailyBreakdown
    }
}

/// Represents Git activity statistics for a single day
struct DailyActivity {
    /// The date for this activity
    let date: String
    
    /// Number of commits on this day
    let commits: Int
    
    /// Number of files changed on this day
    let filesChanged: Int
    
    /// Lines added on this day
    let linesAdded: Int
    
    /// Lines deleted on this day
    let linesDeleted: Int
    
    /// Computed property for total lines modified on this day
    var totalLinesModified: Int {
        linesAdded + linesDeleted
    }
}


// MARK: - Display Formatting
extension GitActivityStats {
    /// Formats the statistics for console display
    /// - Parameters:
    ///   - days: Number of days the statistics represent
    ///   - verbose: Whether to include daily breakdown
    /// - Returns: Formatted string ready for console output
    func formatForDisplay(days: Int, verbose: Bool = false) -> String {
        let dayText = days == 1 ? "Day" : "Days"
        let commitText = commits == 1 ? "Commit" : "Commits"
        let fileText = filesChanged == 1 ? "File Changed" : "Files Changed"
        
        var output = """
        Git Activity Report (Last \(days) \(dayText)):
        =====================================
        \(commitText): \(commits)
        \(fileText): \(filesChanged)
        Lines Added: \(linesAdded)
        Lines Deleted: \(linesDeleted)
        Total Lines Modified: \(totalLinesModified)
        """
        
        if verbose, let breakdown = dailyBreakdown, !breakdown.isEmpty {
            output += "\n\nDaily Breakdown:"
            output += "\n" + String(repeating: "-", count: 40)
            
            for daily in breakdown {
                let dayCommitText = daily.commits == 1 ? "commit" : "commits"
                let dayFileText = daily.filesChanged == 1 ? "file" : "files"
                
                output += "\n\(daily.date): \(daily.commits) \(dayCommitText), \(daily.filesChanged) \(dayFileText), +\(daily.linesAdded)/-\(daily.linesDeleted) lines"
            }
        }
        
        return output
    }
}