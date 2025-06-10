//
//  Nngit.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

struct Nngit {
    static let configuration = CommandConfiguration(
        abstract: "A utility for working with Git.",
        subcommands: [
            Discard.self,
            NewBranch.self, SwitchBranch.self, DeleteBranch.self
        ]
    )
    
    nonisolated(unsafe) static var context: NnGitContext = DefaultContext()
}

extension Nngit {
    static func makePicker() -> Picker {
        return context.makePicker()
    }
    
    static func makeShell() -> GitShell {
        return context.makeShell()
    }
}

protocol NnGitContext {
    func makePicker() -> Picker
    func makeShell() -> GitShell
}

struct DefaultContext: NnGitContext {
    func makePicker() -> Picker {
        return SwiftPicker()
    }
    
    func makeShell() -> GitShell {
        return GitShellAdapter()
    }
}
