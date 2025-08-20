import Testing
import GitShellKit
@testable import nngit

@MainActor
struct SoftResetTests {
    @Test("soft resets specified number of commits")
    func softResetsSpecifiedCommits() throws {
        let responses = [
            "git config user.name": "Test User",
            "git log -n 1 --pretty=format:'%h - %s (%an, %ar)'": "abc123 - Test commit (Test User, 2 hours ago)",
            "git reset --soft HEAD~1": ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.permissionResponses["Are you sure you want to soft reset 1 commit(s)? The changes will be moved to staging area."] = true
        let context = MockContext(picker: picker, shell: shell)

        try runCommand(context, number: 1)

        #expect(shell.commands.contains("git config user.name"))
        #expect(shell.commands.contains("git log -n 1 --pretty=format:'%h - %s (%an, %ar)'"))
        #expect(shell.commands.contains("git reset --soft HEAD~1"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to soft reset 1 commit(s)? The changes will be moved to staging area."))
    }
    
    @Test("soft resets multiple commits")
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

    @Test("requires force flag for commits by other authors")
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

    @Test("allows soft reset with force flag for other authors")
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

    @Test("handles permission denial")
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
}


// MARK: - Helper Methods
private extension SoftResetTests {
    func runCommand(_ testFactory: NnGitContext, number: Int = 1, force: Bool = false) throws {
        var args = ["undo", "soft", "\(number)"]
        
        if force {
            args.append("--force")
        }
        
        try Nngit.testRun(context: testFactory, args: args)
    }
}