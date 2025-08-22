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
            let config = try Nngit.makeConfigLoader().loadConfig(picker: picker)
            
            let manager = SwitchBranchManager(
                branchLocation: branchLocation,
                shell: shell,
                picker: picker,
                branchLoader: branchLoader,
                config: config
            )
            try manager.executeSwitchWorkflow(search: search)
        }
    }
}

// MARK: - Extension Dependencies
extension BranchLocation: ExpressibleByArgument { }
extension GitBranch: DisplayablePickerItem {
    var displayName: String {
        let mergeStatus = isMerged ? "merged" : "unmerged"
        let sync = syncStatus.rawValue
        return "\(name) (\(mergeStatus), \(sync))"
    }
}
