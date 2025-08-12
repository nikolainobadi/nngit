# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building and Testing
- **Build project**: `swift build`
- **Build for release**: `swift build -c release`
- **Run tests**: `swift test`
- **Run specific test**: `swift test --filter <TestName>`
- **Run executable**: `swift run nngit <command>`

### Common Development Tasks
- **Test a specific command**: `swift run nngit <command> --help`
- **Check executable location**: `.build/debug/nngit` (debug) or `.build/release/nngit` (release)

## Architecture Overview

### Core Structure
This is a Swift CLI tool built with `swift-argument-parser` that provides Git workflow utilities. The architecture follows a dependency injection pattern with a context-based approach for testability.

### Key Components

#### Main Entry Point
- `Sources/nngit/Main/Nngit.swift` - Main command entry point using ArgumentParser
- Uses `NnGitContext` protocol for dependency injection
- Version: 0.4.1

#### Command Categories
1. **Branch Commands**: `NewBranch`, `SwitchBranch`, `DeleteBranch`, `CheckoutRemote` (in `Sources/nngit/Commands/Branch/`)
2. **Branch Management**: `MyBranches` (parent command with `Add`, `Remove`, `List` subcommands in `Sources/nngit/Commands/MyBranch/`)
3. **Branch Prefix Commands**: `AddBranchPrefix`, `EditBranchPrefix`, `DeleteBranchPrefix`, `ListBranchPrefix` (in `Sources/nngit/Commands/BranchPrefix/`)
4. **Staging Commands**: `Staging` (parent command with `Stage`, `Unstage` subcommands in `Sources/nngit/Commands/Staging/`)
5. **Utility Commands**: `Discard`, `Undo` (parent command with `Soft`, `Hard` subcommands), `BranchDiff` (in `Sources/nngit/Commands/Utility/`)
6. **Configuration**: `EditConfig` (in `Sources/nngit/Commands/Config/`)

#### Git Abstraction Layer
- `GitShellAdapter` - Concrete implementation using SwiftShell
- `GitCommitManager` - Handles commit operations
- `GitBranchLoader` - Loads branch information
- `GitConfigLoader` - Manages nngit configuration

#### Models
- `GitConfig` - Main configuration structure stored in `~/.config/nngit/config.json`
- `BranchPrefix` - Branch naming prefix configuration with support for multiple issue prefixes and default values
- `GitBranch`, `CommitInfo`, `BranchLocation` - Git-related data models
- `FileStatus` - Represents git file status with staging information, used by Staging and Discard commands

### Configuration System
- Configuration stored at `~/.config/nngit/config.json`
- Uses `NnConfigKit` for configuration management
- Key settings: default branch, branch prefixes, rebase/prune behavior, branch loading options

### Testing Structure
- Tests located in `Tests/nngitTests/`
- Uses `MockContext` for dependency injection in tests
- Mock implementations: `MockGitShell`, `MockPicker`
- Test categories mirror the command structure

### External Dependencies
- `SwiftShell` - Shell command execution
- `NnGitKit` (GitShellKit) - Git operations abstraction
- `NnConfigKit` - Configuration management
- `SwiftPicker` - User interaction prompts
- `swift-argument-parser` - CLI parsing

### Key Workflows

#### Branch Prefix Workflow
Branch prefixes are stored in the configuration and can optionally require issue numbers. Prefixes support multiple issue prefixes (e.g., "FRA-", "RAPP-") and default values (e.g., "NO-JIRA"). The system combines prefix + issue prefix + issue number + description to generate branch names (e.g., `feature/FRA-42/add-login-screen`).

#### Undo Workflow
The `Undo` command provides commit undoing with two strategies:
- `Soft` subcommand (default): Soft resets commits, moving changes back to staging area
- `Hard` subcommand: Hard resets commits, completely discarding changes
- Both support `--force` flag for commits authored by others
- Uses `GitCommitManager` for commit operations and safety checks

#### Staging Workflow
The `Staging` command provides interactive file staging/unstaging:
- `Stage` subcommand: Lists unstaged and untracked files for multi-selection staging
- `Unstage` subcommand: Lists staged files for multi-selection unstaging
- Uses `SwiftPicker` for interactive multi-selection interface
- Executes individual `git add` and `git reset HEAD` commands per selected file

#### MyBranches Workflow
The `MyBranches` command manages a tracked list of user's branches for easier access:
- `Add` subcommand: Add current branch to tracked list
- `Remove` subcommand: Remove branches from tracked list
- `List` subcommand (default): Show tracked branches for quick switching/deletion

## Development Notes

### Adding New Commands
1. Create command struct extending `ParsableCommand`
2. Add to `Nngit.configuration.subcommands` array
3. Use `Nngit.makeXXX()` factory methods for dependencies
4. Follow existing patterns in other command implementations

### Testing
- All commands should have corresponding test files
- Use `MockContext` for testing command logic
- Test files follow `<CommandName>Tests.swift` naming convention

### Error Handling
- Git operations throw `GitShellError` for shell failures
- Commands should verify git repository exists using `shell.verifyLocalGitExists()`
- User interactions handled through `SwiftPicker` abstraction