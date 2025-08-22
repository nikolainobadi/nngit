//
//  SoftResetTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import GitShellKit
import NnShellKit
@testable import nngit

@MainActor
struct SoftResetTests {
    @Test("Soft resets specified number of commits")
    func softResetsSpecifiedCommits() throws {
        // Setup mock reset helper with initialization parameters
        let commitInfo = [
            CommitInfo(hash: "abc123", message: "Test commit 1", author: "Test User", date: "1 hour ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "def456", message: "Test commit 2", author: "Test User", date: "2 hours ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "ghi789", message: "Test commit 3", author: "Test User", date: "3 hours ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "jkl012", message: "Test commit 4", author: "Test User", date: "4 hours ago", wasAuthoredByCurrentUser: true)
        ]
        let mockResetHelper = MockGitResetHelper(
            prepareResetResult: commitInfo,
            verifyAuthorPermissionsResult: true
        )
        
        // Setup mock shell for the actual reset command
        let shell = MockShell(results: [""])
        let context = MockContext(shell: shell, resetHelper: mockResetHelper)
        
        try runCommand(context, number: 1)
        
        // Verify the reset helper was called with correct parameters
        #expect(mockResetHelper.prepareResetCount == 1)
        #expect(mockResetHelper.displayCommitsAction == "moved back to staging area")
        #expect(mockResetHelper.verifyAuthorPermissionsForce == false)
        #expect(mockResetHelper.confirmResetCount == 1)
        #expect(mockResetHelper.confirmResetType == "soft")
        
        // Verify the actual reset command was executed
        #expect(shell.executedCommands.contains("git reset --soft HEAD~1"))
    }
    
    @Test("Soft resets multiple commits")
    func softResetsMultipleCommits() throws {
        let shellResults = [
            "Test User",                    // git config user.name
            "test@example.com",             // git config user.email
            "abc123 - Test commit 1 (Test User <test@example.com>, 2 hours ago)\ndef456 - Test commit 2 (Test User <test@example.com>, 3 hours ago)\nghi789 - Test commit 3 (Test User <test@example.com>, 4 hours ago)",  // git log
            ""                              // git reset --soft HEAD~3
        ]
        
        let picker = MockPicker(permissionResponses: [
            "Are you sure you want to soft reset 3 commit(s)? The changes will be moved to staging area.": true
        ])
        let shell = MockShell(results: shellResults)
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context, number: 3)
        
        #expect(shell.executedCommands.contains("git reset --soft HEAD~3"))
    }
    
    @Test("Requires force flag for commits by other authors")
    func requiresForceForOtherAuthors() throws {
        let shellResults = [
            "Test User",                    // git config user.name (called by DefaultGitCommitManager)
            "test@example.com",             // git config user.email (called by DefaultGitCommitManager)
            "abc123 - Test commit 1 (Test User <test@example.com>, 2 hours ago)\ndef456 - Test commit 2 (Other User <other@example.com>, 3 hours ago)",  // git log (called by DefaultGitCommitManager)
            ""                              // Should not reach git reset because verifyAuthorPermissions should block it
        ]
        
        let picker = MockPicker()
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)
        
        try runCommand(context, number: 2, force: false)
        
        // Should not execute soft reset without force flag when commits by other authors are present
        #expect(!shell.executedCommands.contains("git reset --soft HEAD~2"))
        #expect(!picker.requiredPermissions.contains("Are you sure you want to soft reset 2 commit(s)? The changes will be moved to staging area."))
    }
    
    @Test("Allows soft reset with force flag for other authors")
    func allowsSoftResetWithForceForOtherAuthors() throws {
        let shellResults = [
            "Test User",                    // git config user.name
            "test@example.com",             // git config user.email  
            "abc123 - Test commit 1 (Test User <test@example.com>, 2 hours ago)\ndef456 - Test commit 2 (Other User <other@example.com>, 3 hours ago)",  // git log
            ""                              // git reset --soft HEAD~2
        ]
        
        let picker = MockPicker(permissionResponses: [
            "Are you sure you want to soft reset 2 commit(s)? The changes will be moved to staging area.": true
        ])
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)
        
        try runCommand(context, number: 2, force: true)
        
        #expect(shell.executedCommands.contains("git reset --soft HEAD~2"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to soft reset 2 commit(s)? The changes will be moved to staging area."))
    }
    
    @Test("Validates number is greater than zero")
    func validatesNumberGreaterThanZero() throws {
        let picker = MockPicker()
        let shell = MockShell(results: [])
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context, number: 0)
        
        // Should not execute any git commands with invalid number
        #expect(!shell.executedCommands.contains("git config user.name"))
        #expect(!shell.executedCommands.contains("git reset --soft HEAD~0"))
    }
    
    @Test("Handles permission denial")
    func handlesPermissionDenial() throws {
        let shellResults = [
            "Test User",                    // git config user.name
            "test@example.com",             // git config user.email
            "abc123 - Test commit (Test User <test@example.com>, 2 hours ago)"  // git log
        ]
        
        let picker = MockPicker(permissionResponses: [
            "Are you sure you want to soft reset 1 commit(s)? The changes will be moved to staging area.": false
        ])
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)
        
        do {
            try runCommand(context, number: 1)
            #expect(Bool(false), "Expected permission denied error")
        } catch {
            // Expected to throw due to permission denial
            #expect(!shell.executedCommands.contains("git reset --soft HEAD~1"))
        }
    }
    
    // MARK: - Selection Mode Tests
    
    @Test("Selects first commit in selection mode")
    func selectsFirstCommitInSelectionMode() throws {
        let commitInfo = [
            CommitInfo(hash: "abc123", message: "Test commit 1", author: "Test User", date: "1 hour ago", wasAuthoredByCurrentUser: true)
        ]
        let mockResetHelper = MockGitResetHelper(
            selectCommitForResetResult: (count: 1, commits: commitInfo),
            verifyAuthorPermissionsResult: true
        )
        
        let picker = MockPicker(permissionResponses: [
            "Are you sure you want to soft reset 1 commit(s)? The changes will be moved to staging area.": true
        ])
        let shell = MockShell(results: [""])
        let context = MockContext(picker: picker, shell: shell, resetHelper: mockResetHelper)
        
        try runCommand(context, select: true)
        
        #expect(mockResetHelper.displayCommitsAction == "moved back to staging area")
        #expect(mockResetHelper.verifyAuthorPermissionsForce == false)
        #expect(mockResetHelper.confirmResetCount == 1)
        #expect(mockResetHelper.confirmResetType == "soft")
        #expect(shell.executedCommands.contains("git reset --soft HEAD~1"))
    }
    
    @Test("Selects middle commit in selection mode")
    func selectsMiddleCommitInSelectionMode() throws {
        let commitInfo = [
            CommitInfo(hash: "jkl012", message: "Test commit 4", author: "Test User", date: "4 hours ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "ghi789", message: "Test commit 3", author: "Test User", date: "3 hours ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "def456", message: "Test commit 2", author: "Test User", date: "2 hours ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "abc123", message: "Test commit 1", author: "Test User", date: "1 hour ago", wasAuthoredByCurrentUser: true)
        ]
        let mockResetHelper = MockGitResetHelper(
            selectCommitForResetResult: (count: 4, commits: commitInfo),
            verifyAuthorPermissionsResult: true
        )
        
        let picker = MockPicker(permissionResponses: [
            "Are you sure you want to soft reset 4 commit(s)? The changes will be moved to staging area.": true
        ])
        let shell = MockShell(results: [""])
        let context = MockContext(picker: picker, shell: shell, resetHelper: mockResetHelper)
        
        try runCommand(context, select: true)
        
        #expect(shell.executedCommands.contains("git reset --soft HEAD~4"))
    }
    
    @Test("Selects last available commit in selection mode")
    func selectsLastAvailableCommitInSelectionMode() throws {
        let commitInfo = (1...7).map { i in
            CommitInfo(hash: "hash\(i)", message: "Test commit \(i)", author: "Test User", date: "\(i) hours ago", wasAuthoredByCurrentUser: true)
        }
        let mockResetHelper = MockGitResetHelper(
            selectCommitForResetResult: (count: 7, commits: commitInfo),
            verifyAuthorPermissionsResult: true
        )
        
        let picker = MockPicker(permissionResponses: [
            "Are you sure you want to soft reset 7 commit(s)? The changes will be moved to staging area.": true
        ])
        let shell = MockShell(results: [""])
        let context = MockContext(picker: picker, shell: shell, resetHelper: mockResetHelper)
        
        try runCommand(context, select: true)
        
        #expect(shell.executedCommands.contains("git reset --soft HEAD~7"))
    }
    
    // MARK: - Selection Integration Tests
    
    @Test("Selection mode works with force flag for other authors")
    func selectionModeWorksWithForceFlagForOtherAuthors() throws {
        let commitInfo = [
            CommitInfo(hash: "def456", message: "Test commit 2", author: "Other User", date: "2 hours ago", wasAuthoredByCurrentUser: false),
            CommitInfo(hash: "abc123", message: "Test commit 1", author: "Test User", date: "1 hour ago", wasAuthoredByCurrentUser: true)
        ]
        let mockResetHelper = MockGitResetHelper(
            selectCommitForResetResult: (count: 2, commits: commitInfo),
            verifyAuthorPermissionsResult: true
        )
        
        let picker = MockPicker(permissionResponses: [
            "Are you sure you want to soft reset 2 commit(s)? The changes will be moved to staging area.": true
        ])
        let shell = MockShell(results: [""])
        let context = MockContext(picker: picker, shell: shell, resetHelper: mockResetHelper)
        
        try runCommand(context, force: true, select: true)
        
        #expect(mockResetHelper.verifyAuthorPermissionsForce == true)
        #expect(shell.executedCommands.contains("git reset --soft HEAD~2"))
    }
    
    @Test("Selection mode respects author validation")
    func selectionModeRespectsAuthorValidation() throws {
        let commitInfo = [
            CommitInfo(hash: "def456", message: "Test commit 2", author: "Other User", date: "2 hours ago", wasAuthoredByCurrentUser: false),
            CommitInfo(hash: "abc123", message: "Test commit 1", author: "Test User", date: "1 hour ago", wasAuthoredByCurrentUser: true)
        ]
        let mockResetHelper = MockGitResetHelper(
            selectCommitForResetResult: (count: 2, commits: commitInfo),
            verifyAuthorPermissionsResult: false  // Permission denied due to other author
        )
        
        let picker = MockPicker()
        let shell = MockShell(results: [""])
        let context = MockContext(picker: picker, shell: shell, resetHelper: mockResetHelper)
        
        try runCommand(context, select: true)
        
        // Should not execute soft reset without force flag when other authors are present
        #expect(mockResetHelper.verifyAuthorPermissionsForce == false)
        #expect(mockResetHelper.confirmResetCount == nil)  // Should not reach confirmation
        #expect(!shell.executedCommands.contains("git reset --soft HEAD~2"))
    }
    
    @Test("Selection mode handles permission denial", .disabled())
    func selectionModeHandlesPermissionDenial() throws {
        let commitInfo = [
            CommitInfo(hash: "ghi789", message: "Test commit 3", author: "Test User", date: "3 hours ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "def456", message: "Test commit 2", author: "Test User", date: "2 hours ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "abc123", message: "Test commit 1", author: "Test User", date: "1 hour ago", wasAuthoredByCurrentUser: true)
        ]
        let mockResetHelper = MockGitResetHelper(
            selectCommitForResetResult: (count: 3, commits: commitInfo),
            verifyAuthorPermissionsResult: true
        )
        
        let picker = MockPicker(permissionResponses: [
            "Are you sure you want to soft reset 3 commit(s)? The changes will be moved to staging area.": false
        ])
        let shell = MockShell(results: [""])
        let context = MockContext(picker: picker, shell: shell, resetHelper: mockResetHelper)
        
        do {
            try runCommand(context, select: true)
            #expect(Bool(false), "Expected permission denied error")
        } catch {
            // Expected to throw due to permission denial in the actual implementation
            // The MockGitResetHelper doesn't throw, but the real helper does
            #expect(!shell.executedCommands.contains("git reset --soft HEAD~3"))
        }
    }
    
    // MARK: - Edge Case Tests
    
    @Test("Selection mode handles empty commit history")
    func selectionModeHandlesEmptyCommitHistory() throws {
        let mockResetHelper = MockGitResetHelper(
            selectCommitForResetResult: nil  // No commits selected
        )
        
        let picker = MockPicker()
        let shell = MockShell(results: [""])
        let context = MockContext(picker: picker, shell: shell, resetHelper: mockResetHelper)
        
        try runCommand(context, select: true)
        
        // Should not execute any reset commands with empty commit history
        #expect(mockResetHelper.confirmResetCount == nil)
        #expect(!shell.executedCommands.contains { $0.contains("git reset --soft") })
        #expect(picker.requiredPermissions.isEmpty)
    }
    
    @Test("Selection mode with insufficient commits")
    func selectionModeWithInsufficientCommits() throws {
        let commitInfo = [
            CommitInfo(hash: "def456", message: "Test commit 2", author: "Test User", date: "2 hours ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "abc123", message: "Test commit 1", author: "Test User", date: "1 hour ago", wasAuthoredByCurrentUser: true)
        ]
        let mockResetHelper = MockGitResetHelper(
            selectCommitForResetResult: (count: 2, commits: commitInfo),
            verifyAuthorPermissionsResult: true
        )
        
        let picker = MockPicker(permissionResponses: [
            "Are you sure you want to soft reset 2 commit(s)? The changes will be moved to staging area.": true
        ])
        let shell = MockShell(results: [""])
        let context = MockContext(picker: picker, shell: shell, resetHelper: mockResetHelper)
        
        try runCommand(context, select: true)
        
        // Should work correctly even with fewer than 7 commits
        #expect(shell.executedCommands.contains("git reset --soft HEAD~2"))
    }
    
    // MARK: - Argument Validation Tests
    
    @Test("Selection mode ignores number argument")
    func selectionModeIgnoresNumberArgument() throws {
        let commitInfo = [
            CommitInfo(hash: "ghi789", message: "Test commit 3", author: "Test User", date: "3 hours ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "def456", message: "Test commit 2", author: "Test User", date: "2 hours ago", wasAuthoredByCurrentUser: true),
            CommitInfo(hash: "abc123", message: "Test commit 1", author: "Test User", date: "1 hour ago", wasAuthoredByCurrentUser: true)
        ]
        let mockResetHelper = MockGitResetHelper(
            selectCommitForResetResult: (count: 3, commits: commitInfo),
            verifyAuthorPermissionsResult: true
        )
        
        let picker = MockPicker(permissionResponses: [
            "Are you sure you want to soft reset 3 commit(s)? The changes will be moved to staging area.": true
        ])
        let shell = MockShell(results: [""])
        let context = MockContext(picker: picker, shell: shell, resetHelper: mockResetHelper)
        
        // Pass number argument 5, but it should be ignored in select mode
        try runCommand(context, number: 5, select: true)
        
        // Should use selection (3) not the number argument (5)
        #expect(shell.executedCommands.contains("git reset --soft HEAD~3"))
        #expect(!shell.executedCommands.contains("git reset --soft HEAD~5"))
    }
}


// MARK: - Helper Methods
private extension SoftResetTests {
    private func runCommand(_ testFactory: NnGitContext, number: Int = 1, force: Bool = false, select: Bool = false) throws {
        var args = ["undo", "soft", "\(number)"]
        
        if force {
            args.append("--force")
        }
        
        if select {
            args.append("--select")
        }
        
        try Nngit.testRun(context: testFactory, args: args)
    }
}
