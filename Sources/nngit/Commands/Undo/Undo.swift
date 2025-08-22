//
//  Undo.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/11/25.
//

import ArgumentParser

extension Nngit {
    /// Parent command for undoing commits with different reset strategies.
    struct Undo: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Undo commits using soft or hard reset strategies.",
            subcommands: [Soft.self, HardReset.self],
            defaultSubcommand: Soft.self
        )
    }
}