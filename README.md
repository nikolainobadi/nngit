# nngit

![Swift Version](https://badgen.net/badge/swift/6.0%2B/purple)
![Platform](https://img.shields.io/badge/platform-macOS%2014-blue)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

## Overview
A command-line utility for managing Git branches and history. `nngit` offers helpers for creating, switching, and deleting branches, as well as discarding local changes and undoing commits.

## Features
- Create branches with optional prefixes and issue numbers
- Manage branch prefixes (add, edit, delete, list)
- Switch between local and remote branches
- Delete merged branches and prune origin
- Discard staged/unstaged changes
- Undo commits with safety checks

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
$ nngit discard --files both
$ nngit undo-commit 2
```

## Architecture Notes
- Built on top of `swift-argument-parser` for CLI parsing
- Uses `SwiftShell` for shell execution and `GitShellKit` abstractions
- Configuration is stored via `NnConfigKit`
- Modular components injected through a context for easier testing

## Documentation
The source is documented with inline comments, and a test suite resides under `Tests/`.

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
