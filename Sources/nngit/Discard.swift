//
//  Discard.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import GitShellKit
import SwiftPicker
import ArgumentParser

enum DiscardFiles: String, ExpressibleByArgument {
    case staged, unstaged, both
}

extension Nngit {
    struct Discard: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Convenience command to discard all local changes in repository"
        )

        @Option(name: .shortAndLong, help: "Which changes to discard: staged, unstaged, or both")
        var files: DiscardFiles = .both

        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            try shell.verifyLocalGitExists()
            
            guard try containsUntrackedFiles(shell: shell) else {
                return print("No changes detected.")
            }
            
            try picker.requiredPermission("Are you sure you want to discard the changes you made in this branch? You cannot undo this action.")
            try discardChanges(for: files, shell: shell)
        }
    }
}

extension Nngit.Discard {
    func containsUntrackedFiles(shell: GitShell) throws -> Bool {
        return try !shell.runGitCommandWithOutput(.getLocalChanges, path: nil).isEmpty
    }

    func discardChanges(for files: DiscardFiles, shell: GitShell) throws {
        switch files {
        case .staged:
            try shell.runGitCommandWithOutput(.clearStagedFiles, path: nil)
        case .unstaged:
            try shell.runGitCommandWithOutput(.clearUnstagedFiles, path: nil)
        case .both:
            try shell.runGitCommandWithOutput(.clearStagedFiles, path: nil)
            try shell.runGitCommandWithOutput(.clearUnstagedFiles, path: nil)
        }
    }
}
