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

真正执行 Git 流程的脚本仍然留在当前项目里：

```text
<clone-path>\scripts\demand-submit.ps1
```

安装时会自动把 Skill 里的脚本路径替换成你本机的真实 clone 路径，所以这个项目可以放在任意目录。

## 在 Codex 中使用

安装后，新开一个 Codex 会话，然后直接说：

```text
用 demand-submit 提交当前仓库，需求号 197462，标题“壮医诊断改造”
```

Codex 会根据 Skill 自动调用脚本，不需要你每次手动找脚本路径。

## 在其他本地 AI 工具中使用

如果是 CatPaw、Trae 或其他能执行本地命令的 AI 工具，可以让它执行：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\scripts\demand-submit.ps1" 197462 "需求标题"
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
   - 如果本地分支存在，直接使用；
   - 如果远程分支 `origin/<需求号>` 存在，则创建本地跟踪分支；
   - 如果都不存在，则从最新 `origin/<baseBranch>` 创建新分支。
6. 恢复刚才 stash 的改动。
7. 如果发生冲突，立即停止，不 commit、不 push。
8. 如果没有冲突，执行 `git add -A`，提交为 `[需求号] 标题`，然后 push 到远程分支。

## 常用示例

默认分支名就是需求号：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\scripts\demand-submit.ps1" 197462 "需求标题"
```

指定基线分支，例如基于 `release-1.44`：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\scripts\demand-submit.ps1" 197462 "需求标题" -BaseBranch release-1.44
```

给需求分支加前缀：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\scripts\demand-submit.ps1" 197462 "需求标题" -BranchPrefix "feature/"
```

指定完整分支名：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\scripts\demand-submit.ps1" 197462 "需求标题" -BranchName "197462-1.44"
```

只 commit，不 push：

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "<clone-path>\scripts\demand-submit.ps1" 197462 "需求标题" -NoPush
```

## 安全策略

- 不会往 `master` 提交。
- 不会创建或合并 Merge Request。
- 遇到冲突会停止，不会推送冲突代码。
- 执行前会生成 patch 备份。
- 拉取基础分支时使用 `git pull --ff-only`，避免自动 merge。
- 建议同一时间只让一个工具执行 Git 操作，避免 IDEA、Codex、CatPaw 同时切分支。
