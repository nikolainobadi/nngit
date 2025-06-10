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
        let config = makeConfig()
        let result = try BranchNameGenerator.generate(name: "My Feature!", branchType: nil, issueNumber: nil, config: config)
        #expect(result == "my-feature")
    }

    @Test("includes branch type prefix")
    func includesBranchTypePrefix() throws {
        let config = makeConfig()
        let result = try BranchNameGenerator.generate(name: "Add login", branchType: .feature, issueNumber: nil, config: config)
        #expect(result == "feature/add-login")
    }

    @Test("adds issue number and prefix")
    func addsIssueNumberAndPrefix() throws {
        let config = makeConfig(issueNumberPrefix: "JIRA")
        let result = try BranchNameGenerator.generate(name: "Critical fix", branchType: .bugfix, issueNumber: 42, config: config)
        #expect(result == "bugfix/JIRA-42/critical-fix")
    }

    @Test("strips non-alphanumeric characters")
    func stripsNonAlphaNumeric() throws {
        let config = makeConfig()
        let result = try BranchNameGenerator.generate(name: "Add login(#2)", branchType: nil, issueNumber: nil, config: config)
        #expect(result == "add-login2")
    }
}


// MARK: - Private Methods
private extension BranchNameGeneratorTests {
    func makeConfig(issueNumberPrefix: String? = nil) -> GitConfig {
        GitConfig(
            defaultBranch: "main",
            issueNumberPrefix: issueNumberPrefix,
            rebaseWhenBranchingFromDefaultBranch: false
        )
    }
}
