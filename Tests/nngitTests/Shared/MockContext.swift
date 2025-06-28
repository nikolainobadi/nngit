//
//  MockContext.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/22/25.
//

import SwiftPicker
import GitShellKit
@testable import nngit

final class MockContext {
    private var picker: MockPicker?
    private var shell: MockGitShell?
    private var configLoader: GitConfigLoader?
    private var branchLoader: GitBranchLoaderProtocol?
    
    init(picker: MockPicker? = nil,
         shell: MockGitShell? = nil,
         configLoader: GitConfigLoader? = nil,
         branchLoader: GitBranchLoaderProtocol? = nil) {
        self.picker = picker
        self.shell = shell
        self.configLoader = configLoader
        self.branchLoader = branchLoader
    }
}


// MARK: - Context
extension MockContext: NnGitContext {
    func makePicker() -> Picker {
        if let picker {
            return picker
        }
        
        let newPicker = MockPicker()
        picker = newPicker
        return newPicker
    }
    func makeShell() -> GitShell {
        if let shell {
            return shell
        }
        
        let newShell = MockGitShell(responses: [:])
        shell = newShell
        return newShell
    }
    
    func makeCommitManager() -> GitCommitManager {
        return DefaultGitCommitManager(shell: makeShell())
    }

    func makeConfigLoader() -> GitConfigLoader {
        if let configLoader { return configLoader }
        let loader = DefaultGitConfigLoader()
        configLoader = loader
        return loader
    }
    func makeBranchLoader() -> GitBranchLoaderProtocol {
        if let branchLoader { return branchLoader }
        let loader = GitBranchLoader(shell: makeShell())
        branchLoader = loader
        return loader
    }
}
