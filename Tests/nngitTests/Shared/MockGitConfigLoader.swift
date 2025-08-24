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
    private let customConfig: GitConfig?
    
    init(shouldThrowOnAdd: Bool = false, customConfig: GitConfig? = nil) {
        self.shouldThrowOnAdd = shouldThrowOnAdd
        self.customConfig = customConfig
    }
    
    func save(_ config: GitConfig) throws {
        // Not needed for these tests
    }
    
    func loadConfig() throws -> GitConfig {
        return customConfig ?? GitConfig.defaultConfig
    }
    
    func addGitFile(_ gitFile: GitFile) throws {
        if shouldThrowOnAdd {
            throw TestError.configError
        }
        self.addedGitFile = gitFile
    }
    
    func removeGitFile(named fileName: String) throws -> Bool {
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
