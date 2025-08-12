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

    @Test("adds issue number")
    func addsIssueNumber() throws {
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
    
    @Test("adds issue prefix to issue number")
    func addsIssuePrefix() throws {
        let result = BranchNameGenerator.generate(
            name: "login screen",
            branchPrefix: "feature",
            issueNumber: "36848",
            issuePrefix: "FRA-"
        )
        #expect(result == "feature/FRA-36848/login-screen")
    }
    
    @Test("handles empty branch name with issue")
    func handlesEmptyBranchName() throws {
        let result = BranchNameGenerator.generate(
            name: "",
            branchPrefix: "bugfix",
            issueNumber: "123",
            issuePrefix: "RAPP-"
        )
        #expect(result == "bugfix/RAPP-123")
    }
    
    @Test("handles issue without prefix")
    func handlesIssueWithoutPrefix() throws {
        let result = BranchNameGenerator.generate(
            name: "quick fix",
            branchPrefix: "feature",
            issueNumber: "NO-JIRA",
            issuePrefix: ""
        )
        #expect(result == "feature/NO-JIRA/quick-fix")
    }
    
}
