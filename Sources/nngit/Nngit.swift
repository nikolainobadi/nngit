//
//  Nngit.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

@main
struct Nngit: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A utility for working with Git.",
        subcommands: [
            Discard.self, UndoCommit.self,
            NewBranch.self, SwitchBranch.self, DeleteBranch.self,
            AddBranchPrefix.self, EditBranchPrefix.self, DeleteBranchPrefix.self
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

    static func makeCommitManager() -> GitCommitManager {
        return context.makeCommitManager()
    }
}

protocol NnGitContext {
    func makePicker() -> Picker
    func makeShell() -> GitShell
    func makeCommitManager() -> GitCommitManager
}

struct DefaultContext: NnGitContext {
    func makePicker() -> Picker {
        return SwiftPicker()
    }
    
    func makeShell() -> GitShell {
        return GitShellAdapter()
    }

    func makeCommitManager() -> GitCommitManager {
        return DefaultGitCommitManager(shell: makeShell())
    }
}
