//
//  NewRemoteManagerTests.swift
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

struct NewRemoteManagerTests {
    @Test("Successfully creates remote repository with provided visibility.")
    func successfulRemoteCreationWithProvidedVisibility() throws {
        let shellResults = [
            "true",                               // verifyLocalGitExists
            "/usr/bin/gh",                        // which gh
            "",                                   // remoteExists (empty means no remote)
            "testuser",                           // gh api user
            "/Users/test/project",                // pwd
            "",                                   // gh repo create
            "",                                   // git remote add
            "",                                   // git push
            "https://github.com/testuser/project" // getGitHubURL
        ]
        let inputResponses = [
            "Please add a brief description for your new GitHub repository:": "Test description"
        ]
        let (sut, shell, picker) = makeSUT(
            shellResults: shellResults,
            inputResponses: inputResponses
        )
        
        try sut.initializeGitHubRemote(visibility: .privateRepo)
        
        #expect(shell.executedCommands.contains("which gh"))
        #expect(shell.executedCommands.contains("gh api user --jq '.login'"))
        #expect(shell.executedCommands.contains("pwd"))
        #expect(shell.executedCommands.contains("gh repo create project --private -d 'Test description'"))
        #expect(shell.executedCommands.contains("git remote add origin https://github.com/testuser/project.git"))
        #expect(shell.executedCommands.contains("git push -u origin main"))
        #expect(picker.requiredPermissions.count == 1)
        #expect(picker.requiredPermissions[0].contains("Test description"))
    }
    
    @Test("Successfully creates public repository when visibility is selected.")
    func successfulPublicRepositoryCreation() throws {
        let shellResults = [
            "true",                               // verifyLocalGitExists
            "/usr/bin/gh",                        // which gh
            "",                                   // remoteExists
            "testuser",                           // gh api user
            "/Users/test/myapp",                  // pwd
            "",                                   // gh repo create
            "",                                   // git remote add
            "",                                   // git push
            "https://github.com/testuser/myapp"   // getGitHubURL
        ]
        let inputResponses = [
            "Please add a brief description for your new GitHub repository:": "My awesome app"
        ]
        let selectionResponses = [
            "Select repository visibility:": 0    // publicRepo appears to be at index 0
        ]
        let (sut, shell, _) = makeSUT(
            shellResults: shellResults,
            inputResponses: inputResponses,
            selectionResponses: selectionResponses
        )
        
        try sut.initializeGitHubRemote()
        
        #expect(shell.executedCommands.contains("gh repo create myapp --public -d 'My awesome app'"))
        #expect(shell.executedCommands.contains("git remote add origin https://github.com/testuser/myapp.git"))
    }
    
    @Test("Prompts for visibility when not provided.")
    func promptsForVisibilitySelection() throws {
        let shellResults = [
            "true",                               // verifyLocalGitExists
            "/usr/bin/gh",                        // which gh
            "",                                   // remoteExists
            "testuser",                           // gh api user
            "/Users/test/project",                // pwd
            "",                                   // gh repo create
            "",                                   // git remote add
            "",                                   // git push
            "https://github.com/testuser/project" // getGitHubURL
        ]
        let inputResponses = [
            "Please add a brief description for your new GitHub repository:": ""
        ]
        let selectionResponses = [
            "Select repository visibility:": 1    // privateRepo appears to be at index 1
        ]
        let (sut, shell, _) = makeSUT(
            shellResults: shellResults,
            inputResponses: inputResponses,
            selectionResponses: selectionResponses
        )
        
        try sut.initializeGitHubRemote()
        
        #expect(shell.executedCommands.contains("gh repo create project --private -d ''"))
    }
    
    @Test("Throws error when local git repository doesn't exist.")
    func throwsErrorWhenNoLocalGit() throws {
        let shellResults = ["false"]  // verifyLocalGitExists returns false
        let (sut, _, _) = makeSUT(shellResults: shellResults)
        
        #expect(throws: Error.self) {
            try sut.initializeGitHubRemote()
        }
    }
    
    @Test("Throws error when GitHub CLI is not installed.")
    func throwsErrorWhenGitHubCLINotInstalled() throws {
        let shellResults = ["true"]  // verifyLocalGitExists
        let (sut, _, _) = makeSUT(shellResults: shellResults, shouldThrowShellError: true)
        
        #expect(throws: Error.self) {
            try sut.initializeGitHubRemote()
        }
    }
    
    @Test("Throws error when remote repository already exists.")
    func throwsErrorWhenRemoteAlreadyExists() throws {
        let shellResults = [
            "true",        // verifyLocalGitExists
            "/usr/bin/gh", // which gh
            "origin"       // remoteExists returns origin
        ]
        let (sut, _, _) = makeSUT(shellResults: shellResults)
        
        #expect(throws: NewRemoteError.remoteAlreadyExists) {
            try sut.initializeGitHubRemote()
        }
    }
    
    @Test("Throws error when cannot determine directory name.")
    func throwsErrorWhenCannotDetermineDirectoryName() throws {
        let shellResults = [
            "true",        // verifyLocalGitExists
            "/usr/bin/gh", // which gh
            "",            // remoteExists
            "testuser",    // gh api user
            "/"            // pwd returns root (no directory name)
        ]
        let inputResponses = [
            "Please add a brief description for your new GitHub repository:": "Test"
        ]
        let (sut, _, _) = makeSUT(
            shellResults: shellResults,
            inputResponses: inputResponses
        )
        
        #expect(throws: NewRemoteError.cannotDetermineDirectoryName) {
            try sut.initializeGitHubRemote(visibility: .privateRepo)
        }
    }
    
    @Test("Throws error when cannot get GitHub username.")
    func throwsErrorWhenCannotGetGitHubUsername() throws {
        let shellResults = [
            "true",        // verifyLocalGitExists
            "/usr/bin/gh", // which gh
            ""             // remoteExists
        ]
        let (sut, _, _) = makeSUT(shellResults: shellResults, shouldThrowShellError: true)
        
        #expect(throws: Error.self) {
            try sut.initializeGitHubRemote()
        }
    }
    
    @Test("Throws error when user denies permission to create repository.")
    func throwsErrorWhenUserDeniesPermission() throws {
        let shellResults = [
            "true",                    // verifyLocalGitExists
            "/usr/bin/gh",             // which gh
            "",                        // remoteExists
            "testuser",                // gh api user
            "/Users/test/project"      // pwd
        ]
        let inputResponses = [
            "Please add a brief description for your new GitHub repository:": "Test description"
        ]
        let confirmationMessage = """
        
        📋 Repository Details:
        • GitHub Username: testuser
        • Repository Name: project
        • Description: Test description
        • Visibility: Private
        
        Create remote repository with these settings?
        """
        let permissionResponses = [
            confirmationMessage: false
        ]
        let (sut, _, _) = makeSUT(
            shellResults: shellResults,
            inputResponses: inputResponses,
            permissionResponses: permissionResponses
        )
        
        #expect(throws: NewRemoteError.userDeniedPermission) {
            try sut.initializeGitHubRemote(visibility: .privateRepo)
        }
    }
    
    @Test("Properly formats repository details in confirmation prompt.")
    func properlyFormatsConfirmationPrompt() throws {
        let shellResults = [
            "true",                               // verifyLocalGitExists
            "/usr/bin/gh",                        // which gh
            "",                                   // remoteExists
            "myusername",                         // gh api user
            "/Users/test/awesome-project",        // pwd
            "",                                   // gh repo create
            "",                                   // git remote add
            "",                                   // git push
            "https://github.com/myusername/awesome-project"
        ]
        let inputResponses = [
            "Please add a brief description for your new GitHub repository:": "An awesome project!"
        ]
        let (sut, _, picker) = makeSUT(
            shellResults: shellResults,
            inputResponses: inputResponses
        )
        
        try sut.initializeGitHubRemote(visibility: .publicRepo)
        
        #expect(picker.requiredPermissions.count == 1)
        let prompt = picker.requiredPermissions[0]
        #expect(prompt.contains("myusername"))
        #expect(prompt.contains("awesome-project"))
        #expect(prompt.contains("An awesome project!"))
        #expect(prompt.contains("Public"))
    }
    
    @Test("Handles empty description input.")
    func handlesEmptyDescription() throws {
        let shellResults = [
            "true",                               // verifyLocalGitExists
            "/usr/bin/gh",                        // which gh
            "",                                   // remoteExists
            "testuser",                           // gh api user
            "/Users/test/project",                // pwd
            "",                                   // gh repo create
            "",                                   // git remote add
            "",                                   // git push
            "https://github.com/testuser/project" // getGitHubURL
        ]
        let inputResponses = [
            "Please add a brief description for your new GitHub repository:": ""
        ]
        let (sut, shell, _) = makeSUT(
            shellResults: shellResults,
            inputResponses: inputResponses
        )
        
        try sut.initializeGitHubRemote(visibility: .privateRepo)
        
        #expect(shell.executedCommands.contains("gh repo create project --private -d ''"))
    }
    
    @Test("Trims whitespace from GitHub username.")
    func trimsWhitespaceFromUsername() throws {
        let shellResults = [
            "true",                               // verifyLocalGitExists
            "/usr/bin/gh",                        // which gh
            "",                                   // remoteExists
            "  testuser  \n",                     // gh api user (with whitespace)
            "/Users/test/project",                // pwd
            "",                                   // gh repo create
            "",                                   // git remote add
            "",                                   // git push
            "https://github.com/testuser/project" // getGitHubURL
        ]
        let inputResponses = [
            "Please add a brief description for your new GitHub repository:": "Test"
        ]
        let (sut, _, picker) = makeSUT(
            shellResults: shellResults,
            inputResponses: inputResponses
        )
        
        try sut.initializeGitHubRemote(visibility: .privateRepo)
        
        // Check that the confirmation prompt has the trimmed username
        #expect(picker.requiredPermissions.count == 1)
        let prompt = picker.requiredPermissions[0]
        #expect(prompt.contains("• GitHub Username: testuser"))
        #expect(!prompt.contains("  testuser  "))
    }
}


// MARK: - SUT
private extension NewRemoteManagerTests {
    func makeSUT(
        shellResults: [String] = [],
        inputResponses: [String: String] = [:],
        permissionResponses: [String: Bool] = [:],
        selectionResponses: [String: Int] = [:],
        shouldThrowShellError: Bool = false
    ) -> (sut: NewRemoteManager, shell: MockShell, picker: MockPicker) {
        let shell = MockShell(results: shellResults, shouldThrowError: shouldThrowShellError)
        let picker = MockPicker(
            permissionResponses: permissionResponses,
            requiredInputResponses: inputResponses,
            selectionResponses: selectionResponses
        )
        let sut = NewRemoteManager(shell: shell, picker: picker)
        
        return (sut, shell, picker)
    }
}