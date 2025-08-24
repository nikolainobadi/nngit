//
//  NewGit.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    /// Command used to initialize a new Git repository with template files.
    struct NewGit: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "new-git",
            abstract: "Initialize a new Git repository with template files."
        )

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let configLoader = Nngit.makeConfigLoader()
            
            try shell.verifyNoLocalGit()
            
            let manager = NewGitManager(
                shell: shell,
                picker: picker,
                configLoader: configLoader
            )
            
            try manager.initializeGitRepository()
        }
    }
}