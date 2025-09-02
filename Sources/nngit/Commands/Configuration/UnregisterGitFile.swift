//
//  UnregisterGitFile.swift
//  nngit
//
//  Created by Nikolai Nobadi on 9/2/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    /// Command used to unregister a template file from the nngit configuration.
    struct UnregisterGitFile: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "unregister-git-file",
            abstract: "Unregisters a template file from nngit configuration."
        )

        @Argument(help: "Name or nickname of the template file to unregister")
        var templateName: String?
        
        @Flag(name: .customLong("all"), help: "Remove all registered git files")
        var removeAll: Bool = false

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let configLoader = Nngit.makeConfigLoader()
            let fileCreator = Nngit.makeFileCreator()
            
            try shell.verifyLocalGitExists()
            
            let manager = UnregisterGitFileManager(
                configLoader: configLoader,
                fileCreator: fileCreator,
                picker: picker
            )
            
            try manager.unregisterGitFile(
                templateName: templateName,
                removeAll: removeAll
            )
        }
    }
}