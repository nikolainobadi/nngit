//
//  GitBranchLoader.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import Foundation
import GitShellKit

struct GitBranchLoader {
    private let shell: GitShell
    
    init(shell: GitShell) {
        self.shell = shell
    }
}


// MARK: - Load
extension GitBranchLoader {
    func loadLocalBranches(shell: GitShell) throws -> [GitBranch] {
        try shell.verifyLocalGitExists()
        let branchNames = try loadBranchNames(shell: shell)
        let mergedOutput = try shell.runWithOutput(makeGitCommand(.listMergedBranches, path: nil))
        let mergedBranches = Set(mergedOutput.split(separator: "\n").map { $0.trimmingCharacters(in: .whitespaces) })
        
        return branchNames.map { name in
            let isCurrentBranch = name.hasPrefix("*")
            let cleanBranchName = isCurrentBranch ? String(name.dropFirst(2)) : name
            let isMerged = cleanBranchName == "main" ? true : mergedBranches.contains(cleanBranchName)
            var creationDate: Date?
            
            if let dateOutput = try? shell.runWithOutput(makeGitCommand(.getBranchCreationDate(cleanBranchName), path: nil)) {
                creationDate = ISO8601DateFormatter().date(from: dateOutput.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            
            let syncStatus = try? getSyncStatus(branchName: name, shell: shell)
            
            return .init(name: cleanBranchName, isMerged: isMerged, isCurrentBranch: isCurrentBranch, creationDate: creationDate, syncStatus: syncStatus ?? .undetermined)
        }
    }
}


// MARK: - Private Methods
private extension GitBranchLoader {
    func loadBranchNames(shell: GitShell) throws -> [String] {
        let output = try shell.runWithOutput(makeGitCommand(.listLocalBranches, path: nil))
        
        return output
            .split(separator: "\n")
            .map({ $0.trimmingCharacters(in: .whitespaces) })
    }
    
    func getSyncStatus(branchName: String, comparingBranch: String? = nil, shell: GitShell) throws -> BranchSyncStatus {
        guard try shell.remoteExists(path: nil) else {
            return .noRemoteBranch
        }
        
        let remoteBranch = "origin/\(comparingBranch ?? branchName)"
        let comparisonResult = try shell.runWithOutput(makeGitCommand(.compareBranchAndRemote(local: branchName, remote: remoteBranch), path: nil))
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
