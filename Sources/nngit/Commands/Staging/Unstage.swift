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
            
            let gitOutput = try shell.runGitCommandWithOutput(.getLocalChanges, path: nil)
            let allFiles = FileStatus.parseFromGitStatus(gitOutput)
            
            // Filter for files that are currently staged
            let stagedFiles = allFiles.filter { $0.hasStaged }
            
            guard !stagedFiles.isEmpty else {
                print("No staged files to unstage.")
                return
            }
            
            let selectedFiles = picker.multiSelection("Select files to unstage:", items: stagedFiles)
            
            guard !selectedFiles.isEmpty else {
                print("No files selected.")
                return
            }
            
            // Unstage each selected file
            for file in selectedFiles {
                try shell.runWithOutput("git reset HEAD \"\(file.path)\"")
            }
            
            print("✅ Unstaged \(selectedFiles.count) file(s)")
        }
    }
}