//
//  GitShellAdapter.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import SwiftShell
import GitShellKit

struct GitShellAdapter: GitShell {
    func runWithOutput(_ command: String) throws -> String {
        // TODO: - maybe handle erros?
        return SwiftShell.run(bash: command).stdout
    }
}

extension GitShell {
    func verifyLocalGitExists() throws {
        guard try localGitExists(at: nil) else {
            throw GitShellError.missingLocalGit
        }
    }
}
