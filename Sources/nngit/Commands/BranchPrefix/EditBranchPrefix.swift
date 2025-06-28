//
//  EditBranchPrefix.swift
//  nngit
//
//  Created by Codex on 6/22/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    /// Command used to modify an existing branch prefix.
    struct EditBranchPrefix: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Edits an existing branch prefix in the nngit configuration."
        )

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let loader = Nngit.makeConfigLoader()

            try shell.verifyLocalGitExists()
            var config = try loader.loadConfig(picker: picker)

            guard !config.branchPrefixList.isEmpty else {
                print("No branch prefixes exist.")
                return
            }

            let selected = try picker.requiredSingleSelection(
                "Select a branch prefix to edit",
                items: config.branchPrefixList
            )

            let newName = try picker.getRequiredInput("Enter a new name for the prefix")
            let requiresIssue = picker.getPermission("Require an issue number when using this prefix?")

            // Prompt for an optional issue-number prefix
            let issuePrefixInput = picker.getInput("Enter a new issue number prefix (leave blank to keep existing or none)")
            let newIssueNumberPrefix: String?
            if issuePrefixInput.isEmpty {
                newIssueNumberPrefix = selected.issueNumberPrefix
            } else {
                newIssueNumberPrefix = issuePrefixInput
            }

            if let index = config.branchPrefixList.firstIndex(where: { $0.name == selected.name }) {
                let updatedPrefix = BranchPrefix(
                    name: newName,
                    requiresIssueNumber: requiresIssue,
                    issueNumberPrefix: newIssueNumberPrefix
                )

                print("Current:")
                print("  Name: \(selected.name)")
                print("  Requires Issue Number: \(selected.requiresIssueNumber)")
                print("  Issue Number Prefix: \(selected.issueNumberPrefix ?? "")")
                print("Updated:")
                print("  Name: \(updatedPrefix.name)")
                print("  Requires Issue Number: \(updatedPrefix.requiresIssueNumber)")
                print("  Issue Number Prefix: \(updatedPrefix.issueNumberPrefix ?? "")")
                try picker.requiredPermission("Save these changes?")

                config.branchPrefixList[index] = updatedPrefix
                try loader.save(config)
                print("✅ Updated branch prefix: \(selected.name) -> \(newName)")
            }
        }
    }
}
