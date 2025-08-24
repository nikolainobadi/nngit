//
//  FileSystemManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import Foundation

/// Protocol for abstracting file system operations.
protocol FileSystemManager {
    /// Checks if a file exists at the given path.
    ///
    /// - Parameter path: The file path to check.
    /// - Returns: true if the file exists, false otherwise.
    func fileExists(atPath path: String) -> Bool
    
    /// Reads the contents of a file as a string.
    ///
    /// - Parameters:
    ///   - path: The file path to read from.
    ///   - encoding: The string encoding to use.
    /// - Returns: The contents of the file as a string.
    /// - Throws: An error if the file cannot be read.
    func contentsOfFile(atPath path: String, encoding: String.Encoding) throws -> String
    
    /// Copies a file from source path to destination path.
    ///
    /// - Parameters:
    ///   - srcPath: The source file path to copy from.
    ///   - dstPath: The destination file path to copy to.
    /// - Throws: An error if the file cannot be copied.
    func copyItem(atPath srcPath: String, toPath dstPath: String) throws
}