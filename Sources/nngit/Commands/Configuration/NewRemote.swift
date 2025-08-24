//
//  NewRemote.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    /// Command used to initialize a new GitHub remote repository.
    struct NewRemote: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "new-remote",
            abstract: "Initialize a new GitHub remote repository."
        )
        
        @Option(name: .long, help: "Repository visibility (public or private)")
        var visibility: RepoVisibility?

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            
            let manager = NewRemoteManager(
                shell: shell,
                picker: picker
            )
            
            try manager.initializeGitHubRemote(visibility: visibility)
        }
    }
}

// MARK: - ArgumentParser Conformance
extension RepoVisibility: @retroactive ExpressibleByArgument {}