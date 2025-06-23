//
//  MockGitShell.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/22/25.
//

import GitShellKit

final class MockGitShell {
    private(set) var commands: [String] = []
    var responses: [String: String]
    
    init(responses: [String: String]) {
        self.responses = responses
    }
}


// MARK: - Shell
extension MockGitShell: GitShell {
    func runWithOutput(_ command: String) throws -> String {
        commands.append(command)
        let output = responses[command] ?? ""
        return output
    }
}
