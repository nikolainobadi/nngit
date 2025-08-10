//
//  RemoveMyBranch.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/10/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    /// Command that allows removing branches from the tracked MyBranches list.
    struct RemoveMyBranch: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Remove branches from your tracked MyBranches list without deleting the actual git branch."
        )

        @Argument(help: "Name of the branch to remove from MyBranches")
        var branchName: String?

        @Flag(name: .long, help: "Remove all MyBranches")
        var all: Bool = false

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let configLoader = Nngit.makeConfigLoader()
            
            try shell.verifyLocalGitExists()
            
            var config = try configLoader.loadConfig(picker: picker)
            
            if config.myBranches.isEmpty {
                print("No branches are currently tracked in MyBranches.")
                return
            }
            
            if all {
                try removeAllMyBranches(config: &config, configLoader: configLoader)
            } else if let branchName = branchName {
                try removeSpecificMyBranch(branchName: branchName, config: &config, configLoader: configLoader)
            } else {
                try selectAndRemoveMyBranches(picker: picker, config: &config, configLoader: configLoader)
            }
        }
        
        /// Removes all MyBranches
        private func removeAllMyBranches(config: inout GitConfig, configLoader: GitConfigLoader) throws {
            let count = config.myBranches.count
            config.myBranches.removeAll()
            try configLoader.save(config)
            
            print("✅ Removed all \(count) branches from MyBranches.")
        }
        
        /// Removes a specific branch from MyBranches
        private func removeSpecificMyBranch(branchName: String, config: inout GitConfig, configLoader: GitConfigLoader) throws {
            guard let index = config.myBranches.firstIndex(where: { $0.name == branchName }) else {
                print("❌ Branch '\(branchName)' is not tracked in MyBranches.")
                return
            }
            
            config.myBranches.remove(at: index)
            try configLoader.save(config)
            
            print("✅ Removed branch '\(branchName)' from MyBranches.")
        }
        
        /// Prompts user to select MyBranches to remove
        private func selectAndRemoveMyBranches(picker: Picker, config: inout GitConfig, configLoader: GitConfigLoader) throws {
            let selectedBranches = picker.multiSelection("Select MyBranches to remove from tracking", items: config.myBranches)
            
            if selectedBranches.isEmpty {
                print("No branches selected.")
                return
            }
            
            // Remove selected branches
            let selectedNames = Set(selectedBranches.map { $0.name })
            config.myBranches.removeAll { selectedNames.contains($0.name) }
            
            try configLoader.save(config)
            let branchNames = selectedBranches.map { $0.name }
            print("✅ Removed \(branchNames.count) branches from MyBranches: \(branchNames.joined(separator: ", "))")
        }
    }
}