//
//  DefaultGitFileCreator.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import Foundation
import SwiftPicker

/// Default implementation of ``GitFileCreator`` using Foundation's FileManager.
struct DefaultGitFileCreator: GitFileCreator {
    private let fileManager = FileManager.default
}


// MARK: - Actions
extension DefaultGitFileCreator {
    /// Creates a single file by copying from source to destination.
    func createFile(named fileName: String, sourcePath: String, destinationPath: String?) throws {
        guard !sourcePath.isEmpty else {
            throw GitFileError.missingSourcePath
        }
        
        let sourceURL = URL(fileURLWithPath: sourcePath)
        guard fileManager.fileExists(atPath: sourcePath) else {
            throw GitFileError.sourceFileNotFound(sourcePath)
        }
        
        let destinationURL = getDestinationURL(fileName: fileName, destinationPath: destinationPath)
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
    }
    
    /// Creates multiple files from GitFile configurations.
    func createGitFiles(_ gitFiles: [GitFile], destinationPath: String?) throws {
        for gitFile in gitFiles {
            try createFile(named: gitFile.fileName, sourcePath: gitFile.localPath, destinationPath: destinationPath)
        }
    }
    
    /// Copies a source file to the templates directory and returns the final path.
    func copyToTemplatesDirectory(sourcePath: String, fileName: String, picker: CommandLinePicker) throws -> String {
        let templatesDirectory = try getOrCreateTemplatesDirectory(picker: picker)
        let destinationURL = templatesDirectory.appendingPathComponent(fileName)
        let sourceURL = URL(fileURLWithPath: sourcePath)
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            if !picker.getPermission("Template file '\(fileName)' already exists. Replace it?") {
                return destinationURL.path
            }
            try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.copyItem(at: sourceURL, to: destinationURL)
        
        return destinationURL.path
    }
}


// MARK: - Private Methods
private extension DefaultGitFileCreator {
    /// Gets the destination URL for the file, using current directory if destinationPath is nil.
    func getDestinationURL(fileName: String, destinationPath: String?) -> URL {
        let baseURL: URL
        
        if let destinationPath = destinationPath {
            baseURL = URL(fileURLWithPath: destinationPath)
        } else {
            baseURL = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        }
        
        return baseURL.appendingPathComponent(fileName)
    }
    
    /// Gets or creates the templates directory, asking for permission if needed.
    func getOrCreateTemplatesDirectory(picker: CommandLinePicker) throws -> URL {
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        let configDirectory = homeDirectory.appendingPathComponent(".config")
        let nngitDirectory = configDirectory.appendingPathComponent("nngit")
        let templatesDirectory = nngitDirectory.appendingPathComponent("templates")
        
        if !fileManager.fileExists(atPath: templatesDirectory.path) {
            if !picker.getPermission("Create templates directory at '\(templatesDirectory.path)'?") {
                throw GitFileError.templateDirectoryCreationDenied
            }
            
            try fileManager.createDirectory(at: templatesDirectory, withIntermediateDirectories: true)
        }
        
        return templatesDirectory
    }
}


// MARK: - Errors
enum GitFileError: Error {
    case missingSourcePath
    case sourceFileNotFound(String)
    case templateDirectoryCreationDenied
}