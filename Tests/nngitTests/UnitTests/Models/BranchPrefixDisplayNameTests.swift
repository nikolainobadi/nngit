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
        let prefix = BranchPrefix(name: "feature", requiresIssueNumber: false, issueNumberPrefix: nil)
        #expect(prefix.displayName == "feature")
    }

    @Test("includes placeholder when issue number is required without prefix")
    func placeholderNoPrefix() throws {
        let prefix = BranchPrefix(name: "feat", requiresIssueNumber: true, issueNumberPrefix: nil)
        #expect(prefix.displayName == "feat/<issueNumber>")
    }

    @Test("includes prefix and placeholder when issue number prefix exists")
    func prefixAndPlaceholder() throws {
        let prefix = BranchPrefix(name: "feat", requiresIssueNumber: true, issueNumberPrefix: "ISS-")
        #expect(prefix.displayName == "feat/ISS-<issueNumber>")
    }
}
