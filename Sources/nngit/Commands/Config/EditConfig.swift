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
            abstract: "Edits the nngit configuration file."
        )

        @Option(name: .customLong("default-branch"), help: "New name for the default branch")
        var defaultBranch: String?

        @Option(name: .customLong("rebase-when-branching"), help: "Toggle rebase prompt when branching from the default branch (true/false)")
        var rebaseWhenBranching: Bool?

        @Option(name: .customLong("prune-when-deleting"), help: "Toggle automatic pruning when deleting branches (true/false)")
        var pruneWhenDeleting: Bool?

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let loader = Nngit.makeConfigLoader()
            let config = try loader.loadConfig(picker: picker)

            try shell.verifyLocalGitExists()
            var updated = config

            let argsProvided = defaultBranch != nil || rebaseWhenBranching != nil || pruneWhenDeleting != nil

            if argsProvided {
                if let branch = defaultBranch { updated.defaultBranch = branch }
                if let rebase = rebaseWhenBranching { updated.rebaseWhenBranchingFromDefaultBranch = rebase }
                if let prune = pruneWhenDeleting { updated.pruneWhenDeletingBranches = prune }
            } else {
                let branchInput = picker.getInput("Enter a new default branch name (leave blank to keep '\(config.defaultBranch)')")
                if !branchInput.isEmpty { updated.defaultBranch = branchInput }

                let rebasePrompt = "Rebase when branching from default branch? (current: \(config.rebaseWhenBranchingFromDefaultBranch ? "yes" : "no"))"
                updated.rebaseWhenBranchingFromDefaultBranch = picker.getPermission(rebasePrompt)

                let prunePrompt = "Automatically prune origin when deleting branches? (current: \(config.pruneWhenDeletingBranches ? "yes" : "no"))"
                updated.pruneWhenDeletingBranches = picker.getPermission(prunePrompt)
            }

            guard updated.defaultBranch != config.defaultBranch ||
                  updated.rebaseWhenBranchingFromDefaultBranch != config.rebaseWhenBranchingFromDefaultBranch ||
                  updated.pruneWhenDeletingBranches != config.pruneWhenDeletingBranches else {
                print("No changes to save.")
                return
            }

            print("Current:")
            print("  Default Branch: \(config.defaultBranch.lightRed)")
            print("  Rebase When Branching: \(String(config.rebaseWhenBranchingFromDefaultBranch).lightRed)")
            print("  Prune When Deleting: \(String(config.pruneWhenDeletingBranches).lightRed)")
            print("Updated:")
            print("  Default Branch: \(updated.defaultBranch.green)")
            print("  Rebase When Branching: \(String(updated.rebaseWhenBranchingFromDefaultBranch).green)")
            print("  Prune When Deleting: \(String(updated.pruneWhenDeletingBranches).green)")
            try picker.requiredPermission("Save these changes?")

            try loader.save(updated)
            print("✅ Updated configuration")
        }
    }
}
