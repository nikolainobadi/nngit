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
        #expect(output.contains("number of commits to undo must be greater than 1"))
    }
}


// MARK: - Helper Methods
private extension UndoCommitCommandTests {
    func runCommand(_ context: NnGitContext, numberOfCommits: Int, force: Bool = false) throws -> String {
        var args = ["undo-commit", String(numberOfCommits)]
        if force {
            args.append("--force")
        }
        return try Nngit.testRun(context: context, args: args)
    }
}
