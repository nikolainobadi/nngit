//
//  ListBranchPrefix.swift
//  nngit
//
//  Created by Codex on 6/27/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    /// Command that prints all branch prefixes configured for the repository.
    struct ListBranchPrefix: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Lists all saved branch prefixes in the nngit configuration."
        )

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let loader = Nngit.makeConfigLoader()

            try shell.verifyLocalGitExists()
            let config = try loader.loadConfig(picker: picker)

            guard !config.branchPrefixes.isEmpty else {
                print("No branch prefixes exist.")
                return
            }

            print("Branch prefixes:")
            for prefix in config.branchPrefixes {
                let requiresText = prefix.requiresIssueNumber ? "yes" : "no"
                print("  - \(prefix.name) (requires issue number: \(requiresText))")
            }
        }
    }
}
