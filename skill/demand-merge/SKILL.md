---
name: demand-merge
description: Merge one GitLab demand from master into a release branch by cherry-picking matching demand commits onto a clean target branch, with conflict handoff for AI analysis.
---

# Demand Merge

Use this when the user wants to merge/backport one demand from `master` into a release branch such as `release-1.11`.

This skill is named merge for the business workflow, but the Git operation is cherry-pick, not `git merge master`.

Run the standalone script:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_MERGE_SCRIPT_PATH}}" <demandId> "<title>" -TargetBranch release-1.11
```

Commit message is always:

```text
[demandId] title
```

## Fast Path

Do this with minimal explanation.

1. Work in the user's target Git repository.
2. Check status:

```powershell
git status --short --branch
```

3. If the working tree is dirty, stop and tell the user demand-merge needs a clean repo.
4. Infer branches:
   - source branch defaults to `master`.
   - if the user says `11`, use `release-1.11`.
   - target work branch defaults to `<demandId>-11`.
5. If the user gives a date/time, pass it with `-After` or `-Before` to narrow matching commits.
6. Run the script.
7. If the script exits with conflict code `2`, inspect `git status`, conflicted files, the log directory, and original commit diffs. Resolve conflicts by understanding both target release code and source demand intent.

## Commands

Merge one demand from `master` to `release-1.11`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_MERGE_SCRIPT_PATH}}" 2063657 "AI病历智能辅写AI按钮逻辑调整" -TargetBranch release-1.11
```

User says `11`:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_MERGE_SCRIPT_PATH}}" 2063657 "AI病历智能辅写AI按钮逻辑调整" -TargetBranch 11
```

Narrow by time when the same demand id has many commits:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_MERGE_SCRIPT_PATH}}" 2063657 "AI病历智能辅写AI按钮逻辑调整" -TargetBranch 11 -After "2026-05-21 10:30"
```

Only prepare locally, do not push:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_MERGE_SCRIPT_PATH}}" 2063657 "AI病历智能辅写AI按钮逻辑调整" -TargetBranch 11 -NoPush
```

## Conflict Handling

When conflicts occur, do not choose ours/theirs blindly.

Use:

```powershell
git status --short
git diff --name-only --diff-filter=U
git diff --cc -- <file>
git show <commit> -- <file>
```

Resolve by preserving the release branch's compatible structure and applying only the demand's intended behavior.

After conflicts are resolved:

```powershell
git add -- <resolved-files>
git diff --check
git commit -m "[demandId] title"
git push -u origin <demandId>-11
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

- Never commit to `master` or the target release branch directly.
- Never create or merge a GitLab merge request unless the user asks.
- Never use `git merge master` for this workflow.
- Require a clean working tree before running.
- If too many commits match the same demand id, ask the user for date/time to narrow the range.
- If no matching commits are found, stop; do not guess.
- If the script stops on conflict, keep the conflict state for AI/manual resolution.
