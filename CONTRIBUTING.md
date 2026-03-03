# Contributing to GitHub Grass for Rainmeter

Thank you for your interest in contributing!
This document outlines how to get started, what we need, and how to submit your work.

---

## Getting Started

### Prerequisites

- [Rainmeter](https://www.rainmeter.net/) 4.x or higher installed
- Windows 10 / 11
- A GitHub account and Personal Access Token (`read:user` scope)
- Basic familiarity with PowerShell or Rainmeter INI syntax

### Setup

1. Fork the repository on GitHub
2. Clone your fork:
   ```
   git clone https://github.com/YOUR_USERNAME/grassmeter.git
   ```
3. Copy the skin folder into Rainmeter:
   ```
   Documents\Rainmeter\Skins\grassmeter\
   ```
4. Edit `Settings.inc` with your credentials
5. Run `run.bat` to verify everything works

---

## Project Structure

```
rainmeter_plugin\
├── Settings.inc              ← All user configuration
├── FetchAndBuild.ps1         ← GrassView data fetcher + INI generator
├── FetchCommits.ps1          ← CommitView data fetcher + INI generator
├── GrassView.ini             ← Auto-generated (do not edit directly)
└── CommitView\
    └── CommitView.ini        ← Auto-generated (do not edit directly)
```

The core workflow is:
1. PowerShell script reads `Settings.inc`
2. Calls GitHub REST/GraphQL API
3. Generates a Rainmeter `.ini` file with hardcoded meter values
4. Triggers `Rainmeter.exe !Refresh` to reload the skin

---

## How to Contribute

### 1. Pick an Issue

Browse [open issues](https://github.com/ssassu/grassmeter/issues) — look for ones labeled `good first issue` if you're new.

### 2. Comment Before Starting

Leave a comment on the issue to let others know you're working on it.

### 3. Make Your Changes

- Keep changes focused — one issue per PR
- Test with Rainmeter by running the relevant `.bat` file
- Check the generated `.ini` file visually on the desktop

### 4. Submit a Pull Request

- Write a clear PR title (e.g., `feat: add Light color theme`)
- Describe what changed and why
- Reference the issue number (e.g., `Closes #3`)

---

## Code Style

### PowerShell (`FetchAndBuild.ps1`, `FetchCommits.ps1`)

- Use `[System.IO.File]::WriteAllText(...)` for file writes (not `Out-File`)
- Log every meaningful step with the `L()` function
- Keep INI generation in the `W()` builder pattern
- No external dependencies — pure PowerShell + Windows APIs only

### Rainmeter INI (generated)

- All generated files begin with a `; DO NOT EDIT` comment
- Use `AccurateText=1` for consistent font rendering
- `AntiAlias=1` on all String meters
- Background via `Meter=Shape` rectangle, not `Meter=Image`

---

## Good First Issues

| # | Title | Difficulty |
|---|-------|------------|
| [#1](https://github.com/ssassu/grassmeter/issues/1) | Add opacity slider UI on widget | Beginner |
| [#2](https://github.com/ssassu/grassmeter/issues/2) | Add light background preset | Beginner |
| [#3](https://github.com/ssassu/grassmeter/issues/3) | Improve error message display on widget | Beginner/Intermediate |
| [#4](https://github.com/ssassu/grassmeter/issues/4) | Add system startup auto-refresh | Intermediate |
| [#5](https://github.com/ssassu/grassmeter/issues/5) | Create .rmskin package | Beginner |
| [#6](https://github.com/ssassu/grassmeter/issues/6) | Add private repo contribution toggle | Intermediate |

---

## Questions?

Open a [GitHub Discussion](https://github.com/ssassu/grassmeter/discussions) or leave a comment on the relevant issue.
