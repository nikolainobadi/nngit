//
//  MockGitShell.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/22/25.
//

import GitShellKit
@testable import nngit

final class MockGitShell {
    private(set) var commands: [String] = []
    var responses: [String: String]
    var shouldThrowOnMissingCommand: Bool = false
    
    init(responses: [String: String]) {
        self.responses = responses
    }
}


// MARK: - Shell
extension MockGitShell: GitShell {
    func runWithOutput(_ command: String) throws -> String {
        commands.append(command)
        
        if let response = responses[command] {
            return response
        } else if shouldThrowOnMissingCommand {
            throw GitShellError.commandFailed(code: 1, command: command, output: "Command not found")
        } else {
            return ""
        }
    }
}
