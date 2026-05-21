---
name: demand-submit
description: Fast GitLab demand submit workflow. Use when the user gives a demand/ticket id and title and wants current repo changes committed to a clean demand branch from latest master/release, with IDEA/WebStorm Staged files honored automatically.
---

# Demand Submit

Run the standalone script:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" <demandId> "<title>" <mode>
```

Uninstall from the cloned project root with `git-demand-skills-uninstall.bat`. Clear only logs with `git-demand-skills-clear-logs.bat`.

Commit message is always:

```text
[demandId] title
```

When maintaining this git-demand-skills repository itself, use a Chinese commit message title and describe what this push changed or added.

## Fast Path

Do this with minimal explanation. Do not write a long analysis before running commands.

1. Work in the user's current Git repository.
2. Check status:

```powershell
git status --short --branch
git diff --cached --name-only
```

3. Choose mode:
   - If `git diff --cached --name-only` returns any file, run with `-StagedOnly`.
   - Do not ask for confirmation when staged files exist. IDEA/WebStorm Staged is the user's selection.
   - Use `-All` only when there are no staged files, or when the user explicitly says to submit all local changes.
4. Run the script.
5. If the script stops with conflict exit code `2`, inspect `git status`, resolve conflicts, run `git diff --check`, then finish commit/push.

## Commands

Staged files exist, or user says to submit selected/staged files:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title" -StagedOnly
```

Submit all local changes:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title" -All
```

Only commit, do not push:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title" -StagedOnly -NoPush
```

Different base branch:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title" -BaseBranch release-1.44 -StagedOnly
```

## Windows Terminal Rules

Assume Windows PowerShell unless the tool explicitly says otherwise.

Use:

```powershell
Set-Location -LiteralPath "D:\path\repo"
git status --short --branch
```

Do not use Bash/CMD syntax in PowerShell:

```text
cd repo && git status
cd /d D:\repo & git status
timeout /t 30 /nobreak >nul
```

Prefer a tool `workdir` parameter over changing directories in shell text.

## Safety Rules

- Never commit to `master`.
- Never create or merge a GitLab merge request unless the user asks.
- Never use `git add -A` manually when staged files exist; use script `-StagedOnly`.
- If staged and unstaged/untracked changes both exist, run `-StagedOnly` directly. Do not ask the user to choose.
- Use `-All` only when the user explicitly wants all local changes, or when there are no staged files.
- Do not auto-merge, reset, rebase, or force-push when base branch pull fails.
- If the script stops on conflict, preserve both sides' intent; do not blindly choose current/incoming changes.
- If the original run used `-StagedOnly`, finish conflicts by re-staging only intended files, not `git add -A`.
