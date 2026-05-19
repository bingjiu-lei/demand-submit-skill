param(
    [string]$CodexHome = (Join-Path $env:USERPROFILE ".codex")
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillSource = Join-Path $repoRoot "skill\demand-submit"
$scriptPath = Join-Path $repoRoot "scripts\demand-submit.ps1"
$skillTarget = Join-Path $CodexHome "skills\demand-submit"
$oldSkillTarget = Join-Path $CodexHome "skills\demand-git"

if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Cannot find demand-submit script: $scriptPath"
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

Write-Host "Installed demand-submit skill to: $skillTarget"
Write-Host "Codex does not need to be installed; this only writes files under:"
Write-Host "  $CodexHome\skills"
Write-Host "Any AI tool that scans .codex\skills can load it."
Write-Host "Configured script path:"
Write-Host "  $scriptPath"
Write-Host "Ask an AI agent:"
Write-Host '  Use demand-submit for demand 197462 with title "demand title".'
