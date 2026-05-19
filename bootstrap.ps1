param(
    [string]$InstallRoot = "",
    [string]$ProjectName = "demand-submit-skill"
)

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$giteeRepo = "https://gitee.com/bingjiu-lei/demand-submit-skill.git"
$githubRepo = "https://github.com/bingjiu-lei/demand-submit-skill.git"

function Show-Info {
    param([string]$Message, [string]$Title = "demand-submit installer")
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
    $dialog.Description = "请选择 demand-submit-skill 保存到哪个目录"
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
        [string]$TargetPath
    )

    if (Test-Path -LiteralPath $TargetPath) {
        if (Test-Path -LiteralPath (Join-Path $TargetPath ".git")) {
            Write-Host "Project already exists, updating: $TargetPath"
            Run-Git @("fetch", "--all", "--prune") -WorkDir $TargetPath
            Run-Git @("pull", "--ff-only") -WorkDir $TargetPath
            return
        }
        throw "目标目录已存在但不是 Git 仓库：$TargetPath"
    }

    Run-Git @("clone", $RepoUrl, $TargetPath)
}

try {
    Assert-Git

    if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
        $InstallRoot = Select-InstallRoot
    }

    $targetPath = Join-Path $InstallRoot $ProjectName
    Write-Host "Install root: $InstallRoot"
    Write-Host "Target path:  $targetPath"

    try {
        Write-Host "Trying Gitee: $giteeRepo"
        Clone-Or-Update -RepoUrl $giteeRepo -TargetPath $targetPath
    } catch {
        Write-Host "Gitee failed: $($_.Exception.Message)"
        Write-Host "Trying GitHub: $githubRepo"
        Clone-Or-Update -RepoUrl $githubRepo -TargetPath $targetPath
    }

    $installScript = Join-Path $targetPath "install.ps1"
    if (-not (Test-Path -LiteralPath $installScript)) {
        throw "Cannot find install script: $installScript"
    }

    & powershell -NoProfile -ExecutionPolicy Bypass -File $installScript
    if ($LASTEXITCODE -ne 0) {
        throw "install.ps1 failed with exit code $LASTEXITCODE"
    }

    Show-Info "demand-submit skill 安装完成。`n项目目录：$targetPath"
} catch {
    Show-Info "安装失败：$($_.Exception.Message)" "demand-submit installer failed"
    exit 1
}
