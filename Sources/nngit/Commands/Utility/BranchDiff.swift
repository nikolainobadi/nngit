//
//  BranchDiff.swift
//  nngit
//
//  Created by Nikolai Nobadi on 7/9/25.
//

import Foundation
import GitShellKit
import SwiftPicker
import ArgumentParser

extension Nngit {
    /// Command used to show the cumulative diff of all changes from when the current branch was created.
    struct BranchDiff: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "branch-diff",
            abstract: "Shows the cumulative diff of all changes from when the current branch was created"
        )

        @Flag(name: .shortAndLong, help: "Copy diff to clipboard")
        var copy: Bool = false

        @Option(name: .customLong("base-branch"), help: "Base branch to diff against (defaults to configured default branch)")
        var baseBranch: String?

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let loader = Nngit.makeConfigLoader()
            let picker = Nngit.makePicker()
            
            try shell.verifyLocalGitExists()
            
            let config = try loader.loadConfig(picker: picker)
            let targetBaseBranch = baseBranch ?? config.branches.defaultBranch
            
            // Get current branch name
            let currentBranch = try shell.runWithOutput("git branch --show-current")
                .trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Check if we're on the base branch
            if currentBranch == targetBaseBranch {
                print("You are currently on the base branch '\(targetBaseBranch)'. No diff to show.")
                return
            }
            
            // Check if base branch exists
            let branchExists: Bool
            do {
                _ = try shell.runWithOutput("git show-ref --verify --quiet refs/heads/\(targetBaseBranch)")
                branchExists = true
            } catch {
                branchExists = false
            }
            
            if !branchExists {
                print("Base branch '\(targetBaseBranch)' does not exist.")
                return
            }
            
            // Get the diff from when the branch was created to now
            let diffOutput = try shell.runWithOutput("git diff \(targetBaseBranch)...HEAD")
            
            if diffOutput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                print("No differences found between '\(targetBaseBranch)' and current branch '\(currentBranch)'.")
                return
            }
            
            print("📊 Showing diff between '\(targetBaseBranch)' and '\(currentBranch)':")
            print(diffOutput)
        }
    }
}

/// Errors that can occur during branch diff operations.
enum BranchDiffError: Error, LocalizedError {
    case clipboardFailed
    
    var errorDescription: String? {
        switch self {
        case .clipboardFailed:
            return "Failed to copy diff to clipboard"
        }
    }
}
