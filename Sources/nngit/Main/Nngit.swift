//
//  Nngit.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import GitShellKit
import ArgumentParser

/// Entry point for the `nngit` command-line tool.
@main
struct Nngit: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "A utility for working with Git.",
        version: "v0.7.0",
        subcommands: [
            Discard.self, Undo.self, GitActivity.self,
//            BranchDiff.self, CheckoutRemote.self,
            NewBranch.self, SwitchBranch.self, DeleteBranch.self, NewPush.self,
            StopTracking.self,
            EditConfig.self, AddGitFile.self, RegisterGitFile.self, UnregisterGitFile.self, NewGit.self, NewRemote.self
        ]
    )
    
    nonisolated(unsafe) static var context: NnGitContext = DefaultContext()
}


// MARK: - Factory Methods
extension Nngit {
    static func makePicker() -> any GitPicker {
        return context.makePicker()
    }

    static func makeShell() -> any GitShell {
        return context.makeShell()
    }

    static func makeCommitManager() -> any GitCommitManager {
        return context.makeCommitManager()
    }

    static func makeConfigLoader() -> any GitConfigLoader {
        return context.makeConfigLoader()
    }

    static func makeBranchLoader() -> any GitBranchLoader {
        return context.makeBranchLoader()
    }

    static func makeResetHelper() -> any GitResetHelper {
        return context.makeResetHelper()
    }
    
    static func makeFileTracker() -> GitFileTracker {
        return context.makeFileTracker()
    }
    
    static func makeFileCreator() -> any GitFileCreator {
        return context.makeFileCreator()
    }
    
    static func makeFileSystemManager() -> any FileSystemManager {
        return context.makeFileSystemManager()
    }
}
