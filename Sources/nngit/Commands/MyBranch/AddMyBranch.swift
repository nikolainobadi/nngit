//
//  AddMyBranch.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/10/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit.MyBranches {
    /// Command that allows registering existing branches as tracked MyBranches.
    struct Add: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Register existing git branches to your tracked MyBranches list for easier switching and deletion."
        )

        @Argument(help: "Name of the branch to add to MyBranches")
        var branchName: String?

        @Option(name: .shortAndLong, help: "Description for the branch")
        var description: String?

        @Flag(name: .long, help: "Add all existing branches to MyBranches")
        var all: Bool = false

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let configLoader = Nngit.makeConfigLoader()
            
            try shell.verifyLocalGitExists()
            
            var config = try configLoader.loadConfig(picker: picker)
            let branchLoader = Nngit.makeBranchLoader()
            
            if all {
                try addAllBranches(shell: shell, config: &config, configLoader: configLoader, branchLoader: branchLoader)
            } else if let branchName = branchName {
                try addSpecificBranch(branchName: branchName, shell: shell, config: &config, configLoader: configLoader, branchLoader: branchLoader)
            } else {
                try selectAndAddBranch(shell: shell, picker: picker, config: &config, configLoader: configLoader, branchLoader: branchLoader)
            }
        }
        
        /// Adds all existing branches to MyBranches
        private func addAllBranches(shell: GitShell, config: inout GitConfig, configLoader: GitConfigLoader, branchLoader: GitBranchLoader) throws {
            let existingBranches = try branchLoader.loadBranchNames(from: .local, shell: shell)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "* ", with: "") }
            
            let currentMyBranchNames = Set(config.myBranches.map { $0.name })
            let newBranches = existingBranches.filter { !currentMyBranchNames.contains($0) }
            
            if newBranches.isEmpty {
                print("All existing branches are already tracked in MyBranches.")
                return
            }
            
            for branchName in newBranches {
                let myBranch = MyBranch(name: branchName, description: branchName)
                config.myBranches.append(myBranch)
            }
            
            try configLoader.save(config)
            print("✅ Added \(newBranches.count) branches to MyBranches: \(newBranches.joined(separator: ", "))")
        }
        
        /// Adds a specific branch to MyBranches
        private func addSpecificBranch(branchName: String, shell: GitShell, config: inout GitConfig, configLoader: GitConfigLoader, branchLoader: GitBranchLoader) throws {
            // Verify branch exists
            let existingBranches = try branchLoader.loadBranchNames(from: .local, shell: shell)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "* ", with: "") }
            
            guard existingBranches.contains(branchName) else {
                print("❌ Branch '\(branchName)' does not exist locally.")
                return
            }
            
            // Check if already tracked
            if config.myBranches.contains(where: { $0.name == branchName }) {
                print("Branch '\(branchName)' is already tracked in MyBranches.")
                return
            }
            
            let myBranch = MyBranch(name: branchName, description: description ?? branchName)
            config.myBranches.append(myBranch)
            try configLoader.save(config)
            
            print("✅ Added branch '\(branchName)' to MyBranches.")
        }
        
        /// Prompts user to select branches to add
        private func selectAndAddBranch(shell: GitShell, picker: CommandLinePicker, config: inout GitConfig, configLoader: GitConfigLoader, branchLoader: GitBranchLoader) throws {
            let existingBranches = try branchLoader.loadBranchNames(from: .local, shell: shell)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "* ", with: "") }
            
            let currentMyBranchNames = Set(config.myBranches.map { $0.name })
            let availableBranches = existingBranches.filter { !currentMyBranchNames.contains($0) }
                .map { BranchOption(name: $0) }
            
            if availableBranches.isEmpty {
                print("All existing branches are already tracked in MyBranches.")
                return
            }
            
            let selectedBranches = picker.multiSelection("Select branches to add to MyBranches", items: availableBranches)
            
            if selectedBranches.isEmpty {
                print("No branches selected.")
                return
            }
            
            for branchOption in selectedBranches {
                let myBranch = MyBranch(name: branchOption.name, description: branchOption.name)
                config.myBranches.append(myBranch)
            }
            
            try configLoader.save(config)
            let branchNames = selectedBranches.map { $0.name }
            print("✅ Added \(branchNames.count) branches to MyBranches: \(branchNames.joined(separator: ", "))")
        }
    }
}

/// Simple wrapper for branch names to use with picker
private struct BranchOption: DisplayablePickerItem {
    let name: String
    var displayName: String { name }
}