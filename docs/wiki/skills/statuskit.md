# statuskit

Survey a project read-only into a one-screen dashboard, then crown one finish-first next move routed to the kit that does it.

**Reach for it when** you sit back down at a project and ask "where is this, and what's my single best next move?"

| | |
|---|---|
| Modes | single procedure |
| Tools | `Bash`, `Read`, `Write`, `Skill` |
| Writes | `docs/status/status-<slug>-YYYY-MM-DD.md` — gitignored scratch |
| Visibility | public |

## What it does

statuskit surveys the whole project **read-only** — git working tree, GitHub issues, open PRs, unfiled plans — prints a one-screen dashboard, then does the opinionated part: it ranks the possible next actions and crowns exactly **one**, routing you to the kit or plain command that does it.

It's a **read-and-advise** tool. It never commits, pushes, closes an issue, edits a PR, merges, relabels, or writes code. Every mutation happens inside the kit it hands off to, under that kit's own guard.

That zero-mutation stance is the point: statuskit is safe to run anytime, as often as you like, to re-orient.

## Three panels name names

Most of the dashboard is counts, which is right for signals you only need a feel for. Three aren't:

- **Unblocked issues** — a table of every open issue that isn't blocked, by ID, with its bucket and title. "Blocked" means the `blocked` label, or a `Blocked by #N` line pointing at a still-open issue in repos that don't use the label.
- **Blocked issues** — the other half of that same read, with what each one says it's waiting on. It comes free, and "2 blocked" doesn't tell you whether they're waiting on a PR that merged this morning.
- **PRs waiting for review** — a table of every open non-draft PR whose review is still outstanding, with **what it closes** right beside its number, then its CI state, its author, and whether the next move is yours or theirs.

The reason these three get rows instead of a number is that a count sends you straight back to `gh` to find out *which* — and that round trip is exactly the friction statuskit exists to remove. All three list everything that qualifies; on a repo large enough to blow the one-screen budget they cap at 10 rows and say so with a `+N more` line rather than truncating silently.

**The two actionable tables sort by `Unblocks`, not recency.** A column you have to scan isn't a priority list — the row to pick up next belongs on the first line, not wherever a big number happens to land. Recency doesn't vanish; it becomes its own `Last active` column (`4h`, `2d`, `3w`), so "what did I touch last" stays answerable without deciding the order. The count line declares the sort (`— highest leverage first`), because a table that silently changed its ordering is one you misread once and distrust after. The blocked table keeps its recency sort and gets no leverage column: nothing in it can be picked up, so ranking it by what it would free is a number with nowhere to go.

The `Closes` column comes from GitHub's own `closingIssuesReferences`, not a `Closes #N` scrape of the PR body, so it catches every keyword spelling and issues linked by hand in the UI. Filled, it tells you what merging that PR retires — read against the blocked table, it turns "3 PRs awaiting review" into "reviewing #34 frees #19." Empty is the more useful reading: that PR will merge and leave its issue open, which is exactly what the stale-tracker signal counts *after* the fact. Seeing it beforehand costs nothing and beats reconciling later.

Note the asymmetry with the ladder: the waiting-for-review table is **surfaced, not crowned**. Seeing the PRs is useful; being told to go chase a reviewer is not a finish-first move.

## The panel set is closed

Working tree, Issues, Pull requests, Plans, Next move — that's the dashboard, plus **at most one** repo-specific panel when the repo keeps a first-class queue the standard five genuinely can't see, like an `IDEAS.md` backlog. And a panel is **one line**: its heading and counts on the same line, nothing under it but a table.

Both rules exist because the panel block's entire value is that four lines tell you where the project stands before you've started reading. A panel that grows a second sentence has become a report, and the sentence it grows is almost always an argument for a move — which belongs in the move, where you can act on it. A panel that has to be *run* to fill (a lint result, a test count) is out of bounds twice over: statuskit's survey is read-only, so it's a claim the survey can't back. Without the closed set, every run improvises a different one and no two days' files compare.

## The ranking principle: finish-first

Everything it crowns derives from one rule — **stop starting, start finishing**. The crowned move is whatever retires the most in-flight work for the least effort, *before* anything new is started.

Ties within a rung break on one of two signals, depending on what the rung asks of you. **Resume and finish rungs** go to the most-recently-active candidate, because recency proxies context-switch cost and that cost is what you're minimizing when there's a half-built thing to switch back into. **Start-something rungs** go to the highest unblock leverage, because starting fresh means there's no context to preserve — the cost recency measures is zero, and what's worth maximizing instead is how much work the repo can run in parallel once this lands.

## Unblock leverage

**`unblocks(X)` is the number of open issues that become *fully workable* the moment X lands** — the answer to "which of these frees the most independent work next." It rides as a sortable column on the two tables that already name names.

The word *fully* is doing the work. If #19 is blocked by both #12 and #23, closing #12 makes #19 *less blocked*, which is worth nothing to somebody looking for something to pick up. So an issue counts toward `unblocks(#12)` only when removing #12 empties its open-blocker set. A looser count inflates the number and points you at the wrong issue, which is worse than not ranking at all.

Leverage reaches PRs through what they close, which is what turns the `Closes` column from a fact into a priority: a review that frees three issues outranks one that frees none, whatever their CI says.

Four things keep the number honest:

- **Depth 1 only** — no cascades. A transitive count assumes the intermediate issue gets *finished* rather than merely unblocked, which is a schedule prediction a survey has no business making. Depth-1 is also cycle-safe for free, where a transitive walk needs a guard against `A blocked by B blocked by A`.
- **Only still-open blockers count.**
- **A blocker may be a PR** — issue and PR numbers share one namespace on GitHub, so `blockedBy: #34` can mean "waiting on a merge."
- **No declared dependencies means no column at all.** A column of zeros lies: it reads as "nothing unblocks anything" when the truth is "nobody wrote it down." statuskit drops it, says so once, and points at [`issuekit`](./issuekit.md) — declaring dependencies is tracker hygiene, not a survey's job.

The graph itself is free: `gh issue list --json blockedBy,blocking` returns GitHub's **native** issue dependencies on a call statuskit already makes, so there's no body scraping and no second round trip. Repos not using the feature fall back to a `Blocked by #N` line in the body, extracted in the shell so bodies never enter context.

Leverage never promotes a candidate *across* ladder rungs. Finish-first stays the spine; leverage only orders within it.

Two states are **surfaced but never crowned**, because acting on them is a human gate rather than a finish-first win:

- an approved and CI-green PR — merging is your call;
- a PR awaiting *someone else's* review — out of your hands.

Both appear as facts. Neither becomes the #1 move.

## It degrades per source, never wholesale

statuskit is **git-first**: git signals always drive it, GitHub signals enrich it.

| Missing | Effect |
|---|---|
| Not a git repo | says so, skips everything git-derived. No repo at all → the move is to start with [`plankit`](./plankit.md) |
| `gh` missing, unauthenticated, or no remote | drops to the **git-only ladder** — a first-class mode, not an error. Names the actual gap once and carries on |
| No `docs/plans/` | skips the plans panel |
| No shell | prints the commands for you to run, reasons from what you paste back |

## The two ladders

**Git-only** (no `gh`):

| # | State | Move |
|---|-------|------|
| 1 | uncommitted work on a feature branch | continue / [`commitkit`](./commitkit.md) |
| 2 | unpushed commits | `git push` |
| 3 | a stash | restore or drop it |
| 4 | an unmerged local feature branch | finish or clean up — [`gitkit`](./gitkit.md) |
| 5 | an unfiled plan doc | [`implementkit`](./implementkit.md) / [`plankit`](./plankit.md) |
| 6 | clean on base, nothing pending | start something |

**Full** (`gh` available) — every git-only state has an explicit home here:

| # | State | Move |
|---|-------|------|
| 1 | your PR is red or change-requested | [`mergekit`](./mergekit.md) `fix` |
| 2 | in-progress issue whose branch you're on | resume / [`implementkit`](./implementkit.md) |
| 3 | orphaned work — uncommitted on base, untracked branch, unpushed commits | [`commitkit`](./commitkit.md) / push |
| 4 | a stash | restore or drop |
| 5 | an unmerged local feature branch | [`gitkit`](./gitkit.md) |
| 6 | stale-tracker signal fired | [`issuekit`](./issuekit.md) `sync` |
| 7 | a `ready` issue to start (highest `unblocks` first) | [`issuekit`](./issuekit.md) `start`, then implement |
| 8 | an unlabeled issue needing classification | [`issuekit`](./issuekit.md) `triage` |
| 9 | an unfiled plan, or none at all | [`issuekit`](./issuekit.md) `create` / [`plankit`](./plankit.md) |

When the owning kit isn't installed, it names the **plain action** instead — "commit your changes" rather than "run commitkit". statuskit routes; it doesn't require the ecosystem.

## Two lines it holds

**gitkit owns the git facts.** The base branch, the branch-name convention, and where a worktree lives all come from [`gitkit`](./gitkit.md). Keeping a second copy of any of them is how a dashboard starts confidently describing a repo that no longer matches it.

**issuekit owns the tracker.** statuskit displays issue counts, the unblocked set by ID, and computes *one* cheap staleness boolean — how many merged PRs have a linked issue still open — used only to decide whether "reconcile" ranks. It never itemizes which issues are stale or why. The moment you're explaining that, it's [`issuekit`](./issuekit.md)'s job, and statuskit should be pointing at it rather than doing it.

The split in one line: issuekit answers *"is my tracker honest?"*; statuskit answers *"where's this project and what do I do next?"*

## The snapshot is written by default

A terminal dashboard scrolls away, and its ranked moves can't be ticked off. So the file gets written every run — no permission asked — with one line saying where it went.

It's **disposable**: `docs/status/` goes in `.gitignore` before the first write, and the file stays uncommitted.

**One file per day.** Before writing, statuskit looks for a snapshot already dated today and updates that one in place, keeping its existing name. It only creates a file when there isn't one. A status file is a point-in-time read, and keeping five from one afternoon is how a scratch directory becomes archaeology — worse, it splits your ticked boxes across files that all look current.

Three things the file adds over the printed dashboard:

- a **provenance line** — when the snapshot was taken, against which commit, and how many times it's been rewritten today. Without it a stale file reads as current, and without the run count an afternoon rewrite is indistinguishable from the morning's original.
- the ranked moves as a **checkbox list**, so the file doubles as a to-do.
- a **`Done today`** section, so the day accumulates.

**One task per checkbox.** Each item names exactly one issue or PR, so "start #12, #19 and #23" is three items rather than one. A box covering three issues can't be ticked until all three are done, and until then it reads exactly like nothing has happened — which defeats the only thing a checkbox is for. When that makes the list long, that's the real length of the work; it caps the same way the tables do instead of merging items back together.

"Just print it" or "no file" skips it for that run only.

## Why the checkboxes carry a hidden key

Each move ends with an invisible `<!-- k: issue-12 -->`, and an update matches on that key and nothing else.

The alternative — matching on the move's text — quietly loses your ticks. A move that survives the survey gets re-ranked and *re-worded*, so `Author debugkit` comes back as `Write the debugkit skill` and the box you ticked at 9am is empty at 2pm. The moves with an issue or PR number were never the hard case; it's the ones without — provision the labels, file the backlog into the tracker — where text is the only handle and where your tick most needs to survive. Keys come from a fixed vocabulary (`issue-12`, `pr-34`, `plan-<slug>`, `branch-…`, `stash-0`, or one fixed slug per ladder rung) so they don't drift the way prose does.

The key **never leaves the file** — not into a commit message, a branch name, or an issue body. It's a join key between two versions of one gitignored scratch file, and putting it in permanent history would leave durable artifacts referencing a throwaway one. The linkage that does belong in git already exists: `Closes #12` on the PR, which the survey reads anyway.

## Every move must have a signal that retires it

Completion is detected from the **survey**, never from the ticks. A move drops off because the PR merged, the issue closed, the labels now exist, the tree went clean. Your tick is a mid-day annotation — which is why the merge preserves it, and why it's never evidence that something got done.

That has a consequence worth stating: a move with no observable signal — *"decide whether this repo dogfoods its own workflow"* — can never drop off on its own. It re-ranks every run forever, and the only thing that ever silences it is a tick that today's file takes to the grave tomorrow. Those aren't next actions, they're decisions, and they route to [`plankit`](./plankit.md) or get filed with [`issuekit`](./issuekit.md) `create` so the resulting issue is what shows up here instead. If you can't name what would make a move disappear, it doesn't belong on the list.

The same reasoning is why ticked moves land in **`Done today`** rather than being deleted with the rest of the stale ladder. One file per day only pays off if the day accumulates in it; a file showing nothing but what's left reads identically at 6pm and 9am, which is the one impression a status file must never give.

## No state between runs

Every run is a fresh read. There's no `STATUS.md` at the repo root, no last-run cache, and it never *reads* a snapshot back to shortcut the survey. The one thing it takes from an existing file is which boxes were ticked — the survey itself is always re-derived.

## Hands off to

Whichever kit the crowned move belongs to. **Route, don't launch** — statuskit names the kit and its one-line command and never invokes it. Calling the kit itself would restart mutation in the same breath as "orient me", breaking the read-only stance.

## Install

```sh
npx skills add mimukit/skills -s statuskit
```

Source: [`skills/statuskit/SKILL.md`](../../../skills/statuskit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`fcdb628` on 2026-08-07._
