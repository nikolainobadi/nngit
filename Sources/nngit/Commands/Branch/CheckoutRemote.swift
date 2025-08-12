//
//  CheckoutRemote.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/10/25.
//

import Foundation
import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    /// Command that checks out remote branches authored by the user.
    struct CheckoutRemote: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List and checkout remote branches that you authored which don't exist locally."
        )
        
        @Option(name: .long, parsing: .upToNextOption,
                help: "Additional author names or emails to include when filtering branches")
        var includeAuthor: [String] = []
        
        @Option(name: .long,
                help: "Only show branches created within the last N days (default: 15)")
        var days: Int = 15
        
        @Flag(name: .long,
              help: "Disable date filtering and show all branches regardless of age")
        var noFilter: Bool = false
        
        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let configLoader = Nngit.makeConfigLoader()
            let branchLoader = Nngit.makeBranchLoader()
            
            try shell.verifyLocalGitExists()
            
            let config = try configLoader.loadConfig(picker: picker)
            
            // Load remote branches
            var remoteBranchNames = try branchLoader.loadBranchNames(from: .remote, shell: shell)
            
            // Filter by author (automatically includes current git user)
            remoteBranchNames = branchLoader.filterBranchNamesByAuthor(remoteBranchNames, shell: shell, includeAuthor: includeAuthor)
            
            // Filter by date unless --no-filter flag is used
            if !noFilter {
                remoteBranchNames = branchLoader.filterBranchNamesByDate(remoteBranchNames, shell: shell, withinDays: days)
            }
            
            if remoteBranchNames.isEmpty {
                let message = noFilter 
                    ? "No remote branches found that you authored."
                    : "No remote branches found that you authored within the last \(days) days. Use --no-filter to show all branches."
                print(message)
                return
            }
            
            // Clean up remote branch names (remove origin/ prefix) and filter out existing local branches
            let availableRemoteBranches = try filterNonExistingLocalBranches(
                remoteBranches: remoteBranchNames,
                branchLoader: branchLoader,
                shell: shell
            )
            
            if availableRemoteBranches.isEmpty {
                print("All your remote branches already exist locally.")
                print("Use 'nngit switch-branch --branch-location remote' to switch to existing remote branches.")
                return
            }
            
            // Present branches for selection
            let remoteBranchItems = availableRemoteBranches.map { RemoteBranchItem(name: $0) }
            let selectedBranch = try picker.requiredSingleSelection("Select a remote branch to checkout", items: remoteBranchItems)
            
            // Checkout the branch (creates local tracking branch)
            let branchName = selectedBranch.name
            let remoteBranchName = "origin/\(branchName)"
            
            try shell.runWithOutput("git checkout -b \(branchName) \(remoteBranchName)")
            
            // Add to MyBranches
            let newMyBranch = MyBranch(name: branchName, description: branchName)
            var updatedConfig = config
            updatedConfig.myBranches.append(newMyBranch)
            try configLoader.save(updatedConfig)
            
            print("✅ Created and switched to local branch '\(branchName)' tracking '\(remoteBranchName)'")
            print("📋 Added '\(branchName)' to your MyBranches list.")
        }
        
        /// Filters remote branches to only include those that don't exist locally
        private func filterNonExistingLocalBranches(
            remoteBranches: [String],
            branchLoader: GitBranchLoader,
            shell: GitShell
        ) throws -> [String] {
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
        
        /// Removes origin/ prefix and other remote prefixes from branch names
        private func cleanRemoteBranchName(_ remoteBranch: String) -> String {
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
    }
}

// MARK: - Supporting Types
private struct RemoteBranchItem: DisplayablePickerItem {
    let name: String
    
    var displayName: String {
        return name
    }
}