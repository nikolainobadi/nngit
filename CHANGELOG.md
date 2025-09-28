# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.0] - 2025-09-28
### Added
- Remote branch switching with automatic local tracking branch creation
- `--remote` flag for SwitchBranch command to filter only remote branches
- Automatic detection and handling of remote branches in branch switching workflow
- Creation of comprehensive changelog documenting all releases from v0.3.0 to v0.6.0

### Changed
- Enhanced SwitchBranch command to seamlessly handle both local and remote branches
- Improved test coverage for remote branch switching scenarios
- Consolidated FileManager usage in test cleanup for better maintainability

## [0.6.0] - 2025-09-02
### Added
- `register-git-file` command for registering template files for reuse in new repositories
- `unregister-git-file` command for removing registered template files
- `add-git-file` command for adding registered templates to current repository
- Enhanced error handling for branch operations when no branches are available
- COMMANDS.md documentation file

### Changed
- Improved branch validation logic with consolidated error handling
- Updated project documentation and configuration files

### Fixed
- Branch switching operations now properly validate branch availability
- Branch deletion operations now properly validate branch availability

## [0.5.2] - 2025-08-27
### Fixed
- Bug in NewGitManager that was causing initialization issues
- Bug in NewRemoteManager affecting remote repository operations
- Test isolation issues where tests were overwriting production config files
- Broken unit tests affecting build stability

## [0.5.1] - 2025-08-26
### Fixed
- Bug in NewGit command affecting repository initialization

## [0.5.0] - 2025-08-26
### Added
- `activity` command for Git activity reporting with colorized output and daily breakdowns
- `new-push` command for safely pushing new branches with comprehensive validation
- `stop-tracking` command for managing gitignore compliance by removing tracked files
- `add-git-file` command for adding registered template files to repositories
- `new-remote` command for creating remote repositories with visibility options
- `new-git` command for initializing new Git repositories with remote creation
- Enhanced commit selection for reset operations with `--select` flag
- Manager pattern implementation for improved code organization and testability
- Branch validation and error handling improvements
- Origin fetching before branch operations for up-to-date remote information

### Changed
- Reorganized codebase into better folder hierarchy with manager pattern
- Updated to latest Swift package versions including NnShellKit
- Improved branch switching logic with better validation and safety checks
- Enhanced reset operations with proper permission prompts and authorship validation
- Removed deprecated MyBranch commands and BranchPrefix functionality
- Simplified command interfaces by removing unneeded parameters

### Fixed
- Flaky test execution through better test isolation and mock implementations
- Branch status display issues preventing main branch from showing 'merged' status incorrectly
- Current branch filtering in deletion operations
- Remote branch existence validation in sync status operations

### Removed
- Legacy MyBranch command system
- BranchPrefix model and related commands
- Direct FileManager dependencies in favor of abstracted services

## [0.4.1] - 2025-08-11
### Changed
- Refactored reset commands into unified Undo parent command with soft/hard subcommands
- Updated NewBranch and BranchPrefix commands for improved flexibility
- Enhanced CheckoutRemote command functionality
- Updated documentation in README and CLAUDE.md

## [0.4.0] - 2025-08-11
### Added
- New Staging command for interactive file staging operations
- CheckoutRemote command for switching to remote branches
- ListMyBranch command and consolidated MyBranch commands under parent command
- Commands to register and remove MyBranch objects for quick branch access
- SoftReset command for undoing commits while preserving changes
- BranchDiff command for comparing branch differences
- Enhanced Discard command with file selection capabilities

### Changed
- Refactored DeleteBranch and SwitchBranch to use MyBranch for improved selection
- NewBranch now automatically adds created branches to MyBranches
- Updated GitConfig structure for better robustness and organization
- Moved GitConfig nested structs to extensions for better code organization
- Removed issueNumberPrefix from BranchPrefix for simplified workflow

## [0.3.6] - 2025-07-04
### Changed
- Updated EditConfig command to include new branch loading properties
- Enhanced SwitchBranch and DeleteBranch commands with configurable branch loading arguments
- Updated GitBranchLoader to utilize new GitConfig parameters
- Added new parameters to GitConfig for customizable branch loading behavior

### Fixed
- Failing unit tests affecting build stability

## [0.3.5] - 2025-07-04
### Changed
- Optimized loadBranches logic for improved performance and faster workflow

## [0.3.4] - 2025-07-01
### Added
- Delete all merged branches functionality
- Option to list all local branches when switching or deleting branches
- Author filtering logic to DeleteBranch command
- Include author argument for SwitchBranch (defaults to current user only)
- EditConfig command for configuration management
- Optional prune functionality when deleting branches
- Ability to skip branch prefix selection when creating new branches

### Changed
- Fixed loadBranches to ensure merged branch checking uses config.defaultBranch
- Reduced unnecessary checks for remote repository existence
- Fixed displayName property for BranchPrefix
- Updated documentation in README
- Enhanced shell error handling

## [0.3.3] - 2025-06-28
### Fixed
- Version updates and minor improvements

## [0.3.1] - 2025-06-28
### Added
- Version identifier

## [0.3.0] - 2025-06-28
### Added
- Initial release with core Git workflow functionality
- NewBranch command for creating branches with customizable naming
- SwitchBranch command for branch switching with user selection
- DeleteBranch command for safe branch deletion
- Discard command for reverting changes to specific files
- BranchNameGenerator for standardized branch naming conventions
- Comprehensive unit test suite for all core functionality
- Configuration system for customizable workflow preferences