//
//  NewGitTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import Testing
import Foundation
import SwiftPicker
import GitShellKit
import NnShellKit
@testable import nngit

final class NewGitTests {
}


// MARK: - Tests
@MainActor
extension NewGitTests {
    @Test("Successfully initializes git repository when no git files are configured.")
    func initializeGitWithoutTemplateFiles() throws {
        let configLoader = MockGitConfigLoader()
        let shell = MockShell(results: ["", "Initialized empty Git repository"])
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(
            context: context, 
            args: ["new-git"]
        )
        
        #expect(output.contains("No template files configured"))
        #expect(output.contains("📁 Initialized empty Git repository"))
        #expect(shell.executedCommands.count >= 1)
        #expect(shell.executedCommands.contains("git init"))
    }
}