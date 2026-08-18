# orcakit

Keep the [Orca](https://www.onorca.dev/) desktop app's workspace list honest about the git worktrees your workflow actually creates.

**Reach for it when** your Orca sidebar is full of finished work, or its cards say nothing about what each workspace is for.

| | |
|---|---|
| Modes | [`list`](#list) · [`link`](#link) · [`clean`](#clean) · [`align`](#align) |
| Tools | `Bash`, `Read`, `Skill` |
| Writes | Orca workspace metadata; removes merged worktrees on confirmation |
| Visibility | public |

## What it does

Orca shows one workspace per git worktree, with a card carrying the linked issue, a status, and any terminals running in it. Worktrees themselves come from plain `git worktree` — [`gitkit`](./gitkit.md)'s convention, [`issuekit`](./issuekit.md)'s `start`, or your own hands — and Orca discovers them on its own.

What nothing owns is the **drift between the two**. A worktree named `issue-42-add-sso-login` sits in the sidebar with no issue attached, so its card says nothing. An issue closes and its PR merges, but the workspace stays forever, and three weeks later the sidebar is mostly finished work.

orcakit owns exactly that reconciliation: **Orca's view of your worktrees, made to match the tracker.**

## The line it does not cross

**Git is the source of truth for a worktree.** orcakit never runs `orca worktree create` to do real work and never invents a path. Creating a worktree is native `git worktree` under gitkit's convention, so a headless Linux box with no Orca runs identical commands.

orcakit works one layer up, on things only Orca knows: **metadata** (the linked issue, workspace status, comment, display name) and **Orca-side resources git can't express** (live terminals bound to a workspace, a repo's archive and setup hooks).

Removing a worktree with git is enough — Orca notices within seconds and drops the entry itself.

**It never touches the tracker.** It reads issues and PRs to judge state; it never closes an issue, moves a label, or edits a PR. A merged PR whose issue is still open is tracker drift, and it says so, routing to [`issuekit`](./issuekit.md) `close` rather than reaching around it.

## Two kinds of workspace

Everything turns on this distinction:

| Kind | Where it lives | Created by | How it goes away |
|---|---|---|---|
| **git-native** | `$WORKTREE_ROOT/<repo>/<branch>` | gitkit, issuekit `start`, or a human | **git removes it**; Orca drops the entry on its own |
| **Orca-native** | `~/orca/workspaces/<repo>/<name>` | `orca worktree create` | **`orca worktree rm`**, so hooks and terminals are handled |

Classification is by path prefix, which is a heuristic rather than something Orca records — so it's a *reason to confirm before deleting*, never a thing to act on silently. [`align`](#align) exists to collapse the two locations and retire the guesswork.

## Modes

### `list`

Read-only. Changes nothing, asks nothing, and is the right first move whenever state is unclear.

Every non-main workspace gets joined against the tracker and given a verdict:

| Verdict | Means | Fix |
|---|---|---|
| `active` | open issue or PR, work in flight | nothing |
| `unlinked` | branch names an issue, `linkedIssue` is null | [`link`](#link) |
| `stale status` | Orca says `in-progress`, the PR is merged or in review | [`link`](#link) |
| `reapable` | PR merged, issue closed, tree clean | [`clean`](#clean) |
| `tracker drift` | PR merged, issue still **open** | [`issuekit`](./issuekit.md) `close` — not orcakit's to fix |
| `dirty` | uncommitted or unpushed work, whatever the tracker says | a human, before anything else |
| `unknown` | no issue in the branch name and no PR | leave it; say so |

`dirty` rows go first when any exist. That's where work gets lost.

### `link`

Attach the metadata Orca can't infer, so a card actually says what it's for — the issue number, and a `workspaceStatus` mapped from the *real* state rather than the label alone (no PR and no commits → `todo`; work committed → `in-progress`; PR open → `in-review`; PR merged → `done`).

Four rules keep it from trampling deliberate choices:

- **Preview the whole batch, take one OK.** Nothing is destroyed, but it rewrites your sidebar.
- **Never overwrite a `linkedIssue` already set** to something different — a human put it there. Report the disagreement and leave it.
- **Never overwrite a hand-written comment.** Set one only when empty.
- **Leave the main worktree alone.** It isn't feature work.

A branch naming no issue is skipped and counted. It never invents links from slugs.

### `clean`

Reclaim workspaces whose work already landed. Every removal is irreversible, so the shape is fixed: **gather, qualify, preview everything at once, take one confirm, then remove.**

A candidate needs its work **provably merged with the tracker already agreeing** — a merged PR, and either no issue in the branch name or an issue already closed. A branch merged into the base with no PR is weaker evidence, so it gets its own section in the preview rather than being bundled in.

**A merged PR with an open issue is not a candidate.** That's tracker drift, routed to issuekit `close`, which closes the issue, unblocks dependents, *and* tears the worktree down — doing the job properly instead of deleting the evidence behind the tracker's back.

Hard skips, each appearing in the preview with its reason so nothing vanishes silently: uncommitted or untracked files, unpushed commits or no upstream, the main worktree, **the worktree you're currently inside**, and live Orca terminals — which get offered as a separate confirmed step, never stopped as a side effect of tidying.

**A merged PR does not imply an empty worktree.** Scratch files, a stashed experiment, a follow-up commit that never got pushed — none are in the PR, all live there.

Removal goes by kind. git-native hands to gitkit's teardown and then **stops** — calling `orca worktree rm` too just errors on a path that's already gone. Orca-native uses `orca worktree rm --run-hooks`, the one place orcakit runs a vendor command that also performs the git removal, because Orca created that checkout and its `rm` sequences the hook and terminals that git knows nothing about.

**Never `--force`.** Every removal is already gated on a clean tree and a merged PR; if git refuses anyway, that refusal is information.

### `align`

Stop Orca creating worktrees somewhere gitkit will never look. Two roots means every sweep has to classify by path forever.

It **verifies rather than assumes**: the setups listing doesn't echo the base path back, and whether Orca appends the repo name is undocumented. So it confirms empirically with a throwaway worktree, reads the resulting path, and removes it in the same breath. A declined or failed check gets reported as "set but not verified" — never a convergence it didn't observe.

**Existing worktrees are untouched.** `align` only changes where the *next* one goes, and it says so out loud, because "aligned" reads like "migrated" and it isn't.

## Preflight

No `orca` on the machine means there's nothing to reconcile — it says exactly that and stops, with no fallback. Worktrees are already fine without Orca.

Without `gh`, `list` still works but every verdict degrades to unknown tracker state, and **`clean` cannot run at all**, because its whole safety rests on knowing a PR merged.

It also checks that Orca is configured to surface externally-created worktrees. A repo set to hide them makes every gitkit worktree invisible to every mode here — that's a per-repo UI setting with no CLI flag, so it reports the repo by name rather than pretending an empty result is an empty worktree root.

## Hands off to

Whatever the sweep surfaced: anything skipped as **dirty** outranks everything, because unlanded work in a stale worktree is what actually gets lost. Then tracker drift to [`issuekit`](./issuekit.md) `close`. Nothing left to clean means it says so and stops — sidebar hygiene is not a loop worth repeating.

## A note on optionality

orcakit is **machine-local and always optional**. No Orca means no-op, and nothing else in the workflow may depend on it — gitkit, issuekit, and the rest never call it, because they'd break on every machine without the app. It's a janitor you run, not a link in a chain.

[`paseokit`](./paseokit.md) is the sibling that does the same job for [Paseo](https://paseo.sh), against the opposite problem: Paseo discovers nothing and prunes nothing, so it pushes rows in rather than tidying rows it found. Both are optional, and **neither ever calls the other**.

## Install

```sh
npx skills add mimukit/skills -s orcakit
```

Source: [`skills/orcakit/SKILL.md`](../../../skills/orcakit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`27667cb` on 2026-08-18._
