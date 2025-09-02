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
    private(set) var removedFileName: String?
    private(set) var savedConfig: GitConfig?
    private let shouldThrowOnAdd: Bool
    private let customConfig: GitConfig?
    private let mockGitFiles: [GitFile]
    var removeResult: Bool = true
    
    init(shouldThrowOnAdd: Bool = false, customConfig: GitConfig? = nil, mockGitFiles: [GitFile] = []) {
        self.shouldThrowOnAdd = shouldThrowOnAdd
        self.customConfig = customConfig
        self.mockGitFiles = mockGitFiles
    }
    
    func save(_ config: GitConfig) throws {
        self.savedConfig = config
    }
    
    func loadConfig() throws -> GitConfig {
        if !mockGitFiles.isEmpty {
            return GitConfig(defaultBranch: "main", gitFiles: mockGitFiles)
        }
        return customConfig ?? GitConfig.defaultConfig
    }
    
    func addGitFile(_ gitFile: GitFile) throws {
        if shouldThrowOnAdd {
            throw TestError.configError
        }
        self.addedGitFile = gitFile
    }
    
    func removeGitFile(named fileName: String) throws -> Bool {
        self.removedFileName = fileName
        return removeResult
    }
}

extension MockGitConfigLoader {
    enum TestError: Error {
        case configError
        case fileCreatorError
    }
}
