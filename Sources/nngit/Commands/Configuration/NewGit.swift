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
            let fileSystemManager = Nngit.makeFileSystemManager()
            
            try shell.verifyNoLocalGit()
            
            let manager = NewGitManager(
                shell: shell,
                picker: picker,
                configLoader: configLoader,
                fileSystemManager: fileSystemManager
            )
            
            try manager.initializeGitRepository()
            
            // Prompt user for GitHub remote repository creation
            let choice = picker.getPermission("Would you like to create a GitHub remote repository for this project?")
            
            if choice {
                let remoteManager = NewRemoteManager(shell: shell, picker: picker)
                try remoteManager.initializeGitHubRemote()
            }
        }
    }
}