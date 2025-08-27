//
//  NewRemoteManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import Foundation
import SwiftPicker
import GitShellKit

/// Manager for handling GitHub remote repository initialization.
struct NewRemoteManager {
    private let shell: GitShell
    private let picker: CommandLinePicker
    
    init(shell: GitShell, picker: CommandLinePicker) {
        self.shell = shell
        self.picker = picker
    }
}


// MARK: - Main Workflow
extension NewRemoteManager {
    /// Initializes a new GitHub remote repository for the current local repository.
    func initializeGitHubRemote(visibility: RepoVisibility? = nil) throws {
        try verifyPrerequisites()
        
        let currentBranch = try getCurrentBranch()
        
        if currentBranch != "main" {
            try handleNonMainBranch(currentBranch)
        }
        
        let selectedVisibility = visibility ?? selectVisibility()
        let repoName = try getCurrentDirectoryName()
        let username = try getGitHubUsername()
        
        try confirmRepositoryCreation(
            username: username,
            projectName: repoName,
            branch: currentBranch,
            visibility: selectedVisibility
        )
        
        try addGitHubRemote(username: username, projectName: repoName, visibility: selectedVisibility)
        try pushCurrentBranch(currentBranch)
        
        let githubURL = try shell.getGitHubURL(at: nil)
        print("✅ Remote repository created successfully!")
        print("🔗 GitHub URL: \(githubURL)")
    }
}


// MARK: - Prerequisites Verification
private extension NewRemoteManager {
    /// Verifies all prerequisites are met before creating remote repository.
    func verifyPrerequisites() throws {
        try shell.verifyLocalGitExists()
        try verifyGitHubCLIInstalled()
        try verifyNoRemoteExists()
    }
    
    /// Verifies that the GitHub CLI (gh) is installed and accessible.
    func verifyGitHubCLIInstalled() throws {
        do {
            _ = try shell.runWithOutput("which gh")
        } catch {
            throw NewRemoteError.githubCLINotInstalled
        }
    }
    
    /// Verifies that no remote repository is already configured.
    func verifyNoRemoteExists() throws {
        guard try !shell.remoteExists(path: nil) else {
            throw NewRemoteError.remoteAlreadyExists
        }
    }
}


// MARK: - Branch Handling
private extension NewRemoteManager {
    /// Handles the case when current branch is not 'main'.
    func handleNonMainBranch(_ currentBranch: String) throws {
        let options = ["Yes", "No"]
        let choice = picker.singleSelection(
            "Current branch is '\(currentBranch)', not 'main'. Create remote repository with this branch?",
            items: options
        )
        
        if choice == "No" {
            throw NewRemoteError.userCancelledNonMainBranch
        }
        
        print("📝 Creating remote repository with branch: \(currentBranch)")
    }
}


// MARK: - Visibility Selection
private extension NewRemoteManager {
    /// Prompts user to select repository visibility.
    func selectVisibility() -> RepoVisibility {
        let options = ["Private", "Public"]
        let choice = picker.singleSelection(
            "Select repository visibility:",
            items: options
        )
        
        return choice == "Public" ? .publicRepo : .privateRepo
    }
}


// MARK: - Confirmation
private extension NewRemoteManager {
    /// Confirms repository creation details with the user.
    func confirmRepositoryCreation(
        username: String,
        projectName: String,
        branch: String,
        visibility: RepoVisibility
    ) throws {
        let visibilityText = visibility == .publicRepo ? "Public" : "Private"
        let confirmationMessage = """
        📋 Repository Details:
        • GitHub Username: \(username)
        • Repository Name: \(projectName)
        • Current Branch: \(branch)
        • Visibility: \(visibilityText)
        
        Create remote repository with these settings?
        """
        
        do {
            try picker.requiredPermission(confirmationMessage)
        } catch {
            throw NewRemoteError.userDeniedPermission
        }
    }
}


// MARK: - Repository Operations
private extension NewRemoteManager {
    /// Gets the current branch name, handling fresh repositories without HEAD.
    func getCurrentBranch() throws -> String {
        if headExists() {
            return try shell.runGitCommandWithOutput(.getCurrentBranchName, path: nil)
        } else {
            // In fresh repositories without commits, default to "main"
            return "main"
        }
    }
    
    /// Checks if HEAD exists (i.e., if there are any commits in the repository).
    func headExists() -> Bool {
        do {
            let result = try shell.runWithOutput("git rev-parse --verify HEAD")
            return !result.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        } catch {
            return false
        }
    }
    
    /// Gets the current directory name to use as repository name.
    func getCurrentDirectoryName() throws -> String {
        let currentPath = try shell.runWithOutput("pwd")
        guard let directoryName = currentPath.split(separator: "/").last else {
            throw NewRemoteError.cannotDetermineDirectoryName
        }
        return String(directoryName)
    }
    
    /// Gets the GitHub username of the authenticated user.
    func getGitHubUsername() throws -> String {
        do {
            return try shell.runWithOutput("gh api user --jq '.login'").trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw NewRemoteError.cannotGetGitHubUsername
        }
    }
    
    /// Adds the GitHub remote origin to the local repository.
    func addGitHubRemote(username: String, projectName: String, visibility: RepoVisibility) throws {
        // First create the remote repository on GitHub
        let visibilityFlag = visibility == .publicRepo ? "--public" : "--private"
        _ = try shell.runWithOutput("gh repo create \(projectName) \(visibilityFlag) -d 'Repository created via nngit'")
        print("📦 Created remote repository: \(username)/\(projectName)")
        
        // Then add the remote origin
        try shell.runGitCommandWithOutput(.addGitHubRemote(username: username, projectName: projectName), path: nil)
        print("🔗 Added remote origin")
    }
    
    /// Pushes the current branch to the remote repository.
    func pushCurrentBranch(_ branchName: String) throws {
        try shell.runGitCommandWithOutput(.pushNewRemote(branchName: branchName), path: nil)
        print("⬆️  Pushed \(branchName) to remote")
    }
}


// MARK: - Errors
enum NewRemoteError: Error, Equatable {
    case githubCLINotInstalled
    case remoteAlreadyExists
    case userCancelledNonMainBranch
    case cannotDetermineDirectoryName
    case cannotGetGitHubUsername
    case userDeniedPermission
}