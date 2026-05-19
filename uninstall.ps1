param(
    [string]$CodexHome = (Join-Path $env:USERPROFILE ".codex"),
    [switch]$RemoveBackups,
    [switch]$RemoveProject
)

$ErrorActionPreference = "Stop"

$skillTarget = Join-Path $CodexHome "skills\demand-submit"
$oldSkillTarget = Join-Path $CodexHome "skills\demand-git"
$backupTarget = Join-Path $CodexHome "demand-submit-backups"
$oldBackupTarget = Join-Path $CodexHome "demand-git-backups"
$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

$removed = New-Object System.Collections.Generic.List[string]

foreach ($path in @($skillTarget, $oldSkillTarget)) {
    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Recurse -Force
        $removed.Add($path) | Out-Null
    }
}

if ($RemoveBackups) {
    foreach ($path in @($backupTarget, $oldBackupTarget)) {
        if (Test-Path -LiteralPath $path) {
            Remove-Item -LiteralPath $path -Recurse -Force
            $removed.Add($path) | Out-Null
        }
    }
}

if ($removed.Count -eq 0) {
    Write-Host "No demand-submit skill files found under: $CodexHome"
} else {
    Write-Host "Removed:"
    $removed | ForEach-Object { Write-Host "  $_" }
}

Write-Host ""
if ($RemoveProject) {
    Write-Host "Scheduling cloned project directory removal:"
    Write-Host "  $repoRoot"
    Write-Host "Close any editor or terminal opened inside this directory if removal does not complete."

    $deleteScript = @"
Start-Sleep -Seconds 2
Remove-Item -LiteralPath '$($repoRoot.Replace("'", "''"))' -Recurse -Force
"@
    Start-Process -FilePath "powershell" -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy",
        "Bypass",
        "-Command",
        $deleteScript
    ) -WindowStyle Hidden | Out-Null
} else {
    Write-Host "The cloned project directory was not removed."
}

Write-Host "To remove script-generated safety records too, rerun with: -RemoveBackups"
Write-Host "To remove the cloned project directory too, rerun with: -RemoveProject"
