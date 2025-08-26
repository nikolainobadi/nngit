//
//  GitActivityTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Testing
import NnShellKit
import SwiftPicker
import GitShellKit
import ArgumentParser
@testable import nngit

@MainActor
struct GitActivityTests {
    @Test("Shows default activity for today when no days option provided.")
    func showsDefaultActivityForToday() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let gitLogOutput = """
        a1b2c3d Initial commit
        3	1	README.md
        
        b4e5f6g Add feature
        2	0	src/main.swift
        1	2	src/helper.swift
        """
        let shell = MockShell(results: [
            "true",  // localGitCheck
            gitLogOutput  // git log command
        ])
        let context = MockContext(shell: shell)

        let output = try runCommand(context: context)
        
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains("git log --since=\"midnight\" --pretty=format:\"%h %s\" --numstat"))
        #expect(output.contains("Git Activity Report (Last 1 Day):"))
        #expect(output.contains("Commits: 2"))
        #expect(output.contains("Files Changed: 3"))
        #expect(output.contains("Lines Added: 6"))
        #expect(output.contains("Lines Deleted: 3"))
        #expect(output.contains("Total Lines Modified: 9"))
    }

    @Test("Shows activity for specified number of days.")
    func showsActivityForSpecifiedDays() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let gitLogOutput = """
        a1b2c3d Recent commit
        5	2	file1.swift
        
        b4e5f6g Older commit
        1	1	file2.swift
        """
        let shell = MockShell(results: [
            "true",  // localGitCheck
            gitLogOutput  // git log command
        ])
        let context = MockContext(shell: shell)

        let output = try runCommand(context: context, additionalArgs: ["--days", "7"])
        
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains("git log --since=\"7 days ago\" --pretty=format:\"%h %s\" --numstat"))
        #expect(output.contains("Git Activity Report (Last 7 Days):"))
        #expect(output.contains("Commits: 2"))
        #expect(output.contains("Files Changed: 2"))
        #expect(output.contains("Lines Added: 6"))
        #expect(output.contains("Lines Deleted: 3"))
        #expect(output.contains("Total Lines Modified: 9"))
    }

    @Test("Shows zero activity when no commits found.")
    func showsZeroActivityWhenNoCommits() throws {
        let shell = MockShell(results: [
            "true",  // localGitCheck
            ""       // empty git log output
        ])
        let context = MockContext(shell: shell)

        let output = try runCommand(context: context)
        
        #expect(output.contains("Git Activity Report (Last 1 Day):"))
        #expect(output.contains("Commits: 0"))
        #expect(output.contains("Files Changed: 0"))
        #expect(output.contains("Lines Added: 0"))
        #expect(output.contains("Lines Deleted: 0"))
        #expect(output.contains("Total Lines Modified: 0"))
    }

    @Test("Handles mixed numstat and commit lines correctly.")
    func handlesMixedOutput() throws {
        let gitLogOutput = """
        a1b2c3d First commit
        10	5	file1.swift
        2	0	file2.swift
        
        b4e5f6g Second commit
        0	3	file3.swift
        """
        let shell = MockShell(results: [
            "true",  // localGitCheck
            gitLogOutput
        ])
        let context = MockContext(shell: shell)

        let output = try runCommand(context: context)
        
        #expect(output.contains("Commits: 2"))
        #expect(output.contains("Files Changed: 3"))
        #expect(output.contains("Lines Added: 12"))
        #expect(output.contains("Lines Deleted: 8"))
        #expect(output.contains("Total Lines Modified: 20"))
    }

    @Test("Uses singular form for single day.")
    func usesSingularFormForSingleDay() throws {
        let shell = MockShell(results: [
            "true",  // localGitCheck
            ""       // empty output
        ])
        let context = MockContext(shell: shell)

        let output = try runCommand(context: context, additionalArgs: ["--days", "1"])
        
        #expect(output.contains("Git Activity Report (Last 1 Day):"))
    }

    @Test("Uses plural form for multiple days.")
    func usesPluralFormForMultipleDays() throws {
        let shell = MockShell(results: [
            "true",  // localGitCheck
            ""       // empty output
        ])
        let context = MockContext(shell: shell)

        let output = try runCommand(context: context, additionalArgs: ["--days", "30"])
        
        #expect(output.contains("Git Activity Report (Last 30 Days):"))
    }

    @Test("Uses singular form for single commit.")
    func usesSingularFormForSingleCommit() throws {
        let gitLogOutput = """
        a1b2c3d Single commit
        1	1	file.swift
        """
        let shell = MockShell(results: [
            "true",  // localGitCheck
            gitLogOutput
        ])
        let context = MockContext(shell: shell)

        let output = try runCommand(context: context)
        
        #expect(output.contains("Commit: 1"))
        #expect(output.contains("File Changed: 1"))
    }

    @Test("Uses plural form for multiple commits and files.")
    func usesPluralFormForMultipleCommitsAndFiles() throws {
        let gitLogOutput = """
        a1b2c3d First commit
        1	0	file1.swift
        
        b4e5f6g Second commit
        2	1	file2.swift
        """
        let shell = MockShell(results: [
            "true",  // localGitCheck
            gitLogOutput
        ])
        let context = MockContext(shell: shell)

        let output = try runCommand(context: context)
        
        #expect(output.contains("Commits: 2"))
        #expect(output.contains("Files Changed: 2"))
    }

    @Test("Validates that days must be greater than zero.")
    func validatesDaysGreaterThanZero() throws {
        let shell = MockShell(results: ["true"])  // localGitCheck
        let context = MockContext(shell: shell)

        // Note: This test verifies runtime validation, not ArgumentParser validation
        #expect {
            _ = try runCommand(context: context, additionalArgs: ["--days", "0"])
        } throws: { error in
            // Any error thrown indicates validation worked
            return true
        }
    }

    @Test("Ignores empty lines in git log output.")
    func ignoresEmptyLines() throws {
        let gitLogOutput = """
        
        a1b2c3d Commit with empty lines
        
        3	1	file.swift
        

        """
        let shell = MockShell(results: [
            "true",  // localGitCheck
            gitLogOutput
        ])
        let context = MockContext(shell: shell)

        let output = try runCommand(context: context)
        
        #expect(output.contains("Commit: 1"))
        #expect(output.contains("File Changed: 1"))
        #expect(output.contains("Lines Added: 3"))
        #expect(output.contains("Lines Deleted: 1"))
    }

    @Test("Shows verbose output with daily breakdown for multiple days.")
    func showsVerboseOutputWithDailyBreakdown() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let gitLogOutput = """
        a1b2c3d First commit 2025-08-25
        2	1	file1.swift
        
        b4e5f6g Second commit 2025-08-25
        1	0	file2.swift
        
        c7d8e9f Third commit 2025-08-24
        3	2	file3.swift
        """
        let shell = MockShell(results: [
            "true",  // localGitCheck
            gitLogOutput
        ])
        let context = MockContext(shell: shell)

        let output = try runCommand(context: context, additionalArgs: ["--days", "3", "--verbose"])
        
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains("git log --since=\"3 days ago\" --pretty=format:\"%h %s %ad\" --date=short --numstat"))
        #expect(output.contains("Git Activity Report (Last 3 Days):"))
        #expect(output.contains("Commits: 3"))
        #expect(output.contains("Files Changed: 3"))
        #expect(output.contains("Lines Added: 6"))
        #expect(output.contains("Lines Deleted: 3"))
        #expect(output.contains("Daily Breakdown:"))
        #expect(output.contains("2025-08-24: 1 commit, 1 file, +3/-2 lines"))
        #expect(output.contains("2025-08-25: 2 commits, 2 files, +3/-1 lines"))
    }

    @Test("Prevents verbose flag when days equals 1.")
    func preventsVerboseWithSingleDay() throws {
        let shell = MockShell(results: ["true"])  // localGitCheck
        let context = MockContext(shell: shell)

        #expect {
            _ = try runCommand(context: context, additionalArgs: ["--verbose"])
        } throws: { error in
            return true
        }
    }

    @Test("Prevents verbose flag when days explicitly set to 1.")
    func preventsVerboseWithExplicitSingleDay() throws {
        let shell = MockShell(results: ["true"])  // localGitCheck
        let context = MockContext(shell: shell)

        #expect {
            _ = try runCommand(context: context, additionalArgs: ["--days", "1", "--verbose"])
        } throws: { error in
            return true
        }
    }

    @Test("Shows non-verbose output for multiple days without verbose flag.")
    func showsNonVerboseOutputForMultipleDays() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let gitLogOutput = """
        a1b2c3d First commit
        2	1	file1.swift
        
        b4e5f6g Second commit  
        1	0	file2.swift
        """
        let shell = MockShell(results: [
            "true",  // localGitCheck
            gitLogOutput
        ])
        let context = MockContext(shell: shell)

        let output = try runCommand(context: context, additionalArgs: ["--days", "3"])
        
        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(shell.executedCommands.contains("git log --since=\"3 days ago\" --pretty=format:\"%h %s\" --numstat"))
        #expect(output.contains("Git Activity Report (Last 3 Days):"))
        #expect(output.contains("Commits: 2"))
        #expect(!output.contains("Daily Breakdown:"))
    }

    @Test("Handles empty verbose output gracefully.")
    func handlesEmptyVerboseOutput() throws {
        let shell = MockShell(results: [
            "true",  // localGitCheck
            ""       // empty git log output
        ])
        let context = MockContext(shell: shell)

        let output = try runCommand(context: context, additionalArgs: ["--days", "7", "--verbose"])
        
        #expect(output.contains("Git Activity Report (Last 7 Days):"))
        #expect(output.contains("Commits: 0"))
        #expect(!output.contains("Daily Breakdown:"))
    }

    @Test("Sorts daily breakdown by date.")
    func sortsDailyBreakdownByDate() throws {
        let gitLogOutput = """
        a1b2c3d Latest commit 2025-08-26
        1	0	file1.swift
        
        b4e5f6g Middle commit 2025-08-25
        2	1	file2.swift
        
        c7d8e9f Earliest commit 2025-08-24
        1	1	file3.swift
        """
        let shell = MockShell(results: [
            "true",  // localGitCheck
            gitLogOutput
        ])
        let context = MockContext(shell: shell)

        let output = try runCommand(context: context, additionalArgs: ["--days", "5", "--verbose"])
        
        let lines = output.split(separator: "\n").map(String.init)
        let dailyLines = lines.filter { $0.contains("2025-08-") }
        
        #expect(dailyLines.count == 3)
        #expect(dailyLines[0].contains("2025-08-24"))
        #expect(dailyLines[1].contains("2025-08-25"))
        #expect(dailyLines[2].contains("2025-08-26"))
    }
}


// MARK: - Run
private extension GitActivityTests {
    func runCommand(context: MockContext, additionalArgs: [String] = []) throws -> String {
        return try Nngit.testRun(context: context, args: ["activity", "--no-color"] + additionalArgs)
    }
}
