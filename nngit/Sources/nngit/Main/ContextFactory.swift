//
//  ContextFactory.swift
//  nngit
//
//  Created by Nikolai Nobadi on 2/12/26.
//

protocol ContextFactory {
    func makeShell() -> any NnGitShell
    func makePicker() -> any NnGitPicker
}
