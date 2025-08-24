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
This Swift CLI tool follows a clean, modular architecture with clear separation of concerns. Built with `swift-argument-parser`, it provides Git workflow utilities using a dependency injection pattern with a context-based approach for testability.

### Project Organization

```
Sources/nngit/
├── Core/                     # Essential components
│   ├── Context/              # Dependency injection (NnGitContext, DefaultContext)
│   ├── Models/               # Core data models (GitBranch, CommitInfo, BranchLocation, FileStatus)
│   └── Extensions/           # Type extensions (CommitInfo+Display)
├── Services/                 # External integrations & abstractions
│   ├── Git/
│   │   ├── Protocols/        # Git service contracts (GitBranchLoader, GitCommitManager, GitResetHelper, GitFileTracker)
│   │   └── Implementations/  # Concrete implementations (DefaultGitBranchLoader, DefaultGitCommitManager, etc.)
│   └── Configuration/
│       ├── Protocols/        # Config contracts (GitConfigLoader)
│       ├── Implementations/  # Config implementations (DefaultGitConfigLoader)
│       └── Models/           # Config models (GitConfig, BranchPrefix)
├── Managers/                 # Business logic layer
│   ├── Branch/               # Branch operations (SwitchBranchManager, DeleteBranchManager, etc.)
│   ├── FileOperations/       # File handling (StageManager, UnstageManager, DiscardManager, StopTrackingManager)
│   ├── Reset/                # Reset operations (SoftResetManager, HardResetManager)
│   └── Utility/              # Utility functions (BranchDiffManager)
├── Commands/                 # CLI command definitions
│   ├── Branch/               # Branch commands (NewBranch, SwitchBranch, DeleteBranch, CheckoutRemote)
│   ├── FileOperations/       # File operation commands (Staging, Stage, Unstage, Discard, StopTracking)
│   ├── Reset/                # Reset commands (Undo, SoftReset, HardReset)
│   ├── Configuration/        # Config commands (EditConfig)
│   └── BranchDiff.swift      # Branch comparison command
├── Errors/                   # Centralized error definitions
└── Main/Nngit.swift         # Main entry point (v0.4.1)
```

### Key Components

#### Core Layer
- **Context**: Dependency injection container using `NnGitContext` protocol
- **Models**: Core data structures for Git entities and file status
- **Extensions**: Type extensions for enhanced functionality

#### Services Layer
- **Git Services**: Abstractions for Git operations with protocol/implementation separation
- **Configuration Services**: Settings management with clean abstractions
- All implementations use concrete types like `GitShellAdapter` for shell execution

#### Managers Layer
Business logic components that coordinate complex workflows:
- **Branch Managers**: Handle branch switching, deletion, creation, and remote checkout
- **File Operation Managers**: Manage staging, unstaging, and discarding of changes
- **Reset Managers**: Coordinate commit reset operations with safety checks
- **Utility Managers**: Provide specialized functions like branch diff generation

#### Commands Layer
CLI command definitions organized by feature area:
- **Branch Commands**: User-facing branch operations
- **File Operation Commands**: Interactive file staging/unstaging/discarding
- **Reset Commands**: Commit undo operations with enhanced safety
- **Configuration Commands**: Settings management
- **Utility Commands**: Branch comparison and other utilities

### Configuration System
- Configuration stored at `~/.config/nngit/config.json`
- Uses `NnConfigKit` for configuration management
- Key settings: default branch, branch prefixes, rebase/prune behavior, branch loading options

### Testing Structure

```
Tests/nngitTests/
├── Shared/                   # Test utilities and mocks
│   ├── MockContext.swift     # Dependency injection for tests
│   ├── Mock implementations  # MockShell, MockPicker, MockGitResetHelper
│   └── Stub implementations  # StubBranchLoader, StubConfigLoader
└── UnitTests/                # Test cases organized by source structure
    ├── Commands/
    │   ├── Branch/           # Branch command tests
    │   ├── FileOperations/   # File operation command tests
    │   ├── Reset/            # Reset command tests
    │   ├── Configuration/    # Config command tests
    │   └── Utility/          # Utility command tests
    ├── Managers/
    │   ├── Branch/           # Branch manager tests
    │   ├── FileOperations/   # File operation manager tests
    │   ├── Reset/            # Reset manager tests
    │   └── Utility/          # Utility manager tests
    └── Services/
        ├── Git/
        │   └── Implementations/  # Git service implementation tests
        └── Configuration/
            └── Implementations/  # Config service tests
```

**Testing Approach:**
- **Behavior-driven**: Tests focus on public interfaces and expected behaviors
- **Comprehensive Coverage**: 171 tests covering all major functionality
- **Enhanced Safety Testing**: Authorship validation with git username and email
- **Permission Verification**: Reset operations include extensive safety checks
- **Mock-based**: Clean separation using dependency injection for testability

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
- **Test Stability**: Fixed flaky tests through serialization (`.serialized` trait) and robust mock implementations
- **Comprehensive Coverage**: 229 tests across all major functionality with stable execution

### Key Workflows

#### Branch Prefix Workflow
Branch prefixes are stored in the configuration and can optionally require issue numbers. Prefixes support multiple issue prefixes (e.g., "FRA-", "RAPP-") and default values (e.g., "NO-JIRA"). The system combines prefix + issue prefix + issue number + description to generate branch names (e.g., `feature/FRA-42/add-login-screen`).

#### Undo Workflow
The `Undo` command (in `Commands/Reset/`) provides commit undoing with two strategies:
- `Soft` subcommand (default): Soft resets commits, moving changes back to staging area
- `Hard` subcommand: Hard resets commits, completely discarding changes
- Both support `--force` flag for commits authored by others
- Both support `--select` flag to choose from the last 7 commits interactively
- Enhanced authorship detection using both git username and email for safety
- Uses `SoftResetManager`/`HardResetManager` (in `Managers/Reset/`) for business logic
- Leverages `DefaultGitCommitManager` and `DefaultGitResetHelper` (in `Services/Git/Implementations/`) for safety
- Comprehensive permission verification prevents accidental deletion of other authors' work

#### Staging Workflow
The `Staging` command (in `Commands/FileOperations/`) provides interactive file staging/unstaging:
- `Stage` subcommand: Lists unstaged and untracked files for multi-selection staging
- `Unstage` subcommand: Lists staged files for multi-selection unstaging
- Uses `StageManager`/`UnstageManager` (in `Managers/FileOperations/`) for workflow coordination
- Leverages `SwiftPicker` for interactive multi-selection interface
- Executes individual `git add` and `git reset HEAD` commands per selected file

#### Stop Tracking Workflow
The `StopTracking` command (in `Commands/FileOperations/`) helps manage gitignore compliance:
- Reads `.gitignore` patterns and identifies tracked files that should be untracked
- Provides interactive selection between stopping all matching files or selecting specific ones
- Uses `StopTrackingManager` (in `Managers/FileOperations/`) for workflow coordination
- Leverages `DefaultGitFileTracker` (in `Services/Git/Implementations/`) for file pattern matching
- Executes `git rm --cached` commands with proper file path escaping


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
- **Always use existing mocks**: NEVER create new mock implementations without explicit approval. Use the existing mocks in `Tests/nngitTests/Shared/` (MockContext, MockShell, MockPicker, MockGitResetHelper, etc.)
- **Request permission for new functionality**: If new functionality is required that doesn't exist in current mocks, ask the user first before implementing
- **Request permission for new mocks**: If you believe new mocks need to be created, ask the user first before creating them
- **Test descriptions must be formatted as sentences**: All test case descriptions should begin with a capital letter and end with a period, written as complete sentences (e.g., `@Test("Handles user permission denial.")` not `@Test("handles user permission denial")`)
- **Use `#require` for optional unwrapping in tests**: When testing optionals that should have values, use `try #require()` to safely unwrap and provide clear test failures:
  ```swift
  // Good - clear failures when optional is nil
  let count = try #require(helper.displayedCommits).count
  #expect(count == 2)
  
  // Avoid - less clear test failures
  #expect(helper.displayedCommits?.count == 2)
  ```

### Protocol Design
- **Keep protocols focused and cohesive**: Each protocol should have a single, well-defined responsibility
- **Never inject other protocols into method signatures**: Protocols should not depend on other protocols in their method parameters
  - **Good**: `func loadConfig() throws -> GitConfig`
  - **Bad**: `func loadConfig(using picker: CommandLinePicker) throws -> GitConfig`
- **Use dependency injection at the implementation level**: If an implementation needs other dependencies, inject them through the initializer or context, not through protocol methods
- **Maintain protocol independence**: Protocols should be testable and implementable without requiring knowledge of other protocols

### Error Handling
- Git operations throw `GitShellError` for shell failures
- Commands should verify git repository exists using `shell.verifyLocalGitExists()`
- User interactions handled through `SwiftPicker` abstraction