//
//  DefaultContext.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/21/25.
//

import GitShellKit
import SwiftPicker

struct DefaultContext: NnGitContext {
    /// Default implementation returning ``InteractivePicker``.
    func makePicker() -> CommandLinePicker {
        return InteractivePicker()
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

    /// Default ``GitResetHelper`` based on the manager and picker.
    func makeResetHelper() -> GitResetHelper {
        return DefaultGitResetHelper(
            manager: makeCommitManager(),
            picker: makePicker()
        )
    }
    
    /// Default ``GitFileTracker`` based on the shell from ``makeShell()``.
    func makeFileTracker() -> GitFileTracker {
        return DefaultGitFileTracker(shell: makeShell())
    }
    
    /// Default ``GitFileCreator`` for managing template files.
    func makeFileCreator() -> GitFileCreator {
        return DefaultGitFileCreator()
    }
}
