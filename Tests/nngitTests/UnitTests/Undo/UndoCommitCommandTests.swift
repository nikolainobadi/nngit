//import Testing
//@testable import nngit
//
//@MainActor
//struct UndoCommitCommandTests {
//    @Test("Undoes commits when all authored by current user")
//    func undoesCommitsForCurrentUser() throws {
//        let responses = [
//            "git config user.name": "John Doe",
//            "git log -n 2 --pretty=format:'%h - %s (%an, %ar)'": """
//abc123 - Initial commit (John Doe, 2 days ago)
//def456 - Update README (John Doe, 1 day ago)
//""",
//            "git reset --hard HEAD~2": ""
//        ]
//
//        let shell = MockGitShell(responses: responses)
//        let context = MockContext(shell: shell)
//
//        _ = try runCommand(context, numberOfCommits: 2)
//
//        #expect(shell.commands == [
//            "git config user.name",
//            "git log -n 2 --pretty=format:'%h - %s (%an, %ar)'",
//            "git reset --hard HEAD~2"
//        ])
//    }
//
//    @Test("does not discard commits from other authors without force")
//    func doesNotUndoWhenOtherAuthors() throws {
//        let responses = [
//            "git config user.name": "John Doe",
//            "git log -n 1 --pretty=format:'%h - %s (%an, %ar)'": "abc123 - Fix bug (Jane Smith, 2 days ago)"
//        ]
//
//        let shell = MockGitShell(responses: responses)
//        let context = MockContext(shell: shell)
//
//        let output = try runCommand(context, numberOfCommits: 1)
//
//        #expect(!shell.commands.contains("git reset --hard HEAD~1"))
//        #expect(output.contains("Some of the commits were created by other authors"))
//    }
//
//    @Test("discards commits from other authors when forced")
//    func discardsWithForce() throws {
//        let responses = [
//            "git config user.name": "John Doe",
//            "git log -n 1 --pretty=format:'%h - %s (%an, %ar)'": "abc123 - Fix bug (Jane Smith, 2 days ago)",
//            "git reset --hard HEAD~1": ""
//        ]
//
//        let shell = MockGitShell(responses: responses)
//        let context = MockContext(shell: shell)
//
//        let output = try runCommand(context, numberOfCommits: 1, force: true)
//
//        #expect(shell.commands.contains("git reset --hard HEAD~1"))
//        #expect(output.contains("Warning: discarding commits authored by others."))
//    }
//
//    @Test("prints invalid count message when number is less than one")
//    func printsInvalidCount() throws {
//        let shell = MockGitShell(responses: [:])
//        let context = MockContext(shell: shell)
//
//        let output = try runCommand(context, numberOfCommits: 0)
//
//        #expect(shell.commands.isEmpty)
//        #expect(output.contains("number of commits to undo must be greater than 0"))
//    }
//
//    @Test("does not undo commits when permission is denied")
//    func doesNotUndoWhenPermissionDenied() throws {
//        let responses = [
//            "git config user.name": "John Doe",
//            "git log -n 1 --pretty=format:'%h - %s (%an, %ar)'": "abc123 - Initial commit (John Doe, 2 days ago)"
//        ]
//
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        picker.permissionResponses["Are you sure you want to hard reset 1 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."] = false
//        let context = MockContext(picker: picker, shell: shell)
//
//        #expect(throws: (any Error).self) {
//            _ = try runCommand(context, numberOfCommits: 1)
//        }
//
//        #expect(!shell.commands.contains("git reset --hard HEAD~1"))
//        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 1 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
//    }
//    
//    // MARK: - Selection Mode Tests
//    
//    @Test("selects first commit in selection mode")
//    func selectsFirstCommitInSelectionMode() throws {
//        let responses = [
//            "git config user.name": "Test User",
//            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
//                abc123 - Test commit 1 (Test User, 1 hour ago)
//                def456 - Test commit 2 (Test User, 2 hours ago)
//                ghi789 - Test commit 3 (Test User, 3 hours ago)
//                jkl012 - Test commit 4 (Test User, 4 hours ago)
//                mno345 - Test commit 5 (Test User, 5 hours ago)
//                pqr678 - Test commit 6 (Test User, 6 hours ago)
//                stu901 - Test commit 7 (Test User, 7 hours ago)
//                """,
//            "git reset --hard HEAD~1": ""
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        picker.selectionResponses["Select a commit to hard reset to:"] = 0 // Select first commit
//        picker.permissionResponses["Are you sure you want to hard reset 1 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."] = true
//        let context = MockContext(picker: picker, shell: shell)
//
//        _ = try runCommand(context, select: true)
//
//        #expect(shell.commands.contains("git log -n 7 --pretty=format:'%h - %s (%an, %ar)'"))
//        #expect(shell.commands.contains("git reset --hard HEAD~1"))
//        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 1 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
//    }
//    
//    @Test("selects middle commit in selection mode")
//    func selectsMiddleCommitInSelectionMode() throws {
//        let responses = [
//            "git config user.name": "Test User",
//            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
//                abc123 - Test commit 1 (Test User, 1 hour ago)
//                def456 - Test commit 2 (Test User, 2 hours ago)
//                ghi789 - Test commit 3 (Test User, 3 hours ago)
//                jkl012 - Test commit 4 (Test User, 4 hours ago)
//                mno345 - Test commit 5 (Test User, 5 hours ago)
//                pqr678 - Test commit 6 (Test User, 6 hours ago)
//                stu901 - Test commit 7 (Test User, 7 hours ago)
//                """,
//            "git reset --hard HEAD~4": ""
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        picker.selectionResponses["Select a commit to hard reset to:"] = 3 // Select 4th commit (index 3)
//        picker.permissionResponses["Are you sure you want to hard reset 4 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."] = true
//        let context = MockContext(picker: picker, shell: shell)
//
//        _ = try runCommand(context, select: true)
//
//        #expect(shell.commands.contains("git reset --hard HEAD~4"))
//        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 4 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
//    }
//    
//    @Test("selects last available commit in selection mode")
//    func selectsLastAvailableCommitInSelectionMode() throws {
//        let responses = [
//            "git config user.name": "Test User",
//            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
//                abc123 - Test commit 1 (Test User, 1 hour ago)
//                def456 - Test commit 2 (Test User, 2 hours ago)
//                ghi789 - Test commit 3 (Test User, 3 hours ago)
//                jkl012 - Test commit 4 (Test User, 4 hours ago)
//                mno345 - Test commit 5 (Test User, 5 hours ago)
//                pqr678 - Test commit 6 (Test User, 6 hours ago)
//                stu901 - Test commit 7 (Test User, 7 hours ago)
//                """,
//            "git reset --hard HEAD~7": ""
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        picker.selectionResponses["Select a commit to hard reset to:"] = 6 // Select 7th commit (index 6)
//        picker.permissionResponses["Are you sure you want to hard reset 7 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."] = true
//        let context = MockContext(picker: picker, shell: shell)
//
//        _ = try runCommand(context, select: true)
//
//        #expect(shell.commands.contains("git reset --hard HEAD~7"))
//        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 7 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
//    }
//    
//    // MARK: - Selection Integration Tests
//    
//    @Test("selection mode works with force flag for other authors")
//    func selectionModeWorksWithForceFlagForOtherAuthors() throws {
//        let responses = [
//            "git config user.name": "Test User",
//            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
//                abc123 - Test commit 1 (Test User, 1 hour ago)
//                def456 - Test commit 2 (Other User, 2 hours ago)
//                ghi789 - Test commit 3 (Test User, 3 hours ago)
//                jkl012 - Test commit 4 (Test User, 4 hours ago)
//                mno345 - Test commit 5 (Test User, 5 hours ago)
//                pqr678 - Test commit 6 (Test User, 6 hours ago)
//                stu901 - Test commit 7 (Test User, 7 hours ago)
//                """,
//            "git reset --hard HEAD~2": ""
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        picker.selectionResponses["Select a commit to hard reset to:"] = 1 // Select 2nd commit (has other author)
//        picker.permissionResponses["Are you sure you want to hard reset 2 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."] = true
//        let context = MockContext(picker: picker, shell: shell)
//
//        _ = try runCommand(context, force: true, select: true)
//
//        #expect(shell.commands.contains("git reset --hard HEAD~2"))
//        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 2 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
//    }
//    
//    @Test("selection mode respects author validation")
//    func selectionModeRespectsAuthorValidation() throws {
//        let responses = [
//            "git config user.name": "Test User",
//            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
//                abc123 - Test commit 1 (Test User, 1 hour ago)
//                def456 - Test commit 2 (Other User, 2 hours ago)
//                ghi789 - Test commit 3 (Test User, 3 hours ago)
//                jkl012 - Test commit 4 (Test User, 4 hours ago)
//                mno345 - Test commit 5 (Test User, 5 hours ago)
//                pqr678 - Test commit 6 (Test User, 6 hours ago)
//                stu901 - Test commit 7 (Test User, 7 hours ago)
//                """
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        picker.selectionResponses["Select a commit to hard reset to:"] = 1 // Select 2nd commit (has other author)
//        let context = MockContext(picker: picker, shell: shell)
//
//        let output = try runCommand(context, select: true)
//
//        // Should not execute hard reset without force flag when other authors are present
//        #expect(!shell.commands.contains("git reset --hard HEAD~2"))
//        #expect(!picker.requiredPermissions.contains("Are you sure you want to hard reset 2 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
//        #expect(output.contains("Some of the commits were created by other authors"))
//    }
//    
//    @Test("selection mode handles permission denial")
//    func selectionModeHandlesPermissionDenial() throws {
//        let responses = [
//            "git config user.name": "Test User",
//            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
//                abc123 - Test commit 1 (Test User, 1 hour ago)
//                def456 - Test commit 2 (Test User, 2 hours ago)
//                ghi789 - Test commit 3 (Test User, 3 hours ago)
//                jkl012 - Test commit 4 (Test User, 4 hours ago)
//                mno345 - Test commit 5 (Test User, 5 hours ago)
//                pqr678 - Test commit 6 (Test User, 6 hours ago)
//                stu901 - Test commit 7 (Test User, 7 hours ago)
//                """
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        picker.selectionResponses["Select a commit to hard reset to:"] = 2 // Select 3rd commit
//        picker.permissionResponses["Are you sure you want to hard reset 3 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."] = false
//        let context = MockContext(picker: picker, shell: shell)
//
//        #expect(throws: (any Error).self) {
//            _ = try runCommand(context, select: true)
//        }
//        
//        #expect(!shell.commands.contains("git reset --hard HEAD~3"))
//    }
//    
//    // MARK: - Edge Case Tests
//    
//    @Test("selection mode handles empty commit history")
//    func selectionModeHandlesEmptyCommitHistory() throws {
//        let responses = [
//            "git config user.name": "Test User",
//            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": ""
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        let context = MockContext(picker: picker, shell: shell)
//
//        let output = try runCommand(context, select: true)
//
//        // Should not execute any reset commands with empty commit history
//        #expect(!shell.commands.contains { $0.contains("git reset --hard") })
//        #expect(picker.requiredPermissions.isEmpty)
//        #expect(output.contains("No commits found to select from"))
//    }
//    
//    @Test("selection mode with insufficient commits")
//    func selectionModeWithInsufficientCommits() throws {
//        let responses = [
//            "git config user.name": "Test User",
//            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
//                abc123 - Test commit 1 (Test User, 1 hour ago)
//                def456 - Test commit 2 (Test User, 2 hours ago)
//                ghi789 - Test commit 3 (Test User, 3 hours ago)
//                """,
//            "git reset --hard HEAD~2": ""
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        picker.selectionResponses["Select a commit to hard reset to:"] = 1 // Select 2nd commit (out of 3 available)
//        picker.permissionResponses["Are you sure you want to hard reset 2 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."] = true
//        let context = MockContext(picker: picker, shell: shell)
//
//        _ = try runCommand(context, select: true)
//
//        // Should work correctly even with fewer than 7 commits
//        #expect(shell.commands.contains("git reset --hard HEAD~2"))
//        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 2 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
//    }
//    
//    // MARK: - Argument Validation Tests
//    
//    @Test("selection mode ignores number argument")
//    func selectionModeIgnoresNumberArgument() throws {
//        let responses = [
//            "git config user.name": "Test User",
//            "git log -n 7 --pretty=format:'%h - %s (%an, %ar)'": """
//                abc123 - Test commit 1 (Test User, 1 hour ago)
//                def456 - Test commit 2 (Test User, 2 hours ago)
//                ghi789 - Test commit 3 (Test User, 3 hours ago)
//                jkl012 - Test commit 4 (Test User, 4 hours ago)
//                mno345 - Test commit 5 (Test User, 5 hours ago)
//                """,
//            "git reset --hard HEAD~3": ""
//        ]
//        
//        let shell = MockGitShell(responses: responses)
//        let picker = MockPicker()
//        picker.selectionResponses["Select a commit to hard reset to:"] = 2 // Select 3rd commit
//        picker.permissionResponses["Are you sure you want to hard reset 3 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."] = true
//        let context = MockContext(picker: picker, shell: shell)
//
//        // Pass number argument 5, but it should be ignored in select mode
//        _ = try runCommand(context, numberOfCommits: 5, force: false, select: true)
//
//        // Should use selection (3) not the number argument (5)
//        #expect(shell.commands.contains("git reset --hard HEAD~3"))
//        #expect(!shell.commands.contains("git reset --hard HEAD~5"))
//        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 3 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
//    }
//}
//
//
//// MARK: - Helper Methods
//private extension UndoCommitCommandTests {
//    func runCommand(_ context: NnGitContext, numberOfCommits: Int = 1, force: Bool = false, select: Bool = false) throws -> String {
//        var args = ["undo", "hard", String(numberOfCommits)]
//        if force {
//            args.append("--force")
//        }
//        if select {
//            args.append("--select")
//        }
//        return try Nngit.testRun(context: context, args: args)
//    }
//}
