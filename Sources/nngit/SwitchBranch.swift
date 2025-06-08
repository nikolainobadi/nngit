//
//  SwitchBranch.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    struct SwitchBranch: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Lists all local branches, allows selecting a branch to switch."
        )
        
        func run() throws {
            let picker = SwiftPicker()
            let shell = GitShellAdapter()
            let branchList = try loadLocalBranches(shell: shell)
            let currentBranch = branchList.first(where: { $0.isCurrentBranch })
            let otherBranches = branchList.filter({ !$0.isCurrentBranch})
            
            var details = ""
            
            if let currentBranch {
                details = "(switching from \(currentBranch.name)"
            }
            
            let selectedBranch = try picker.requiredSingleSelection("Select a branch \(details)", items: otherBranches)
            let _ = try shell.runWithOutput(makeGitCommand(.switchBranch(selectedBranch.name), path: nil))
        }
    }
}

extension Nngit.SwitchBranch {
    func loadLocalBranches(shell: GitShell) throws -> [GitBranch] {
        try shell.verifyLocalGitExists()
        
        return []
    }
    
    func loadBranchNames(shell: GitShell) throws -> [String] {
        let output = try shell.runWithOutput(makeGitCommand(.listLocalBranches, path: nil))
        
        return output
            .split(separator: "\n")
            .map({ $0.trimmingCharacters(in: .whitespaces) })
    }
}

extension GitBranch: DisplayablePickerItem {
    var displayName: String {
        return name
    }
}
