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

        @Option(name: .shortAndLong, help: "Name of the branch prefix to use.")
        var branchPrefixName: String?

        @Option(name: .shortAndLong, help: "Issue number to include in the branch name.")
        var issueNumber: String?

        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let loader = GitConfigLoader()
            try shell.verifyLocalGitExists()
            let config = try loader.loadConfig(picker: picker)
            try rebaseIfNecessary(shell: shell, config: config, picker: picker)
            let branchName = try name ?? picker.getRequiredInput("Enter the name of your new branch.")

            var selectedPrefix: BranchPrefix?

            if !config.branchPrefixList.isEmpty {
                if let providedName = branchPrefixName {
                    if let match = config.branchPrefixList.first(where: { $0.name == providedName }) {
                        selectedPrefix = match
                    } else {
                        print("No branch prefix named '\(providedName)'.")
                        selectedPrefix = try picker.requiredSingleSelection("Select a branch prefix", items: config.branchPrefixList)
                    }
                } else {
                    selectedPrefix = try picker.requiredSingleSelection("Select a branch prefix", items: config.branchPrefixList)
                }
            }

            var issue = issueNumber

            if let prefix = selectedPrefix, prefix.requiresIssueNumber {
                if issue == nil || issue?.isEmpty == true {
                    issue = try picker.getRequiredInput("Enter an issue number")
                }
            }

            let fullBranchName = BranchNameGenerator.generate(
                name: branchName,
                branchPrefix: selectedPrefix?.name,
                issueNumber: issue
            )

            try shell.runGitCommandWithOutput(.newBranch(branchName: fullBranchName), path: nil)
            print("✅ Created and switched to branch: \(fullBranchName)")
        }
    }
}

extension Nngit.NewBranch {
    func rebaseIfNecessary(shell: GitShell, config: GitConfig, picker: Picker) throws {
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
}
