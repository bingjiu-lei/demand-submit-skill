param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot
)

$ErrorActionPreference = "Continue"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Remove-PathIfExists {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        Remove-Item -LiteralPath $Path -Recurse -Force
        Write-Host "Removed: $Path"
    }
}

Write-Host "git-demand-skills uninstaller"
Write-Host ""
Write-Host "The following items will be removed:"
Write-Host "  1. Installed demand-submit skill"
Write-Host "  2. Installed demand-merge skill"
Write-Host "  3. Current git-demand-skills project directory"
Write-Host "  4. Generated logs and legacy safety records"
Write-Host ""

Start-Sleep -Seconds 2

$RepoRoot = $RepoRoot.Trim().Trim('"')
$resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path.TrimEnd("\")
$codexHome = Join-Path $env:USERPROFILE ".codex"

$paths = @(
    (Join-Path $codexHome "skills\demand-submit"),
    (Join-Path $codexHome "skills\demand-merge"),
    (Join-Path $codexHome "skills\demand-git"),
    (Join-Path $resolvedRepoRoot "demand-skill-logs"),
    (Join-Path $resolvedRepoRoot "demand-submit-logs"),
    (Join-Path $codexHome "demand-submit-backups"),
    (Join-Path $codexHome "demand-git-backups")
)

foreach ($path in $paths) {
    try {
        Remove-PathIfExists -Path $path
    } catch {
        Write-Host "Failed to remove: $path"
        Write-Host "Reason: $($_.Exception.Message)"
    }
}

Write-Host "Removing project directory: $resolvedRepoRoot"
try {
    Remove-Item -LiteralPath $resolvedRepoRoot -Recurse -Force -ErrorAction Stop
    Write-Host "Uninstall finished."
} catch {
    Write-Host "Project directory removal failed: $($_.Exception.Message)"
    Write-Host "Close editors, terminals, or Explorer windows opened inside the project directory, then run uninstall again."
}

Remove-Item -LiteralPath $PSCommandPath -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 3
