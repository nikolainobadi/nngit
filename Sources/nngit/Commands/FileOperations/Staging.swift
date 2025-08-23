//
//  Staging.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/10/25.
//

import ArgumentParser

extension Nngit {
    /// Parent command for managing file staging operations.
    struct Staging: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Manage file staging operations for preparing commits.",
            subcommands: [Stage.self, Unstage.self],
            defaultSubcommand: Stage.self
        )
    }
}