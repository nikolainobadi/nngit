//
//  Unstage.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/10/25.
//

import GitShellKit
import SwiftPicker
import ArgumentParser

extension Nngit.Staging {
    /// Command for unstaging selected files to remove them from the staging area.
    struct Unstage: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Unstage files to remove them from the staging area using interactive multi-selection."
        )
        
        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            try shell.verifyLocalGitExists()
            let manager = UnstageManager(shell: shell, picker: picker)
            
            try manager.unstageFiles()
        }
    }
}