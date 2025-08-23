//
//  GitShellError.swift
//  nngit
//
//  Created by OpenAI's Codex on 6/30/25.
//

import Foundation

/// Errors that can be thrown by ``GitShell`` implementations.
enum GitShellError: Error, Equatable {
    /// No git repository exists at the specified location.
    case missingLocalGit
    /// Indicates a git command exited with a non-zero status code.
    /// - Parameters:
    ///   - code: Exit status of the command.
    ///   - command: The command that was executed.
    ///   - output: Combined stdout and stderr from the command.
    case commandFailed(code: Int32, command: String, output: String)
}

extension GitShellError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .missingLocalGit:
            return "A git repository was not found at the specified location."
        case let .commandFailed(code, command, output):
            return "Git command failed (exit code \(code)): \(command)\n\(output)"
        }
    }
}
