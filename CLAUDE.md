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
- Version: 0.3.6

#### Command Categories
1. **Branch Commands**: `NewBranch`, `SwitchBranch`, `DeleteBranch` (in `Sources/nngit/Commands/Branch/`)
2. **Branch Prefix Commands**: `AddBranchPrefix`, `EditBranchPrefix`, `DeleteBranchPrefix`, `ListBranchPrefix` (in `Sources/nngit/Commands/BranchPrefix/`)
3. **Utility Commands**: `Discard`, `UndoCommit` (in `Sources/nngit/Commands/Utility/`)
4. **Configuration**: `EditConfig` (in `Sources/nngit/Commands/Config/`)

#### Git Abstraction Layer
- `GitShellAdapter` - Concrete implementation using SwiftShell
- `GitCommitManager` - Handles commit operations
- `GitBranchLoader` - Loads branch information
- `GitConfigLoader` - Manages nngit configuration

#### Models
- `GitConfig` - Main configuration structure stored in `~/.config/nngit/config.json`
- `BranchPrefix` - Branch naming prefix configuration
- `GitBranch`, `CommitInfo`, `BranchLocation` - Git-related data models

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

### Branch Prefix Workflow
Branch prefixes are stored in the configuration and can optionally require issue numbers. The system combines prefix + issue number + description to generate branch names (e.g., `feature/ISS-42-add-login-screen`).

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