//
//  StopTracking.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/23/25.
//

import ArgumentParser

/// Command to stop tracking files that match gitignore patterns.
struct StopTracking: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Stop tracking files that match gitignore patterns"
    )
    
    func run() throws {
        let manager = StopTrackingManager(
            shell: Nngit.makeShell(),
            picker: Nngit.makePicker(),
            tracker: Nngit.makeFileTracker()
        )
        
        try manager.stopTrackingIgnoredFiles()
    }
}