//
//  BranchPrefixDisplayNameTests.swift
//  nngitTests
//
//  Created by Codex.
//

import Testing
@testable import nngit

struct BranchPrefixDisplayNameTests {
    @Test("returns just the name when no issue number is required")
    func nameOnly() throws {
        let prefix = BranchPrefix(name: "feature", requiresIssueNumber: false)
        #expect(prefix.displayName == "feature")
    }

    @Test("includes placeholder when issue number is required")
    func placeholderWithIssueNumber() throws {
        let prefix = BranchPrefix(name: "feat", requiresIssueNumber: true)
        #expect(prefix.displayName == "feat/<issueNumber>")
    }
    
    @Test("shows issue prefixes when configured")
    func showsIssuePrefixes() throws {
        let prefix = BranchPrefix(name: "feature", requiresIssueNumber: true, issuePrefixes: ["FRA-", "RAPP-", "BUG-"])
        #expect(prefix.displayName == "feature/[FRA-|RAPP-]<issue>")
    }
    
    @Test("handles single issue prefix")
    func handlesSingleIssuePrefix() throws {
        let prefix = BranchPrefix(name: "bugfix", requiresIssueNumber: true, issuePrefixes: ["FRA-"])
        #expect(prefix.displayName == "bugfix/[FRA-]<issue>")
    }
}
