//
//  UnregisterGitFileTests.swift
//  nngitTests
//
//  Created by Nikolai Nobadi on 9/2/25.
//

import Testing
import Foundation
import GitShellKit
import NnShellTesting
import SwiftPickerTesting
@testable import nngit

@MainActor
final class UnregisterGitFileTests {
    @Test("Successfully unregisters git file by exact filename.")
    func unregisterByExactFilename() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt"),
            GitFile(fileName: "readme.md", nickname: "Readme", localPath: "/templates/readme.md")
        ]
        let (context, configLoader, shell) = makeSUT(gitFiles: gitFiles, permissionResults: [true, false])

        let output = try Nngit.testRun(
            context: context, 
            args: ["unregister-git-file", "test.txt"]
        )

        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(configLoader.removedFileName == "test.txt")
        #expect(output.contains("✅ Removed git file 'Test File (test.txt)'"))
    }
    
    @Test("Successfully unregisters git file by nickname.")
    func unregisterByNickname() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt"),
            GitFile(fileName: "readme.md", nickname: "Readme", localPath: "/templates/readme.md")
        ]
        let (context, configLoader, shell) = makeSUT(gitFiles: gitFiles, permissionResults: [true, false])

        let output = try Nngit.testRun(
            context: context, 
            args: ["unregister-git-file", "Readme"]
        )

        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(configLoader.removedFileName == "readme.md")
        #expect(output.contains("✅ Removed git file 'Readme (readme.md)'"))
    }
    
    @Test("Successfully removes all git files with --all flag.")
    func removesAllGitFilesWithFlag() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt"),
            GitFile(fileName: "readme.md", nickname: "Readme", localPath: "/templates/readme.md"),
            GitFile(fileName: "config.json", nickname: "Config", localPath: "/templates/config.json")
        ]
        let (context, configLoader, shell) = makeSUT(gitFiles: gitFiles, permissionResults: [true, false])

        let output = try Nngit.testRun(
            context: context, 
            args: ["unregister-git-file", "--all"]
        )

        #expect(shell.executedCommands.contains(localGitCheck))
        let savedConfig = try #require(configLoader.savedConfig)
        #expect(savedConfig.gitFiles.isEmpty)
        #expect(output.contains("Found 3 registered git file(s):"))
        #expect(output.contains("✅ Removed all registered git files"))
    }
    
    @Test("Handles cancellation when user denies permission.")
    func handlesCancellationOnPermissionDenial() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt")
        ]
        let (context, configLoader, shell) = makeSUT(gitFiles: gitFiles, permissionResults: [false])

        #expect(throws: UnregisterGitFileError.deletionCancelled) {
            try Nngit.testRun(
                context: context, 
                args: ["unregister-git-file", "test.txt"]
            )
        }

        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(configLoader.removedFileName == nil)
    }
    
    @Test("Throws error when no git files are registered.")
    func throwsErrorWhenNoGitFilesRegistered() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let (context, _, shell) = makeSUT(gitFiles: [])

        #expect(throws: UnregisterGitFileError.noRegisteredFiles) {
            try Nngit.testRun(
                context: context, 
                args: ["unregister-git-file", "test.txt"]
            )
        }

        #expect(shell.executedCommands.contains(localGitCheck))
    }
    
    @Test("Throws error when specified file not found.")
    func throwsErrorWhenFileNotFound() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt")
        ]
        let (context, configLoader, shell) = makeSUT(gitFiles: gitFiles)

        #expect(throws: UnregisterGitFileError.fileNotFound("nonexistent.txt")) {
            try Nngit.testRun(
                context: context, 
                args: ["unregister-git-file", "nonexistent.txt"]
            )
        }

        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(configLoader.removedFileName == nil)
    }
    
    @Test("Verifies local git repository exists before execution.")
    func verifiesLocalGitExists() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt")
        ]
        let (context, _, shell) = makeSUT(gitFiles: gitFiles, permissionResults: [true, false])

        try Nngit.testRun(
            context: context, 
            args: ["unregister-git-file", "test.txt"]
        )

        #expect(shell.executedCommands.contains(localGitCheck))
    }
    
    @Test("Handles case-insensitive matching for filenames and nicknames.")
    func handlesCaseInsensitiveMatching() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let gitFiles = [
            GitFile(fileName: "Test.txt", nickname: "Test File", localPath: "/templates/Test.txt")
        ]
        let (context, configLoader, shell) = makeSUT(gitFiles: gitFiles, permissionResults: [true, false])

        let output = try Nngit.testRun(
            context: context, 
            args: ["unregister-git-file", "test.txt"] // lowercase input
        )

        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(configLoader.removedFileName == "Test.txt")
        #expect(output.contains("✅ Removed git file 'Test File (Test.txt)'"))
    }
    
    @Test("Handles --all flag cancellation correctly.")
    func handlesAllFlagCancellation() throws {
        let localGitCheck = makeGitCommand(.localGitCheck, path: nil)
        let gitFiles = [
            GitFile(fileName: "test.txt", nickname: "Test File", localPath: "/templates/test.txt"),
            GitFile(fileName: "readme.md", nickname: "Readme", localPath: "/templates/readme.md")
        ]
        let (context, configLoader, shell) = makeSUT(gitFiles: gitFiles, permissionResults: [false])

        #expect(throws: UnregisterGitFileError.deletionCancelled) {
            try Nngit.testRun(
                context: context, 
                args: ["unregister-git-file", "--all"]
            )
        }

        #expect(shell.executedCommands.contains(localGitCheck))
        #expect(configLoader.savedConfig == nil)
    }
}


// MARK: - Helper Methods
private extension UnregisterGitFileTests {
    func makeSUT(
        gitFiles: [GitFile],
        shellResults: [String] = ["true"],
        permissionResults: [Bool] = []
    ) -> (context: MockContext, configLoader: MockGitConfigLoader, shell: MockShell) {
        let configLoader = MockGitConfigLoader(mockGitFiles: gitFiles)
        let shell = MockShell(results: shellResults)
        let picker = MockSwiftPicker(permissionResult: .init(type: .ordered(permissionResults)))
        let context = MockContext(picker: picker, shell: shell, configLoader: configLoader)
        
        return (context, configLoader, shell)
    }
}
