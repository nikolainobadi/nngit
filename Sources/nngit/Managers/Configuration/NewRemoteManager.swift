//
//  NewRemoteManager.swift
//  nngit
//
//  Created by Nikolai Nobadi on 8/24/25.
//

import Foundation
import GitShellKit

struct NewRemoteManager {
    private let shell: any GitShell
    private let picker: any GitPicker
    
    init(shell: any GitShell, picker: any GitPicker) {
        self.shell = shell
        self.picker = picker
    }
}


// MARK: - Main Workflow
extension NewRemoteManager {
    /// Initializes a new GitHub remote repository for the current local repository.
    func initializeGitHubRemote(visibility: RepoVisibility? = nil) throws {
        try verifyPrerequisites()
        
        let username = try getGitHubUsername()
        let repoName = try getCurrentDirectoryName()
        let description = picker.getInput("Please add a brief description for your new GitHub repository:")
        let selectedVisibility = try visibility ?? picker.requiredSingleSelection("Select repository visibility:", items: RepoVisibility.allCases)
        
        try confirmRepositoryCreation(username: username, projectName: repoName, description: description, visibility: selectedVisibility)

        try shell.runWithOutput("gh repo create \(repoName) --\(selectedVisibility.rawValue) -d '\(description)'")
        print("📦 Created remote repository: \(username)/\(repoName)")
        try shell.runGitCommandWithOutput(.addGitHubRemote(username: username, projectName: repoName), path: nil)
        print("🔗 Added remote origin")
        try shell.runGitCommandWithOutput(.pushNewRemote(branchName: "main"), path: nil)
        
        let githubURL = try shell.getGitHubURL(at: nil)
        
        print("✅ Remote repository created successfully!")
        print("🔗 GitHub URL: \(githubURL)")
    }
}


// MARK: - Private Methods
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
            try shell.runWithOutput("which gh")
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
    
    /// Confirms repository creation details with the user.
    func confirmRepositoryCreation(username: String, projectName: String, description: String, visibility: RepoVisibility) throws {
        let confirmationMessage = """
        
        📋 Repository Details:
        • GitHub Username: \(username)
        • Repository Name: \(projectName)
        • Description: \(description)
        • Visibility: \(visibility.displayName)
        
        Create remote repository with these settings?
        """
        
        do {
            try picker.requiredPermission(confirmationMessage)
        } catch {
            throw NewRemoteError.userDeniedPermission
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
