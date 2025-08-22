//
//  NewBranch.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import GitShellKit
import SwiftPicker
import ArgumentParser

extension Nngit {
    /// Command that creates a new branch using optional branch prefixes and issue numbers.
    struct NewBranch: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Creates a new branch. If remote repository exists, will require merging any remote changes before creating new branch."
        )

        @Argument(help: "The name of the new branch.")
        var name: String?


        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            try shell.verifyLocalGitExists()
            
            let branchName = try name ?? picker.getRequiredInput("Enter the name of your new branch.")
            let fullBranchName = branchName

            try shell.runGitCommandWithOutput(.newBranch(branchName: fullBranchName), path: nil)
            
            print("✅ Created and switched to branch: \(fullBranchName)")
        }
    }
}
