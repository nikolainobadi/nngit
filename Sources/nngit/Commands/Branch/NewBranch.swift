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
    struct NewBranch: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Creates a new branch. If remote repository exists, will require merging any remote changes before creating new branch."
        )

        @Argument(help: "The name of the new branch.")
        var name: String?

        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            
            try shell.verifyLocalGitExists()
            
            let branchName = try name ?? picker.getRequiredInput("Enter the name of your new branch.")
            let formattedBranchName = branchName.formattedBranchName

            try shell.runGitCommandWithOutput(.newBranch(branchName: formattedBranchName), path: nil)
            
            print("✅ Created and switched to branch: \(formattedBranchName)")
        }
    }
}


// MARK: - Extension Dependencies
private extension String {
    var formattedBranchName: String {
        return self.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "_", with: "-")
    }
}
