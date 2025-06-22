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

        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let loader = GitConfigLoader()
            try shell.verifyLocalGitExists()
            let config = try loader.loadConfig(picker: picker)
            try rebaseIfNecessary(shell: shell, config: config, picker: picker)
            let branchName = try name ?? picker.getRequiredInput("Enter the name of your new branch.")
            let fullBranchName = BranchNameGenerator.generate(name: branchName)

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
