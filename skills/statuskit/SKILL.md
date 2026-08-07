---
name: statuskit
description: >-
  Survey a project read-only — git working tree, GitHub issues, open PRs, unfiled plans — into a one-screen dashboard that crowns one finish-first next move routed to the kit that does it, saved by default as a throwaway snapshot under docs/status/. Use when you sit down at a project and ask "what should I do next", "check project status", "what's next", "orient me", "write me a status file", or run "/statuskit" — add "just print it" or "no file" to skip the snapshot.
license: MIT
allowed-tools: Bash, Read, Write, Skill
metadata:
  internal: false
---

# statuskit

The front door you open when you sit back down at a project and ask *"where is this thing, and what's my single best next move?"* statuskit surveys the whole project **read-only** — git working tree, GitHub issues, open PRs, unfiled plans — prints a one-screen **status dashboard**, then does the opinionated part: it ranks the possible next actions by a **finish-first** rule and crowns exactly **one** as the move to make, routing you to the kit (or plain command) that does it.

It is a **read + advise** tool. It never commits, pushes, closes an issue, edits a PR, merges, relabels, or writes code — every mutation happens inside the kit it hands you off to, under that kit's own guard. That zero-mutation stance is the point: statuskit is safe to run anytime, as often as you like, to re-orient.

## When this fires

You want to orient before acting: "what should I do next", "check project status", "where's this project at", "what's next", "project status", "orient me", "/statuskit", or a bare "what's the state of this" after stepping away.

One boundary matters:

- **Not the tracker authority** — that's issuekit. statuskit reads issue *counts and state* to inform its recommendation and computes one cheap staleness signal. Detailed tracker health belongs to issuekit: issuekit answers "is my tracker honest?"; statuskit answers "where's this project and what do I do next?"

## The ranking principle: finish-first

Everything statuskit crowns derives from one rule — **"stop starting, start finishing"** (minimize work-in-progress). The crowned move is always whatever retires the most in-flight work for the least effort, *before* anything new is started.

Ties within a rung break on one of two signals, depending on what the rung asks you to do:

- **Resume or finish rungs** — crown the **most-recently-active** candidate (issue/PR `updatedAt`, or a branch's last-commit time). Recency is a proxy for context-switch cost, and switching cost is what you're minimizing when there's a half-built thing to switch back into.
- **Start-something rungs** — crown the highest **unblock leverage** (below), falling back to recency. Starting fresh means there's no context to preserve, so the cost recency measures is zero and the thing worth maximizing instead is throughput: how much work the repo can run in parallel after this one lands.

The rest become runners-up. Leverage never promotes a candidate *across* rungs — finish-first is the spine, and leverage only orders within it.

## Unblock leverage

**`unblocks(X)` is the number of open issues that become *fully workable* the moment X lands.** It's the answer to "which of these frees the most independent work next," and the file surfaces it as a sortable column on the two tables that already name names.

The word *fully* carries the rule. If #19 is blocked by both #12 and #23, closing #12 alone doesn't make #19 workable — it makes it less blocked, which is worth nothing to somebody looking for something to pick up. An issue counts toward `unblocks(#12)` only when removing #12 leaves its open-blocker set **empty**. Any looser definition inflates the number and points you at the wrong issue, which is worse than not ranking at all.

Leverage flows to PRs through what they close: `unblocks(PR #34)` is the leverage of the issues in its `closingIssuesReferences`. That's what turns the `Closes` column from a fact into a priority — a review that frees three issues outranks one that frees none, whatever their CI says.

Four rules keep the number honest:

- **Depth 1 only.** Don't count cascades. A transitive number assumes the intermediate issue gets *finished* rather than merely unblocked, which is a schedule prediction statuskit has no business making — and depth-1 is naturally cycle-safe, where a transitive walk needs a guard against `A blocked by B blocked by A`.
- **Only still-open blockers count**, the same rule the blocked set already follows.
- **A blocker may be a PR.** Issue and PR numbers share one namespace on GitHub, so `blockedBy: #34` can mean "waiting on a merge," and it resolves against the open-PR read.
- **No declared dependencies means no column.** When the repo's graph has no edges at all, every value is 0 and the column actively lies: it reads as "nothing unblocks anything" when the truth is "nobody wrote it down." Drop the column, say it once — *no dependencies declared; leverage unavailable* — and point at **issuekit**, because declaring them is tracker hygiene, not a survey's job.

Two states are **surfaced but never crowned**, because acting on them is a human gate, not a finish-first win statuskit should push:

- an approved + CI-green PR ("ready to merge") — merging is your call;
- a PR awaiting *someone else's* review — out of your hands.

Both appear in the dashboard as facts; neither becomes the #1 move.

## Procedure

### 1. Preflight — degrade per source, never fail wholesale

statuskit is **git-first**: git signals always drive it, and GitHub signals enrich it when available. Detect what's present and adapt, rather than bailing:

- **Not a git repo** → say so; skip everything git-derived. If there's no repo yet, the move is "start with `plankit`."
- **`gh` missing / unauthenticated / no remote** → drop to the **git-only ladder** below. This is a first-class mode, not an error — name the actual gap once (`gh` is not installed, run `gh auth login`, or add a GitHub remote) and carry on.
- **No `docs/plans/`** → skip the plans panel.
- **No shell at all** (e.g. a browser-based agent) → you can't run the survey; print the commands below for the user to run and reason from what they paste back.

### 2. Survey — collect signals read-only

Gather git always; gather GitHub only when `gh` is usable. All commands are read-only.

**git (always):**
- working tree — `git status --porcelain`, current branch, upstream ahead/behind, `git log @{u}.. --oneline` (unpushed — skip if the branch has no upstream set, which is itself the "push/publish" signal), `git stash list`, and any local branches carrying unmerged commits.
- **the base branch** — from **gitkit**, not an assumption that it's `main`. Every "is this a feature branch?" and "is it unmerged?" judgment below turns on it, and on a `develop`- or `trunk`-defaulted repo, assuming `main` misreads the whole dashboard.
- **branch → issue mapping** — resolve the current branch to a tracked issue from its open PR's `closingIssuesReferences` (the reliable signal, and already in hand from the PR read below); fall back to a branch-name heuristic. **The branch-name pattern comes from gitkit**, which named the branch in the first place (`issue-<n>-<slug>`) — read it there rather than keeping a second copy of the parser here, or a rename upstream leaves this one silently matching nothing. A bare `#N` or a slug matching an issue title are the looser fallbacks. When it stays unmappable, treat a dirty branch that isn't the base as *continue*, not *commit*.
- **worktrees** — when the survey needs to know where a branch's code lives, ask gitkit rather than reading paths. statuskit never creates or removes one; it only reports.

**GitHub (only when `gh` is usable):**
- issues — `gh issue list --state open --json number,title,labels,updatedAt,blockedBy,blocking`, bucketed by lifecycle label (`in-progress` / `ready` / `blocked` / `in-review`) plus an **unlabeled/other-status** bucket for repos without that vocabulary. Counts and the actionable set only — no drift detection. Treat recent unlabeled issues as candidates for classification or planning, not as invisible work.
- **the dependency graph** — `blockedBy` and `blocking` from that same call are GitHub's **native** issue dependencies, so the graph arrives already resolved: no body scraping, no per-issue fetch, no second round trip. Read them defensively (`(.blockedBy // []) | length`) rather than assuming a field layout, and when a repo doesn't use the feature fall back to the text convention — a `Blocked by #N` / `Depends on #N` / `Blocks #N` line in the body, extracted in the shell with `--jq` so bodies never enter context. Both directions describe the same edge; normalize to one.
- **the unblocked set** — every open issue that *isn't* blocked, kept as number + bucket + `updatedAt` + **`unblocks` count** + title rather than folded into a count. This is the pick-up-now list, and the dashboard prints it as a table so you can act on one without a second `gh` call. An issue is blocked when it has a still-open `blockedBy` entry, or carries the `blocked` label. Everything else is unblocked, including `in-progress` work you can resume. **Sort by `unblocks` descending, then most-recently-updated** — the highest-leverage thing to start belongs at the top, and recency survives as its own column rather than as the sort order.
- **the blocked set** — the other half of that same read, kept as number + what it's waiting on + title. The blocker comes from `blockedBy` when it's there, a `Blocked by #N` / `Depends on #N` line when it isn't, and is unnamed when all you have is the bare `blocked` label. Keep all three forms; an unnamed blocker is still a fact worth printing. Reporting what an issue *says* it's waiting on is a fact read, not a tracker verdict — the moment you're judging whether that blocker is still real, you've crossed into issuekit and should be pointing at it.
- open PRs — `gh pr list --json number,title,author,statusCheckRollup,reviewDecision,isDraft,updatedAt,closingIssuesReferences`, classified into: *your red / change-requested PR* (actionable), *approved + green* (surface-only), *awaiting others* (surface-only). Cap the list on large repos to stay fast; if a JSON field is rejected, check `gh pr list --json` with no value, which prints the field list your `gh` accepts.
- **what each PR closes** — `closingIssuesReferences` from that same call, not a `Closes #N` scrape of the body. It's GitHub's own resolved linkage, so it covers `Closes` / `Fixes` / `Resolves` in any casing and issues linked by hand in the UI, and it can't be fooled by the phrase appearing in a code block or a quoted review comment.
- **the waiting-for-review set** — every open non-draft PR whose review is still outstanding (`reviewDecision` empty or `REVIEW_REQUIRED`), kept as number + **what it closes** + **`unblocks` count** + CI state + author + `updatedAt` + title, in that order — the ID and the work it retires belong side by side, since together they're the whole reason to care about the row. Sort by `unblocks` descending, then most-recently-updated, the same way the unblocked set does. The dashboard prints these as a table, because "3 awaiting review" tells you nothing about which one is yours to nudge and which is somebody else's to answer. Record for each whether the next move is **yours** (you're a requested reviewer) or **theirs** (you authored it and are waiting).
- **stale-tracker signal** — one cheap cross-check: how many merged PRs have a linked issue still open. A single count, used only to decide whether "reconcile" ranks. **Never itemize which or why** — that's issuekit's job.

**plans (filesystem, available even without `gh`):**
- list canonical `docs/plans/plan-<slug>-YYYY-MM-DD.md` files (or wherever the repo keeps plans — an `rfcs/`, `specs/`, or documented location takes precedence); when `gh` is present, cross-check titles against the issue list to flag plans never turned into issues.

### 3. Rank — crown one finish-first move

Map the signals onto candidate actions, each tagged with its owning kit/command, then crown the highest applicable rung (most-recently-active breaks ties; the rest become runners-up). Pick the ladder by whether GitHub signals are available.

**Git-only ladder** (no `gh`):

| # | State | Move → |
|---|-------|--------|
| 1 | uncommitted work on a feature branch | continue / `commitkit` |
| 2 | unpushed commits | `git push` |
| 3 | a stash | restore or drop it |
| 4 | an unmerged local feature branch | finish it, or clean it up — `gitkit` |
| 5 | an unfiled plan doc | `implementkit` / `plankit` |
| 6 | clean on the base branch, nothing pending | start something (newest plan) / `plankit` |

**Full ladder** (`gh` available) — every git-only state has an explicit home below. *(Surfaced, never crowned: an approved+green PR; a PR awaiting others.)*

| # | State | Move → |
|---|-------|--------|
| 1 | your PR is red or change-requested | fix CI / address review — `mergekit fix` |
| 2 | in-progress issue whose branch you're on *(uncommitted work folds in here as "continue")* | resume / `implementkit` |
| 3 | orphaned work — uncommitted on the base branch or an untracked branch, or unpushed commits | `commitkit` / push |
| 4 | a stash | restore it to finish the work, or drop it if obsolete |
| 5 | an unmerged local feature branch | finish it, or clean it and its worktree up — `gitkit` |
| 6 | stale-tracker signal fired | reconcile — `issuekit sync` |
| 7 | a `ready` issue to start (highest `unblocks`, then most-recently-updated) | `issuekit start` (worktree via `gitkit`), then `implementkit` |
| 8 | an unlabeled/other-status issue needing classification | classify it — `issuekit triage` |
| 9 | an unfiled plan, or none at all | `issuekit create` / `plankit` |

When the owning kit isn't installed, name the **plain action** instead ("commit your changes" rather than "run commitkit") — statuskit routes, it doesn't require the ecosystem.

### 4. Output — dashboard, then one crowned move

Print a compact panel (one line per signal source, **empty panels suppressed**), then the ranked next-actions list with the **#1 move bolded** and its exact kit/command. Three of the panels carry a table under their count line — the unblocked issue IDs, the blocked issues with their blocker, and the PRs waiting for review — because those are the three places a bare number sends you straight back to `gh` to find out *which*. Keep it to one screen:

```
# Project status — <repo> · <branch> · YYYY-MM-DD

## Working tree  <clean | N uncommitted · M unpushed · stash K>

## Issues        in-progress N · ready N · blocked N · in-review N     (omit without gh)

Unblocked (N)  — highest leverage first
| Issue | Unblocks | Status | Last active | Title |
|---|---|---|---|---|
| #12 | 3 | ready | 2d | <title> |
| #31 | 1 | in-progress | 4h | <title> |
| #47 | 0 | unlabeled | 3w | <title> |

Blocked (N)
| Issue | Waiting on | Title |
|---|---|---|
| #19 | #12 | <title> |
| #23 | `blocked` label, no blocker named | <title> |

## Pull requests <open N — X awaiting review, Y CI-red, Z ready to merge>   (omit without gh)

Waiting for review (X)  — highest leverage first
| PR | Closes | Unblocks | CI | Author | Next move | Last active | Title |
|---|---|---|---|---|---|---|---|
| #34 | #12 | 3 | ✓ | you | theirs | 1d | <title> |
| #29 | #19, #23 | 0 | ✗ | @someone | yours | 6h | <title> |
| #38 | — | 0 | ✓ | you | theirs | 2w | <title> |

## Plans         <N filed · M unfiled>

## Next move
**→ <the #1 action>** — run `<kit / command>`.

Then:
- <runner-up> — `<kit / command>`
- <runner-up> — `<kit / command>`
- <runner-up> — `<kit / command>`
```

**A signal panel is one line.** Working tree, Issues, Pull requests, Plans — heading and counts on the same line, nothing following but a table. No paragraph, no parenthetical tracing a plan to the commit that shipped it, no clause explaining why a count matters: that reasoning is an argument for a move, so it belongs in the move, where the user can act on it. The entire value of the block is that four lines tell you where the project stands before you've started reading, and a panel that grows a second sentence has quietly become a report. `Next move` is the exception and the only one — it's the block everything above exists to produce.

**The panel set is closed.** Working tree, Issues, Pull requests, Plans, Next move — that is the dashboard, plus **at most one** repo-specific panel when the repo keeps a first-class queue the standard five genuinely can't see (an `IDEAS.md` backlog, an RFC index). It takes the same shape as the rest: a name, one line, sourced from a file the survey read. Anything you'd have to *run* to fill a panel is out of bounds — statuskit surveys read-only, so a build, test, or lint result is not a signal it has, and inventing a `Health` panel from one is both a mutation risk and a claim the survey can't back. Without this rule every run improvises a different set and no two days' files compare.

**The `Closes` column carries two signals.** Filled, it tells you what merging that PR actually retires — read against the `Blocked (N)` table it says which review is holding up which issue, which is the difference between "3 PRs awaiting review" and "reviewing #34 frees #19." Empty (`—`) is the more valuable reading: that PR will merge and leave its issue open, which is precisely the condition the stale-tracker signal counts after the fact. Seeing it *before* the merge costs nothing and is far cheaper than reconciling afterwards. Print `—`, never omit the cell — a blank reads as "not checked."

**`Unblocks` sorts, `Last active` informs.** The two actionable tables lead with leverage because a column you have to scan is not a priority list — the row you should pick up next belongs on the first line, not somewhere in the middle where a big number happens to sit. Recency doesn't disappear, it moves into its own `Last active` column as a compact relative stamp (`4h`, `2d`, `3w`), so "what did I touch last" is still answerable at a glance without being the thing that decides the order. Say `— highest leverage first` on the count line so the ordering is declared rather than inferred; a table that silently changed its sort is a table you'll misread once and distrust after. The `Blocked (N)` table keeps its recency sort and gains no leverage column: nothing in it can be picked up, so ranking it by what it would free is a number with nowhere to go.

All three tables list **every** row that qualifies — the whole point is completeness, so don't trim to the interesting ones. On a repo big enough to blow the one-screen budget, cap at 10 rows and close with a `+N more` line naming the `gh` command that shows the rest; never truncate silently. An empty set drops the table but keeps its count line, so "0 waiting for review" still reads as a surveyed fact rather than a missing panel.

Runner-ups get **one line each, naming exactly one issue or PR** — never "start #12, #19 and #23" on a single line. This is the same rule the snapshot's checkboxes follow (see [Write the status snapshot](#5-write-the-status-snapshot--the-default-not-an-offer)), and it holds here so the printed list and the file agree item for item.

Drop any panel with nothing to show (no PRs → no PR line; no `gh` → omit Issues + PRs and say so once).

### 5. Write the status snapshot — the default, not an offer

**Write the file every run.** A terminal dashboard scrolls away and its ranked moves can't be ticked off; the same content on disk reads better and doubles as the run's to-do list. So don't ask permission — write it, then say where it went in one line:

> Saved to `docs/status/status-<repo-slug>-YYYY-MM-DD.md` — scratch file, gitignored, not committed.

**Skip only when asked.** "Just print it", "no file", "don't write anything", "screen only", "/statuskit --no-file" — honor that for the run and print the dashboard alone. A skip applies to that run only; it isn't a standing preference unless the user says so or the repo's agent-guide file (`CLAUDE.md` or an equivalent) does. Skip silently too when there's no writable filesystem (below).

**Where it goes.** `docs/status/status-<repo-slug>-YYYY-MM-DD.md` — a short lowercase kebab-case slug (normally the repo name; use a narrower one such as the branch or issue when the snapshot covers a slice of the project) and the ISO creation date. Create `docs/status/` if it doesn't exist.

**One file per day — always update, never add.** Before writing, list `docs/status/` and look for a snapshot already carrying **today's date**. If one exists, that's the file: update it in place, keeping its existing name even if this run would have picked a different slug. Only when the directory has nothing dated today do you create a new file. A status file is a point-in-time read, and three of them from one afternoon is how a scratch directory becomes archaeology — worse, it splits the user's ticked boxes across files that all look current. If today's snapshot genuinely covers a different project in a monorepo, make the slug specific to that project and match on slug + date instead; there is no case where the same project gets two files on the same day, so never fall back to a sequence suffix.

**Updating means merging, not overwriting.** Re-derive the whole survey from git and GitHub — never trust what the file says — then carry over the **checked state** of every move that's still open, matching on its key (below) and nothing else. Rewrite every other word from the fresh survey: a move whose wording changed completely is the same move if its key matches, and a move that kept its wording by coincidence is a different one if its key doesn't. A ticked move that no longer applies goes to `Done today`; an unticked one that no longer applies just drops.

**What it contains.** The dashboard as printed, with two additions the file earns:

- a **provenance line** recording when the snapshot was taken, against which commit, and how many times it's been rewritten today (`Snapshot: 2026-07-23 14:20 · <branch> @ <short-sha> · run 3 today (first 09:05)`) — without it a stale file reads as current, and without the run count an afternoon rewrite is indistinguishable from the morning's original;
- the ranked moves as a **checkbox list** so the file works as a to-do, crowned move first and each carrying its kit/command:

```markdown
## Next moves

- [ ] **<the #1 move> — unblocks 3** — `<kit / command>` <!-- k: issue-12 -->
- [ ] <runner-up> — unblocks 1 — `<kit / command>` <!-- k: pr-34 -->
- [ ] <runner-up> — `<kit / command>` <!-- k: plan-debugkit -->

## Done today

- [x] <move, as it read when it was ticked> <!-- k: issue-9 -->

## Surfaced, not queued

- #34 approved + CI-green — merge when you're ready (`mergekit`)
- #29 awaiting @someone's review
```

**Every move carries a key.** The trailing `<!-- k: … -->` comment is what the merge matches on, and it exists because the visible text can't be matched on: the wording is regenerated every run, so a move that survives the survey comes back phrased differently and its tick is silently lost. Moves with an issue or PR number are the easy half; the ones without — provision the labels, file the backlog — are exactly where text matching fails and where a user's tick most needs to survive. The key is invisible when rendered because the file is read by a human and the key means nothing outside it.

Draw keys from a fixed vocabulary, never an improvised slug, or the key drifts run to run the same way the prose does:

| Move's subject | Key |
|---|---|
| an issue | `issue-12` |
| a PR | `pr-34` |
| a plan doc | `plan-<slug>` — the plan's own slug |
| a local branch | `branch-issue-12-retry-budget` |
| a stash entry | `stash-0` |
| a ladder rung with no subject | one fixed slug per rung — `push`, `reconcile`, `triage`, `repo-labels` |

**A move that frees work says so.** When a queued move has `unblocks` above zero, carry the count into its line — `**Start #12 — unblocks 3** — \`issuekit start 12\``. The checkbox list is where the user actually chooses, often hours after the tables scrolled past, and "unblocks 3" is the whole argument for why this item outranks the one below it. Omit the clause at zero rather than writing `unblocks 0`; the absence says it.

The key never leaves the file. Don't put it in a commit message, a branch name, an issue body, or anywhere else: it's a join key between two versions of one gitignored scratch file, and exporting it into permanent history would make durable artifacts reference a throwaway one. The linkage that *does* belong in git already exists — `Closes #12` on the PR, which the survey reads anyway.

**Every move must have a signal that retires it.** A queued move is something the next survey can observe as finished — the PR merged, the issue closed, the labels now exist, the tree went clean. Completion is detected that way, not from the ticks; the tick is only a human's own mid-day annotation, which is why the merge has to preserve it and why it is never evidence. A move with no observable signal ("decide whether this repo dogfoods its own workflow") can never drop off on its own, so it re-ranks every run forever and the only thing that ever silences it is a tick that today's file takes to the grave. Those aren't next actions, they're decisions — route them to `plankit` or file them with `issuekit create`, and let the resulting issue be what appears here. If you can't name what would make a move disappear, it doesn't belong on the list.

**Ticked moves go to `Done today`, not the bin.** When the fresh survey no longer supports a move the user had ticked, that's the move getting *finished* — record it under `## Done today` rather than deleting it with the rest of the stale ladder. One file per day only pays off if the day accumulates in it; a file that shows nothing but what's left reads identically at 6pm and 9am, which is the one impression a status file must never give. Drop the section entirely on a day with nothing done.

**One task per checkbox — never bundle.** Every item is a single thing the user can finish and tick off on its own, so it names **exactly one** issue or PR. "Start #12, #19, and #23 — `issuekit start`" is three items, not one; so is "triage the 4 unlabeled issues." When a rung of the ladder applies to several issues at once, split it into one item per issue, each carrying that issue's own number, title, and command, and keep them in the rung's order. The whole reason the snapshot is a checkbox list is that a half-done item is invisible — a box covering three issues can't be ticked until all three are done, and until then it reads exactly like nothing has happened. The same rule governs the `Surfaced, not queued` list: one line per PR, never a summary line. If the split makes the list long, that's the true length of the work; cap it the way the tables do — most-recently-updated first, then a `+N more` line — rather than by merging items back together.

All three tables — unblocked, blocked, waiting for review — go into the file as printed. They're the part of the snapshot that ages into a worklist, and a file that kept only the counts would be strictly worse than the terminal it replaced. Beyond the file's own additions, don't inflate it into a report the dashboard didn't contain — same survey, same closed panel set, durable form.

**It's disposable.** This file is scratch, not a tracked artifact: add `docs/status/` to `.gitignore` before writing the first one (say so in the same line), and leave it uncommitted. Commit it only if the user explicitly asks — then it's their call, and honor it without arguing. Skip the `.gitignore` edit if the path is already ignored or the repo has no `.gitignore` you should be touching.

**No filesystem?** Print the snapshot as a codeblock with the canonical `docs/status/status-<repo-slug>-YYYY-MM-DD.md` path so the user can save it themselves.

## Notes

- **Zero mutation, always.** statuskit surveys and advises; it never changes git or GitHub state. If a recommendation needs a mutation, it routes to the kit that owns it — that kit previews and gets approval on its own. The one thing it writes is the status snapshot — a gitignored scratch file that touches no git or tracker state, which is why writing it by default is still zero mutation.
- **Route, don't launch.** Routing means *naming* the kit and its one-line command — statuskit never invokes the kit for you; the user launches it. Naming "run `issuekit sync`" and then calling the kit yourself would restart mutation in the same breath as "orient me," breaking the read-only stance.
- **Route, don't require.** Every recommendation degrades to a plain command when its kit isn't installed. statuskit is useful in a bare repo with only git.
- **Hold the issuekit line.** Display issue counts, the unblocked set by ID, the blocked set with what each says it's waiting on, and the ready/in-progress set; compute the one staleness boolean to rank "reconcile." Listing IDs is not crossing the line — it's the same read, printed usefully, and it saves a round trip to `gh` before acting on the crowned move. What stays on issuekit's side is *judgment* about the tracker: never render an itemized health verdict, and the moment you're explaining which issues are stale and why, that's issuekit `triage`/`sync` and statuskit should be pointing at it, not doing it.
- **gitkit owns the git facts.** The base branch, the branch-name convention, and where a worktree lives all come from gitkit — statuskit reads them and reports. Keeping a second copy of any of them here is how a dashboard starts confidently describing a repo that no longer matches it.
- **On-demand, no state.** Every run is a fresh read — statuskit keeps no `STATUS.md` at the repo root and no last-run cache, and it never *reads* a snapshot back to shortcut the survey. The one thing it takes from an existing file is which boxes were already ticked; the survey itself is always re-derived from git and GitHub. A `docs/status/` file is output for a human (or the next agent), not memory statuskit trusts.
