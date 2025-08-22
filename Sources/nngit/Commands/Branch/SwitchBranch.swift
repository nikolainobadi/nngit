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
            let (shell, picker, branchLoader, config) = try setupComponents()
            let branchNames = try branchLoader.loadBranchNames(from: branchLocation, shell: shell)
            
            guard let filteredNames = try handleSearchAndFiltering(branchNames: branchNames, search: search, branchLoader: branchLoader, shell: shell) else {
                return
            }
            
            let branches = try loadBranchData(branchNames: filteredNames, branchLoader: branchLoader, shell: shell, config: config)
            let (currentBranch, availableBranches) = prepareBranchSelection(branches: branches)
            
            try selectAndSwitchBranch(
                availableBranches: availableBranches, 
                currentBranch: currentBranch, 
                picker: picker, 
                shell: shell
            )
        }
    }
}


// MARK: - Helper Methods
private extension Nngit.SwitchBranch {
    func setupComponents() throws -> (GitShell, CommandLinePicker, GitBranchLoader, GitConfig) {
        let shell = Nngit.makeShell()
        let picker = Nngit.makePicker()
        try shell.verifyLocalGitExists()
        let branchLoader = Nngit.makeBranchLoader()
        let config = try Nngit.makeConfigLoader().loadConfig(picker: picker)
        return (shell, picker, branchLoader, config)
    }
    
    func handleSearchAndFiltering(branchNames: [String], search: String?, branchLoader: GitBranchLoader, shell: GitShell) throws -> [String]? {
        var filteredNames = branchNames
        
        if let search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filteredNames = branchLoader.filterBranchNamesBySearch(filteredNames, search: search)

            if filteredNames.isEmpty {
                print("No branches found matching '\(search)'")
                return nil
            }
            
            if filteredNames.contains(where: { $0 == search || $0 == "* " + search }) {
                let exactName = filteredNames.first(where: { $0 == search || $0 == "* " + search })!
                let clean = exactName.hasPrefix("*") ? String(exactName.dropFirst(2)) : exactName
                try shell.runGitCommandWithOutput(.switchBranch(branchName: clean), path: nil)
                return nil
            }
        }
        
        return filteredNames
    }
    
    func loadBranchData(branchNames: [String], branchLoader: GitBranchLoader, shell: GitShell, config: GitConfig) throws -> [GitBranch] {
        return try branchLoader.loadBranches(
            for: branchNames,
            shell: shell,
            mainBranchName: config.branches.defaultBranch,
            loadMergeStatus: true,
            loadCreationDate: true,
            loadSyncStatus: true
        )
    }
    
    func prepareBranchSelection(branches: [GitBranch]) -> (current: GitBranch?, available: [GitBranch]) {
        let currentBranch = branches.first(where: { $0.isCurrentBranch })
        let availableBranches = branches.filter { !$0.isCurrentBranch }
        return (currentBranch, availableBranches)
    }
    
    func selectAndSwitchBranch(availableBranches: [GitBranch], currentBranch: GitBranch?, picker: CommandLinePicker, shell: GitShell) throws {
        var details = ""
        
        if let currentBranch {
            details = "(switching from \(currentBranch.name))"
        }

        let selectedBranch = try picker.requiredSingleSelection("Select a branch \(details)", items: availableBranches)

        try shell.runGitCommandWithOutput(.switchBranch(branchName: selectedBranch.name), path: nil)
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
