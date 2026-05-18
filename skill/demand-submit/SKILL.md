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
   - rename an existing local target branch to `<target>-backup-<timestamp>`;
   - do not reuse or track an existing remote target branch;
   - always create a fresh local branch from latest `origin/<baseBranch>`.
6. Restore the stashed changes.
7. If conflicts occur, stop immediately with exit code `2`; do not commit or push.
8. If clean, `git add -A`, commit with `[$demandId] <title>`, and push with upstream.

For IDEA/WebStorm partial commits, use Git's Staged area. Files under `Staged` are visible to the script via `git diff --cached --name-only`; ordinary checked files in the IDE commit UI are not necessarily visible unless Git staging is enabled.

## Options

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title" -BaseBranch master -Remote origin
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title" -BranchPrefix "feature/"
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title" -BranchName "feature/197462"
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title" -NoPush
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title" -AllowEmpty
powershell -NoProfile -ExecutionPolicy Bypass -File "{{DEMAND_SUBMIT_SCRIPT_PATH}}" 197462 "demand title" -StagedOnly
```

## IDEA/WebStorm Staged Workflow

When the user wants to submit only selected files:

1. Ask them to put the desired files in IDEA/WebStorm `Staged`.
2. Run the script with `-StagedOnly`.
3. The script records the original staged file list, moves all local changes across the base branch switch, then re-stages only those original staged files.
4. Unstaged local files such as IDE files, generated files, local ports, `.env`, or `bootstrap.yml` remain uncommitted.

Do not use `git add -A` manually in this workflow. Before committing, inspect `git diff --cached --name-only` and ensure it contains only the intended files. This mode is file-based, not hunk-based; if a staged file also has unstaged hunks, those hunks may be included after the file is re-staged.

## Branch Strategy

Default behavior is always to create a clean demand branch from latest `origin/<baseBranch>`. Do not continue a local or remote branch with the same demand id unless the user explicitly asks for that behavior in a future script mode.

If a local target branch already exists, the script renames it to `<target>-backup-<timestamp>` before creating the new branch. This avoids accidentally basing new work on an old MR branch that may have already been merged and deleted remotely.

## Conflict Handling

If the script stops on conflict:

1. Inspect `git status`.
2. Resolve files containing conflict markers.
3. Run `git diff --check`.
4. Run the narrowest practical project validation when available.
5. Finish manually:

```powershell
git add -A
git commit -m "[197462] demand title"
git push -u origin 197462
```

Agents should resolve conflicts by reading surrounding code and preserving both sides' intent, not by blindly choosing current or incoming changes.

If `git pull --ff-only` fails on the base branch, do not auto-merge, reset, rebase, or force-push. Inspect and report the base-branch divergence first:

```powershell
git status --short --branch
git log --oneline origin/<baseBranch>..<baseBranch>
git log --oneline <baseBranch>..origin/<baseBranch>
```

## Safety Rules

- Do not run this when the repository already has unresolved conflicts.
- Do not merge or create GitLab merge requests unless the user asks.
- Do not auto-merge, reset, or rebase when base branch fast-forward pull fails.
- Do not reuse old local or remote demand branches by default; use a clean branch from latest `origin/<baseBranch>`.
- Do not commit to `master`.
- If `stash pop` fails, leave the repository as-is for IDE or AI conflict resolution.
- Prefer one Git operator at a time: if an AI/script is running this flow, avoid simultaneous IDEA branch checkout or pull.
