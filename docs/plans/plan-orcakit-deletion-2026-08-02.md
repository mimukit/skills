# plan: delete orcakit

**Status:** deferred — tracked now, implemented later
**Date:** 2026-08-02
**Depends on:** [plan-gitkit-worktree-convention-2026-08-02.md](plan-gitkit-worktree-convention-2026-08-02.md)

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
4. afkkit no longer instructs the human to run `orcakit start <n>` — see below.

## Mechanical checklist

- [ ] Add `start` mode to `skills/issuekit/SKILL.md`; extend `sync` with the merged-PR precondition and the preview-and-confirm gate.
- [ ] Delete `skills/orcakit/`.
- [ ] `skills.sh.json` — remove `"orcakit"` from the "Git & GitHub" group.
- [ ] `README.md` — remove the orcakit row (currently *"bridge a `ready` GitHub issue to an isolated Orca worktree and back"*).
- [ ] `skills/afkkit/SKILL.md` — four references to fix: the input contract, the manual-prerequisite paragraph, the `afkkit all` batch paragraph, and the worktree-discovery line. Each becomes issuekit `start` + gitkit rather than `orcakit start`.
- [ ] `skills/statuskit/SKILL.md` — the ladder routes a `ready` issue to `implementkit` / `orcakit`; retarget to issuekit / gitkit.
- [ ] `docs/plans/plan-orcakit-2026-07-22.md` — leave in place as history; add a status line pointing at this plan.
- [ ] `make lint` clean.

## Open question: orcakit is published

orcakit is `internal: false` and discoverable on skills.sh, so people may have it installed. Deleting the directory removes it from discovery but does nothing to existing installs — those keep working and keep calling `orca worktree create`, which is fine in isolation (it is still a valid Orca command) but will silently diverge from the gitkit convention.

Options, undecided:

- **Delete outright.** Simplest. Existing installs quietly rot.
- **Ship a deprecation release first** — rewrite `SKILL.md` to a short notice pointing at issuekit + gitkit, leave it for a release or two, then delete. Costs a cycle, gives anyone who installed it a signal.

Lean toward the deprecation release if telemetry shows any installs; delete outright if it is only you.

## Risks

- **afkkit is the tightest coupling.** Its entire safety property is stated in terms of orcakit's `ready` guard being the entry gate. That property must survive the move to issuekit `start` verbatim, or afkkit's unattended mode loses its human-judgment gate.
- **Losing the Orca↔GitHub link is a real, accepted downgrade.** Locally, worktrees currently carry a live issue link that Orca's UI renders. After this, the only issue↔worktree signal is the `issue-<n>-…` branch name. That is the portable key and it works on both machines, but the UI affordance goes away.
- **Do not bundle this with the gitkit rollout.** If gitkit's convention needs adjusting after real use, having orcakit still present is a working fallback. Delete only once the new path is proven.
