param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$DemandId,

    [Parameter(Position = 1)]
    [Alias("Message")]
    [string]$Title = "",

    [string]$SourceBranch = "master",
    [string]$TargetBranch = "release-1.11",
    [string]$Remote = "origin",
    [string]$BranchName = "",
    [string]$After = "",
    [string]$Before = "",
    [int]$MaxMatches = 8,
    [switch]$NoPush
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

function Normalize-ReleaseBranch {
    param([string]$Branch)
    $value = $Branch.Trim()
    if ($value -match '^\d+$') {
        return "release-1.$value"
    }
    return $value
}

function Get-BranchSuffix {
    param([string]$Branch)
    if ($Branch -match '^release-1\.(\d+)$') {
        return $Matches[1]
    }
    return ($Branch -replace '^origin/', '' -replace '[\\/:*?""<>|]', '-')
}

function Rename-LocalBranchIfExists {
    param(
        [string]$Branch,
        [string]$Stamp
    )
    $localRef = "refs/heads/$Branch"
    if (-not (Has-Ref $localRef)) {
        return
    }

    $currentBranch = (Git-Output @("branch", "--show-current") | Select-Object -First 1)
    $backupBranch = "$Branch-backup-$Stamp"
    Write-Host "Local target branch already exists. Renaming it to: $backupBranch"
    if ($currentBranch -eq $Branch) {
        Run-Git @("branch", "-m", $backupBranch)
    } else {
        Run-Git @("branch", "-m", $Branch, $backupBranch)
    }
}

function Get-MatchingCommits {
    param(
        [string]$Demand,
        [string]$SourceRef,
        [string]$TargetRef,
        [string]$AfterValue,
        [string]$BeforeValue
    )

    $args = @(
        "log",
        "--reverse",
        "--no-merges",
        "--fixed-strings",
        "--grep=[$Demand]",
        "--format=%H%x09%ci%x09%s"
    )
    if (-not [string]::IsNullOrWhiteSpace($AfterValue)) {
        $args += "--after=$AfterValue"
    }
    if (-not [string]::IsNullOrWhiteSpace($BeforeValue)) {
        $args += "--before=$BeforeValue"
    }
    $args += "$TargetRef..$SourceRef"

    return @(Git-Output $args | Where-Object {
        if ([string]::IsNullOrWhiteSpace($_)) {
            return $false
        }
        $subject = ($_ -split "`t", 3)[2]
        return $subject.Trim().StartsWith("[$Demand]")
    })
}

function Get-TargetDemandCommits {
    param(
        [string]$Demand,
        [string]$TargetRef
    )

    return @(Git-Output @(
        "log",
        "--reverse",
        "--no-merges",
        "--fixed-strings",
        "--grep=[$Demand]",
        "--format=%H%x09%ci%x09%s",
        $TargetRef
    ) | Where-Object {
        if ([string]::IsNullOrWhiteSpace($_)) {
            return $false
        }
        $subject = ($_ -split "`t", 3)[2]
        return $subject.Trim().StartsWith("[$Demand]")
    })
}

function Infer-Title {
    param(
        [string]$Demand,
        [string]$ProvidedTitle,
        [string[]]$CommitLines
    )

    if (-not [string]::IsNullOrWhiteSpace($ProvidedTitle)) {
        $clean = $ProvidedTitle.Trim()
        if ($clean.StartsWith("[$Demand]")) {
            return $clean.Substring(("[$Demand]").Length).Trim()
        }
        return $clean
    }

    $firstSubject = (($CommitLines[0] -split "`t", 3)[2]).Trim()
    return ($firstSubject -replace "^\[$([regex]::Escape($Demand))\]\s*", "").Trim()
}

$repoRoot = (Git-Output @("rev-parse", "--show-toplevel") | Select-Object -First 1)
Set-Location -LiteralPath $repoRoot

$cleanDemandId = $DemandId.Trim().TrimStart("[").TrimEnd("]")
$source = $SourceBranch.Trim()
$target = Normalize-ReleaseBranch $TargetBranch
$targetRef = "$Remote/$target"
$sourceRef = "$Remote/$source"
$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$branchSuffix = Get-BranchSuffix $target
$mergeBranch = if ([string]::IsNullOrWhiteSpace($BranchName)) {
    "$cleanDemandId-$branchSuffix"
} else {
    $BranchName.Trim()
}

$toolRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$logRoot = Join-Path $toolRoot "demand-skill-logs"
$logDir = Join-Path $logRoot "$stamp-demand-merge-$($mergeBranch -replace '[\\/:*?""<>|]', '_')"
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

try {
    Write-Section "Repository"
    Write-Host "Root: $repoRoot"
    Write-Host "Source: $sourceRef"
    Write-Host "Target: $targetRef"
    Write-Host "Merge branch: $mergeBranch"
    Write-Host "Demand id: $cleanDemandId"
    Write-Host "After: $After"
    Write-Host "Before: $Before"
    Write-Host "NoPush: $NoPush"
    Write-Host "Log: $logDir"

    $unmergedBefore = @(Git-Output @("diff", "--name-only", "--diff-filter=U"))
    if ($unmergedBefore.Count -gt 0) {
        throw "Repository already has unresolved conflicts. Resolve them before running demand-merge."
    }

    $statusBefore = @(Git-Output @("status", "--porcelain"))
    if ($statusBefore.Count -gt 0) {
        Git-Output @("status", "--short") | Set-Content -LiteralPath (Join-Path $logDir "dirty-status.txt") -Encoding UTF8
        throw "Working tree is not clean. Commit, stash, or discard local changes before running demand-merge."
    }

    Write-Section "Fetch"
    Run-Git @("fetch", $Remote, "--prune")

    Run-Git @("rev-parse", "--verify", $sourceRef)
    Run-Git @("rev-parse", "--verify", $targetRef)

    Write-Section "Check Target"
    $targetDemandCommits = Get-TargetDemandCommits -Demand $cleanDemandId -TargetRef $targetRef
    if ($targetDemandCommits.Count -gt 0) {
        $targetDemandCommits | Set-Content -LiteralPath (Join-Path $logDir "target-already-has-demand.txt") -Encoding UTF8
        Write-Host "$targetRef already contains commit message with [$cleanDemandId]:"
        $targetDemandCommits | ForEach-Object { Write-Host "  $_" }
        Write-Host "Skip creating and pushing merge branch."
        exit 0
    }

    Write-Section "Find Commits"
    $commitLines = Get-MatchingCommits -Demand $cleanDemandId -SourceRef $sourceRef -TargetRef $targetRef -AfterValue $After -BeforeValue $Before
    if ($commitLines.Count -eq 0) {
        throw "No commits found on $sourceRef with message containing [$cleanDemandId]. Add -After/-Before or pass the correct demand id."
    }
    if ($commitLines.Count -gt $MaxMatches) {
        $commitLines | Set-Content -LiteralPath (Join-Path $logDir "matched-commits-too-many.txt") -Encoding UTF8
        throw "Found $($commitLines.Count) matching commits, which is more than MaxMatches=$MaxMatches. Add -After/-Before to narrow the range."
    }

    $commitHashes = @()
    foreach ($line in $commitLines) {
        $parts = $line -split "`t", 3
        $commitHashes += $parts[0]
        Write-Host "  $($parts[0])  $($parts[1])  $($parts[2])"
    }
    $commitLines | Set-Content -LiteralPath (Join-Path $logDir "matched-commits.txt") -Encoding UTF8
    foreach ($hash in $commitHashes) {
        Git-Output @("show", "--stat", "--oneline", "--decorate=short", $hash) | Set-Content -LiteralPath (Join-Path $logDir "commit-$hash-stat.txt") -Encoding UTF8
        Git-Output @("show", "--patch", "--find-renames", "--find-copies", $hash) | Set-Content -LiteralPath (Join-Path $logDir "commit-$hash.patch") -Encoding UTF8
    }

    $finalTitle = Infer-Title -Demand $cleanDemandId -ProvidedTitle $Title -CommitLines $commitLines
    if ([string]::IsNullOrWhiteSpace($finalTitle)) {
        throw "Cannot infer commit title. Pass a title explicitly."
    }
    $commitMessage = "[$cleanDemandId] $finalTitle"
    $commitMessage | Set-Content -LiteralPath (Join-Path $logDir "commit-message.txt") -Encoding UTF8

    Write-Section "Checkout Merge Branch"
    Rename-LocalBranchIfExists -Branch $mergeBranch -Stamp $stamp
    Run-Git @("checkout", "-B", $mergeBranch, $targetRef)

    Write-Section "Cherry Pick"
    foreach ($hash in $commitHashes) {
        Write-Host "Applying: $hash"
        $hash | Set-Content -LiteralPath (Join-Path $logDir "current-cherry-pick-commit.txt") -Encoding UTF8
        & git -c core.quotepath=false cherry-pick --no-commit $hash
        if ($LASTEXITCODE -ne 0) {
            Write-Host ""
            Write-Host "Cherry-pick stopped with conflicts."
            $conflicts = @(Git-Output @("diff", "--name-only", "--diff-filter=U"))
            $conflicts | Set-Content -LiteralPath (Join-Path $logDir "conflict-files.txt") -Encoding UTF8
            Git-Output @("status", "--short") | Set-Content -LiteralPath (Join-Path $logDir "conflict-status.txt") -Encoding UTF8
            Write-Host "Conflicted files:"
            $conflicts | ForEach-Object { Write-Host "  $_" }
            Write-Host ""
            Write-Host "Log directory: $logDir"
            Write-Host "Ask AI to inspect conflicts, then run:"
            Write-Host "  Use commit-$hash.patch to check patch facts for each incoming conflict line."
            Write-Host "  Keep an incoming line only when it is a '+' added line in that patch."
            Write-Host "  Drop context lines that are not '+' additions, even if they appear on the incoming side."
            Write-Host "  git add -- <resolved-files>"
            Write-Host "  git commit -m `"$commitMessage`""
            if (-not $NoPush) {
                Write-Host "  git push -u $Remote $mergeBranch"
            }
            exit 2
        }
    }

    $staged = @(Git-Output @("diff", "--cached", "--name-only"))
    if ($staged.Count -eq 0) {
        Write-Host "Cherry-pick produced no changes. Nothing to commit."
        exit 0
    }

    Write-Section "Commit"
    Run-Git @("commit", "-m", $commitMessage)

    if (-not $NoPush) {
        Write-Section "Push"
        Run-Git @("push", "-u", $Remote, $mergeBranch)
    } else {
        Write-Host "NoPush was set; skipping push."
    }

    Write-Section "Done"
    Run-Git @("status", "--short", "--branch")
    Write-Host "Demand merge branch is ready: $mergeBranch"
} catch {
    Write-Host ""
    Write-Host "demand-merge stopped: $($_.Exception.Message)"
    Write-Host "Log directory: $logDir"
    exit 1
}
