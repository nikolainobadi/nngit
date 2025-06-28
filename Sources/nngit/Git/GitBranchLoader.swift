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

/// Default implementation of GitBranchLoaderProtocol using GitShell.
struct GitBranchLoader: GitBranchLoaderProtocol {
    private let shell: GitShell

    init(shell: GitShell) {
        self.shell = shell
    }
}


// MARK: - Load
extension GitBranchLoader {
    func loadBranches(from location: BranchLocation = .local, shell: GitShell) throws -> [GitBranch] {
        try shell.verifyLocalGitExists()
        let branchNames = try loadBranchNames(from: location, shell: shell)
        let mergedOutput = try shell.runGitCommandWithOutput(.listMergedBranches, path: nil)
        let mergedBranches = Set(mergedOutput.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) })

        return branchNames.map { name in
            let isCurrentBranch = name.hasPrefix("*")
            let cleanBranchName = isCurrentBranch ? String(name.dropFirst(2)) : name
            let isMerged = mergedBranches.contains(cleanBranchName)
            var creationDate: Date?

            if let dateOutput = try? shell.runGitCommandWithOutput(.getBranchCreationDate(branchName: cleanBranchName), path: nil) {
                creationDate = ISO8601DateFormatter().date(from: dateOutput.trimmingCharacters(in: .whitespacesAndNewlines))
            }

            let syncStatus = try? getSyncStatus(branchName: name, shell: shell)

            return .init(name: cleanBranchName, isMerged: isMerged, isCurrentBranch: isCurrentBranch, creationDate: creationDate, syncStatus: syncStatus ?? .undetermined)
        }
    }
}


// MARK: - Private Methods
private extension GitBranchLoader {
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
    
    func getSyncStatus(branchName: String, comparingBranch: String? = nil, shell: GitShell) throws -> BranchSyncStatus {
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
