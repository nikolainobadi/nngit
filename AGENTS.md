# Repository Guidelines

## Project Structure & Module Organization
- Swift package root with `Package.swift`; binary target is `nngit`.
- Source lives in `Sources/nngit/` with clear separation: `Commands/*` (CLI entry points), `Managers/*` (workflow logic), `Services/*` (Git/config/filesystem adapters), `Core/*` (context, models, extensions), plus `Helpers`, `Errors`, and `Main/Nngit.swift`.
- Docs live in `README.md` and `docs/COMMANDS.md`; release notes in `CHANGELOG.md`.
- Tests mirror the code layout under `Tests/nngitTests/UnitTests/...`; shared mocks and stubs sit in `Tests/nngitTests/Shared/`.

## Build, Test, and Development Commands
- `swift build` for debug builds; `swift build -c release` outputs `.build/release/nngit`.
- `swift run nngit --help` to view available commands; `swift run nngit new-branch feature-login` (or similar) to exercise flows locally.
- `swift test` runs the swift-testing suite; use `swift test --filter NewPushManagerTests` to scope to a suite when iterating.

## Coding Style & Naming Conventions
- Target Swift 6/macOS 14; follow Swift API Design Guidelines with UpperCamel types and lowerCamel properties/functions.
- Use 4-space indentation and keep parameter lists on a single line when readable; prefer protocol-first design with dependencies injected via `DefaultContext`.
- Organize files with `// MARK:` sections; keep helpers scoped `private`/`fileprivate` and use small extensions for convenience APIs.
- Add the standard Swift header with author `Nikolai Nobadi` on new Swift files to match existing sources.

## Testing Guidelines
- Use the `Testing` framework (`@Test`, `#expect`) for new cases; mirror production namespaces (e.g., `Managers/Branch`, `Commands/Reset`) under `UnitTests/`.
- Reuse shared fakes (`MockShell`, `MockPicker`, `StubConfigLoader`, etc.) to avoid shelling out to real git; prefer deterministic inputs over filesystem or network access.
- Cover new behaviors for branch safety checks, file tracking, and config validation; add regression tests alongside bug fixes and document intent in test names.

## Commit & Pull Request Guidelines
- Keep commit subjects concise and imperative; conventional prefixes like `feat:`, `fix:`, `docs:`, and `test:` appear in history alongside straightforward version bumps (`Update version to v0.7.0`).
- PRs should explain motivation, list key commands exercised, and call out tests added or impacted; link issues when applicable.
- Update `docs/COMMANDS.md`, `README.md`, and `CHANGELOG.md` when modifying user-facing commands or release details; include sample CLI output if behavior changes.

## Resource Requests
- Ask before loading `~/.codex/guidelines/shared/shared-formatting-codex.md` when editing Swift code or touching formatting expectations.
- Ask before loading `~/.codex/guidelines/testing/base_unit_testing_guidelines.md` when discussing or adjusting tests.
- Ask before loading `~/.codex/guidelines/testing/CLI_TESTING_GUIDE_CODEX.md` when working on CLI-related tests.
- Ask before loading `~/.codex/guidelines/cli/NnShellKit-Usage.md` when modifying shell execution flows or NnShellKit usage.
- Ask before loading `~/.codex/guidelines/cli/NnShellTesting-Usage.md` when adding or updating tests that touch shell execution.
- Ask before loading `~/.codex/guidelines/cli/SwiftPickerKit-usage.md` when editing SwiftPickerKit integrations.
- Ask before loading `~/.codex/guidelines/cli/SwiftPickerTesting-usage.md` when testing SwiftPickerKit-driven flows.

## CLI Design
- Single-responsibility commands
- Clear, predictable argument handling
- Minimal logging to stdout/stderr
- Use `NnShellKit` for shell execution; prefer absolute program paths

## CLI Testing
- Behavior-driven tests for command logic
- Use `makeSUT` pattern where applicable
- Test both success and error paths
- Verify output formatting
- Use `MockShell` from NnShellTesting for shell interactions
