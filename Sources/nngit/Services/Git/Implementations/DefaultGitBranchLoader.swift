//
//  DefaultGitBranchLoader.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Foundation
import GitShellKit

/// Default implementation of ``GitBranchLoader`` using ``GitShell``.
///
/// This class provides the core branch loading functionality for nngit, handling:
/// - Loading branch names from local, remote, or both locations
/// - Creating full ``GitBranch`` objects with merge status, creation dates, and sync status
/// - Determining branch synchronization status with remote counterparts
/// - Automatic fetching of remote changes to ensure accurate sync status
///
/// The implementation automatically fetches from origin when loading branches to ensure
/// sync status calculations are based on the latest remote state.
struct DefaultGitBranchLoader {
    private let shell: GitShell

    init(shell: GitShell) {
        self.shell = shell
    }
}


// MARK: - GitBranchLoader
extension DefaultGitBranchLoader: GitBranchLoader {
    /// Loads raw branch names from the specified location.
    ///
    /// This method executes the appropriate git command based on the location parameter
    /// and returns a cleaned list of branch names. The output is processed to:
    /// - Split lines and trim whitespace
    /// - Filter out symbolic references (those containing "->")
    ///
    /// - Parameter location: Where to load branches from (.local, .remote, or .both)
    /// - Returns: Array of cleaned branch names
    /// - Throws: ``GitShellError`` if git commands fail
    func loadBranchNames(from location: BranchLocation) throws -> [String] {
        let output: String

        switch location {
        case .local:
            output = try self.shell.runGitCommandWithOutput(.listLocalBranches, path: nil)
        case .remote:
            output = try self.shell.runGitCommandWithOutput(.listRemoteBranches, path: nil)
        case .both:
            output = try self.shell.runWithOutput("git branch -a")
        }

        return output
            .split(separator: "\n")
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .filter({ !$0.contains("->") })
    }

    /// Creates complete ``GitBranch`` objects with full metadata for the specified branch names.
    ///
    /// This is the primary method for loading branch data. It performs several operations:
    /// 1. Determines which branch names to process (provided names or all local branches)
    /// 2. Loads merged branch information to determine merge status
    /// 3. Automatically fetches from origin if a remote exists (ensures accurate sync status)
    /// 4. For each branch, collects:
    ///    - Current branch status (identified by "*" prefix)
    ///    - Merge status (whether merged into main branch)
    ///    - Creation date (using git log, may be nil if unavailable)
    ///    - Sync status (ahead/behind/in-sync with remote)
    ///
    /// The method handles both current branches (prefixed with "*") and regular branches,
    /// cleaning the names appropriately before processing.
    ///
    /// - Parameters:
    ///   - names: Optional array of specific branch names to load. If nil, loads all local branches.
    ///   - mainBranchName: The name of the main/default branch for merge status checks.
    /// - Returns: Array of ``GitBranch`` objects with complete metadata
    /// - Throws: ``GitShellError`` if git commands fail
    func loadBranches(for names: [String]?, mainBranchName: String) throws -> [GitBranch] {
        let branchNames: [String]
        if let names = names {
            branchNames = names
        } else {
            branchNames = try loadBranchNames(from: .local)
        }
        
        let mergedOutput = try self.shell.runGitCommandWithOutput(
            .listMergedBranches(branchName: mainBranchName),
            path: nil
        )
        let mergedBranches = Set(mergedOutput
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) })
        
        // Fetch latest remote changes to ensure accurate sync status
        // This is crucial for accurate ahead/behind calculations
        if try shell.remoteExists(path: nil) {
            try shell.runGitCommandWithOutput(.fetchOrigin, path: nil)
        }

        return branchNames.map { name in
            // Determine if this is the current branch (prefixed with "*")
            let isCurrentBranch = name.hasPrefix("*")
            let cleanBranchName = isCurrentBranch ? String(name.dropFirst(2)) : name
            let isMerged = mergedBranches.contains(cleanBranchName)

            // Attempt to get branch creation date using git log
            // This may fail for branches without history, so we use try? and default to nil
            var creationDate: Date?
            if let dateOutput = try? self.shell.runGitCommandWithOutput(
                   .getBranchCreationDate(branchName: cleanBranchName),
                   path: nil
               ) {
                creationDate = ISO8601DateFormatter().date(
                    from: dateOutput.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }

            // Get sync status with remote branch
            // Falls back to .undetermined if comparison fails (e.g., no remote branch)
            let syncStatus = (try? self.getSyncStatus(
                branchName: cleanBranchName,
                comparingBranch: nil
            )) ?? .undetermined

            return .init(
                name: cleanBranchName,
                isMerged: isMerged,
                isCurrentBranch: isCurrentBranch,
                creationDate: creationDate,
                syncStatus: syncStatus
            )
        }
    }

    /// Returns the synchronization status between a local branch and its remote counterpart.
    ///
    /// This method determines the relationship between a local branch and its remote tracking branch
    /// by using git's rev-list command to count commits that exist in one branch but not the other.
    ///
    /// The process:
    /// 1. First checks if a remote repository exists
    /// 2. Constructs the remote branch name (origin/branchName by default)
    /// 3. Uses `git rev-list --left-right --count` to get ahead/behind counts
    /// 4. Parses the tab-separated output to determine sync status
    ///
    /// Possible return values:
    /// - `.noRemoteBranch`: No remote repository configured
    /// - `.nsync`: Local and remote are identical (0 ahead, 0 behind)
    /// - `.ahead`: Local has commits not in remote (>0 ahead, 0 behind)
    /// - `.behind`: Remote has commits not in local (0 ahead, >0 behind)  
    /// - `.diverged`: Both have unique commits (>0 ahead, >0 behind)
    /// - `.undetermined`: Cannot determine status (command failed or unexpected output)
    ///
    /// - Parameters:
    ///   - branchName: The local branch name to compare (should be clean, without "*" prefix).
    ///   - comparingBranch: Optional remote branch name to compare against. When
    ///     `nil`, the same branch name on `origin` is used (e.g., "origin/main").
    /// - Returns: ``BranchSyncStatus`` describing the synchronization state.
    /// - Throws: ``GitShellError`` if git commands fail (remote existence check or branch comparison).
    func getSyncStatus(branchName: String, comparingBranch: String? = nil) throws -> BranchSyncStatus {
        guard (try? self.shell.remoteExists(path: nil)) == true else {
            return .noRemoteBranch
        }
        
        // Construct remote branch reference (e.g., "origin/main" or "origin/feature-branch")  
        let remoteBranch = "origin/\(comparingBranch ?? branchName)"
        
        // Execute git rev-list command to get ahead/behind counts
        // Output format: "ahead_count\tbehind_count" (tab-separated)
        // If the remote branch doesn't exist, this command will fail
        let comparisonResult: String
        do {
            comparisonResult = try self.shell.runGitCommandWithOutput(.compareBranchAndRemote(local: branchName, remote: remoteBranch), path: nil)
        } catch {
            // If the command fails (likely because the remote branch doesn't exist),
            // return .noRemoteBranch status
            return .noRemoteBranch
        }
        
        let changes = comparisonResult.split(separator: "\t").map(String.init)
        
        // Ensure we got exactly two values (ahead and behind counts)
        guard changes.count == 2 else {
            return .undetermined
        }
        
        let ahead = changes[0]    // Number of commits local is ahead
        let behind = changes[1]   // Number of commits local is behind
        
        // Determine sync status based on ahead/behind counts
        if ahead == "0" && behind == "0" {
            return .nsync        // Perfectly in sync
        } else if ahead != "0" && behind == "0" {
            return .ahead        // Local has unpushed commits
        } else if ahead == "0" && behind != "0" {
            return .behind       // Remote has commits local doesn't have
        } else {
            return .diverged     // Both have unique commits (merge conflict scenario)
        }
    }
}
