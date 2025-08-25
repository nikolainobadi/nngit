//
//  BranchDiffTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Testing
import NnShellKit
import GitShellKit
@testable import nngit

@MainActor
@Suite(.disabled())
struct BranchDiffTests {
    @Test("shows diff output for branch with changes")
    func showsDiffOutput() throws {
        let results = makeShellResults(diffResult: sampleDiffOutput)
        let context = makeContext(results: results).context
        let output = try runCommand(context)
        
        #expect(output.contains("📊 Showing diff between 'main' and 'feature/test-branch':"))
        #expect(output.contains("diff --git a/file.swift b/file.swift"))
        #expect(output.contains("+added line"))
    }
    
    @Test("shows no differences message when branches are identical")
    func showsNoDifferencesMessage() throws {
        let results = makeShellResults(diffResult: "")
        let context = makeContext(results: results).context
        let output = try runCommand(context)
        
        #expect(output.contains("No differences found between 'main' and current branch 'feature/test-branch'"))
    }
    
    @Test("shows message when on base branch")
    func showsMessageWhenOnBaseBranch() throws {
        let results = makeShellResults(onMainBranch: true)
        let context = makeContext(results: results).context
        let output = try runCommand(context)
        
        #expect(output.contains("You are currently on the base branch 'main'. No diff to show."))
    }
    
    @Test("uses custom base branch when provided")
    func usesCustomBaseBranch() throws {
        let results = makeShellResults(diffResult: sampleDiffOutput)
        let (context, shell) = makeContext(results: results)
        let output = try runCommand(context, baseBranch: "develop")
        
        #expect(output.contains("📊 Showing diff between 'develop' and 'feature/test-branch':"))
        #expect(shell.executedCommands.contains("git diff develop...HEAD"))
    }
}


// MARK: - Helper Methods
private extension BranchDiffTests {
    var sampleDiffOutput: String {
        "diff --git a/file.swift b/file.swift\nindex 1234567..abcdefg 100644\n--- a/file.swift\n+++ b/file.swift\n@@ -1,3 +1,4 @@\n line 1\n line 2\n+added line\n line 3"
    }
    
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
    
    func makeContext(results: [String] = []) -> (context: MockContext, shell: MockShell) {
        let shell = MockShell(results: results)
        let context = MockContext(shell: shell)
        
        return (context, shell)
    }
    
    func makeShellResults(onMainBranch: Bool = false, diffResult: String? = nil) -> [String] {
        var results = [
            "true",  // localGitCheck
            onMainBranch ? "main" : "feature/test-branch",  // git branch --show-current
        ]
        
        if let diffResult {
            results.append("") // git show-ref --verify --quiet refs/heads/develop
            results.append(diffResult)
        }
        
        return results
    }
}
