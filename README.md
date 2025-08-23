# nngit

![Swift Version](https://badgen.net/badge/swift/6.0%2B/purple)
![Platform](https://img.shields.io/badge/platform-macOS%2014-blue)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## Overview
A command-line utility for managing Git branches and history. `nngit` offers helpers for creating, switching, and deleting branches, interactive file staging/unstaging, discarding local changes, and undoing commits.

## Features
- Create branches with optional prefixes and issue numbers
- Switch between local and remote branches
- Delete merged branches with optional origin pruning
- **Interactive file staging and unstaging** with multi-selection
- Checkout remote branches that don't exist locally
- Compare branch differences with `branch-diff`
- Discard staged/unstaged changes with file selection options
- **Enhanced undo commits** with soft/hard reset strategies, safety checks, and interactive selection
- Edit overall nngit configuration

## Installation
```bash
brew tap nikolainobadi/nntools
brew install nngit
```

## Usage
Run commands via `swift run` or the built binary. A few examples:
```bash
$ nngit new-branch feature "Add login"
$ nngit switch-branch
$ nngit staging stage              # Interactive file staging
$ nngit staging unstage            # Interactive file unstaging  
$ nngit checkout-remote            # Checkout remote branches
$ nngit branch-diff                # Compare current branch with main
$ nngit discard --files both       # Discard staged and unstaged changes
$ nngit undo hard 2 --select       # Interactive selection of commits to hard reset
$ nngit config --default-branch develop
```

### Interactive Staging Workflow
Use the staging commands to selectively stage or unstage files:

```bash
# Stage specific files interactively
$ nngit staging stage
# (shows list of unstaged/untracked files for multi-selection)

# Unstage specific files interactively  
$ nngit staging unstage
# (shows list of staged files for multi-selection)

# Default subcommand is 'stage'
$ nngit staging  # same as 'nngit staging stage'
```


### Undo Workflow
Undo commits using soft or hard reset strategies with enhanced safety features:

```bash
$ nngit undo 3                      # Soft reset 3 commits (moves to staging area, default)
$ nngit undo soft 2 --force         # Soft reset 2 commits, including from other authors
$ nngit undo soft --select          # Interactive selection from last 7 commits
$ nngit undo hard 1                 # Hard reset 1 commit (completely discards changes)
$ nngit undo hard 2 --force         # Hard reset 2 commits, including from other authors
$ nngit undo hard --select --force  # Interactive selection with force override
```

**Safety Features:**
- Enhanced authorship detection using both git username and email
- Automatic prevention of resetting commits by other authors (unless `--force` is used)
- Interactive commit selection with `--select` flag
- Clear confirmation prompts showing what will be affected

## Configuration
`nngit` stores its settings in a JSON file located at `~/.config/nngit/config.json`. This file is created automatically the first time you run the tool. You can modify values using the `config` command or by opening the file in your editor of choice.

The configuration includes settings for:
- Default branch name
- Branch loading behavior
- Rebase and prune preferences  
- Branch prefix configurations (for structured branch naming)

Non-Homebrew users can build the executable manually:

```bash
swift build -c release
```

The compiled binary will be available at `.build/release/nngit`.

## Architecture
This Swift CLI tool follows a clean, modular architecture with clear separation of concerns:

### Project Structure
```
Sources/nngit/
├── Core/                     # Essential components
│   ├── Context/              # Dependency injection
│   ├── Models/               # Data models
│   └── Extensions/           # Type extensions
├── Services/                 # External integrations
│   ├── Git/                  # Git operations (protocols & implementations)
│   └── Configuration/        # Config management
├── Managers/                 # Business logic
│   ├── Branch/               # Branch-related workflows
│   ├── FileOperations/       # File staging/unstaging/discarding
│   ├── Reset/                # Commit reset operations
│   └── Utility/              # Utility functions
├── Commands/                 # CLI command definitions
│   ├── Branch/               # Branch commands
│   ├── FileOperations/       # File operation commands
│   ├── Reset/                # Reset commands
│   ├── Configuration/        # Config commands
│   └── BranchDiff.swift      # Branch comparison
├── Errors/                   # Error definitions
└── Nngit.swift              # Main entry point
```

### Key Design Principles
- **Dependency Injection**: Context-based injection for testability
- **Feature-Based Organization**: Related functionality grouped together
- **Protocol/Implementation Split**: Clean abstraction boundaries
- **Enhanced Safety Systems**: Comprehensive authorship detection and permission checks
- **Comprehensive Testing**: 171 passing tests with behavior-driven approach

### Dependencies
- Built on `swift-argument-parser` for CLI parsing
- Uses `SwiftShell` and `GitShellKit` for Git operations
- Configuration managed via `NnConfigKit`
- User interaction through `SwiftPicker`

## Documentation
The source is documented with inline comments, and a test suite resides under `Tests/`.

## Troubleshooting
If you see a "missing git repository" error when running commands, ensure you are inside a git repository. Navigate to your project root or run `git init` to create one before using `nngit`.

## Acknowledgments
- [SwiftShell](https://github.com/kareman/SwiftShell)
- [NnGitKit](https://github.com/nikolainobadi/NnGitKit)
- [NnConfigKit](https://github.com/nikolainobadi/NnConfigKit)
- [swift-argument-parser](https://github.com/apple/swift-argument-parser)
- [SwiftPicker](https://github.com/nikolainobadi/SwiftPicker)

## About This Project
This public repository hosts a tool for automating everyday Git tasks on macOS. It streamlines branch workflows and provides safeguards when discarding work.

## Contributing
Feel free to open issues and pull requests on [GitHub](https://github.com/nikolainobadi/nngit).

## License
This project is available under the MIT license. See [LICENSE](LICENSE) for details.
