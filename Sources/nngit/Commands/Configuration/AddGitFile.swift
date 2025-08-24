//
//  AddGitFile.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    /// Command used to add a template file to the nngit configuration.
    struct AddGitFile: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "add-git-file",
            abstract: "Adds a template file to nngit for use in new repositories."
        )

        @Option(name: .customLong("source"), help: "Path to the source template file")
        var sourcePath: String?
        
        @Option(name: .customLong("name"), help: "Output filename (defaults to source filename)")
        var fileName: String?
        
        @Option(name: .customLong("nickname"), help: "Display name for the template")
        var nickname: String?
        
        @Flag(name: .customLong("direct-path"), help: "Use file at current location instead of copying")
        var useDirectPath = false

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let configLoader = Nngit.makeConfigLoader()
            let fileCreator = Nngit.makeFileCreator()
            
            try shell.verifyLocalGitExists()
            
            let manager = AddGitFileManager(
                configLoader: configLoader,
                fileCreator: fileCreator
            )
            
            try manager.addGitFile(
                sourcePath: sourcePath,
                fileName: fileName,
                nickname: nickname,
                useDirectPath: useDirectPath,
                picker: picker
            )
        }
    }
}