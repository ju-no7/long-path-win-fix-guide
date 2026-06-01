# long-paths-windows Skill

**Your one-stop solution for Windows long path problems.**

This skill eliminates the dreaded "filename too long" errors on Windows, whether you're cloning a repo, installing npm packages, or building projects with deep directory structures. It combines a ready-to-use PowerShell utility with comprehensive guidance to deliver:

- **Auto-detection** — knows if you're in a git repo and whether you have admin rights
- **Unified fix** — configures both Git (`core.longpaths`) and Windows Registry (`LongPathsEnabled`) in one command
- **Smart fallback** — HKCU when you don't have admin, HKLM when you do
- **Status checking** — see exactly what's configured and what's missing
- **Verification** — confirm everything is working after applying fixes

Long path issues become a one-command solve instead of a half-hour of searching forums.

## How to Use It

Simply tell the agent about your long path problem:

- "I'm getting 'filename too long' when cloning a git repo on Windows"
- "npm install fails because paths are too long in node_modules"
- "Check if long paths are enabled on my machine"
- "Git checkout fails on deep directory trees"

The skill will automatically activate, guide you to run the PowerShell utility, and explain the results.

The skill will instruct the agent to:

1. Check current status with `Enable-LongPaths.ps1 -Mode Status`
2. Apply fixes with `Enable-LongPaths.ps1 -Mode Enable`
3. Verify with `Enable-LongPaths.ps1 -Mode Fix`
4. Explain reboot requirements if registry was modified
5. Reference the detailed guide for manual troubleshooting if needed

## Installation

### Manual (clone and copy)

1. Clone this repository:

```bash
git clone https://github.com/your-username/long-paths-windows-skill.git
cd long-paths-windows-skill
```

2. Copy the skill folder into your agent's skills directory:

```bash
rm -rf ~/.agents/skills/long-paths-windows
cp -r skills/long-paths-windows ~/.agents/skills/long-paths-windows
```

```powershell
Remove-Item -Recurse -Force ~/.agents/skills/long-paths-windows -ErrorAction SilentlyContinue
Copy-Item -Recurse skills\long-paths-windows ~/.agents\skills\long-paths-windows
```

Restart the agent or reload skills for the new skill discovery.

## What's Included

```
skills/long-paths-windows/
├── SKILL.md                        # Skill instructions
├── scripts/
│   └── Enable-LongPaths.ps1        # Ready-to-use PowerShell utility
├── references/
│   └── long-paths-guide.md         # Full reference guide
```

The PowerShell script supports three modes:
- **Status** — check current configuration
- **Enable** — apply all settings with smart auto-detection
- **Fix** — enable + verify
