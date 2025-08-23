//
//  Discard.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import GitShellKit
import SwiftPicker
import ArgumentParser

/// Represents which scope of changes to discard when running the ``Discard`` command.
enum DiscardScope: String, ExpressibleByArgument {
    case staged, unstaged, both
}

extension Nngit {
    /// Command used for discarding local changes from the working tree.
    struct Discard: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Convenience command to discard all local changes in repository"
        )

        @Option(name: .shortAndLong, help: "Which scope of changes to discard: staged, unstaged, or both")
        var scope: DiscardScope = .both

        @Flag(name: .long, help: "Select specific files to discard (interactive mode)")
        var files: Bool = false

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            try shell.verifyLocalGitExists()
            
            let manager = DiscardManager(shell: shell, picker: picker)
            try manager.performDiscard(scope: scope, files: files)
        }
    }
}

