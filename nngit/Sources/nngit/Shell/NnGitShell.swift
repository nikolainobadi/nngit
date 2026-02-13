//
//  NnGitShell.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

protocol NnGitShell {
    func bash(_ command: String) throws -> String
    func runAndPrint(bash command: String) throws
}
