# plan: reactivate orcakit as the Orca workspace reconciler

**Status:** shipped 2026-08-05 — the SKILL.md rewrite and every doc/config reference landed in one change.
**Date:** 2026-08-05
**Supersedes:** [plan-orcakit-deletion-2026-08-02.md](plan-orcakit-deletion-2026-08-02.md)
**Related:** [plan-gitkit-worktree-convention-2026-08-02.md](plan-gitkit-worktree-convention-2026-08-02.md)

## Why the deletion was cancelled

The deprecation reasoning was sound for the orcakit that existed: it *sequenced* the tracker and Orca-created worktrees, and once gitkit made worktrees native git on every machine, there was no Orca half left to sequence. That half is gone for good — issuekit owns `start` and `close`, gitkit owns worktrees, and none of that moves back.

What the deletion plan didn't notice is that a **different** job appeared in the same move, one nothing owns: reconciling Orca's *view* of the worktrees with what the tracker says. Orca discovers gitkit worktrees on its own, but discovery gives it a path and a branch and nothing else. The card has no issue on it. The status stays `in-progress` forever. The workspace survives the merge that ended its reason to exist. Every one of those is drift between two systems that are both working correctly.

## What was verified before designing (2026-08-05, Orca 1.4.169)

Empirically, on the owner's machine, with a throwaway worktree created and removed:

| claim | result |
|---|---|
| Orca discovers a worktree created by plain `git worktree add` under `~/worktrees/<repo>/<branch>` | **yes** — every registered repo carries `externalWorktreeVisibility: "show"` |
| A discovered worktree is addressable by selector | **yes** — both `branch:<name>` and `path:<abs>` resolve it |
| Metadata can be attached to a discovered worktree | **yes** — `orca worktree set --issue 99 --comment …` succeeded on one Orca never created |
| `git worktree remove` is enough to retire the Orca entry | **yes** — the selector returned `selector_not_found` and the listing dropped it, with no `orca` call |
| Discovery is instant | **no** — `worktree show` resolved it well before `worktree list` did; treat as eventually consistent |
| `workspaceStatus` vocabulary | `todo`, `in-progress`, `in-review`, `done`, `archived` |
| The per-setup worktree base path is readable back | **no** — `--worktree-base-path` is settable via `project setup-update`, but `project setups --json` does not echo it |

The fourth row is the one the design rests on: Orca is a pure **observer** of external worktrees, so orcakit can own the metadata layer without ever touching the git layer.

## The boundary

**Git owns the worktree; Orca owns its card.** orcakit never creates a worktree for real work and never removes a gitkit one through the vendor CLI. It writes only what lives inside Orca — linked issue, status, comment, display name — plus the two Orca-side resources git can't express: live terminals and repo archive/setup hooks.

Two documented exceptions, both narrow and both stated in the skill:

1. **Removing an Orca-*created* workspace** (under `~/orca/workspaces/…`) goes through `orca worktree rm --run-hooks`, because Orca has an archive hook and terminal sessions bound to it and its `rm` sequences all three. Removing that one with git first orphans the metadata and skips the hook.
2. **`align` creates one throwaway worktree** with `orca worktree create`, purely to read back the resulting path, and removes it in the same breath — because the base-path semantics aren't documented and aren't readable back.

**orcakit never writes to the tracker.** It reads issue and PR state to judge a workspace, and when it finds a merged PR with an open issue it reports the drift and routes to issuekit `close`, which does that job properly.

gitkit's "no vendor worktree CLI" rule was amended rather than broken: the prohibition now names *creating and removing* a worktree, and explicitly allows a companion skill to reconcile a vendor's metadata layer, since that layer has no git equivalent to diverge from.

## Modes

| mode | does | mutates |
|---|---|---|
| `list` | joins Orca's workspaces against issues, PRs, and git state; one table, one verdict per row | nothing |
| `link` | attaches `--issue` parsed from `issue-<n>-<slug>`, and a `workspaceStatus` derived from real PR/issue state | Orca metadata, batch-previewed |
| `clean` | removes workspaces whose PR merged and issue closed — gitkit teardown for git-native, `orca worktree rm --run-hooks` for Orca-native | disk, batch-previewed, one confirm |
| `align` | points a repo's Orca worktree base path at `$WORKTREE_ROOT` so future Orca-created worktrees land in the convention | Orca config |

`clean`'s disqualifiers are hard and always reported as skips rather than dropped: dirty tree, unpushed commits or no upstream, the main worktree, the worktree you're standing in, and live Orca terminals. Never `--force`.

## Decisions settled

| decision | answer | why |
|---|---|---|
| Visibility | **public** (`internal: false`) | Orca is a real product with other users; the skill degrades honestly (no `orca` → no-op) even though it is vendor-coupled by nature |
| Reap ergonomics | **batch preview, one confirm**, named `clean` not `sweep` | clearing a ten-workspace backlog behind ten prompts defeats the purpose; `clean` is the verb the owner actually uses |
| Coupling to issuekit | **none** — standalone janitor | issuekit `close` is public and portable; a vendor-conditional branch inside it would break on every machine without Orca. Orca drops the entry by itself when `close` tears the worktree down, so nothing is missed |
| Path convergence | **`align` included** | two worktree roots means classifying by path forever; one root retires the heuristic |

## Files changed

- `skills/orcakit/SKILL.md` — full rewrite from deprecation stub to four-mode reconciler.
- `skills/gitkit/SKILL.md` — the vendor-CLI prohibition narrowed to creation/removal, with the metadata carve-out stated.
- `README.md`, `WORKFLOW.md` — the orcakit row and side-kit entry rewritten.
- `skills.sh.json` — group description reworded; orcakit stays in "Git & GitHub".
- `scripts/lint.sh` — orcakit dropped from `HANDOFF_EXEMPT`; it now has real hand-offs to enforce.
- `docs/plans/plan-orcakit-deletion-2026-08-02.md` — marked superseded.

## Known limits

- **`externalWorktreeVisibility` has no CLI flag.** A repo set to `hide` makes every mode blind to its gitkit worktrees, and the only fix is the Orca UI. The skill reports the repo by name rather than treating an empty result as an empty worktree root.
- **`align` is unverified until someone runs it.** Whether Orca appends the repo name to the base path is undocumented, which is why the mode reads the answer back from a throwaway instead of asserting it. If the throwaway is declined, the skill says "set but not verified".
- **Discovery lag is real.** Anything that reads `worktree list` right after a git mutation must tolerate a stale answer.
