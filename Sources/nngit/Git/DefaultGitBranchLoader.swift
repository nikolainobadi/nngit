//
//  DefaultGitBranchLoader.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Foundation
import GitShellKit

/// Default implementation of ``GitBranchLoader`` using ``GitShell``.
struct DefaultGitBranchLoader {
    private let shell: GitShell

    init(shell: GitShell) {
        self.shell = shell
    }
}


// MARK: - GitBranchLoader
extension DefaultGitBranchLoader: GitBranchLoader {
    func loadBranchNames(from location: BranchLocation, shell: GitShell) throws -> [String] {
        let output: String

        switch location {
        case .local:
            output = try shell.runGitCommandWithOutput(.listLocalBranches, path: nil)
        case .remote:
            output = try shell.runGitCommandWithOutput(.listRemoteBranches, path: nil)
        case .both:
            output = try shell.runWithOutput("git branch -a")
        }

        return output
            .split(separator: "\n")
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .filter({ !$0.contains("->") })
    }

    func loadBranches(for names: [String], shell: GitShell, mainBranchName: String) throws -> [GitBranch] {
        let mergedOutput = try shell.runGitCommandWithOutput(
            .listMergedBranches(branchName: mainBranchName),
            path: nil
        )
        let mergedBranches = Set(mergedOutput
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) })

        let remoteExists = (try? shell.remoteExists(path: nil)) ?? false

        return names.map { name in
            let isCurrentBranch = name.hasPrefix("*")
            let cleanBranchName = isCurrentBranch ? String(name.dropFirst(2)) : name
            let isMerged = mergedBranches.contains(cleanBranchName)

            var creationDate: Date?
            if let dateOutput = try? shell.runGitCommandWithOutput(
                   .getBranchCreationDate(branchName: cleanBranchName),
                   path: nil
               ) {
                creationDate = ISO8601DateFormatter().date(
                    from: dateOutput.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }

            let syncStatus = (try? self.getSyncStatus(
                branchName: name,
                comparingBranch: nil,
                shell: shell,
                remoteExists: remoteExists
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
    /// - Parameters:
    ///   - branchName: The local branch name to compare.
    ///   - comparingBranch: Optional remote branch name to compare against. When
    ///     `nil`, the same branch name on `origin` is used.
    ///   - shell: Shell used to execute git commands.
    ///   - remoteExists: Whether a remote repository exists.
    /// - Returns: ``BranchSyncStatus`` describing whether the branch is ahead,
    ///   behind, or in sync with the remote.
    func getSyncStatus(branchName: String, comparingBranch: String? = nil, shell: GitShell, remoteExists: Bool = true) throws -> BranchSyncStatus {
        if !remoteExists {
            return .noRemoteBranch
        }

        // Skip additional remote existence checks when the caller already
        // determined whether a remote is configured.
        
        let remoteBranch = "origin/\(comparingBranch ?? branchName)"
        let comparisonResult = try shell.runGitCommandWithOutput(.compareBranchAndRemote(local: branchName, remote: remoteBranch), path: nil)
        let changes = comparisonResult.split(separator: "\t").map(String.init)
        
        guard changes.count == 2 else {
            return .undetermined
        }
        
        let ahead = changes[0]
        let behind = changes[1]
        
        if ahead == "0" && behind == "0" {
            return .nsync
        } else if ahead != "0" && behind == "0" {
            return .ahead
        } else if ahead == "0" && behind != "0" {
            return .behind
        } else {
            return .diverged
        }
    }
}
