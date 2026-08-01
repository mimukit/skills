---
name: mergekit
description: >-
  Take an open GitHub PR and make it merge-ready on your machine — a git worktree, a sync with the base branch, the project set up and running, and a review pack of everything you need to judge it — then merge it with a merge commit once you say so. Use when you sit down to review the PRs an agent opened overnight, say "pull PR #34 down so I can test it", "review the ready PRs locally", "check out this PR for QA", "get this PR merge-ready", "merge PR #34", or run "/mergekit".
license: MIT
allowed-tools: Bash, Read, Write
metadata:
  internal: false
---

# mergekit

The other half of a pull request's life. Something else opened it — you, an agent, a teammate; mergekit is what you run when it is your turn to *judge* it. It pulls the PR down into its own [git worktree](https://git-scm.com/docs/git-worktree), syncs it with the base branch, gets the project running, and prints a **review pack** of everything you need to form an opinion. Then it waits. When you say merge, it merges; when you say fix, it fixes in the worktree you already have open.

mergekit is the **one skill permitted to merge a pull request** — a deliberate exception to the "never merge without an explicit ask" rule the rest of a PR toolchain holds. That permission is earned by a single hard precondition, stated in [Never merge automatically](#never-merge-automatically): a human confirms *that specific PR*, every time. Without the confirmation, mergekit has no more authority than any other skill.

It forms **no opinion about the code**. Judging the source is a code-review job; mergekit sets the review up and executes the decision you reach.

## When this fires

You are the reviewer, and the PR already exists:

- **list** — "what PRs are waiting on me", "show me the ready-for-review PRs", "mergekit list".
- **start `<n>`** — "pull PR #34 down so I can test it", "set up #34 for review", "check out this PR for QA", "get #34 merge-ready".
- **finish `<n>`** — "merge #34", "this one's good, land it", "#34 needs changes: <findings>".

If a PR is named but the action isn't, assume `start` — setting a PR up is safe and reversible; merging is not.

**Not this skill:** opening a PR from your branch, or judging whether the code is any good. Those belong to a PR-authoring skill and a code-review skill respectively. mergekit begins at an open PR and ends at a merged or updated one.

## Never merge automatically

Every merge requires an explicit, per-PR confirmation from a human who has just reviewed *that* PR. Concretely:

- **Never a batch.** "Merge them all" is not a confirmation for any individual PR. Ask once per PR, naming the number and title.
- **Never inferred.** Green CI, an approving review, zero unresolved threads, and a passing local gate are *inputs to the human's decision* — none of them is the decision. A perfectly green PR still waits.
- **Never default-yes.** Don't phrase the prompt so silence merges. No answer means no merge.
- **Never as a side effect.** `start` never merges. A fix round never merges. Only `finish` merges, and only after the confirmation.

The same preview-and-confirm rule covers every other outward-facing mutation — pushing a sync merge, commenting, relabeling, closing an issue. Show what will happen, wait for the OK.

## Preflight

Every mode starts here:

```sh
gh --version && gh auth status                        # GitHub CLI installed + authenticated
gh repo view --json nameWithOwner,defaultBranchRef    # inside a repo; base branch as structured JSON
```

- If `gh` is missing or unauthenticated, say so and point to `https://cli.github.com` / `gh auth login` — don't work around it.
- Read the base branch from `gh`'s JSON rather than assuming `main`; repos that default to `develop` or `trunk` are real. Everything below written as `origin/<base>` means that branch.
- For `start` and `finish`, confirm the PR exists and is open before touching the filesystem.

## Mode `list` — the morning dashboard

What is actually waiting on you, in one table:

```sh
gh pr list --state open --json number,title,headRefName,isDraft,statusCheckRollup,reviewDecision,author,updatedAt
```

Three facts that command cannot give you matter more than the ones it can, so gather them per PR:

- **Unresolved review threads.** REST does not expose thread resolution state at all — only GraphQL does, via a `reviewThreads` connection carrying `isResolved` and `isOutdated`. Query it with `gh api graphql`; if the shape has moved, check the current [GraphQL API docs](https://docs.github.com/en/graphql) rather than guessing. A PR with a bot review sitting unanswered is not ready for your time.
- **Behind the base branch.** `git fetch origin` once, then compare each head against `origin/<base>` — a PR that is behind is one you would be reviewing in a state that will never exist.
- **A QA plan and proof.** Look for the artifacts your repo's conventions produce (a QA plan doc, a proof bundle, whatever the PR body links). Absence is a fact worth printing, not a silence.

Print one table, most-ready first, with drafts and PRs authored by others clearly marked. **Do not crown a "next" PR** — ranking work is a project-status job, and a reviewer's queue is theirs to order.

## Mode `start <n>` — make it merge-ready

### 1. Resolve the head

```sh
gh pr view <n> --json headRefName,headRepositoryOwner,isCrossRepository,author,title,body,url
```

A **cross-repository (fork) PR** is read-only from here: you can review and merge it, but you cannot push fixes to the contributor's branch. Say that plainly at setup time rather than letting it surface as a confusing push failure later.

### 2. Create the worktree

Worktrees live in `.worktrees/pr-<n>-<slug>/` at the repo root, where `<slug>` is the head branch name kebab-cased and capped at roughly 40 characters. Keep the directory out of git via `.git/info/exclude` rather than `.gitignore` — a local-only ignore that never dirties the tracked tree of a repo you are only visiting.

- **Same-repo PR** — fetch the head branch and add a worktree tracking it, so pushes go back to the PR.
- **Fork PR** — `git fetch origin "pull/<n>/head:pr-<n>"` and add the worktree on that local branch.
- **A worktree for this PR already exists** — adopt it and say so. Re-running `start` is a normal thing a reviewer does; it must never error, and must never blow away work in progress. If the existing worktree is dirty, report what's uncommitted before doing anything else.

### 3. Sync with the base branch — merge, never rebase

Bring `origin/<base>` into the PR branch *before* the human reviews, so they review what will actually land:

```sh
git fetch origin
git rev-list --left-right --count origin/<base>...HEAD    # "<behind>\t<ahead>"; left > 0 means behind
```

If behind, merge `origin/<base>` into the branch. **Never rebase, never force-push** — and this is the opposite of what is right at PR-open time, so it is worth being clear about why. A fresh branch nobody has read can be rebased freely. A branch under review cannot: its review threads are anchored to commits, and a force-push marks every one of them outdated — you would destroy the bot findings and human comments moments before the review that needs them. The PR is landing as a merge commit anyway, so there is no history purity left to protect.

**On conflict:** stop and surface it. List the conflicted files (`git diff --name-only --diff-filter=U`), propose a resolution for each, and confirm before writing. Then, before pushing, **run the repo's own test and build gate** — a conflict resolution is a code change, and it can break something CI passed on five minutes ago. Push the sync merge only after the gate is green and the human has OK'd it, so the PR itself becomes mergeable on GitHub. On a fork PR you cannot push; say so, and keep the merge local for review purposes only.

### 4. Set the project up

Detect the manifest (`package.json`, `pyproject.toml`, `go.mod`, `Gemfile`, `Cargo.toml`, …) and run the install the repo actually uses — the lockfile tells you which package manager, the scripts tell you the dev command. Prefer a project-local run or dev skill when one exists. **Never invent a command**: if you cannot determine how to start the app, say so and ask, rather than guessing at a `dev` script that doesn't exist. Copy `.env.example` to `.env` only if that is the repo's documented setup and the file is absent.

### 5. Print the review pack

Everything the reviewer needs, assembled once so they don't go hunting:

- PR title, number, author, URL, and the body's summary.
- The linked issue and its acceptance criteria, when the PR references one.
- The commits (`git log origin/<base>..HEAD --oneline`) and the file-level shape of the diff (`--stat`).
- The QA plan, if the repo has one for this change, and any proof artifacts.
- **Unresolved review threads with `file:line` and the comment text** — bot or human. This is the highest-value part of the pack: it is what the reviewer would otherwise re-derive by hand.
- Any follow-up nits the PR body itself records.
- CI status per check, and whether the branch is now in sync.

**Name what is missing.** "No QA plan in this repo's conventional location" is information; printing nothing where a QA plan would go is not.

### 6. Hand over

End with two lines: the worktree path, and the single command that starts the app. Then stop — the human reviews and tests. mergekit does not judge the code, and does not proceed to `finish` on its own.

## Mode `finish <n>` — merge or fix

The reviewer has formed an opinion. Which fork you take depends entirely on which one they state.

### Merge path

1. **Confirm** — per [Never merge automatically](#never-merge-automatically). Name the PR number and title, state what you are about to do, and wait.
2. **Approve, when it's possible.** GitHub does not permit approving your own pull request, so on a self-authored PR — the common case when an agent opens PRs under your account — skip the approval, say once that it was skipped and why, and merge directly. When the author is someone else (or a machine identity), offer `gh pr review <n> --approve` first.
3. **Merge** with a merge commit and a fixed subject:

   ```sh
   gh pr merge <n> --merge --subject "chore(repo): merge pull request #<n>"
   ```

   No squash, no rebase-merge. If your repo's merge-commit convention differs, that subject is the one line to change.
4. **Reconcile the tracker** — close the linked issue, unblock dependents, tick a parent checklist. Prefer an installed issue-lifecycle or worktree-teardown skill so that logic lives in one place; otherwise fall back to plain `gh issue close` / `gh issue edit` calls, previewed and confirmed like any other mutation.
5. **Tear down** — remove the worktree (`git worktree remove`) and delete the local branch. Teardown is **idempotent**: a worktree that is already gone reports "already gone" rather than erroring. If the worktree is dirty, stop and show what would be lost instead of forcing the removal.

### Fix path

The reviewer wants changes. They already have the code checked out and running, so fix it right there — do not hand the work back to whatever opened the PR.

1. Turn the reviewer's findings into a concrete spec and implement them **in the live worktree**, preferring an installed implementation skill.
2. Run the repo's test and build gate.
3. Commit in the repo's own style, preferring an installed commit skill.
4. Push. The PR updates in place; the reviewer stays in the same worktree with the app still running.
5. Return to the review — re-print only what changed. Do not merge; that is a fresh decision, and it needs a fresh confirmation.

## Notes

- **The merge exception is narrow.** mergekit may merge because a human is sitting in front of it. It must therefore never be dispatched as a subagent inside an unattended pipeline — the confirmation would have nobody to come from, and "the orchestrator said yes" is not a human review.
- **No polling, no queue, no auto-merge.** mergekit runs when you invoke it. It does not watch for PRs, does not enable GitHub's auto-merge, and does not act on a schedule.
- **Never force-push.** Not during sync, not during a fix round, not to tidy history. A reviewer's threads are anchored to the commits you would be rewriting.
- **Read-only on fork PRs.** You can review and merge them; you cannot push fixes to them. Say so at setup, not at failure.
- **Bot review feedback is reported, not resolved.** mergekit surfaces unresolved threads in the review pack. Triaging bot findings, replying to them, and resolving threads is separate work that belongs earlier in the PR's life, on whatever machine authored it.
- **No shell or `gh` available** (e.g. a browser-based agent)? Then you can't create a worktree or call `gh`. Print the review pack from what the user provides, and print the setup and merge commands as codeblocks for them to run — never claim a merge happened that you could not perform.
