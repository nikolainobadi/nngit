//
//  MyBranches.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/10/25.
//

import ArgumentParser

extension Nngit {
    /// Parent command for managing tracked MyBranches.
    struct MyBranches: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Manage your tracked branches for easier switching and deletion.",
            subcommands: [List.self],
            defaultSubcommand: List.self
        )
    }
}
