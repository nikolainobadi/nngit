//
//  CheckoutRemoteManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import GitShellKit
import SwiftPicker

/// Manager utility for handling remote branch checkout workflows and operations.
struct CheckoutRemoteManager {
    private let shell: GitShell
    private let picker: CommandLinePicker
    private let branchLoader: GitBranchLoader
    
    init(shell: GitShell, picker: CommandLinePicker, branchLoader: GitBranchLoader) {
        self.shell = shell
        self.picker = picker
        self.branchLoader = branchLoader
    }
}


// MARK: - Remote Branch Checkout Operations
extension CheckoutRemoteManager {
    func loadRemoteBranchNames() throws -> [String] {
        return try branchLoader.loadBranchNames(from: .remote, shell: shell)
    }
    
    func filterNonExistingLocalBranches(remoteBranches: [String]) throws -> [String] {
        // Get local branch names
        let localBranchNames = try branchLoader.loadBranchNames(from: .local, shell: shell)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "* ", with: "") }
        let localBranchSet = Set(localBranchNames)
        
        // Filter remote branches
        var availableBranches: [String] = []
        
        for remoteBranch in remoteBranches {
            // Clean the remote branch name (remove origin/ prefix)
            let cleanName = cleanRemoteBranchName(remoteBranch)
            
            // Only include if it doesn't exist locally
            if !localBranchSet.contains(cleanName) {
                availableBranches.append(cleanName)
            }
        }
        
        return availableBranches.sorted()
    }
    
    func cleanRemoteBranchName(_ remoteBranch: String) -> String {
        let trimmed = remoteBranch.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmed.hasPrefix("origin/") {
            return String(trimmed.dropFirst(7)) // Remove "origin/"
        }
        
        // Handle other remote prefixes if needed
        if let slashIndex = trimmed.firstIndex(of: "/") {
            return String(trimmed[trimmed.index(after: slashIndex)...])
        }
        
        return trimmed
    }
    
    func selectRemoteBranch(availableBranches: [String]) throws -> String {
        let remoteBranchItems = availableBranches.map { RemoteBranchItem(name: $0) }
        let selectedBranch = try picker.requiredSingleSelection("Select a remote branch to checkout", items: remoteBranchItems)
        return selectedBranch.name
    }
    
    func checkoutRemoteBranch(branchName: String) throws {
        let remoteBranchName = "origin/\(branchName)"
        try shell.runWithOutput("git checkout -b \(branchName) \(remoteBranchName)")
        print("✅ Created and switched to local branch '\(branchName)' tracking '\(remoteBranchName)'")
    }
    
    func executeCheckoutWorkflow() throws {
        let remoteBranchNames = try loadRemoteBranchNames()
        
        if remoteBranchNames.isEmpty {
            print("No remote branches found.")
            return
        }
        
        let availableRemoteBranches = try filterNonExistingLocalBranches(remoteBranches: remoteBranchNames)
        
        if availableRemoteBranches.isEmpty {
            print("All remote branches already exist locally.")
            print("Use 'nngit switch-branch --branch-location remote' to switch to existing remote branches.")
            return
        }
        
        let selectedBranchName = try selectRemoteBranch(availableBranches: availableRemoteBranches)
        try checkoutRemoteBranch(branchName: selectedBranchName)
    }
}


// MARK: - Supporting Types
private struct RemoteBranchItem: DisplayablePickerItem {
    let name: String
    
    var displayName: String {
        return name
    }
}