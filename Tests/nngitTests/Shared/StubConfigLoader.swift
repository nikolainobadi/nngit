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
    
    func addGitFile(_ gitFile: GitFile, picker: CommandLinePicker) throws {
        var config = try loadConfig(picker: picker)
        config.gitFiles.append(gitFile)
        savedConfig = config
    }
    
    func removeGitFile(named fileName: String, picker: CommandLinePicker) throws -> Bool {
        var config = try loadConfig(picker: picker)
        let initialCount = config.gitFiles.count
        config.gitFiles.removeAll { $0.fileName == fileName }
        savedConfig = config
        return config.gitFiles.count < initialCount
    }
}