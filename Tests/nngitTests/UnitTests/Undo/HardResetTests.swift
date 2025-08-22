import Testing
import GitShellKit
import NnShellKit
@testable import nngit

@MainActor
struct HardResetTests {
    @Test("Undoes commits when all authored by current user")
    func undoesCommitsForCurrentUser() throws {
        let shellResults = [
            "John Doe",                     // git config user.name
            "john@example.com",             // git config user.email
            "abc123 - Initial commit (John Doe <john@example.com>, 2 days ago)\ndef456 - Update README (John Doe <john@example.com>, 1 day ago)",  // git log
            ""                              // git reset --hard HEAD~2
        ]
        
        let picker = MockPicker(permissionResponses: [
            "Are you sure you want to hard reset 2 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action.": true
        ])
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)

        _ = try runCommand(context, numberOfCommits: 2)

        #expect(shell.executedCommands.contains("git config user.name"))
        #expect(shell.executedCommands.contains("git config user.email"))
        #expect(shell.executedCommands.contains("git log -n 2 --pretty=format:'%h - %s (%an <%ae>, %ar)'"))
        #expect(shell.executedCommands.contains("git reset --hard HEAD~2"))
    }

    @Test("does not discard commits from other authors without force")
    func doesNotUndoWhenOtherAuthors() throws {
        let shellResults = [
            "John Doe",                     // git config user.name
            "john@example.com",             // git config user.email
            "abc123 - Fix bug (Jane Smith <jane@example.com>, 2 days ago)"  // git log
        ]
        
        let picker = MockPicker()
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)

        let output = try runCommand(context, numberOfCommits: 1)

        #expect(!shell.executedCommands.contains("git reset --hard HEAD~1"))
        #expect(output.contains("Some of the commits were created by other authors"))
    }

    @Test("discards commits from other authors when forced")
    func discardsWithForce() throws {
        let shellResults = [
            "John Doe",                     // git config user.name
            "john@example.com",             // git config user.email
            "abc123 - Fix bug (Jane Smith <jane@example.com>, 2 days ago)",  // git log
            ""                              // git reset --hard HEAD~1
        ]
        
        let picker = MockPicker(permissionResponses: [
            "Are you sure you want to hard reset 1 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action.": true
        ])
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)

        let output = try runCommand(context, numberOfCommits: 1, force: true)

        #expect(shell.executedCommands.contains("git reset --hard HEAD~1"))
        #expect(output.contains("Warning: resetting commits authored by others."))
    }

    @Test("prints invalid count message when number is less than one")
    func printsInvalidCount() throws {
        let picker = MockPicker()
        let shell = MockShell(results: [])
        let context = MockContext(picker: picker, shell: shell)

        let output = try runCommand(context, numberOfCommits: 0)

        #expect(shell.executedCommands.isEmpty)
        #expect(output.contains("Number of commits to reset must be greater than 0"))
    }

    @Test("does not undo commits when permission is denied")
    func doesNotUndoWhenPermissionDenied() throws {
        let shellResults = [
            "John Doe",                     // git config user.name
            "john@example.com",             // git config user.email
            "abc123 - Initial commit (John Doe <john@example.com>, 2 days ago)"  // git log
        ]
        
        let picker = MockPicker(permissionResponses: [
            "Are you sure you want to hard reset 1 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action.": false
        ])
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)

        #expect(throws: (any Error).self) {
            _ = try runCommand(context, numberOfCommits: 1)
        }

        #expect(!shell.executedCommands.contains("git reset --hard HEAD~1"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 1 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
    }
    
    // MARK: - Selection Mode Tests
    
    @Test("selects first commit in selection mode")
    func selectsFirstCommitInSelectionMode() throws {
        let shellResults = [
            "Test User",                    // git config user.name
            "test@example.com",             // git config user.email
            "abc123 - Test commit 1 (Test User <test@example.com>, 1 hour ago)\ndef456 - Test commit 2 (Test User <test@example.com>, 2 hours ago)\nghi789 - Test commit 3 (Test User <test@example.com>, 3 hours ago)\njkl012 - Test commit 4 (Test User <test@example.com>, 4 hours ago)\nmno345 - Test commit 5 (Test User <test@example.com>, 5 hours ago)\npqr678 - Test commit 6 (Test User <test@example.com>, 6 hours ago)\nstu901 - Test commit 7 (Test User <test@example.com>, 7 hours ago)",  // git log
            ""                              // git reset --hard HEAD~1
        ]
        
        let picker = MockPicker(
            permissionResponses: [
                "Are you sure you want to hard reset 1 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action.": true
            ],
            selectionResponses: [
                "Select a commit to reset to:": 0  // Select first commit
            ]
        )
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)

        _ = try runCommand(context, select: true)

        #expect(shell.executedCommands.contains("git log -n 7 --pretty=format:'%h - %s (%an <%ae>, %ar)'"))
        #expect(shell.executedCommands.contains("git reset --hard HEAD~1"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 1 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
    }
    
    @Test("selects middle commit in selection mode")
    func selectsMiddleCommitInSelectionMode() throws {
        let shellResults = [
            "Test User",                    // git config user.name
            "test@example.com",             // git config user.email
            "abc123 - Test commit 1 (Test User <test@example.com>, 1 hour ago)\ndef456 - Test commit 2 (Test User <test@example.com>, 2 hours ago)\nghi789 - Test commit 3 (Test User <test@example.com>, 3 hours ago)\njkl012 - Test commit 4 (Test User <test@example.com>, 4 hours ago)\nmno345 - Test commit 5 (Test User <test@example.com>, 5 hours ago)\npqr678 - Test commit 6 (Test User <test@example.com>, 6 hours ago)\nstu901 - Test commit 7 (Test User <test@example.com>, 7 hours ago)",  // git log
            ""                              // git reset --hard HEAD~4
        ]
        
        let picker = MockPicker(
            permissionResponses: [
                "Are you sure you want to hard reset 4 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action.": true
            ],
            selectionResponses: [
                "Select a commit to reset to:": 3  // Select 4th commit (index 3)
            ]
        )
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)

        _ = try runCommand(context, select: true)

        #expect(shell.executedCommands.contains("git reset --hard HEAD~4"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 4 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
    }
    
    @Test("selects last available commit in selection mode")
    func selectsLastAvailableCommitInSelectionMode() throws {
        let shellResults = [
            "Test User",                    // git config user.name
            "test@example.com",             // git config user.email
            "abc123 - Test commit 1 (Test User <test@example.com>, 1 hour ago)\ndef456 - Test commit 2 (Test User <test@example.com>, 2 hours ago)\nghi789 - Test commit 3 (Test User <test@example.com>, 3 hours ago)\njkl012 - Test commit 4 (Test User <test@example.com>, 4 hours ago)\nmno345 - Test commit 5 (Test User <test@example.com>, 5 hours ago)\npqr678 - Test commit 6 (Test User <test@example.com>, 6 hours ago)\nstu901 - Test commit 7 (Test User <test@example.com>, 7 hours ago)",  // git log
            ""                              // git reset --hard HEAD~7
        ]
        
        let picker = MockPicker(
            permissionResponses: [
                "Are you sure you want to hard reset 7 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action.": true
            ],
            selectionResponses: [
                "Select a commit to reset to:": 6  // Select 7th commit (index 6)
            ]
        )
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)

        _ = try runCommand(context, select: true)

        #expect(shell.executedCommands.contains("git reset --hard HEAD~7"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 7 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
    }
    
    // MARK: - Selection Integration Tests
    
    @Test("selection mode works with force flag for other authors")
    func selectionModeWorksWithForceFlagForOtherAuthors() throws {
        let shellResults = [
            "Test User",                    // git config user.name
            "test@example.com",             // git config user.email
            "abc123 - Test commit 1 (Test User <test@example.com>, 1 hour ago)\ndef456 - Test commit 2 (Other User <other@example.com>, 2 hours ago)\nghi789 - Test commit 3 (Test User <test@example.com>, 3 hours ago)\njkl012 - Test commit 4 (Test User <test@example.com>, 4 hours ago)\nmno345 - Test commit 5 (Test User <test@example.com>, 5 hours ago)\npqr678 - Test commit 6 (Test User <test@example.com>, 6 hours ago)\nstu901 - Test commit 7 (Test User <test@example.com>, 7 hours ago)",  // git log
            ""                              // git reset --hard HEAD~2
        ]
        
        let picker = MockPicker(
            permissionResponses: [
                "Are you sure you want to hard reset 2 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action.": true
            ],
            selectionResponses: [
                "Select a commit to reset to:": 1  // Select 2nd commit (has other author)
            ]
        )
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)

        _ = try runCommand(context, force: true, select: true)

        #expect(shell.executedCommands.contains("git reset --hard HEAD~2"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 2 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
    }
    
    @Test("selection mode respects author validation")
    func selectionModeRespectsAuthorValidation() throws {
        let shellResults = [
            "Test User",                    // git config user.name
            "test@example.com",             // git config user.email
            "abc123 - Test commit 1 (Test User <test@example.com>, 1 hour ago)\ndef456 - Test commit 2 (Other User <other@example.com>, 2 hours ago)\nghi789 - Test commit 3 (Test User <test@example.com>, 3 hours ago)\njkl012 - Test commit 4 (Test User <test@example.com>, 4 hours ago)\nmno345 - Test commit 5 (Test User <test@example.com>, 5 hours ago)\npqr678 - Test commit 6 (Test User <test@example.com>, 6 hours ago)\nstu901 - Test commit 7 (Test User <test@example.com>, 7 hours ago)"  // git log
        ]
        
        let picker = MockPicker(
            selectionResponses: [
                "Select a commit to reset to:": 1  // Select 2nd commit (has other author)
            ]
        )
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)

        let output = try runCommand(context, select: true)

        // Should not execute hard reset without force flag when other authors are present
        #expect(!shell.executedCommands.contains("git reset --hard HEAD~2"))
        #expect(!picker.requiredPermissions.contains("Are you sure you want to hard reset 2 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
        #expect(output.contains("Some of the commits were created by other authors"))
    }
    
    @Test("selection mode handles permission denial")
    func selectionModeHandlesPermissionDenial() throws {
        let shellResults = [
            "Test User",                    // git config user.name
            "test@example.com",             // git config user.email
            "abc123 - Test commit 1 (Test User <test@example.com>, 1 hour ago)\ndef456 - Test commit 2 (Test User <test@example.com>, 2 hours ago)\nghi789 - Test commit 3 (Test User <test@example.com>, 3 hours ago)\njkl012 - Test commit 4 (Test User <test@example.com>, 4 hours ago)\nmno345 - Test commit 5 (Test User <test@example.com>, 5 hours ago)\npqr678 - Test commit 6 (Test User <test@example.com>, 6 hours ago)\nstu901 - Test commit 7 (Test User <test@example.com>, 7 hours ago)"  // git log
        ]
        
        let picker = MockPicker(
            permissionResponses: [
                "Are you sure you want to hard reset 3 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action.": false
            ],
            selectionResponses: [
                "Select a commit to reset to:": 2  // Select 3rd commit
            ]
        )
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)

        #expect(throws: (any Error).self) {
            _ = try runCommand(context, select: true)
        }
        
        #expect(!shell.executedCommands.contains("git reset --hard HEAD~3"))
    }
    
    // MARK: - Edge Case Tests
    
    @Test("selection mode handles empty commit history")
    func selectionModeHandlesEmptyCommitHistory() throws {
        let shellResults = [
            "Test User",                    // git config user.name
            "test@example.com",             // git config user.email
            ""                              // empty git log
        ]
        
        let picker = MockPicker()
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)

        let output = try runCommand(context, select: true)

        // Should not execute any reset commands with empty commit history
        #expect(!shell.executedCommands.contains { $0.contains("git reset --hard") })
        #expect(picker.requiredPermissions.isEmpty)
        #expect(output.contains("No commits found to select from"))
    }
    
    @Test("selection mode with insufficient commits")
    func selectionModeWithInsufficientCommits() throws {
        let shellResults = [
            "Test User",                    // git config user.name
            "test@example.com",             // git config user.email
            "abc123 - Test commit 1 (Test User <test@example.com>, 1 hour ago)\ndef456 - Test commit 2 (Test User <test@example.com>, 2 hours ago)\nghi789 - Test commit 3 (Test User <test@example.com>, 3 hours ago)",  // git log
            ""                              // git reset --hard HEAD~2
        ]
        
        let picker = MockPicker(
            permissionResponses: [
                "Are you sure you want to hard reset 2 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action.": true
            ],
            selectionResponses: [
                "Select a commit to reset to:": 1  // Select 2nd commit (out of 3 available)
            ]
        )
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)

        _ = try runCommand(context, select: true)

        // Should work correctly even with fewer than 7 commits
        #expect(shell.executedCommands.contains("git reset --hard HEAD~2"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 2 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
    }
    
    // MARK: - Argument Validation Tests
    
    @Test("selection mode ignores number argument")
    func selectionModeIgnoresNumberArgument() throws {
        let shellResults = [
            "Test User",                    // git config user.name
            "test@example.com",             // git config user.email
            "abc123 - Test commit 1 (Test User <test@example.com>, 1 hour ago)\ndef456 - Test commit 2 (Test User <test@example.com>, 2 hours ago)\nghi789 - Test commit 3 (Test User <test@example.com>, 3 hours ago)\njkl012 - Test commit 4 (Test User <test@example.com>, 4 hours ago)\nmno345 - Test commit 5 (Test User <test@example.com>, 5 hours ago)",  // git log
            ""                              // git reset --hard HEAD~3
        ]
        
        let picker = MockPicker(
            permissionResponses: [
                "Are you sure you want to hard reset 3 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action.": true
            ],
            selectionResponses: [
                "Select a commit to reset to:": 2  // Select 3rd commit
            ]
        )
        let shell = MockShell(results: shellResults)
        let commitManager = DefaultGitCommitManager(shell: shell)
        let resetHelper = DefaultGitResetHelper(manager: commitManager, picker: picker)
        let context = MockContext(picker: picker, shell: shell, resetHelper: resetHelper)

        // Pass number argument 5, but it should be ignored in select mode
        _ = try runCommand(context, numberOfCommits: 5, force: false, select: true)

        // Should use selection (3) not the number argument (5)
        #expect(shell.executedCommands.contains("git reset --hard HEAD~3"))
        #expect(!shell.executedCommands.contains("git reset --hard HEAD~5"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 3 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
    }
}


// MARK: - Helper Methods
private extension HardResetTests {
    func runCommand(_ context: NnGitContext, numberOfCommits: Int = 1, force: Bool = false, select: Bool = false) throws -> String {
        var args = ["undo", "hard", String(numberOfCommits)]
        if force {
            args.append("--force")
        }
        if select {
            args.append("--select")
        }
        return try Nngit.testRun(context: context, args: args)
    }
}
