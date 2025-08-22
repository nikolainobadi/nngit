//
//  BranchDiffManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/22/25.
//

import Foundation
import GitShellKit

/// Manager utility for handling branch diff workflows and operations.
struct BranchDiffManager {
    private let shell: GitShell
    private let clipboardHandler: ClipboardHandler
    
    init(shell: GitShell, clipboardHandler: ClipboardHandler = DefaultClipboardHandler()) {
        self.shell = shell
        self.clipboardHandler = clipboardHandler
    }
}


// MARK: - Branch Diff Operations
extension BranchDiffManager {
    func generateDiff(baseBranch: String, copyToClipboard: Bool) throws {
        let currentBranch = try getCurrentBranch()
        
        if currentBranch == baseBranch {
            print("You are currently on the base branch '\(baseBranch)'. No diff to show.")
            return
        }
        
        try validateBaseBranchExists(baseBranch)
        
        let diffOutput = try generateDiffOutput(baseBranch: baseBranch, currentBranch: currentBranch)
        
        if diffOutput.isEmpty {
            print("No differences found between '\(baseBranch)' and current branch '\(currentBranch)'.")
            return
        }
        
        try handleDiffOutput(diffOutput, baseBranch: baseBranch, currentBranch: currentBranch, copyToClipboard: copyToClipboard)
    }
}


// MARK: - Private Methods
private extension BranchDiffManager {
    func getCurrentBranch() throws -> String {
        return try shell.runWithOutput("git branch --show-current")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func validateBaseBranchExists(_ baseBranch: String) throws {
        do {
            _ = try shell.runWithOutput("git show-ref --verify --quiet refs/heads/\(baseBranch)")
        } catch {
            print("Base branch '\(baseBranch)' does not exist.")
            throw BranchDiffError.baseBranchNotFound(baseBranch)
        }
    }
    
    func generateDiffOutput(baseBranch: String, currentBranch: String) throws -> String {
        let diffOutput = try shell.runWithOutput("git diff \(baseBranch)...HEAD")
        return diffOutput.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func handleDiffOutput(_ diffOutput: String, baseBranch: String, currentBranch: String, copyToClipboard: Bool) throws {
        print("📊 Showing diff between '\(baseBranch)' and '\(currentBranch)':")
        print(diffOutput)
        
        if copyToClipboard {
            try clipboardHandler.copyToClipboard(diffOutput)
            print("✅ Diff copied to clipboard!")
        }
    }
}


// MARK: - Clipboard Handling
protocol ClipboardHandler {
    func copyToClipboard(_ text: String) throws
}

struct DefaultClipboardHandler: ClipboardHandler {
    func copyToClipboard(_ text: String) throws {
        let process = Process()
        process.launchPath = "/usr/bin/pbcopy"
        
        let pipe = Pipe()
        process.standardInput = pipe
        
        do {
            try process.run()
            pipe.fileHandleForWriting.write(text.data(using: .utf8) ?? Data())
            pipe.fileHandleForWriting.closeFile()
            process.waitUntilExit()
            
            if process.terminationStatus != 0 {
                throw BranchDiffError.clipboardFailed
            }
        } catch {
            throw BranchDiffError.clipboardFailed
        }
    }
}


// MARK: - Enhanced Error Types
enum BranchDiffError: Error, LocalizedError, Equatable {
    case clipboardFailed
    case baseBranchNotFound(String)
    
    var errorDescription: String? {
        switch self {
        case .clipboardFailed:
            return "Failed to copy diff to clipboard"
        case .baseBranchNotFound(let branch):
            return "Base branch '\(branch)' does not exist"
        }
    }
}