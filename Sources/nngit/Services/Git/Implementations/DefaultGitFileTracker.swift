//
//  DefaultGitFileTracker.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/23/25.
//

import Foundation
import GitShellKit

/// Concrete implementation of GitFileTracker for managing Git file tracking operations.
struct DefaultGitFileTracker: GitFileTracker {
    private let shell: GitShell
    
    init(shell: GitShell) {
        self.shell = shell
    }
}


// MARK: - GitFileTracker Implementation
extension DefaultGitFileTracker {
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
private extension DefaultGitFileTracker {
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
        
        // Check for absolute path patterns
        let isAbsolute = pattern.hasPrefix("/")
        if isAbsolute {
            pattern = String(pattern.dropFirst())
        }
        
        // Check for directory patterns
        let isDirectory = pattern.hasSuffix("/")
        if isDirectory {
            pattern = String(pattern.dropLast())
        }
        
        // Convert gitignore pattern to regex
        var regexPattern = ""
        var i = pattern.startIndex
        
        while i < pattern.endIndex {
            let char = pattern[i]
            
            if char == "*" {
                // Check for double asterisk
                let nextIndex = pattern.index(after: i)
                if nextIndex < pattern.endIndex && pattern[nextIndex] == "*" {
                    regexPattern += ".*"
                    i = pattern.index(after: nextIndex)
                } else {
                    regexPattern += "[^/]*"
                    i = nextIndex
                }
            } else if char == "?" {
                regexPattern += "."
                i = pattern.index(after: i)
            } else if char == "." || char == "[" || char == "]" || char == "(" || char == ")" || 
                      char == "{" || char == "}" || char == "^" || char == "$" || 
                      char == "|" || char == "\\" || char == "+" {
                // Escape regex special characters
                regexPattern += "\\\(char)"
                i = pattern.index(after: i)
            } else {
                regexPattern += String(char)
                i = pattern.index(after: i)
            }
        }
        
        // Build final regex based on pattern type
        if isDirectory {
            // Directory patterns match the directory and everything inside
            if isAbsolute {
                regexPattern = "^" + regexPattern + "(/.*)?$"
            } else {
                regexPattern = "(^|.*/)" + regexPattern + "(/.*)?$"
            }
        } else if isAbsolute || pattern.contains("/") {
            // Absolute patterns or patterns with slashes must match from the beginning
            regexPattern = "^" + regexPattern + "$"
        } else {
            // Patterns without slashes can match anywhere in the path
            regexPattern = "(^|.*/)" + regexPattern + "$"
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

