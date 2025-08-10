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
            
            let gitOutput = try shell.runGitCommandWithOutput(.getLocalChanges, path: nil)
            let allFiles = FileStatus.parseFromGitStatus(gitOutput)
            
            // Filter for files that can be staged (unstaged or untracked)
            let unstageableFiles = allFiles.filter { $0.hasUnstaged || $0.unstagedStatus == .untracked }
            
            guard !unstageableFiles.isEmpty else {
                print("No files available to stage.")
                return
            }
            
            let selectedFiles = picker.multiSelection("Select files to stage:", items: unstageableFiles)
            
            guard !selectedFiles.isEmpty else {
                print("No files selected.")
                return
            }
            
            // Stage each selected file
            for file in selectedFiles {
                try shell.runWithOutput("git add \"\(file.path)\"")
            }
            
            print("✅ Staged \(selectedFiles.count) file(s)")
        }
    }
}