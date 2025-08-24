//
//  EditConfig.swift
//  nngit
//
//  Created by Codex on 6/27/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    /// Command used to modify fields in the nngit configuration.
    struct EditConfig: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "config",
            abstract: "Edits the nngit configuration file."
        )

        @Option(name: .customLong("default-branch"), help: "New name for the default branch")
        var defaultBranch: String?

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let loader = Nngit.makeConfigLoader()
            let config = try loader.loadConfig()

            try shell.verifyLocalGitExists()
            var updated = config

            if let branch = defaultBranch {
                updated.defaultBranch = branch
            } else {
                let input = picker.getInput("Enter a new default branch name (leave blank to keep '\(config.defaultBranch)')")
                if !input.isEmpty { 
                    updated.defaultBranch = input 
                }
            }

            guard updated.defaultBranch != config.defaultBranch else {
                print("No changes to save.")
                return
            }

            print("Current Default Branch: \(config.defaultBranch.lightRed)")
            print("Updated Default Branch: \(updated.defaultBranch.green)")
            try picker.requiredPermission("Save these changes?")

            try loader.save(updated)
            print("✅ Updated configuration")
        }
    }
}
