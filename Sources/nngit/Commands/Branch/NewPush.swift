//
//  NewPush.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import GitShellKit
import ArgumentParser

extension Nngit {
    struct NewPush: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Pushes current branch to remote repository and sets upstream tracking when no upstream branch exists."
        )

        func run() throws {
            let shell = Nngit.makeShell()
            let picker = Nngit.makePicker()
            let configLoader = Nngit.makeConfigLoader()
            
            try shell.verifyLocalGitExists()
            
            let manager = NewPushManager(shell: shell, picker: picker, configLoader: configLoader)
            try manager.pushNewBranch()
        }
    }
}
