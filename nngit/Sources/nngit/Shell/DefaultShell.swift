//
//  DefaultShell.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import NnShellKit

struct DefaultShell {
    private let shell = NnShell()
}

// MARK: - NnGitShell
extension DefaultShell: NnGitShell {
    func bash(_ command: String) throws -> String {
        return try shell.bash(command)
    }

    func runAndPrint(bash command: String) throws {
        try shell.runAndPrint(bash: command)
    }
}
