//
//  GitFileTracker.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/23/25.
//

import Foundation
import GitShellKit

struct GitFileTracker {
    private let shell: GitShell
    
    init(shell: GitShell) {
        self.shell = shell
    }
}


// MARK: - Actions
extension GitFileTracker {
    func loadUnwantedFiles(gitignore: String) -> [String] {
        let trackedFiles = loadTrackedFiles()
        let ignorePatterns = parseGitignorePatterns(gitignore)
        
        return trackedFiles.filter { file in
            ignorePatterns.contains { pattern in
                matchesGitignorePattern(file: file, pattern: pattern)
            }
        }
    }
    
    func stopTrackingFile(file: String) throws {
        try shell.runWithOutput("git rm --cached \"\(file)\"")
    }
    
    func containsUntrackedFiles() throws -> Bool {
        return try !shell.runGitCommandWithOutput(.getLocalChanges, path: nil).isEmpty
    }
}


// MARK: - Private Methods
private extension GitFileTracker {
    func loadTrackedFiles() -> [String] {
        do {
            let trackedFileOutput = try shell.runWithOutput("git ls-files")
            return trackedFileOutput.split(separator: "\n").map({ String($0) })
        } catch {
            return []
        }
    }
    
    func parseGitignorePatterns(_ gitignore: String) -> [String] {
        gitignore.split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty && !$0.hasPrefix("#") }
    }
    
    func matchesGitignorePattern(file: String, pattern: String) -> Bool {
        var pattern = pattern
        
        // Handle negation patterns
        if pattern.hasPrefix("!") {
            return false
        }
        
        // Remove leading slash for absolute path patterns
        if pattern.hasPrefix("/") {
            pattern = String(pattern.dropFirst())
        }
        
        // Convert gitignore pattern to regex
        var regexPattern = NSRegularExpression.escapedPattern(for: pattern)
        
        // Replace escaped wildcards with regex equivalents
        regexPattern = regexPattern.replacingOccurrences(of: "\\\\\\*\\\\\\*", with: ".*")
        regexPattern = regexPattern.replacingOccurrences(of: "\\\\\\*", with: "[^/]*")
        regexPattern = regexPattern.replacingOccurrences(of: "\\\\\\?", with: ".")
        
        // Handle directory patterns (ending with /)
        if pattern.hasSuffix("/") {
            regexPattern = "^" + regexPattern + ".*"
        } else if pattern.contains("/") {
            // Patterns with slashes must match from the beginning
            regexPattern = "^" + regexPattern + "$"
        } else {
            // Patterns without slashes can match anywhere
            regexPattern = "(^|.*/)?" + regexPattern + "$"
        }
        
        do {
            let regex = try NSRegularExpression(pattern: regexPattern, options: [])
            let range = NSRange(location: 0, length: file.utf16.count)
            return regex.firstMatch(in: file, options: [], range: range) != nil
        } catch {
            return false
        }
    }
}

