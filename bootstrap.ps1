param(
    [string]$InstallRoot = "",
    [string]$ProjectName = "git-demand-skills",
    [string]$Ref = "main"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$giteeRepo = "https://gitee.com/bingjiu-lei/git-demand-skills.git"
$githubRepo = "https://github.com/bingjiu-lei/git-demand-skills.git"
$legacyGiteeRepo = "https://gitee.com/bingjiu-lei/demand-submit-skill.git"
$legacyGithubRepo = "https://github.com/bingjiu-lei/demand-submit-skill.git"

function Show-Info {
    param([string]$Message, [string]$Title = "git-demand-skills installer")
    try {
        Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
        [System.Windows.Forms.MessageBox]::Show($Message, $Title, "OK", "Information") | Out-Null
    } catch {
        Write-Host $Message
    }
}

function Select-InstallRoot {
    Add-Type -AssemblyName System.Windows.Forms
    $dialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $dialog.Description = "请选择 git-demand-skills 保存到哪个目录"
    $dialog.ShowNewFolderButton = $true
    $dialog.SelectedPath = [Environment]::GetFolderPath("UserProfile")

    $result = $dialog.ShowDialog()
    if ($result -ne [System.Windows.Forms.DialogResult]::OK -or [string]::IsNullOrWhiteSpace($dialog.SelectedPath)) {
        throw "用户取消了安装目录选择。"
    }
    return $dialog.SelectedPath
}

function Assert-Git {
    & git --version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "未检测到 git。请先安装 Git for Windows，再重新运行安装器。"
    }
}

function Run-Git {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$GitArgs,
        [string]$WorkDir = ""
    )

    if ([string]::IsNullOrWhiteSpace($WorkDir)) {
        & git @GitArgs
    } else {
        & git -C $WorkDir @GitArgs
    }
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') failed with exit code $LASTEXITCODE"
    }
}

function Clone-Or-Update {
    param(
        [string]$RepoUrl,
        [string]$TargetPath,
        [string]$CheckoutRef = "main"
    )

    if (Test-Path -LiteralPath $TargetPath) {
        if (Test-Path -LiteralPath (Join-Path $TargetPath ".git")) {
            Write-Host "Project already exists, updating: $TargetPath"
            Run-Git @("fetch", "--all", "--prune") -WorkDir $TargetPath
            Run-Git @("fetch", "--tags", "--force") -WorkDir $TargetPath
            if ($CheckoutRef -eq "main") {
                Run-Git @("checkout", "main") -WorkDir $TargetPath
                Run-Git @("pull", "--ff-only") -WorkDir $TargetPath
            } else {
                Run-Git @("checkout", "--detach", $CheckoutRef) -WorkDir $TargetPath
            }
            return
        }
        throw "目标目录已存在但不是 Git 仓库：$TargetPath"
    }

    Run-Git @("clone", $RepoUrl, $TargetPath)
    if ($CheckoutRef -ne "main") {
        Run-Git @("fetch", "--tags", "--force") -WorkDir $TargetPath
        Run-Git @("checkout", "--detach", $CheckoutRef) -WorkDir $TargetPath
    }
}

function Move-LegacyProjectIfNeeded {
    param(
        [string]$InstallRoot,
        [string]$ProjectName
    )

    $targetPath = Join-Path $InstallRoot $ProjectName
    $legacyPath = Join-Path $InstallRoot "demand-submit-skill"

    if ((Test-Path -LiteralPath $targetPath) -or -not (Test-Path -LiteralPath $legacyPath)) {
        return $targetPath
    }

    if (-not (Test-Path -LiteralPath (Join-Path $legacyPath ".git"))) {
        return $targetPath
    }

    Write-Host "Found legacy project directory:"
    Write-Host "  $legacyPath"
    Write-Host "Renaming it to:"
    Write-Host "  $targetPath"
    Rename-Item -LiteralPath $legacyPath -NewName $ProjectName
    return $targetPath
}

function Install-Skill {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectPath,
        [string]$CodexHome = (Join-Path $env:USERPROFILE ".codex")
    )

    $submitSkillSource = Join-Path $ProjectPath "skill\demand-submit"
    $submitScriptPath = Join-Path $ProjectPath "scripts\demand-submit.ps1"
    $submitSkillTarget = Join-Path $CodexHome "skills\demand-submit"
    $mergeSkillSource = Join-Path $ProjectPath "skill\demand-merge"
    $mergeScriptPath = Join-Path $ProjectPath "scripts\demand-merge.ps1"
    $mergeSkillTarget = Join-Path $CodexHome "skills\demand-merge"
    $oldSkillTarget = Join-Path $CodexHome "skills\demand-git"

    if (-not (Test-Path -LiteralPath $submitScriptPath)) {
        throw "Cannot find demand-submit script: $submitScriptPath"
    }
    if (-not (Test-Path -LiteralPath $submitSkillSource)) {
        throw "Cannot find demand-submit skill directory: $submitSkillSource"
    }
    if (-not (Test-Path -LiteralPath $mergeScriptPath)) {
        throw "Cannot find demand-merge script: $mergeScriptPath"
    }
    if (-not (Test-Path -LiteralPath $mergeSkillSource)) {
        throw "Cannot find demand-merge skill directory: $mergeSkillSource"
    }

    New-Item -ItemType Directory -Force -Path (Split-Path -Parent $submitSkillTarget) | Out-Null

    if (Test-Path -LiteralPath $submitSkillTarget) {
        Remove-Item -LiteralPath $submitSkillTarget -Recurse -Force
    }
    if (Test-Path -LiteralPath $mergeSkillTarget) {
        Remove-Item -LiteralPath $mergeSkillTarget -Recurse -Force
    }
    if (Test-Path -LiteralPath $oldSkillTarget) {
        Remove-Item -LiteralPath $oldSkillTarget -Recurse -Force
    }

    Copy-Item -LiteralPath $submitSkillSource -Destination $submitSkillTarget -Recurse -Force
    Copy-Item -LiteralPath $mergeSkillSource -Destination $mergeSkillTarget -Recurse -Force

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)

    $installedSubmitSkill = Join-Path $submitSkillTarget "SKILL.md"
    $submitContent = Get-Content -Raw -LiteralPath $installedSubmitSkill
    $submitContent = $submitContent.Replace("{{DEMAND_SUBMIT_SCRIPT_PATH}}", $submitScriptPath)
    [System.IO.File]::WriteAllText($installedSubmitSkill, $submitContent, $utf8NoBom)

    $installedMergeSkill = Join-Path $mergeSkillTarget "SKILL.md"
    $mergeContent = Get-Content -Raw -LiteralPath $installedMergeSkill
    $mergeContent = $mergeContent.Replace("{{DEMAND_MERGE_SCRIPT_PATH}}", $mergeScriptPath)
    [System.IO.File]::WriteAllText($installedMergeSkill, $mergeContent, $utf8NoBom)

    Write-Host "Installed demand-submit skill to: $submitSkillTarget"
    Write-Host "Installed demand-merge skill to:  $mergeSkillTarget"
    Write-Host "Configured script paths:"
    Write-Host "  $submitScriptPath"
    Write-Host "  $mergeScriptPath"
}

try {
    Assert-Git

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        $InstallRoot = Select-InstallRoot
    }

    $targetPath = Move-LegacyProjectIfNeeded -InstallRoot $InstallRoot -ProjectName $ProjectName
    Write-Host "Install root: $InstallRoot"
    Write-Host "Target path:  $targetPath"
    Write-Host "Install ref:  $Ref"

    try {
        Write-Host "Trying Gitee: $giteeRepo"
        Clone-Or-Update -RepoUrl $giteeRepo -TargetPath $targetPath -CheckoutRef $Ref
    } catch {
        Write-Host "Gitee failed: $($_.Exception.Message)"
        try {
            Write-Host "Trying GitHub: $githubRepo"
            Clone-Or-Update -RepoUrl $githubRepo -TargetPath $targetPath -CheckoutRef $Ref
        } catch {
            Write-Host "GitHub failed: $($_.Exception.Message)"
            try {
                Write-Host "Trying legacy Gitee: $legacyGiteeRepo"
                Clone-Or-Update -RepoUrl $legacyGiteeRepo -TargetPath $targetPath -CheckoutRef $Ref
            } catch {
                Write-Host "Legacy Gitee failed: $($_.Exception.Message)"
                Write-Host "Trying legacy GitHub: $legacyGithubRepo"
                Clone-Or-Update -RepoUrl $legacyGithubRepo -TargetPath $targetPath -CheckoutRef $Ref
            }
        }
    }

    Install-Skill -ProjectPath $targetPath

    Show-Info "git-demand-skills 安装完成。`n已安装：demand-submit / demand-merge`n项目目录：$targetPath"
} catch {
    Show-Info "安装失败：$($_.Exception.Message)" "git-demand-skills installer failed"
    exit 1
}


