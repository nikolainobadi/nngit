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

@MainActor
struct NewGitTests {
    @Test("Successfully initializes git repository when no git files are configured.")
    func initializeGitWithoutTemplateFiles() throws {
        let configLoader = MockGitConfigLoader()
        let shell = MockShell(results: ["", "Initialized empty Git repository"])
        let picker = MockPicker(permissionResponses: [
            "Would you like to create a GitHub remote repository for this project?": false
        ])
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
    
    @Test("Creates GitHub remote when user accepts prompt after git initialization.")
    func createsGitHubRemoteWhenUserAccepts() throws {
        let configLoader = MockGitConfigLoader()
        let shell = MockShell(results: [
            "", "Initialized empty Git repository",  // git init results
            "true",           // localGitExists (for NewRemoteManager)
            "/usr/bin/gh",    // which gh
            "",               // checkForRemote
            "main",           // getCurrentBranchName
            "/Users/test/project", // pwd
            "testuser",       // gh api user
            "",               // gh repo create
            "",               // git remote add
            "",               // git push
            "https://github.com/testuser/project"
        ])
        let confirmationMessage = """
        📋 Repository Details:
        • GitHub Username: testuser
        • Repository Name: project
        • Current Branch: main
        • Visibility: Private
        
        Create remote repository with these settings?
        """
        let picker = MockPicker(
            permissionResponses: [
                "Would you like to create a GitHub remote repository for this project?": true,
                confirmationMessage: true
            ],
            selectionResponses: ["Select repository visibility:": 0] // Private
        )
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(
            context: context, 
            args: ["new-git"]
        )
        
        #expect(output.contains("📁 Initialized empty Git repository"))
        #expect(output.contains("✅ Remote repository created successfully!"))
        #expect(shell.executedCommands.contains("git init"))
        #expect(shell.executedCommands.contains("which gh"))
    }
}
