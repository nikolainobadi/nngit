import Testing
import SwiftPicker
import GitShellKit
@testable import nngit

@MainActor
struct SwitchBranchTests {
    @Test("switches without prompting when exact branch name is provided")
    func switchesExactMatch() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let switchCmd = makeGitCommand(.switchBranch(branchName: "dev"), path: nil)
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "dev", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let branch3 = GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [branch1, branch2, branch3])
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            "git config user.name": "John Doe",
            "git config user.email": "john@example.com",
            "git log -1 --pretty=format:'%an,%ae' dev": "John Doe,john@example.com",
            "git log -1 --pretty=format:'%an,%ae' feature": "Jane Smith,jane@example.com",
            switchCmd: ""
        ])
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch", "dev"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(switchCmd))
        #expect(output.isEmpty)
    }

    @Test("prints no branches found matching search term when none match")
    func printsNoMatchForSearch() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "dev", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [branch1, branch2])
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            "git config user.name": "John Doe",
            "git config user.email": "john@example.com",
            "git log -1 --pretty=format:'%an,%ae' dev": "John Doe,john@example.com"
        ])
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch", "xyz"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(output.contains("No branches found matching 'xyz'"))
    }

    @Test("prompts to select branch when no search provided")
    func promptsAndSwitches() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let switchCmd = makeGitCommand(.switchBranch(branchName: "feature"), path: nil)
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "feature", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [branch1, branch2])
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            "git config user.name": "John Doe",
            "git config user.email": "john@example.com",
            "git log -1 --pretty=format:'%an,%ae' feature": "John Doe,john@example.com",
            switchCmd: ""
        ])
        let picker = MockPicker()
        picker.selectionResponses["Select a branch (switching from main)"] = 0
        let context = MockContext(picker: picker, shell: shell, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch"])
        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(switchCmd))
        #expect(output.isEmpty)
    }

    @Test("shows all branches when no git user is configured")
    func noUserConfigShowsAll() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let switchCmd = makeGitCommand(.switchBranch(branchName: "dev"), path: nil)
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "dev", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [branch1, branch2])
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            "git config user.name": "",
            "git config --global user.name": "",
            "git config user.email": "",
            "git config --global user.email": "",
            switchCmd: ""
        ])
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch", "dev"])

        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(switchCmd))
        #expect(!shell.commands.contains(where: { $0.contains("git log -1") }))
        #expect(output.isEmpty)
    }

    @Test("includes branches from all authors with flag")
    func includeAllFlag() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let switchCmd = makeGitCommand(.switchBranch(branchName: "dev"), path: nil)
        let branch1 = GitBranch(name: "main", isMerged: false, isCurrentBranch: true, creationDate: nil, syncStatus: .undetermined)
        let branch2 = GitBranch(name: "dev", isMerged: false, isCurrentBranch: false, creationDate: nil, syncStatus: .undetermined)
        let loader = StubBranchLoader(branches: [branch1, branch2])
        let shell = MockGitShell(responses: [
            localGitCheck: "true",
            switchCmd: ""
        ])
        let picker = MockPicker()
        picker.selectionResponses["Select a branch (switching from main)"] = 1
        let context = MockContext(picker: picker, shell: shell, branchLoader: loader)

        let output = try Nngit.testRun(context: context, args: ["switch-branch", "--include-all"])

        #expect(shell.commands.contains(localGitCheck))
        #expect(shell.commands.contains(switchCmd))
        #expect(!shell.commands.contains(where: { $0.contains("git log -1") }))
        #expect(output.isEmpty)
    }
}

// MARK: - Helpers
private class StubBranchLoader: GitBranchLoaderProtocol {
    private let branches: [GitBranch]

    init(branches: [GitBranch]) {
        self.branches = branches
    }

    func loadBranches(from location: BranchLocation, shell: GitShell) throws -> [GitBranch] {
        return branches
    }
}