# Plan — statuskit

## Context

The kit collection has grown into a full workflow — `plankit → grillkit → issuekit → implementkit → prkit → commitkit`, plus satellites (repokit, reviewkit, qakit, verifykit, orcakit…). Each kit answers *one* question well, but nothing answers the **meta** question you ask when you sit back down at a project: *"Where is this thing right now, and what's my single best next move?"* Today you reconstruct that by hand — `git status`, scroll the issue tracker, check open PRs, remember which `plan-*.md` was never filed — then decide which kit to run.

**statuskit** is that missing front door. It surveys the whole project read-only (git working tree, GitHub issues, open PRs + CI, unfiled plans), prints a **status dashboard**, and ranks the next actions with **one clearly-bolded top move** — then routes you to the right existing kit to do it (issuekit, implementkit, prkit, commitkit, plankit…). It never mutates anything itself; the kit it hands off to does, behind that kit's own guards.

**Boundary with issuekit (settled, load-bearing):** statuskit is the **broad, read-only survey + router**; issuekit stays the **deep authority on the GitHub tracker**. statuskit does *not* re-implement drift detection, health verdicts, or lifecycle mutation. When the tracker needs reconciling it *routes* — and it earns the right to say so with a single cheap boolean (see the decisions table), never an itemized health report. The overlap is deliberately limited to *presentation* (both may show the ready/in-progress set); zero tracker logic is duplicated. Put simply: **issuekit answers "is my tracker honest?"; statuskit answers "I just sat down — where's this project and what do I do next?"**

**Success:** running `/statuskit` in any repo prints an at-a-glance whole-project state and one unambiguous recommended next action, with the exact kit (or plain command) to run for it — so the user never has to reconstruct project state by hand or guess which kit fits. It stays useful with **zero `gh`** (git-only ladder), and gets richer when the GitHub tracker is available.

## Design decisions (settled)

Settled with the user across a planning session and a grillkit hardening pass:

| Decision | Resolution |
|----------|-----------|
| **Name** | `statuskit` — functional word ("status") leads, `kit` appended, per the kit convention. Searchable on "status". |
| **Core role** | **Recommend + route.** Survey → report → rank next actions → name the right kit/command. **Read-only itself** — never commits, closes issues, edits PRs, merges, or writes code. Every mutation happens inside the kit it hands off to, under that kit's own guard. Not auto-execute. |
| **Ranking principle** | **Finish-first / minimize-WIP** — *"stop starting, start finishing."* The whole ladder derives from this one principle: the crowned move is always whatever retires the most in-flight work for the least effort, before anything new is started. |
| **Merge stance** | **Surface, never crown.** An approved + CI-green PR appears in the dashboard as a fact, but statuskit never makes "merge" the #1 move — merge is a human-only gate. Same for a PR **awaiting someone else's review** (out of your hands) → surfaced, not crowned. |
| **Uncommitted-work rule** | **Key on branch context.** A dirty branch that maps to an in-progress issue → crown "**continue #N**" (resume), with commit as the implicit next beat — never a separate "commit!" nag. "Commit/bank" is crowned **only for orphaned work**: a dirty `main`, or a branch with no tracked issue. |
| **gh dependency** | **git-first, GitHub-enriches.** A real git-only finish-first ladder is a **first-class path** (not a degraded stub) — statuskit delivers a genuinely useful crowned move with zero `gh`. GitHub signals (issues, PRs, CI) layer *on top* when available. |
| **issuekit line** | statuskit runs **one cheap boolean** — a count of merged PRs whose linked issue is still open — purely as a ranking signal ("tracker may be stale → run `issuekit sync`"). It **never itemizes** which/why (no stale/orphaned/zombie report). issuekit owns detection + rendering + fix. Boolean to rank; issuekit to render. |
| **Tiebreak within a rung** | **Most-recently-active.** When several candidates share a rung (two red PRs, three `ready` issues, several dirty branches), crown the one touched last — issue/PR `updatedAt`, or a branch's last-commit time — for the lowest context-switch cost. Remaining candidates become runners-up. |
| **Routing mechanics** | **Name + one-line command; no auto-launch.** statuskit prints "run `issuekit sync`" / the plain command — it does **not** invoke the kit for you (preserves the read-only stance + portability). When the owning kit isn't installed, it names the **plain action** instead ("commit your changes"). |
| **Output shape** | **Dashboard + one top move.** A compact status panel (one section per signal source, empty panels suppressed), then a ranked next-actions list with the **#1 recommendation bolded** and the exact kit/command to run it. |
| **Visibility** | **Public** (`internal: false`) — portable, self-contained, no repo-relative links, no hard `make`/`AGENTS.md` dependency. |
| **Mutation stance** | Zero. statuskit is a **read + advise** tool — that's what makes it a safe, re-runnable "sit down and orient" command. |

## Approach

Single lean `SKILL.md`, no satellite files — the logic is survey + rank + route, all expressible in prose + a handful of read-only shell snippets. No bundled scripts (nothing fragile enough to earn one; `git`/`gh` are the host's).

### Phase 1 — Frontmatter + triggers
- `name: statuskit`, `metadata.internal: false`, `license: MIT`.
- `allowed-tools: Bash, Read` — read-only, no Edit/Write, reinforcing the no-mutation stance.
- `description`: front-load "Survey a project's status and recommend the single best next move…" then a pushy **"Use when …"** clause naming the phrasings: "what should I do next", "check project status", "where's this project at", "what's next", "project status", "orient me", "/statuskit".

### Phase 2 — Body: identity + boundary
- One paragraph on the job: read-only whole-project survey → dashboard → one ranked top move (finish-first) → route to the right kit.
- State the two things it is **not**, explicitly: **not the tracker authority** (that's issuekit — statuskit routes to it via a single boolean, never re-implements it) and **not a doer** (it recommends and hands off; the invoked kit acts). This paragraph is what keeps the issuekit overlap from creeping.

### Phase 3 — Preflight + graceful degradation
Detect what's available before surveying; degrade *per source*, never fail wholesale:
- Not a git repo → say so, skip everything git-derived, offer greenfield guidance (e.g. "no repo yet → `plankit`").
- **`gh` missing / unauthenticated / no remote → drop to the git-only ladder** (Phase 5a) — this is a *first-class* mode, not an error. Note the gap once ("issues/PRs unavailable — `gh auth login` for the fuller picture") and carry on.
- No `docs/plans/` → skip the plans panel.
- No shell at all (browser agent) → print the survey commands for the user to run and reason from what they paste.

### Phase 4 — Survey (read-only signal collection)
One subsection per signal source, each a small set of read-only commands. **git signals are always collected; gh signals only when available.**
- **git working tree** — `git status --porcelain`, current branch, upstream ahead/behind, `git log @{u}.. --oneline` (unpushed), `git stash list`, local branches with unmerged commits. This block alone powers the git-only ladder.
- **branch→issue mapping** — resolve the current branch to a tracked issue via an open PR's `Closes #N` (reliable); fall back to a branch-name heuristic; when unmappable, treat a dirty non-`main` branch as "continue," not "commit."
- **GitHub issues** *(gh only)* — `gh issue list --state open --json number,title,labels,updatedAt` → bucket by lifecycle label (in-progress / ready / blocked / in-review). Counts + the actionable set only — no drift detection.
- **open PRs** *(gh only)* — `gh pr list --json number,title,statusCheckRollup,reviewDecision,isDraft,updatedAt` → classify: your red/change-requested PR (actionable), approved+green (surface-only), awaiting others (surface-only). Cap the list for speed on big repos.
- **stale-tracker boolean** *(gh only)* — one cross-check: count merged PRs whose linked issue is still open. A single number, used only to decide whether "reconcile" ranks; never itemized.
- **unfiled plans** — list `docs/plans/plan-*.md` (filesystem — available even without gh); cross-check titles against `gh issue list` *when gh is present* to flag plans never turned into issues.

### Phase 5 — Rank + recommend (the finish-first core)
Map collected signals onto candidate actions, each tagged with its owning kit/command, then crown the highest rung (most-recently-active breaks intra-rung ties; the rest become runners-up). Two ladders, chosen by whether gh is available:

**5a — git-only ladder** (no `gh`):
1. **Continue uncommitted work on a feature branch** → resume / `commitkit`.
2. **Push unpushed commits** → `git push`.
3. **Restore or drop a stash** → `git stash pop` / `drop`.
4. **Finish or clean an unmerged local branch** → resume / delete.
5. **Build an unfiled plan doc** → `implementkit` / `plankit`.
6. **Clean on `main`, nothing pending** → start something (newest plan) / `plankit`.

**5b — full ladder** (gh available) — git-only rungs still apply; GitHub rungs interleave by finish-first value:
- *Surfaced, never crowned:* an approved+green PR ("ready to merge"); a PR awaiting others' review.
1. **Fix your red / change-requested PR** → address CI or review feedback (`implementkit` / `prkit`).
2. **Resume the in-progress issue** whose branch you're on *(uncommitted work folds in here as "continue")* → resume / `implementkit`.
3. **Bank orphaned work** — uncommitted on `main`/untracked branch → `commitkit`; unpushed → push.
4. **Reconcile the tracker** — only if the stale-boolean fired → `issuekit sync`.
5. **Start the most-recently-updated `ready` issue** → `implementkit` / `orcakit`.
6. **Feed the pipeline** — an unfiled plan → `issuekit create`; no plans at all → `plankit`.

Present the **dashboard first**, then the ranked list with the **#1 move bolded** + its exact command/kit. When the owning kit isn't installed, name the plain action instead.

### Phase 6 — Output format
```
# Project status — <repo> (<branch>)

## Working tree
<clean | N uncommitted, M unpushed, stash: K>

## Issues        in-progress N · ready N · blocked N · in-review N     (omitted without gh)
## Pull requests <open N — X awaiting review, Y CI-red, Z ready to merge>   (omitted without gh)
## Plans         <N filed · M unfiled>

## Next move
**→ <the #1 action>** — run `<kit / command>`.

Then: <2–4 ranked runner-up actions, each with its kit>
```
Terse, scannable, one screen. Suppress empty panels (no PRs → drop the line; no gh → drop Issues + PRs and say so once).

### Phase 7 — Wire-up (repo housekeeping)
- Add a `statuskit` row to the README Skills table (public).
- Add `statuskit` to `skills.sh.json` — likely a new **"Orientation / Workflow"** group, or fold into an existing one if a better fit emerges (per AGENTS.md, same change).
- statuskit is a fresh idea, **not** in IDEAS.md — no backlog row to remove.
- `make lint name=statuskit` clean; live-test with `make link` in a fresh session against this repo (real git + issues + plans), *and* in a git-only repo to exercise the 5a ladder.

## Open questions

Small, authoring-time refinements — the load-bearing decisions are settled above:

- **Branch→issue mapping fallback** — precise branch-name heuristic when there's no open PR to read `Closes #N` from (match `#N`, `issue-N`, `<slug>` against issue titles?). Safe default already fixed: unmappable dirty non-`main` branch → "continue," not "commit."
- **PR/CI fetch depth** — exact `gh` JSON fields and a list cap to stay fast on large repos without losing the red-vs-green-vs-awaiting classification.
- **Caching** — default is on-demand with no persisted state; revisit only if a `--since-last-run` diff proves worth the state it'd have to write.

## Non-goals

- **No mutation.** statuskit never commits, pushes, closes issues, edits PRs, merges, relabels, or writes code. It surveys and advises; the routed-to kit acts under its own guard. This is the property that makes it safe to run anytime.
- **No tracker ownership.** It does not create, sync, or triage issues, and does not re-implement issuekit's drift detection or lifecycle logic — it computes one boolean and routes to issuekit for all of that.
- **No merge nudging.** Merging (and acting on a PR awaiting others) is a human gate — surfaced as a fact, never crowned.
- **No implementation or planning content.** It points you at implementkit / plankit; it doesn't write the code or the plan itself.
- **No new status artifact / no status file** by default — it prints to the session; it doesn't maintain a `STATUS.md` or persist state.
- **No bundled scripts / satellite files** — the whole skill is prose + read-only `git`/`gh` snippets; nothing here is fragile or large enough to earn one.
