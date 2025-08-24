//
//  NnGitContext.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/21/25.
//

import GitShellKit
import SwiftPicker

protocol NnGitContext {
    /// Creates the picker used for user interaction.
    func makePicker() -> CommandLinePicker
    /// Creates the shell used for executing git commands.
    func makeShell() -> GitShell
    /// Provides a commit manager for commit related operations.
    func makeCommitManager() -> GitCommitManager
    /// Provides access to the git configuration loader.
    func makeConfigLoader() -> GitConfigLoader
    /// Creates an object capable of loading git branches.
    func makeBranchLoader() -> GitBranchLoader
    /// Creates a helper for git reset operations.
    func makeResetHelper() -> GitResetHelper
    /// Creates a file tracker for managing git tracked files.
    func makeFileTracker() -> GitFileTracker
}
