# issuekit

Own the GitHub issue lifecycle in five modes — file the work, pick it up, land it, keep it in sync as PRs merge, and keep the tracker honest.

**Reach for it when** a plan needs turning into issues, or an issue needs starting, closing, or reconciling.

| | |
|---|---|
| Modes | [`create`](#create) · [`start`](#start) · [`close`](#close) · [`sync`](#sync) · [`triage`](#triage) |
| Tools | `Bash`, `Read`, `Edit`, `Write`, `Skill` |
| Writes | GitHub issues, labels, PR bodies; annotates the source plan |
| Visibility | public |

## What it does

Five jobs in one skill, because they're the same job at five points in a dev workflow.

**`close` vs `sync`** is the split worth understanding: it's by *scope*, not mechanism. `close` lands **one named issue** whose PR you know merged, and is the only mode that touches the filesystem. `sync` sweeps the **whole tracker** for drift after the fact and never touches a worktree. `close` reuses `sync`'s reconciliation rather than restating it.

**If no mode is clear, it asks first.** It won't guess between creating and mutating the tracker.

## Safety stance

Creating, closing, and relabeling issues are outward-facing mutations. **Every one is previewed and gets an OK before it runs.** It never merges PRs.

**One exemption exists, for an unattended caller.** An orchestrator running with nobody at the keyboard ([`afkkit`](./afkkit.md)) may pre-authorize exactly one mutation: `start`'s `ready → in-progress` flip. It has to be *told* the run is unattended; it's never assumed.

The exemption is narrow because it's the only mutation whose approval is already implied by an earlier human act — the `ready` guard has refused everything a human hasn't grilled, so the only issues reaching the flip are ones a human already cleared for exactly this. Nothing else widens, and **no caller of any kind gets to skip the guard itself.**

## The lifecycle labels

issuekit **uses** these labels and never creates them. Provisioning is [`repokit`](./repokit.md)'s job — a missing label means it stops and tells you how to add it rather than creating it silently.

| label | means |
|-------|-------|
| `triage` | filed, not yet assessed |
| `needs-planning` | a human plan/grill session is still owed |
| `ready` | specified and **independent** — safe to take into its own worktree now |
| `blocked` | has an unmet prerequisite, named in the body as `Blocked by #N` |
| `in-progress` | actively being worked |
| `in-review` | a PR is open |
| `needs-info` · `wontfix` · `duplicate` | side exits |

Two pairs carry the design:

**`ready` vs `blocked` is the parallel-work pair.** issuekit sizes and sequences issues so each can be picked up in its own worktree with no ordering constraint. `gh issue list --label ready` is then the exact set you can fan out right now.

**`needs-planning` vs `ready` is the human-gate pair.** `ready` means specified enough to work **unattended**. An issue earns it only once a grill settled its decisions.

**Type lives in the title, not a label** — issues carry `feat(scope):` per the Conventional-Commits title convention shared with [`commitkit`](./commitkit.md), so the map holds only lifecycle status. A **closed** issue needs no `done` label; the closed state is the signal.

## Modes

### `create`

Turn a plan document or a plain description into well-formed issues.

Four principles govern the breakdown, applied **before** anything is presented:

- **Fewest issues by default.** Actively look for scopes where related tasks collapse into **one issue with a checklist**. Splitting on request beats starting fragmented.
- **Vertical slices.** Size each issue to complete **one testable feature end to end** — "user can log in with SSO" rather than separate "add OIDC table" / "add OIDC route" / "add OIDC UI" issues, with those layers folded in as checklist items. Size it to fit a single fresh agent context, too.
- **Independent by default.** When two slices share state, first try to **design the dependency away** — fold them together, or resequence so the shared piece ships inside the prerequisite. Only a surviving real constraint gets recorded.
- **Prefactor first.** Look for a simplifying refactor that makes the real change trivial. A clean prefactor often *removes* a dependency that would otherwise force a `blocked` chain, so it earns its keep even as an extra issue.

A wide mechanical refactor that genuinely can't be one slice gets sequenced **expand → migrate → contract** — turning one un-sliceable change into a fan of mostly-parallel issues with honest `Blocked by #N` edges, reusing the existing machinery with no new labels.

The proposal comes as a **preview table** and stops for approval. The **Depends on** column is where independence is decided out loud, and keeping it as empty as honesty allows is the goal — a mostly-blank column is a tracker you can fan out. **This guard is the point: never spray a repo with auto-generated issues.**

It also **guards against duplicates** before creating, because `create` is the workflow's entry point and gets re-invoked. And **milestones are opt-in** — never introduced by default, because you'd then have to maintain them.

The **grill gate** decides which label vocabulary applies. A plan carrying grillkit's `Grilled: YYYY-MM-DD` stamp gets the normal `ready`/`blocked` pair. An ungrilled source gets **`needs-planning` on everything** — which is what keeps afkkit from picking up work a human hasn't grilled.

### `start`

Pick an issue up. Deliberately thin: the tracker half is issuekit's, the worktree half is [`gitkit`](./gitkit.md)'s, and there's nothing in between.

**Never start an issue that isn't labeled `ready`.** This one guard carries more weight than its size suggests, and it's the reason `start` lives here rather than in a worktree skill.

An issue reaches `ready` only two ways: a human grilled its decisions settled, or `sync` promoted it when its prerequisite landed. So refusing everything else enforces **both the dependency graph and the human-grill gate for free.**

The gate does not depend on who types the command. It's the *label* that carries the human's judgment, earned upstream at the grill, and nothing calling `start` can award it. So it refuses on the label alone — **never softened because the caller sounds confident, names a plan, or says it's fine.**

Refusals name the reason. An issue already `in-progress` isn't a failure — it takes the adopt path, where gitkit hands back the existing worktree and the label is left alone. That's what makes `start` safe to re-run.

### `close`

The other bookend. The issue's PR merged, so close it out and reclaim its workspace.

**A merged PR is required, not assumed.** No PR, or one still open, means `close` does **nothing** — no close, no label change, no worktree removal.

That precondition is the whole reason `close` is safe to run on a name you half-remember. Its two irreversible acts — closing the issue and deleting a worktree — are both gated behind evidence the work actually landed. Forced teardown of unlanded work stays something you do deliberately, through gitkit directly.

The preview names **every** effect, including routine ones: unblocking a dependent changes what someone else picks up next, and removing a worktree deletes a directory they may have a terminal sitting in.

Teardown goes to gitkit, whose rules aren't overridden: **a dirty worktree stops the removal**, because a merged PR does not guarantee an empty worktree — scratch files, a stashed experiment, an unpushed follow-up all live there and none are in the PR.

### `sync`

Reconcile the PR↔issue relationship after the fact.

It **deliberately does not write the forward `Closes #N` link onto a fresh PR** — that's [`prkit`](./prkit.md)'s job at open time. sync earns its place only where the automatic chain *broke*: a merged PR whose issue never closed, a missing link on an existing PR, an un-ticked parent checklist, and the dependency payoff — when a blocker closes, finding what it was holding up and swapping `blocked` → `ready`.

**If which issue a PR should have closed is ambiguous, it asks rather than guesses.** Closing the wrong issue is worse than leaving one open.

Its hand-off prints the **actionable set** — every open issue that's `in-progress` or `ready` after the sync — so you see at a glance what's being worked and what you can pick up.

### `triage`

Report first, act on approval. **It never mutates the tracker just to tidy up.**

It fetches `--state all`, because detecting a closed parent with open children needs the closed issues too, and it enumerates native sub-issues through the API rather than assuming the body tells the whole story.

The drift it flags: stale · orphaned · broken hierarchy · **zombie label** (a closed issue still carrying a status) · **stale block** (a `blocked` whose target already closed) · dangling or circular dependencies · unmarked · **ungrilled `ready`** — an issue promoted too early, offered a move back to `needs-planning` so unattended workers skip it until a human grills it.

triage only classifies. The fixes it can't make itself route to a sibling mode.

## Where the boundaries sit

**Worktrees and branches are gitkit's.** `start` and `close` bookend a worktree's life and both get it from [`gitkit`](./gitkit.md) — branch name, path convention, create-or-adopt, teardown. issuekit answers *"is this issue workable, and what does the tracker say now?"*; gitkit answers *"where does the code for this branch live?"*

**Labels are repokit's to create.** The label map here is a shared contract with [`repokit`](./repokit.md), duplicated on purpose because each skill must stand alone once installed. This repo's `make lint` diffs the two tables on every full run and errors on drift.

## Hands off to

By mode and by what came back. `create` with `ready` issues → `start` on the most valuable one. `create` with everything `needs-planning` → [`grillkit`](./grillkit.md), because nothing is workable unattended yet. `start` → the worktree and [`implementkit`](./implementkit.md), or [`afkkit`](./afkkit.md) for an unattended run. `close` → whatever this close unblocked, unless **the worktree survived dirty**, which outranks everything, because unlanded work in a stale worktree is what gets lost.

## Install

```sh
npx skills add mimukit/skills -s issuekit
```

Source: [`skills/issuekit/SKILL.md`](../../../skills/issuekit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`fd96414` on 2026-08-07._
