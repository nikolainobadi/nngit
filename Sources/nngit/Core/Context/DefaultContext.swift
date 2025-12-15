//
//  DefaultContext.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/21/25.
//

import GitShellKit
import SwiftPickerKit

struct DefaultContext: NnGitContext {
    func makeShell() -> any GitShell {
        return GitShellAdapter()
    }
    
    func makePicker() -> any GitPicker {
        return SwiftPicker()
    }

    func makeCommitManager() -> any GitCommitManager {
        return DefaultGitCommitManager(shell: makeShell())
    }

    func makeConfigLoader() -> any GitConfigLoader {
        return DefaultGitConfigLoader(picker: makePicker())
    }

    func makeBranchLoader() -> any GitBranchLoader {
        return DefaultGitBranchLoader(shell: makeShell())
    }

    func makeResetHelper() -> any GitResetHelper {
        return DefaultGitResetHelper(manager: makeCommitManager(), picker: makePicker())
    }
    
    func makeFileTracker() -> GitFileTracker {
        return GitFileTracker(shell: makeShell())
    }
    
    func makeFileCreator() -> any GitFileCreator {
        return DefaultGitFileCreator()
    }
    
    func makeFileSystemManager() -> any FileSystemManager {
        return DefaultFileSystemManager()
    }
}


// MARK: - Extension Dependencies
extension SwiftPicker: GitPicker { }
