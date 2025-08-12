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

            guard !config.branchPrefixes.isEmpty else {
                print("No branch prefixes exist.")
                return
            }

            let selected = try picker.requiredSingleSelection(
                "Select a branch prefix to edit",
                items: config.branchPrefixes
            )

            let newName = try picker.getRequiredInput("Enter a new name for the prefix")
            let requiresIssue = picker.getPermission("Require an issue number when using this prefix?")
            
            // Get issue prefixes
            var parsedIssuePrefixes: [String] = selected.issuePrefixes
            let prefixInput = picker.getInput("Enter issue prefixes (comma-separated, e.g., 'FRA-,RAPP-') or leave empty to keep current")
            if !prefixInput.isEmpty {
                parsedIssuePrefixes = prefixInput.split(separator: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }
            
            // Get default issue value
            var defaultValue = selected.defaultIssueValue
            if requiresIssue {
                let defaultInput = picker.getInput("Enter a default issue value (e.g., 'NO-JIRA') or leave empty to keep current")
                if !defaultInput.isEmpty {
                    defaultValue = defaultInput
                }
            }


            if let index = config.branchPrefixes.firstIndex(where: { $0.name == selected.name }) {
                let updatedPrefix = BranchPrefix(
                    name: newName,
                    requiresIssueNumber: requiresIssue,
                    issuePrefixes: parsedIssuePrefixes,
                    defaultIssueValue: defaultValue
                )

                print("Current:")
                print("  Name: \(selected.name)")
                print("  Requires Issue Number: \(selected.requiresIssueNumber)")
                if !selected.issuePrefixes.isEmpty {
                    print("  Issue Prefixes: \(selected.issuePrefixes.joined(separator: ", "))")
                }
                if let defaultIssue = selected.defaultIssueValue {
                    print("  Default Issue: \(defaultIssue)")
                }
                print("Updated:")
                print("  Name: \(updatedPrefix.name)")
                print("  Requires Issue Number: \(updatedPrefix.requiresIssueNumber)")
                if !updatedPrefix.issuePrefixes.isEmpty {
                    print("  Issue Prefixes: \(updatedPrefix.issuePrefixes.joined(separator: ", "))")
                }
                if let defaultIssue = updatedPrefix.defaultIssueValue {
                    print("  Default Issue: \(defaultIssue)")
                }
                try picker.requiredPermission("Save these changes?")

                config.branchPrefixes[index] = updatedPrefix
                try loader.save(config)
                print("✅ Updated branch prefix: \(selected.name) -> \(newName)")
            }
        }
    }
}
