//
//  Nngit.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import ArgumentParser

struct Nngit {
    static let configuration = CommandConfiguration(
        abstract: "A utility for working with Git.",
        subcommands: [
            Discard.self,
            NewBranch.self, SwitchBranch.self, DeleteBranch.self
        ]
    )
}
