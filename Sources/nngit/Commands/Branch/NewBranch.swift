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


        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let loader = Nngit.makeConfigLoader()
            try shell.verifyLocalGitExists()
            let config = try loader.loadConfig(picker: picker)
            try rebaseIfNecessary(shell: shell, config: config, picker: picker)
            let branchName = try name ?? picker.getRequiredInput("Enter the name of your new branch.")

            let fullBranchName = branchName

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
    func rebaseIfNecessary(shell: GitShell, config: GitConfig, picker: CommandLinePicker) throws {
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

}

