//
//  CheckoutRemote.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/10/25.
//

import Foundation
import SwiftPicker
import GitShellKit
import ArgumentParser

extension Nngit {
    /// Command that checks out remote branches.
    struct CheckoutRemote: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "List and checkout remote branches that don't exist locally."
        )
        
        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            try shell.verifyLocalGitExists()
            let branchLoader = Nngit.makeBranchLoader()
            let manager = CheckoutRemoteManager(shell: shell, picker: picker, branchLoader: branchLoader)
            
            try manager.checkoutRemote()
        }
    }
}
