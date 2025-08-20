import Testing
@testable import nngit

@MainActor
struct UndoCommitCommandTests {
    @Test("undoes commits when all authored by current user")
    func undoesCommitsForCurrentUser() throws {
        let responses = [
            "git config user.name": "John Doe",
            "git log -n 2 --pretty=format:'%h - %s (%an, %ar)'": """
abc123 - Initial commit (John Doe, 2 days ago)
def456 - Update README (John Doe, 1 day ago)
""",
            "git reset --hard HEAD~2": ""
        ]

        let shell = MockGitShell(responses: responses)
        let context = MockContext(shell: shell)

        _ = try runCommand(context, numberOfCommits: 2)

        #expect(shell.commands == [
            "git config user.name",
            "git log -n 2 --pretty=format:'%h - %s (%an, %ar)'",
            "git reset --hard HEAD~2"
        ])
    }

    @Test("does not discard commits from other authors without force")
    func doesNotUndoWhenOtherAuthors() throws {
        let responses = [
            "git config user.name": "John Doe",
            "git log -n 1 --pretty=format:'%h - %s (%an, %ar)'": "abc123 - Fix bug (Jane Smith, 2 days ago)"
        ]

        let shell = MockGitShell(responses: responses)
        let context = MockContext(shell: shell)

        let output = try runCommand(context, numberOfCommits: 1)

        #expect(!shell.commands.contains("git reset --hard HEAD~1"))
        #expect(output.contains("Some of the commits were created by other authors"))
    }

    @Test("discards commits from other authors when forced")
    func discardsWithForce() throws {
        let responses = [
            "git config user.name": "John Doe",
            "git log -n 1 --pretty=format:'%h - %s (%an, %ar)'": "abc123 - Fix bug (Jane Smith, 2 days ago)",
            "git reset --hard HEAD~1": ""
        ]

        let shell = MockGitShell(responses: responses)
        let context = MockContext(shell: shell)

        let output = try runCommand(context, numberOfCommits: 1, force: true)

        #expect(shell.commands.contains("git reset --hard HEAD~1"))
        #expect(output.contains("Warning: discarding commits authored by others."))
    }

    @Test("prints invalid count message when number is less than one")
    func printsInvalidCount() throws {
        let shell = MockGitShell(responses: [:])
        let context = MockContext(shell: shell)

        let output = try runCommand(context, numberOfCommits: 0)

        #expect(shell.commands.isEmpty)
        #expect(output.contains("number of commits to undo must be greater than 0"))
    }

    @Test("does not undo commits when permission is denied")
    func doesNotUndoWhenPermissionDenied() throws {
        let responses = [
            "git config user.name": "John Doe",
            "git log -n 1 --pretty=format:'%h - %s (%an, %ar)'": "abc123 - Initial commit (John Doe, 2 days ago)"
        ]

        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        picker.permissionResponses["Are you sure you want to hard reset 1 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."] = false
        let context = MockContext(picker: picker, shell: shell)

        #expect(throws: (any Error).self) {
            _ = try runCommand(context, numberOfCommits: 1)
        }

        #expect(!shell.commands.contains("git reset --hard HEAD~1"))
        #expect(picker.requiredPermissions.contains("Are you sure you want to hard reset 1 commit(s)? This will permanently discard the commits and all their changes. You cannot undo this action."))
    }
}


// MARK: - Helper Methods
private extension UndoCommitCommandTests {
    func runCommand(_ context: NnGitContext, numberOfCommits: Int, force: Bool = false) throws -> String {
        var args = ["undo", "hard", String(numberOfCommits)]
        if force {
            args.append("--force")
        }
        return try Nngit.testRun(context: context, args: args)
    }
}
