param(
    [Parameter(Mandatory = $true)]
    [string]$RepoRoot
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$resolvedRepoRoot = (Resolve-Path -LiteralPath $RepoRoot).Path.TrimEnd("\")
$paths = @(
    (Join-Path $resolvedRepoRoot "demand-skill-logs"),
    (Join-Path $resolvedRepoRoot "demand-submit-logs")
)

Write-Host "git-demand-skills log cleaner"
Write-Host ""
Write-Host "The following generated log directories will be removed:"
foreach ($path in $paths) {
    Write-Host "  $path"
}
Write-Host ""

foreach ($path in $paths) {
    if (Test-Path -LiteralPath $path) {
        Remove-Item -LiteralPath $path -Recurse -Force
        Write-Host "Removed: $path"
    }
}

Write-Host "Log cleanup finished."
