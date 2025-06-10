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
    struct SwitchBranch: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Lists all local branches, allows selecting a branch to switch."
        )
        
        func run() throws {
            let picker = SwiftPicker()
            let shell = GitShellAdapter()
            let branchLoader = GitBranchLoader(shell: shell)
            let branchList = try branchLoader.loadLocalBranches(shell: shell)
            let currentBranch = branchList.first(where: { $0.isCurrentBranch })
            let otherBranches = branchList.filter({ !$0.isCurrentBranch})
            
            var details = ""
            
            if let currentBranch {
                details = "(switching from \(currentBranch.name)"
            }
            
            let selectedBranch = try picker.requiredSingleSelection("Select a branch \(details)", items: otherBranches)
            
            try shell.runGitCommandWithOutput(.switchBranch(branchName: selectedBranch.name), path: nil)
        }
    }
}

extension GitBranch: DisplayablePickerItem {
    var displayName: String {
        return name
    }
}
