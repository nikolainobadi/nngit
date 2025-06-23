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
    struct EditBranchPrefix: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Edits an existing branch prefix in the nngit configuration."
        )

        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let loader = GitConfigLoader()

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

            if let index = config.branchPrefixList.firstIndex(where: { $0.name == selected.name }) {
                let updatedPrefix = BranchPrefix(name: newName, requiresIssueNumber: requiresIssue)

                print("Current:")
                print("  Name: \(selected.name)")
                print("  Requires Issue Number: \(selected.requiresIssueNumber)")
                print("Updated:")
                print("  Name: \(updatedPrefix.name)")
                print("  Requires Issue Number: \(updatedPrefix.requiresIssueNumber)")
                try picker.requiredPermission("Save these changes?")

                config.branchPrefixList[index] = updatedPrefix
                try loader.save(config)
                print("✅ Updated branch prefix: \(selected.name) -> \(newName)")
            }
        }
    }
}
