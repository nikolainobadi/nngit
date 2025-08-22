//
//  SwitchBranchManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import GitShellKit
import SwiftPicker

/// Manager utility for handling branch switching workflows and operations.
struct SwitchBranchManager {
    private let branchLocation: BranchLocation
    private let shell: GitShell
    private let picker: CommandLinePicker
    private let branchLoader: GitBranchLoader
    private let config: GitConfig
    
    init(branchLocation: BranchLocation, shell: GitShell, picker: CommandLinePicker, branchLoader: GitBranchLoader, config: GitConfig) {
        self.branchLocation = branchLocation
        self.shell = shell
        self.picker = picker
        self.branchLoader = branchLoader
        self.config = config
    }
}


// MARK: - Branch Switching Operations
extension SwitchBranchManager {
    func switchBranch(search: String?) throws {
        let branchNames = try branchLoader.loadBranchNames(from: branchLocation, shell: shell)
        
        guard let filteredNames = try handleSearchAndFiltering(branchNames: branchNames, search: search) else {
            return
        }
        
        let branches = try loadBranchData(branchNames: filteredNames)
        let (currentBranch, availableBranches) = prepareBranchSelection(branches: branches)
        
        try selectAndSwitchBranch(
            availableBranches: availableBranches, 
            currentBranch: currentBranch
        )
    }
}


// MARK: - Private Methods
private extension SwitchBranchManager {
    func handleSearchAndFiltering(branchNames: [String], search: String?) throws -> [String]? {
        var filteredNames = branchNames
        
        if let search, !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            filteredNames = self.branchLoader.filterBranchNamesBySearch(filteredNames, search: search)

            if filteredNames.isEmpty {
                print("No branches found matching '\(search)'")
                return nil
            }
            
            if filteredNames.contains(where: { $0 == search || $0 == "* " + search }) {
                let exactName = filteredNames.first(where: { $0 == search || $0 == "* " + search })!
                let clean = exactName.hasPrefix("*") ? String(exactName.dropFirst(2)) : exactName
                try self.shell.runGitCommandWithOutput(.switchBranch(branchName: clean), path: nil)
                return nil
            }
        }
        
        return filteredNames
    }
    
    func loadBranchData(branchNames: [String]) throws -> [GitBranch] {
        return try branchLoader.loadBranches(
            for: branchNames,
            shell: shell,
            mainBranchName: config.defaultBranch
        )
    }
    
    func prepareBranchSelection(branches: [GitBranch]) -> (current: GitBranch?, available: [GitBranch]) {
        let currentBranch = branches.first(where: { $0.isCurrentBranch })
        let availableBranches = branches.filter { !$0.isCurrentBranch }
        return (currentBranch, availableBranches)
    }
    
    func selectAndSwitchBranch(availableBranches: [GitBranch], currentBranch: GitBranch?) throws {
        var details = ""
        
        if let currentBranch {
            details = "(switching from \(currentBranch.name))"
        }

        let selectedBranch = try self.picker.requiredSingleSelection("Select a branch \(details)", items: availableBranches)

        try self.shell.runGitCommandWithOutput(.switchBranch(branchName: selectedBranch.name), path: nil)
    }
}
