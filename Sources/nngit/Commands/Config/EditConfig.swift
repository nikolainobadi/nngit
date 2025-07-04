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
                if let branch = defaultBranch { updated.defaultBranch = branch }
                if let rebase = rebaseWhenBranching { updated.rebaseWhenBranchingFromDefaultBranch = rebase }
                if let prune = pruneWhenDeleting { updated.pruneWhenDeletingBranches = prune }
                if let merge = loadMergeStatus { updated.loadMergeStatusWhenLoadingBranches = merge }
                if let creation = loadCreationDate { updated.loadCreationDateWhenLoadingBranches = creation }
                if let sync = loadSyncStatus { updated.loadSyncStatusWhenLoadingBranches = sync }
            } else {
                let options: [FieldChoice] = [
                    .init(field: .defaultBranch, current: config.defaultBranch),
                    .init(field: .rebaseWhenBranching, current: String(config.rebaseWhenBranchingFromDefaultBranch)),
                    .init(field: .pruneWhenDeleting, current: String(config.pruneWhenDeletingBranches)),
                    .init(field: .loadMergeStatus, current: String(config.loadMergeStatusWhenLoadingBranches)),
                    .init(field: .loadCreationDate, current: String(config.loadCreationDateWhenLoadingBranches)),
                    .init(field: .loadSyncStatus, current: String(config.loadSyncStatusWhenLoadingBranches))
                ]

                let selected = picker.multiSelection("Select which values you would like to edit", items: options)

                for item in selected {
                    switch item.field {
                    case .defaultBranch:
                        let input = picker.getInput("Enter a new default branch name (leave blank to keep '\(config.defaultBranch)')")
                        if !input.isEmpty { updated.defaultBranch = input }
                    case .rebaseWhenBranching:
                        let prompt = "Rebase when branching from default branch? (current: \(config.rebaseWhenBranchingFromDefaultBranch ? "yes" : "no"))"
                        updated.rebaseWhenBranchingFromDefaultBranch = picker.getPermission(prompt)
                    case .pruneWhenDeleting:
                        let prompt = "Automatically prune origin when deleting branches? (current: \(config.pruneWhenDeletingBranches ? "yes" : "no"))"
                        updated.pruneWhenDeletingBranches = picker.getPermission(prompt)
                    case .loadMergeStatus:
                        let prompt = "Load merge status when listing branches? (current: \(config.loadMergeStatusWhenLoadingBranches ? "yes" : "no"))"
                        updated.loadMergeStatusWhenLoadingBranches = picker.getPermission(prompt)
                    case .loadCreationDate:
                        let prompt = "Load branch creation date when listing branches? (current: \(config.loadCreationDateWhenLoadingBranches ? "yes" : "no"))"
                        updated.loadCreationDateWhenLoadingBranches = picker.getPermission(prompt)
                    case .loadSyncStatus:
                        let prompt = "Load sync status when listing branches? (current: \(config.loadSyncStatusWhenLoadingBranches ? "yes" : "no"))"
                        updated.loadSyncStatusWhenLoadingBranches = picker.getPermission(prompt)
                    }
                }
            }

            guard updated.defaultBranch != config.defaultBranch ||
                  updated.rebaseWhenBranchingFromDefaultBranch != config.rebaseWhenBranchingFromDefaultBranch ||
                  updated.pruneWhenDeletingBranches != config.pruneWhenDeletingBranches ||
                  updated.loadMergeStatusWhenLoadingBranches != config.loadMergeStatusWhenLoadingBranches ||
                  updated.loadCreationDateWhenLoadingBranches != config.loadCreationDateWhenLoadingBranches ||
                  updated.loadSyncStatusWhenLoadingBranches != config.loadSyncStatusWhenLoadingBranches else {
                print("No changes to save.")
                return
            }

            print("Current:")
            print("  Default Branch: \(config.defaultBranch.lightRed)")
            print("  Rebase When Branching: \(String(config.rebaseWhenBranchingFromDefaultBranch).lightRed)")
            print("  Prune When Deleting: \(String(config.pruneWhenDeletingBranches).lightRed)")
            print("  Load Merge Status: \(String(config.loadMergeStatusWhenLoadingBranches).lightRed)")
            print("  Load Creation Date: \(String(config.loadCreationDateWhenLoadingBranches).lightRed)")
            print("  Load Sync Status: \(String(config.loadSyncStatusWhenLoadingBranches).lightRed)")
            print("Updated:")
            print("  Default Branch: \(updated.defaultBranch.green)")
            print("  Rebase When Branching: \(String(updated.rebaseWhenBranchingFromDefaultBranch).green)")
            print("  Prune When Deleting: \(String(updated.pruneWhenDeletingBranches).green)")
            print("  Load Merge Status: \(String(updated.loadMergeStatusWhenLoadingBranches).green)")
            print("  Load Creation Date: \(String(updated.loadCreationDateWhenLoadingBranches).green)")
            print("  Load Sync Status: \(String(updated.loadSyncStatusWhenLoadingBranches).green)")
            try picker.requiredPermission("Save these changes?")

            try loader.save(updated)
            print("✅ Updated configuration")
        }
    }
}
