//
//  AddGitFileTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import Testing
import Foundation
import SwiftPicker
import GitShellKit
import NnShellKit
@testable import nngit

final class AddGitFileTests {
    private let tempDirectory: URL
    private let fileManager = FileManager.default
    
    init() {
        // Create unique temp directory for this test instance
        tempDirectory = fileManager.temporaryDirectory
            .appendingPathComponent("AddGitFileTests-\(UUID().uuidString)")
        try! fileManager.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    deinit {
        // Clean up entire temp directory
        try? fileManager.removeItem(at: tempDirectory)
    }
}


// MARK: - Tests
@MainActor
extension AddGitFileTests {
    @Test("Successfully adds GitFile with all parameters and direct path.")
    func addGitFileWithAllParametersDirectPath() throws {
        let sourcePath = try createTempFile(named: "test.txt", content: "test content")
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let configLoader = MockGitConfigLoader()
        let shell = MockShell(results: ["true"]) // localGitCheck
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(
            context: context, 
            args: [
                "add-git-file",
                "--source", sourcePath,
                "--name", "test.txt",
                "--nickname", "Test File",
                "--direct-path"
            ]
        )

        #expect(shell.executedCommands.contains(localGitCheck))
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.fileName == "test.txt")
        #expect(addedFile.nickname == "Test File")
        #expect(addedFile.localPath == sourcePath)
        #expect(output.contains("Using direct path:"))
        #expect(output.contains("✅ Added GitFile 'Test File' (test.txt)"))
    }
    
    @Test("Successfully adds GitFile with all parameters and template copy.")
    func addGitFileWithAllParametersTemplateCopy() throws {
        let sourcePath = try createTempFile(named: "template.txt", content: "template content")
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let configLoader = MockGitConfigLoader()
        let fileCreator = MockGitFileCreator(copyResult: "/templates/template.txt")
        let shell = MockShell(results: ["true"]) // localGitCheck
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, fileCreator: fileCreator)

        let output = try Nngit.testRun(
            context: context, 
            args: [
                "add-git-file",
                "--source", sourcePath,
                "--name", "template.txt",
                "--nickname", "Template File"
            ]
        )

        #expect(shell.executedCommands.contains(localGitCheck))
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.fileName == "template.txt")
        #expect(addedFile.nickname == "Template File")
        #expect(addedFile.localPath == "/templates/template.txt")
        #expect(output.contains("Copied template to:"))
        #expect(output.contains("✅ Added GitFile 'Template File' (template.txt)"))
    }
    
    @Test("Prompts for source path when not provided.")
    func promptsForSourcePath() throws {
        let sourcePath = try createTempFile(named: "prompted.txt", content: "prompted content")
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let configLoader = MockGitConfigLoader()
        let shell = MockShell(results: ["true"]) // localGitCheck
        let picker = MockPicker(
            requiredInputResponses: ["Enter path to template file:": sourcePath]
        )
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(
            context: context, 
            args: [
                "add-git-file",
                "--name", "prompted.txt",
                "--nickname", "Prompted File",
                "--direct-path"
            ]
        )

        #expect(shell.executedCommands.contains(localGitCheck))
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.fileName == "prompted.txt")
        #expect(addedFile.nickname == "Prompted File")
        #expect(addedFile.localPath == sourcePath)
        #expect(output.contains("✅ Added GitFile 'Prompted File' (prompted.txt)"))
    }
    
    @Test("Uses source filename when name not provided.")
    func usesSourceFileNameWhenNotProvided() throws {
        let sourcePath = try createTempFile(named: "source-file.txt", content: "content")
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let configLoader = MockGitConfigLoader()
        let shell = MockShell(results: ["true"]) // localGitCheck
        let picker = MockPicker(
            requiredInputResponses: ["Output filename (leave blank for 'source-file.txt'):": ""]
        )
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(
            context: context, 
            args: [
                "add-git-file",
                "--source", sourcePath,
                "--nickname", "Source File",
                "--direct-path"
            ]
        )

        #expect(shell.executedCommands.contains(localGitCheck))
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.fileName == "source-file.txt")
        #expect(addedFile.nickname == "Source File")
        #expect(output.contains("✅ Added GitFile 'Source File' (source-file.txt)"))
    }
    
    @Test("Uses custom filename when prompted.")
    func usesCustomFileNameWhenPrompted() throws {
        let sourcePath = try createTempFile(named: "original.txt", content: "content")
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let configLoader = MockGitConfigLoader()
        let shell = MockShell(results: ["true"]) // localGitCheck
        let picker = MockPicker(
            requiredInputResponses: ["Output filename (leave blank for 'original.txt'):": "custom.txt"]
        )
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(
            context: context, 
            args: [
                "add-git-file",
                "--source", sourcePath,
                "--nickname", "Custom File",
                "--direct-path"
            ]
        )

        #expect(shell.executedCommands.contains(localGitCheck))
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.fileName == "custom.txt")
        #expect(addedFile.nickname == "Custom File")
        #expect(output.contains("✅ Added GitFile 'Custom File' (custom.txt)"))
    }
    
    @Test("Uses filename as nickname when nickname not provided.")
    func usesFileNameAsNicknameWhenNotProvided() throws {
        let sourcePath = try createTempFile(named: "auto-nickname.txt", content: "content")
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let configLoader = MockGitConfigLoader()
        let shell = MockShell(results: ["true"]) // localGitCheck
        let picker = MockPicker(
            requiredInputResponses: ["Display name (leave blank for 'auto-nickname.txt'):": ""]
        )
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(
            context: context, 
            args: [
                "add-git-file",
                "--source", sourcePath,
                "--name", "auto-nickname.txt",
                "--direct-path"
            ]
        )

        #expect(shell.executedCommands.contains(localGitCheck))
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.fileName == "auto-nickname.txt")
        #expect(addedFile.nickname == "auto-nickname.txt")
        #expect(output.contains("✅ Added GitFile 'auto-nickname.txt' (auto-nickname.txt)"))
    }
    
    @Test("Uses custom nickname when prompted.")
    func usesCustomNicknameWhenPrompted() throws {
        let sourcePath = try createTempFile(named: "file.txt", content: "content")
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let configLoader = MockGitConfigLoader()
        let shell = MockShell(results: ["true"]) // localGitCheck
        let picker = MockPicker(
            requiredInputResponses: ["Display name (leave blank for 'file.txt'):": "Custom Display Name"]
        )
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(
            context: context, 
            args: [
                "add-git-file",
                "--source", sourcePath,
                "--name", "file.txt",
                "--direct-path"
            ]
        )

        #expect(shell.executedCommands.contains(localGitCheck))
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.fileName == "file.txt")
        #expect(addedFile.nickname == "Custom Display Name")
        #expect(output.contains("✅ Added GitFile 'Custom Display Name' (file.txt)"))
    }
    
    @Test("Handles file copy operation when not using direct path.")
    func handlesFileCopyOperation() throws {
        let sourcePath = try createTempFile(named: "copy-source.txt", content: "copy content")
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let configLoader = MockGitConfigLoader()
        let fileCreator = MockGitFileCreator(copyResult: "/templates/copied-file.txt")
        let shell = MockShell(results: ["true"]) // localGitCheck
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, fileCreator: fileCreator)

        let output = try Nngit.testRun(
            context: context, 
            args: [
                "add-git-file",
                "--source", sourcePath,
                "--name", "copied-file.txt",
                "--nickname", "Copied File"
            ]
        )

        #expect(shell.executedCommands.contains(localGitCheck))
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.fileName == "copied-file.txt")
        #expect(addedFile.nickname == "Copied File")
        #expect(addedFile.localPath == "/templates/copied-file.txt")
        #expect(output.contains("Copied template to:"))
        #expect(output.contains("✅ Added GitFile 'Copied File' (copied-file.txt)"))
    }
    
    @Test("Throws error when source file does not exist.")
    func throwsErrorWhenSourceFileNotFound() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let shell = MockShell(results: ["true"]) // localGitCheck
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)

        #expect(throws: AddGitFileError.sourceFileNotFound("nonexistent.txt")) {
            try Nngit.testRun(
                context: context, 
                args: [
                    "add-git-file",
                    "--source", "nonexistent.txt",
                    "--name", "test.txt",
                    "--nickname", "Test",
                    "--direct-path"
                ]
            )
        }

        #expect(shell.executedCommands.contains(localGitCheck))
    }
    
    @Test("Throws error when prompted source file does not exist.")
    func throwsErrorWhenPromptedSourceFileNotFound() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let shell = MockShell(results: ["true"]) // localGitCheck
        let picker = MockPicker(
            requiredInputResponses: ["Enter path to template file:": "nonexistent-prompted.txt"]
        )
        let context = MockContext(picker: picker, shell: shell)

        #expect(throws: AddGitFileError.sourceFileNotFound("nonexistent-prompted.txt")) {
            try Nngit.testRun(
                context: context, 
                args: [
                    "add-git-file",
                    "--name", "test.txt",
                    "--nickname", "Test",
                    "--direct-path"
                ]
            )
        }

        #expect(shell.executedCommands.contains(localGitCheck))
    }
    
    @Test("Propagates errors from config loader.")
    func propagatesConfigLoaderErrors() throws {
        let sourcePath = try createTempFile(named: "error-test.txt", content: "content")
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let configLoader = MockGitConfigLoader(shouldThrowOnAdd: true)
        let shell = MockShell(results: ["true"]) // localGitCheck
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        #expect(throws: MockGitConfigLoader.TestError.configError) {
            try Nngit.testRun(
                context: context, 
                args: [
                    "add-git-file",
                    "--source", sourcePath,
                    "--name", "error-test.txt",
                    "--nickname", "Error Test",
                    "--direct-path"
                ]
            )
        }

        #expect(shell.executedCommands.contains(localGitCheck))
    }
    
    @Test("Propagates errors from file creator.")
    func propagatesFileCreatorErrors() throws {
        let sourcePath = try createTempFile(named: "creator-error.txt", content: "content")
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let configLoader = MockGitConfigLoader()
        let fileCreator = MockGitFileCreator(shouldThrowOnCopy: true)
        let shell = MockShell(results: ["true"]) // localGitCheck
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader, fileCreator: fileCreator)

        #expect(throws: MockGitConfigLoader.TestError.fileCreatorError) {
            try Nngit.testRun(
                context: context, 
                args: [
                    "add-git-file",
                    "--source", sourcePath,
                    "--name", "creator-error.txt",
                    "--nickname", "Creator Error Test"
                ]
            )
        }

        #expect(shell.executedCommands.contains(localGitCheck))
    }
    
    @Test("Verifies local git repository exists before execution.")
    func verifiesLocalGitExists() throws {
        let sourcePath = try createTempFile(named: "git-check.txt", content: "content")
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let shell = MockShell(results: ["true"]) // localGitCheck
        let picker = MockPicker()
        let context = MockContext(picker: picker, shell: shell)

        try Nngit.testRun(
            context: context, 
            args: [
                "add-git-file",
                "--source", sourcePath,
                "--name", "git-check.txt",
                "--nickname", "Git Check",
                "--direct-path"
            ]
        )

        #expect(shell.executedCommands.contains(localGitCheck))
    }
    
    @Test("Handles minimal arguments with interactive prompts.")
    func handlesMinimalArgumentsWithPrompts() throws {
        let sourcePath = try createTempFile(named: "minimal.txt", content: "minimal content")
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let configLoader = MockGitConfigLoader()
        let shell = MockShell(results: ["true"]) // localGitCheck
        let picker = MockPicker(
            requiredInputResponses: [
                "Enter path to template file:": sourcePath,
                "Output filename (leave blank for 'minimal.txt'):": "",
                "Display name (leave blank for 'minimal.txt'):": ""
            ]
        )
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)

        let output = try Nngit.testRun(
            context: context, 
            args: ["add-git-file", "--direct-path"]
        )

        #expect(shell.executedCommands.contains(localGitCheck))
        let addedFile = try #require(configLoader.addedGitFile)
        #expect(addedFile.fileName == "minimal.txt")
        #expect(addedFile.nickname == "minimal.txt")
        #expect(addedFile.localPath == sourcePath)
        #expect(output.contains("✅ Added GitFile 'minimal.txt' (minimal.txt)"))
    }
}


// MARK: - Helper Methods
private extension AddGitFileTests {
    func createTempFile(named name: String, content: String = "test content") throws -> String {
        let path = tempDirectory.appendingPathComponent(name).path
        try content.write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }
}
