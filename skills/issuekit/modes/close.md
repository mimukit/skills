## Mode: `close`

The other bookend to [`start`](./start.md): the issue's PR has merged, so close it out and reclaim its workspace. This mode **previews the close and the teardown and waits for an OK** before it runs them. The label writes run without one, per [the label exemption](../SKILL.md#preflight-every-mode).

### 1. Confirm the PR actually merged, a hard precondition

```sh
gh pr list --search "<n>" --state merged --json number,title,url,closingIssuesReferences
gh pr view <pr> --json state,mergedAt
```

**A merged PR is required, not assumed.** Keep only a PR that links `#<n>`, per [Linking a PR to an issue](../SKILL.md#linking-a-pr-to-an-issue), or the one the user names. If none is found, whether no PR at all or one that's still open, `close` does **nothing**: no close, no label change, no worktree removal. Report exactly what's blocking (`PR #X still open`, `no PR found for #N`) and stop. A failed query is unknown, not "no PR": name the failed call and stop the same way. A forced teardown of unlanded work stays a deliberate thing the user does themselves, through gitkit directly.

This step is done when one merged PR is linked to `#<n>`, or the run has stopped with the reason named.

### 2. Preview, then confirm

Show the full consequence in one line and wait:

> PR #10 (`feat(auth): add sso login`) merged → close #42 and strip its `in-review`, unblock #44 (`blocked → ready`), move #46 (`stacked → ready`), keep #45 `blocked` (still waits on #43), remove the worktree for `issue-42-add-sso-login`, delete `~/qakit/0012-qa-sso-login-2026-07-23/` (14 files).

Compute the dependent moves for the preview with [the transition rule](../SKILL.md#promoting-a-dependent), so each one shows its real result. Name every effect, the label moves included. Find the screenshot folders for the preview as [Remove the QA screenshots](#5-remove-the-qa-screenshots) describes.

This step is done when the user approves the previewed line or declines it. A decline stops the run before the close.

**A merge instruction is the approval when mergekit calls `close`.** mergekit calls `close` after it merges a PR on a direct human ask. That ask already covers the issue close and the teardown, so print the preview line and run it without a wait. A "keep the worktree" or "keep the branch" in the ask still applies.

### 3. Reconcile the tracker

Close the issue and set each dependent with [the transition rule](../SKILL.md#promoting-a-dependent). **This is [`sync`](./sync.md)'s job and `close` reuses it rather than restating it**, so apply [Reconcile](./sync.md#1-reconcile-a-merged-pr-whose-issue-never-closed) and [Labels](./sync.md#3-labels-advance-lifecycle-state-unblock-whats-freed) to this one issue. Find the dependents through the native edge, not the body text, and recheck every open prerequisite of each one before it moves:

```sh
gh issue close <n> --comment "Closed by #<pr> (merged)."
gh issue edit <n> --remove-label in-review --remove-label in-progress
gh issue view <n> --json blocking -q '[.blocking[].number]'    # the dependents
# for each dependent labeled blocked or stacked, the label the rule computes:
gh issue edit <dep> --remove-label blocked --add-label ready
gh issue edit <dep> --remove-label stacked --add-label ready
```

Closing strips the active status label in the same action, so a closed issue never carries a stale `in-review`.

This step is done when the issue is closed with no lifecycle label, and every `blocked` or `stacked` dependent carries the label the rule computes, or is named in the hand-off as unknown or as having incompatible parents.

### 4. Tear the worktree down through gitkit, keyed on the branch

Hand this to **gitkit**, which looks the worktree up by its branch (`issue-<n>-<slug>`) through `git worktree list --porcelain`. Lookup is by branch, never by guessing at a path, so it finds a worktree that predates the current path convention or was moved.

gitkit's own teardown rules apply and issuekit does not override them:

- **A dirty worktree stops the removal** and shows what would be lost.
- **Already gone → "already gone"**, not an error, so a re-run after a partial run is normal.
- **gitkit owns the removal rule, and it resolves to `-d`**, with `-D` only for a squash merge whose merged PR `headRefOid` equals the branch tip. Without gitkit, delete with `-d` and keep the branch when it refuses.
- **A prepared worktree runs its declared teardown first**, such as a drop of the worktree's database, and a failed teardown keeps the worktree. Without gitkit, run the `teardown:` block of the repo's `## Worktree setup` section from inside the worktree before the removal.
- **gitkit removes only what it created**, and reports an unmarked worktree as adopted and keeps it. After a direct merge ask from mergekit, gitkit removes the PR's worktree and local branch, marker or not.
- **A branch another layer is stacked on stays.** Before the teardown, check for open PRs that target this branch (`gh pr list --state open --base issue-<n>-<slug>`), and when there are any, remove the worktree but keep the branch, naming the layers that still need it. Read the PRs, not the labels: a layer already in work is `in-progress` or `in-review`, not `stacked`. GitHub retargets a layer once the branch below it *merges*, but it cannot recover one whose base branch was deleted.

If no worktree matches the branch, say so and carry on. This step is done when the worktree is removed, kept dirty with what would be lost, kept as adopted, or reported as already gone, and the branch is deleted or kept with its reason.

### 5. Remove the QA screenshots

qakit keeps each run's screenshots and gallery in `~/qakit/<plan file name without .md>/`, outside every repo, and commits none of them. Once the PR merges, the folders for the QA plans that PR added have no further use. List those plans from the merged PR:

```sh
gh api --paginate "repos/{owner}/{repo}/pulls/<pr>/files" --jq '.[] | select(.status == "added") | .filename | select(test("^docs/qa/.*[.]md$"))'
```

For each plan, the folder is `~/qakit/` plus the file name without `.md`. Look before you delete: confirm the folder exists and count its files.

```sh
stem=$(basename "<plan>" .md); [ -n "$stem" ] && ls -A "$HOME/qakit/$stem" | wc -l
```

The previewed line names each folder with its file count, so the approval covers the delete. Delete only the folders the preview named:

```sh
[ -n "$stem" ] && rm -rf -- "$HOME/qakit/$stem"
```

A plan with no folder is normal: no driver ran, or a sweep removed it. Say "no screenshots" for it and go on. A failed `gh api` call is unknown, not "no plans": name it and keep every folder. A dirty worktree that [the teardown](#4-tear-the-worktree-down-through-gitkit-keyed-on-the-branch) kept does not keep these folders.

This step is done when each added plan's folder is deleted or reported as absent, or the failed call is named.

### 6. Hand off

**What changed.** Report the issue closed and by which PR, and each dependent move (`blocked → ready`, `stacked → ready`, `blocked → stacked`). Name each dependent left alone, with its reason: open prerequisites remain, an unknown PR query, or incompatible stack parents.

**Where it landed.** Say whether the worktree was removed, left dirty, kept as adopted, or already gone. Name each QA screenshot folder deleted, and each plan that had none. If it survived, name the path and why. A worktree made before gitkit marked its creations is reported as adopted and kept; remove it through gitkit directly when it is no longer needed.

**Next.** Name the issue to pick up next, naming a kit only when it's installed:

- **this close unblocked something** → that dependent is the strongest candidate; name it and offer `start <n>`. When several moved, offer the highest-priority one.
- **nothing was unblocked, but `ready` issues exist** → offer `start` on the highest-priority one, breaking a tie on the most recently updated.
- **nothing is `ready`** → offer **statuskit** to re-orient, or `triage` if the tracker looks like it's hiding work.
- **the worktree survived dirty** → that outranks everything above. Say it first.

