//
//  SwitchBranch.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import Foundation
import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    /// Command that helps switching between local or remote branches.
    struct SwitchBranch: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Lists branches from the specified location and allows selecting one to switch to."
        )

        @Argument(help: "Name (or partial name) of the branch to switch to")
        var search: String?

        @Option(name: .shortAndLong, help: "Where to search for branches: local, remote, or both")
        var branchLocation: BranchLocation = .local

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            try shell.verifyLocalGitExists()
            let branchLoader = Nngit.makeBranchLoader()
            let config = try Nngit.makeConfigLoader().loadConfig()
            let manager = SwitchBranchManager(branchLocation: branchLocation, shell: shell, picker: picker, branchLoader: branchLoader, config: config)
            
            try manager.switchBranch(search: search)
        }
    }
}

// MARK: - Extension Dependencies
extension BranchLocation: ExpressibleByArgument { }
extension GitBranch: DisplayablePickerItem {
    var displayName: String {
        let sync = syncStatus.rawValue
        
        // For the main branch, show only sync status since "merged" doesn't apply conceptually
        if !isMerged {
            // This includes both unmerged branches and the main branch (which is never marked as merged now)
            return "\(name) (\(sync))"
        } else {
            // Non-main branches that are actually merged
            return "\(name) (merged, \(sync))"
        }
    }
}
