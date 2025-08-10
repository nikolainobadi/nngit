//
//  ListMyBranch.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/10/25.
//

import Foundation
import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit.MyBranches {
    /// Command that lists all branches tracked in MyBranches.
    struct List: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List all branches tracked in your MyBranches list with their descriptions and status."
        )

        @Flag(name: .long, help: "Show detailed information including creation date")
        var detailed: Bool = false

        @Flag(name: .long, help: "Show only branch names without descriptions")
        var namesOnly: Bool = false

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let configLoader = Nngit.makeConfigLoader()
            
            try shell.verifyLocalGitExists()
            
            let config = try configLoader.loadConfig(picker: picker)
            
            if config.myBranches.isEmpty {
                print("No branches are currently tracked in MyBranches.")
                print("Use 'nngit my-branches add' to start tracking branches.")
                return
            }
            
            if namesOnly {
                try listNamesOnly(branches: config.myBranches)
            } else if detailed {
                try listDetailed(branches: config.myBranches, shell: shell)
            } else {
                try listDefault(branches: config.myBranches, shell: shell)
            }
        }
    }
}


// MARK: - Private Methods
private extension Nngit.MyBranches.List {
    /// Lists only branch names
    func listNamesOnly(branches: [MyBranch]) throws {
        print("Tracked MyBranches (\(branches.count)):")
        for branch in branches.sorted(by: { $0.name < $1.name }) {
            print("  \(branch.name)")
        }
    }
    
    /// Lists branches with detailed information
    func listDetailed(branches: [MyBranch], shell: GitShell) throws {
        print("Tracked MyBranches (\(branches.count)):")
        print("")
        
        let branchLoader = Nngit.makeBranchLoader()
        let existingBranches = try branchLoader.loadBranchNames(from: .local, shell: shell)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "* ", with: "") }
        let existingBranchSet = Set(existingBranches)
        
        let currentBranch = try shell.runGitCommandWithOutput(.getCurrentBranchName, path: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .short
        
        for branch in branches.sorted(by: { $0.name < $1.name }) {
            let status = getStatus(branch: branch, currentBranch: currentBranch, existingBranches: existingBranchSet)
            let createdDate = dateFormatter.string(from: branch.createdDate)
            
            print("📋 \(branch.name) \(status)")
            if let description = branch.description, description != branch.name {
                print("   Description: \(description)")
            }
            print("   Added to MyBranches: \(createdDate)")
            print("")
        }
    }
    
    /// Lists branches with default formatting
    func listDefault(branches: [MyBranch], shell: GitShell) throws {
        print("Tracked MyBranches (\(branches.count)):")
        
        let branchLoader = Nngit.makeBranchLoader()
        let existingBranches = try branchLoader.loadBranchNames(from: .local, shell: shell)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "* ", with: "") }
        let existingBranchSet = Set(existingBranches)
        
        let currentBranch = try shell.runGitCommandWithOutput(.getCurrentBranchName, path: nil)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        for branch in branches.sorted(by: { $0.name < $1.name }) {
            let status = getStatus(branch: branch, currentBranch: currentBranch, existingBranches: existingBranchSet)
            
            if let description = branch.description, description != branch.name {
                print("  \(branch.name) - \(description) \(status)")
            } else {
                print("  \(branch.name) \(status)")
            }
        }
    }
    
    /// Gets the status indicator for a branch
    func getStatus(branch: MyBranch, currentBranch: String, existingBranches: Set<String>) -> String {
        if branch.name == currentBranch {
            return "(current)"
        } else if !existingBranches.contains(branch.name) {
            return "(deleted)"
        } else {
            return ""
        }
    }
}
