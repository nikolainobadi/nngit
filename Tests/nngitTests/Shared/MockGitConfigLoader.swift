//
//  MockGitConfigLoader.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import SwiftPicker
@testable import nngit

final class MockGitConfigLoader: GitConfigLoader {
    private(set) var addedGitFile: GitFile?
    private let shouldThrowOnAdd: Bool
    
    init(shouldThrowOnAdd: Bool = false) {
        self.shouldThrowOnAdd = shouldThrowOnAdd
    }
    
    func save(_ config: GitConfig) throws {
        // Not needed for these tests
    }
    
    func loadConfig(picker: CommandLinePicker) throws -> GitConfig {
        // Not needed for these tests
        return GitConfig.defaultConfig
    }
    
    func addGitFile(_ gitFile: GitFile, picker: CommandLinePicker) throws {
        if shouldThrowOnAdd {
            throw TestError.configError
        }
        self.addedGitFile = gitFile
    }
    
    func removeGitFile(named fileName: String, picker: CommandLinePicker) throws -> Bool {
        // Not needed for these tests
        return true
    }
}

extension MockGitConfigLoader {
    enum TestError: Error {
        case configError
        case fileCreatorError
    }
}
