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
    @Test("Successfully creates remote repository when all prerequisites are met.")
    func successfulRemoteCreation() throws {
        let results = [
            "true",           // localGitExists check (verifyLocalGitExists)
            "/usr/bin/gh",    // which gh (verifyGitHubCLIInstalled)
            "",               // checkForRemote (verifyNoRemoteExists - empty means no remote)
            "HEAD",           // git rev-parse --verify HEAD (headExists)
            "main",           // getCurrentBranchName
            "/Users/test/project", // pwd (getCurrentDirectoryName)
            "testuser",       // gh api user (getGitHubUsername)
            "",               // gh repo create (addGitHubRemote)
            "",               // git remote add (addGitHubRemote)
            "",               // git push -u origin main (pushCurrentBranch)
            "https://github.com/testuser/project"  // getGitHubURL
        ]
        
        let (sut, shell) = makeSUT(results: results)
        
        try sut.initializeGitHubRemote()
        
        #expect(shell.executedCommands.contains("which gh"))
        #expect(shell.executedCommands.contains("git rev-parse --verify HEAD"))
        #expect(shell.executedCommands.contains("git rev-parse --abbrev-ref HEAD"))
        #expect(shell.executedCommands.contains("pwd"))
        #expect(shell.executedCommands.contains("gh api user --jq '.login'"))
        #expect(shell.executedCommands.contains("gh repo create project --private -d 'Repository created via nngit'"))
        #expect(shell.executedCommands.contains("git remote add origin https://github.com/testuser/project.git"))
        #expect(shell.executedCommands.contains("git push -u origin main"))
    }
    
    @Test("Successfully creates remote repository for fresh repository without HEAD.", .disabled())
    func successfulRemoteCreationWithoutHead() throws {
        let results = [
            "true",           // localGitExists check (verifyLocalGitExists)
            "/usr/bin/gh",    // which gh (verifyGitHubCLIInstalled)
            "",               // checkForRemote (verifyNoRemoteExists - empty means no remote)
            "",               // git rev-parse --verify HEAD (headExists) - empty result means error/no HEAD
            "/Users/test/project", // pwd (getCurrentDirectoryName)
            "testuser",       // gh api user (getGitHubUsername)
            "",               // gh repo create (addGitHubRemote)
            "",               // git remote add (addGitHubRemote)
            "",               // git push -u origin main (pushCurrentBranch)
            "https://github.com/testuser/project"  // getGitHubURL
        ]
        
        let (sut, shell) = makeSUT(results: results)
        
        try sut.initializeGitHubRemote()
        
        #expect(shell.executedCommands.contains("which gh"))
        #expect(shell.executedCommands.contains("git rev-parse --verify HEAD"))
        #expect(!shell.executedCommands.contains("git rev-parse --abbrev-ref HEAD")) // Should NOT be called for fresh repo
        #expect(shell.executedCommands.contains("pwd"))
        #expect(shell.executedCommands.contains("gh api user --jq '.login'"))
        #expect(shell.executedCommands.contains("gh repo create project --private -d 'Repository created via nngit'"))
        #expect(shell.executedCommands.contains("git remote add origin https://github.com/testuser/project.git"))
        #expect(shell.executedCommands.contains("git push -u origin main"))
    }

    @Test("Throws error when local git repository doesn't exist.")
    func throwsErrorWhenNoLocalGit() throws {
        let (sut, _) = makeSUT(results: ["false"]) // localGitExists returns false
        
        #expect(throws: Error.self) {
            try sut.initializeGitHubRemote()
        }
    }
    
    @Test("Throws error when GitHub CLI is not installed.")
    func throwsErrorWhenGitHubCLINotInstalled() throws {
        let (sut, _) = makeSUT(results: ["true"], shouldThrowShellError: true) // First call succeeds via result, then all throw
        
        #expect(throws: Error.self) {
            try sut.initializeGitHubRemote()
        }
    }
    
    @Test("Throws error when remote repository already exists.")
    func throwsErrorWhenRemoteAlreadyExists() throws {
        let (sut, _) = makeSUT(results: [
            "true",    // localGitExists
            "/usr/bin/gh", // which gh
            "origin"   // checkForRemote returns origin
        ])
        
        #expect(throws: NewRemoteError.remoteAlreadyExists) {
            try sut.initializeGitHubRemote()
        }
    }
    
    @Test("Prompts user when current branch is not main.", .disabled())
    func promptsUserForNonMainBranch() throws {
        let selectionResponses = [
            "Current branch is 'feature-branch', not 'main'. Create remote repository with this branch?": 0
        ] // "Yes"
        let results = [
            "true",           // localGitExists
            "/usr/bin/gh",    // which gh
            "",               // checkForRemote (no remote)
            "feature-branch", // getCurrentBranchName (not main)
            "/Users/test/project", // pwd
            "testuser",       // gh api user
            "",               // gh repo create
            "",               // git remote add
            "",               // git push
            "https://github.com/testuser/project"
        ]
        let (sut, shell) = makeSUT(selectionResponses: selectionResponses, results: results)
        
        try sut.initializeGitHubRemote()
        
        #expect(shell.executedCommands.contains("git push -u origin feature-branch"))
    }
    
    @Test("Throws error when user cancels non-main branch creation.", .disabled())
    func throwsErrorWhenUserCancelsNonMainBranch() throws {
        let selectionResponses = [
            "Current branch is 'feature-branch', not 'main'. Create remote repository with this branch?": 1
        ] // "No"
        let results = [
            "true",           // localGitExists
            "/usr/bin/gh",    // which gh
            "",               // checkForRemote
            "feature-branch"  // getCurrentBranchName
        ]
        let (sut, _) = makeSUT(selectionResponses: selectionResponses, results: results)
        
        #expect(throws: NewRemoteError.userCancelledNonMainBranch) {
            try sut.initializeGitHubRemote()
        }
    }
    
    @Test("Throws error when cannot determine directory name.")
    func throwsErrorWhenCannotDetermineDirectoryName() throws {
        let (sut, _) = makeSUT(results: [
            "true",        // localGitExists
            "/usr/bin/gh", // which gh
            "",            // checkForRemote
            "main",        // getCurrentBranchName
            "/"            // pwd - root directory with no name
        ])
        
        #expect(throws: NewRemoteError.cannotDetermineDirectoryName) {
            try sut.initializeGitHubRemote()
        }
    }
    
    @Test("Throws error when cannot get GitHub username.")
    func throwsErrorWhenCannotGetGitHubUsername() throws {
        let (sut, _) = makeSUT(results: [
            "true",                   // localGitExists
            "/usr/bin/gh",           // which gh
            "",                      // checkForRemote
            "main",                  // getCurrentBranchName
            "/Users/test/project"    // pwd
        ], shouldThrowShellError: true) // gh api user will throw
        
        #expect(throws: Error.self) {
            try sut.initializeGitHubRemote()
        }
    }
    
    @Test("Creates public repository when visibility is specified.", .disabled())
    func createsPublicRepositoryWhenVisibilitySpecified() throws {
        let results = [
            "true",           // localGitExists
            "/usr/bin/gh",    // which gh
            "",               // checkForRemote
            "main",           // getCurrentBranchName
            "/Users/test/project", // pwd
            "testuser",       // gh api user
            "",               // gh repo create
            "",               // git remote add
            "",               // git push
            "https://github.com/testuser/project"
        ]
        let (sut, shell) = makeSUT(results: results)
        
        try sut.initializeGitHubRemote(visibility: .publicRepo)
        
        #expect(shell.executedCommands.contains("gh repo create project --public -d 'Repository created via nngit'"))
    }
    
    @Test("Creates private repository when visibility is specified.", .disabled())
    func createsPrivateRepositoryWhenVisibilitySpecified() throws {
        let results = [
            "true",           // localGitExists
            "/usr/bin/gh",    // which gh
            "",               // checkForRemote
            "main",           // getCurrentBranchName
            "/Users/test/project", // pwd
            "testuser",       // gh api user
            "",               // gh repo create
            "",               // git remote add
            "",               // git push
            "https://github.com/testuser/project"
        ]
        let (sut, shell) = makeSUT(results: results)
        
        try sut.initializeGitHubRemote(visibility: .privateRepo)
        
        #expect(shell.executedCommands.contains("gh repo create project --private -d 'Repository created via nngit'"))
    }
    
    @Test("Prompts for visibility when not specified and creates repository accordingly.", .disabled())
    func promptsForVisibilityWhenNotSpecified() throws {
        let selectionResponses = [
            "Select repository visibility:": 1  // "Public"
        ]
        let results = [
            "true",           // localGitExists
            "/usr/bin/gh",    // which gh
            "",               // checkForRemote
            "main",           // getCurrentBranchName
            "/Users/test/project", // pwd
            "testuser",       // gh api user
            "",               // gh repo create
            "",               // git remote add
            "",               // git push
            "https://github.com/testuser/project"
        ]
        let (sut, shell) = makeSUT(selectionResponses: selectionResponses, results: results)
        
        try sut.initializeGitHubRemote()
        
        #expect(shell.executedCommands.contains("gh repo create project --public -d 'Repository created via nngit'"))
    }
    
    @Test("Prompts user to confirm repository details before creation.", .disabled())
    func promptsUserToConfirmRepositoryDetails() throws {
        let results = [
            "true",           // localGitExists
            "/usr/bin/gh",    // which gh
            "",               // checkForRemote
            "main",           // getCurrentBranchName
            "/Users/test/project", // pwd
            "testuser",       // gh api user
            "",               // gh repo create
            "",               // git remote add
            "",               // git push
            "https://github.com/testuser/project"
        ]
        let (sut, picker) = makeSUTWithPicker(results: results)
        
        try sut.initializeGitHubRemote(visibility: .privateRepo)
        
        #expect(picker.requiredPermissions.count == 1)
        let confirmationPrompt = picker.requiredPermissions[0]
        #expect(confirmationPrompt.contains("Repository Details:"))
        #expect(confirmationPrompt.contains("testuser"))
        #expect(confirmationPrompt.contains("project"))
        #expect(confirmationPrompt.contains("main"))
        #expect(confirmationPrompt.contains("Private"))
    }
    
    @Test("Throws error when user denies permission to create repository.", .disabled())
    func throwsErrorWhenUserDeniesPermission() throws {
        let confirmationMessage = """
        📋 Repository Details:
        • GitHub Username: testuser
        • Repository Name: project
        • Current Branch: main
        • Visibility: Private
        
        Create remote repository with these settings?
        """
        let permissionResponses = [
            confirmationMessage: false
        ]
        let results = [
            "true",           // localGitExists
            "/usr/bin/gh",    // which gh
            "",               // checkForRemote
            "main",           // getCurrentBranchName
            "/Users/test/project", // pwd
            "testuser"        // gh api user
        ]
        let (sut, _) = makeSUTWithPicker(permissionResponses: permissionResponses, results: results)
        
        #expect(throws: NewRemoteError.userDeniedPermission) {
            try sut.initializeGitHubRemote(visibility: .privateRepo)
        }
    }
}


// MARK: - SUT
private extension NewRemoteManagerTests {
    func makeSUT(
        permissionResponses: [String: Bool] = [:],
        selectionResponses: [String: Int] = [:],
        results: [String] = [],
        shouldThrowShellError: Bool = false
    ) -> (sut: NewRemoteManager, shell: MockShell) {
        let picker = MockPicker(permissionResponses: permissionResponses, selectionResponses: selectionResponses)
        let shell = MockShell(results: results, shouldThrowError: shouldThrowShellError)
        let sut = NewRemoteManager(shell: shell, picker: picker)
        
        return (sut, shell)
    }
    
    func makeSUTWithPicker(
        permissionResponses: [String: Bool] = [:],
        selectionResponses: [String: Int] = [:],
        results: [String] = [],
        shouldThrowShellError: Bool = false
    ) -> (sut: NewRemoteManager, picker: MockPicker) {
        let picker = MockPicker(permissionResponses: permissionResponses, selectionResponses: selectionResponses)
        let shell = MockShell(results: results, shouldThrowError: shouldThrowShellError)
        let sut = NewRemoteManager(shell: shell, picker: picker)
        
        return (sut, picker)
    }
}
