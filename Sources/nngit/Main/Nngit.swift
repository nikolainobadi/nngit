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
        version: "0.4.1",
        subcommands: [
            Discard.self, Undo.self, BranchDiff.self,
            NewBranch.self, SwitchBranch.self, DeleteBranch.self, CheckoutRemote.self,
            Staging.self, StopTracking.self,
            EditConfig.self, AddGitFile.self, NewGit.self
        ]
    )
    
    nonisolated(unsafe) static var context: NnGitContext = DefaultContext()
}


// MARK: - Factory Methods
extension Nngit {
    /// Returns the picker used for user interaction. Defaults to ``InteractivePicker``.
    static func makePicker() -> CommandLinePicker {
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

    /// Factory for obtaining the configured ``GitResetHelper`` instance.
    static func makeResetHelper() -> GitResetHelper {
        return context.makeResetHelper()
    }
    
    /// Factory for obtaining the configured ``GitFileTracker`` instance.
    static func makeFileTracker() -> GitFileTracker {
        return context.makeFileTracker()
    }
    
    /// Factory for obtaining the configured ``GitFileCreator`` instance.
    static func makeFileCreator() -> GitFileCreator {
        return context.makeFileCreator()
    }
    
    /// Factory for obtaining the configured ``FileSystemManager`` instance.
    static func makeFileSystemManager() -> FileSystemManager {
        return context.makeFileSystemManager()
    }
}
