import Testing
import GitShellKit
@testable import nngit

@MainActor
struct BranchDiffTests {
    @Test("shows diff output for branch with changes")
    func showsDiffOutput() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            "git branch --show-current": "feature/test-branch",
            "git show-ref --verify --quiet refs/heads/main": "",
            "git diff main...HEAD": "diff --git a/file.swift b/file.swift\nindex 1234567..abcdefg 100644\n--- a/file.swift\n+++ b/file.swift\n@@ -1,3 +1,4 @@\n line 1\n line 2\n+added line\n line 3"
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try runCommand(context)
        
        #expect(output.contains("📊 Showing diff between 'main' and 'feature/test-branch':"))
        #expect(output.contains("diff --git a/file.swift b/file.swift"))
        #expect(output.contains("+added line"))
    }
    
    @Test("shows no differences message when branches are identical")
    func showsNoDifferencesMessage() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            "git branch --show-current": "feature/test-branch",
            "git show-ref --verify --quiet refs/heads/main": "",
            "git diff main...HEAD": ""
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try runCommand(context)
        
        #expect(output.contains("No differences found between 'main' and current branch 'feature/test-branch'"))
    }
    
    @Test("shows message when on base branch")
    func showsMessageWhenOnBaseBranch() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            "git branch --show-current": "main"
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try runCommand(context)
        
        #expect(output.contains("You are currently on the base branch 'main'. No diff to show."))
    }
    
    @Test("shows error when base branch does not exist")
    func showsErrorWhenBaseBranchDoesNotExist() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            "git branch --show-current": "feature/test-branch"
        ]
        
        let shell = MockGitShell(responses: responses)
        shell.shouldThrowOnMissingCommand = true
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try runCommand(context)
        
        #expect(output.contains("Base branch 'main' does not exist."))
    }
    
    @Test("uses custom base branch when provided")
    func usesCustomBaseBranch() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            "git branch --show-current": "feature/test-branch",
            "git show-ref --verify --quiet refs/heads/develop": "",
            "git diff develop...HEAD": "diff --git a/file.swift b/file.swift\nindex 1234567..abcdefg 100644\n--- a/file.swift\n+++ b/file.swift\n@@ -1,3 +1,4 @@\n line 1\n line 2\n+added line\n line 3"
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try runCommand(context, baseBranch: "develop")
        
        #expect(output.contains("📊 Showing diff between 'develop' and 'feature/test-branch':"))
        #expect(shell.commands.contains("git diff develop...HEAD"))
    }
    
    @Test("shows copy confirmation when copy flag is used")
    func showsCopyConfirmationWhenCopyFlagUsed() throws {
        let responses = [
            makeGitCommand(.localGitCheck, path: nil): "true",
            "git branch --show-current": "feature/test-branch",
            "git show-ref --verify --quiet refs/heads/main": "",
            "git diff main...HEAD": "diff --git a/file.swift b/file.swift\nindex 1234567..abcdefg 100644\n--- a/file.swift\n+++ b/file.swift\n@@ -1,3 +1,4 @@\n line 1\n line 2\n+added line\n line 3"
        ]
        
        let shell = MockGitShell(responses: responses)
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)
        
        let output = try runCommand(context, copy: true)
        
        #expect(output.contains("✅ Diff copied to clipboard"))
        #expect(output.contains("📊 Showing diff between 'main' and 'feature/test-branch':"))
    }
}


// MARK: - Helper Methods
private extension BranchDiffTests {
    func runCommand(_ testFactory: NnGitContext, baseBranch: String? = nil, copy: Bool = false) throws -> String {
        var args = ["branch-diff"]
        
        if let baseBranch = baseBranch {
            args.append(contentsOf: ["--base-branch", baseBranch])
        }
        
        if copy {
            args.append("--copy")
        }
        
        return try Nngit.testRun(context: testFactory, args: args)
    }
}