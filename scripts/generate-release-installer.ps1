param(
    [Parameter(Mandatory = $true)]
    [string]$Version,
    [string]$OutputDir = ""
)

$ErrorActionPreference = "Stop"

if ($Version -notmatch '^v\d+\.\d+\.\d+$') {
    throw "Version must look like v0.1.2"
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $repoRoot "release-installers"
}

New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null

$fileName = "git-demand-skills-install-$Version.bat"
$target = Join-Path $OutputDir $fileName

$content = @"
@echo off
setlocal

set "GIT_DEMAND_SKILLS_REF=$Version"
set "GITEE_BOOTSTRAP=https://gitee.com/bingjiu-lei/git-demand-skills/raw/%GIT_DEMAND_SKILLS_REF%/bootstrap.ps1"
set "GITHUB_BOOTSTRAP=https://raw.githubusercontent.com/bingjiu-lei/git-demand-skills/%GIT_DEMAND_SKILLS_REF%/bootstrap.ps1"
set "LEGACY_GITEE_BOOTSTRAP=https://gitee.com/bingjiu-lei/demand-submit-skill/raw/%GIT_DEMAND_SKILLS_REF%/bootstrap.ps1"
set "LEGACY_GITHUB_BOOTSTRAP=https://raw.githubusercontent.com/bingjiu-lei/demand-submit-skill/%GIT_DEMAND_SKILLS_REF%/bootstrap.ps1"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "`$ErrorActionPreference='Stop';" ^
  "`$bootstrap = Join-Path `$env:TEMP 'git-demand-skills-bootstrap.ps1';" ^
  "`$urls = @('%GITEE_BOOTSTRAP%', '%GITHUB_BOOTSTRAP%', '%LEGACY_GITEE_BOOTSTRAP%', '%LEGACY_GITHUB_BOOTSTRAP%');" ^
  "`$ok = `$false; foreach (`$url in `$urls) { try { Write-Host ('Downloading bootstrap: ' + `$url); Invoke-WebRequest `$url -OutFile `$bootstrap; `$ok = `$true; break } catch { Write-Host ('Bootstrap failed: ' + `$url) } }; if (-not `$ok) { throw 'Cannot download bootstrap.ps1 from Gitee or GitHub.' };" ^
  "& powershell -NoProfile -ExecutionPolicy Bypass -File `$bootstrap -Ref '%GIT_DEMAND_SKILLS_REF%'"

if errorlevel 1 (
  echo.
  echo Installation failed.
  pause
  exit /b 1
)

echo.
echo Installation finished.
pause
"@

$content = $content -replace "`r?`n", "`r`n"
[System.IO.File]::WriteAllText($target, $content, [System.Text.UTF8Encoding]::new($false))

Write-Host "Generated release installer:"
Write-Host "  $target"
