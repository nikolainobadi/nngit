//
//  NewRemoteTests.swift
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
struct NewRemoteTests {
    @Test("Successfully runs NewRemote command.")
    func successfulNewRemoteCommand() throws {
        let shell = MockShell(results: [
            "true",                               // verifyLocalGitExists
            "/usr/bin/gh",                        // which gh
            "",                                   // remoteExists
            "testuser",                           // gh api user
            "/Users/test/project",                // pwd
            "",                                   // gh repo create
            "",                                   // git remote add
            "",                                   // git push
            "https://github.com/testuser/project" // getGitHubURL
        ])
        let picker = MockPicker(
            requiredInputResponses: [
                "Please add a brief description for your new GitHub repository:": "Test project"
            ],
            selectionResponses: [
                "Select repository visibility:": 1 // private
            ]
        )
        let context = MockContext(picker: picker, shell: shell)

        let output = try runCommand(context: context)

        #expect(shell.executedCommands.contains("which gh"))
        #expect(shell.executedCommands.contains("gh api user --jq '.login'"))
        #expect(shell.executedCommands.contains("pwd"))
        #expect(shell.executedCommands.contains("gh repo create project --private -d 'Test project'"))
        #expect(shell.executedCommands.contains("git remote add origin https://github.com/testuser/project.git"))
        #expect(shell.executedCommands.contains("git push -u origin main"))
        #expect(output.contains("📦 Created remote repository: testuser/project"))
        #expect(output.contains("🔗 Added remote origin"))
        #expect(output.contains("✅ Remote repository created successfully!"))
        #expect(output.contains("🔗 GitHub URL: https://github.com/testuser/project"))
    }
    
    @Test("Handles error when local git repository doesn't exist.")
    func handlesNoLocalGitError() throws {
        let shell = MockShell(results: ["false"]) // verifyLocalGitExists returns false
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)

        #expect(throws: Error.self) {
            try runCommand(context: context)
        }
    }
    
    @Test("Handles error when GitHub CLI is not installed.")
    func handlesGitHubCLINotInstalledError() throws {
        let shell = MockShell(results: ["true"], shouldThrowError: true) // First call succeeds, then all throw
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)

        #expect(throws: Error.self) {
            try runCommand(context: context)
        }
    }
    
    @Test("Handles error when remote already exists.")
    func handlesRemoteAlreadyExistsError() throws {
        let shell = MockShell(results: [
            "true",        // verifyLocalGitExists
            "/usr/bin/gh", // which gh
            "origin"       // remoteExists returns origin
        ])
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)

        #expect(throws: NewRemoteError.remoteAlreadyExists) {
            try runCommand(context: context)
        }
    }
    
    @Test("Handles user interaction for non-main branch.")
    func handlesNonMainBranchInteraction() throws {
        // Note: This test is no longer relevant since branch checking was removed
        // but keeping the test structure for consistency
        let shell = MockShell(results: [
            "true",                               // verifyLocalGitExists
            "/usr/bin/gh",                        // which gh
            "",                                   // remoteExists
            "testuser",                           // gh api user
            "/Users/test/project",                // pwd
            "",                                   // gh repo create
            "",                                   // git remote add
            "",                                   // git push
            "https://github.com/testuser/project" // getGitHubURL
        ])
        let picker = MockPicker(
            requiredInputResponses: [
                "Please add a brief description for your new GitHub repository:": "Feature branch project"
            ],
            selectionResponses: [
                "Select repository visibility:": 1 // private
            ]
        )
        let context = MockContext(picker: picker, shell: shell)

        let output = try runCommand(context: context)

        #expect(shell.executedCommands.contains("git push -u origin main"))
        #expect(output.contains("✅ Remote repository created successfully!"))
    }
    
    @Test("Handles user cancellation for non-main branch.")
    func handlesUserCancellationForNonMainBranch() throws {
        // Note: This test is no longer relevant since branch checking was removed
        // but keeping the test structure for consistency with user permission denial
        let confirmationMessage = """
        
        📋 Repository Details:
        • GitHub Username: testuser
        • Repository Name: project
        • Description: Test project
        • Visibility: Private
        
        Create remote repository with these settings?
        """
        let shell = MockShell(results: [
            "true",                    // verifyLocalGitExists
            "/usr/bin/gh",             // which gh
            "",                        // remoteExists
            "testuser",                // gh api user
            "/Users/test/project"      // pwd
        ])
        let picker = MockPicker(
            permissionResponses: [
                confirmationMessage: false
            ],
            requiredInputResponses: [
                "Please add a brief description for your new GitHub repository:": "Test project"
            ]
        )
        let context = MockContext(picker: picker, shell: shell)

        #expect(throws: NewRemoteError.userDeniedPermission) {
            try runCommand(context: context, additionalArgs: ["--visibility", "private"])
        }
    }
    
    @Test("Creates public repository when --visibility public is specified.")
    func createsPublicRepositoryWithVisibilityArgument() throws {
        let shell = MockShell(results: [
            "true",                               // verifyLocalGitExists
            "/usr/bin/gh",                        // which gh
            "",                                   // remoteExists
            "testuser",                           // gh api user
            "/Users/test/project",                // pwd
            "",                                   // gh repo create
            "",                                   // git remote add
            "",                                   // git push
            "https://github.com/testuser/project" // getGitHubURL
        ])
        let picker = MockPicker(
            requiredInputResponses: [
                "Please add a brief description for your new GitHub repository:": "Public test project"
            ]
        )
        let context = MockContext(picker: picker, shell: shell)

        let output = try runCommand(context: context, additionalArgs: ["--visibility", "public"])

        #expect(shell.executedCommands.contains("gh repo create project --public -d 'Public test project'"))
        #expect(output.contains("✅ Remote repository created successfully!"))
    }
    
    @Test("Creates private repository when --visibility private is specified.")
    func createsPrivateRepositoryWithVisibilityArgument() throws {
        let shell = MockShell(results: [
            "true",                               // verifyLocalGitExists
            "/usr/bin/gh",                        // which gh
            "",                                   // remoteExists
            "testuser",                           // gh api user
            "/Users/test/project",                // pwd
            "",                                   // gh repo create
            "",                                   // git remote add
            "",                                   // git push
            "https://github.com/testuser/project" // getGitHubURL
        ])
        let picker = MockPicker(
            requiredInputResponses: [
                "Please add a brief description for your new GitHub repository:": "Private test project"
            ]
        )
        let context = MockContext(picker: picker, shell: shell)

        let output = try runCommand(context: context, additionalArgs: ["--visibility", "private"])

        #expect(shell.executedCommands.contains("gh repo create project --private -d 'Private test project'"))
        #expect(output.contains("✅ Remote repository created successfully!"))
    }
    
    @Test("Prompts for visibility when no --visibility argument is provided.")
    func promptsForVisibilityWhenNotProvided() throws {
        let shell = MockShell(results: [
            "true",                               // verifyLocalGitExists
            "/usr/bin/gh",                        // which gh
            "",                                   // remoteExists
            "testuser",                           // gh api user
            "/Users/test/project",                // pwd
            "",                                   // gh repo create
            "",                                   // git remote add
            "",                                   // git push
            "https://github.com/testuser/project" // getGitHubURL
        ])
        let picker = MockPicker(
            requiredInputResponses: [
                "Please add a brief description for your new GitHub repository:": "Test project"
            ],
            selectionResponses: [
                "Select repository visibility:": 0 // public
            ]
        )
        let context = MockContext(picker: picker, shell: shell)

        let output = try runCommand(context: context)

        #expect(shell.executedCommands.contains("gh repo create project --public -d 'Test project'"))
        #expect(output.contains("✅ Remote repository created successfully!"))
    }
    
    @Test("Throws error when user denies permission to create repository.")
    func throwsErrorWhenUserDeniesPermission() throws {
        let confirmationMessage = """
        
        📋 Repository Details:
        • GitHub Username: testuser
        • Repository Name: project
        • Description: Test project
        • Visibility: Private
        
        Create remote repository with these settings?
        """
        let shell = MockShell(results: [
            "true",                    // verifyLocalGitExists
            "/usr/bin/gh",             // which gh
            "",                        // remoteExists
            "testuser",                // gh api user
            "/Users/test/project"      // pwd
        ])
        let picker = MockPicker(
            permissionResponses: [
                confirmationMessage: false
            ],
            requiredInputResponses: [
                "Please add a brief description for your new GitHub repository:": "Test project"
            ]
        )
        let context = MockContext(picker: picker, shell: shell)

        #expect(throws: NewRemoteError.userDeniedPermission) {
            try runCommand(context: context, additionalArgs: ["--visibility", "private"])
        }
    }
}


// MARK: - Run
private extension NewRemoteTests {
    @discardableResult
    func runCommand(context: MockContext, additionalArgs: [String] = []) throws -> String {
        return try Nngit.testRun(context: context, args: ["new-remote"] + additionalArgs)
    }
}