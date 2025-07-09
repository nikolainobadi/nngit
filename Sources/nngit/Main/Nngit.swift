//
//  Nngit.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import SwiftPicker
import GitShellKit
import ArgumentParser

/// Entry point for the `nngit` command-line tool.
@main
struct Nngit: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A utility for working with Git.",
        version: "0.3.6",
        subcommands: [
            Discard.self, UndoCommit.self, BranchDiff.self,
            NewBranch.self, SwitchBranch.self, DeleteBranch.self,
            AddBranchPrefix.self, EditBranchPrefix.self, DeleteBranchPrefix.self, ListBranchPrefix.self,
            EditConfig.self
        ]
    )
    
    nonisolated(unsafe) static var context: NnGitContext = DefaultContext()
}

extension Nngit {
    /// Returns the picker used for user interaction. Defaults to ``SwiftPicker``.
    static func makePicker() -> Picker {
        return context.makePicker()
    }

    /// Returns the shell used for executing git commands.
    static func makeShell() -> GitShell {
        return context.makeShell()
    }

    /// Factory for obtaining the configured ``GitCommitManager`` instance.
    static func makeCommitManager() -> GitCommitManager {
        return context.makeCommitManager()
    }

    /// Returns the loader responsible for reading and saving git configuration.
    static func makeConfigLoader() -> GitConfigLoader {
        return context.makeConfigLoader()
    }

    /// Abstraction for branch loading so it can be mocked in tests.
    static func makeBranchLoader() -> GitBranchLoader {
        return context.makeBranchLoader()
    }
}

protocol NnGitContext {
    /// Creates the picker used for user interaction.
    func makePicker() -> Picker
    /// Creates the shell used for executing git commands.
    func makeShell() -> GitShell
    /// Provides a commit manager for commit related operations.
    func makeCommitManager() -> GitCommitManager
    /// Provides access to the git configuration loader.
    func makeConfigLoader() -> GitConfigLoader
    /// Creates an object capable of loading git branches.
    func makeBranchLoader() -> GitBranchLoader
}

struct DefaultContext: NnGitContext {
    /// Default implementation returning ``SwiftPicker``.
    func makePicker() -> Picker {
        return SwiftPicker()
    }
    
    /// Default implementation returning ``GitShellAdapter``.
    func makeShell() -> GitShell {
        return GitShellAdapter()
    }

    /// Default ``GitCommitManager`` based on the shell from ``makeShell()``.
    func makeCommitManager() -> GitCommitManager {
        return DefaultGitCommitManager(shell: makeShell())
    }

    /// Returns a loader for the application's git configuration.
    func makeConfigLoader() -> GitConfigLoader {
        return DefaultGitConfigLoader()
    }

    /// Provides the default branch loader for the repository.
    func makeBranchLoader() -> GitBranchLoader {
        return DefaultGitBranchLoader(shell: makeShell())
    }
}
