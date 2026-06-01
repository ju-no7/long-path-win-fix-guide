# Long Paths Support for Git and Windows — Reference Guide

This reference document contains the full manual steps for enabling long path support. **In most cases, use the `Enable-LongPaths.ps1` script instead** — it automates everything below.

## Scenario 1: Repository Not Yet Cloned

> You plan to clone a repo but haven't done so yet.

### Step 1: Configure Git (global)

```bash
git config --global core.longpaths true
```

### Step 2: Configure Windows Registry

**Without admin rights:**
```powershell
New-Item -Path 'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem' -Force | Out-Null
New-ItemProperty -Path 'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force
```

**With admin rights:**
```powershell
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force
```

> ⚠️ Requires logoff or restart.

### Step 3: Clone the repository

```bash
git clone <url>
```

## Scenario 2: Repository Already Cloned

> You have a local repo but encounter long path issues.

### Step 1: Configure Git (local to this repo)

```bash
git config core.longpaths true
```

or explicitly:

```bash
git config --local core.longpaths true
```

### Step 2: Verify settings

```bash
# Show local setting
git config --get core.longpaths

# Show global setting
git config --global --get core.longpaths
```

### Step 3: Configure Windows Registry (if issues persist)

**Without admin rights:**
```powershell
New-Item -Path 'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem' -Force | Out-Null
New-ItemProperty -Path 'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force
```

**With admin rights:**
```powershell
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force
```

> ⚠️ Requires logoff or restart.

## Verification Commands

```bash
# Git — local repo setting
git config --get core.longpaths

# Git — global setting
git config --global --get core.longpaths

# Windows Registry (HKLM — system-wide)
reg query "HKLM\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled

# Windows Registry (HKCU — current user)
reg query "HKCU\SYSTEM\CurrentControlSet\Control\FileSystem" /v LongPathsEnabled
```

## Quick Commands

### Everything at once (no admin) — for a new repo

```powershell
git config --global core.longpaths true
New-Item -Path 'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem' -Force | Out-Null
New-ItemProperty -Path 'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force
```

### Everything at once (with admin) — for a new repo

```powershell
git config --global core.longpaths true
New-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' -Name 'LongPathsEnabled' -Value 1 -PropertyType DWORD -Force
```

## Important Notes

- **HKCU** (HKEY_CURRENT_USER): Applies to current user only, no admin required, takes effect after logoff/restart
- **HKLM** (HKEY_LOCAL_MACHINE): Applies system-wide, requires admin rights, takes effect immediately for new processes
- **Git global**: Applies to all repos for the current user
- **Git local**: Applies only to the current repo, stored in `.git/config`
- The PowerShell script handles all these distinctions automatically
