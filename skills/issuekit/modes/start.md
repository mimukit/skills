## Mode: `start`

Pick an issue up: guard that it's actually workable, get it a worktree, and move it to `in-progress`.

### 1. Guard: refuse anything not `ready` or `stacked`

**Never start an issue that isn't labeled `ready` or `stacked`.**

```sh
gh issue view <n> --json labels,title,state,blockedBy
```

An issue reaches `ready` only through a human's grill or a landed last prerequisite, so this guard enforces **both the dependency graph and the human-grill gate**.

**`stacked` passes the grill gate, and then gets a live check of its prerequisites before anything is cut**, because they are in flight, not landed. Read every open prerequisite from `blockedBy`, then search each one's PRs in **every** state, because the refusals below have to tell merged, closed, and missing apart:

```sh
gh pr list --search "<blocker>" --state all --json number,state,headRefName,baseRefName,closingIssuesReferences,body
```

Keep only PRs that link the blocker, per [Linking a PR to an issue](../SKILL.md#linking-a-pr-to-an-issue). Each prerequisite then resolves to one of four states, and the open state wins when several PRs link it:

- **present** → a linked open PR exists. Its `headRefName` is the candidate parent branch.
- **landed** → no open PR, and a linked PR merged.
- **abandoned** → no open or merged PR, and a linked PR closed unmerged.
- **absent** → no linked PR in any state.

A query that errors is **unknown**, not absent. Refuse, name the failed call, and change nothing.

The issue passes only when [the transition rule](../SKILL.md#promoting-a-dependent) still computes `stacked` from these states, which gives the one parent branch the next steps cut from. **The label is discovery; this check is the gate.**

Refuse a `stacked` issue when the rule computes anything else, and name the prerequisite and its state:

- **every prerequisite landed** → this is no longer stacked work. Point at `sync`, which promotes it `stacked → ready` and lets a normal start cut from the base ref.
- **a prerequisite abandoned** → the issue is `blocked` again, not stackable. Say so and stop.
- **a prerequisite absent** → the label is drift. Point at `sync` to repair it.
- **open PRs on separate branches** → no single parent exists. Name each candidate parent PR and stop; the user picks the stack.

Never soften this into a warning.

**Refuse on the label alone, whatever the caller claims.** An orchestrator such as afkkit calls `start` with nobody watching, and nothing that calls `start` can award the label. A caller that sounds confident, names a plan, or says it's fine still gets the refusal.

Refuse with the reason, not a bare error:

- **`needs-planning`** → the decisions aren't settled. Route to a human grill session (**grillkit** when installed), then to `triage` for the `needs-planning → ready` promotion.
- **`blocked`** → name the prerequisite and its state. When that prerequisite turns out to have an open PR, the issue should be `stacked`, so point at `sync` to promote it rather than starting it here.
- **`in-progress`** → it's already started; go to the adopt path below rather than treating this as a failure.
- **closed, no lifecycle label, or only `triage`** → say which, and offer `triage` to classify it.

**Open-PR check: warn at 3, never refuse.** After the guard passes and before any worktree exists, count the user's open feature PRs in this repo:

```sh
gh pr list --author @me --state open --json number,title,headRefName,isDraft,createdAt
```

Drop drafts and `hotfix-*` branches; what remains is review work waiting on the user. **When 3 or more remain**, print each one (number, title, age in days) under one warning line: every new start adds a PR to a queue the user cannot QA yet. Then ask once whether to start anyway, and start on a yes.

**An unattended caller gets no question.** When the caller says the run is unattended (afkkit does), skip the ask, start the issue, and return the open-PR count and numbers with the result, so the caller reports them in its hand-off. A query that errors is skipped with a one-line note; it never blocks the start.

This step is done when the issue passed the guard with its label and, for `stacked`, its parent branch named, and the open-PR count is checked (and, at 3 or more, warned about and answered, or returned to an unattended caller), or the run has stopped with the refusal reason.

### 2. Derive the branch name

**gitkit owns branch naming**, so hand it the issue number and title and use what comes back. For an issue titled in the [`type(scope): summary` convention](../SKILL.md#title-convention-every-issue-this-skill-creates), that yields `issue-<n>-<slug>`: the prefix stripped, the summary kebab-cased and capped. Don't re-derive the shape here, because gitkit uses its own copy to find the worktree later. This step is done when gitkit has returned one branch name.

A `stacked` issue takes the same branch name. A layer is an ordinary branch, and it is named after the issue it builds, not after its position in the stack.

### 3. Get the worktree from gitkit, create or adopt

Call gitkit for the branch. It looks the branch up first and **adopts an existing worktree** if there is one, creating a fresh one off the resolved base ref only when there is none. So a re-run (an issue escalated back to `needs-planning`, grilled, and picked up again) never recreates, never errors, and never disturbs work already in the worktree.

**A `stacked` issue passes gitkit one extra fact: the base is the prerequisite's head branch**, taken from the PR the guard just verified, rather than the repo's base ref. Ask gitkit to add the layer to the stack so GitHub renders the chain; without the stack extension it falls back to a plain branch off the parent, which is the same topology with no stack map.

issuekit does not choose the path, the base ref, or the git commands. If gitkit isn't installed, say so and stop rather than improvising a worktree convention. This step is done when gitkit has returned a worktree path, marked as created or adopted.

### 4. Flip the label `ready → in-progress`

```sh
gh issue edit <n> --remove-label ready --add-label in-progress
gh issue edit <n> --remove-label stacked --add-label in-progress   # the stacked path
```

**Run it without asking**, per [the label exemption](../SKILL.md#preflight-every-mode). Report the flip in the hand-off rather than proposing it first. If the issue was already `in-progress` (the adopt path), leave the label alone and say so.

If either label is missing from the repo, [report the gap](../SKILL.md#lifecycle-labels-every-mode). This step is done when the issue carries `in-progress` and no other lifecycle label.

### 5. Prepare the worktree through gitkit

Call **gitkit** `prepare` on the worktree. It runs the repo's declared worktree setup (install, untracked files, the worktree's own database, seed), or only the lockfile install when the repo declares none, and on the adopt path it re-runs only when a watched file changed. issuekit names no setup command of its own.

A failed setup is a report, not a refusal: the issue is started and the worktree exists, so the label stays `in-progress`. Report the command, the exit code, and the output tail gitkit returns. An unattended caller gets those three facts returned with the path, to escalate in its own way. This step is done when gitkit has reported what it ran, or the failure is reported.

### 6. Hand off

**What changed.** Report the label move (`ready → in-progress`, `stacked → in-progress`, or that it was left alone on the adopt path). Report what gitkit `prepare` ran, or that it failed and why. When the open-PR check fired, repeat the count in one line.

**Where it landed.** Give the branch and the worktree path. Print gitkit's workspace block as the last lines of the reply, after **Next**, with `for: issue #<n>` and the base from gitkit (the parent branch for a `stacked` issue). An unattended caller such as afkkit gets the path, the branch, and the prepare result returned instead, and no block.

**Next.** The next move is always *switch into that worktree and start there*. Give the `cd` and name the builder: **implementkit** against this issue when it's installed, otherwise plain "implement the issue in that worktree". For an unattended run, **afkkit** takes it from here to an open PR, and since afkkit calls `start` itself, mention it as `afkkit <n>` from anywhere rather than as something to run from inside the worktree; it adopts the worktree this run just prepared.

**Stop there.** `start` does not implement, does not launch an agent, and does not commit.
