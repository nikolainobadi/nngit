//
//  GitShellAdapter.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import NnShellKit
import GitShellKit

/// Concrete implementation of ``GitShell`` that executes commands using
/// ``NnShellKit``.
struct GitShellAdapter: GitShell {
    private let shell: Shell
    
    /// Initializes the adapter with a shell implementation.
    ///
    /// - Parameter shell: The shell to use for command execution. Defaults to NnShell().
    init(shell: Shell = NnShell()) {
        self.shell = shell
    }
    
    /// Runs the provided command via the underlying shell and returns the
    /// standard output produced by the command.
    ///
    /// - Parameter command: The git command to execute.
    /// - Returns: The standard output from the shell.
    func runWithOutput(_ command: String) throws -> String {
        do {
            return try shell.bash(command)
        } catch let shellError as ShellError {
            switch shellError {
            case .failed(_, let code, let output):
                throw GitShellError.commandFailed(code: code, command: command, output: output)
            }
        }
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
