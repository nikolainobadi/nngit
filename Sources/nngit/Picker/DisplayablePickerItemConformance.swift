//
//  DisplayablePickerItemConformance.swift
//  nngit
//
//  Created by Nikolai Nobadi on 12/15/25.
//

import GitShellKit
import SwiftPickerKit

// MARK: - RepoVisibility
extension RepoVisibility: @retroactive DisplayablePickerItem {
    public var displayName: String {
        return rawValue.capitalized
    }
}


// MARK: - GitFile
extension GitFile: DisplayablePickerItem {
    var displayName: String {
        return "\(nickname) (\(fileName))"
    }
}

// MARK: - FileState
extension FileStatus: DisplayablePickerItem {
    var displayName: String {
        let staged = stagedStatus?.rawValue ?? " "
        let unstaged = unstagedStatus?.rawValue ?? " "
        let statusIndicator = "\(staged)\(unstaged)"
        
        return "\(statusIndicator) \(path)"
    }
}

// MARK: - CommitInfo
extension CommitInfo: DisplayablePickerItem {
    var displayName: String {
        let authorName = wasAuthoredByCurrentUser ? author : "(\(author))"
        return "\(hash) | \(authorName), \(date) - \(message)"
    }
}


// MARK: - SyncOption
extension SyncOption: DisplayablePickerItem {
    var displayName: String {
        switch self {
        case .merge:
            return "Merge remote changes (git pull)"
        case .rebase:
            return "Rebase onto remote changes (git pull --rebase)"
        }
    }
}


// MARK: - GitBranch
extension GitBranch: DisplayablePickerItem {
    var displayName: String {
        let sync = syncStatus.rawValue
        
        // For the main branch, show only sync status since "merged" doesn't apply conceptually
        if !isMerged {
            // This includes both unmerged branches and the main branch (which is never marked as merged now)
            return "\(name) (\(sync))"
        } else {
            // Non-main branches that are actually merged
            return "\(name) (merged, \(sync))"
        }
    }
}
