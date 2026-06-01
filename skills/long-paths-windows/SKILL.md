---
name: long-paths-windows
description: Always use this skill when dealing with long file path issues on Windows — git clone failures with "filename too long", git checkout errors on deep directory trees, npm/yarn install errors on Windows with long paths, or any "LongPathsEnabled" or "core.longpaths" configuration task. This skill provides a unified PowerShell utility that detects, enables, and verifies long path support in both Git and Windows Registry, handling all scenarios (before cloning, after cloning, with/without admin rights).
---

# long-paths-windows

## What you do

When a user hits a long path error on Windows, you use the bundled PowerShell script to diagnose and fix it — no manual guides, no guesswork.

The script is at `scripts/Enable-LongPaths.ps1` (relative to this SKILL.md). Resolve its full path before running.

## Workflow

1. **Check status first** — always start here so the user sees what's wrong:
   ```
   powershell -ExecutionPolicy Bypass -File "<path>/scripts/Enable-LongPaths.ps1" -Mode Status
   ```

2. **Enable with auto-detection** — the default `-Mode Enable` handles everything: detects git repo vs not, admin vs non-admin, sets the right git scope and registry hive:
   ```
   powershell -ExecutionPolicy Bypass -File "<path>/scripts/Enable-LongPaths.ps1" -Mode Enable -Force
   ```
   Use `-Force` to skip prompts so the user doesn't have to interact.

3. **Warn about reboot** if the script output says registry was modified via HKCU (no admin). HKLM changes take effect immediately for new processes.

4. **Tell user to retry** the operation that failed.

## Script modes

| Mode | When |
|------|------|
| `-Mode Status` | User asks "is long paths enabled?" — diagnostic only |
| `-Mode Enable` | Default fix — apply all settings |
| `-Mode Fix` | "Fix" means enable + verify — when user wants confirmation |

## Interpreting output

| Indicator | Meaning |
|-----------|---------|
| `[OK]` | Setting correct, no action needed |
| `[FAIL]` | Needs fixing, script will handle |
| `[SKIP]` | Declined at prompt (only happens without `-Force`) |
| `[INFO]` | Informational |

## Explicit overrides (rarely needed)

Only offer these when the user explicitly asks for a specific scope or registry target:

- `-Scope Local` — only this repo's git config
- `-Scope Global` — only global git config
- `-Scope All` — both local and global
- `-Registry HKCU` — user hive, no admin needed
- `-Registry HKLM` — system-wide, needs admin

## When the script isn't enough

If the script reports everything `[OK]` but the issue persists, read `references/long-paths-guide.md` for manual verification commands and edge cases.
