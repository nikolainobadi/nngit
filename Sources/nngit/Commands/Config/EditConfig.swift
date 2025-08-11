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

        @Option(name: .customLong("rebase-when-branching"), help: "Toggle rebase prompt when branching from the default branch (true/false)")
        var rebaseWhenBranching: Bool?

        @Option(name: .customLong("prune-when-deleting"), help: "Toggle automatic pruning when deleting branches (true/false)")
        var pruneWhenDeleting: Bool?

        @Option(name: .customLong("load-merge-status"), help: "Load merge status when listing branches (true/false)")
        var loadMergeStatus: Bool?

        @Option(name: .customLong("load-creation-date"), help: "Load branch creation date when listing branches (true/false)")
        var loadCreationDate: Bool?

        @Option(name: .customLong("load-sync-status"), help: "Load sync status when listing branches (true/false)")
        var loadSyncStatus: Bool?

        enum Field: String, CaseIterable {
            case defaultBranch = "Default Branch"
            case rebaseWhenBranching = "Rebase When Branching"
            case pruneWhenDeleting = "Prune When Deleting"
            case loadMergeStatus = "Load Merge Status"
            case loadCreationDate = "Load Creation Date"
            case loadSyncStatus = "Load Sync Status"
        }

        struct FieldChoice: DisplayablePickerItem {
            let field: Field
            let current: String
            var displayName: String { "<\(field.rawValue): \(current)>" }
        }

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let loader = Nngit.makeConfigLoader()
            let config = try loader.loadConfig(picker: picker)

            try shell.verifyLocalGitExists()
            var updated = config

            let argsProvided = defaultBranch != nil ||
                rebaseWhenBranching != nil ||
                pruneWhenDeleting != nil ||
                loadMergeStatus != nil ||
                loadCreationDate != nil ||
                loadSyncStatus != nil

            if argsProvided {
                if let branch = defaultBranch { updated.branches.defaultBranch = branch }
                if let rebase = rebaseWhenBranching { updated.behaviors.rebaseWhenBranchingFromDefault = rebase }
                if let prune = pruneWhenDeleting { updated.behaviors.pruneWhenDeleting = prune }
                if let merge = loadMergeStatus { updated.loading.loadMergeStatus = merge }
                if let creation = loadCreationDate { updated.loading.loadCreationDate = creation }
                if let sync = loadSyncStatus { updated.loading.loadSyncStatus = sync }
            } else {
                let options: [FieldChoice] = [
                    .init(field: .defaultBranch, current: config.branches.defaultBranch),
                    .init(field: .rebaseWhenBranching, current: String(config.behaviors.rebaseWhenBranchingFromDefault)),
                    .init(field: .pruneWhenDeleting, current: String(config.behaviors.pruneWhenDeleting)),
                    .init(field: .loadMergeStatus, current: String(config.loading.loadMergeStatus)),
                    .init(field: .loadCreationDate, current: String(config.loading.loadCreationDate)),
                    .init(field: .loadSyncStatus, current: String(config.loading.loadSyncStatus))
                ]

                let selected = picker.multiSelection("Select which values you would like to edit", items: options)

                for item in selected {
                    switch item.field {
                    case .defaultBranch:
                        let input = picker.getInput("Enter a new default branch name (leave blank to keep '\(config.branches.defaultBranch)')")
                        if !input.isEmpty { updated.branches.defaultBranch = input }
                    case .rebaseWhenBranching:
                        let prompt = "Rebase when branching from default branch? (current: \(config.behaviors.rebaseWhenBranchingFromDefault ? "yes" : "no"))"
                        updated.behaviors.rebaseWhenBranchingFromDefault = picker.getPermission(prompt)
                    case .pruneWhenDeleting:
                        let prompt = "Automatically prune origin when deleting branches? (current: \(config.behaviors.pruneWhenDeleting ? "yes" : "no"))"
                        updated.behaviors.pruneWhenDeleting = picker.getPermission(prompt)
                    case .loadMergeStatus:
                        let prompt = "Load merge status when listing branches? (current: \(config.loading.loadMergeStatus ? "yes" : "no"))"
                        updated.loading.loadMergeStatus = picker.getPermission(prompt)
                    case .loadCreationDate:
                        let prompt = "Load branch creation date when listing branches? (current: \(config.loading.loadCreationDate ? "yes" : "no"))"
                        updated.loading.loadCreationDate = picker.getPermission(prompt)
                    case .loadSyncStatus:
                        let prompt = "Load sync status when listing branches? (current: \(config.loading.loadSyncStatus ? "yes" : "no"))"
                        updated.loading.loadSyncStatus = picker.getPermission(prompt)
                    }
                }
            }

            guard updated.branches.defaultBranch != config.branches.defaultBranch ||
                  updated.behaviors.rebaseWhenBranchingFromDefault != config.behaviors.rebaseWhenBranchingFromDefault ||
                  updated.behaviors.pruneWhenDeleting != config.behaviors.pruneWhenDeleting ||
                  updated.loading.loadMergeStatus != config.loading.loadMergeStatus ||
                  updated.loading.loadCreationDate != config.loading.loadCreationDate ||
                  updated.loading.loadSyncStatus != config.loading.loadSyncStatus else {
                print("No changes to save.")
                return
            }

            print("Current:")
            print("  Default Branch: \(config.branches.defaultBranch.lightRed)")
            print("  Rebase When Branching: \(String(config.behaviors.rebaseWhenBranchingFromDefault).lightRed)")
            print("  Prune When Deleting: \(String(config.behaviors.pruneWhenDeleting).lightRed)")
            print("  Load Merge Status: \(String(config.loading.loadMergeStatus).lightRed)")
            print("  Load Creation Date: \(String(config.loading.loadCreationDate).lightRed)")
            print("  Load Sync Status: \(String(config.loading.loadSyncStatus).lightRed)")
            print("Updated:")
            print("  Default Branch: \(updated.branches.defaultBranch.green)")
            print("  Rebase When Branching: \(String(updated.behaviors.rebaseWhenBranchingFromDefault).green)")
            print("  Prune When Deleting: \(String(updated.behaviors.pruneWhenDeleting).green)")
            print("  Load Merge Status: \(String(updated.loading.loadMergeStatus).green)")
            print("  Load Creation Date: \(String(updated.loading.loadCreationDate).green)")
            print("  Load Sync Status: \(String(updated.loading.loadSyncStatus).green)")
            try picker.requiredPermission("Save these changes?")

            try loader.save(updated)
            print("✅ Updated configuration")
        }
    }
}
