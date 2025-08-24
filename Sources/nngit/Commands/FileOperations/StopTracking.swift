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
        let shell = Nngit.makeShell()
        
        let manager = StopTrackingManager(
            shell: shell,
            picker: Nngit.makePicker(),
            tracker: Nngit.makeFileTracker()
        )
        
        try manager.stopTrackingIgnoredFiles()
    }
}