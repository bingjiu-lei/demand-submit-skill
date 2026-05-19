# demand-submit-skill

一个可复用的 Codex Skill + PowerShell 脚本，用来把当前本地改动快速提交到公司 GitLab 的需求分支。

它适合这种工作流：

```text
当前目录开发代码
基于最新 master / release 分支创建需求分支
自动生成 [需求号] 标题 的 commit message
自动 commit 并 push 到远程需求分支
如果有冲突就停下来，不提交、不推送
```

提交信息格式固定为：

```text
[需求号] 标题
```

例如：

```text
[197462] 壮医诊断改造，诊断类型选择壮医诊断时，只显示壮医目录下的内容
```

## 安装

先 clone 这个仓库，然后在仓库根目录执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\install.ps1
```

安装器只会把 Codex Skill 复制到：

```text
%USERPROFILE%\.codex\skills\demand-submit
```

不要求必须安装 Codex。安装脚本只是写入用户目录下的 `.codex\skills`；只要你的 AI 工具支持扫描 `.codex\skills`，就可以加载这个 skill。

真正执行 Git 流程的脚本仍然留在当前项目里：

```text
<clone-path>\scripts\demand-submit.ps1
```

安装时会自动把 Skill 里的脚本路径替换成你本机的真实 clone 路径，所以这个项目可以放在任意目录。

## 卸载

推荐用完整路径执行卸载脚本，不要站在项目目录里卸载项目本身：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\uninstall.ps1"
```

默认只删除安装到 Codex 目录里的 skill，不会删除你 clone 下来的 `demand-submit-skill` 项目。

如果想连 clone 下来的项目目录一起删除，加 `-RemoveProject`：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\uninstall.ps1" -RemoveProject
```

如果也想删除脚本自动生成的提交保护记录，可以加 `-RemoveBackups`：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\uninstall.ps1" -RemoveProject -RemoveBackups
```

如果编辑器或终端还打开在项目目录里，Windows 可能会暂时删不干净；关闭占用后重新执行即可。

## 在 Codex 中使用

安装后，新开一个 Codex 会话，然后直接说：

```text
用 demand-submit 提交当前仓库，需求号 197462，标题“壮医诊断改造”
```

Codex 会根据 Skill 自动调用脚本，不需要你每次手动找脚本路径。

## 给 AI 工具的终端提醒

Windows 上默认按 PowerShell 处理命令，不要把 Bash、CMD、PowerShell 的语法混用。

PowerShell 里应该这样写：

```powershell
Set-Location -LiteralPath "D:\gitProgram\your-repo"
git status --short --branch
```

不要在 PowerShell 里用这些写法：

```text
cd repo && git status
cd /d D:\repo & git status
timeout /t 30 /nobreak >nul
```

如果 AI 工具有 `workdir` / 工作目录参数，优先直接把工作目录设成仓库路径，再单独执行 Git 命令。

## IDEA / WebStorm 只提交部分文件

如果你只想提交某些文件，不想把本地端口配置、IDE 文件、运行服务生成文件一起提交，推荐使用 IDEA / WebStorm 的 `Staged` 区。

在 IDEA / WebStorm 里：

```text
Staged      = 这次要提交的文件
Unstaged    = 继续留在本地、不提交的文件
```

只需要把要提交的文件放进 `Staged`，不需要在 IDEA 里点 commit。

然后让 AI 执行：

```text
用 demand-submit 只提交暂存文件，需求号 197462，标题“需求标题”
```

或直接执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\scripts\demand-submit.ps1" 197462 "需求标题" -StagedOnly
```

`-StagedOnly` 会记录脚本运行前已经暂存的文件，切换基础分支并恢复改动后，只重新暂存这些文件并提交。未暂存文件会继续留在本地工作区，不进入 commit。

注意：`-StagedOnly` 是按“文件”处理，不是按“代码块/hunk”处理。如果同一个文件里既有已暂存改动，又有未暂存改动，脚本恢复后会重新暂存这个文件的当前完整改动。建议在 IDEA / WebStorm 里先把要提交的文件整理成“这个文件可以整体提交”的状态。

为了防止 AI 忘记加 `-StagedOnly`，脚本现在有一个强制保护：

```text
如果同时存在 Staged 文件和 Unstaged / Untracked 文件，
并且命令里既没有 -StagedOnly，也没有 -All，
脚本会直接停止，不会自动提交。
```

这种情况通常表示你已经在 IDEA / WebStorm 里选择了本次要提交的文件，所以 AI 应该使用 `-StagedOnly`。只有你明确说“提交全部本地改动”时，才应该使用 `-All`。

对 AI 工具的要求是：看到这种混合状态时，不要再问用户“提交暂存区还是提交全部”。直接按 IDEA / WebStorm 的 Staged 选择执行 `-StagedOnly`。用户明确说“全部提交”“提交所有本地改动”时，才使用 `-All`。

可以用下面的命令确认哪些文件会被提交：

```powershell
git diff --cached --name-only
```

## 在其他本地 AI 工具中使用

如果是 CatPaw、Trae 或其他能执行本地命令的 AI 工具，可以让它执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\scripts\demand-submit.ps1" 197462 "需求标题" -All
```

如果你已经在 IDEA / WebStorm 里把文件放进 `Staged`，让它执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\scripts\demand-submit.ps1" 197462 "需求标题" -StagedOnly
```

如果脚本遇到冲突并停止，可以继续让 AI：

```text
查看 git status，分析冲突文件，保留两边代码意图后解决冲突，运行 git diff --check，然后按 [197462] 需求标题 的格式提交并推送。
```

## 脚本会做什么

1. 在 `%USERPROFILE%\.codex\demand-submit-backups` 下备份当前状态和 patch。
2. stash 当前已跟踪和未跟踪的改动。
3. 切到基础分支，默认是 `master`。
4. 使用 `git pull --ff-only` 拉取最新 `origin/<baseBranch>`。
5. 切到需求分支：
   - 如果本地已有同名需求分支，先改名备份为 `<需求号>-backup-时间戳`；
   - 不复用远程同名需求分支；
   - 始终从最新 `origin/<baseBranch>` 创建新的需求分支。
6. 恢复刚才 stash 的改动。
7. 如果发生冲突，立即停止，不 commit、不 push。
8. 如果没有冲突：
   - `-All` 模式会执行 `git add -A`，提交全部改动；
   - `-StagedOnly` 模式只提交脚本运行前已经暂存的文件。
   - 如果脚本发现同时存在 `Staged` 和 `Unstaged / Untracked`，但命令里没有显式传 `-StagedOnly` 或 `-All`，它会停止，防止 AI 误提交全部文件。

## 冲突和拉取失败时怎么办

如果 `stash pop` 或恢复改动时发生冲突，脚本会停止并保留冲突现场。此时不要直接提交或推送，应该让 AI 或 IDE 继续处理：

```text
查看 git status，打开冲突文件，结合上下文合并冲突，运行 git diff --check，必要时运行项目的最小验证，确认无误后再 git add、commit、push。
```

如果 `git pull --ff-only` 失败，说明本地基础分支不能直接快进到远程基础分支。此时不要自动 merge、不要 reset，也不要强推。应该先检查：

```powershell
git status --short --branch
git log --oneline origin/<baseBranch>..<baseBranch>
git log --oneline <baseBranch>..origin/<baseBranch>
```

确认本地基础分支是否有额外提交、是否落后远程、是否需要人工处理后，再继续提交流程。

## 分支策略

脚本默认不会复用本地或远程已有的需求分支。每次提交都会先更新基础分支，然后从最新的 `origin/<baseBranch>` 创建一个干净的需求分支。

如果本地已经存在同名需求分支，例如 `190281`，脚本会先把它改名为：

```text
190281-backup-20260518-101500
```

然后重新从 `origin/<baseBranch>` 创建新的 `190281` 分支。这样可以避免旧需求分支、已合并 MR 分支、或本地残留分支影响新提交。

## 常用示例

默认分支名就是需求号：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\scripts\demand-submit.ps1" 197462 "需求标题" -All
```

指定基线分支，例如基于 `release-1.44`：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\scripts\demand-submit.ps1" 197462 "需求标题" -BaseBranch release-1.44 -All
```

只提交 IDEA / WebStorm Staged 里的文件：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\scripts\demand-submit.ps1" 197462 "需求标题" -StagedOnly
```

给需求分支加前缀：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\scripts\demand-submit.ps1" 197462 "需求标题" -BranchPrefix "feature/" -All
```

指定完整分支名：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\scripts\demand-submit.ps1" 197462 "需求标题" -BranchName "197462-1.44" -All
```

只 commit，不 push：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\scripts\demand-submit.ps1" 197462 "需求标题" -NoPush -All
```

## 安全策略

- 不会往 `master` 提交。
- 不会创建或合并 Merge Request。
- 遇到冲突会停止，不会推送冲突代码。
- `git pull --ff-only` 失败时不会自动 merge 或 reset。
- `-StagedOnly` 模式不会提交未暂存文件。
- 如果同时存在已暂存和未暂存/未跟踪文件，AI 应该直接使用 `-StagedOnly`，不要反复询问；只有用户明确要求提交全部时才使用 `-All`。
- 不会复用本地或远程旧需求分支，会从最新 `origin/<baseBranch>` 创建干净分支。
- 执行前会生成 patch 备份。
- 拉取基础分支时使用 `git pull --ff-only`，避免自动 merge。
- 建议同一时间只让一个工具执行 Git 操作，避免 IDEA、Codex、CatPaw 同时切分支。
