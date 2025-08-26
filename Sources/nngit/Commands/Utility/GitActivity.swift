//
//  GitActivity.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/26/25.
//

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

        func run() throws {
            let shell = Nngit.makeShell()
            try shell.verifyLocalGitExists()
            
            let manager = GitActivityManager(shell: shell)
            let report = try manager.generateActivityReport(days: days, verbose: verbose)
            print(report)
        }
    }
}
