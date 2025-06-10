//
//  NewBranch.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import GitShellKit
import SwiftPicker
import ArgumentParser

extension Nngit {
    struct NewBranch: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Creates a new branch. If remote repository exists, will require merging any remote changes before creating new branch."
        )

        @Argument(help: "The name of the new branch.")
        var name: String?

        @Option(name: .shortAndLong, help: "The branch type (e.g., feature, bugfix).")
        var branchType: BranchType?

        @Option(name: .shortAndLong, help: "Optional issue number to include in the branch name.")
        var issueNumber: Int?

        func run() throws {
            let picker = SwiftPicker()
            let shell = GitShellAdapter()
            let loader = GitConfigLoader()
            try shell.verifyLocalGitExists()
            let config = try loader.loadConfig(picker: picker)
            try rebaseIfNecessary(shell: shell, config: config, picker: picker)
            let branchName = try createBranchName(name: name, branchType: branchType, issueNumber: issueNumber, config: config, picker: picker)
            
            try shell.runGitCommandWithOutput(.newBranch(branchName: branchName), path: nil)
            print("✅ Created and switched to branch: \(branchName)")
        }
    }
}

extension Nngit.NewBranch {
    func rebaseIfNecessary(shell: GitShell, config: GitConfig, picker: SwiftPicker) throws {
        guard try shell.remoteExists(path: nil) else {
            return
        }
        
        let currentBranch = try shell.runWithOutput(makeGitCommand(.getCurrentBranchName, path: nil)).trimmingCharacters(in: .whitespacesAndNewlines)
        let isOnMainBranch = currentBranch.lowercased() == config.defaultBranch.lowercased()
        
        guard isOnMainBranch && config.rebaseWhenBranchingFromDefaultBranch else {
            return
        }
        
        if picker.getPermission("Would you like to rebase before creating your new branch?") {
            try shell.runWithOutput("git pull --rebase")
        }
    }
    
    func createBranchName(name: String?, branchType: BranchType?, issueNumber: Int?, config: GitConfig, picker: SwiftPicker) throws -> String {
        var result = ""
        
        if let branchType {
            switch branchType {
            case .feature:
                result.append("feature/")
            case .bugfix:
                result.append("bugfix/")
            }
        }
        
        if let issueNumber {
            if let issueNumberPrefix = config.issueNumberPrefix {
                result.append("\(issueNumberPrefix)-")
            }
            result.append("\(issueNumber)/")
        }
        
        let branchName = try name ?? picker.getRequiredInput("Enter the name of your new branch.")
        let formattedBranchName = branchName
            .lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "[^a-z0-9\\-]", with: "", options: .regularExpression)
        
        result.append(formattedBranchName)
        
        return result
    }
}

extension Nngit.NewBranch {
    enum BranchType: String, CaseIterable, ExpressibleByArgument, CustomStringConvertible {
        case feature, bugfix

        var description: String {
            return rawValue
        }
    }
}
