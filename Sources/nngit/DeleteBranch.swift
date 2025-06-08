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
            let picker = SwiftPicker()
            let shell = GitShellAdapter()
            let eligibleBranches = try loadEligibleBranches(shell: shell)
            let branchesToDelete = picker.multiSelection("Select which branches to delete", items: eligibleBranches)
        
            for branch in branchesToDelete {
                if branch.isMerged {
                    try deleteBranch(branch)
                } else {
                    try picker.requiredPermission("") // TODO: -
                    try deleteBranch(branch, forced: true)
                }
            }
            
            try pruneOrigin()
        }
    }
}

extension Nngit.DeleteBranch {
    func loadEligibleBranches(shell: GitShell) throws -> [GitBranch] {
        return [] // TODO: -
    }
    
    func deleteBranch(_ branch: GitBranch, forced: Bool = false) throws {
        // TODO: -
    }
    
    func pruneOrigin() throws {
        // TODO: -
    }
}
