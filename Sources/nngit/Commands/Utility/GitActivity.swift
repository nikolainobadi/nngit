//
//  GitActivity.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Foundation
import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    struct GitActivity: ParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "activity",
            abstract: "Shows Git activity statistics for the specified number of days (defaults to today)."
        )

        @Option(name: .shortAndLong, help: "Number of days to analyze (default: 1 for today)")
        var days: Int = 1
        
        @Flag(name: .shortAndLong, help: "Show day-by-day breakdown (only allowed when days > 1)")
        var verbose: Bool = false
        
        @Flag(help: "Disable colored output")
        var noColor: Bool = false

        func run() throws {
            let shell = Nngit.makeShell()
            try shell.verifyLocalGitExists()
            
            let manager = GitActivityManager(shell: shell)
            let report = try manager.generateActivityReport(days: days, verbose: verbose)
            
            print("")
            if shouldUseColor {
                print(colorizeOutput(report))
            } else {
                print(report)
            }
            print("")
        }
    }
}


// MARK: - Color Support
private extension Nngit.GitActivity {
    var shouldUseColor: Bool {
        !noColor && ProcessInfo.processInfo.environment["NO_COLOR"] == nil
    }
    
    func colorizeOutput(_ text: String) -> String {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        let colorizedLines = lines.map { line in
            let lineString = String(line)
            
            // Color header line
            if lineString.contains("Git Activity Report") {
                return lineString.replacingOccurrences(
                    of: "Git Activity Report",
                    with: "Git Activity Report".cyan.bold
                )
            }
            
            // Color separator lines
            if lineString.contains("====") {
                return lineString.cyan
            }
            if lineString.contains("----") {
                return lineString.cyan
            }
            
            // Color section headers
            if lineString.contains("Daily Breakdown:") {
                return "Daily Breakdown:".yellow.bold
            }
            
            // Color metric lines
            if lineString.contains("Commits: ") {
                return lineString.replacingOccurrences(
                    of: #"(\d+)"#,
                    with: "$1".green.bold,
                    options: .regularExpression
                )
            }
            if lineString.contains("Files Changed: ") {
                return lineString.replacingOccurrences(
                    of: #"(\d+)"#,
                    with: "$1".green.bold,
                    options: .regularExpression
                )
            }
            if lineString.contains("Lines Added: ") || lineString.contains("Lines Deleted: ") || lineString.contains("Total Lines Modified: ") {
                return lineString.replacingOccurrences(
                    of: #"(\d+)"#,
                    with: "$1".green.bold,
                    options: .regularExpression
                )
            }
            
            // Color daily breakdown lines (dates)
            if lineString.contains(":") && (lineString.contains("commit") || lineString.contains("file")) {
                // Parse the line manually to avoid regex conflicts
                let parts = lineString.components(separatedBy: ": ")
                if parts.count == 2 {
                    let datePart = parts[0].blue.bold
                    let restPart = parts[1]
                        .replacingOccurrences(of: #"(\d+) (commits?)"#, with: "$1".green.bold + " $2", options: .regularExpression)
                        .replacingOccurrences(of: #"(\d+) (files?)"#, with: "$1".green.bold + " $2", options: .regularExpression)
                        .replacingOccurrences(of: #"\+(\d+)"#, with: "+" + "$1".green.bold, options: .regularExpression)
                        .replacingOccurrences(of: #"-(\d+)"#, with: "-" + "$1".green.bold, options: .regularExpression)
                    return datePart + ": " + restPart
                }
            }
            
            return lineString
        }
        
        return colorizedLines.joined(separator: "\n")
    }
}
