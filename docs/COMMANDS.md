# nngit Commands Reference

A comprehensive guide to all nngit commands, organized by workflow and complexity.

## Table of Contents

- [Getting Started](#getting-started)
- [Essential Daily Workflow](#essential-daily-workflow)
- [Branch Management](#branch-management)
- [File Operations & Change Management](#file-operations--change-management)
- [History & Undo Operations](#history--undo-operations)
- [Template File Management](#template-file-management)
- [Configuration & Setup](#configuration--setup)
- [Advanced Usage Patterns](#advanced-usage-patterns)
- [Appendices](#appendices)

---

## Getting Started

### Installation
```bash
brew tap nikolainobadi/nntools
brew install nngit
```

### Basic Usage Pattern
```bash
nngit <command> [arguments] [options]
nngit <command> --help    # Get help for any command
nngit --version          # Show version
```

### Configuration
nngit stores settings in `~/.config/nngit/config.json` (created automatically on first use).
Template files are stored in `~/.config/nngit/templates/` (or referenced by direct path).

### Prerequisites
- Must be run inside a Git repository (except for `new-git` command)
- Git must be installed and configured

---

## Essential Daily Workflow

### `new-branch` - Create New Branches

**Purpose**: Create new branches with interactive support and validation.

#### Basic Usage
```bash
# Interactive mode - prompts for branch name
nngit new-branch

# Direct mode - specify name immediately
nngit new-branch "add user auth"  # Creates: add-user-auth
```

#### Features
- Automatic branch name formatting and validation
- Checks for remote repository and handles conflicts
- Switches to new branch automatically
- Supports branch prefixes from configuration

#### Safety Features
- Prevents duplicate branch names
- Requires merging remote changes before creating new branches
- Validates git repository exists

---

### `switch-branch` - Switch Between Branches

**Purpose**: Interactively switch between local and remote branches.

#### Basic Usage
```bash
# Interactive selection from all available branches
nngit switch-branch

# Switch to specific branch (if exists)
nngit switch-branch main
```

#### Features
- Lists both local and remote branches
- Handles remote branch checkout automatically
- Shows current branch status
- Supports partial name matching

#### Safety Features
- Prevents switching with uncommitted changes (prompts for stashing)
- Validates branch exists before switching

---

### `new-push` - Safely Push New Branches

**Purpose**: Push new branches to remote with comprehensive safety checks.

#### Basic Usage
```bash
# Push current branch with all safety checks
nngit new-push
```

#### Features
- Sets upstream tracking automatically (`-u origin <branch>`)
- Verifies remote repository exists
- Checks for naming conflicts
- Compares with default branch

#### Safety Features
- **No uncommitted changes**: Prevents accidental pushes with dirty working tree
- **Remote existence check**: Confirms remote repository is accessible
- **Conflict prevention**: Ensures no remote branch with same name exists
- **Behind main warning**: Alerts if branch is behind default branch
- **User confirmation**: Prompts before pushing if behind main

---

### `activity` - View Git Activity

**Purpose**: Display Git activity statistics with colorized output and daily breakdowns.

#### Basic Usage
```bash
# Show today's activity (default)
nngit activity

# Show activity for specific number of days
nngit activity --days 7

# Show activity with daily breakdown
nngit activity --days 30 --verbose
```

#### Options
- `--days, -d <number>`: Number of days to analyze (default: 1)
- `--verbose, -v`: Show day-by-day breakdown (only for days > 1)
- `--no-color`: Disable colored output

#### Features
- Colorized output (respects `NO_COLOR` environment variable)
- Intelligent singular/plural formatting
- Daily breakdown for multi-day periods
- Comprehensive git log parsing

---

## Branch Management

### `delete-branch` - Delete Branches

**Purpose**: Safely delete local branches with multiple selection options.

#### Basic Usage
```bash
# Interactive selection of branches to delete
nngit delete-branch

# Delete all merged branches
nngit delete-branch --all-merged
nngit delete-branch -m  # Short form

# Search for specific branches
nngit delete-branch feature
```

#### Options
- `--all-merged, -m`: Delete all merged branches without individual selection
- `<search_term>`: Filter branches by partial name match

#### Features
- Multi-selection interface for precise control
- Automatic origin pruning after deletion
- Shows merge status for each branch
- Excludes current branch and default branch automatically

#### Safety Features
- **Current branch protection**: Cannot delete the branch you're currently on
- **Default branch protection**: Cannot delete the configured default branch (main/master)
- **Merge status confirmation**: Prompts for confirmation when deleting unmerged branches
- **Forced deletion warning**: Clear warnings for unmerged branches requiring force delete

---

## File Operations & Change Management

### `discard` - Discard Changes

**Purpose**: Discard staged, unstaged, or all local changes with optional file selection.

#### Basic Usage
```bash
# Discard all changes (staged and unstaged) - default behavior
nngit discard

# Discard only staged changes
nngit discard --scope staged

# Discard only unstaged changes  
nngit discard --scope unstaged

# Interactive file selection
nngit discard --files
```

#### Options
- `--scope, -s <scope>`: Which changes to discard (`staged`, `unstaged`, `both`)
- `--files`: Enable interactive file selection mode

#### Features
- Supports different scopes of changes
- Multi-selection interface for precise control
- Clear confirmation prompts for safety

#### Safety Features
- **Confirmation prompts**: Always asks for confirmation before discarding
- **Scope clarity**: Clearly indicates what will be discarded
- **File-level control**: Option to select specific files rather than all changes

---

### `stop-tracking` - Manage Gitignore Compliance

**Purpose**: Stop tracking files that match patterns in your `.gitignore` file.

#### Basic Usage
```bash
# Analyze .gitignore and offer options for tracked files that should be ignored
nngit stop-tracking
```

#### Features
- Reads and interprets `.gitignore` patterns
- Handles complex patterns (wildcards, negation, directories)
- Batch or selective operation modes
- Proper file path escaping for git commands

#### Safety Features
- **Preview before action**: Shows which files will be affected
- **User choice**: Option to select specific files or process all
- **Non-destructive**: Uses `git rm --cached` to preserve files locally

---

## History & Undo Operations

### `undo` - Undo Commits

**Purpose**: Undo commits using soft or hard reset strategies with comprehensive safety features.

#### Command Structure
```bash
nngit undo <subcommand> [count] [options]
```

#### Subcommands
- `soft` (default): Moves commits to staging area, preserving changes
- `hard`: Completely removes commits and changes

---

### `undo soft` - Soft Reset (Default)

**Purpose**: Move commits back to staging area while preserving all changes.

#### Basic Usage
```bash
# Soft reset 1 commit (default behavior)
nngit undo
nngit undo soft
nngit undo 1

# Soft reset multiple commits
nngit undo soft 3
nngit undo 3

# Interactive selection
nngit undo soft --select
nngit undo --select
```

#### Options
- `<count>`: Number of commits to reset (default: 1)
- `--select, -s`: Choose from last 7 commits interactively
- `--force`: Override authorship safety checks

#### Safety Features
- **Authorship protection**: Prevents resetting commits by other authors
- **Email + username validation**: Uses both git username and email for authorship detection
- **Confirmation prompts**: Shows exactly what will be reset
- **Change preservation**: All changes remain in staging area

---

### `undo hard` - Hard Reset

**Purpose**: Completely remove commits and discard all changes. **⚠️ DESTRUCTIVE OPERATION**

#### Basic Usage
```bash
# Hard reset 1 commit
nngit undo hard
nngit undo hard 1

# Hard reset multiple commits
nngit undo hard 3

# Interactive selection with safety override
nngit undo hard --select --force
```

#### Options
- `<count>`: Number of commits to reset (default: 1)
- `--select, -s`: Choose from last 7 commits interactively  
- `--force`: Override authorship safety checks

#### Safety Features
- **Double confirmation**: Requires typing 'CONFIRM' for destructive operations
- **Authorship protection**: Same protection as soft reset
- **Clear warnings**: Multiple warnings about permanent data loss
- **Preview**: Shows exactly what will be lost

#### ⚠️ Warning
Hard reset permanently deletes commits and changes. Use with extreme caution.

---

## Template File Management

Template files allow you to create reusable file templates that can be quickly added to new projects.

### `register-git-file` - Register Template Files

**Purpose**: Register template files for reuse across multiple repositories.

#### Basic Usage
```bash
# Interactive mode - prompts for all parameters
nngit register-git-file

# Direct mode with all parameters
nngit register-git-file --source ~/templates/README.md --name README.md --nickname "Project Readme"

# Direct path mode (reference file at current location)
nngit register-git-file --source ~/.gitignore --name .gitignore --nickname "Standard Gitignore" --direct-path
```

#### Options
- `--source <path>`: Path to the source template file
- `--name <filename>`: Output filename (defaults to source filename)
- `--nickname <name>`: Display name for the template
- `--direct-path`: Use file at current location instead of copying

#### Features
- Interactive prompts for missing parameters
- Automatic template directory creation
- File conflict handling with replacement prompts
- Support for both copied templates and direct path references
- Automatic filename inference from source path

#### Template Storage
- **Copied templates**: Stored in `~/.config/nngit/templates/`
- **Direct path**: References original file location
- **Configuration**: Registered files stored in `~/.config/nngit/config.json`

---

### `add-git-file` - Use Template Files

**Purpose**: Add registered template files to the current repository.

#### Basic Usage
```bash
# Interactive selection from registered templates
nngit add-git-file

# Add specific template by name or nickname
nngit add-git-file "Project Readme"
nngit add-git-file README.md
```

#### Features
- Interactive template selection
- Support for both filename and nickname matching
- Automatic file copying to current repository
- Clear success confirmation

#### Safety Features
- Verifies git repository exists
- Handles file conflicts gracefully
- Preserves file permissions and content

---

### `unregister-git-file` - Remove Template Files

**Purpose**: Remove registered template files from nngit configuration.

#### Basic Usage
```bash
# Interactive selection of template to remove
nngit unregister-git-file

# Remove specific template by name or nickname
nngit unregister-git-file "Project Readme"
nngit unregister-git-file README.md

# Remove all registered templates
nngit unregister-git-file --all
```

#### Options
- `<template_name>`: Name or nickname of template to unregister
- `--all`: Remove all registered git files

#### Features
- Case-insensitive matching for filenames and nicknames
- Interactive selection when no name provided
- Option to delete template files from disk
- Bulk removal with `--all` flag

#### Safety Features
- **Confirmation prompts**: Always asks before removing templates
- **Disk file option**: Separate confirmation for deleting template files from disk
- **Batch confirmation**: Clear summary for bulk operations
- **Cancellation support**: Can cancel operations at any point

---

## Configuration & Setup

### `config` - Edit Configuration

**Purpose**: Modify nngit configuration settings.

#### Basic Usage
```bash
# Interactive configuration editing
nngit config

# Set default branch directly
nngit config --default-branch develop
```

#### Options
- `--default-branch <name>`: Set the default branch name

#### Configuration File Location
`~/.config/nngit/config.json`

#### Configuration Settings
- **Default branch**: Used for comparisons in new-push and other operations
- **Branch prefixes**: Configure structured branch naming
- **Registered git files**: Template file registry
- **Branch loading options**: Control branch listing behavior

---

### `new-git` - Initialize Git Repository

**Purpose**: Initialize a new Git repository with nngit-friendly setup.

#### Basic Usage
```bash
# Initialize git repository in current directory
nngit new-git
```

#### Features
- Standard git repository initialization
- Optional initial commit creation
- Interactive remote repository setup
- nngit configuration initialization

---

### `new-remote` - Add Remote Repository

**Purpose**: Add remote repository with interactive setup.

#### Basic Usage
```bash
# Interactive remote setup
nngit new-remote
```

#### Features
- Interactive remote configuration
- Connection testing
- Support for custom remote names
- URL validation

---

## Advanced Usage Patterns

### Command Combinations for Common Workflows

#### Complete Feature Development Workflow
```bash
# 1. Create feature branch
nngit new-branch "feature/user-dashboard"

# 2. Work on feature... make commits...

# 3. Check activity to review work
nngit activity --days 3

# 4. Push feature branch
nngit new-push

# 5. After code review, switch back to main and clean up
nngit switch-branch main
nngit delete-branch feature/user-dashboard
```

#### Emergency Hotfix Workflow
```bash
# 1. Switch to main and create hotfix branch
nngit switch-branch main
nngit new-branch "hotfix/critical-security-fix"

# 2. Make fix and push immediately
# ... make commits ...
nngit new-push

# 3. After merge, cleanup
nngit switch-branch main
nngit delete-branch hotfix/critical-security-fix
```

#### Project Template Setup Workflow
```bash
# 1. Register common project templates
nngit register-git-file --source ~/.templates/README.md --nickname "Standard Readme"
nngit register-git-file --source ~/.templates/.gitignore --nickname "Node Gitignore"
nngit register-git-file --source ~/.templates/LICENSE --nickname "MIT License"

# 2. Start new project
mkdir new-project && cd new-project
nngit new-git

# 3. Add templates
nngit add-git-file "Standard Readme"
nngit add-git-file "Node Gitignore"
nngit add-git-file "MIT License"
```

### Configuration Best Practices

#### Setting Up Branch Prefixes
Edit `~/.config/nngit/config.json`:
```json
{
  "defaultBranch": "main",
  "branchPrefixes": [
    {
      "prefix": "feature",
      "requiresIssue": true,
      "issuePrefixes": ["FEAT-", "EPIC-"],
      "defaultIssuePrefix": "FEAT-"
    },
    {
      "prefix": "bugfix",
      "requiresIssue": false
    }
  ],
  "gitFiles": [...]
}
```

#### Template Organization
```bash
# Organize templates by project type
nngit register-git-file --source ~/.templates/web/package.json --nickname "Web Package.json"
nngit register-git-file --source ~/.templates/mobile/Podfile --nickname "iOS Podfile"
nngit register-git-file --source ~/.templates/common/README.md --nickname "Standard Readme"
```

### Safety and Recovery

#### Before Destructive Operations
```bash
# Always check current status
git status
nngit activity

# Create backup branch before major changes
git branch backup-$(date +%Y%m%d)

# Use soft reset first, then hard if needed
nngit undo soft 3  # Review changes in staging
# If satisfied with reset:
nngit undo hard 3  # Only if you're certain
```

#### Recovery Patterns
```bash
# If you accidentally hard reset
git reflog  # Find the commit hash
git cherry-pick <commit-hash>  # Restore specific commits

# If you need to restore deleted branch
git reflog --all
git checkout -b recovered-branch <commit-hash>
```

---

## Appendices

### A. Quick Reference Table

| Command | Purpose | Key Options | Safety Level |
|---------|---------|-------------|--------------|
| `new-branch` | Create branches | Interactive/direct | ✅ Safe |
| `switch-branch` | Switch branches | Search support | ✅ Safe |
| `new-push` | Push with checks | Auto upstream | ✅ Safe |
| `delete-branch` | Delete branches | `-m`, search | ⚠️ Moderate |
| `activity` | View stats | `--days`, `--verbose` | ✅ Safe |
| `discard` | Discard changes | `--scope`, `--files` | ⚠️ Moderate |
| `stop-tracking` | Untrack files | Interactive | ✅ Safe |
| `undo soft` | Soft reset | `--select`, `--force` | ⚠️ Moderate |
| `undo hard` | Hard reset | `--select`, `--force` | 🚨 Dangerous |
| `register-git-file` | Add templates | `--direct-path` | ✅ Safe |
| `add-git-file` | Use templates | Interactive | ✅ Safe |
| `unregister-git-file` | Remove templates | `--all` | ✅ Safe |
| `config` | Edit settings | `--default-branch` | ✅ Safe |

### B. Configuration File Reference

Location: `~/.config/nngit/config.json`

```json
{
  "defaultBranch": "main",
  "branchPrefixes": [
    {
      "prefix": "feature",
      "requiresIssue": true,
      "issuePrefixes": ["FEAT-", "EPIC-"],
      "defaultIssuePrefix": "FEAT-"
    }
  ],
  "gitFiles": [
    {
      "fileName": "README.md",
      "nickname": "Standard Readme",
      "localPath": "/Users/user/.config/nngit/templates/README.md"
    }
  ],
  "branchLoadingOptions": {
    "loadRemoteBranches": true,
    "maxBranches": 50
  },
  "rebasePreference": "always",
  "pruneAfterDelete": true
}
```

### C. Template Management Workflows

#### Template Creation Workflow
1. Create template file with placeholder content
2. Test template in a sample project
3. Register with descriptive nickname
4. Document template purpose and usage

#### Template Maintenance
```bash
# List all registered templates
cat ~/.config/nngit/config.json | jq '.gitFiles'

# Update template file
# Edit the template file directly, then re-register:
nngit unregister-git-file "Old Template"
nngit register-git-file --source ~/updated-template.md --nickname "Updated Template"
```

### D. Safety Features Overview

#### Authorship Protection
- Uses both git username and email for validation
- Prevents accidental modification of others' commits
- Override available with `--force` flag

#### Confirmation Systems
- **Single confirmation**: Standard operations (delete, discard)
- **Double confirmation**: Destructive operations (hard reset)
- **Typed confirmation**: Most dangerous operations (requires typing "CONFIRM")

#### Data Preservation
- Soft reset preserves changes in staging area
- Template unregistration optionally preserves files on disk
- Branch deletion preserves commits (recoverable via reflog)

### E. Troubleshooting

#### Common Issues

**"Missing git repository" error:**
```bash
# Ensure you're in a git repository
pwd
git status
# Or initialize new repository:
nngit new-git
```

**"Permission denied" errors:**
```bash
# Check file permissions
ls -la ~/.config/nngit/
# Fix permissions if needed:
chmod 755 ~/.config/nngit/
```

**"Template file not found" errors:**
```bash
# Check template exists:
ls -la ~/.config/nngit/templates/
# Re-register if missing:
nngit register-git-file --source /path/to/template
```

#### Getting Help

```bash
# General help
nngit --help

# Command-specific help
nngit <command> --help
nngit undo soft --help

# Version information
nngit --version
```

#### Recovery Commands

```bash
# View git reflog to recover lost commits
git reflog

# Restore from backup branch
git checkout backup-branch
git checkout -b recovered-work

# Check configuration
cat ~/.config/nngit/config.json
```

---

## Version

This documentation is for nngit v0.5.2. For the latest version and updates, visit the [GitHub repository](https://github.com/nikolainobadi/nngit).

---

*Happy coding with nngit! 🚀*