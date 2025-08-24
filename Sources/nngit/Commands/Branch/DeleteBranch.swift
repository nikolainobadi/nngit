//
//  DeleteBranch.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    /// Command that allows selecting and deleting local branches.
    struct DeleteBranch: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Lists all available local branches, deletes the selected branches, and prunes the remote origin."
        )

        @Flag(name: .long, help: "Delete all merged branches without prompting")
        var allMerged: Bool = false

        @Argument(help: "Name (or partial name) of the branch to delete")
        var search: String?
        
        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            try shell.verifyLocalGitExists()
            let branchLoader = Nngit.makeBranchLoader()
            let config = try Nngit.makeConfigLoader().loadConfig()
            let manager = DeleteBranchManager(shell: shell, picker: picker, branchLoader: branchLoader, config: config)
            
            try manager.deleteBranches(search: search, allMerged: allMerged)
        }
    }
}
