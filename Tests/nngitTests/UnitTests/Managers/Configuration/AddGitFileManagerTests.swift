//
//  AddGitFileManagerTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/31/25.
//

import Testing
import Foundation
import SwiftPicker
@testable import nngit

struct AddGitFileManagerTests {
    @Test("Successfully adds file when template name matches nickname.")
    func addFileByNickname() throws {
        let templateFile = "/templates/test.txt"
        let gitFile = GitFile(fileName: "test.txt", nickname: "Test File", localPath: templateFile)
        let configLoader = MockGitConfigLoader(customConfig: GitConfig(
            defaultBranch: "main",
            gitFiles: [gitFile]
        ))
        let fileSystemManager = MockFileSystemManager(existingFiles: [templateFile])
        let picker = MockPicker()
        
        let manager = AddGitFileManager(
            configLoader: configLoader,
            fileSystemManager: fileSystemManager,
            picker: picker
        )
        
        try manager.addGitFileToRepository(templateName: "Test File")
        
        #expect(fileSystemManager.copiedFiles.count == 1)
        #expect(fileSystemManager.copiedFiles[0].from == templateFile)
        #expect(fileSystemManager.copiedFiles[0].to == "test.txt")
    }
    
    @Test("Successfully adds file when template name matches filename.")
    func addFileByFilename() throws {
        let templateFile = "/templates/test.txt"
        let gitFile = GitFile(fileName: "test.txt", nickname: "My Test File", localPath: templateFile)
        let configLoader = MockGitConfigLoader(customConfig: GitConfig(
            defaultBranch: "main",
            gitFiles: [gitFile]
        ))
        let fileSystemManager = MockFileSystemManager(existingFiles: [templateFile])
        let picker = MockPicker()
        
        let manager = AddGitFileManager(
            configLoader: configLoader,
            fileSystemManager: fileSystemManager,
            picker: picker
        )
        
        try manager.addGitFileToRepository(templateName: "test.txt")
        
        #expect(fileSystemManager.copiedFiles.count == 1)
        #expect(fileSystemManager.copiedFiles[0].from == templateFile)
        #expect(fileSystemManager.copiedFiles[0].to == "test.txt")
    }
    
    @Test("Successfully selects file interactively when no name provided.")
    func addFileInteractively() throws {
        let templateFile1 = "/templates/file1.txt"
        let templateFile2 = "/templates/file2.txt"
        let gitFile1 = GitFile(fileName: "file1.txt", nickname: "File 1", localPath: templateFile1)
        let gitFile2 = GitFile(fileName: "file2.txt", nickname: "File 2", localPath: templateFile2)
        
        let configLoader = MockGitConfigLoader(customConfig: GitConfig(
            defaultBranch: "main",
            gitFiles: [gitFile1, gitFile2]
        ))
        let fileSystemManager = MockFileSystemManager(existingFiles: [templateFile1, templateFile2])
        let picker = MockPicker(selectionResponses: ["Select a template file to add:": 1]) // Select second file
        
        let manager = AddGitFileManager(
            configLoader: configLoader,
            fileSystemManager: fileSystemManager,
            picker: picker
        )
        
        try manager.addGitFileToRepository(templateName: nil)
        
        #expect(fileSystemManager.copiedFiles.count == 1)
        #expect(fileSystemManager.copiedFiles[0].from == templateFile2)
        #expect(fileSystemManager.copiedFiles[0].to == "file2.txt")
    }
    
    @Test("Prompts for overwrite when file exists.")
    func addFileOverwritePrompt() throws {
        let templateFile = "/templates/test.txt"
        let gitFile = GitFile(fileName: "test.txt", nickname: "Test File", localPath: templateFile)
        let configLoader = MockGitConfigLoader(customConfig: GitConfig(
            defaultBranch: "main",
            gitFiles: [gitFile]
        ))
        let fileSystemManager = MockFileSystemManager(existingFiles: [templateFile, "test.txt"]) // File already exists
        let picker = MockPicker(permissionResponses: ["File 'test.txt' already exists. Overwrite it?": true])
        
        let manager = AddGitFileManager(
            configLoader: configLoader,
            fileSystemManager: fileSystemManager,
            picker: picker
        )
        
        try manager.addGitFileToRepository(templateName: "Test File")
        
        #expect(fileSystemManager.copiedFiles.count == 1)
    }
    
    @Test("Cancels operation when user denies overwrite.")
    func addFileCancelOverwrite() throws {
        let templateFile = "/templates/test.txt"
        let gitFile = GitFile(fileName: "test.txt", nickname: "Test File", localPath: templateFile)
        let configLoader = MockGitConfigLoader(customConfig: GitConfig(
            defaultBranch: "main",
            gitFiles: [gitFile]
        ))
        let fileSystemManager = MockFileSystemManager(existingFiles: [templateFile, "test.txt"]) // File already exists
        let picker = MockPicker(permissionResponses: ["File 'test.txt' already exists. Overwrite it?": false])
        
        let manager = AddGitFileManager(
            configLoader: configLoader,
            fileSystemManager: fileSystemManager,
            picker: picker
        )
        
        try manager.addGitFileToRepository(templateName: "Test File")
        
        #expect(fileSystemManager.copiedFiles.isEmpty)
    }
    
    @Test("Throws error when no registered files exist.")
    func addFileNoRegisteredFiles() throws {
        let configLoader = MockGitConfigLoader(customConfig: GitConfig(
            defaultBranch: "main",
            gitFiles: []
        ))
        let fileSystemManager = MockFileSystemManager()
        let picker = MockPicker()
        
        let manager = AddGitFileManager(
            configLoader: configLoader,
            fileSystemManager: fileSystemManager,
            picker: picker
        )
        
        #expect(throws: AddGitFileError.noRegisteredFiles) {
            try manager.addGitFileToRepository(templateName: nil)
        }
    }
    
    @Test("Throws error when template not found.")
    func addFileTemplateNotFound() throws {
        let templateFile = "/templates/test.txt"
        let gitFile = GitFile(fileName: "test.txt", nickname: "Test File", localPath: templateFile)
        let configLoader = MockGitConfigLoader(customConfig: GitConfig(
            defaultBranch: "main",
            gitFiles: [gitFile]
        ))
        let fileSystemManager = MockFileSystemManager(existingFiles: [templateFile])
        let picker = MockPicker()
        
        let manager = AddGitFileManager(
            configLoader: configLoader,
            fileSystemManager: fileSystemManager,
            picker: picker
        )
        
        #expect(throws: AddGitFileError.templateNotFound("nonexistent")) {
            try manager.addGitFileToRepository(templateName: "nonexistent")
        }
    }
    
    @Test("Throws error when template file not found at registered path.")
    func addFileTemplateFileNotFound() throws {
        let templateFile = "/nonexistent/test.txt"
        let gitFile = GitFile(fileName: "test.txt", nickname: "Test File", localPath: templateFile)
        let configLoader = MockGitConfigLoader(customConfig: GitConfig(
            defaultBranch: "main",
            gitFiles: [gitFile]
        ))
        let fileSystemManager = MockFileSystemManager() // Template file doesn't exist
        let picker = MockPicker()
        
        let manager = AddGitFileManager(
            configLoader: configLoader,
            fileSystemManager: fileSystemManager,
            picker: picker
        )
        
        #expect(throws: AddGitFileError.templateFileNotFound(templateFile)) {
            try manager.addGitFileToRepository(templateName: "Test File")
        }
    }
    
    @Test("Handles partial matches with selection.")
    func addFilePartialMatchSelection() throws {
        let templateFile1 = "/templates/test1.txt"
        let templateFile2 = "/templates/test2.txt"
        let gitFile1 = GitFile(fileName: "test1.txt", nickname: "Test File 1", localPath: templateFile1)
        let gitFile2 = GitFile(fileName: "test2.txt", nickname: "Test File 2", localPath: templateFile2)
        
        let configLoader = MockGitConfigLoader(customConfig: GitConfig(
            defaultBranch: "main",
            gitFiles: [gitFile1, gitFile2]
        ))
        let fileSystemManager = MockFileSystemManager(existingFiles: [templateFile1, templateFile2])
        let picker = MockPicker(selectionResponses: ["Multiple templates match 'test'. Select one:": 0])
        
        let manager = AddGitFileManager(
            configLoader: configLoader,
            fileSystemManager: fileSystemManager,
            picker: picker
        )
        
        try manager.addGitFileToRepository(templateName: "test")
        
        #expect(fileSystemManager.copiedFiles.count == 1)
        #expect(fileSystemManager.copiedFiles[0].from == templateFile1)
        #expect(fileSystemManager.copiedFiles[0].to == "test1.txt")
    }
}