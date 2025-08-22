//
//  Stage.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/10/25.
//

import GitShellKit
import SwiftPicker
import ArgumentParser

extension Nngit.Staging {
    /// Command for staging selected files to prepare them for commit.
    struct Stage: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Stage files for commit using interactive multi-selection."
        )
        
        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            try shell.verifyLocalGitExists()
            let manager = StageManager(shell: shell, picker: picker)
            
            try manager.stageFiles()
        }
    }
}
