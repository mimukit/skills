# paseokit

Push the git worktrees your workflow actually creates into [Paseo](https://paseo.sh)'s workspace registry, and reap the finished work — the dead rows, and the worktrees whose PRs merged.

**Reach for it when** a worktree you just made is missing from your Paseo sidebar, the sidebar is full of entries whose directories no longer exist, or your machine is full of worktrees whose work already landed.

| | |
|---|---|
| Modes | [`list`](#list) · [`sync`](#sync) · [`clean`](#clean) · [`align`](#align) |
| Tools | `Bash`, `Read`, `Skill` |
| Writes | Paseo workspace rows — `sync` registers and retitles, `clean` archives. `clean`'s confirmed teardown also removes merged worktrees, branches, and sessions |
| Triggering | **explicit only** — model invocation is disabled |
| Visibility | public |

## What it does

Paseo shows one workspace per checkout and hangs agents off each one. The worktrees come from plain `git worktree` — [`gitkit`](./gitkit.md)'s convention, [`issuekit`](./issuekit.md)'s `start`, or your own hands.

**Paseo registers nothing on its own.** A worktree that `git worktree add` created is invisible until something registers it, and there is no discovery setting to turn on.

**It does prune one thing on its own, since 0.7.** A reconciliation pass runs at daemon start and every five minutes, and archives any active row whose directory has gone. It stops there — no duplicate collapsing, no verdict on whether the work landed, nothing touched while the directory still exists.

So the sidebar still drifts from the disk two ways at once — real work that never appears, and finished work that never leaves. paseokit owns that reconciliation, split by direction: [`sync`](#sync) adds what is missing, [`clean`](#clean) removes what is finished. Scoped to the project you run it from, machine-wide on request, and running either twice changes nothing the second time.

## Why it's a pump, not a janitor

This is the whole reason paseokit is a separate skill from [`orcakit`](./orcakit.md) rather than a mode inside it.

| | Orca | Paseo |
|---|---|---|
| Finds worktrees git made | **yes**, on its own | **no**, ever |
| Drops rows for deleted worktrees | **yes**, within seconds | **yes**, since 0.7, within five minutes |
| So the skill's job is | enrich what's already there, then clean up | push rows in, and reap them back out |

The two tools have opposite models, so a shared adapter behind one skill would be most of the skill. They stay independent siblings, both installed, and **neither ever calls the other**.

## On-demand by design

An earlier draft paired the skill with a `post-checkout` git hook, so a worktree registered the moment it was born. The hook was verified working and **cut anyway** — it writes into every repo's `.git/hooks`, and the owner preferred to run the sync by hand.

The trade is stated rather than hidden: worktrees appear in Paseo when you run [`sync`](#sync), not when they are created. No hooks, no scheduler, no background process, nothing written into any repo.

## The line it does not cross

**Git owns the worktree; Paseo owns the row.** paseokit never runs `paseo workspace create --isolation worktree` to do real work, never invents a path, and never lets Paseo create a branch. Creating and removing worktrees stays native `git worktree`, so a machine with no Paseo runs identical commands.

Two facts make the rest of the design possible:

- **`paseo workspace archive` is not registry-only** — it archives every agent the workspace owns, kills every terminal in it, and then tries to delete the backing directory. Only the row is reversible. The delete fires on a worktree Paseo created itself and refuses on one git created, which is why `clean` sorts its candidates by path shape before it queues a single archive, and why the reap still sits behind a preview and one confirmation.
- **Paseo never notices a deleted directory**, so removing a worktree is still gitkit's job, and the row has to be archived afterward — which is exactly what [`clean`](#clean)'s registry reap is for. `clean` is the one mode that removes anything at all: `sync` only adds, and the disk teardown reaches the filesystem by calling gitkit rather than by growing its own teardown.

**It never touches the tracker.** It reads issues and pull requests to build a title and judge a verdict; it never closes, labels, or edits. Tracker drift routes to [`issuekit`](./issuekit.md) `close`.

## The seam it depends on

Worth knowing before you trust it against a newer Paseo, because this is the part most likely to break.

`paseo workspace ls --json` is a **thin projection** — `workspaceId`, `project`, `name`, `isolation`, `cwd`, active rows only. It answers one question (is a live row pointing at this path) and nothing else. Everything the modes actually decide on — `branch`, `title`, `createdAt`, `archivedAt`, `projectId` — lives in `~/.paseo/projects/workspaces.json` and `projects.json`.

`paseo project ls --json` resolves the `prj_…` id that `--project` demands, so the state file is only a fallback there. `workspaces.json` is still unavoidable, because `workspace ls` exposes no `branch`, no `title`, no `createdAt`, and no archived row at all. paseokit reads those files and writes exclusively through the CLI — never into them, because a hand-edited state file needs a daemon restart, and a restart kills every running agent.

An unreadable or unexpectedly-shaped file degrades every writing mode to read-only, naming which file and why. It never guesses at an id.

Two registry quirks it documents rather than works around:

- **`isPaseoOwnedWorktree` stopped lying in 0.7** — it now runs the same hash-directory test the delete runs, and every reconciliation pass refreshes it, so the flag forecasts whether an archive reaches the disk. paseokit reads it and still checks the path shape beside it, because a stored value is only as fresh as the last pass.
- **`workspace create` is not idempotent** — two identical calls on one path silently make two rows. Every existence check before a registration is load-bearing, and it has to count archived rows too, or the tombstone rule below fails silently.

## Modes

### `list`

Read-only. Changes nothing, asks nothing, and is the right first move whenever state is unclear.

It joins `git worktree list --porcelain` per project, `paseo workspace ls --json`, and `paseo ls -g --json` for agents, matching on **absolute path** — the only key both git and Paseo record. Two filters run before any verdict: a worktree with no symbolic HEAD never registers (which is what keeps [`debugkit`](./debugkit.md)'s detached bisect scratch out of the sidebar), and agent `cwd` values come back tilde-abbreviated, so they get expanded before comparison or every `busy` check quietly returns false.

| Verdict | Means | Fix |
|---|---|---|
| `busy` | a non-idle agent's `cwd` is inside this workspace | leave it |
| `registered` | worktree exists, exactly one active row points at it | nothing |
| `unregistered` | worktree exists, no row points at it | [`sync`](#sync) |
| `orphaned` | an active row points at a path that no longer exists | wait; the daemon archives it within five minutes |
| `duplicate` | two or more active rows share one `cwd` | [`clean`](#clean) |
| `tombstoned` | worktree exists, and its only row is archived | [`sync`](#sync), on confirmation |
| `unknown repo` | worktree under `$WORKTREE_ROOT` whose repo Paseo has never seen | [`sync`](#sync), on confirmation |
| `stray project` | a project whose `rootPath` is a worktree, not a main checkout | reported; `paseo project delete` removes it, behind a confirmation |
| `reapable` | pull request merged, issue closed, tree clean | [`clean`](#clean) |

`busy` rows go first when any exist. Those are the rows where an action would interrupt live work. An `orphaned` row is a timing artifact on 0.7 rather than a job: the skill reports it and says when the daemon's own pass will take it, and queues it for archive only when you ask to clear the sidebar now.

A **stray project** has a clear signature — its `projectKey` matches a real project's while its `rootPath` sits under `$WORKTREE_ROOT`. That is what a registration without `--project` produces, and it is the failure paseokit works hardest to avoid. `paseo project delete` makes it recoverable, but the fix deletes every workspace under the project and therefore sits behind `clean`'s confirmation, listing those workspaces first.

The command has a trap the skill guards against: **a wrong project id is not an error.** The daemon accepts any well-formed `prj_…`, removes nothing, and reports success with an empty `removedWorkspaceIds`. `clean` therefore checks that array against what the preview promised rather than trusting the exit status.

### `sync`

The adding mode, safe to run repeatedly by construction. It registers, retitles, and restores — it never archives a row, never collapses a duplicate, and never touches a directory or a branch. Every removal, registry or disk, belongs to [`clean`](#clean).

**Two scopes, picked by the words in the request.** Run from inside a repo, `sync` acts on that project alone — its worktrees, and the rows whose `projectId` matches. "Sync all" widens it to every live project on the machine, and is the only scope that runs the unknown-repo walk, which is machine-wide by nature. Outside a repo, project scope has no referent, so the skill says so and names `sync all` rather than silently sweeping everything.

**Straight through, no confirmation** — register the `unregistered`, retitle the machine-generated titles, and skip anything `busy` with the agent named. `duplicate` sets get reported and routed to [`clean`](#clean), `orphaned` rows get reported as self-healing, and neither is archived here. None of what `sync` does can lose work, so none of it asks.

Two rules carry most of the weight:

- **`--project` is mandatory, and an unresolvable id means skip.** Registering without it creates a stray project instead of a workspace. A missing row is recoverable; a stray project is not, so the skip is the safe failure.
- **Only a title that is null or exactly the branch name gets rewritten.** Titles are `#<n> · <issue title>` from `gh`, degrading to the branch name. Anything else was set by a human and is reported as a disagreement rather than overwritten — the same rule orcakit applies to hand-written metadata.

**Gated on one confirmation each**, because both widen scope past what was asked:

- **Unknown repos** (`sync all` only). It walks `$WORKTREE_ROOT`, resolves each candidate with `git rev-parse --git-common-dir`, and lists repos Paseo has never seen. On an OK it runs `paseo project create <repo>`, which returns the new `prj_…` id directly, then registers the main checkout and the worktrees under that id. Paseo's own worktrees need no special case: they already carry a row and resolve to a known repo, so no hash-directory pattern has to be guessed at.
- **Tombstones.** An archived row **suppresses re-registration**. Someone archived that workspace deliberately, and silently re-adding it would undo the decluttering they just did — so it gets a verdict of its own and an explicit ask.

One honest limitation: **there is still no `paseo workspace unarchive` in 0.7.0.** "Restoring" a tombstone creates a fresh row for the same path, so the archived row stays and the restored workspace gets a new id. The skill says so when it does it rather than reporting a resurrection.

### `clean`

The removing mode, and the only one — every archive and every delete in the skill lives here, in two halves. The **registry reap** collapses `duplicate` sets, and archives an `orphaned` row when you ask for it before the daemon's own pass gets there: registry-only and reversible, since an archived row can be restored. The **worktree teardown** removes the whole local footprint of work that already landed: the agent sessions in the worktree, the directory, the local branch, and the registry row. It takes the same two scopes as `sync`, picked by the same words. Neither half runs before the preview: both candidate sets are collected first, shown as one list, and gated on a single confirmation.

**A merged pull request is the teardown's precondition, and nothing substitutes for it.** `gh pr list --head <branch> --state merged` is the test; a closed-unmerged PR fails it and a suggestive branch name means nothing. Three more gates follow: a clean tree, no unpushed commit, and no live agent. Because the merge is the whole basis for the delete, a missing or unauthenticated `gh` stops the teardown outright instead of degrading it — the one place in paseokit where that happens. The registry reap still goes to the preview, since it proves nothing against the tracker.

**One preview, one confirmation.** The table has an archive section (workspace id, title, reason) and a delete section (branch, merged PR, path, workspace id, and the sessions that go with it), and the ask covers exactly that listed set. Rejected worktrees are printed underneath with their reason, since "why is this one still here" is the next question every time. An empty list ends the mode without asking anything.

**The teardown order is fixed**: stop the sessions, remove the worktree through gitkit, delete the branch with the safe `-d` (a squash merge that refuses gets its own ask before `-D`), then archive the row. Each step strands the next if it runs late. A failure stops that candidate, reports the step, and moves to the next one; nothing is unwound.

An open issue does not block the clean. The code is on the base branch either way, so the local copy is redundant, and the drift routes to [`issuekit`](./issuekit.md) `close` in the hand-off rather than being fixed here.

### `align`

One-time configuration, per machine. It touches no workspace at all.

It compares `worktrees.root` in `~/.paseo/config.json` against `$WORKTREE_ROOT`, because two roots in play means every sweep classifies by path forever. Aligning them **only affects worktrees Paseo creates itself** — existing ones are untouched, and git stores absolute paths, so nothing moves. It says that out loud, because "aligned" reads like "migrated" and it isn't.

It also surfaces `daemon.autoArchiveAfterMerge`, which lets Paseo archive a workspace itself when its change request merges. In 0.7 that switch carries its own gates — merged PR, clean tree, nothing ahead of origin, Paseo-created worktree — so it is a fair native shortcut for the Paseo-created half of [`clean`](#clean)'s reaping, and the skill presents the choice rather than a recommendation. What it still skips is the preview and the confirmation, and it stops the agents and kills the terminals without asking. It reaches no gitkit worktree at all, since those fail the ownership test.

## Preflight

No `paseo` on the machine means there is nothing to reconcile — it says exactly that and stops, with no fallback. The worktrees are already fine without Paseo.

A daemon that is down gets named (`paseo start`) rather than started. It does not launch a daemon on someone's machine unasked.

Without `gh`, titles degrade to the branch name and the tracker column reads unknown. Nothing else degrades in `list`, `sync`, and `align`. [`clean`](#clean)'s worktree teardown is the exception and stops, because only the tracker can prove a merge; its registry reap still runs, behind its own preview and confirmation.

## Hands off to

Whatever the sweep surfaced, ranked. **`busy`** outranks everything: run the mode again once the agent finishes. Then any **stray project**, routed to [`clean`](#clean), because `paseo project delete` also removes every workspace under it. Then **`duplicate`** and **`reapable`** rows to [`clean`](#clean), and tracker drift to [`issuekit`](./issuekit.md) `close`. A registry that already matches the disk gets said plainly, and it stops.

## A note on optionality

paseokit is **machine-local and always optional**. No Paseo means no-op, and nothing else in the workflow may depend on it — gitkit, issuekit, and the rest never call it, because they would break on every machine without the tool. It's a pump you run, not a link in a chain.

## Install

```sh
npx skills add mimukit/skills -s paseokit
```

Source: [`skills/paseokit/SKILL.md`](../../../skills/paseokit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`fb54c09` on 2026-08-31, with Paseo CLI 0.7.0 and daemon 0.7.0._
