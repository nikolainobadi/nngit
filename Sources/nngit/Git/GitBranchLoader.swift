//
//  GitBranchLoader.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
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


// MARK: - Load
extension DefaultGitBranchLoader: GitBranchLoader {
    /// Returns branch models enriched with merge and sync information.
    ///
    /// - Parameters:
    ///   - location: The source of branches to load. Defaults to ``BranchLocation.local``.
    ///   - shell: Shell instance used to execute git commands.
    /// - Returns: Array of ``GitBranch`` representing the repository state.
    func loadBranches(
        from location: BranchLocation = .local,
        shell: GitShell,
        mainBranchName: String,
        loadMergeStatus: Bool = true,
        loadCreationDate: Bool = true,
        loadSyncStatus: Bool = true
    ) throws -> [GitBranch] {
        try shell.verifyLocalGitExists()
        let names = try loadBranchNames(from: location, shell: shell)
        return try loadBranches(
            for: names,
            shell: shell,
            mainBranchName: mainBranchName,
            loadMergeStatus: loadMergeStatus,
            loadCreationDate: loadCreationDate,
            loadSyncStatus: loadSyncStatus
        )
    }

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

    func loadBranches(
        for names: [String],
        shell: GitShell,
        mainBranchName: String,
        loadMergeStatus: Bool = true,
        loadCreationDate: Bool = true,
        loadSyncStatus: Bool = true
    ) throws -> [GitBranch] {
        let mergedBranches: Set<String>
        if loadMergeStatus {
            let mergedOutput = try shell.runGitCommandWithOutput(
                .listMergedBranches(branchName: mainBranchName),
                path: nil
            )
            mergedBranches = Set(mergedOutput
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) })
        } else {
            mergedBranches = []
        }

        let remoteExists = loadSyncStatus ? ((try? shell.remoteExists(path: nil)) ?? false) : false

        return names.map { name in
            let isCurrentBranch = name.hasPrefix("*")
            let cleanBranchName = isCurrentBranch ? String(name.dropFirst(2)) : name
            let isMerged = loadMergeStatus ? mergedBranches.contains(cleanBranchName) : false

            var creationDate: Date?
            if loadCreationDate,
               let dateOutput = try? shell.runGitCommandWithOutput(
                   .getBranchCreationDate(branchName: cleanBranchName),
                   path: nil
               ) {
                creationDate = ISO8601DateFormatter().date(
                    from: dateOutput.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }

            let syncStatus: BranchSyncStatus
            if loadSyncStatus {
                syncStatus = (try? getSyncStatus(
                    branchName: name,
                    shell: shell,
                    remoteExists: remoteExists
                )) ?? .undetermined
            } else {
                syncStatus = .undetermined
            }

            return .init(
                name: cleanBranchName,
                isMerged: isMerged,
                isCurrentBranch: isCurrentBranch,
                creationDate: creationDate,
                syncStatus: syncStatus
            )
        }
    }
}


// MARK: - Private Methods
private extension DefaultGitBranchLoader {
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


// MARK: - Dependencies
/// Protocol for loading Git branches, abstracted for testing.
protocol GitBranchLoader {
    /// Loads branches from the given location.
    func loadBranches(
        from location: BranchLocation,
        shell: GitShell,
        mainBranchName: String,
        loadMergeStatus: Bool,
        loadCreationDate: Bool,
        loadSyncStatus: Bool
    ) throws -> [GitBranch]
    /// Returns just the raw branch names from the given location.
    func loadBranchNames(from location: BranchLocation, shell: GitShell) throws -> [String]
    /// Creates ``GitBranch`` models using the provided branch names.
    func loadBranches(
        for names: [String],
        shell: GitShell,
        mainBranchName: String,
        loadMergeStatus: Bool,
        loadCreationDate: Bool,
        loadSyncStatus: Bool
    ) throws -> [GitBranch]
}


// MARK: - Filtering Helpers
extension GitBranchLoader {
    /// Filters raw branch names by author. Only names whose most recent commit
    /// was authored by one of the provided names/emails are returned. The
    /// current git user's name/email are automatically included when present.
    func filterBranchNamesByAuthor(_ names: [String], shell: GitShell, includeAuthor: [String]) -> [String] {
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

        guard !allowedAuthors.isEmpty else { return names }

        return names.filter { name in
            let cleanName = name.hasPrefix("*") ? String(name.dropFirst(2)) : name
            if let output = try? shell.runWithOutput("git log -1 --pretty=format:'%an,%ae' \(cleanName)") {
                let parts = output.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ",")
                guard parts.count == 2 else { return false }
                let authorName = String(parts[0])
                let authorEmail = String(parts[1])
                return allowedAuthors.contains(authorName) || allowedAuthors.contains(authorEmail)
            }
            return false
        }
    }

    /// Filters branch names by a search term, matching case-insensitively on the name.
    func filterBranchNamesBySearch(_ names: [String], search: String?) -> [String] {
        guard let search,
              !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return names }

        return names.filter { $0.lowercased().contains(search.lowercased()) }
    }

    /// Filters branches by author using the provided shell and includeAuthor list.
    /// The current git user's name/email are automatically included when present.
    func filterBranchesByAuthor(_ branches: [GitBranch], shell: GitShell, includeAuthor: [String]) -> [GitBranch] {
        let names = branches.map { $0.name }
        let filteredNames = filterBranchNamesByAuthor(names, shell: shell, includeAuthor: includeAuthor)
        return branches.filter { filteredNames.contains($0.name) }
    }

    /// Filters branches by a search term, matching case-insensitively on the name.
    func filterBranchesBySearch(_ branches: [GitBranch], search: String?) -> [GitBranch] {
        let names = branches.map { $0.name }
        let filteredNames = filterBranchNamesBySearch(names, search: search)
        return branches.filter { filteredNames.contains($0.name) }
    }
}
