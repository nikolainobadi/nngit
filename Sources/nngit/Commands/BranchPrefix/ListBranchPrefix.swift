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
    struct ListBranchPrefix: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Lists all saved branch prefixes in the nngit configuration."
        )

        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let loader = Nngit.makeConfigLoader()

            try shell.verifyLocalGitExists()
            let config = try loader.loadConfig(picker: picker)

            guard !config.branchPrefixList.isEmpty else {
                print("No branch prefixes exist.")
                return
            }

            print("Branch prefixes:")
            print("Branch prefixes:")
            for prefix in config.branchPrefixList {
                let requiresText = prefix.requiresIssueNumber ? "yes" : "no"
                let prefixPart = prefix.issueNumberPrefix.map { ", prefix: \($0)" } ?? ""
                print("  - \(prefix.name) (requires issue number: \(requiresText)\(prefixPart))")
            }
        }
    }
}