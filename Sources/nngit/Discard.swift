//
//  Discard.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import GitShellKit
import SwiftPicker
import ArgumentParser

extension Nngit {
    struct Discard: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Convenience command to discard all local changes in repository"
        )
        
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            try shell.verifyLocalGitExists()
            
            guard try containsUntrackedFiles(shell: shell) else {
                return print("No changes detected.")
            }
            
            try picker.requiredPermission("Are you sure you want to discard the changes you made in this branch? You cannot undo this action.")
            try discardAllChanges(shell: shell)
        }
    }
}

extension Nngit.Discard {
    func containsUntrackedFiles(shell: GitShell) throws -> Bool {
        return try !shell.runGitCommandWithOutput(.getLocalChanges, path: nil).isEmpty
    }
    
    func discardAllChanges(shell: GitShell) throws{
        try shell.runGitCommandWithOutput(.clearStagedFiles, path: nil)
        try shell.runGitCommandWithOutput(.clearUnstagedFiles, path: nil)
    }
}
