param(
    [string]$CodexHome = (Join-Path $env:USERPROFILE ".codex")
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillSource = Join-Path $repoRoot "skill\demand-submit"
$scriptPath = Join-Path $repoRoot "scripts\demand-submit.ps1"
$skillTarget = Join-Path $CodexHome "skills\demand-submit"
$oldSkillTarget = Join-Path $CodexHome "skills\demand-git"
$uninstallScript = Join-Path $repoRoot "uninstall.ps1"
$uninstallBatSource = Join-Path $repoRoot "demand-submit-uninstall.bat"

if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Cannot find demand-submit script: $scriptPath"
}
if (-not (Test-Path -LiteralPath $uninstallScript)) {
    throw "Cannot find demand-submit uninstall script: $uninstallScript"
}
if (-not (Test-Path -LiteralPath $uninstallBatSource)) {
    throw "Cannot find demand-submit uninstall entrypoint: $uninstallBatSource"
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $skillTarget) | Out-Null

if (Test-Path -LiteralPath $skillTarget) {
    Remove-Item -LiteralPath $skillTarget -Recurse -Force
}
if (Test-Path -LiteralPath $oldSkillTarget) {
    Remove-Item -LiteralPath $oldSkillTarget -Recurse -Force
}

Copy-Item -LiteralPath $skillSource -Destination $skillTarget -Recurse -Force

$installedSkill = Join-Path $skillTarget "SKILL.md"
$content = Get-Content -Raw -LiteralPath $installedSkill
$content = $content.Replace("{{DEMAND_SUBMIT_SCRIPT_PATH}}", $scriptPath)
Set-Content -LiteralPath $installedSkill -Value $content -Encoding UTF8

$installedUninstaller = Join-Path $skillTarget "demand-submit-uninstall.bat"
$uninstallBat = Get-Content -Raw -LiteralPath $uninstallBatSource
$uninstallBat = $uninstallBat.Replace('%~dp0uninstall.ps1', $uninstallScript)
Set-Content -LiteralPath $installedUninstaller -Value $uninstallBat -Encoding UTF8

Write-Host "Installed demand-submit skill to: $skillTarget"
Write-Host "Installed uninstaller to:"
Write-Host "  $installedUninstaller"
Write-Host "Codex does not need to be installed; this only writes files under:"
Write-Host "  $CodexHome\skills"
Write-Host "Any AI tool that scans .codex\skills can load it."
Write-Host "Configured script path:"
Write-Host "  $scriptPath"
Write-Host "Ask an AI agent:"
Write-Host '  Use demand-submit for demand 197462 with title "demand title".'
