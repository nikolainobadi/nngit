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
            "true",           // localGitExists
            "/usr/bin/gh",    // which gh  
            "",               // checkForRemote
            "main",           // getCurrentBranchName
            "/Users/test/project", // pwd
            "testuser",       // gh api user
            "",               // gh repo create
            "",               // git remote add
            "",               // git push
            "https://github.com/testuser/project" // getGitHubURL
        ])
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try Nngit.testRun(context: context, args: ["new-remote"])
        
        // Verify the command executed successfully by checking shell calls
        #expect(shell.executedCommands.contains("which gh"))
        #expect(shell.executedCommands.contains("git rev-parse --abbrev-ref HEAD"))
        #expect(shell.executedCommands.contains("gh repo create project --private -d 'Repository created via nngit'"))
        #expect(output.contains("✅ Remote repository created successfully!"))
    }
    
    @Test("Handles error when local git repository doesn't exist.")
    func handlesNoLocalGitError() throws {
        let shell = MockShell(results: ["false"]) // localGitExists returns false
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        #expect(throws: Error.self) {
            _ = try Nngit.testRun(context: context, args: ["new-remote"])
        }
    }
    
    @Test("Handles error when GitHub CLI is not installed.")
    func handlesGitHubCLINotInstalledError() throws {
        let shell = MockShell(results: ["true"], shouldThrowError: true) // First call succeeds, then all throw
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        #expect(throws: Error.self) {
            _ = try Nngit.testRun(context: context, args: ["new-remote"])
        }
    }
    
    @Test("Handles error when remote already exists.")
    func handlesRemoteAlreadyExistsError() throws {
        let shell = MockShell(results: [
            "true",    // localGitExists
            "/usr/bin/gh", // which gh
            "origin"   // checkForRemote returns origin
        ])
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        #expect(throws: NewRemoteError.remoteAlreadyExists) {
            _ = try Nngit.testRun(context: context, args: ["new-remote"])
        }
    }
    
    @Test("Handles user interaction for non-main branch.")
    func handlesNonMainBranchInteraction() throws {
        let shell = MockShell(results: [
            "true",           // localGitExists
            "/usr/bin/gh",    // which gh
            "",               // checkForRemote
            "feature-branch", // getCurrentBranchName
            "/Users/test/project", // pwd
            "testuser",       // gh api user
            "",               // gh repo create
            "",               // git remote add
            "",               // git push
            "https://github.com/testuser/project"
        ])
        let picker = MockPicker(selectionResponses: [
            "Current branch is 'feature-branch', not 'main'. Create remote repository with this branch?": 0
        ]) // "Yes"
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try Nngit.testRun(context: context, args: ["new-remote"])
        
        #expect(shell.executedCommands.contains("git push -u origin feature-branch"))
        #expect(output.contains("✅ Remote repository created successfully!"))
    }
    
    @Test("Handles user cancellation for non-main branch.")
    func handlesUserCancellationForNonMainBranch() throws {
        let shell = MockShell(results: [
            "true",           // localGitExists
            "/usr/bin/gh",    // which gh
            "",               // checkForRemote
            "feature-branch"  // getCurrentBranchName
        ])
        let picker = MockPicker(selectionResponses: [
            "Current branch is 'feature-branch', not 'main'. Create remote repository with this branch?": 1
        ]) // "No"
        let context = MockContext(picker: picker, shell: shell)
        
        #expect(throws: NewRemoteError.userCancelledNonMainBranch) {
            _ = try Nngit.testRun(context: context, args: ["new-remote"])
        }
    }
    
    @Test("Creates public repository when --visibility public is specified.")
    func createsPublicRepositoryWithVisibilityArgument() throws {
        let shell = MockShell(results: [
            "true",           // localGitExists
            "/usr/bin/gh",    // which gh  
            "",               // checkForRemote
            "main",           // getCurrentBranchName
            "/Users/test/project", // pwd
            "testuser",       // gh api user
            "",               // gh repo create
            "",               // git remote add
            "",               // git push
            "https://github.com/testuser/project" // getGitHubURL
        ])
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try Nngit.testRun(context: context, args: ["new-remote", "--visibility", "public"])
        
        #expect(shell.executedCommands.contains("gh repo create project --public -d 'Repository created via nngit'"))
        #expect(output.contains("✅ Remote repository created successfully!"))
    }
    
    @Test("Creates private repository when --visibility private is specified.")
    func createsPrivateRepositoryWithVisibilityArgument() throws {
        let shell = MockShell(results: [
            "true",           // localGitExists
            "/usr/bin/gh",    // which gh  
            "",               // checkForRemote
            "main",           // getCurrentBranchName
            "/Users/test/project", // pwd
            "testuser",       // gh api user
            "",               // gh repo create
            "",               // git remote add
            "",               // git push
            "https://github.com/testuser/project" // getGitHubURL
        ])
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try Nngit.testRun(context: context, args: ["new-remote", "--visibility", "private"])
        
        #expect(shell.executedCommands.contains("gh repo create project --private -d 'Repository created via nngit'"))
        #expect(output.contains("✅ Remote repository created successfully!"))
    }
    
    @Test("Prompts for visibility when no --visibility argument is provided.")
    func promptsForVisibilityWhenNotProvided() throws {
        let shell = MockShell(results: [
            "true",           // localGitExists
            "/usr/bin/gh",    // which gh  
            "",               // checkForRemote
            "main",           // getCurrentBranchName
            "/Users/test/project", // pwd
            "testuser",       // gh api user
            "",               // gh repo create
            "",               // git remote add
            "",               // git push
            "https://github.com/testuser/project" // getGitHubURL
        ])
        let picker = MockPicker(selectionResponses: [
            "Select repository visibility:": 0  // "Private"
        ])
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try Nngit.testRun(context: context, args: ["new-remote"])
        
        #expect(shell.executedCommands.contains("gh repo create project --private -d 'Repository created via nngit'"))
        #expect(output.contains("✅ Remote repository created successfully!"))
    }
}