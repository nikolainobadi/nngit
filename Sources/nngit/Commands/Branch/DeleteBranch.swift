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
    struct DeleteBranch: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Lists all available local branches, deletes the selected branches, and prunes the remote origin if one exists."
        )
        
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let configLoader = Nngit.makeConfigLoader()
            
            try shell.verifyLocalGitExists()
            
            let config = try configLoader.loadConfig(picker: picker)
            let eligibleBranches = try loadEligibleBranches(shell: shell, config: config)
            let branchesToDelete = picker.multiSelection("Select which branches to delete", items: eligibleBranches)
        
            for branch in branchesToDelete {
                if branch.isMerged {
                    try deleteBranch(branch, shell: shell)
                } else {
                    try picker.requiredPermission("This branch has NOT been merged into \(config.defaultBranch.yellow). Are you sure you want to delete it?")
                    try deleteBranch(branch, shell: shell, forced: true)
                }
            }
            
            if try shell.remoteExists(path: nil) {
                let _ = try shell.runWithOutput(makeGitCommand(.pruneOrigin, path: nil))
            }
        }
    }
}

extension Nngit.DeleteBranch {
    func loadEligibleBranches(shell: GitShell, config: GitConfig) throws -> [GitBranch] {
        let loader = GitBranchLoader(shell: shell)
        
        return try loader.loadBranches(from: .local, shell: shell).filter({ $0.isCurrentBranch && $0.name.lowercased() != config.defaultBranch.lowercased() })
    }
    
    func deleteBranch(_ branch: GitBranch, shell: GitShell, forced: Bool = false) throws {
        let _ = try shell.runWithOutput(makeGitCommand(.deleteBranch(name: branch.name, forced: forced), path: nil))
    }
}
