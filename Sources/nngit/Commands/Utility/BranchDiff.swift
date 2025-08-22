//
//  BranchDiff.swift
//  nngit
//
//  Created by Nikolai Nobadi on 7/9/25.
//

import Foundation
import GitShellKit
import SwiftPicker
import ArgumentParser

extension Nngit {
    /// Command used to show the cumulative diff of all changes from when the current branch was created.
    struct BranchDiff: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "branch-diff",
            abstract: "Shows the cumulative diff of all changes from when the current branch was created"
        )

        @Flag(name: .shortAndLong, help: "Copy diff to clipboard")
        var copy: Bool = false

        @Option(name: .customLong("base-branch"), help: "Base branch to diff against (defaults to configured default branch)")
        var baseBranch: String?

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let loader = Nngit.makeConfigLoader()
            let picker = Nngit.makePicker()
            let manager = BranchDiffManager(shell: shell)
            
            try shell.verifyLocalGitExists()
            
            let config = try loader.loadConfig(picker: picker)
            let targetBaseBranch = baseBranch ?? config.defaultBranch
            
            try manager.generateDiff(baseBranch: targetBaseBranch, copyToClipboard: copy)
        }
    }
}

