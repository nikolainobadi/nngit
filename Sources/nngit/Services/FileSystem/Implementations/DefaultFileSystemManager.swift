//
//  DefaultFileSystemManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import Foundation

/// Default implementation of FileSystemManager using Foundation's FileManager.
struct DefaultFileSystemManager: FileSystemManager {
    private let fileManager = FileManager.default
    
    func fileExists(atPath path: String) -> Bool {
        return fileManager.fileExists(atPath: path)
    }
    
    func contentsOfFile(atPath path: String, encoding: String.Encoding) throws -> String {
        return try String(contentsOfFile: path, encoding: encoding)
    }
}