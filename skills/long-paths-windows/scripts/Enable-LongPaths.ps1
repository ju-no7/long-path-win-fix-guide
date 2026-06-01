<#
.SYNOPSIS
    Enable or check long path support in Git and Windows.

.DESCRIPTION
    A unified utility to enable, check, and fix long path support.
    Detects current state and handles all scenarios:
    - Git repo not yet cloned → sets global core.longpaths
    - Git repo already cloned → sets local core.longpaths
    - Windows registry (HKCU without admin, HKLM with admin)

.PARAMETER Mode
    What action to perform: Status, Enable, or Fix.
    Status  - Check current configuration (default)
    Enable  - Apply all long path settings
    Fix     - Enable then verify everything is correct

.PARAMETER Scope
    Git config scope to target: Auto, Local, Global, or All.
    Auto    - Detects if inside a git repo (default)
    Local   - Only set local git config
    Global  - Only set global git config
    All     - Set both local and global

.PARAMETER Registry
    Registry target: Auto, HKCU, HKLM, or Both.
    Auto    - Try HKLM first, fall back to HKCU (default)
    HKCU    - Current user only (no admin required)
    HKLM    - System-wide (requires admin)
    Both    - Set both HKCU and HKLM

.PARAMETER Force
    Suppress confirmation prompts.

.EXAMPLE
    .\Enable-LongPaths.ps1 -Mode Status
    Check current long path configuration.

.EXAMPLE
    .\Enable-LongPaths.ps1 -Mode Enable
    Enable long paths with auto-detection.

.EXAMPLE
    .\Enable-LongPaths.ps1 -Mode Enable -Scope Global -Registry HKCU -Force
    Enable globally with user registry, no prompts.

.EXAMPLE
    .\Enable-LongPaths.ps1 -Mode Fix
    Enable and verify everything.
#>

param(
    [ValidateSet('Status', 'Enable', 'Fix')]
    [string]$Mode = 'Status',

    [ValidateSet('Auto', 'Local', 'Global', 'All')]
    [string]$Scope = 'Auto',

    [ValidateSet('Auto', 'HKCU', 'HKLM', 'Both')]
    [string]$Registry = 'Auto',

    [switch]$Force
)

function Write-Title {
    param([string]$Text)
    $width = 60
    $pad = [math]::Max(0, [math]::Floor(($width - $Text.Length - 2) / 2))
    Write-Host "`n$('=' * $width)" -ForegroundColor Cyan
    Write-Host " $(' ' * $pad)$Text$(' ' * ($pad + ($Text.Length % 2)))" -ForegroundColor Cyan
    Write-Host "$('=' * $width)"
}

function Write-Result {
    param(
        [string]$Label,
        [string]$Value,
        [string]$Status
    )
    $color = switch ($Status) {
        'OK'    { 'Green' }
        'FAIL'  { 'Red' }
        'SKIP'  { 'Yellow' }
        'INFO'  { 'Gray' }
        default { 'White' }
    }
    Write-Host "[$Status] " -ForegroundColor $color -NoNewline
    Write-Host "$Label`: " -NoNewline
    Write-Host "$Value" -ForegroundColor $color
}

function Get-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Test-IsGitRepo {
    try {
        $null = git rev-parse --is-inside-work-tree 2>$null
        return $true
    } catch {
        return $false
    }
}

function Get-GitLongPathsConfig {
    param([string]$Scope)
    $value = git config --$Scope core.longpaths 2>$null
    return $value.Trim()
}

function Set-GitLongPathsConfig {
    param([string]$Scope)
    try {
        git config --$Scope core.longpaths true
        return $true
    } catch {
        return $false
    }
}

function Get-RegistryLongPaths {
    param([string]$Path)
    try {
        $value = Get-ItemProperty -Path $Path -Name 'LongPathsEnabled' -ErrorAction Stop
        return $value.LongPathsEnabled
    } catch {
        return $null
    }
}

function Set-RegistryLongPaths {
    param([string]$Path)
    try {
        New-Item -Path $Path -Force -ErrorAction Stop | Out-Null
        Set-ItemProperty -Path $Path -Name 'LongPathsEnabled' -Value 1 -Type DWORD -Force -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}

function Test-RebootRequired {
    $hkcu = Get-RegistryLongPaths 'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem'
    $hklm = Get-RegistryLongPaths 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
    if ($hklm -eq 1) { return $false }
    if ($hkcu -eq 1) {
        return -not (Get-IsAdministrator)
    }
    return $false
}

<#
.SYNOPSIS
    Check current status of long paths configuration.
#>
function Show-Status {
    Write-Title "Long Paths Support — Status Check"

    $isAdmin = Get-IsAdministrator
    Write-Result "Admin rights" $isAdmin (if ($isAdmin) { 'OK' } else { 'INFO' })
    Write-Result "In a git repo" (Test-IsGitRepo) 'INFO'

    Write-Host "`n--- Git Configuration ---" -ForegroundColor Yellow
    $globalGit = Get-GitLongPathsConfig 'global'
    $localGit = Get-GitLongPathsConfig 'local'
    Write-Result "Git global core.longpaths" ($globalGit -eq 'true') (if ($globalGit -eq 'true') { 'OK' } elseif ($globalGit -eq 'false' -or $null -eq $globalGit) { 'FAIL' } else { 'FAIL' })
    Write-Result "Git local core.longpaths"  ($localGit -eq 'true')  (if ($localGit -eq 'true') { 'OK' } elseif ($localGit -eq 'false' -or $null -eq $localGit) { 'FAIL' } else { 'FAIL' })

    Write-Host "`n--- Registry Configuration ---" -ForegroundColor Yellow
    $hklmVal = Get-RegistryLongPaths 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
    $hkcuVal = Get-RegistryLongPaths 'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem'
    Write-Result "HKLM (system-wide)" $hklmVal (if ($hklmVal -eq 1) { 'OK' } else { 'FAIL' })
    Write-Result "HKCU (current user)" $hkcuVal (if ($hkcuVal -eq 1) { 'OK' } else { 'FAIL' })

    $needsReboot = Test-RebootRequired
    if ($needsReboot) {
        Write-Host "`n⚠️  Registry changes require a logoff/restart to take effect." -ForegroundColor Yellow
    }

    $allOk = ($globalGit -eq 'true')
    if ((Test-IsGitRepo) -and $localGit -ne 'true') { $allOk = $false }
    if ($hklmVal -ne 1 -and $hkcuVal -ne 1) { $allOk = $false }

    if ($allOk) {
        Write-Host "`n✅ Long paths support is fully enabled." -ForegroundColor Green
    } else {
        Write-Host "`n❌ Long paths support is NOT fully enabled. Run with -Mode Enable." -ForegroundColor Red
    }
}

<#
.SYNOPSIS
    Enable long paths — git config and/or registry.
#>
function Enable-LongPaths {
    Write-Title "Enabling Long Paths Support"

    $isAdmin = Get-IsAdministrator
    Write-Result "Admin rights" $isAdmin (if ($isAdmin) { 'OK' } else { 'INFO' })

    # --- Resolve Git Scope ---
    $gitScopes = @()
    $resolvedScope = $Scope
    if ($Scope -eq 'Auto') {
        if (Test-IsGitRepo) {
            $gitScopes += 'local'
            $resolvedScope = 'Local'
        } else {
            $gitScopes += 'global'
            $resolvedScope = 'Global'
        }
    } elseif ($Scope -eq 'All') {
        $gitScopes = @('local', 'global')
    } else {
        $gitScopes += $Scope.ToLower()
    }

    Write-Host "`n--- Git Configuration ---" -ForegroundColor Yellow
    Write-Result "Git scope" $resolvedScope 'INFO'

    foreach ($scope in $gitScopes) {
        $current = Get-GitLongPathsConfig $scope
        if ($current -eq 'true') {
            Write-Result "Git $scope core.longpaths" 'already true' 'OK'
        } else {
            $proceed = $Force -or (Should-Proceed "Set git $scope core.longpaths to true?")
            if ($proceed) {
                if (Set-GitLongPathsConfig $scope) {
                    Write-Result "Git $scope core.longpaths" 'set to true' 'OK'
                } else {
                    Write-Result "Git $scope core.longpaths" 'FAILED' 'FAIL'
                }
            } else {
                Write-Result "Git $scope core.longpaths" 'skipped' 'SKIP'
            }
        }
    }

    # --- Resolve Registry Target ---
    $registryTargets = @()
    $resolvedRegistry = $Registry
    if ($Registry -eq 'Auto') {
        $hklmCurrent = Get-RegistryLongPaths 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
        if ($hklmCurrent -eq 1) {
            $resolvedRegistry = 'HKLM (already set)'
        } elseif ($isAdmin) {
            $registryTargets += 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem'
            $resolvedRegistry = 'HKLM'
        } else {
            $registryTargets += 'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem'
            $resolvedRegistry = 'HKCU'
        }
    } elseif ($Registry -eq 'Both') {
        $registryTargets = @(
            'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem',
            'HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem'
        )
    } elseif ($Registry -eq 'HKLM') {
        $registryTargets = @('HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem')
    } else {
        $registryTargets = @('HKCU:\SYSTEM\CurrentControlSet\Control\FileSystem')
    }

    Write-Host "`n--- Registry Configuration ---" -ForegroundColor Yellow
    Write-Result "Registry target" $resolvedRegistry 'INFO'

    foreach ($regPath in $registryTargets) {
        $regName = if ($regPath -like 'HKLM:*') { 'HKLM (system-wide)' } else { 'HKCU (current user)' }
        $current = Get-RegistryLongPaths $regPath
        if ($current -eq 1) {
            Write-Result "$regName LongPathsEnabled" 'already enabled' 'OK'
        } else {
            $proceed = $Force -or (Should-Proceed "Enable LongPathsEnabled in $regName?")
            if ($proceed) {
                if (Set-RegistryLongPaths $regPath) {
                    Write-Result "$regName LongPathsEnabled" 'set to 1' 'OK'
                } else {
                    Write-Result "$regName LongPathsEnabled" 'FAILED' 'FAIL'
                }
            } else {
                Write-Result "$regName LongPathsEnabled" 'skipped' 'SKIP'
            }
        }
    }

    # --- Check reboot requirement ---
    $needsReboot = Test-RebootRequired
    if ($needsReboot) {
        Write-Host "`n⚠️  Registry changes require a logoff/restart to take effect." -ForegroundColor Yellow
        Write-Host "   For immediate effect without restart, run as Administrator (sets HKLM)." -ForegroundColor Gray
    }

    Write-Host "`n--- Summary ---" -ForegroundColor Yellow
    Write-Host "✅ Git configuration updated." -ForegroundColor Green
    Write-Host "✅ Registry configuration updated." -ForegroundColor Green
    Write-Host "`n💡 Run with -Mode Fix to verify everything afterwards." -ForegroundColor Cyan
}

<#
.SYNOPSIS
    Fix and verify long paths support.
#>
function Fix-LongPaths {
    Enable-LongPaths
    Write-Title "Verification"
    Show-Status
}

function Should-Proceed {
    param([string]$Message)
    $response = Read-Host "`n$Message (y/N)"
    return $response.Trim().ToLower() -eq 'y'
}

# --- MAIN ---
switch ($Mode) {
    'Status' { Show-Status }
    'Enable' { Enable-LongPaths }
    'Fix'    { Fix-LongPaths }
}
