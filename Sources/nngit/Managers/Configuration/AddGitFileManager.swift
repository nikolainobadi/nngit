//
//  AddGitFileManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import Foundation
import SwiftPicker

/// Manager for handling GitFile addition with interactive prompts and file management.
struct AddGitFileManager {
    private let configLoader: GitConfigLoader
    private let fileCreator: GitFileCreator
    
    init(configLoader: GitConfigLoader, fileCreator: GitFileCreator) {
        self.configLoader = configLoader
        self.fileCreator = fileCreator
    }
}


// MARK: - Main Workflow
extension AddGitFileManager {
    /// Adds a GitFile to the configuration with interactive prompts for missing information.
    func addGitFile(
        sourcePath: String?,
        fileName: String?,
        nickname: String?,
        useDirectPath: Bool,
        picker: CommandLinePicker
    ) throws {
        let resolvedSourcePath = try getSourcePath(sourcePath: sourcePath, picker: picker)
        let resolvedFileName = try getFileName(fileName: fileName, sourcePath: resolvedSourcePath, picker: picker)
        let resolvedNickname = try getNickname(nickname: nickname, fileName: resolvedFileName, picker: picker)
        
        let finalPath: String
        
        if useDirectPath {
            finalPath = resolvedSourcePath
            print("Using direct path: \(finalPath)")
        } else {
            finalPath = try copyToTemplatesDirectory(
                sourcePath: resolvedSourcePath,
                fileName: resolvedFileName,
                picker: picker
            )
            print("Copied template to: \(finalPath)")
        }
        
        let gitFile = GitFile(
            fileName: resolvedFileName,
            nickname: resolvedNickname,
            localPath: finalPath
        )
        
        try configLoader.addGitFile(gitFile, picker: picker)
        
        print("✅ Added GitFile '\(resolvedNickname)' (\(resolvedFileName))")
    }
}


// MARK: - Interactive Input Resolution
private extension AddGitFileManager {
    /// Gets the source path, prompting if not provided.
    func getSourcePath(sourcePath: String?, picker: CommandLinePicker) throws -> String {
        if let sourcePath = sourcePath {
            guard FileManager.default.fileExists(atPath: sourcePath) else {
                throw AddGitFileError.sourceFileNotFound(sourcePath)
            }
            return sourcePath
        }
        
        let inputPath = try picker.getRequiredInput("Enter path to template file:")
        guard FileManager.default.fileExists(atPath: inputPath) else {
            throw AddGitFileError.sourceFileNotFound(inputPath)
        }
        
        return inputPath
    }
    
    /// Gets the output filename, prompting with default if not provided.
    func getFileName(fileName: String?, sourcePath: String, picker: CommandLinePicker) throws -> String {
        if let fileName = fileName {
            return fileName
        }
        
        let sourceFileName = URL(fileURLWithPath: sourcePath).lastPathComponent
        let input = picker.getInput("Output filename (leave blank for '\(sourceFileName)'):")
        
        return input.isEmpty ? sourceFileName : input
    }
    
    /// Gets the nickname, prompting with default if not provided.
    func getNickname(nickname: String?, fileName: String, picker: CommandLinePicker) throws -> String {
        if let nickname = nickname {
            return nickname
        }
        
        let input = picker.getInput("Display name (leave blank for '\(fileName)'):")
        
        return input.isEmpty ? fileName : input
    }
    
    /// Copies the source file to the templates directory and returns the final path.
    func copyToTemplatesDirectory(
        sourcePath: String,
        fileName: String,
        picker: CommandLinePicker
    ) throws -> String {
        return try fileCreator.copyToTemplatesDirectory(
            sourcePath: sourcePath,
            fileName: fileName,
            picker: picker
        )
    }
}


// MARK: - Errors
enum AddGitFileError: Error {
    case sourceFileNotFound(String)
    case templateDirectoryCreationFailed
    case fileCopyFailed(String)
}