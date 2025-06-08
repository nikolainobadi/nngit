//
//  DeleteBranch.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import ArgumentParser

extension Nngit {
    struct DeleteBranch: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Lists all available local branches, deletes the selected branches, and prunes the remote origin if one exists."
        )
        
        func run() throws {
            
        }
    }
}
