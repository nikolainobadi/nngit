//
//  MockContext.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/22/25.
//

import SwiftPicker
import GitShellKit
import NnShellKit
@testable import nngit

final class MockContext {
    private var picker: MockPicker?
    private var shell: MockShell?
    private var configLoader: GitConfigLoader?
    private var branchLoader: GitBranchLoader?
    private var resetHelper: GitResetHelper?
    
    init(picker: MockPicker? = nil,
         shellResults: [String] = [],
         configLoader: GitConfigLoader? = nil,
         branchLoader: GitBranchLoader? = nil,
         resetHelper: GitResetHelper? = nil) {
        self.picker = picker
        self.shell = shellResults.isEmpty ? nil : MockShell(results: shellResults)
        self.configLoader = configLoader
        self.branchLoader = branchLoader
        self.resetHelper = resetHelper
    }
}


// MARK: - Context
extension MockContext: NnGitContext {
    func makePicker() -> CommandLinePicker {
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
        
        let newShell = MockShell(results: [])
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
    
    func makeBranchLoader() -> GitBranchLoader {
        if let branchLoader { return branchLoader }
        let loader = DefaultGitBranchLoader(shell: makeShell())
        branchLoader = loader
        return loader
    }
    
    func makeResetHelper() -> GitResetHelper {
        if let resetHelper { return resetHelper }
        let helper = MockGitResetHelper()
        resetHelper = helper
        return helper
    }
}

// MARK: - Test Access
extension MockContext {
    var mockShell: MockShell? {
        return shell
    }
}
