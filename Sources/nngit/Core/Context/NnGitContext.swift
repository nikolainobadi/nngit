//
//  NnGitContext.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/21/25.
//

import GitShellKit

protocol NnGitContext {
    func makeShell() -> any GitShell
    func makePicker() -> any GitPicker
    func makeFileTracker() -> GitFileTracker
    func makeFileCreator() -> any GitFileCreator
    func makeResetHelper() -> any GitResetHelper
    func makeConfigLoader() -> any GitConfigLoader
    func makeBranchLoader() -> any GitBranchLoader
    func makeCommitManager() -> any GitCommitManager
    func makeFileSystemManager() -> any FileSystemManager
}
