//
//  FileStatus.swift
//  nngit
//
//  Created by Claude on 7/9/25.
//

import Foundation
import SwiftPicker

/// Represents the status of a file in the git working directory.
struct FileStatus: DisplayablePickerItem {
    let path: String
    let stagedStatus: FileChangeType?
    let unstagedStatus: FileChangeType?
    
    /// The display name shown in the picker interface.
    var displayName: String {
        let statusIndicator = buildStatusIndicator()
        return "\(statusIndicator) \(path)"
    }
    
    /// Whether this file has staged changes.
    var hasStaged: Bool {
        return stagedStatus != nil
    }
    
    /// Whether this file has unstaged changes.
    var hasUnstaged: Bool {
        return unstagedStatus != nil
    }
    
    /// Builds the status indicator string for display.
    private func buildStatusIndicator() -> String {
        let staged = stagedStatus?.rawValue ?? " "
        let unstaged = unstagedStatus?.rawValue ?? " "
        return "\(staged)\(unstaged)"
    }
}

/// Represents the type of change for a file.
enum FileChangeType: String {
    case modified = "M"
    case added = "A"
    case deleted = "D"
    case renamed = "R"
    case copied = "C"
    case untracked = "?"
    case ignored = "!"
    case updated = "U"
}

extension FileStatus {
    /// Creates FileStatus objects from git status --porcelain output.
    static func parseFromGitStatus(_ output: String) -> [FileStatus] {
        return output
            .split(separator: "\n")
            .compactMap { line in
                let lineString = String(line)
                guard lineString.count >= 3 else { return nil }
                
                let stagedChar = lineString[lineString.startIndex]
                let unstagedChar = lineString[lineString.index(lineString.startIndex, offsetBy: 1)]
                // Git status porcelain format: XY filename (space is at position 2)
                let pathStartIndex = lineString.index(lineString.startIndex, offsetBy: 2)
                let path = String(lineString[pathStartIndex...]).trimmingCharacters(in: .whitespaces)
                
                let stagedStatus = stagedChar == " " ? nil : FileChangeType(rawValue: String(stagedChar))
                let unstagedStatus = unstagedChar == " " ? nil : FileChangeType(rawValue: String(unstagedChar))
                
                return FileStatus(
                    path: path,
                    stagedStatus: stagedStatus,
                    unstagedStatus: unstagedStatus
                )
            }
    }
}