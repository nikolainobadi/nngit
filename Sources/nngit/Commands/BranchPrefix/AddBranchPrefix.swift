//
//  AddBranchPrefix.swift
//  nngit
//
//  Created by Codex on 6/22/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    struct AddBranchPrefix: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Adds a new branch prefix to the nngit configuration."
        )

        @Argument(help: "Name for the new branch prefix")
        var prefixName: String?

        @Flag(name: .long, help: "Require an issue number when using this prefix")
        var requiresIssueNumber: Bool = false

        @Option(name: .long, help: "Optional prefix string to prepend before the issue number")
        var issueNumberPrefixOption: String?

        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let loader = Nngit.makeConfigLoader()

            try shell.verifyLocalGitExists()
            var config = try loader.loadConfig(picker: picker)

            let name = try prefixName ?? picker.getRequiredInput("Enter a branch prefix name")

            guard !config.branchPrefixList.contains(where: { $0.name == name }) else {
                print("A branch prefix named '\(name)' already exists.")
                return
            }

            var requireIssue = requiresIssueNumber
            if !requireIssue {
                requireIssue = picker.getPermission("Require an issue number when using this prefix?")
            }

            // Prompt for an optional issue-number prefix if needed
            var issueNumberPrefix = issueNumberPrefixOption
            if requireIssue && (issueNumberPrefix == nil || issueNumberPrefix?.isEmpty == true) {
                let input = picker.getInput("Enter an issue number prefix (leave blank for none)")
                issueNumberPrefix = input.isEmpty ? nil : input
            }

            let prefix = BranchPrefix(
                name: name,
                requiresIssueNumber: requireIssue,
                issueNumberPrefix: issueNumberPrefix
            )

            print("Name: \(name)")
            print("Requires Issue Number: \(requireIssue)")
            if requireIssue {
                print("Issue Number Prefix: \(issueNumberPrefix ?? "")")
            }
            try picker.requiredPermission("Add this branch prefix?")

            config.branchPrefixList.append(prefix)
            try loader.save(config)
            print("✅ Added branch prefix: \(name)")
        }
    }
}
