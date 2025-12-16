//
//  RegisterGitFileManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import Foundation

struct RegisterGitFileManager {
    private let picker: any GitPicker
    private let fileCreator: any GitFileCreator
    private let configLoader: any GitConfigLoader
    
    init(configLoader: any GitConfigLoader, fileCreator: any GitFileCreator, picker: any GitPicker) {
        self.picker = picker
        self.fileCreator = fileCreator
        self.configLoader = configLoader
    }
}


// MARK: - Main Workflow
extension RegisterGitFileManager {
    /// Adds a GitFile to the configuration with interactive prompts for missing information.
    func addGitFile(
        sourcePath: String?,
        fileName: String?,
        nickname: String?,
        useDirectPath: Bool
    ) throws {
        let resolvedSourcePath = try getSourcePath(sourcePath: sourcePath)
        let resolvedFileName = try getFileName(fileName: fileName, sourcePath: resolvedSourcePath)
        let resolvedNickname = try getNickname(nickname: nickname, fileName: resolvedFileName)
        
        let finalPath: String
        
        if useDirectPath {
            finalPath = resolvedSourcePath
            print("Using direct path: \(finalPath)")
        } else {
            finalPath = try copyToTemplatesDirectory(
                sourcePath: resolvedSourcePath,
                fileName: resolvedFileName
            )
            print("Copied template to: \(finalPath)")
        }
        
        let gitFile = GitFile(
            fileName: resolvedFileName,
            nickname: resolvedNickname,
            localPath: finalPath
        )
        
        try configLoader.addGitFile(gitFile)
        
        print("✅ Added GitFile '\(resolvedNickname)' (\(resolvedFileName))")
    }
}


// MARK: - Interactive Input Resolution
private extension RegisterGitFileManager {
    /// Gets the source path, prompting if not provided.
    func getSourcePath(sourcePath: String?) throws -> String {
        if let sourcePath = sourcePath {
            guard FileManager.default.fileExists(atPath: sourcePath) else {
                throw RegisterGitFileError.sourceFileNotFound(sourcePath)
            }
            return sourcePath
        }
        
        let inputPath = try picker.getRequiredInput("Enter path to template file:")
        guard FileManager.default.fileExists(atPath: inputPath) else {
            throw RegisterGitFileError.sourceFileNotFound(inputPath)
        }
        
        return inputPath
    }
    
    /// Gets the output filename, prompting with default if not provided.
    func getFileName(fileName: String?, sourcePath: String) throws -> String {
        if let fileName = fileName {
            return fileName
        }
        
        let sourceFileName = URL(fileURLWithPath: sourcePath).lastPathComponent
        let input = picker.getInput("Output filename (leave blank for '\(sourceFileName)'):")
        
        return input.isEmpty ? sourceFileName : input
    }
    
    /// Gets the nickname, prompting with default if not provided.
    func getNickname(nickname: String?, fileName: String) throws -> String {
        if let nickname = nickname {
            return nickname
        }
        
        let input = picker.getInput("Display name (leave blank for '\(fileName)'):")
        
        return input.isEmpty ? fileName : input
    }
    
    /// Copies the source file to the templates directory and returns the final path.
    func copyToTemplatesDirectory(
        sourcePath: String,
        fileName: String
    ) throws -> String {
        return try fileCreator.copyToTemplatesDirectory(
            sourcePath: sourcePath,
            fileName: fileName,
            picker: picker
        )
    }
}


// MARK: - Errors
enum RegisterGitFileError: Error, Equatable {
    case sourceFileNotFound(String)
    case templateDirectoryCreationFailed
    case fileCopyFailed(String)
}
