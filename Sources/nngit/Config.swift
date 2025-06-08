//
//  Config.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import ArgumentParser

extension Nngit {
    struct Config: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "View or update Nngit configuration.",
            subcommands: [
                
            ]
        )
    }
}
