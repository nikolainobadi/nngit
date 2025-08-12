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
    /// Command that appends a new branch prefix to the configuration.
    struct AddBranchPrefix: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Adds a new branch prefix to the nngit configuration."
        )

        @Argument(help: "Name for the new branch prefix")
        var prefixName: String?

        @Flag(name: .long, help: "Require an issue number when using this prefix")
        var requiresIssueNumber: Bool = false
        
        @Option(name: .long, parsing: .upToNextOption,
                help: "Issue prefixes to use with this branch prefix (comma-separated, e.g., 'FRA-,RAPP-')")
        var issuePrefixes: [String] = []
        
        @Option(name: .long, help: "Default value to use when no issue is provided (e.g., 'NO-JIRA')")
        var defaultIssue: String?


        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let loader = Nngit.makeConfigLoader()

            try shell.verifyLocalGitExists()
            var config = try loader.loadConfig(picker: picker)

            let name = try prefixName ?? picker.getRequiredInput("Enter a branch prefix name")

            guard !config.branchPrefixes.contains(where: { $0.name == name }) else {
                print("A branch prefix named '\(name)' already exists.")
                return
            }

            var requireIssue = requiresIssueNumber
            if !requireIssue && issuePrefixes.isEmpty {
                requireIssue = picker.getPermission("Require an issue number when using this prefix?")
            }
            
            // Parse issue prefixes from comma-separated input
            var parsedIssuePrefixes: [String] = []
            if !issuePrefixes.isEmpty {
                // Handle comma-separated values
                parsedIssuePrefixes = issuePrefixes.flatMap { $0.split(separator: ",") }
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                    .filter { !$0.isEmpty }
            }
            
            // If issue prefixes are provided but none via CLI, prompt for them
            if requireIssue && parsedIssuePrefixes.isEmpty {
                let prefixInput = picker.getInput("Enter issue prefixes (comma-separated, e.g., 'FRA-,RAPP-') or leave empty for no prefix")
                if !prefixInput.isEmpty {
                    parsedIssuePrefixes = prefixInput.split(separator: ",")
                        .map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                }
            }
            
            var defaultValue = defaultIssue
            if requireIssue && defaultValue == nil {
                let input = picker.getInput("Enter a default issue value (e.g., 'NO-JIRA') or leave empty")
                defaultValue = input.isEmpty ? nil : input
            }

            let prefix = BranchPrefix(
                name: name,
                requiresIssueNumber: requireIssue,
                issuePrefixes: parsedIssuePrefixes,
                defaultIssueValue: defaultValue
            )

            print("Name: \(name)")
            print("Requires Issue Number: \(requireIssue)")
            if !parsedIssuePrefixes.isEmpty {
                print("Issue Prefixes: \(parsedIssuePrefixes.joined(separator: ", "))")
            }
            if let defaultValue {
                print("Default Issue: \(defaultValue)")
            }
            try picker.requiredPermission("Add this branch prefix?")

            config.branchPrefixes.append(prefix)
            try loader.save(config)
            print("✅ Added branch prefix: \(name)")
        }
    }
}
