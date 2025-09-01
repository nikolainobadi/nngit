//
//  AddGitFile.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/31/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    /// Command used to add a registered template file to the current repository.
    struct AddGitFile: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "add-git-file",
            abstract: "Adds a registered template file to the current repository."
        )

        @Argument(help: "Name or nickname of the registered template file to add")
        var templateName: String?

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let configLoader = Nngit.makeConfigLoader()
            let fileSystemManager = Nngit.makeFileSystemManager()
            
            try shell.verifyLocalGitExists()
            
            let manager = AddGitFileManager(
                configLoader: configLoader,
                fileSystemManager: fileSystemManager,
                picker: picker
            )
            
            try manager.addGitFileToRepository(templateName: templateName)
        }
    }
}