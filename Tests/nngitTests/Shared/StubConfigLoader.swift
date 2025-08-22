//
//  StubConfigLoader.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/21/25.
//

import SwiftPicker
@testable import nngit

final class StubConfigLoader: GitConfigLoader {
    private let initialConfig: GitConfig
    private(set) var savedConfig: GitConfig?
    
    init(initialConfig: GitConfig) {
        self.initialConfig = initialConfig
    }
    
    func loadConfig(picker: CommandLinePicker) throws -> GitConfig {
        initialConfig
    }
    
    func save(_ config: GitConfig) throws {
        savedConfig = config
    }
}
