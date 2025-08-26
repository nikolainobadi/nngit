//
//  GitActivityManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/26/25.
//

import Testing
import GitShellKit
import NnShellKit
@testable import nngit

struct GitActivityManagerTests {
    @Test("Generates activity report for single day.")
    func generateActivityReportSingleDay() throws {
        let gitLogOutput = """
        a1b2c3d Initial commit
        3	1	README.md
        
        b4e5f6g Add feature
        2	0	src/main.swift
        1	2	src/helper.swift
        """
        let shell = MockShell(results: [gitLogOutput])
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 1, verbose: false)
        
        #expect(shell.executedCommands.contains("git log --since=\"midnight\" --pretty=format:\"%h %s\" --numstat"))
        #expect(report.contains("Git Activity Report (Last 1 Day):"))
        #expect(report.contains("Commits: 2"))
        #expect(report.contains("Files Changed: 3"))
        #expect(report.contains("Lines Added: 6"))
        #expect(report.contains("Lines Deleted: 3"))
        #expect(report.contains("Total Lines Modified: 9"))
    }
    
    @Test("Generates activity report for multiple days.")
    func generateActivityReportMultipleDays() throws {
        let gitLogOutput = """
        a1b2c3d Recent commit
        5	2	file1.swift
        
        b4e5f6g Older commit
        1	1	file2.swift
        """
        let shell = MockShell(results: [gitLogOutput])
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 7, verbose: false)
        
        #expect(shell.executedCommands.contains("git log --since=\"7 days ago\" --pretty=format:\"%h %s\" --numstat"))
        #expect(report.contains("Git Activity Report (Last 7 Days):"))
        #expect(report.contains("Commits: 2"))
        #expect(report.contains("Files Changed: 2"))
        #expect(report.contains("Lines Added: 6"))
        #expect(report.contains("Lines Deleted: 3"))
        #expect(report.contains("Total Lines Modified: 9"))
    }
    
    @Test("Generates verbose activity report with daily breakdown.")
    func generateVerboseActivityReport() throws {
        let gitLogOutput = """
        a1b2c3d First commit 2025-08-25
        2	1	file1.swift
        
        b4e5f6g Second commit 2025-08-25
        1	0	file2.swift
        
        c7d8e9f Third commit 2025-08-24
        3	2	file3.swift
        """
        let shell = MockShell(results: [gitLogOutput])
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 3, verbose: true)
        
        #expect(shell.executedCommands.contains("git log --since=\"3 days ago\" --pretty=format:\"%h %s %ad\" --date=short --numstat"))
        #expect(report.contains("Git Activity Report (Last 3 Days):"))
        #expect(report.contains("Commits: 3"))
        #expect(report.contains("Files Changed: 3"))
        #expect(report.contains("Lines Added: 6"))
        #expect(report.contains("Lines Deleted: 3"))
        #expect(report.contains("Daily Breakdown:"))
        #expect(report.contains("2025-08-24: 1 commit, 1 file, +3/-2 lines"))
        #expect(report.contains("2025-08-25: 2 commits, 2 files, +3/-1 lines"))
    }
    
    @Test("Handles zero activity when no commits found.")
    func generateReportWithZeroActivity() throws {
        let shell = MockShell(results: [""]) // empty output
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 1, verbose: false)
        
        #expect(report.contains("Git Activity Report (Last 1 Day):"))
        #expect(report.contains("Commits: 0"))
        #expect(report.contains("Files Changed: 0"))
        #expect(report.contains("Lines Added: 0"))
        #expect(report.contains("Lines Deleted: 0"))
        #expect(report.contains("Total Lines Modified: 0"))
    }
    
    @Test("Uses singular form for single day.")
    func usesSingularFormForSingleDay() throws {
        let shell = MockShell(results: [""]) // empty output
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 1, verbose: false)
        
        #expect(report.contains("Git Activity Report (Last 1 Day):"))
        #expect(!report.contains("Days)"))
    }
    
    @Test("Uses plural form for multiple days.")
    func usesPluralFormForMultipleDays() throws {
        let shell = MockShell(results: [""]) // empty output
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 30, verbose: false)
        
        #expect(report.contains("Git Activity Report (Last 30 Days):"))
    }
    
    @Test("Uses singular form for single commit.")
    func usesSingularFormForSingleCommit() throws {
        let gitLogOutput = """
        a1b2c3d Single commit
        1	1	file.swift
        """
        let shell = MockShell(results: [gitLogOutput])
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 1, verbose: false)
        
        #expect(report.contains("Commit: 1"))
        #expect(report.contains("File Changed: 1"))
    }
    
    @Test("Uses plural form for multiple commits and files.")
    func usesPluralFormForMultipleCommitsAndFiles() throws {
        let gitLogOutput = """
        a1b2c3d First commit
        1	0	file1.swift
        
        b4e5f6g Second commit
        2	1	file2.swift
        """
        let shell = MockShell(results: [gitLogOutput])
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 1, verbose: false)
        
        #expect(report.contains("Commits: 2"))
        #expect(report.contains("Files Changed: 2"))
    }
    
    @Test("Validates that days must be greater than zero.")
    func validatesDaysGreaterThanZero() throws {
        let shell = MockShell(results: [])
        let manager = makeSUT(shell: shell)
        
        #expect(throws: GitActivityError.invalidDays) {
            _ = try manager.generateActivityReport(days: 0, verbose: false)
        }
        
        #expect(throws: GitActivityError.invalidDays) {
            _ = try manager.generateActivityReport(days: -1, verbose: false)
        }
    }
    
    @Test("Prevents verbose flag when days equals 1.")
    func preventsVerboseWithSingleDay() throws {
        let shell = MockShell(results: [])
        let manager = makeSUT(shell: shell)
        
        #expect(throws: GitActivityError.verboseNotAllowedForSingleDay) {
            _ = try manager.generateActivityReport(days: 1, verbose: true)
        }
    }
    
    @Test("Allows verbose flag when days is greater than 1.")
    func allowsVerboseWithMultipleDays() throws {
        let gitLogOutput = """
        a1b2c3d Commit 2025-08-25
        1	0	file.swift
        """
        let shell = MockShell(results: [gitLogOutput])
        let manager = makeSUT(shell: shell)
        
        // Should not throw
        let report = try manager.generateActivityReport(days: 2, verbose: true)
        #expect(report.contains("Git Activity Report (Last 2 Days):"))
    }
    
    @Test("Ignores empty lines in git log output.")
    func ignoresEmptyLines() throws {
        let gitLogOutput = """
        
        a1b2c3d Commit with empty lines
        
        3	1	file.swift
        

        """
        let shell = MockShell(results: [gitLogOutput])
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 1, verbose: false)
        
        #expect(report.contains("Commit: 1"))
        #expect(report.contains("File Changed: 1"))
        #expect(report.contains("Lines Added: 3"))
        #expect(report.contains("Lines Deleted: 1"))
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
        let shell = MockShell(results: [gitLogOutput])
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 1, verbose: false)
        
        #expect(report.contains("Commits: 2"))
        #expect(report.contains("Files Changed: 3"))
        #expect(report.contains("Lines Added: 12"))
        #expect(report.contains("Lines Deleted: 8"))
        #expect(report.contains("Total Lines Modified: 20"))
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
        let shell = MockShell(results: [gitLogOutput])
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 5, verbose: true)
        
        let lines = report.split(separator: "\n").map(String.init)
        let dailyLines = lines.filter { $0.contains("2025-08-") }
        
        #expect(dailyLines.count == 3)
        #expect(dailyLines[0].contains("2025-08-24"))
        #expect(dailyLines[1].contains("2025-08-25"))
        #expect(dailyLines[2].contains("2025-08-26"))
    }
    
    @Test("Handles empty verbose output gracefully.")
    func handlesEmptyVerboseOutput() throws {
        let shell = MockShell(results: [""]) // empty output
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 7, verbose: true)
        
        #expect(report.contains("Git Activity Report (Last 7 Days):"))
        #expect(report.contains("Commits: 0"))
        #expect(!report.contains("Daily Breakdown:"))
    }
    
    @Test("Shows non-verbose output for multiple days without verbose flag.")
    func showsNonVerboseOutputForMultipleDays() throws {
        let gitLogOutput = """
        a1b2c3d First commit
        2	1	file1.swift
        
        b4e5f6g Second commit  
        1	0	file2.swift
        """
        let shell = MockShell(results: [gitLogOutput])
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 3, verbose: false)
        
        #expect(shell.executedCommands.contains("git log --since=\"3 days ago\" --pretty=format:\"%h %s\" --numstat"))
        #expect(report.contains("Git Activity Report (Last 3 Days):"))
        #expect(report.contains("Commits: 2"))
        #expect(!report.contains("Daily Breakdown:"))
    }
    
    @Test("Correctly identifies hex digit characters.")
    func identifiesHexDigits() throws {
        let gitLogOutput = """
        a1b2c3d Valid hex commit
        1	0	file1.swift
        
        g123456 Invalid hex commit (starts with g)
        2	1	file2.swift
        
        123abcd Valid hex commit
        1	1	file3.swift
        """
        let shell = MockShell(results: [gitLogOutput])
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 1, verbose: false)
        
        // Should only count commits that start with valid hex digits (a1b2c3d and 123abcd)
        // But all files are processed regardless of commit validity
        #expect(report.contains("Commits: 2"))
        #expect(report.contains("Files Changed: 3")) // All files are counted
        #expect(report.contains("Lines Added: 4"))  // 1+2+1
        #expect(report.contains("Lines Deleted: 2")) // 0+1+1
    }
    
    @Test("Handles git log output with malformed numstat lines.")
    func handlesMalformedNumstatLines() throws {
        let gitLogOutput = """
        a1b2c3d Valid commit
        1	0	file1.swift
        malformed	line	without	proper	tabs
        2	1	file2.swift
        invalid-additions	2	file3.swift
        3		file4.swift
        """
        let shell = MockShell(results: [gitLogOutput])
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 1, verbose: false)
        
        // Should only count valid numstat lines (1	0	file1.swift and 2	1	file2.swift)
        // malformed lines and lines with invalid numbers are ignored
        #expect(report.contains("Commits: 2")) // a1b2c3d and malformed line that looks like commit
        #expect(report.contains("Files Changed: 2")) // file1.swift and file2.swift
        #expect(report.contains("Lines Added: 3"))   // 1 + 2
        #expect(report.contains("Lines Deleted: 1")) // 0 + 1
    }
    
    @Test("Handles verbose output with missing dates.")
    func handlesVerboseOutputWithMissingDates() throws {
        let gitLogOutput = """
        a1b2c3d Commit without proper date format
        1	0	file1.swift
        
        b2c3d4e Commit with date 2025-08-25
        2	1	file2.swift
        
        c3d4e5f Another commit without date
        1	1	file3.swift
        """
        let shell = MockShell(results: [gitLogOutput])
        let manager = makeSUT(shell: shell)
        
        let report = try manager.generateActivityReport(days: 3, verbose: true)
        
        #expect(report.contains("Commits: 3"))
        #expect(report.contains("Files Changed: 3"))
        // Should only show daily breakdown for commits with valid dates
        #expect(report.contains("Daily Breakdown:"))
        #expect(report.contains("2025-08-25: 1 commit, 2 files, +3/-2 lines")) // Only b2c3d4e has valid date, but files are processed in order
    }
}


// MARK: - SUT
private extension GitActivityManagerTests {
    func makeSUT(shell: GitShell = MockShell()) -> GitActivityManager {
        return GitActivityManager(shell: shell)
    }
}