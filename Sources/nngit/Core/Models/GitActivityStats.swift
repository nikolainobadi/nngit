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
    
    /// Computed property for total lines modified (added + deleted)
    var totalLinesModified: Int {
        linesAdded + linesDeleted
    }
    
    /// Creates a new GitActivityStats instance
    init(commits: Int = 0, filesChanged: Int = 0, linesAdded: Int = 0, linesDeleted: Int = 0) {
        self.commits = commits
        self.filesChanged = filesChanged
        self.linesAdded = linesAdded
        self.linesDeleted = linesDeleted
    }
}


// MARK: - Display Formatting
extension GitActivityStats {
    /// Formats the statistics for console display
    /// - Parameter days: Number of days the statistics represent
    /// - Returns: Formatted string ready for console output
    func formatForDisplay(days: Int) -> String {
        let dayText = days == 1 ? "Day" : "Days"
        let commitText = commits == 1 ? "Commit" : "Commits"
        let fileText = filesChanged == 1 ? "File Changed" : "Files Changed"
        
        return """
        Git Activity Report (Last \(days) \(dayText)):
        =====================================
        \(commitText): \(commits)
        \(fileText): \(filesChanged)
        Lines Added: \(linesAdded)
        Lines Deleted: \(linesDeleted)
        Total Lines Modified: \(totalLinesModified)
        """
    }
}