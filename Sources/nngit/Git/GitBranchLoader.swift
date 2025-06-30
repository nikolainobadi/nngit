//
//  GitBranchLoader.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import Foundation
import GitShellKit

/// Protocol for loading Git branches, abstracted for testing.
protocol GitBranchLoaderProtocol {
    /// Loads branches from the given location.
    func loadBranches(from location: BranchLocation, shell: GitShell) throws -> [GitBranch]
}

// MARK: - Filtering Helpers
extension GitBranchLoaderProtocol {
    /// Filters branches by author using the provided shell and includeAuthor list.
    /// The current git user's name/email are automatically included when present.
    func filterBranchesByAuthor(_ branches: [GitBranch], shell: GitShell, includeAuthor: [String]) -> [GitBranch] {
        var allowedAuthors = Set(includeAuthor)

        let userName = (try? shell.runWithOutput("git config user.name").trimmingCharacters(in: .whitespacesAndNewlines))
            .flatMap { $0.isEmpty ? nil : $0 }
            ?? (try? shell.runWithOutput("git config --global user.name").trimmingCharacters(in: .whitespacesAndNewlines))
            .flatMap { $0.isEmpty ? nil : $0 }

        let userEmail = (try? shell.runWithOutput("git config user.email").trimmingCharacters(in: .whitespacesAndNewlines))
            .flatMap { $0.isEmpty ? nil : $0 }
            ?? (try? shell.runWithOutput("git config --global user.email").trimmingCharacters(in: .whitespacesAndNewlines))
            .flatMap { $0.isEmpty ? nil : $0 }

        if let userName { allowedAuthors.insert(userName) }
        if let userEmail { allowedAuthors.insert(userEmail) }

        guard !allowedAuthors.isEmpty else { return branches }

        return branches.filter { branch in
            if let output = try? shell.runWithOutput("git log -1 --pretty=format:'%an,%ae' \(branch.name)") {
                let parts = output.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ",")
                guard parts.count == 2 else { return false }
                let authorName = String(parts[0])
                let authorEmail = String(parts[1])
                return allowedAuthors.contains(authorName) || allowedAuthors.contains(authorEmail)
            }
            return false
        }
    }

    /// Filters branches by a search term, matching case-insensitively on the name.
    func filterBranchesBySearch(_ branches: [GitBranch], search: String?) -> [GitBranch] {
        guard let search,
              !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return branches }

        return branches.filter { $0.name.lowercased().contains(search.lowercased()) }
    }
}

/// Default implementation of ``GitBranchLoaderProtocol`` using ``GitShell``.
struct GitBranchLoader: GitBranchLoaderProtocol {
    private let shell: GitShell

    init(shell: GitShell) {
        self.shell = shell
    }
}


// MARK: - Load
extension GitBranchLoader {
    /// Returns branch models enriched with merge and sync information.
    ///
    /// - Parameters:
    ///   - location: The source of branches to load. Defaults to ``BranchLocation.local``.
    ///   - shell: Shell instance used to execute git commands.
    /// - Returns: Array of ``GitBranch`` representing the repository state.
    func loadBranches(from location: BranchLocation = .local, shell: GitShell) throws -> [GitBranch] {
        try shell.verifyLocalGitExists()
        let branchNames = try loadBranchNames(from: location, shell: shell)
        let mergedOutput = try shell.runGitCommandWithOutput(.listMergedBranches, path: nil)
        let mergedBranches = Set(mergedOutput.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) })
        let remoteExists = (try? shell.remoteExists(path: nil)) ?? false

        return branchNames.map { name in
            let isCurrentBranch = name.hasPrefix("*")
            let cleanBranchName = isCurrentBranch ? String(name.dropFirst(2)) : name
            let isMerged = mergedBranches.contains(cleanBranchName)
            var creationDate: Date?

            if let dateOutput = try? shell.runGitCommandWithOutput(.getBranchCreationDate(branchName: cleanBranchName), path: nil) {
                creationDate = ISO8601DateFormatter().date(from: dateOutput.trimmingCharacters(in: .whitespacesAndNewlines))
            }

            let syncStatus = try? getSyncStatus(branchName: name, shell: shell, remoteExists: remoteExists)

            return .init(name: cleanBranchName, isMerged: isMerged, isCurrentBranch: isCurrentBranch, creationDate: creationDate, syncStatus: syncStatus ?? .undetermined)
        }
    }
}


// MARK: - Private Methods
private extension GitBranchLoader {
    /// Loads raw branch name strings from git.
    ///
    /// - Parameters:
    ///   - location: Where to list branches from.
    ///   - shell: Shell used to execute git commands.
    /// - Returns: Array of branch names exactly as returned by git.
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
    
    /// Returns the synchronization status between a local branch and its remote counterpart.
    ///
    /// - Parameters:
    ///   - branchName: The local branch name to compare.
    ///   - comparingBranch: Optional remote branch name to compare against. When
    ///     `nil`, the same branch name on `origin` is used.
    ///   - shell: Shell used to execute git commands.
    /// - Returns: ``BranchSyncStatus`` describing whether the branch is ahead,
    ///   behind, or in sync with the remote.
    func getSyncStatus(
        branchName: String,
        comparingBranch: String? = nil,
        shell: GitShell,
        remoteExists: Bool = true
    ) throws -> BranchSyncStatus {
        if !remoteExists {
            return .noRemoteBranch
        }

        guard try shell.remoteExists(path: nil) else {
            return .noRemoteBranch
        }
        
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
