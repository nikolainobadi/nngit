//
//  MockGitFileCreator.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import SwiftPicker
@testable import nngit

final class MockGitFileCreator: GitFileCreator {
    private(set) var copiedSourcePath: String?
    private(set) var copiedFileName: String?
    private let copyResult: String
    private let shouldThrowOnCopy: Bool
    
    init(copyResult: String? = nil, shouldThrowOnCopy: Bool = false) {
        self.copyResult = copyResult ?? "/default/path"
        self.shouldThrowOnCopy = shouldThrowOnCopy
    }
    
    func createFile(named fileName: String, sourcePath: String, destinationPath: String?) throws {
        // Not needed for these tests
    }
    
    func createGitFiles(_ gitFiles: [GitFile], destinationPath: String?) throws {
        // Not needed for these tests
    }
    
    func copyToTemplatesDirectory(sourcePath: String, fileName: String, picker: CommandLinePicker) throws -> String {
        if shouldThrowOnCopy {
            throw MockGitConfigLoader.TestError.fileCreatorError
        }
        self.copiedSourcePath = sourcePath
        self.copiedFileName = fileName
        return copyResult
    }
}
