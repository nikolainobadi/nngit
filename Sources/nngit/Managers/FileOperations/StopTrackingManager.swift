//
//  StopTrackingManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/23/25.
//

import Foundation
import GitShellKit
import SwiftPicker

/// Manager for handling stop tracking workflows and operations.
struct StopTrackingManager {
    private let shell: GitShell
    private let picker: CommandLinePicker
    private let tracker: GitFileTracker
    
    init(shell: GitShell, picker: CommandLinePicker, tracker: GitFileTracker) {
        self.shell = shell
        self.picker = picker
        self.tracker = tracker
    }
}


// MARK: - Stop Tracking Operations
extension StopTrackingManager {
    func stopTrackingIgnoredFiles() throws {
        // Verify git repository exists
        try shell.verifyLocalGitExists()
        
        // Check for gitignore file
        let gitignorePath = ".gitignore"
        guard FileManager.default.fileExists(atPath: gitignorePath) else {
            print("No .gitignore file found in the current directory.")
            return
        }
        
        // Read gitignore contents
        let gitignoreContents = try String(contentsOfFile: gitignorePath, encoding: .utf8)
        
        // Get files that should not be tracked
        let unwantedFiles = tracker.loadUnwantedFiles(gitignore: gitignoreContents)
        
        guard !unwantedFiles.isEmpty else {
            print("No tracked files match the gitignore patterns.")
            return
        }
        
        // Display count and prompt user
        print("Found \(unwantedFiles.count) file(s) that match gitignore patterns but are still tracked.")
        
        let selectedOption = promptUserForAction()
        
        switch selectedOption {
        case .stopAll:
            try stopTrackingFiles(unwantedFiles)
            
        case .selectSpecific:
            let selectedFiles = selectFilesToStopTracking(unwantedFiles)
            
            guard !selectedFiles.isEmpty else {
                print("No files selected.")
                return
            }
            
            try stopTrackingFiles(selectedFiles)
            
        case .cancel:
            print("Operation cancelled.")
            return
        }
    }
}


// MARK: - Private Methods
private extension StopTrackingManager {
    enum UserAction {
        case stopAll
        case selectSpecific
        case cancel
    }
    
    func promptUserForAction() -> UserAction {
        let options = [
            "Stop tracking all files",
            "Select specific files to stop tracking",
            "Cancel"
        ]
        
        let selectedOption = picker.singleSelection("What would you like to do?", items: options)
        
        switch selectedOption {
        case "Stop tracking all files":
            return .stopAll
        case "Select specific files to stop tracking":
            return .selectSpecific
        case "Cancel":
            return .cancel
        default:
            return .cancel
        }
    }
    
    func selectFilesToStopTracking(_ files: [String]) -> [String] {
        return picker.multiSelection("Select files to stop tracking:", items: files)
    }
    
    func stopTrackingFiles(_ files: [String]) throws {
        print("Stopping tracking for \(files.count) file(s)...")
        
        var successCount = 0
        var failures: [(String, Error)] = []
        
        for file in files {
            do {
                try tracker.stopTrackingFile(file: file)
                print("  ✓ Stopped tracking: \(file)")
                successCount += 1
            } catch {
                print("  ✗ Failed to stop tracking \(file): \(error.localizedDescription)")
                failures.append((file, error))
            }
        }
        
        // Display final results
        if successCount > 0 {
            print("\n✅ Successfully stopped tracking \(successCount) file(s)")
        }
        
        if !failures.isEmpty {
            print("❌ Failed to stop tracking \(failures.count) file(s)")
        }
        
        if successCount > 0 {
            print("\nNote: The files have been removed from tracking but remain in your working directory.")
            print("Remember to commit these changes to apply them to the repository.")
        }
    }
}