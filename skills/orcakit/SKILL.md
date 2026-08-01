---
name: orcakit
description: >-
  Bridge a GitHub issue to its own git worktree and back — turn a `ready` issue into an isolated worktree with its label flipped, then reconcile the tracker and remove the worktree once the PR lands. Use when the user says "start issue #N", "spin up a worktree for #N", "finish #N", "orcakit", or wants an issue's isolated workspace created or torn down.
license: MIT
allowed-tools: Bash, Read, Skill
metadata:
  internal: false
---

# orcakit

Thin glue between two systems that each own half of "take an issue from ready to landed": a GitHub issue tracker (labels say *what* is workable) and [git worktrees](https://git-scm.com/docs/git-worktree) (an isolated branch + workspace is *where* it gets worked). orcakit doesn't add tracker or worktree behavior — it **sequences** the two at the two moments they meet: `start <n>` and `finish <n>`.

Both halves are owned elsewhere, and orcakit calls them rather than reimplementing either:

- **issuekit** — the GitHub lifecycle: the `ready` guard, the label flips, closing an issue and unblocking its dependents.
- **gitkit** — the worktree lifecycle: branch naming, the path convention, create-or-adopt, base-ref resolution, and teardown.

> **Deprecated — nothing is left here.** issuekit's `start` and `close` modes now own both moments end to end, worktrees included (via gitkit). **Use issuekit `start <n>` and issuekit `close <n>` directly.** Both actions below are pointers at those modes, kept only so existing invocations of orcakit keep working; the skill is scheduled for removal once the native-git path has proven out on every machine.

## When this fires

The user wants to move an issue between "ready to work" and "landed":

- **start** — "start issue #12", "spin up a worktree for #12", "begin #12", "orcakit start 12".
- **finish** — "finish #12", "wrap up #12 now the PR merged", "tear down #12's worktree", "orcakit finish 12".

If they name neither action explicitly but reference an issue and a worktree, ask which. orcakit never *implements* — it only prepares or tears down the workspace; writing code inside the worktree is a separate step.

## Preflight

Confirm the tooling is ready before mutating anything:

```sh
gh --version && gh auth status          # GitHub CLI installed + authenticated
gh repo view --json nameWithOwner -q .nameWithOwner   # inside a repo
```

- If `gh` is missing or unauthenticated, say so and point to `https://cli.github.com` / `gh auth login` — don't work around it.
- **Portability.** orcakit is repo-agnostic and machine-agnostic: never hard-code a repo id, a base branch, or a worktree path. Everything runs on `gh` plus native git, so a laptop and a headless server behave identically. Run these from inside the target repo's checkout.

## The safety property

orcakit **never creates a worktree for an issue that isn't labeled `ready`.** This one guard is the whole point: because an issue only moves `blocked → ready` when its prerequisite lands (via issuekit `sync`), and only reaches `ready` from the pre-work `needs-planning` state once a human has grilled it, refusing to start anything not-`ready` enforces both the dependency graph *and* the human-grill gate for free — no worktree can get ahead of the tracker or ahead of human judgment. Everything else is mechanical.

The guard itself lives in **issuekit `start`**, which is what orcakit calls; this section states the property, it does not reimplement it.

The lifecycle labels involved — `ready`, `in-progress`, `in-review`, and `blocked` — are provisioned by repokit, not created here. If a required label is absent, stop and point the user at repokit or give the exact fallback command, for example `gh label create ready --color 0E8A16 --description "specified and independent — safe to take into its own worktree now"`.

## Action: `start <n>`

**Invoke issuekit `start <n>`.** It runs the whole start-event sequence: the `ready` guard, the branch name and create-or-adopt worktree via gitkit (off a freshly resolved base ref, never a hard-coded `origin/main` and never a sibling feature branch), and the `ready → in-progress` label flip. Re-running is safe — an existing worktree is adopted and reported, never recreated.

If issuekit isn't installed, run the same sequence yourself: read the issue's labels (`gh issue view <n> --json labels`) and refuse unless it carries `ready`; ask **gitkit** for the branch and worktree; then flip the label:

```sh
gh issue edit <n> --remove-label ready --add-label in-progress
```

Report the worktree and the label move. Do **not** launch an agent or start implementing — that's a separate step run inside the worktree.

## Action: `finish <n>`

**Invoke issuekit `close <n>`.** It runs the whole land-event sequence: the merged-PR hard precondition, the preview-and-confirm gate, the tracker reconciliation (close the issue, tick the parent epic's checklist, flip dependents `blocked → ready`), and the worktree teardown via gitkit — branch-keyed, stopping on a dirty worktree, idempotent when it's already gone.

If issuekit isn't installed, run the same sequence yourself: confirm a merged PR exists for the issue (`gh pr list --search "…" --state merged`) and **stop entirely if none does**, preview what's about to happen and wait for the OK, then:

```sh
gh issue close <n> --comment "Closed by #<pr> (merged)."
gh issue edit <n> --remove-label in-review --remove-label in-progress
# if a task-list parent contains "- [ ] #<n>", read its body, replace that
# marker with "- [x] #<n>", and write the updated body back:
gh issue view <parent> --json body -q .body
gh issue edit <parent> --body-file <updated-body>
# for each dependent whose body says "Blocked by #<n>":
gh issue edit <dep> --remove-label blocked --add-label ready
```

Then ask **gitkit** to remove the worktree for branch `issue-<n>-<slug>`.

Report what changed: issue closed, dependents unblocked, worktree removed.

## Notes

- **Off-convention / legacy worktrees.** Branch-keyed lookup finds a worktree wherever it sits on disk, including one created before this convention existed — git tracks worktrees by recorded path, so an old location keeps working untouched. The one case that still escapes detection is a worktree whose **branch** doesn't follow `issue-<n>-<slug>`. Don't teach `start` to fuzzy-match names; migrate that worktree once by hand (rename the branch to the convention) and note it as a manual step.
- **Non-goals.** orcakit does not implement the feature (that's a separate step inside the worktree), does not launch agents, does not poll-and-spawn or run fleet automation, and adds no tracker or worktree behavior of its own — it only sequences issuekit and gitkit.
- **No shell / CLI available** (e.g. a browser-based agent)? You can't run `gh` or git. Reason from what the user provides and **print the exact commands** — the guard check, the worktree creation, and the label edits — as a codeblock for them to run.
