//
//  GitFileTracker.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/23/25.
//

import Foundation

/// Protocol for managing Git file tracking operations.
protocol GitFileTracker {
    /// Identifies tracked files that match gitignore patterns.
    ///
    /// - Parameter gitignore: The contents of a gitignore file.
    /// - Returns: Array of file paths that are tracked but should be ignored.
    func loadUnwantedFiles(gitignore: String) -> [String]
    
    /// Stops tracking a file while keeping it in the working directory.
    ///
    /// - Parameter file: The file path to stop tracking.
    /// - Throws: GitShellError if the operation fails.
    func stopTrackingFile(file: String) throws
    
    /// Checks if there are any untracked changes in the repository.
    ///
    /// - Returns: true if there are untracked changes, false otherwise.
    /// - Throws: GitShellError if the operation fails.
    func containsUntrackedFiles() throws -> Bool
}