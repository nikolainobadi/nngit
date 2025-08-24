//
//  MockFileSystemManager.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import Foundation
@testable import nngit

final class MockFileSystemManager: FileSystemManager {
    private var existingFiles: Set<String> = []
    private var fileContents: [String: String] = [:]
    private(set) var copiedFiles: [(from: String, to: String)] = []
    
    init(existingFiles: [String] = [], fileContents: [String: String] = [:]) {
        self.existingFiles = Set(existingFiles)
        self.fileContents = fileContents
    }
    
    func fileExists(atPath path: String) -> Bool {
        return existingFiles.contains(path)
    }
    
    func contentsOfFile(atPath path: String, encoding: String.Encoding) throws -> String {
        guard let content = fileContents[path] else {
            throw MockFileSystemError.fileNotFound(path)
        }
        return content
    }
    
    func copyItem(atPath srcPath: String, toPath dstPath: String) throws {
        guard existingFiles.contains(srcPath) else {
            throw MockFileSystemError.fileNotFound(srcPath)
        }
        
        // Record the copy operation
        copiedFiles.append((from: srcPath, to: dstPath))
        
        // Simulate copying by adding the destination file
        existingFiles.insert(dstPath)
        if let content = fileContents[srcPath] {
            fileContents[dstPath] = content
        }
    }
    
    // Test helpers
    func addFile(path: String, content: String = "") {
        existingFiles.insert(path)
        fileContents[path] = content
    }
    
    func removeFile(path: String) {
        existingFiles.remove(path)
        fileContents.removeValue(forKey: path)
    }
}

enum MockFileSystemError: Error {
    case fileNotFound(String)
}