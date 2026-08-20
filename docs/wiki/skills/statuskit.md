# statuskit

Survey a project read-only into a one-screen dashboard, then crown one finish-first next move — ranked on declared priority — routed to the kit that does it.

**Reach for it when** you sit back down at a project and ask "where is this, and what's my single best next move?"

| | |
|---|---|
| Modes | single procedure |
| Tools | `Bash`, `Read`, `Write`, `Edit`, `Skill` |
| Writes | `docs/status/status-<slug>-YYYY-MM-DD.md` — gitignored scratch; one tracker-declaration line in an existing agent-guide file, on approval |
| Visibility | public |

## What it does

statuskit surveys the whole project **read-only** — git working tree, GitHub issues, open PRs, unfiled plans — prints a one-screen dashboard, then does the opinionated part: it ranks the possible next actions and crowns exactly **one**, routing you to the kit or plain command that does it.

It's a **read-and-advise** tool. It never commits, pushes, closes an issue, edits a PR, merges, relabels, or writes code. Every mutation happens inside the kit it hands off to, under that kit's own guard.

Nothing it does reaches a remote, a branch, or a tracker, and that is the point: statuskit is safe to run anytime, as often as you like, to re-orient.

The stance used to be stated as "zero mutation," which was never quite true, because the snapshot was always a write. It is now stated as the boundary that actually holds: two local files, and nothing outward-facing ever. A headline a skill contradicts is worse than a narrower one it keeps.

## Three panels name names

Most of the dashboard is counts, which is right for signals you only need a feel for. Three aren't:

- **Unblocked issues** — the pick-up-now list: every open issue you could actually start, by ID, with its bucket and title. That means `ready`, unlabeled, and `in-progress` work you can resume. "Blocked" means the `blocked` label, or a `Blocked by #N` line pointing at a still-open issue in repos that don't use the label.
- **PRs waiting for review** — a table of every open non-draft PR whose review is still outstanding, with **what it closes** right beside its number, then its CI state, its author, and whose move it is.
- **Blocked issues** — the other half of the issue read, with what each one says it's waiting on. It comes free, and "2 blocked" doesn't tell you whether they're waiting on a PR that merged this morning.

**An `in-review` issue never appears in the unblocked table.** Its next move is a review of a PR, and the waiting-for-review row already names the person and the CI state — strictly more than a second row in a list of work you can start would say. The count stays on the Issues line, because it's still a fact about the tracker. An `in-review` issue with no open PR at all is the one case with nothing to point at; that's tracker drift, so it gets a note on the count line and a route to [`issuekit`](./issuekit.md) `triage` rather than a silent restoration to the pick-up-now list.

**The order is the order you can act in, and blocked work goes last.** Unblocked leads, waiting-for-review follows, and `Blocked issues` closes the block — sitting under the Pull requests panel rather than under the Issues line that counts it. A reader scans from the top and stops at their next move, so every row they can act on has to precede the first row they cannot. The table carries its full name for the same reason: away from the Issues panel, a bare `Blocked (N)` reads as blocked *PRs*.

The reason these three get rows instead of a number is that a count sends you straight back to `gh` to find out *which* — and that round trip is exactly the friction statuskit exists to remove. All three list everything that qualifies; on a repo large enough to blow the one-screen budget they cap at 10 rows and say so with a `+N more` line rather than truncating silently.

**The two actionable tables sort by `Priority`, then `Unblocks` — not recency.** A column you have to scan isn't a priority list — the row to pick up next belongs on the first line, not wherever a big number happens to land. Recency doesn't vanish; it becomes its own `Last active` column (`4h`, `2d`, `3w`), so "what did I touch last" stays answerable without deciding the order. The count line declares the sort (`— highest priority first`, reverting to `— highest leverage first` when the priority column drops), because a table that silently changed its ordering is one you misread once and distrust after. The blocked table keeps its recency sort and gets no leverage column — nothing in it can be picked up, so ranking it by what it would free is a number with nowhere to go — but it *does* carry priority, because that's what tells you whether the blocker is worth chasing.

**Three columns drop themselves, and that's what keeps the tables affordable.** `Author` goes when every row shares one, `Unblocks` when every value is zero, `Priority` when nothing is ranked. On a solo repo those rules are the difference between a nine-column PR table that fits on one screen and one that wraps — at which point it communicates less than the bare count it replaced. If a table still doesn't fit after every drop has fired, `Title` gets truncated rather than a sort key hidden: a shortened title is still a hint, where an invisible sort key is a lie.

The `Closes` column comes from GitHub's own `closingIssuesReferences`, not a `Closes #N` scrape of the PR body, so it catches every keyword spelling and issues linked by hand in the UI. Filled, it tells you what merging that PR retires — read against the blocked table, it turns "3 PRs awaiting review" into "reviewing #34 frees #19." Empty is the more useful reading: that PR will merge and leave its issue open, which is exactly what the stale-tracker signal counts *after* the fact. Seeing it beforehand costs nothing and beats reconciling later.

## Whose move it is, read off the reviewers

The `Next move` column used to be inferred from authorship — *you opened it, so you must be waiting on someone.* That inference is only sound when someone was actually asked, and on a solo repo nobody ever is: every PR you open would report *waiting on them* forever, naming a reviewer who doesn't exist, while the ladder crowned something else entirely. Three green PRs could sit unmerged for a month and the dashboard would keep insisting they were out of your hands.

So it comes off `reviewRequests` and `latestReviews` instead, with three outcomes:

| Signal | Column reads | Ranks? |
|---|---|---|
| you're a requested reviewer | `yours` | surfaced |
| someone else is requested, or a non-author already reviewed | `theirs — @name` | surfaced — genuinely out of your hands |
| neither | `nobody reviewing → yours` | **crowned** — rung 2 |

Naming the reviewer in the middle case is what makes it checkable; an unattributed *theirs* is indistinguishable from the bug it replaces. And there's no "solo mode" anywhere — the third row fires just as usefully on a team repo where you opened a PR and forgot to request anyone.

When it does fire, statuskit spends **one** extra call to sharpen the advice: `gh api …/collaborators --jq length`. Exactly one collaborator proves no other reviewer exists, so the move is self-review outright; more than one, or a 403, and it names both halves — request a reviewer, or self-review it. The column is already correct without that call, so a failure costs nothing.

**The `Author` column disappears when every row shares one author**, replaced by `— all yours` on the count line. Same rule as the all-zero `Unblocks` column: a column whose values never vary spends width to report nothing, and a wall of `you` is worse than nothing because it reads like a fact that got checked.

## The panel set is closed

Working tree, Issues, Pull requests, Plans, Next move — that's the dashboard, plus **at most one** repo-specific panel when the repo keeps a first-class queue the standard five genuinely can't see, like an `IDEAS.md` backlog. And a panel is **one line**: its heading and counts on the same line, nothing under it but a table.

Both rules exist because the panel block's entire value is that four lines tell you where the project stands before you've started reading. A panel that grows a second sentence has become a report, and the sentence it grows is almost always an argument for a move — which belongs in the move, where you can act on it. A panel that has to be *run* to fill (a lint result, a test count) is out of bounds twice over: statuskit's survey is read-only, so it's a claim the survey can't back. Without the closed set, every run improvises a different one and no two days' files compare.

### Plans is the one conditional panel

It prints only when it has a finding, and it names what it found. A finding is a plan doc that never became an issue, or, on a project with no tracker to file into, a phase still unbuilt. Those are the same shape: work written down that nothing is carrying.

The other four report state that always exists — a tree is always in some condition, a repo always has some number of issues and PRs, and zero is a genuine reading of each. A plan count isn't like that: `21 filed · 0 unfiled` is a fact about a directory rather than a call to action, and it spends a line of the dashboard on every run to report that nothing is wrong. So Plans is a **finding**, and an empty finding doesn't print.

Widening what counts as a finding is deliberately not the same as changing the rule. The panel keeps its name, its position, and its suppression behaviour. What changed is that a trackerless project has no Issues panel at all, so this is the only place its outstanding work can surface, and a panel that stayed narrow would leave that project reading a dashboard with nothing actionable on it.

**And the finding is only computed when the project actually tracks work in GitHub issues.** "Unfiled" is a claim about a tracker, so it needs one to check against: `gh` usable, issues enabled, at least one issue in any state. Any of those missing and statuskit skips the comparison rather than guessing — plenty of projects run on Linear, Jira, a `TODO.md`, or somebody's head, and a survey that announces "18 unfiled" on one of them is reporting its own blind spot as a finding, then routing you to `issuekit create` for a tracker you deliberately don't use. The same gap collapses ladder rung 11 to its second half: no plans at all → [`plankit`](./plankit.md).

Two details make the check trustworthy rather than merely quiet. It matches over `--state all`, because a plan that shipped months ago has a *closed* issue and matching open ones alone would report every finished plan as neglected. And an uncertain match counts as **filed** — the panel only ever prints gaps, so a miss costs one silent line while a false positive sends you off to file a duplicate of work already tracked.

Don't read this as "suppress the quiet panels." Plans is conditional because its empty state is *unactionable*, not because it's boring: a clean tree and an empty PR list are both things you want confirmed, and a dashboard whose panel set shifts with the mood of the repo stops being comparable day to day. Plans is the exception and stays the only one.

## The ranking principle: finish-first

Everything it crowns derives from one rule — **stop starting, start finishing**. The crowned move is whatever retires the most in-flight work for the least effort, *before* anything new is started.

Ties within a rung break on **declared priority first**, then one of two signals depending on what the rung asks of you. **Resume and finish rungs** go to the most-recently-active candidate, because recency proxies context-switch cost and that cost is what you're minimizing when there's a half-built thing to switch back into. **Start-something rungs** go to the highest unblock leverage, because starting fresh means there's no context to preserve — the cost recency measures is zero, and what's worth maximizing instead is how much work the repo can run in parallel once this lands.

## Priority

The [`issuekit`](./issuekit.md) priority labels — `critical`, `high`, `medium`, `low` — are the **first tiebreak everywhere**, and they get that position for one reason: everything else statuskit ranks on is *inferred* from the repo's mechanics, and this is the only signal where a human actually said what matters.

Reading it costs nothing. The survey already fetches every label on every open issue to bucket them by lifecycle state, and priority is four more names in the same array — no extra call, no extra scope.

**An unassessed issue sorts below `low`**, and that isn't a judgment about the work. It's a judgment about the tracker: an issue nobody ranked carries no claim, and statuskit's job is to crown a move it can *defend*. Ranking an unlabeled issue above a labelled one would mean inventing the claim on your behalf. When the unassessed pile is large, that's the finding — it gets surfaced and routed to `issuekit triage` rather than quietly sorted.

**A PR's priority is the highest priority among the issues it closes** — the same path leverage takes through `closingIssuesReferences`, for the same reason: a PR has no importance of its own, only that of the work it retires. Highest rather than average, because merging delivers *all* of them and the most urgent one is what's actually waiting.

### `critical` is the one thing that outranks finish-first

Every other signal orders *within* a rung, and that restraint is deliberate — it's what stops a clever number from talking you out of finishing what you started. `critical` is the single exception, and the argument is narrow enough to state in a line: **finish-first is a heuristic for what to do when nobody has said what matters, and `critical` is somebody saying it.**

Minimizing work-in-progress is the right default precisely because it needs no information — it works on any repo on any day without asking anyone. A `critical` label is strictly better information than that, and it's the only signal in the whole survey a human deliberately placed. Ignoring it would leave the dashboard ranking a half-built refactor above the thing its own user flagged as on fire, which is the one outcome that makes it untrustworthy rather than merely wrong.

Three guards keep the exception from swallowing the rule:

- **Only a *workable* `critical` promotes** — open and unblocked. A `critical` sitting behind an unmet prerequisite has nothing to act on, so it stays in the blocked table and the crowned move becomes its blocker.
- **Nothing else promotes.** `high` is not a small `critical`; it orders within a rung like leverage does. A repo that wants preemption has to say `critical`, and that friction is what keeps the level meaningful.
- **It names what it displaced** — *"#12 is critical, so it goes first; your red PR #34 drops to runner-up."* A preemption you can't see is indistinguishable from a ranking bug, and this one is rare enough that it should read as an event.

**Several workable `critical`s is itself the finding.** Two is an ordinary tiebreak. A tracker where five issues all preempt everything has lost the level — nothing is being dropped for any of them, so `critical` has quietly become the new normal. statuskit says so and points at `issuekit triage`, which flags stale `critical` labels as drift.

**statuskit reads priority; it never assigns one.** Printing the label an issue carries is a fact read, and sorting on it is what the label is *for*. Inferring a priority for an unranked issue is the tracker judgment that belongs to issuekit — and the one place this survey could quietly manufacture the very signal it claims to report.

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

Leverage never promotes a candidate *across* ladder rungs. Finish-first stays the spine; leverage only orders within it — and unlike `critical`, leverage gets no exception, because a big `unblocks` number is something statuskit *computed* rather than something anyone declared.

Two states are **surfaced but never crowned**, because acting on them is a human gate rather than a finish-first win:

- an approved and CI-green PR — merging is your call;
- a PR whose review someone else actually owes you — out of your hands.

Both appear as facts. Neither becomes the #1 move. Note how narrowly the second one is drawn: it needs a named person on the hook, which is exactly what the reviewer read above establishes. A PR nobody is reviewing fails that test and ranks instead.

That's also the line that keeps rung 2 from contradicting this section — **statuskit crowns the review, never the merge.** Reviewing an unreviewed PR is real work with an observable finish. Pressing merge is the judgment call it stays out of, so the crowned move stops at *reviewed* and hands the decision back to you.

## It degrades per source, never wholesale

statuskit is **git-first**: git signals always drive it, GitHub signals enrich it.

| Missing | Effect |
|---|---|
| Not a git repo | says so, skips everything git-derived. No repo at all → the move is to start with [`plankit`](./plankit.md) |
| `gh` missing, unauthenticated, or no remote | drops to the **git-only ladder** — a first-class mode, not an error. Names the actual gap once and carries on |
| No `docs/plans/` | skips the plans read entirely |
| A repo that doesn't use GitHub issues | drops the Issues panel and six ladder rungs, ranks unbuilt plan phases instead. See [Not every project uses GitHub Issues](#not-every-project-uses-github-issues) |
| No shell | prints the commands for you to run, reasons from what you paste back |

## Not every project uses GitHub Issues

`gh` answering is not evidence that this project files issues. A repo can have `gh` authenticated, Issues enabled, and forty open bug reports from users, while every planned change lives in Linear. Another can have zero issues because somebody created it yesterday. Those two want opposite advice, and no amount of API poking separates them.

That's the gap this closes. statuskit already degraded well on two axes: **capability** (is `gh` there and authenticated) and **installation** (is the kit a move routes to installed). Neither covers **policy**, which is a decision a team made and never told a tool about. Treating a working `gh` as consent to recommend filing issues is how a survey ends up confidently pointing a Jira shop at `issuekit create`.

So the question gets resolved explicitly, first answer wins:

1. **The prompt.** You said so.
2. **The repo's agent-guide file.** A sentence like *this project tracks work in Linear, not GitHub Issues*.
3. **Detection**, off the `gh issue list --state all` call the survey already makes. Issues disabled means no tracker; any issue in any state means a tracker.
4. **Unknown**, when the array comes back empty.

**Unknown is a real answer, not a failure.** It routes like no-tracker, so nothing gets asserted as unfiled and nobody gets told to go file issues, and it says out loud that it couldn't tell. An earlier draft resolved the ambiguity by probing for the `ready` / `blocked` lifecycle labels, on the theory that a repo carrying them has declared the workflow. That got cut: it buys a sharper *sentence* rather than a different *action*, spends a call on a repo state that lasts about a day, and misreads a label set some template provisioned that nobody uses.

**Only statuskit resolves this.** It has to, because it crowns exactly one move and a wrong answer sends you somewhere useless. Every other kit either carries the one-line conclusion ([`issuekit`](./issuekit.md), [`afkkit`](./afkkit.md)) or names both destinations without resolving anything ([`plankit`](./plankit.md), [`grillkit`](./grillkit.md), [`implementkit`](./implementkit.md)). Four skills each running their own version of this ladder is four skills drifting into four slightly different answers.

### The work list when there's no tracker

Plan documents. They were already phase-shaped, because that is exactly the structure `issuekit create` decomposes into issues, so nothing new had to be invented to give a trackerless project a queue.

What was missing is a way to tell a built phase from an unbuilt one. That's now an annotation on the phase heading, written by [`implementkit`](./implementkit.md) after its gate goes green, sharing the slot [`issuekit`](./issuekit.md) already writes `(#41)` into:

```markdown
### Phase 2: auth (#41) (built 2026-08-20)
```

Two alternatives lost. A hand-maintained `Status:` line per plan was already in this repo and already stale, still announcing "Not yet built" for a skill that shipped weeks earlier. Inferring builtness from git history needs no convention at all, and it makes a read-only survey guess at something it can be told.

**A plan with no annotation anywhere makes no claim.** That is what let the convention arrive without a migration: every plan written before it stays silent and correct, and a plan starts making claims the first time something stamps it. Reading absence as "unbuilt" instead would have reported every plan in this repo, all 27 of them, as outstanding work on day one.

### It can offer to write the answer down

On an unknown reading only, statuskit offers to append one sentence to the agent-guide file so the next run resolves at rung 2. This is the only thing it writes outside its own snapshot, and it is deliberately hemmed in: previewed and approved, never as the crowned move, at most once per run, never in an unattended run, and only into a file that already exists. A repo with no agent-guide file has decided not to have one, and a status check is the wrong tool to change that, so it prints the line for you instead.

## The two ladders

**Git-only** (no `gh`):

| # | State | Move |
|---|-------|------|
| 1 | uncommitted work on a feature branch | continue / [`commitkit`](./commitkit.md) |
| 2 | unpushed commits | `git push` |
| 3 | a stash | restore or drop it |
| 4 | an unmerged local feature branch | finish or clean up — [`gitkit`](./gitkit.md) |
| 5 | a plan doc on disk — filed or not is unknowable with no tracker | implement the newest — [`implementkit`](./implementkit.md) |
| 6 | clean on base, nothing pending | start something |

**Full** (`gh` available) — every git-only state has an explicit home here:

| # | State | Move |
|---|-------|------|
| 0 † | a **workable `critical`** issue — open, unblocked | drop what you're on — [`issuekit`](./issuekit.md) `start`, or resume it |
| 1 | your PR is red or change-requested | [`mergekit`](./mergekit.md) `fix` |
| 2 | your PR that nobody is reviewing | self-review — [`mergekit`](./mergekit.md) `<N>`, or request a reviewer |
| 3 † | in-progress issue whose branch you're on | resume / [`implementkit`](./implementkit.md) |
| 4 | orphaned work — uncommitted on base, untracked branch, unpushed commits | [`commitkit`](./commitkit.md) / push |
| 5 | a stash | restore or drop |
| 6 | an unmerged local feature branch | [`gitkit`](./gitkit.md) |
| 7 † | stale-tracker signal fired | [`issuekit`](./issuekit.md) `sync` |
| 8 † | a `ready` issue to start (highest priority, then `unblocks`) | [`issuekit`](./issuekit.md) `start`, then implement |
| 8b | **no tracker:** the next unbuilt phase of the newest plan | build it — [`implementkit`](./implementkit.md) |
| 9 † | an unlabeled issue needing classification | [`issuekit`](./issuekit.md) `triage` |
| 10 † | an unassessed backlog — open issues with no priority | rank them — [`issuekit`](./issuekit.md) `triage` |
| 11 | an unfiled plan *(only when the tracker is in use)*, or no plans at all | [`issuekit`](./issuekit.md) `create` / [`plankit`](./plankit.md) |

**† fires only when a tracker is in use.** Six of the twelve rungs are issue rungs, which is why a project tracking work elsewhere used to fall past all of them and get crowned nothing. The PR and git rungs never depend on it: a branch and a pull request are the same facts whatever the tracker is.

**Rung 0 is numbered zero because it isn't really a rung.** It's the [one documented override](#critical-is-the-one-thing-that-outranks-finish-first) of the finish-first spine, and numbering it inside the sequence would make it look like an ordinary state that merely happens to sort first. It fires rarely, it names what it displaced, and everything below it is the actual ladder. If it's firing on most runs, `critical` has stopped meaning anything and the real move is `issuekit triage`.

**Rung 10 sits below every actionable rung and above "go plan something."** An unranked backlog is a real gap — nothing above it can order itself properly — but it's tracker hygiene rather than work, so it never outranks something you could actually finish. It earns a rung at all because without one, a repo where nobody has set a single priority would rank on leverage forever and never be told why.

**Rungs 1 and 2 are one thought twice: your own PR is stuck on you.** A red PR is stuck loudly, an unreviewed one silently — and the silent kind is what sits for weeks. That's why it outranks resuming a half-built issue rather than trailing it: the code is already written and green, so it retires the most work for the least effort, which is the whole of finish-first. It's also the one rung that breaks ties on leverage while asking you to *finish* rather than start, because there's no context to switch back into. Reviewing a finished PR costs the same whichever you pick, so the tiebreak may as well go to the one that frees the most.

When the owning kit isn't installed, it names the **plain action** instead — "commit your changes" rather than "run commitkit". statuskit routes; it doesn't require the ecosystem.

## Every move line is written to be scanned, not read

The crowned move, the runner-ups and the snapshot's checkboxes all use ASD-STE100 Simplified Technical English: one instruction per line, active voice, present tense, a named actor, and no word carrying a second meaning. "Merge #34" and "file the backlog", never "get #34 over the line".

The reason is the same one behind the one-line panel rule. A dashboard earns its place by telling you where the project stands before you have started reading. A move phrased as a small argument stops being scannable, and once one line reads as prose the whole block gets read instead of scanned — at which point it is a report, and you may as well have opened the tracker.

One term per thing matters more here than almost anywhere, because the panels and the moves sit inches apart. A panel that says *unfiled plan* above a move that says *plan doc* reads as two different objects to a person glancing at the block, and the glance is all this format gets.

## Two lines it holds

**gitkit owns the git facts.** The base branch, the branch-name convention, and where a worktree lives all come from [`gitkit`](./gitkit.md). Keeping a second copy of any of them is how a dashboard starts confidently describing a repo that no longer matches it.

**issuekit owns the tracker.** statuskit displays issue counts, the unblocked set by ID, each issue's declared priority, and computes *one* cheap staleness boolean — how many merged PRs have a linked issue still open — used only to decide whether "reconcile" ranks. It never itemizes which issues are stale or why, and it never invents a priority for an issue nobody ranked. The moment you're explaining that, it's [`issuekit`](./issuekit.md)'s job, and statuskit should be pointing at it rather than doing it.

The split in one line: issuekit answers *"is my tracker honest?"*; statuskit answers *"where's this project and what do I do next?"*

One thing sits on statuskit's side of that line despite sounding like issuekit's: **whether there is a GitHub tracker here at all.** It looks misfiled, and the charter argument for moving it to issuekit is real. It stays here because statuskit is the only skill that has to *resolve* it in order to do its job, and because putting it in issuekit would mean statuskit either invoking an 8,000-word tracker skill inside a read-only survey, or restating the answer anyway. Note the asymmetry: issuekit judges the tracker's contents, statuskit only asks whether the project keeps one.

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

_Verified against `main`@`06848f6` on 2026-08-20._
