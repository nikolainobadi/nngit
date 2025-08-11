# nngit

![Swift Version](https://badgen.net/badge/swift/6.0%2B/purple)
![Platform](https://img.shields.io/badge/platform-macOS%2014-blue)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## Overview
A command-line utility for managing Git branches and history. `nngit` offers helpers for creating, switching, and deleting branches, interactive file staging/unstaging, discarding local changes, and undoing commits.

## Features
- Create branches with optional prefixes and issue numbers
- Manage branch prefixes (add, edit, delete, list)
- Switch between local and remote branches
- Delete merged branches with optional origin pruning
- **Interactive file staging and unstaging** with multi-selection
- Track and manage your frequently used branches
- Discard staged/unstaged changes
- Undo commits with safety checks
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
$ nngit my-branches add            # Track current branch
$ nngit discard --files both
$ nngit undo-commit 2
$ nngit edit-config --default-branch develop
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

### Branch Prefix Workflow
Below is an example showing how to add a prefix that requires an issue number and then create a branch using it:

```bash
$ nngit add-branch-prefix feature --requires-issue-number --issue-number-prefix ISS-
$ nngit new-branch --prefix feature --issue 42 "Add login screen"
```

### MyBranches Workflow
Track your frequently used branches for easier access:

```bash
$ nngit my-branches add        # Add current branch to tracked list
$ nngit my-branches            # List tracked branches (default subcommand)
$ nngit my-branches remove     # Remove branches from tracked list
```

## Configuration
`nngit` stores its settings in a JSON file located at
`~/.config/nngit/config.json`.  This file is created automatically the first time
you run the tool.  You can modify values using the `edit-config` command or by
opening the file in your editor of choice.

Branch prefixes are kept inside this same file.  A prefix represents the first
segment of a branch name such as `feature` or `bugfix`.  Prefixes can optionally
require an issue number and may provide a small string to prepend before the
number.  Use the `add-branch-prefix`, `edit-branch-prefix`, `delete-branch-prefix`
and `list-branch-prefix` commands to manage them.  When creating a new branch,
`nngit` will combine the selected prefix, the issue number (if any) and your
branch description to generate the final name.

Non-Homebrew users can build the executable manually:

```bash
swift build -c release
```

The compiled binary will be available at `.build/release/nngit`.

## Architecture Notes
- Built on top of `swift-argument-parser` for CLI parsing
- Uses `SwiftShell` for shell execution and `GitShellKit` abstractions
- Configuration is stored via `NnConfigKit`
- Modular components injected through a context for easier testing

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
