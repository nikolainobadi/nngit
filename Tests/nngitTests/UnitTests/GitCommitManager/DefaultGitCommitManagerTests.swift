//
//  DefaultGitCommitManagerTests.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/22/25.
//

import Testing
import NnShellKit
import GitShellKit
@testable import nngit

struct DefaultGitCommitManagerTests {
    @Test("parses commit logs returned from git")
    func parsesCommitLogs() throws {
        let results = [
            "John Doe",  // git config user.name
            """
abc123 - Initial commit (John Doe, 2 weeks ago)
def456 - Update README (Jane Smith, 3 days ago)
"""  // git log -n 2 --pretty=format:'%h - %s (%an, %ar)'
        ]
        
        let (sut, shell) = makeSUT(results: results)
        let info = try sut.getCommitInfo(count: 2)

        #expect(shell.executedCommands == [
            "git config user.name",
            "git log -n 2 --pretty=format:'%h - %s (%an, %ar)'"
        ])
        #expect(info.count == 2)
        #expect(info[0].hash == "abc123")
        #expect(info[0].message == "Initial commit")
        #expect(info[0].author == "John Doe")
        #expect(info[0].date == "2 weeks ago")
        #expect(info[0].wasAuthoredByCurrentUser)
        #expect(info[1].hash == "def456")
        #expect(info[1].message == "Update README")
        #expect(info[1].author == "Jane Smith")
        #expect(info[1].date == "3 days ago")
        #expect(!info[1].wasAuthoredByCurrentUser)
    }

    @Test("performs hard reset when undoing commits")
    func performsReset() throws {
        let results = [""]  // git reset --hard HEAD~3
        let (sut, shell) = makeSUT(results: results)

        try sut.undoCommits(count: 3)

        #expect(shell.executedCommands == ["git reset --hard HEAD~3"])
    }
}


// MARK: - SUT
private extension DefaultGitCommitManagerTests {
    func makeSUT(results: [String] = []) -> (sut: DefaultGitCommitManager, shell: MockShell) {
        let shell = MockShell(results: results)
        let sut = DefaultGitCommitManager(shell: shell)
        
        return (sut, shell)
    }
}
