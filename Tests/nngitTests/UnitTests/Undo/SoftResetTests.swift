import Testing
import GitShellKit
@testable import nngit

@MainActor
struct SoftResetTests {
    @Test("Soft resets specified number of commits")
    func softResetsSpecifiedCommits() throws {
        // Setup mock reset helper with initialization parameters
        let commitInfo = [CommitInfo(hash: "abc123", message: "Test commit", author: "Test User", date: "2 hours ago", wasAuthoredByCurrentUser: true)]
        let mockResetHelper = MockGitResetHelper(
            prepareResetResult: commitInfo,
            verifyAuthorPermissionsResult: true
        )
        
        // Setup mock shell for the actual reset command
        let shell = MockGitShell(responses: ["git reset --soft HEAD~1": ""])
        let context = MockContext(shell: shell, resetHelper: mockResetHelper)
        
        try runCommand(context, number: 1)
        
        // Verify the reset helper was called with correct parameters
        #expect(mockResetHelper.prepareResetCount == 1)
        #expect(mockResetHelper.displayCommitsAction == "moved back to staging area")
        #expect(mockResetHelper.verifyAuthorPermissionsForce == false)
        #expect(mockResetHelper.confirmResetCount == 1)
        #expect(mockResetHelper.confirmResetType == "soft")
        
        // Verify the actual reset command was executed
        #expect(shell.commands.contains("git reset --soft HEAD~1"))
    }
    
    @Test("Soft resets multiple commits")
    func softResetsMultipleCommits() throws {
        let responses = [
            "git config user.name": "Test User",
            "git log -n 3 --pretty=format:'%h - %s (%an, %ar)'": "abc123 - Test commit 1 (Test User, 2 hours ago)\ndef456 - Test commit 2 (Test User, 3 hours ago)\nghi789 - Test commit 3 (Test User, 4 hours ago)",
            "git reset --soft HEAD~3": ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.permissionResponses["Are you sure you want to soft reset 3 commit(s)? The changes will be moved to staging area."] = true
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context, number: 3)
        
        #expect(shell.commands.contains("git reset --soft HEAD~3"))
    }
    
    @Test("Requires force flag for commits by other authors", .disabled())
    func requiresForceForOtherAuthors() throws {
        let responses = [
            "git config user.name": "Test User",
            "git log -n 2 --pretty=format:'%h - %s (%an, %ar)'": "abc123 - Test commit 1 (Test User, 2 hours ago)\ndef456 - Test commit 2 (Other User, 3 hours ago)"
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context, number: 2, force: false)
        
        // Should not execute soft reset without force flag
        #expect(!shell.commands.contains("git reset --soft HEAD~2"))
        #expect(!picker.requiredPermissions.contains("Are you sure you want to soft reset 2 commit(s)? The changes will be moved to staging area."))
    }
    
    @Test("allows soft reset with force flag for other authors", .disabled())
    func allowsSoftResetWithForceForOtherAuthors() throws {
        let responses = [
            "git config user.name": "Test User",
            "git log -n 2 --pretty=format:'%h - %s (%an, %ar)'": "abc123 - Test commit 1 (Test User, 2 hours ago)\ndef456 - Test commit 2 (Other User, 3 hours ago)",
            "git reset --soft HEAD~2": ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.permissionResponses["Are you sure you want to soft reset 2 commit(s)? The changes will be moved to staging area."] = true
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context, number: 2, force: true)
        
        #expect(shell.commands.contains("git reset --soft HEAD~2"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to soft reset 2 commit(s)? The changes will be moved to staging area."))
    }
    
    @Test("validates number is greater than zero")
    func validatesNumberGreaterThanZero() throws {
        let shell = MockGitShell(responses: [:])
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context, number: 0)
        
        // Should not execute any git commands with invalid number
        #expect(!shell.commands.contains("git config user.name"))
        #expect(!shell.commands.contains("git reset --soft HEAD~0"))
    }
    
    @Test("handles permission denial", .disabled())
    func handlesPermissionDenial() throws {
        let responses = [
            "git config user.name": "Test User",
            "git log -n 1 --pretty=format:'%h - %s (%an, %ar)'": "abc123 - Test commit (Test User, 2 hours ago)"
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.permissionResponses["Are you sure you want to soft reset 1 commit(s)? The changes will be moved to staging area."] = false
        let context = MockContext(picker: picker, shell: shell)
        
        do {
            try runCommand(context, number: 1)
            #expect(Bool(false), "Expected permission denied error")
        } catch {
            // Expected to throw due to permission denial
            #expect(!shell.commands.contains("git reset --soft HEAD~1"))
        }
    }
    
    // MARK: - Selection Mode Tests
    
    @Test("selects first commit in selection mode", .disabled())
    func selectsFirstCommitInSelectionMode() throws {
        let responses = [
            "git config user.name": "Test User",
            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
                abc123 - Test commit 1 (Test User, 1 hour ago)
                def456 - Test commit 2 (Test User, 2 hours ago)
                ghi789 - Test commit 3 (Test User, 3 hours ago)
                jkl012 - Test commit 4 (Test User, 4 hours ago)
                mno345 - Test commit 5 (Test User, 5 hours ago)
                pqr678 - Test commit 6 (Test User, 6 hours ago)
                stu901 - Test commit 7 (Test User, 7 hours ago)
                """,
            "git reset --soft HEAD~1": ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select a commit to soft reset to:"] = 0 // Select first commit
        picker.permissionResponses["Are you sure you want to soft reset 1 commit(s)? The changes will be moved to staging area."] = true
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context, select: true)
        
        #expect(shell.commands.contains("git log -n 7 --pretty=format:'%h - %s (%an, %ar)'"))
        #expect(shell.commands.contains("git reset --soft HEAD~1"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to soft reset 1 commit(s)? The changes will be moved to staging area."))
    }
    
    @Test("selects middle commit in selection mode", .disabled())
    func selectsMiddleCommitInSelectionMode() throws {
        let responses = [
            "git config user.name": "Test User",
            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
                abc123 - Test commit 1 (Test User, 1 hour ago)
                def456 - Test commit 2 (Test User, 2 hours ago)
                ghi789 - Test commit 3 (Test User, 3 hours ago)
                jkl012 - Test commit 4 (Test User, 4 hours ago)
                mno345 - Test commit 5 (Test User, 5 hours ago)
                pqr678 - Test commit 6 (Test User, 6 hours ago)
                stu901 - Test commit 7 (Test User, 7 hours ago)
                """,
            "git reset --soft HEAD~4": ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select a commit to soft reset to:"] = 3 // Select 4th commit (index 3)
        picker.permissionResponses["Are you sure you want to soft reset 4 commit(s)? The changes will be moved to staging area."] = true
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context, select: true)
        
        #expect(shell.commands.contains("git reset --soft HEAD~4"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to soft reset 4 commit(s)? The changes will be moved to staging area."))
    }
    
    @Test("selects last available commit in selection mode", .disabled())
    func selectsLastAvailableCommitInSelectionMode() throws {
        let responses = [
            "git config user.name": "Test User",
            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
                abc123 - Test commit 1 (Test User, 1 hour ago)
                def456 - Test commit 2 (Test User, 2 hours ago)
                ghi789 - Test commit 3 (Test User, 3 hours ago)
                jkl012 - Test commit 4 (Test User, 4 hours ago)
                mno345 - Test commit 5 (Test User, 5 hours ago)
                pqr678 - Test commit 6 (Test User, 6 hours ago)
                stu901 - Test commit 7 (Test User, 7 hours ago)
                """,
            "git reset --soft HEAD~7": ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select a commit to soft reset to:"] = 6 // Select 7th commit (index 6)
        picker.permissionResponses["Are you sure you want to soft reset 7 commit(s)? The changes will be moved to staging area."] = true
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context, select: true)
        
        #expect(shell.commands.contains("git reset --soft HEAD~7"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to soft reset 7 commit(s)? The changes will be moved to staging area."))
    }
    
    // MARK: - Selection Integration Tests
    
    @Test("selection mode works with force flag for other authors", .disabled())
    func selectionModeWorksWithForceFlagForOtherAuthors() throws {
        let responses = [
            "git config user.name": "Test User",
            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
                abc123 - Test commit 1 (Test User, 1 hour ago)
                def456 - Test commit 2 (Other User, 2 hours ago)
                ghi789 - Test commit 3 (Test User, 3 hours ago)
                jkl012 - Test commit 4 (Test User, 4 hours ago)
                mno345 - Test commit 5 (Test User, 5 hours ago)
                pqr678 - Test commit 6 (Test User, 6 hours ago)
                stu901 - Test commit 7 (Test User, 7 hours ago)
                """,
            "git reset --soft HEAD~2": ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select a commit to soft reset to:"] = 1 // Select 2nd commit (has other author)
        picker.permissionResponses["Are you sure you want to soft reset 2 commit(s)? The changes will be moved to staging area."] = true
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context, force: true, select: true)
        
        #expect(shell.commands.contains("git reset --soft HEAD~2"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to soft reset 2 commit(s)? The changes will be moved to staging area."))
    }
    
    @Test("selection mode respects author validation", .disabled())
    func selectionModeRespectsAuthorValidation() throws {
        let responses = [
            "git config user.name": "Test User",
            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
                abc123 - Test commit 1 (Test User, 1 hour ago)
                def456 - Test commit 2 (Other User, 2 hours ago)
                ghi789 - Test commit 3 (Test User, 3 hours ago)
                jkl012 - Test commit 4 (Test User, 4 hours ago)
                mno345 - Test commit 5 (Test User, 5 hours ago)
                pqr678 - Test commit 6 (Test User, 6 hours ago)
                stu901 - Test commit 7 (Test User, 7 hours ago)
                """
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select a commit to soft reset to:"] = 1 // Select 2nd commit (has other author)
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context, select: true)
        
        // Should not execute soft reset without force flag when other authors are present
        #expect(!shell.commands.contains("git reset --soft HEAD~2"))
        #expect(!picker.requiredPermissions.contains("Are you sure you want to soft reset 2 commit(s)? The changes will be moved to staging area."))
    }
    
    @Test("selection mode handles permission denial", .disabled())
    func selectionModeHandlesPermissionDenial() throws {
        let responses = [
            "git config user.name": "Test User",
            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
                abc123 - Test commit 1 (Test User, 1 hour ago)
                def456 - Test commit 2 (Test User, 2 hours ago)
                ghi789 - Test commit 3 (Test User, 3 hours ago)
                jkl012 - Test commit 4 (Test User, 4 hours ago)
                mno345 - Test commit 5 (Test User, 5 hours ago)
                pqr678 - Test commit 6 (Test User, 6 hours ago)
                stu901 - Test commit 7 (Test User, 7 hours ago)
                """
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select a commit to soft reset to:"] = 2 // Select 3rd commit
        picker.permissionResponses["Are you sure you want to soft reset 3 commit(s)? The changes will be moved to staging area."] = false
        let context = MockContext(picker: picker, shell: shell)
        
        do {
            try runCommand(context, select: true)
            #expect(Bool(false), "Expected permission denied error")
        } catch {
            // Expected to throw due to permission denial
            #expect(!shell.commands.contains("git reset --soft HEAD~3"))
        }
    }
    
    // MARK: - Edge Case Tests
    
    @Test("selection mode handles empty commit history")
    func selectionModeHandlesEmptyCommitHistory() throws {
        let responses = [
            "git config user.name": "Test User",
            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context, select: true)
        
        // Should not execute any reset commands with empty commit history
        #expect(!shell.commands.contains { $0.contains("git reset --soft") })
        #expect(picker.requiredPermissions.isEmpty)
    }
    
    @Test("selection mode with insufficient commits", .disabled())
    func selectionModeWithInsufficientCommits() throws {
        let responses = [
            "git config user.name": "Test User",
            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
                abc123 - Test commit 1 (Test User, 1 hour ago)
                def456 - Test commit 2 (Test User, 2 hours ago)
                ghi789 - Test commit 3 (Test User, 3 hours ago)
                """,
            "git reset --soft HEAD~2": ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select a commit to soft reset to:"] = 1 // Select 2nd commit (out of 3 available)
        picker.permissionResponses["Are you sure you want to soft reset 2 commit(s)? The changes will be moved to staging area."] = true
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context, select: true)
        
        // Should work correctly even with fewer than 7 commits
        #expect(shell.commands.contains("git reset --soft HEAD~2"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to soft reset 2 commit(s)? The changes will be moved to staging area."))
    }
    
    // MARK: - Argument Validation Tests
    
    @Test("selection mode ignores number argument", .disabled())
    func selectionModeIgnoresNumberArgument() throws {
        let responses = [
            "git config user.name": "Test User",
            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
                abc123 - Test commit 1 (Test User, 1 hour ago)
                def456 - Test commit 2 (Test User, 2 hours ago)
                ghi789 - Test commit 3 (Test User, 3 hours ago)
                jkl012 - Test commit 4 (Test User, 4 hours ago)
                mno345 - Test commit 5 (Test User, 5 hours ago)
                """,
            "git reset --soft HEAD~3": ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.selectionResponses["Select a commit to soft reset to:"] = 2 // Select 3rd commit
        picker.permissionResponses["Are you sure you want to soft reset 3 commit(s)? The changes will be moved to staging area."] = true
        let context = MockContext(picker: picker, shell: shell)
        
        // Pass number argument 5, but it should be ignored in select mode
        try runCommand(context, number: 5, select: true)
        
        // Should use selection (3) not the number argument (5)
        #expect(shell.commands.contains("git reset --soft HEAD~3"))
        #expect(!shell.commands.contains("git reset --soft HEAD~5"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to soft reset 3 commit(s)? The changes will be moved to staging area."))
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
