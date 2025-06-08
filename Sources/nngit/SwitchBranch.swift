//
//  SwitchBranch.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import ArgumentParser

extension Nngit {
    struct SwitchBranch: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Lists all local branches, allows selecting a branch to switch."
        )
        
        func run() throws {
            
        }
    }
}
