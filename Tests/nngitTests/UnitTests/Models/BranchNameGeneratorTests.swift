//
//  BranchNameGeneratorTests.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/9/25.
//

import Testing
@testable import nngit

struct BranchNameGeneratorTests {
    @Test("generates sanitized names when no options are provided")
    func sanitizedName() throws {
        let result = BranchNameGenerator.generate(name: "My Feature!")
        #expect(result == "my-feature")
    }

    @Test("includes branch type prefix")
    func includesBranchTypePrefix() throws {
        let result = BranchNameGenerator.generate(name: "Add login", branchPrefix: "feature")
        #expect(result == "feature/add-login")
    }

    @Test("adds issue number and prefix")
    func addsIssueNumberAndPrefix() throws {
        let result = BranchNameGenerator.generate(
            name: "Critical fix",
            branchPrefix: "bugfix",
            issueNumber: "42"
        )
        #expect(result == "bugfix/42/critical-fix")
    }

    @Test("strips non-alphanumeric characters")
    func stripsNonAlphaNumeric() throws {
        let result = BranchNameGenerator.generate(name: "Add login(#2)")
        #expect(result == "add-login2")
    }
    
    @Test("applies custom issue-number prefix when provided")
    func appliesIssueNumberPrefix() throws {
        let result = BranchNameGenerator.generate(
            name: "Critical fix",
            branchPrefix: "bugfix",
            issueNumber: "42",
            issueNumberPrefix: "ISS-"
        )
        #expect(result == "bugfix/ISS-42/critical-fix")
    }
}
