//
//  StopTracking.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/23/25.
//

import Foundation
import ArgumentParser
import GitShellKit
import SwiftPicker

/// Command to stop tracking files that match gitignore patterns.
struct StopTracking: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Stop tracking files that match gitignore patterns"
    )
    
    func run() throws {
        let shell = Nngit.makeShell()
        let picker = Nngit.makePicker()
        let tracker = Nngit.makeFileTracker()
        
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
        
        let options = [
            "Stop tracking all files",
            "Select specific files to stop tracking",
            "Cancel"
        ]
        
        let selectedOption = picker.singleSelection("What would you like to do?", items: options)
        
        switch selectedOption {
        case "Stop tracking all files":
            try stopTrackingFiles(unwantedFiles, tracker: tracker)
            
        case "Select specific files to stop tracking":
            let selectedFiles = picker.multiSelection(
                "Select files to stop tracking:",
                items: unwantedFiles
            )
            
            guard !selectedFiles.isEmpty else {
                print("No files selected.")
                return
            }
            
            try stopTrackingFiles(selectedFiles, tracker: tracker)
            
        case "Cancel":
            print("Operation cancelled.")
            return
            
        default:
            break
        }
    }
    
    private func stopTrackingFiles(_ files: [String], tracker: GitFileTracker) throws {
        print("Stopping tracking for \(files.count) file(s)...")
        
        for file in files {
            do {
                try tracker.stopTrackingFile(file: file)
                print("  ✓ Stopped tracking: \(file)")
            } catch {
                print("  ✗ Failed to stop tracking \(file): \(error.localizedDescription)")
            }
        }
        
        print("\n✅ Successfully stopped tracking \(files.count) file(s)")
        print("\nNote: The files have been removed from tracking but remain in your working directory.")
        print("Remember to commit these changes to apply them to the repository.")
    }
}