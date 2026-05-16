---
name: demand-submit
description: Submit local changes to a company GitLab demand or ticket branch from a protected-base workflow. Use when the user wants to move current uncommitted changes onto a demand/feature branch based on latest master or release branch, auto commit with [demandId] title, push to the remote branch, stop safely on conflicts, or let Codex/CatPaw/another AI call a repeatable Git submission workflow.
---

# Demand Submit

Use the standalone project script at `{{DEMAND_SUBMIT_SCRIPT_PATH}}` to turn current local changes into a pushed demand branch. The script never commits to `master`; it uses `master` only as the latest base.

Commit message format is always:

```text
[demandId] title
```

Example:

```text
[197462] demand title
```

## Command

From any Git repository:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title"
```

## Behavior

1. Save a backup under `%USERPROFILE%\.codex\demand-submit-backups`.
2. Stash current tracked and untracked changes.
3. Checkout `master`.
4. Pull latest `origin/master` with `--ff-only`.
5. Checkout the demand branch:
   - use local branch if it exists;
   - otherwise track `origin/<demandId>` if it exists;
   - otherwise create a new local branch from latest `origin/master`.
6. Restore the stashed changes.
7. If conflicts occur, stop immediately with exit code `2`; do not commit or push.
8. If clean, `git add -A`, commit with `[$demandId] <title>`, and push with upstream.

## Options

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title" -BaseBranch master -Remote origin
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title" -BranchPrefix "feature/"
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title" -BranchName "feature/197462"
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title" -NoPush
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title" -AllowEmpty
```

## Conflict Handling

If the script stops on conflict:

1. Inspect `git status`.
2. Resolve files containing conflict markers.
3. Run `git diff --check`.
4. Finish manually:

```powershell
git add -A
git commit -m "[197462] demand title"
git push -u origin 197462
```

Agents should resolve conflicts by reading surrounding code and preserving both sides' intent, not by blindly choosing current or incoming changes.

## Safety Rules

- Do not run this when the repository already has unresolved conflicts.
- Do not merge or create GitLab merge requests unless the user asks.
- Do not commit to `master`.
- If `stash pop` fails, leave the repository as-is for IDE or AI conflict resolution.
- Prefer one Git operator at a time: if an AI/script is running this flow, avoid simultaneous IDEA branch checkout or pull.
