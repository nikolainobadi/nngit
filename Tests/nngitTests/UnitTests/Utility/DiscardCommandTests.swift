import Testing
import GitShellKit
@testable import nngit

@MainActor
struct DiscardCommandTests {
    @Test("clears staged and unstaged files")
    func clearsAllChanges() throws {
        let localGitCheckCommand = makeGitCommand(.localGitCheck, path: nil)
        let localChangesCommand = makeGitCommand(.getLocalChanges, path: nil)
        let responses = [
            localGitCheckCommand: "true",
            localChangesCommand: "M file.swift"
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)

        try runCommand(context)

        #expect(shell.commands.contains(localChangesCommand))
        #expect(shell.commands.contains(localGitCheckCommand))
        #expect(shell.commands.contains(makeGitCommand(.clearStagedFiles, path: nil)))
        #expect(shell.commands.contains(makeGitCommand(.clearUnstagedFiles, path: nil)))
        #expect(picker.requiredPermissions.contains("Are you sure you want to discard the changes you made in this branch? You cannot undo this action."))
    }
    
    @Test("clears only staged files")
    func clearsOnlyStagedFiles() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            makeGitCommand(.getLocalChanges, path: nil): "M file.swift"
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context, discardFiles: .staged)
        
        #expect(shell.commands.contains(makeGitCommand(.clearStagedFiles, path: nil)))
        #expect(!shell.commands.contains(makeGitCommand(.clearUnstagedFiles, path: nil)))
    }

    @Test("clears only unstaged files")
    func clearsOnlyUnstagedFiles() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            makeGitCommand(.getLocalChanges, path: nil): "M file.swift"
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context, discardFiles: .unstaged)
        
        #expect(shell.commands.contains(makeGitCommand(.clearUnstagedFiles, path: nil)))
        #expect(!shell.commands.contains(makeGitCommand(.clearStagedFiles, path: nil)))
    }

    @Test("prints no changes detected when working directory is clean")
    func printsNoChangesDetected() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            makeGitCommand(.getLocalChanges, path: nil): ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        try runCommand(context)

        #expect(!shell.commands.contains(makeGitCommand(.clearStagedFiles, path: nil)))
        #expect(!shell.commands.contains(makeGitCommand(.clearUnstagedFiles, path: nil)))
    }
}


// MARK: - Helper Methods
private extension DiscardCommandTests {
    func runCommand(_ testFactory: NnGitContext, discardFiles: DiscardFiles = .both) throws {
        var args = ["discard"]
        
        switch discardFiles {
        case .staged:
            args = args + ["-f", "staged"]
        case .unstaged:
            args = args + ["-f", "unstaged"]
        case .both:
            break
        }
        
        try Nngit.testRun(context: testFactory, args: args)
    }
}
