//
//  AddBranchPrefix.swift
//  nngit
//
//  Created by Codex on 6/22/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension xNngit {
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
            let loader = Nngit.makeConfigLoader()

            try shell.verifyLocalGitExists()
            var config = try loader.loadConfig(picker: picker)

            let name = try prefixName ?? picker.getRequiredInput("Enter a branch prefix name")

            guard !config.branchPrefixList.contains(where: { $0.name == name }) else {
                print("A branch prefix named '\(name)' already exists.")
                return
            }

            let prefix = BranchPrefix(name: name, requiresIssueNumber: requiresIssueNumber)

            print("Name: \(prefix.name)")
            print("Requires Issue Number: \(prefix.requiresIssueNumber)")
            try picker.requiredPermission("Add this branch prefix?")

            config.branchPrefixList.append(prefix)
            try loader.save(config)
            print("✅ Added branch prefix: \(name)")
        }
    }
}
