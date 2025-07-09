//
//  Discard.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import GitShellKit
import SwiftPicker
import ArgumentParser

/// Represents which scope of changes to discard when running the ``Discard`` command.
enum DiscardScope: String, ExpressibleByArgument {
    case staged, unstaged, both
}

extension Nngit {
    /// Command used for discarding local changes from the working tree.
    struct Discard: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Convenience command to discard all local changes in repository"
        )

        @Option(name: .shortAndLong, help: "Which scope of changes to discard: staged, unstaged, or both")
        var scope: DiscardScope = .both

        @Flag(name: .long, help: "Select specific files to discard (interactive mode)")
        var files: Bool = false

        /// Executes the command using the shared context components.
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            try shell.verifyLocalGitExists()
            
            guard try containsUntrackedFiles(shell: shell) else {
                return print("No changes detected.")
            }
            
            if files {
                try handleFileSelection(shell: shell, picker: picker)
            } else {
                try picker.requiredPermission("Are you sure you want to discard the changes you made in this branch? You cannot undo this action.")
                try discardChanges(for: scope, shell: shell)
            }
        }
    }
}

extension Nngit.Discard {
    /// Returns `true` if there are uncommitted changes in the repository.
    func containsUntrackedFiles(shell: GitShell) throws -> Bool {
        return try !shell.runGitCommandWithOutput(.getLocalChanges, path: nil).isEmpty
    }

    /// Removes local changes according to the selected ``DiscardScope`` option.
    func discardChanges(for scope: DiscardScope, shell: GitShell) throws {
        switch scope {
        case .staged:
            try shell.runGitCommandWithOutput(.clearStagedFiles, path: nil)
        case .unstaged:
            try shell.runGitCommandWithOutput(.clearUnstagedFiles, path: nil)
        case .both:
            try shell.runGitCommandWithOutput(.clearStagedFiles, path: nil)
            try shell.runGitCommandWithOutput(.clearUnstagedFiles, path: nil)
        }
    }
    
    /// Handles file selection mode for discarding specific files.
    func handleFileSelection(shell: GitShell, picker: Picker) throws {
        let gitOutput = try shell.runGitCommandWithOutput(.getLocalChanges, path: nil)
        let allFiles = FileStatus.parseFromGitStatus(gitOutput)
        
        // Filter files based on scope
        let filteredFiles = filterFilesByScope(allFiles, scope: scope)
        
        guard !filteredFiles.isEmpty else {
            print("No files match the selected scope.")
            return
        }
        
        let selectedFiles = picker.multiSelection("Select files to discard changes from:", items: filteredFiles)
        
        guard !selectedFiles.isEmpty else {
            print("No files selected.")
            return
        }
        
        try picker.requiredPermission("Are you sure you want to discard changes in \(selectedFiles.count) selected file(s)? You cannot undo this action.")
        
        for file in selectedFiles {
            try discardFileChanges(file, shell: shell)
        }
        
        print("✅ Discarded changes in \(selectedFiles.count) file(s)")
    }
    
    /// Filters files based on the selected scope.
    func filterFilesByScope(_ files: [FileStatus], scope: DiscardScope) -> [FileStatus] {
        switch scope {
        case .staged:
            return files.filter { $0.hasStaged }
        case .unstaged:
            return files.filter { $0.hasUnstaged }
        case .both:
            return files
        }
    }
    
    /// Discards changes for a specific file based on its status.
    func discardFileChanges(_ file: FileStatus, shell: GitShell) throws {
        // Handle staged changes
        if file.hasStaged && (scope == .staged || scope == .both) {
            try shell.runWithOutput("git reset HEAD \"\(file.path)\"")
        }
        
        // Handle unstaged changes
        if file.hasUnstaged && (scope == .unstaged || scope == .both) {
            if file.unstagedStatus == .untracked {
                try shell.runWithOutput("git clean -f \"\(file.path)\"")
            } else {
                try shell.runWithOutput("git checkout -- \"\(file.path)\"")
            }
        }
    }
}
