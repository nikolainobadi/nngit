//
//  StageManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import GitShellKit
import SwiftPicker

/// Manager utility for handling file staging workflows and operations.
struct StageManager {
    private let shell: GitShell
    private let picker: CommandLinePicker
    
    init(shell: GitShell, picker: CommandLinePicker) {
        self.shell = shell
        self.picker = picker
    }
}


// MARK: - File Staging Operations
extension StageManager {
    func executeStageWorkflow() throws {
        let allFiles = try loadAllFiles()
        let unstageableFiles = filterUnstageableFiles(allFiles)
        
        guard !unstageableFiles.isEmpty else {
            print("No files available to stage.")
            return
        }
        
        let selectedFiles = selectFilesToStage(unstageableFiles)
        
        guard !selectedFiles.isEmpty else {
            print("No files selected.")
            return
        }
        
        try stageFiles(selectedFiles)
        print("✅ Staged \(selectedFiles.count) file(s)")
    }
}


// MARK: - Private Methods
private extension StageManager {
    func loadAllFiles() throws -> [FileStatus] {
        let gitOutput = try shell.runGitCommandWithOutput(.getLocalChanges, path: nil)
        return FileStatus.parseFromGitStatus(gitOutput)
    }
    
    func filterUnstageableFiles(_ files: [FileStatus]) -> [FileStatus] {
        return files.filter { $0.hasUnstaged || $0.unstagedStatus == .untracked }
    }
    
    func selectFilesToStage(_ files: [FileStatus]) -> [FileStatus] {
        return picker.multiSelection("Select files to stage:", items: files)
    }
    
    func stageFiles(_ files: [FileStatus]) throws {
        for file in files {
            try shell.runWithOutput("git add \"\(file.path)\"")
        }
    }
}