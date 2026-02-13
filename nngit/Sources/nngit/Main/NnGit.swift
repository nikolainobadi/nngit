//
//  NnGit.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import ArgumentParser

@main
struct NnGit: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Git utilities",
        version: "0.1.0",
        subcommands: []
    )

    nonisolated(unsafe) static var contextFactory: ContextFactory = DefaultContextFactory()
}

// MARK: - Factory Access
extension NnGit {
    static func makeShell() -> any NnGitShell {
        return contextFactory.makeShell()
    }

    static func makePicker() -> any NnGitPicker {
        return contextFactory.makePicker()
    }
}
