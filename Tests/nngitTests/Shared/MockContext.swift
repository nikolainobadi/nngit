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
    
    init(picker: MockPicker? = nil, shell: MockGitShell? = nil) {
        self.picker = picker
        self.shell = shell
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
}
