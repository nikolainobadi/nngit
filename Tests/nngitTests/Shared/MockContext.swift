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
    let picker: MockPicker
    let shell: MockGitShell
    
    init(picker: MockPicker = MockPicker(), shell: MockGitShell = MockGitShell(responses: [:])) {
        self.picker = picker
        self.shell = shell
    }
}


// MARK: - Context
extension MockContext: NnGitContext {
    func makePicker() -> Picker { picker }
    func makeShell() -> GitShell { shell }
    func makeCommitManager() -> GitCommitManager { DefaultGitCommitManager(shell: shell) }
}
