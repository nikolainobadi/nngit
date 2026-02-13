//
//  DefaultContextFactory.swift
//  nngit
//
//  Created by Nikolai Nobadi on 6/8/25.
//

import SwiftPickerKit

struct DefaultContextFactory: ContextFactory {
    func makeShell() -> any NnGitShell {
        DefaultShell()
    }

    func makePicker() -> any NnGitPicker {
        fatalError()
    }
}
