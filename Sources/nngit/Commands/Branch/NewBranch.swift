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
    /// Command that creates a new branch using optional branch prefixes and issue numbers.
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

        @Flag(name: .long, help: "Select the branch prefix from a list of options.")
        var selectBranchPrefix: Bool = false

        @Flag(name: .long, help: "Create the branch with no prefix even if prefixes exist.")
        var noPrefix: Bool = false

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let loader = Nngit.makeConfigLoader()
            try shell.verifyLocalGitExists()
            let config = try loader.loadConfig(picker: picker)
            try rebaseIfNecessary(shell: shell, config: config, picker: picker)
            let branchName = try name ?? picker.getRequiredInput("Enter the name of your new branch.")

            var selectedPrefix: BranchPrefix?

            if !config.branchPrefixes.isEmpty && !noPrefix {
                if selectBranchPrefix {
                    selectedPrefix = try choosePrefix(from: config.branchPrefixes, picker: picker)
                } else if let providedName = branchPrefixName {
                    if let match = config.branchPrefixes.first(where: { $0.name == providedName }) {
                        selectedPrefix = match
                    } else if providedName.lowercased() == "no-prefix" {
                        selectedPrefix = nil
                    } else {
                        print("No branch prefix named '\(providedName)'.")
                        selectedPrefix = try choosePrefix(from: config.branchPrefixes, picker: picker)
                    }
                } else {
                    selectedPrefix = try choosePrefix(from: config.branchPrefixes, picker: picker)
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
            
            // Add the new branch to myBranches and save config
            let newBranch = MyBranch(name: fullBranchName, description: branchName)
            var updatedConfig = config
            updatedConfig.myBranches.append(newBranch)
            try loader.save(updatedConfig)
            
            print("✅ Created and switched to branch: \(fullBranchName)")
        }
    }
}

extension Nngit.NewBranch {
    /// Rebases the default branch if configured and the user approves.
    func rebaseIfNecessary(shell: GitShell, config: GitConfig, picker: Picker) throws {
        guard try shell.remoteExists(path: nil) else {
            return
        }
        
        let currentBranch = try shell.runWithOutput(makeGitCommand(.getCurrentBranchName, path: nil)).trimmingCharacters(in: .whitespacesAndNewlines)
        let isOnMainBranch = currentBranch.lowercased() == config.branches.defaultBranch.lowercased()
        
        guard isOnMainBranch && config.behaviors.rebaseWhenBranchingFromDefault else {
            return
        }
        
        if picker.getPermission("Would you like to rebase before creating your new branch?") {
            try shell.runWithOutput("git pull --rebase")
        }
    }

    /// Prompts the user to choose a branch prefix or none.
    func choosePrefix(from list: [BranchPrefix], picker: Picker) throws -> BranchPrefix? {
        let items = list.map { BranchPrefixChoice(prefix: $0) } + [BranchPrefixChoice(prefix: nil)]
        let selection = try picker.requiredSingleSelection("Select a branch prefix", items: items)
        return selection.prefix
    }
}

/// Wrapper allowing optional branch prefixes in picker selections.
private struct BranchPrefixChoice: DisplayablePickerItem {
    let prefix: BranchPrefix?
    var displayName: String { prefix?.displayName ?? "No Prefix" }
}
