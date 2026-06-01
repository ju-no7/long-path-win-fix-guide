# long-paths-windows

Fix "filename too long" errors on Windows by enabling long path support in Git and Windows Registry.

## What it fixes

- `git clone` fails with `filename too long`
- `git checkout` fails on deep directory trees
- `npm install` / `yarn` / `pnpm` errors in `node_modules`
- Any operation hitting Windows 260-char `MAX_PATH` limit

## How it works

A single PowerShell script that detects your environment and applies the right settings:

- `git config core.longpaths true` (local or global, depending on whether you're in a repo)
- `LongPathsEnabled = 1` in Windows Registry — HKLM if admin, falls back to HKCU (current user) so no admin rights are needed

## Installation

```bash
npx skills add arterm-sedov/long-paths-windows-skill --skill long-paths-windows
```

**Manual install:**

```bash
git clone https://github.com/arterm-sedov/long-paths-windows-skill.git
cp -r skills/long-paths-windows ~/.agents/skills/long-paths-windows
```

```powershell
Copy-Item -Recurse skills\long-paths-windows ~\.agents\skills\long-paths-windows
```

Restart the agent afterwards.

## Manual usage (without an agent)

Clone the repo, then run the script directly:

```powershell
# Check what's broken
powershell -ExecutionPolicy Bypass -File .\scripts\Enable-LongPaths.ps1 -Mode Status

# Fix everything (auto-detects git repo, admin rights, etc.)
powershell -ExecutionPolicy Bypass -File .\scripts\Enable-LongPaths.ps1 -Mode Enable -Force
```

Modes:

| Command | Does |
|---------|------|
| `-Mode Status` | Show current Git + registry config |
| `-Mode Enable` | Apply all fixes |
| `-Mode Fix` | Enable then verify |

Registry changes via HKCU (the default without admin) need a logoff/logon to take effect. HKLM changes take effect immediately.

## Usage with AI agents

After the skill is installed, trigger it by describing your error:

> "I'm getting 'filename too long' when cloning a repo on Windows"

The agent will run `Enable-LongPaths.ps1 -Mode Enable`, apply both Git and registry settings, and tell you if a restart is needed.

## What's in it

```
skills/long-paths-windows/
├── SKILL.md                       # Agent instructions
├── scripts/
│   └── Enable-LongPaths.ps1       # Status / Enable / Fix utility
└── references/
    └── long-paths-guide.md        # Manual steps & troubleshooting
```
