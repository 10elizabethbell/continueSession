# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Workspace overview

This is a multi-project workspace. Each subdirectory is an independent project:

| Project | Type | Stack | CLAUDE.md |
|---|---|---|---|
| `amazon/` | Amazon OA scraper (2-step: storefront → supplier leads) | TypeScript, Playwright, SQLite, Claude Haiku | Yes |
| `menuBarApps/ApplicationManager/` | Menu bar app launcher/manager | Swift (swiftc, no Xcode) | No |
| `menuBarApps/Caffeinated/` | Menu bar app | Swift (Xcode project) | No |
| `menuBarApps/whisperFlow/` | Menu bar dictation app (on-device transcription + LLM cleanup) | Python, MLX, PyObjC | Yes |
| `vendingMachines/` | Vending machine web app | Next.js, TypeScript | No (see AGENTS.md) |

For `amazon/` and `menuBarApps/whisperFlow/`, read their project-level `CLAUDE.md` first — they contain detailed architecture, commands, and constraints.

## Menu bar app conventions

All menu bar apps in this workspace follow the same pattern:
- A compiled C launcher (`launcher.c`) built by `build.sh` is the `.app`'s `CFBundleExecutable` — **never a shell script or symlink to another binary**. macOS's window server parks status items off-screen when the bundle executable has exec'd a different binary.
- `build.sh` produces `build/<AppName>.app`.
- `ApplicationManager` auto-discovers sibling `build/*.app` bundles to list them in its menu; it reads `MenuBarSymbolName` from each app's `Info.plist` for the menu icon.

## ApplicationManager build

```bash
cd menuBarApps/ApplicationManager
./build.sh          # compiles Swift sources → build/ApplicationManager.app
open build/ApplicationManager.app
```

Requires Xcode or Command Line Tools. No other dependencies.

## vendingMachines

Next.js app. This version of Next.js may have breaking API changes from training data — check `node_modules/next/dist/docs/` before writing any code.

```bash
cd vendingMachines
npm run dev         # dev server at http://localhost:3000
```

## Utilities

`continueSession <time> <directory> <session-id>` — waits `time` decimal hours then resumes a Claude Code session by ID (`-b` to background). Installed at `/opt/homebrew/bin/continueSession`. Find your session ID in the `CLAUDE_CODE_SESSION_ID` env var or via `env | grep CLAUDE_CODE_SESSION_ID` inside a running session.
