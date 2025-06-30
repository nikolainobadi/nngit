//
//  GitShellAdapter.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import SwiftShell
import GitShellKit

/// Concrete implementation of ``GitShell`` that executes commands using
/// ``SwiftShell``.
struct GitShellAdapter: GitShell {
    /// Runs the provided command via the underlying shell and returns the
    /// standard output produced by the command.
    ///
    /// - Parameter command: The git command to execute.
    /// - Returns: The standard output from the shell.
    func runWithOutput(_ command: String) throws -> String {
        let result = SwiftShell.run(bash: command)
        if result.exitcode != 0 {
            let output = (result.stdout + result.stderror).trimmingCharacters(in: .whitespacesAndNewlines)
            throw GitShellError.commandFailed(code: Int32(result.exitcode), command: command, output: output)
        }
        return result.stdout
    }
}

extension GitShell {
    /// Throws ``GitShellError.missingLocalGit`` if no git repository exists at
    /// the given path.
    func verifyLocalGitExists() throws {
        guard try localGitExists(at: nil) else {
            throw GitShellError.missingLocalGit
        }
    }
}
