//
//  DeleteBranchPrefix.swift
//  nngit
//
//  Created by Codex on 6/22/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    struct DeleteBranchPrefix: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Deletes a branch prefix from the nngit configuration."
        )

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
                "Select a branch prefix to delete",
                items: config.branchPrefixList
            )

            try picker.requiredPermission("Delete branch prefix '\(selected.name)'?")

            config.branchPrefixList.removeAll { $0.name == selected.name }
            try loader.save(config)
            print("✅ Deleted branch prefix: \(selected.name)")
        }
    }
}
