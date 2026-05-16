param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$DemandId,

    [Parameter(Mandatory = $true, Position = 1)]
    [Alias("Title")]
    [string]$Message,

    [string]$BaseBranch = "master",
    [string]$Remote = "origin",
    [string]$BranchPrefix = "",
    [string]$BranchName = "",
    [switch]$NoPush,
    [switch]$AllowEmpty
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Run-Git {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$GitArgs
    )
    & git -c core.quotepath=false @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE"
    }
}

function Git-Output {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$GitArgs
    )
    $output = & git -c core.quotepath=false @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE"
    }
    return $output
}

function Has-Ref {
    param([string]$Ref)
    & git show-ref --verify --quiet $Ref
    return $LASTEXITCODE -eq 0
}

function Write-Section {
    param([string]$Text)
    Write-Host ""
    Write-Host "== $Text =="
}

$repoRoot = (Git-Output @("rev-parse", "--show-toplevel") | Select-Object -First 1)
Set-Location -LiteralPath $repoRoot

$targetBranch = if ([string]::IsNullOrWhiteSpace($BranchName)) {
    "$BranchPrefix$DemandId"
} else {
    $BranchName
}

$cleanDemandId = $DemandId.Trim()
$cleanDemandId = $cleanDemandId.TrimStart("[").TrimEnd("]")
$cleanTitle = $Message.Trim()
$commitMessage = if ($cleanTitle.StartsWith("[$cleanDemandId]")) {
    $cleanTitle
} else {
    "[$cleanDemandId] $cleanTitle"
}

Write-Section "Repository"
Write-Host "Root: $repoRoot"
Write-Host "Base: $Remote/$BaseBranch"
Write-Host "Target branch: $targetBranch"
Write-Host "Commit message: $commitMessage"

$existingUnmerged = @(Git-Output @("diff", "--name-only", "--diff-filter=U"))
if ($existingUnmerged.Count -gt 0) {
    throw "Repository already has unresolved conflicts. Resolve them before running demand-submit."
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupRoot = Join-Path $env:USERPROFILE ".codex\demand-submit-backups"
$backupDir = Join-Path $backupRoot "$stamp-$($targetBranch -replace '[\\/:*?""<>|]', '_')"
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

Write-Section "Backup"
Git-Output @("branch", "--show-current") | Set-Content -LiteralPath (Join-Path $backupDir "branch.txt") -Encoding UTF8
Git-Output @("status", "--short") | Set-Content -LiteralPath (Join-Path $backupDir "status.txt") -Encoding UTF8
Git-Output @("diff", "--binary") | Set-Content -LiteralPath (Join-Path $backupDir "working-tree.patch") -Encoding UTF8
Git-Output @("diff", "--cached", "--binary") | Set-Content -LiteralPath (Join-Path $backupDir "staged.patch") -Encoding UTF8
Write-Host "Backup written to: $backupDir"

$statusBefore = @(Git-Output @("status", "--porcelain"))
$createdStash = $false
$stashRef = ""
if ($statusBefore.Count -gt 0) {
    Write-Section "Stash Current Work"
    $stashMessage = "demand-submit:${targetBranch}:${stamp}"
    Run-Git @("stash", "push", "-u", "-m", $stashMessage)
    $createdStash = $true
    $stashRef = "stash@{0}"
} else {
    Write-Host "Working tree is clean."
}

try {
    Write-Section "Update Base"
    Run-Git @("fetch", $Remote, "--prune")
    Run-Git @("checkout", $BaseBranch)
    Run-Git @("pull", "--ff-only", $Remote, $BaseBranch)

    Write-Section "Checkout Target Branch"
    $localRef = "refs/heads/$targetBranch"
    $remoteRef = "refs/remotes/$Remote/$targetBranch"
    if (Has-Ref $localRef) {
        Run-Git @("checkout", $targetBranch)
    } elseif (Has-Ref $remoteRef) {
        Run-Git @("checkout", "-b", $targetBranch, "--track", "$Remote/$targetBranch")
    } else {
        Run-Git @("checkout", "-b", $targetBranch, "$Remote/$BaseBranch")
    }

    if ($createdStash) {
        Write-Section "Restore Work"
        & git -c core.quotepath=false stash pop $stashRef
        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "Conflict or restore failure occurred during stash pop."
            Write-Host "The repository has been left for manual/AI conflict resolution."
            Write-Host "After resolving, run:"
            Write-Host "  git add -A"
            Write-Host "  git commit -m `"$commitMessage`""
            Write-Host "  git push -u $Remote $targetBranch"
            exit 2
        }
    }

    $unmerged = @(Git-Output @("diff", "--name-only", "--diff-filter=U"))
    if ($unmerged.Count -gt 0) {
        Write-Host "Unresolved conflicts:"
        $unmerged | ForEach-Object { Write-Host "  $_" }
        exit 2
    }

    Write-Section "Commit"
    Run-Git @("add", "-A")
    $staged = @(Git-Output @("diff", "--cached", "--name-only"))
    if ($staged.Count -eq 0 -and -not $AllowEmpty) {
        Write-Host "No staged changes after moving to target branch. Nothing to commit."
        exit 0
    }

    if ($staged.Count -eq 0 -and $AllowEmpty) {
        Run-Git @("commit", "--allow-empty", "-m", $commitMessage)
    } else {
        Run-Git @("commit", "-m", $commitMessage)
    }

    if (-not $NoPush) {
        Write-Section "Push"
        Run-Git @("push", "-u", $Remote, $targetBranch)
    } else {
        Write-Host "NoPush was set; skipping push."
    }

    Write-Section "Done"
    Run-Git @("status", "--short")
    Write-Host "Demand branch is ready: $targetBranch"
} catch {
    Write-Host ""
    Write-Host "demand-submit stopped: $($_.Exception.Message)"
    if ($createdStash) {
        Write-Host "If your work was not restored, check: git stash list"
        Write-Host "Backup directory: $backupDir"
    }
    exit 1
}
