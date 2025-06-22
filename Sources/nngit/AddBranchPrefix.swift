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

        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let loader = GitConfigLoader()

            try shell.verifyLocalGitExists()
            var config = try loader.loadConfig(picker: picker)

            let name = try prefixName ?? picker.getRequiredInput("Enter a branch prefix name")

            guard !config.branchPrefixList.contains(where: { $0.name == name }) else {
                print("A branch prefix named '\(name)' already exists.")
                return
            }

            let prefix = BranchPrefix(name: name, requiresIssueNumber: requiresIssueNumber)
            config.branchPrefixList.append(prefix)
            try loader.save(config)
            print("✅ Added branch prefix: \(name)")
        }
    }
}
