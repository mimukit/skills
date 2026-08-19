# paseokit

Push the git worktrees your workflow actually creates into [Paseo](https://paseo.sh)'s workspace registry, and reap the rows whose directories are gone.

**Reach for it when** a worktree you just made is missing from your Paseo sidebar, or the sidebar is full of entries whose directories no longer exist.

| | |
|---|---|
| Modes | [`list`](#list) · [`sync`](#sync) · [`align`](#align) |
| Tools | `Bash`, `Read`, `Skill` |
| Writes | Paseo workspace rows — registers, archives, retitles. Never a directory or a branch |
| Visibility | public |

## What it does

Paseo shows one workspace per checkout and hangs agents off each one. The worktrees come from plain `git worktree` — [`gitkit`](./gitkit.md)'s convention, [`issuekit`](./issuekit.md)'s `start`, or your own hands.

**Paseo's registry is explicit-only in both directions.** It discovers nothing, and it prunes nothing. A worktree that `git worktree add` created is invisible until something registers it; a workspace whose directory was deleted stays in the sidebar forever. There is no discovery setting to turn on and no prune command to run.

So the sidebar drifts from the disk two ways at once — real work that never appears, and finished work that never leaves. paseokit owns that reconciliation: **Paseo's registry, made to match the worktrees that actually exist.** Machine-wide, and running it twice changes nothing the second time.

## Why it's a pump, not a janitor

This is the whole reason paseokit is a separate skill from [`orcakit`](./orcakit.md) rather than a mode inside it.

| | Orca | Paseo |
|---|---|---|
| Finds worktrees git made | **yes**, on its own | **no**, ever |
| Drops rows for deleted worktrees | **yes**, within seconds | **no**, ever |
| So the skill's job is | enrich what's already there, then clean up | push rows in, and reap them back out |

The two tools have opposite models, so a shared adapter behind one skill would be most of the skill. They stay independent siblings, both installed, and **neither ever calls the other**.

## On-demand by design

An earlier draft paired the skill with a `post-checkout` git hook, so a worktree registered the moment it was born. The hook was verified working and **cut anyway** — it writes into every repo's `.git/hooks`, and the owner preferred to run the sync by hand.

The trade is stated rather than hidden: worktrees appear in Paseo when you run [`sync`](#sync), not when they are created. No hooks, no scheduler, no background process, nothing written into any repo.

## The line it does not cross

**Git owns the worktree; Paseo owns the row.** paseokit never runs `paseo workspace create --isolation worktree` to do real work, never invents a path, and never lets Paseo create a branch. Creating and removing worktrees stays native `git worktree`, so a machine with no Paseo runs identical commands.

Two facts make the rest of the design possible:

- **`paseo workspace archive` is registry-only** — verified. It drops the row and leaves the directory, the branch, and git's own worktree registration intact. That is why `sync` can reap without a destructive-confirm gate: nothing it does can lose work, which is the sharpest divergence from orcakit's `clean`, where every removal is irreversible and needs a preview and an OK.
- **Paseo never notices a deleted directory**, so removing a worktree is still gitkit's job, and the row has to be archived afterward — which is exactly what `sync` is for.

**It never touches the tracker.** It reads issues and pull requests to build a title and judge a verdict; it never closes, labels, or edits. Tracker drift routes to [`issuekit`](./issuekit.md) `close`.

## The seam it depends on

Worth knowing before you trust it against a newer Paseo, because this is the part most likely to break.

`paseo workspace ls --json` is a **thin projection** — `workspaceId`, `project`, `name`, `isolation`, `cwd`, active rows only. It answers one question (is a live row pointing at this path) and nothing else. Everything the modes actually decide on — `branch`, `title`, `createdAt`, `archivedAt`, `projectId` — lives in `~/.paseo/projects/workspaces.json` and `projects.json`.

Reading those files is **unavoidable rather than a shortcut**. Paseo 0.4.0 ships no `project ls`; `--project` is mandatory on every registration and rejects both a name and a path; and the `prj_…` id is not derivable from `projectKey` by any hash. paseokit therefore reads the files and writes exclusively through the CLI — never into them, because a hand-edited state file needs a daemon restart, and a restart kills every running agent.

An unreadable or unexpectedly-shaped file degrades every writing mode to read-only, naming which file and why. It never guesses at an id.

Two registry quirks it documents rather than works around:

- **`isPaseoOwnedWorktree` is a known lie** — set `true` for worktrees git created and Paseo merely adopted. No CLI corrects it, so the desktop app may offer to delete a worktree git owns. paseokit never reads the flag to make a decision.
- **`workspace create` is not idempotent** — two identical calls on one path silently make two rows. Every existence check before a registration is load-bearing, and it has to count archived rows too, or the tombstone rule below fails silently.

## Modes

### `list`

Read-only. Changes nothing, asks nothing, and is the right first move whenever state is unclear.

It joins `git worktree list --porcelain` per project, `paseo workspace ls --json`, and `paseo ls --json` for agents, matching on **absolute path** — the only key both git and Paseo record. Two filters run before any verdict: a worktree with no symbolic HEAD never registers (which is what keeps [`debugkit`](./debugkit.md)'s detached bisect scratch out of the sidebar), and agent `cwd` values come back tilde-abbreviated, so they get expanded before comparison or every `busy` check quietly returns false.

| Verdict | Means | Fix |
|---|---|---|
| `busy` | a non-idle agent's `cwd` is inside this workspace | leave it |
| `registered` | worktree exists, exactly one active row points at it | nothing |
| `unregistered` | worktree exists, no row points at it | [`sync`](#sync) |
| `orphaned` | an active row points at a path that no longer exists | [`sync`](#sync) |
| `duplicate` | two or more active rows share one `cwd` | [`sync`](#sync) |
| `tombstoned` | worktree exists, and its only row is archived | [`sync`](#sync), on confirmation |
| `unknown repo` | worktree under `$WORKTREE_ROOT` whose repo Paseo has never seen | [`sync`](#sync), on confirmation |
| `stray project` | a project whose `rootPath` is a worktree, not a main checkout | reported only; no CLI deletes a project |
| `reapable` | pull request merged, issue closed, tree clean | [`gitkit`](./gitkit.md) teardown, then [`sync`](#sync) |

`busy` rows go first when any exist. Those are the rows where an action would interrupt live work.

A **stray project** has a clear signature — its `projectKey` matches a real project's while its `rootPath` sits under `$WORKTREE_ROOT`. That is what a registration without `--project` produces, and it is the failure paseokit works hardest to avoid, because 0.4.0 has no command that deletes a project.

### `sync`

The writing mode, safe to run repeatedly by construction.

**Straight through, no confirmation** — register the `unregistered`, archive the `orphaned`, collapse each `duplicate` set to one row, retitle the machine-generated titles, and skip anything `busy` with the agent named. None of it can lose work, so none of it asks.

Three rules carry most of the weight:

- **`--project` is mandatory, and an unresolvable id means skip.** Registering without it creates a stray project instead of a workspace. A missing row is recoverable; a stray project is not, so the skip is the safe failure.
- **A duplicate set collapses to the agent's row, otherwise the oldest.** The agent pass is already running for the `busy` verdict, so this costs nothing extra.
- **Only a title that is null or exactly the branch name gets rewritten.** Titles are `#<n> · <issue title>` from `gh`, degrading to the branch name. Anything else was set by a human and is reported as a disagreement rather than overwritten — the same rule orcakit applies to hand-written metadata.

**Gated on one confirmation each**, because both widen scope past what was asked:

- **Unknown repos.** It walks `$WORKTREE_ROOT`, resolves each candidate with `git rev-parse --git-common-dir`, and lists repos Paseo has never seen. On an OK it registers the main checkout first — *that call is what brings the project into being* — then re-reads `projects.json` for the new id and registers the worktrees under it. Paseo's own worktrees need no special case: they already carry a row and resolve to a known repo, so no hash-directory pattern has to be guessed at.
- **Tombstones.** An archived row **suppresses re-registration**. Someone archived that workspace deliberately, and silently re-adding it would undo the decluttering they just did — so it gets a verdict of its own and an explicit ask.

One honest limitation: **there is no `paseo workspace unarchive` in 0.4.0.** "Restoring" a tombstone creates a fresh row for the same path, so the archived row stays and the restored workspace gets a new id. The skill says so when it does it rather than reporting a resurrection.

### `align`

One-time configuration, per machine. It touches no workspace at all.

It compares `worktrees.root` in `~/.paseo/config.json` against `$WORKTREE_ROOT`, because two roots in play means every sweep classifies by path forever. Aligning them **only affects worktrees Paseo creates itself** — existing ones are untouched, and git stores absolute paths, so nothing moves. It says that out loud, because "aligned" reads like "migrated" and it isn't.

It also surfaces `daemon.autoArchiveAfterMerge`, which would let Paseo archive a workspace itself when its change request merges — covering part of `sync`'s reaping natively. It's recommended as an experiment to observe, with both limits flagged: undocumented, and it only reaches workspaces where Paseo detected a pull request.

## Preflight

No `paseo` on the machine means there is nothing to reconcile — it says exactly that and stops, with no fallback. The worktrees are already fine without Paseo.

A daemon that is down gets named (`paseo start`) rather than started. It does not launch a daemon on someone's machine unasked.

Without `gh`, titles degrade to the branch name and the tracker column reads unknown. Nothing else degrades and no mode is blocked — unlike orcakit's `clean`, no operation here rests on proving a merge.

## Hands off to

Whatever the sweep surfaced, ranked. **`busy`** outranks everything: run `sync` again once the agent finishes. Then any **stray project**, which is manual by necessity — edit `projects.json`, then `paseo restart` — and which the skill deliberately will not perform, because a restart kills every running agent including its own. Then **`reapable`** rows to [`gitkit`](./gitkit.md) teardown followed by another `sync`, and tracker drift to [`issuekit`](./issuekit.md) `close`. A registry that already matches the disk gets said plainly, and it stops.

## A note on optionality

paseokit is **machine-local and always optional**. No Paseo means no-op, and nothing else in the workflow may depend on it — gitkit, issuekit, and the rest never call it, because they would break on every machine without the tool. It's a pump you run, not a link in a chain.

## Install

```sh
npx skills add mimukit/skills -s paseokit
```

Source: [`skills/paseokit/SKILL.md`](../../../skills/paseokit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`e14d201` on 2026-08-19._
