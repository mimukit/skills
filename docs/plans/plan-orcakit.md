```markdown
# Plan — orcakit

A thin glue skill that bridges a GitHub issue to an Orca worktree and back.

## Context

The saasaloy workflow already has two skills that each own one half of "take an
issue from ready to landed":

- **issuekit** owns the **what/when** — which issue to work, gated by lifecycle
  labels (`ready` / `blocked` / `in-progress` / `in-review`), and `sync` to
  reconcile the tracker after a PR merges.
- **orca-cli** owns the **where** — an isolated Orca worktree + branch + agent
  terminal, plus worktree comments for checkpoints and base-ref control.

What's missing is the ~30 lines of glue between them: derive a branch name from a
conventional issue title, guard on the `ready` label before spawning a worktree,
flip labels at start, and run `issuekit sync` + remove the worktree at land. Today
that's done by hand (Option 1 below), which is fine for one startable issue but
starts costing discipline the moment two issues are workable in parallel.

**Why now:** the saasaloy CLI roadmap has a dependency graph (`#5 → #6,#7 →
#8,#9 → #10`). The first real 2-way parallel moment is when #6/#7 unblock. That's
the point where scripted glue stops being a convenience and starts preventing
mistakes — so orcakit should exist *before* #6/#7 unblock.

**Success:** `start #N` turns a `ready` issue into a clean worktree branched off
`origin/main` with its label flipped, and `finish #N` reconciles the tracker and
removes the worktree — with the `ready` guard making it impossible to start a
`blocked` issue.

## Design decisions (settled)

These were worked out in a prior session and are carried forward as settled.

| Decision | Resolution |
|----------|-----------|
| Build vs. defer | Build orcakit (this is "Option 2"). Manual two-step (Option 1) is fine only for a single startable issue; full poll-and-spawn automation (Option 3) is deferred to Phase 2. |
| What orcakit owns | Nothing on either side — it **sequences** issuekit and orca-cli. It is glue, not a new system. Heavy lifting stays in the two existing skills. |
| Action surface | Two actions mirroring the two events where the systems meet: `start <n>` and `finish <n>`. |
| The safety property | orcakit **never creates a worktree for a `blocked` issue**. The `ready` guard is the whole point — because `blocked → ready` only happens via `issuekit sync` after a prerequisite merges, the dependency graph is enforced for free and Orca can never get ahead of it. |
| Branch base | Branch off `origin/main` every time, passing `--base-branch origin/main` explicitly (the repo base-ref is already pinned there too) — never branch off a sibling feature branch. |
| No implement-by-default | `start` only *prepares* the workspace. Implementing is implementkit's job, run separately inside the worktree. Reserve an optional `--agent` flag for later Option-3 automation, off by default. |
| Branch naming | `issue-<n>-<slug>`, where `<slug>` derives from the conventional title `type(scope): summary` (strip the `type(scope):` prefix, kebab-case, cap ~50 chars at a word boundary, drop trailing hyphen). Empty slug → bare `issue-<n>`. The `<n>` prefix guarantees cross-issue uniqueness, so no tie-break logic is needed. The repo `gitUsername` is now empty, so branches are bare (no `mimukit/` prefix). |
| Where it lives | In `mimukit/skills` as a **public, portable** skill (`internal: false`), alongside issuekit — not repo-local to saasaloy. No hard-coded repo-id (orca infers the repo from cwd/current worktree); conventions inlined, no repo-relative links. |
| Issue↔worktree link | `start` always passes `--issue <n>` to `orca worktree create`, producing a real Orca→GitHub link. `--issue`, `--base-branch`, and `--comment` are native flags, so worktree creation + checkpoint comment fold into **one** call. (The earlier `linkedIssue: null` was just the missing flag, not a CLI limit.) |
| Re-run behavior | Idempotent **adopt & report**. If a worktree for #N already exists, `start` doesn't recreate or error — it reports the existing worktree and stops. A label already at `in-progress` is fine. |
| Adopt detection | Detection order: (1) a worktree whose `linkedIssue == N`, then (2) a worktree named `issue-<n>-…`. Bounded to those two signals — `start` never fuzzy-matches arbitrary names. |
| `finish` precondition | A merged PR is a **hard** precondition. With no merged PR, `finish` runs neither `sync` nor worktree removal and reports what's blocking. A forced teardown stays a deliberate manual orca-cli call. |
| issuekit dependency | The label flip (`ready → in-progress`) is inline `gh`. `finish`'s reconciliation **invokes the issuekit skill when present, with an inline `gh` fallback**, so orcakit still works with only `gh` installed — no hard skill dependency (keeps it portable). |
| Confirmation stance | `start` runs straight through after the `ready` guard (cheap, reversible). `finish` **previews and waits for an OK** before closing the issue and removing the worktree (destructive, outward-facing) — mirroring issuekit's safety stance where it matters. |

## Approach

### Phase 0 — Prerequisites (one-time, mostly done)

- [x] Repo base-ref pinned to `origin/main` (`orca repo set-base-ref`) — every
      worktree inherits latest main.
- [x] `gitUsername` cleared so branches are bare `issue-N-slug` (no namespace prefix).
- [ ] Confirm the lifecycle labels orcakit reads/writes exist (`ready`,
      `in-progress`) — they do in this repo; provisioned by repokit.
- [ ] **Owner to-do (manual, one-time):** the pre-existing worktree
      `cli-clack-ui-18` for #18 follows neither the `issue-18-…` name nor the
      `--issue` link, so adopt-detection won't see it. Migrate it once by hand —
      either set `--issue 18` on it or recreate it to convention — before
      exercising `start #18`. This stays outside orcakit's logic on purpose.

### Phase 1 — Author the skill scaffold

Create the skill via skill-creator with the frontmatter description below, so it
triggers on the right phrases and slots between issuekit and implementkit.

```
name: orcakit
description: Bridge a GitHub issue to an Orca worktree and back. Turns a
  `ready` issuekit issue into an isolated Orca worktree branched off
  origin/main, and reconciles the worktree when the PR lands. Use when the
  user says "start issue #N", "spin up a worktree for #N", "finish #N",
  "orcakit", or wants an issue's isolated workspace created or torn down.
```

### Phase 2 — `start <n>` action

The start-event glue. Runs straight through after the guard (steps are cheap and reversible — no per-step confirmation). Steps, in order:

1. **Guard** — read the issue's labels; refuse unless labeled `ready`. This is
   the safety property; everything else is mechanical.
2. **Adopt check** — look for an existing worktree for #N: first any with
   `linkedIssue == N`, then any named `issue-<n>-…`. If found, **report it and
   stop** (idempotent adopt — never recreate or error). Otherwise continue.
3. **Derive branch name** — `issue-<n>-<slug>` from the conventional title
   (cap ~50 chars at a word boundary; empty → `issue-<n>`).
4. **Create worktree + seed comment — one call** — off `origin/main` with a
   real issue link:
   `orca worktree create --name issue-<n>-<slug> --base-branch origin/main --issue <n> --comment "starting #N (title)"`.
5. **Flip label** — `ready → in-progress` via inline `gh` (`gh issue edit <n> --remove-label ready --add-label in-progress`).

Delegates: step 4 → orca-cli; steps 1, 3, 5 → inline `gh`.

### Phase 3 — `finish <n>` action

The land-event glue. Destructive, so it **previews and waits for an OK** before mutating. Steps:

1. **Confirm the PR merged** for this issue (`gh pr list`/`gh pr view`). A merged
   PR is a **hard precondition** — if none is found (no PR, or PR still open),
   `finish` does nothing and reports exactly what's blocking. No forced teardown.
2. **Preview + confirm** — show what will happen (`PR #X merged → close #N, tick
   parent checklist, remove worktree <name>`) and wait for the OK.
3. **Reconcile** — `issuekit sync` to close #n, tick the parent epic checklist,
   and flip any dependents `blocked → ready`. Invoke the issuekit skill when
   present; otherwise fall back to the equivalent inline `gh` commands.
4. **Remove the worktree** via orca-cli (`worktree rm`).

Delegates: step 3 → issuekit sync (inline `gh` fallback); step 4 → orca-cli.

### Phase 4 — Validate on a real issue

Exercise `start` then `finish` against a live `ready` issue (e.g. #18, the CLI
UI/DX work) end to end: verify the worktree is created off fresh main, the label
flips, the guard rejects a `blocked` issue, and `finish` reconciles + removes.

## Resolved (grillkit)

The Phase-1 open questions, settled in a grillkit session and folded into the
[Design decisions](#design-decisions-settled) table above:

- **Issue↔worktree linking** → always pass `--issue <n>`. `--issue`,
  `--base-branch`, `--comment` are native `orca worktree create` flags; the
  earlier `linkedIssue: null` was just the missing flag. Create + comment fold
  into one call.
- **Existing off-convention worktree** → adopt-detection is bounded to
  `linkedIssue == N` then the `issue-<n>-…` name; `cli-clack-ui-18` (#18) is a
  one-time manual owner to-do (see Phase 0), not skill logic.
- **Idempotency / re-runs** → idempotent adopt & report: existing worktree for #N
  → report and stop, never recreate or error; label already `in-progress` is fine.
- **`finish` when PR not merged** → hard-fail. No `sync`, no removal; report what's
  blocking. A forced teardown is a deliberate manual orca-cli call.
- **Naming collisions** → the `<n>` prefix guarantees uniqueness, so no tie-break.
  `issue-<n>-<slug>`, cap ~50 chars at a word boundary, empty → `issue-<n>`.
- **Where the skill lives** → `mimukit/skills`, public & portable (`internal:
  false`): no hard-coded repo-id (orca infers repo from cwd), conventions inlined.
- **issuekit dependency (soft spot)** → label flip is inline `gh`; `finish`'s sync
  invokes the issuekit skill when present with an inline `gh` fallback — no hard
  dependency, stays portable.
- **Confirmation stance (soft spot)** → `start` runs straight through after the
  `ready` guard; `finish` previews and waits for an OK before its destructive steps.

## Non-goals

- **Implementing the feature.** `start` prepares a workspace; writing code is
  implementkit's job, run separately inside the worktree.
- **Launching agents by default.** No auto-spawned agent on `start`; the `--agent`
  flag is reserved and off until Option-3 automation is justified.
- **Poll-and-spawn / fleet automation (Option 3).** Scheduled Orca automations
  polling `gh issue list --label ready` and auto-launching agents, and
  orchestration-driven coordinator loops over the dependency DAG, are deferred to
  Phase 2's wider fan-out.
- **Owning GitHub or Orca logic.** orcakit adds no new tracker or worktree
  behavior; it only sequences issuekit and orca-cli.

```

