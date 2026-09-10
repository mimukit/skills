# Plan — afkkit

_Created 2026-07-24. Grilled 2026-07-24._

## Context

The kit workflow takes one issue through ~10 manual invocations: `plankit → grillkit → issuekit → orcakit → implementkit → commitkit → reviewkit → (fix) → qakit → commitkit → prkit → issuekit`. Every hop needs the owner at the keyboard, even though the middle of the chain — implement, commit, review, fix, QA plan, PR — is exactly the part an agent can run alone once the issue is well-specified.

**afkkit** ("away from keyboard") is the missing orchestrator: hand it a groomed `ready` issue and it runs that middle span unattended, ending at an open PR with a QA plan and the issue flipped to `in-review`. The human gates stay where human judgment lives — planning/grilling *before* (the `ready` label is the entry contract), PR review and merge *after*. A companion lifecycle change gives the owner a symmetrical queue: a new **`needs-planning`** label marks issues awaiting a human plan/grill session, so `gh issue list --label needs-planning` is "work that needs me" while afkkit drains "work that doesn't."

**Success:** the owner grills a plan in the morning, runs `afkkit all`, and comes back to N open PRs (each with documented assumptions and a QA plan) plus M cleanly-escalated issues sitting in the `needs-planning` queue with their open questions spelled out — and nothing half-broken published in between.

## Design decisions (settled)

Settled with the owner in a grillkit session, 2026-07-24:

| Decision | Resolution |
|----------|-----------|
| **Autonomous span** | **Ready issue → PR open.** Input: a `ready` issue. Output: open PR + QA plan + issue `in-review`. Planning/grilling stays human (upfront); PR review/merge stays human (after). A PR-feedback responder (watch the PR, apply review comments) is an explicit **later phase** — the design must not preclude it, v1 must not attempt it. |
| **Mechanism** | **One conductor session + per-step subagents.** The owner runs afkkit in a normal Claude Code session; the session conducts, and each pipeline step runs as an Agent-tool subagent working in the worktree path with a per-step model override. No headless `claude -p`, no Orca-terminal driving (brittle, and orcakit deliberately excludes fleet automation). |
| **Trigger** | `afkkit <n>` (one issue) and `afkkit all` (**sequential** batch over every `ready` issue). An escalated issue never sinks the batch — escalate and continue. No parallel mode in v1. |
| **Thin-spec gate** | **Split: decisions vs mechanics.** A cheap pre-implementation subagent classifies spec gaps. Missing *decisions* (product choices, trade-offs — things grillkit would ask the owner) → escalate before any code is written. Missing *mechanics* (file names, minor edge cases a competent implementer fills uncontroversially) → proceed, recording **every assumption** for the PR body. |
| **Review→fix loop** | **Max 2 fix rounds.** implement → review → fix → re-review → fix. Only severity-ranked **blockers** force a re-review round; nits are fixed once and noted. Blockers surviving the cap, or tests that won't go green → escalate. |
| **Escalation contract** | Never open a PR from a failed run. Keep the worktree and its commits intact, comment the precise stuck-state on the issue (open questions / failing test / surviving blocker), continue the batch. **Spec-gate escalation flips `in-progress → needs-planning`** (routes to the owner's grill queue); **execution failures keep `in-progress`** (spec was fine, execution stuck — the comment and batch summary carry the detail). |
| **Models** | **Default table + inline override, no config file.** gate/implement/fix/commit/qa/pr = sonnet; review = the **conductor session's model** (owner launches the session on fable/opus, so review inherits the strongest model). Override by saying it at invocation ("afkkit 42, implement on opus"). |
| **verifykit** | **Out of v1.** Unattended browser automation is the flakiest step in the chain; qakit's manual QA plan is the v1 verification artifact. Revisit once the rest is proven. |
| **Signal** | **GitHub + session report, no new infrastructure.** Success = the PR itself (GitHub already notifies); blocked = issue comment + label visible on return or via GitHub mobile. The conductor prints a final batch summary (N PRs opened, M escalated, links). No push notifications, no run-report artifact. |
| **New label: `needs-planning`** | A pre-`ready` lifecycle state: "needs a human plan/grill session before it is workable." Lifecycle reads needs-planning → ready → in-progress → in-review; `blocked` stays orthogonal (dependency-driven). Provisioned by repokit like the rest of the vocabulary. |
| **`ready` is earned by grilling** | At creation, issuekit labels an issue `ready` **only when its source plan was grilled** — signaled by a grill stamp grillkit writes into the plan file when hardening it (a `Grilled: YYYY-MM-DD` line), or by the owner explicitly saying so. Everything else — including issues from an ungrilled plankit doc — starts `needs-planning`. Prerequisites still stamp `blocked`. |
| **Name** | **afkkit** — "away from keyboard" is literally the purpose; searchable on "afk"; no known dev-tool collision; double letters have precedent (grillkit). |
| **Visibility** | **Public** (`internal: false`) — it sequences companion kits that are all publicly on skills.sh. Portable: leans on companions when installed, names the gap and stops when not (an orchestrator without its steps degrades by refusing clearly). |

## Approach

One new skill plus surgical edits to four existing skills and the directory metadata. No bundled scripts — the orchestration is prose driving the Agent tool and companion skills.

### Phase 1 — `skills/afkkit/SKILL.md` (new, the bulk of the work)

Frontmatter per the repo template: `name: afkkit`, `license: MIT`, `metadata.internal: false`, description front-loading "Use when …" with triggers: "afkkit", "run issue #N unattended", "work the ready issues while I'm away", "autopilot this issue", "take this issue to a PR without me".

The body specifies the per-issue pipeline (each step naming its subagent model and its companion kit, invoked when installed):

1. **Preflight** — `gh` authed + inside a repo; warn if the conductor session isn't on a top-tier model (review inherits it). Companion-kit check: name any missing kit and stop rather than improvising its job.
2. **Start** — orcakit `start <n>`. Its `ready`-only guard and adopt-check *are* the entry gate; afkkit adds zero worktree logic. Adopt-and-continue when the worktree already exists (the re-run path after a gate escalation is grilled back to `ready`).
3. **Spec gate** (sonnet) — read the issue + relevant code; classify gaps per the thin-spec decision. Open decisions → escalate now (cheapest failure point): comment the exact grill-questions, flip `in-progress → needs-planning`, next issue. Mechanics-only gaps → proceed, returning the assumptions list.
4. **Implement** (sonnet, cwd = worktree) — implementkit against the issue spec; the repo's test+build gate must pass.
5. **Commit** (sonnet) — commitkit.
6. **Review** (conductor model) — reviewkit on the branch diff, severity-ranked findings.
7. **Fix loop** — blockers → implementkit fix (sonnet) → commitkit → re-review; max 2 fix rounds, then escalate per the contract.
8. **QA plan** (sonnet) — qakit → `docs/qa/qa-<slug>-YYYY-MM-DD.md`, committed.
9. **PR** — push the branch; prkit opens the PR with the gate's assumptions list, unresolved nits, and the QA-plan pointer in the body. prkit already advances the linked issue to `in-review` on open — afkkit relies on that, falling back to `gh issue edit` only if prkit is absent.
10. **Report** — per-issue outcome line; for `all`, the final batch summary (N PRs opened, M escalated, links).

Also in the body: the escalation contract as its own section (both label outcomes), the model table with the inline-override rule, and non-goals (below). No step-number cross-references — heading anchors only.

### Phase 2 — lifecycle-label plumbing (four existing skills)

- **repokit** — add `needs-planning` to the canonical label map (repokit's descriptions are canonical; issuekit mirrors). Suggested row: color `E99695`, description "needs a human plan/grill session before it is workable". Slots before `ready` in the table's left-to-right lifecycle order.
- **issuekit** — mirror the new row in its lifecycle-label table; creation-mode rule: `ready` only when the source plan carries the grill stamp or the user explicitly says it's grilled/ready, else `needs-planning`; prerequisites still get `blocked`. Sync/triage treat `needs-planning` as a first-class status label (zombie-label checks, unmarked-issue classification).
- **grillkit** — when folding settled decisions back into a plan file, stamp it with a `Grilled: YYYY-MM-DD` line near the top (update the date on re-grills) so issuekit can detect grill provenance.
- **orcakit** — no behavior change (its `ready`-only guard already excludes `needs-planning`); mention the new label where it lists the lifecycle vocabulary.

### Phase 3 — wire-up (repo housekeeping)

- `skills.sh.json` — add `afkkit`; likely a new group (e.g. "Autonomy / Orchestration") since no existing group fits an orchestrator, else the best-fitting existing one.
- README Skills table row for afkkit, if the README carries one.
- `make lint` clean; `make link` afkkit for live testing.

## Verification

1. `make lint` — frontmatter markers, anchor links, portability checks pass across all touched skills.
2. **Happy path (live dry-run):** in a real repo, file a small grill-stamped `ready` issue; run `afkkit <n>` in a fresh session on a strong model; confirm end-to-end: worktree created, gate passes, implement/commit/review/fix rounds bounded, QA doc committed, PR opens with assumptions + QA pointer, issue lands `in-review`, summary prints.
3. **Escalation path:** run afkkit on a deliberately thin `ready` issue (a real open decision in it); confirm it stops at the gate — no PR, issue flipped to `needs-planning`, comment lists the grill-questions, batch continues to the next issue.
4. **Label plumbing:** repokit provisions `needs-planning`; issuekit files an ungrilled description as `needs-planning` and a grill-stamped plan's issues as `ready`; grillkit's stamp appears when it hardens a plan file.

## Non-goals

- **No planning or grilling.** afkkit never invents product decisions — thin specs go back to the human queue. plankit/grillkit remain interactive and out of the unattended path.
- **No PR-feedback responding, no merge, no `finish`.** The span ends at PR open; responding to review comments is the designed-for later phase, merging is a human gate, and orcakit `finish` runs after merge — all outside v1.
- **No parallel batches, no verifykit, no notifications** in v1 — sequential issues, qakit-only verification, GitHub as the sole signal surface.
- **No new worktree/tracker logic.** orcakit owns the worktree lifecycle, issuekit the tracker, prkit the PR; afkkit only sequences them and owns the escalation policy.
- **No config file.** Model routing is a table in the skill plus inline override at invocation.
