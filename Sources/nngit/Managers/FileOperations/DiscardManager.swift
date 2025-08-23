//
//  DiscardManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Foundation
import GitShellKit
import SwiftPicker

/// Manager utility for handling discard workflows and operations.
struct DiscardManager {
    private let shell: GitShell
    private let picker: CommandLinePicker
    
    init(shell: GitShell, picker: CommandLinePicker) {
        self.shell = shell
        self.picker = picker
    }
}


// MARK: - Discard Operations
extension DiscardManager {
    func performDiscard(scope: DiscardScope, files: Bool) throws {
        guard try containsChanges() else {
            print("No changes detected.")
            return
        }
        
        if files {
            try handleFileSelection(scope: scope)
        } else {
            try handleFullDiscard(scope: scope)
        }
    }
}


// MARK: - Private Methods
private extension DiscardManager {
    func containsChanges() throws -> Bool {
        return try !shell.runGitCommandWithOutput(.getLocalChanges, path: nil).isEmpty
    }
    
    func handleFullDiscard(scope: DiscardScope) throws {
        try picker.requiredPermission("Are you sure you want to discard the changes you made in this branch? You cannot undo this action.")
        try discardChanges(for: scope)
    }
    
    func discardChanges(for scope: DiscardScope) throws {
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
    
    func handleFileSelection(scope: DiscardScope) throws {
        let gitOutput = try shell.runGitCommandWithOutput(.getLocalChanges, path: nil)
        let allFiles = FileStatus.parseFromGitStatus(gitOutput)
        
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
            try discardFileChanges(file, scope: scope)
        }
        
        print("✅ Discarded changes in \(selectedFiles.count) file(s)")
    }
    
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
    
    func discardFileChanges(_ file: FileStatus, scope: DiscardScope) throws {
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