//
//  MockShell+GitShell.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import NnShellKit
import GitShellKit

extension MockShell: @retroactive GitShell {
    public func runWithOutput(_ command: String) throws -> String {
        return try bash(command)
    }
}