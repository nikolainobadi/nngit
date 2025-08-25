//
//  NewPush.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import GitShellKit
import SwiftPicker
import ArgumentParser

extension Nngit {
    struct NewPush: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Pushes current branch to remote repository and sets upstream tracking when no upstream branch exists."
        )

        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let configLoader = Nngit.makeConfigLoader()
            
            try shell.verifyLocalGitExists()
            try verifyRemoteGitExists(shell: shell)
            
            let currentBranch = try shell.runGitCommandWithOutput(.getCurrentBranchName, path: nil).trimmingCharacters(in: .whitespacesAndNewlines)
            
            try shell.runGitCommandWithOutput(.fetchOrigin, path: nil)
            try verifyNoRemoteBranchExists(shell: shell, branchName: currentBranch)
            try verifyNoPotentialMergeConflictsWithDefaultBranch(shell: shell, picker: picker, configLoader: configLoader, currentBranch: currentBranch)
            try shell.runGitCommandWithOutput(.pushNewRemote(branchName: currentBranch), path: nil)
            
            print("🚀 Successfully pushed '\(currentBranch)' to remote and set upstream tracking.")
        }
    }
}


// MARK: - Private Methods
private extension Nngit.NewPush {
    func verifyRemoteGitExists(shell: GitShell) throws {
        guard try shell.remoteExists(path: nil) else {
            throw NewPushError.noRemoteRepository
        }
    }
    
    func verifyNoRemoteBranchExists(shell: GitShell, branchName: String) throws {
        let remoteBranches = try shell.runGitCommandWithOutput(.listRemoteBranches, path: nil)
        let remoteBranchNames = remoteBranches
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .compactMap { line -> String? in
                if line.hasPrefix("origin/") {
                    return String(line.dropFirst(7)) // Remove "origin/" prefix
                }
                return nil
            }
        
        if remoteBranchNames.contains(branchName) {
            throw NewPushError.remoteBranchExists(branchName)
        }
    }
    
    func verifyNoPotentialMergeConflictsWithDefaultBranch(shell: GitShell, picker: CommandLinePicker, configLoader: GitConfigLoader, currentBranch: String) throws {
        let config = try configLoader.loadConfig()
        let defaultBranch = config.defaultBranch
        
        // Skip check if we're already on the default branch
        if currentBranch == defaultBranch {
            return
        }
        
        // Check if there are uncommitted changes
        let status = try shell.runGitCommandWithOutput(.getLocalChanges, path: nil)
        if !status.isEmpty {
            throw NewPushError.uncommittedChanges
        }
        
        // Check if current branch is up to date with default branch
        let comparison = try shell.runGitCommandWithOutput(.compareBranchAndRemote(local: currentBranch, remote: "origin/\(defaultBranch)"), path: nil)
        let components = comparison.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "\t")
        
        if components.count >= 2 {
            let behind = Int(components[1]) ?? 0
            if behind > 0 {
                try picker.requiredPermission("⚠️  Warning: Your branch is \(behind) commit(s) behind '\(defaultBranch)'. Consider rebasing before pushing to avoid potential conflicts. Continue with push anyway?")
            }
        }
    }
}
