# plan: delete orcakit

**Status:** deprecation shipped 2026-08-02 — issuekit's `start` and `close` modes and the afkkit/statuskit rerouting landed with the gitkit caller refactor, and orcakit is now a stub that warns and routes. **No skill, script, or config depends on it**; the only live references left are the README row and its `skills.sh.json` entry, both of which advertise the deprecation on purpose. The deletion itself is still deferred; preconditions 2 and 3 below are unmet.
**Date:** 2026-08-02
**Depends on:** [plan-gitkit-worktree-convention-2026-08-02.md](plan-gitkit-worktree-convention-2026-08-02.md)

**What already landed, and why early.** The gitkit rollout could not reroute afkkit's front door without a `ready` guard to point it at — gitkit has none — so the `start` mode was pulled forward rather than leaving afkkit's safety property unenforced for the duration. orcakit still exists, now as a deprecated wrapper delegating to issuekit and gitkit, with no `orca` CLI calls and no hard-coded `origin/main`.

## Why

orcakit exists to sequence two systems at the two moments they meet: a GitHub issue tracker and Orca worktrees. Its own summary: *"orcakit doesn't add tracker or worktree behavior — it **sequences** the two."*

The gitkit plan removes the Orca half. Worktrees become native `git worktree` on both machines, with Orca demoted to an observer that surfaces externally-created worktrees in its UI. Once that lands, orcakit has no Orca to sequence.

What remains is: *guard that the issue is `ready`, flip `ready → in-progress`, and on finish close the issue, tick the parent checklist, and unblock dependents.* That is issuekit's stated job. orcakit's `finish` already concedes it — *"This is exactly issuekit's `sync` job: **invoke the issuekit skill when it's installed**"* — and delegates when issuekit is present. So the residue is not new work for issuekit; it is work issuekit already does, currently reached through a wrapper.

A skill whose worktree half is gitkit's and whose tracker half is issuekit's has nothing left to own.

## Where each piece goes

| orcakit today | Destination |
|---|---|
| `start` — `ready`-label guard | **issuekit** (new `start` mode) |
| `start` — adopt check for an existing worktree | **gitkit** (branch-keyed lookup) |
| `start` — derive branch name `issue-<n>-<slug>` from the issue title | **gitkit** (owns branch naming) — but the *title* comes from issuekit |
| `start` — create the worktree off fresh base | **gitkit** |
| `start` — flip `ready → in-progress` | **issuekit** |
| `finish` — confirm the PR merged (hard precondition) | **issuekit** |
| `finish` — preview + confirm before mutating | **issuekit** |
| `finish` — close issue, tick parent checklist, unblock dependents | **issuekit** `sync` (already does this) |
| `finish` — remove the worktree | **gitkit** |
| Orca↔GitHub issue link (`--issue`) | **dropped** — Orca-only metadata with no VPS equivalent |
| `--no-parent` lineage handling | **dropped** — an Orca-specific concern |
| `orca-cli` skill dependency | **dropped** |

issuekit currently has three modes (`create`, `sync`, `triage`). This adds a fourth, `start`, and extends `sync` with the merged-PR precondition check. `sync` already closes issues and unblocks dependents, so the extension is small.

The split is clean because the seam is real: issuekit answers *"is this issue workable, and what does the tracker say now?"*; gitkit answers *"where does the code for this branch live?"*. Neither needs the other's internals — issuekit hands gitkit a branch name, gitkit hands back a path.

## Preconditions — do not start until all are true

1. gitkit ships and every caller is refactored onto it.
2. Both machines have run the gitkit workflow for a sustained stretch, including at least one full `ready → worktree → PR → merge → teardown` cycle **on the VPS**, where Orca does not exist.
3. The Orca external-worktree observation path is confirmed working locally (the open question in the gitkit plan).
4. ~~afkkit no longer instructs the human to run `orcakit start <n>`.~~ **Met 2026-08-02** — afkkit now points at issuekit `start`.

## Mechanical checklist

- [x] Add `start` **and `close`** modes to `skills/issuekit/SKILL.md` — done 2026-08-02. **Two deviations from the table below.** (1) The merged-PR precondition and preview gate went into a dedicated mode rather than into `sync`: `sync` sweeps the whole tracker for drift and never touches the filesystem, while the new mode lands one named issue and tears its worktree down — folding a worktree deletion into a whole-tracker sweep would have been the wrong blast radius. It reuses `sync`'s reconciliation sections rather than restating them. (2) The mode is named **`close`**, not `finish`, because that is the verb the owner actually uses when giving the command. orcakit keeps its own `finish` action name (its published trigger) and points at `issuekit close`.
- [x] Reduce `skills/orcakit/SKILL.md` to a deprecation stub — done 2026-08-02. Warns, maps each old action to its replacement, invokes it, and stops if issuekit is absent rather than falling back.
- [ ] Delete `skills/orcakit/` — after a release or two of the stub.
- [ ] `skills.sh.json` — remove `"orcakit"` from the "Git & GitHub" group. **Keep it listed while deprecated**, so anyone browsing the directory sees the notice instead of a silent disappearance.
- [ ] `README.md` — remove the orcakit row (marked deprecated and pending removal in the meantime).
- [x] `skills/afkkit/SKILL.md` — all references retargeted to issuekit `start` + gitkit, 2026-08-02.
- [x] `skills/statuskit/SKILL.md` — the `ready`-issue rung now routes to `issuekit start` + gitkit, 2026-08-02.
- [ ] `docs/plans/plan-orcakit-2026-07-22.md` — leave in place as history; add a status line pointing at this plan.
- [ ] `make lint` clean.

## Open question: orcakit is published

orcakit is `internal: false` and discoverable on skills.sh, so people may have it installed. Deleting the directory removes it from discovery but does nothing to existing installs — those keep working and keep calling `orca worktree create`, which is fine in isolation (it is still a valid Orca command) but will silently diverge from the gitkit convention.

Options, undecided:

- **Delete outright.** Simplest. Existing installs quietly rot.
- **Ship a deprecation release first** — rewrite `SKILL.md` to a short notice pointing at issuekit + gitkit, leave it for a release or two, then delete. Costs a cycle, gives anyone who installed it a signal.

~~Lean toward the deprecation release if telemetry shows any installs; delete outright if it is only you.~~

**Decided 2026-08-02: deprecation release.** `SKILL.md` is now a stub that prints a warning, maps the old action to its replacement, and invokes it. Two things fell out of writing it:

- **The stub carries no fallback.** The earlier wrapper kept inline `gh` commands for when issuekit is absent; those are gone. A deprecated skill quietly reimplementing its replacement is the exact divergence the deprecation exists to end, so a missing issuekit is now a stop-and-report, not a second code path.
- **Its `description` was narrowed to fire only on the literal name.** It previously advertised "start issue #N" and "spin up a worktree for #N" — the same triggers issuekit `start` now claims. Two skills competing for one phrase is a live routing bug, and the deprecated one winning would put a warning in front of a working command. orcakit now fires only on "orcakit"; issuekit owns the English.

## Risks

- **afkkit is the tightest coupling.** Its entire safety property is stated in terms of orcakit's `ready` guard being the entry gate. That property must survive the move to issuekit `start` verbatim, or afkkit's unattended mode loses its human-judgment gate.
- **Losing the Orca↔GitHub link is a real, accepted downgrade.** Locally, worktrees currently carry a live issue link that Orca's UI renders. After this, the only issue↔worktree signal is the `issue-<n>-…` branch name. That is the portable key and it works on both machines, but the UI affordance goes away.
- **Do not bundle this with the gitkit rollout.** If gitkit's convention needs adjusting after real use, having orcakit still present is a working fallback. Delete only once the new path is proven.
