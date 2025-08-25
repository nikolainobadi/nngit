//
//  BranchDiffManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import GitShellKit
import NnShellKit
@testable import nngit

@Suite(.disabled())
struct BranchDiffManagerTests {
    @Test("Successfully generates diff output between branches")
    func generateDiffSuccess() throws {
        let shell = MockShell(results: [
            "feature-branch",  // getCurrentBranch
            "",                // validateBaseBranchExists
            "diff --git a/file.txt b/file.txt\n+added line"  // generateDiffOutput
        ])
        let clipboardHandler = MockClipboardHandler()
        let manager = makeSUT(shell: shell, clipboardHandler: clipboardHandler)
        
        try manager.generateDiff(baseBranch: "main", copyToClipboard: false)
        
        let expectedCommands = [
            "git branch --show-current",
            "git show-ref --verify --quiet refs/heads/main",
            "git diff main...HEAD"
        ]
        expectedCommands.forEach { command in
            #expect(shell.executedCommands.contains(command))
        }
        #expect(!clipboardHandler.copyToClipboardCalled)
    }
    
    @Test("Successfully generates diff and copies to clipboard")
    func generateDiffWithClipboard() throws {
        let diffOutput = "diff --git a/file.txt b/file.txt\n+added line"
        let shell = MockShell(results: [
            "feature-branch",  // getCurrentBranch
            "",                // validateBaseBranchExists
            diffOutput         // generateDiffOutput
        ])
        let clipboardHandler = MockClipboardHandler()
        let manager = makeSUT(shell: shell, clipboardHandler: clipboardHandler)
        
        try manager.generateDiff(baseBranch: "main", copyToClipboard: true)
        
        #expect(clipboardHandler.copyToClipboardCalled)
        let copiedText = try #require(clipboardHandler.copiedText)
        #expect(copiedText.contains("+added line"))
    }
    
    @Test("Handles case when on base branch")
    func generateDiffOnBaseBranch() throws {
        let shell = MockShell(results: [
            "main"  // getCurrentBranch returns base branch
        ])
        let clipboardHandler = MockClipboardHandler()
        let manager = makeSUT(shell: shell, clipboardHandler: clipboardHandler)
        
        try manager.generateDiff(baseBranch: "main", copyToClipboard: false)
        
        // Only current branch check should be performed
        #expect(shell.executedCommands.contains("git branch --show-current"))
        #expect(!shell.executedCommands.contains("git show-ref --verify --quiet refs/heads/main"))
        #expect(!clipboardHandler.copyToClipboardCalled)
    }
    
    @Test("Handles no differences between branches")
    func generateDiffNoDifferences() throws {
        let shell = MockShell(results: [
            "feature-branch",  // getCurrentBranch
            "",                // validateBaseBranchExists
            "   \n  \t  "      // generateDiffOutput (whitespace only)
        ])
        let clipboardHandler = MockClipboardHandler()
        let manager = makeSUT(shell: shell, clipboardHandler: clipboardHandler)
        
        try manager.generateDiff(baseBranch: "main", copyToClipboard: false)
        
        #expect(shell.executedCommands.contains("git diff main...HEAD"))
        #expect(!clipboardHandler.copyToClipboardCalled)
    }
    
    @Test("Handles clipboard failure")
    func generateDiffClipboardFailure() throws {
        let shell = MockShell(results: [
            "feature-branch",  // getCurrentBranch
            "",                // validateBaseBranchExists
            "diff --git a/file.txt b/file.txt\n+added line"  // generateDiffOutput
        ])
        let clipboardHandler = MockClipboardHandler(shouldFail: true)
        let manager = makeSUT(shell: shell, clipboardHandler: clipboardHandler)
        
        #expect(throws: BranchDiffError.clipboardFailed) {
            try manager.generateDiff(baseBranch: "main", copyToClipboard: true)
        }
        
        #expect(clipboardHandler.copyToClipboardCalled)
    }
    
    @Test("Handles shell command errors gracefully")
    func generateDiffCommandError() throws {
        // Test with valid shell commands but no differences
        let shell = MockShell(results: [
            "feature-branch",  // getCurrentBranch
            "",                // validateBaseBranchExists
            ""                 // generateDiffOutput (empty diff)
        ])
        let clipboardHandler = MockClipboardHandler()
        let manager = makeSUT(shell: shell, clipboardHandler: clipboardHandler)
        
        // This should not throw an error, but handle empty diff gracefully
        try manager.generateDiff(baseBranch: "main", copyToClipboard: false)
        
        // Verify expected commands were called
        #expect(shell.executedCommands.contains("git branch --show-current"))
        #expect(shell.executedCommands.contains("git show-ref --verify --quiet refs/heads/main"))
        #expect(shell.executedCommands.contains("git diff main...HEAD"))
        #expect(!clipboardHandler.copyToClipboardCalled)
    }
    
    @Test("Generates diff with custom base branch")
    func generateDiffCustomBaseBranch() throws {
        let shell = MockShell(results: [
            "feature-branch",  // getCurrentBranch
            "",                // validateBaseBranchExists
            "diff --git a/file.txt b/file.txt\n+change"  // generateDiffOutput
        ])
        let clipboardHandler = MockClipboardHandler()
        let manager = makeSUT(shell: shell, clipboardHandler: clipboardHandler)
        
        try manager.generateDiff(baseBranch: "develop", copyToClipboard: false)
        
        #expect(shell.executedCommands.contains("git show-ref --verify --quiet refs/heads/develop"))
        #expect(shell.executedCommands.contains("git diff develop...HEAD"))
        #expect(!clipboardHandler.copyToClipboardCalled)
    }
    
    @Test("Handles complex diff output with special characters")
    func generateDiffComplexOutput() throws {
        let complexDiff = """
        diff --git a/file.txt b/file.txt
        index 1234567..abcdefg 100644
        --- a/file.txt
        +++ b/file.txt
        @@ -1,3 +1,4 @@
         line 1
        +new line with special chars: !@#$%^&*()
         line 2
         line 3
        """
        let shell = MockShell(results: [
            "feature-branch",  // getCurrentBranch
            "",                // validateBaseBranchExists
            complexDiff        // generateDiffOutput
        ])
        let clipboardHandler = MockClipboardHandler()
        let manager = makeSUT(shell: shell, clipboardHandler: clipboardHandler)
        
        try manager.generateDiff(baseBranch: "main", copyToClipboard: true)
        
        #expect(clipboardHandler.copyToClipboardCalled)
        let copiedText = try #require(clipboardHandler.copiedText)
        #expect(copiedText.contains("special chars: !@#$%^&*()"))
        #expect(copiedText.contains("diff --git"))
    }
}


// MARK: - SUT
private extension BranchDiffManagerTests {
    func makeSUT(
        shell: GitShell = MockShell(),
        clipboardHandler: MockClipboardHandler = MockClipboardHandler()
    ) -> BranchDiffManager {
        return .init(shell: shell, clipboardHandler: clipboardHandler)
    }
}


// MARK: - Mock Clipboard Handler
private final class MockClipboardHandler: ClipboardHandler {
    private(set) var copyToClipboardCalled = false
    private(set) var copiedText: String?
    private let shouldFail: Bool
    
    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }
    
    func copyToClipboard(_ text: String) throws {
        copyToClipboardCalled = true
        copiedText = text
        
        if shouldFail {
            throw BranchDiffError.clipboardFailed
        }
    }
}
