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
2. **Staging Commands**: `Staging` (parent command with `Stage`, `Unstage` subcommands in `Sources/nngit/Commands/Staging/`)
3. **Undo Commands**: `Undo` (parent command with `Soft`, `HardReset` subcommands in `Sources/nngit/Commands/Undo/`)
4. **Utility Commands**: `Discard`, `BranchDiff` (in `Sources/nngit/Commands/Utility/`)
5. **Configuration**: `EditConfig` (in `Sources/nngit/Commands/Config/`)

#### Manager Layer
Manager classes handle complex workflows and coordinate between commands and git operations:
- `SwitchBranchManager` - Handles branch switching workflows with search and exact match support
- `DeleteBranchManager` - Manages branch deletion with safety checks and pruning
- `CheckoutRemoteManager` - Coordinates remote branch checkout operations
- `StageManager` - Manages interactive file staging workflows
- `UnstageManager` - Handles interactive file unstaging workflows
- `SoftResetManager` - Coordinates soft reset operations with safety checks
- `HardResetManager` - Manages hard reset operations with author verification

#### Git Abstraction Layer
- `GitShellAdapter` - Concrete implementation using SwiftShell
- `DefaultGitCommitManager` - Handles commit operations with enhanced authorship detection
- `DefaultGitBranchLoader` - Loads and filters branch information
- `DefaultGitConfigLoader` - Manages nngit configuration
- `DefaultGitResetHelper` - Manages reset operations with safety checks and user permissions

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
- Mock implementations: `MockShell`, `MockPicker`, `MockGitResetHelper`, `StubBranchLoader`, `StubConfigLoader`
- Test categories mirror the command structure:
  - Unit tests for managers (e.g., `SwitchBranchManagerTests`, `DeleteBranchManagerTests`)
  - Integration tests for commands (e.g., `SwitchBranchTests`, `DeleteBranchTests`)
- Behavior-driven testing approach focusing on public interfaces
- Enhanced authorship testing with both git username and email validation
- Comprehensive test coverage for reset operations and permission checks
- 154 tests providing extensive coverage

### External Dependencies
- `SwiftShell` - Shell command execution
- `NnGitKit` (GitShellKit) - Git operations abstraction
- `NnConfigKit` - Configuration management
- `SwiftPicker` - User interaction prompts
- `swift-argument-parser` - CLI parsing

### Architectural Patterns

#### Dependency Injection
- Context-based dependency injection via `NnGitContext` protocol
- Factory methods for creating dependencies (`makeShell()`, `makePicker()`, etc.)
- Enables easy testing with mock implementations

#### Manager Pattern
- Commands delegate complex workflows to manager classes
- Managers encapsulate business logic and coordinate multiple operations
- Clean separation between CLI parsing (commands) and business logic (managers)
- Private helper methods organized in private extensions

#### Testing Strategy
- Behavior-driven tests focus on public interfaces
- Private implementation details not directly tested
- Mock objects simulate external dependencies
- Stub loaders provide controlled test data
- Tests use `@MainActor` when needed to ensure proper serialization

### Key Workflows

#### Branch Prefix Workflow
Branch prefixes are stored in the configuration and can optionally require issue numbers. Prefixes support multiple issue prefixes (e.g., "FRA-", "RAPP-") and default values (e.g., "NO-JIRA"). The system combines prefix + issue prefix + issue number + description to generate branch names (e.g., `feature/FRA-42/add-login-screen`).

#### Undo Workflow
The `Undo` command provides commit undoing with two strategies:
- `Soft` subcommand (default): Soft resets commits, moving changes back to staging area (SoftReset.swift)
- `hard` subcommand: Hard resets commits, completely discarding changes (HardReset.swift)
- Both support `--force` flag for commits authored by others
- Both support `--select` flag to choose from the last 7 commits interactively
- Enhanced authorship detection using both git username and email for safety
- Uses `DefaultGitCommitManager` for commit operations and `DefaultGitResetHelper` for safety checks
- Comprehensive permission verification prevents accidental deletion of other authors' work

#### Staging Workflow
The `Staging` command provides interactive file staging/unstaging:
- `Stage` subcommand: Lists unstaged and untracked files for multi-selection staging
- `Unstage` subcommand: Lists staged files for multi-selection unstaging
- Uses `SwiftPicker` for interactive multi-selection interface
- Executes individual `git add` and `git reset HEAD` commands per selected file


## Development Notes

### Adding New Commands
1. Create command struct extending `ParsableCommand`
2. Add to `Nngit.configuration.subcommands` array
3. Use `Nngit.makeXXX()` factory methods for dependencies
4. Follow existing patterns in other command implementations

### Testing
- All commands and managers should have corresponding test files
- Use `MockContext` for testing command logic
- Test files follow `<ComponentName>Tests.swift` naming convention
- Manager tests focus on behavior, not implementation details
- Command tests verify end-to-end workflows
- For reset operations that require real behavior testing, use `DefaultGitCommitManager` and `DefaultGitResetHelper` instead of mocks
- Enhanced test coverage includes authorship validation, permission checks, and selection mode functionality
- All tests use updated git log format with both author name and email: `%h - %s (%an <%ae>, %ar)`
- Watch for race conditions in tests - ensure proper mock setup and avoid array index issues

### Error Handling
- Git operations throw `GitShellError` for shell failures
- Commands should verify git repository exists using `shell.verifyLocalGitExists()`
- User interactions handled through `SwiftPicker` abstraction