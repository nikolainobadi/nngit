//
//  UnstageManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import GitShellKit
import SwiftPicker

/// Manager utility for handling file unstaging workflows and operations.
struct UnstageManager {
    private let shell: GitShell
    private let picker: CommandLinePicker
    
    init(shell: GitShell, picker: CommandLinePicker) {
        self.shell = shell
        self.picker = picker
    }
}


// MARK: - File Unstaging Operations
extension UnstageManager {
    func executeUnstageWorkflow() throws {
        let allFiles = try loadAllFiles()
        let stagedFiles = filterStagedFiles(allFiles)
        
        guard !stagedFiles.isEmpty else {
            print("No staged files to unstage.")
            return
        }
        
        let selectedFiles = selectFilesToUnstage(stagedFiles)
        
        guard !selectedFiles.isEmpty else {
            print("No files selected.")
            return
        }
        
        try unstageFiles(selectedFiles)
        print("✅ Unstaged \(selectedFiles.count) file(s)")
    }
}


// MARK: - Private Methods
private extension UnstageManager {
    func loadAllFiles() throws -> [FileStatus] {
        let gitOutput = try shell.runGitCommandWithOutput(.getLocalChanges, path: nil)
        return FileStatus.parseFromGitStatus(gitOutput)
    }
    
    func filterStagedFiles(_ files: [FileStatus]) -> [FileStatus] {
        return files.filter { $0.hasStaged }
    }
    
    func selectFilesToUnstage(_ files: [FileStatus]) -> [FileStatus] {
        return picker.multiSelection("Select files to unstage:", items: files)
    }
    
    func unstageFiles(_ files: [FileStatus]) throws {
        for file in files {
            try shell.runWithOutput("git reset HEAD \"\(file.path)\"")
        }
    }
}