---
name: statuskit
description: >-
  Survey a project read-only (working tree, issues and their priority, open PRs, unfiled plans, docs awaiting review) into a one-screen dashboard that crowns one finish-first next move routed to the kit that does it, saved by default as a throwaway snapshot under docs/status/. Use when you sit down at a project and ask "what should I do next" or "check project status"; add "no file" to skip the snapshot. It reads and recommends only; the crowned kit does the work.
license: MIT
allowed-tools: Bash, Read, Write, Edit, Skill
metadata:
  internal: false
---

# statuskit

Read and advise; write only the files the [write rules](#write-rules) list. statuskit never commits, pushes, closes an issue, edits a PR, merges, relabels, or writes code. A move names its kit and one-line command, and the user launches it. The `Skill` tool is for gitkit only, which the survey calls for the base ref, the branch-name pattern, and worktree paths. Every other kit is routed to, never invoked.

Tracker judgment belongs to issuekit. statuskit prints issue counts, the unblocked, blocked, and ready sets by ID, what each blocked issue says it waits on, and each issue's declared priority, and it computes one staleness count. It never renders an itemized tracker-health verdict, never explains which issues are stale and why, and never assigns a priority. When the dashboard needs that judgment, point at `issuekit triage` or `issuekit sync`.

## The ranking principle: finish-first

Crown the move that retires the most in-flight work for the least effort, before anything new starts (minimize work in progress).

Ties within a rung break on **declared priority first**, then on one of two signals:

- **Resume or finish rungs.** Crown the **most-recently-active** candidate (issue or PR `updatedAt`, or a branch's last-commit time), because recency tracks context-switch cost. The exception is a finished-but-unreviewed PR: it has no context to switch back into, so it breaks ties on leverage like a start rung.
- **Start-something rungs.** Crown the highest **unblock leverage** (below), falling back to recency.

The rest become runners-up. Neither priority nor leverage promotes a candidate across rungs. The one exception is a workable `critical` issue.

## Priority

**Priority is the human's declared answer to "what matters", read off the [issuekit label set](#the-priority-scale): `critical`, `high`, `medium`, `low`.** It is the first tiebreak everywhere.

### The priority scale

| label | means | how it ranks |
|-------|-------|--------------|
| `critical` | drop everything; preempts work already in progress | promotes across rungs |
| `high` | do this before other workable issues | orders within a rung |
| `medium` | normal priority, the default once assessed | orders within a rung |
| `low` | worth doing eventually; never preempts anything | orders within a rung |
| *(none)* | unassessed; nobody has ranked it | sorts below `low` |

**Priority and lifecycle (`ready`, `blocked`, `in-progress`, …) are independent label namespaces, and statuskit reads both.** Never derive one from the other: a `critical` issue that is `blocked` is still blocked.

**Unassessed sorts below `low`.** When the unassessed pile is large, surface it as a finding and point at `issuekit triage`.

### `critical` is the one thing that outranks finish-first

A workable `critical` issue preempts every rung. Three guards hold it:

- **Only a workable `critical` promotes**: open and unblocked. A blocked `critical` stays in the blocked table, and the crowned move is its blocker when that blocker is workable.
- **`critical` promotes; nothing else does.** `high` orders within a rung like leverage does.
- **Name the displaced move** in the same line: *"#12 is critical, so it goes first; your red PR #34 drops to the runner-up"*.

Two or more workable `critical` issues break the tie on leverage, then recency. When several are workable, say on the crowned move that `critical` has become routine, and point at `issuekit triage`, which flags stale `critical` labels. If rung 0 is firing on most runs, `critical` has stopped meaning anything and the real move is `issuekit triage`.

## Unblock leverage

**`unblocks(X)` is the number of open issues that become *fully workable* the moment X lands.** An issue counts toward `unblocks(#12)` only when removing #12 leaves its open-blocker set **empty**; if #19 also waits on #23, closing #12 does not count it.

Leverage flows to PRs through what they close: `unblocks(PR #34)` is the leverage of the issues in its `closingIssuesReferences`.

**`closingIssuesReferences` is empty on every stack layer.** GitHub resolves a closing keyword only on a PR that targets the repository's **default branch**, so a layer PR with a correct `Closes #123` reports no closing issues until the layer below merges and GitHub retargets it. **On a PR whose `baseRefName` is not the default branch, fall back to a `Closes #N` scrape of the body** and treat the result exactly as `closingIssuesReferences`. Spend the scrape only on a layer, and only when the field came back empty.

Four rules keep the number honest:

- **Depth 1 only.** Don't count cascades.
- **Only still-open blockers count**, the same rule the blocked set follows.
- **A blocker may be a PR.** Issue and PR numbers share one namespace on GitHub, so `blockedBy: #34` can mean "waiting on a merge"; resolve it against the open-PR read.
- **No declared dependencies means no column.** When the graph has no edges, drop the column, say once *no dependencies declared; leverage unavailable*, and point at **issuekit**.

Two states are **surfaced but never crowned**:

- an approved + CI-green PR ("ready to merge"), because merging is the user's call;
- a PR whose review someone else owes the user, per the *whose move it is* rule in [the survey](#2-survey-collecting-signals-read-only). A PR that nobody is reviewing is not in this state; it ranks on the [full ladder](#3-rank-and-crown-one-finish-first-move).

**statuskit crowns the review, never the merge.** The crowned move ends at *reviewed* and hands the merge decision back to the user.

## Resolving the tracker

**`gh` working is not evidence that the project tracks work in GitHub Issues.** Take the first rung that gives an answer:

1. **The prompt.** The user said so ("we don't use GitHub issues", "file this in the tracker"). Explicit always wins.
2. **The repo's agent-guide file** (`CLAUDE.md` or an equivalent) states where work is tracked. A sentence like *this project tracks work in Linear, not GitHub Issues* settles it in either direction.
3. **Detection**, from the `gh issue list --state all` call [the plans survey](#2-survey-collecting-signals-read-only) already makes. A non-empty array means **present**. An error that says Issues are disabled on the repo means **absent**.
4. **Unknown.** An empty array, or any other error (network, authentication, rate limit).

The reading is one of four states, and every tracker-dependent rule in this file keys on it:

| reading | comes from | issue rungs (†) and Issues panel | unfiled-plan check |
|---|---|---|---|
| **present** | the prompt, the guide, or a non-empty array | run | runs |
| **absent** | the prompt, the guide, or Issues disabled | skipped | skipped |
| **unknown** | an empty array, or any other query error | skipped, and said once | skipped |
| **unavailable** | `gh` missing or unauthenticated, or no GitHub remote | the git-only ladder runs instead | skipped |

*No tracker* below means absent or unknown. **A query error is never absent.** Name the failed call once on the Issues line and route like no tracker. The same holds when the prompt or the guide says present and the issue query fails: the issue rungs skip and the failed call is named.

**Unknown routes like no-tracker and says so.** It never asserts a plan is unfiled, never crowns "go file issues", and names both paths in one line. Do not probe for lifecycle labels to resolve it. When an empty-array unknown fires and a user is there to answer → read [declaration.md](declaration.md), then follow it.

## Procedure

### 1. Preflight, degrading per source and never failing wholesale

Git signals always drive the survey; GitHub signals enrich it when available.

- **Not a git repo** → say so; skip everything git-derived. If there's no repo yet, the move is "start with `plankit`."
- **`gh` missing / unauthenticated / no remote** → drop to the **git-only ladder** below. Name the actual gap once (`gh` is not installed, run `gh auth login`, or add a GitHub remote) and carry on.
- **`gh` usable, but the project may not track work in GitHub Issues** → resolve it per [Resolving the tracker](#resolving-the-tracker). The issue rungs and the Issues panel both turn on it.
- **No plan docs** → skip the plans read. The Plans panel is conditional even when plans exist; see [the plans survey](#2-survey-collecting-signals-read-only).
- **No shell at all** (e.g. a browser-based agent) → print the commands below for the user to run and reason from what they paste back.

### 2. Survey, collecting signals read-only

Gather git always; gather GitHub only when `gh` is usable. All commands are read-only.

**git (always):**
- working tree: `git status --porcelain`, current branch, upstream ahead/behind, `git log @{u}.. --oneline` (unpushed; skip if the branch has no upstream, which is itself the "push/publish" signal), `git stash list --format='%h %gd %s'` (the SHA is the stash's stable identity), and any local branches carrying unmerged commits.
- **the base branch**, from **gitkit**, never assumed to be `main`. Every "is this a feature branch?" and "is it unmerged?" judgment turns on it.
- **branch → issue mapping.** Resolve the current branch from its open PR's `closingIssuesReferences`. **On a stack layer that field is empty**, so apply [the layer fallback](#unblock-leverage) before you drop to the branch name. **The branch-name pattern comes from gitkit** (`issue-<n>-<slug>`); a bare `#N` or a slug matching an issue title are the looser fallbacks. When the branch stays unmappable, treat a dirty branch that isn't the base as *continue*, not *commit*.
- **worktrees.** Ask gitkit where a branch's code lives. statuskit never creates or removes one.
- **`CONTEXT.md` signal**, a yes or no, never itemized, because domainkit's `audit` owns the findings. It fires on either condition. **Missing:** no `CONTEXT.md` (or `CONTEXT-MAP.md`) at the repo root while `docs/adr/` or `docs/plans/` exists. **Behind:** the newest ADR file in `docs/adr/` was added after the last commit that touched `CONTEXT.md`, or 50 or more commits have landed since it (`git log -1 --format=%H -- CONTEXT.md`, then `git rev-list --count <sha>..HEAD`). A `CONTEXT.md` that only lacks an `## Overview` does not fire it.

**GitHub (only when `gh` is usable):**
- issues: `gh issue list --state open --json number,title,labels,updatedAt,blockedBy,blocking`, bucketed by lifecycle label (`in-progress` / `ready` / `stacked` / `needs-planning` / `blocked` / `in-review`) plus an **unlabeled/other-status** bucket for repos without that vocabulary. Counts and the actionable set only, with no drift detection. Treat recent unlabeled issues as candidates for classification or planning.
- **[priority](#priority)**, read from that same `labels` array, so it costs no extra call. Take the highest when an issue carries more than one (a tracker slip that `issuekit triage` repairs), and `none` when it carries none. **When no open issue carries any priority label, drop the column** and say once *no priorities set; ranking on leverage and recency*, pointing at **issuekit triage**.
- **the dependency graph.** `blockedBy` and `blocking` from that same call are GitHub's native issue dependencies, so no body scraping or per-issue fetch is needed. Read them defensively (`(.blockedBy // []) | length`). When a repo doesn't use the feature, fall back to a `Blocked by #N` / `Depends on #N` / `Blocks #N` line in the body, extracted with `--jq` so bodies never enter context. Both directions describe the same edge; normalize to one.
- **the unblocked set**: every open issue that is neither blocked nor `in-review`, kept as number + bucket + **priority** + `updatedAt` + **`unblocks` count** + title. The dashboard prints it as a table. An issue is blocked when it has a still-open `blockedBy` entry or carries the `blocked` label. An `in-review` issue belongs in the waiting-for-review table, not here. **A still-open `blockedBy` whose blocker has an open PR does not count as blocked**: the dependent can be worked now on a branch stacked on the blocker's, so it goes in this table with a `stacked` marker, settled by the open-PR read. Everything else is unblocked: `ready`, unlabeled or needs-planning, and `in-progress` work you can resume. **Sort by priority descending, then `unblocks` descending, then most-recently-updated.**
- **the blocked set**, the other half of that same read, kept as number + **priority** + what it's waiting on + title. It holds only waits on a prerequisite that has *not* been built. The blocker comes from `blockedBy`, else a `Blocked by #N` / `Depends on #N` line, else is unnamed when all you have is the bare `blocked` label; print all three forms. Report what an issue says it waits on; judging whether that blocker is still real is issuekit's job.
- open PRs: `gh pr list --json number,title,author,baseRefName,statusCheckRollup,reviewDecision,reviewRequests,latestReviews,isDraft,updatedAt,closingIssuesReferences`, classified into *your red / change-requested PR* (actionable), *nobody is reviewing it* (actionable), *approved + green* (surface-only), and *awaiting someone else* (surface-only). Cap the list on large repos to stay fast; if a JSON field is rejected, run `gh pr list --json` with no value, which prints the field list your `gh` accepts.
- **what each PR closes**: `closingIssuesReferences` from that same call, not a `Closes #N` scrape of the body. **On a stack layer** apply [the layer fallback](#unblock-leverage): compare `baseRefName` against the default branch, and on a PR that fails that test scrape `Closes #N` out of the body with `gh pr view <n> --json body --jq` so the body never enters context. Print such a row's `Closes` cell as the issue number followed by `(stacked)`, and let priority and leverage flow from it as from the resolved field.
- **the waiting-for-review set**: every open non-draft PR whose review is still outstanding (`reviewDecision` empty or `REVIEW_REQUIRED`), kept as number + **what it closes** + **priority** + **`unblocks` count** + CI state + author + **whose move it is** + `updatedAt` + title, in that order. Sort it the same way as the unblocked set.
- **a PR's priority is the highest priority among the issues it closes.** A PR that closes nothing has no priority, so print a dash and let leverage and recency order it.
- **whose move it is: read it off the reviewers, never the author.** Three outcomes, checked in this order: you appear in `reviewRequests` → **yours**, go review it; somebody else appears in `reviewRequests`, or a non-author appears in `latestReviews` → **theirs**, name them; neither → **nobody is reviewing it**. The third case is every PR on a solo repo and a routine slip on a team one, and it is the only one of the three that ranks.
- **is anyone else able to review?** Ask only when the third case fires, and only once per run: `gh api repos/{owner}/{repo}/collaborators --jq 'length'`. Exactly one collaborator → the move is self-review. More than one, a 403, or any other failure → the move names both halves ("request a reviewer, or self-review it"). The probe changes only the wording; its failure never costs the row.
- **stale-tracker signal**: how many merged PRs have a linked issue still open. A single count, used only to decide whether "reconcile" ranks. **Never itemize which or why.**

**plans (filesystem, where the list always runs and the unfiled check needs a tracker):**
- list canonical `docs/plans/NNNN-plan-<slug>-YYYY-MM-DD.md` files and the older `plan-<slug>-YYYY-MM-DD.md` shape without the serial (or wherever the repo keeps plans; an `rfcs/`, `specs/`, or documented location takes precedence). The list always runs; the ladder's plan rungs read it.
- **the unfiled set, computed only on a present reading.** Cross-check each plan against the issue list and keep the ones that never became an issue. Match over **`--state all`**: `gh issue list --state all --json number,title --limit 200`, one call, spent only when plan docs exist, because a shipped plan has a *closed* issue. That same call is [rung 3 of the tracker resolution](#resolving-the-tracker). On absent, unknown, or unavailable, skip the comparison and never report a plan as unfiled.
- **Match on the plan's slug and its title, and when the match is uncertain call it filed.** An issue whose title matches the plan's title, whose body links the plan's path, or whose slug matches is enough on its own.
- **the unbuilt set, which the plan rung ranks when there is no tracker.** Find phases by a heading beginning `Phase <n>`, matching the separator loosely (`### Phase 2: auth` and `### Phase 2 — auth` are the same shape). A phase is **built** when its heading carries a `(built YYYY-MM-DD)` stamp, which **implementkit** writes into the same trailing slot as issuekit's `(#41)`; the two coexist, so `### Phase 2: auth (#41) (built 2026-08-20)` is a tracked phase that shipped.
- **A plan with no stamp anywhere makes no claim**, because the stamp is opt-in per plan. Treat it as a single unit and crown it whole, as [the git-only ladder](#3-rank-and-crown-one-finish-first-move) does. Once a plan carries one stamp it is authoritative, and its unstamped phases are unbuilt. A fully stamped plan is finished, so drop it.

**review stamps (filesystem, no tracker needed):**
- **the pending-review set.** Run `grep -rl '^Review: pending' docs/` once. A file carries the stamp `Review: pending` on a line of its own, and `Review: done <date>` once reviewed. **commitkit** writes both. Keep each hit as file + title (its first heading) and sort by serial, lowest first. A missing `docs/` directory, or a grep with no hit, means no finding.
- **This read sees the current tree only.** A stamp committed on another branch is invisible; say nothing about it.

### 3. Rank and crown one finish-first move

Map the signals onto candidate actions, each tagged with its owning kit/command, then crown the highest applicable rung. Ties inside it break as the rung's own row says, defaulting to most-recently-active, and everything else becomes a runner-up. Pick the ladder by whether GitHub signals are available.

**Git-only ladder** (no `gh`):

| # | State | Move → |
|---|-------|--------|
| 1 | uncommitted work on a feature branch | continue, or run `commitkit` |
| 2 | unpushed commits | `git push` |
| 3 | a stash | inspect and restore it with `gitkit rescue`, or drop it |
| 4 | an unmerged local feature branch | finish it, or clean it up with `gitkit clean` |
| 4b | a doc stamped `Review: pending` | read it, then mark it reviewed with `commitkit` |
| 5 | a plan doc on disk, where filed or not is unknowable with no tracker to check | implement the newest with `implementkit` |
| 6 | clean on the base branch, nothing pending | start something (newest plan), or run `plankit` |
| 7 | `CONTEXT.md` signal fired | `domainkit init` when it is missing, `domainkit audit` when it is behind |

**Full ladder** (`gh` available), where every git-only state has an explicit home below. *(Surfaced, never crowned: an approved+green PR; a PR someone else owes you.)*

| # | State | Move → |
|---|-------|--------|
| 0 † | a **workable `critical`** issue that is open, unblocked, and not already the crowned move | drop what you're on: `issuekit start <N>` if it's `ready` or startable `stacked`, resume it if it's `in-progress` |
| 1 | your PR is red or change-requested | fix CI or address review with `mergekit fix <N>` |
| 2 | your PR that nobody is reviewing (highest priority, then `unblocks`, then most-recently-updated) | set it up to self-review with `mergekit start <N>`, or request a reviewer |
| 3 † | in-progress issue whose branch you're on *(uncommitted work folds in here as "continue")* | resume, or run `implementkit` |
| 4 | orphaned work: uncommitted on the base branch or an untracked branch, or unpushed commits | run `commitkit`, or push |
| 5 | a stash | restore it with `gitkit rescue` to finish the work, or drop it if obsolete |
| 6 | an unmerged local feature branch | finish it, or clean it and its worktree up with `gitkit clean` |
| 7 † | stale-tracker signal fired | reconcile with `issuekit sync` |
| 8 † | a `ready` issue, or a startable `stacked` one, to start (highest priority, then `unblocks`, then most-recently-updated) | `issuekit start <N>` (worktree via `gitkit`), then `implementkit` |
| 8b | **no tracker:** the next unbuilt phase of the newest plan | build it with `implementkit` |
| 8c † | a `needs-planning` issue (highest priority, then most-recently-updated) | grill it with `grillkit`, then promote it with `issuekit triage` |
| 9 † | an unlabeled issue, or one whose status is outside the lifecycle map, needing classification | classify it with `issuekit triage` |
| 10 † | an unassessed backlog, meaning open issues with no priority label | rank them with `issuekit triage` |
| 10b | a doc stamped `Review: pending` | read it, then mark it reviewed with `commitkit` |
| 11 | an unfiled plan *(only when the tracker is in use)*, or no plans at all | `issuekit create`, or `plankit` |
| 12 | `CONTEXT.md` signal fired | `domainkit init` when it is missing, `domainkit audit` when it is behind |

**† marks a rung that fires only when a tracker is in use.** Resolve the tracker per [Resolving the tracker](#resolving-the-tracker) before ranking. The PR and git rungs never depend on it. Rung 8b keeps a trackerless project with unbuilt plans from getting no move.

**Rung 8b crowns the lowest-numbered unbuilt phase of the newest plan**, because a plan's phases are written in dependency order.

**A `stacked` issue is startable when its prerequisites' PRs are still open and form one chain**, which the open-PR read already shows. One whose prerequisite PR merged or closed is tracker drift: list it on the Issues line and route it to `issuekit sync`, not to `start`, which would refuse it.

**Rung 10b (4b without `gh`) crowns the lowest serial** when several docs are pending, and lists the others as runner-ups, one per doc.

When the owning kit isn't installed, name the **plain action** instead ("commit your changes" rather than "run commitkit"; "change the stamp to `Review: done <date>`" for a reviewed doc; "update `CONTEXT.md` by hand" without domainkit).

### 4. Output: the dashboard, then one crowned move

Print the dashboard in the shape below, under the [render rules](#render-rules), then the ranked next-actions list with the **#1 move bolded** and its exact kit/command. With a tracker in use the tables are the unblocked issues, the PRs waiting for review, and the blocked issues with their blocker; without one the issue tables have nothing to list and the unbuilt phases take their place. Keep it to one screen:

```
# Project status · <repo> · <branch> · YYYY-MM-DD

## Working tree  <clean | N uncommitted · M unpushed · stash K>

## Issues        in-progress N · ready N · in-review N · blocked N     (omit without gh, or without a tracker)

Unblocked (N) · highest priority first
| Issue | Priority | Unblocks | Status | Last active | Title |
|---|---|---|---|---|---|
| #12 | critical | 3 | ready | 2d | <title> |
| #31 | high | 1 | in-progress | 4h | <title> |
| #47 | none | 0 | unlabeled | 3w | <title> |

## Pull requests <open N: X awaiting review, Y CI-red, Z ready to merge>   (omit without gh)

Waiting for review (X) · highest priority first
| PR | Closes | Priority | Unblocks | CI | Author | Next move | Last active | Title |
|---|---|---|---|---|---|---|---|---|
| #34 | #12 | critical | 3 | ✓ | you | nobody reviewing → yours | 1d | <title> |
| #29 | #19, #23 | high | 0 | ✗ | @someone | yours | 6h | <title> |
| #38 | none | none | 0 | ✓ | you | theirs: @reviewer | 2w | <title> |

Blocked issues (N)
| Issue | Priority | Waiting on | Title |
|---|---|---|---|
| #19 | high | #12 | <title> |
| #23 | low | `blocked` label, no blocker named | <title> |

## Plans         <M unfiled: plan-debugkit, plan-testkit>   (omit entirely unless there is a finding)

Unbuilt phases (N) · plan order      (only when there is no tracker, and a plan carries stamps)
| Plan | Phase | Title |
|---|---|---|
| plan-sso-login | 3 | <phase title> |
| plan-sso-login | 4 | <phase title> |

## Review        <N pending: plan-sso-login, research-auth-providers>   (omit entirely unless there is a finding)

## Next move
**→ <the #1 action>.** Run `<kit / command>`.

Then:
- <runner-up> · `<kit / command>`
- <runner-up> · `<kit / command>`
- <runner-up> · `<kit / command>`
```

**Write every move line in ASD-STE100 Simplified Technical English**: the crowned move, the runner-ups, and the snapshot checkboxes. One instruction per line, active voice, present tense, named actor, no metaphor. Say "merge #34", not "get #34 over the line". Use one term per thing across the dashboard and the snapshot.

#### Render rules

Every rule for what prints, where, and in what order lives in this table. The snapshot file follows the same rules.

| Element | Rule |
|---|---|
| Signal panel | Working tree, Issues, Pull requests, Plans, and Review each put the heading and counts on one line, followed only by a table. A reason for a move goes in the move line. |
| Panel presence | Working tree, Issues, and Pull requests always print, zero counts included. A panel is omitted only when its source is unavailable: Issues and Pull requests without `gh`, Issues when the tracker reading is not present. Say the reason once. |
| Plans panel | Prints only with a finding: an unfiled plan when the tracker reading is present, an unbuilt phase of a stamped plan when there is no tracker. Both can print together. No finding means no Plans line, no `## Plans` section in the file, and no mention of why. |
| Review panel | Prints only with a finding: a doc stamped `Review: pending`. It is one count line with the doc names, and no table. No finding means no Review line and no `## Review` section in the file. |
| Extra panel | At most one, for a first-class queue the standard set cannot see (an `IDEAS.md` backlog, an RFC index), filled from a file the survey read. Never a panel filled by running a build, test, or lint. |
| Table order | Unblocked, then Waiting for review, then `Blocked issues (N)`, at most three at once. Blocked issues sit under the Pull requests panel and keep the full name, because a bare `Blocked (N)` there reads as blocked PRs. `Unbuilt phases` sits under Plans. The panel order never changes. |
| `in-review` issue | One row, in Waiting for review, never in Unblocked. Its count stays on the Issues line. One with no open PR is a note on the Issues line (`in-review 7 · 1 with no open PR`), routed to `issuekit triage`. |
| Rows | List every qualifying row. Over 10, cap at 10 and close with `+N more` and the `gh` command that shows the rest. |
| Empty table | Drop the table and keep its count line (`Waiting for review (0)`). |
| Sort | Unblocked and Waiting for review sort by `Priority`, then `Unblocks`, then recency, and the count line declares it (`· highest priority first`, or `· highest leverage first` when Priority drops). `Blocked issues` sorts by recency and carries `Priority` but no `Unblocks`. `Last active` is a column (`4h`, `2d`, `3w`), not the sort. |
| Column order | The sort keys follow the ID on the issue table and follow `Closes` on the PR table. Context columns follow in decreasing order of use. |
| `Closes` cell | Print `none` when the PR closes nothing, never a blank: `none` warns that the merge leaves its issue open, and a blank reads as "not checked". A stack layer's scraped link prints as `#12 (stacked)`. |
| `Next move` cell | `yours`, `theirs: @name`, or `nobody reviewing → yours`. |
| Drop rules | Drop `Author` when every row shares one author (say `all yours` on the count line), `Unblocks` when every value is 0, `Priority` when no row carries one. If a table still does not fit, cut `Title` to its first words. Never drop a sort key. |
| Move lines | One line per runner-up, naming exactly one issue or PR, the same split as the snapshot checkboxes. |

### 5. Write the status snapshot, the default rather than an offer

**Write the file every run without asking**, then say where it went in one line:

> Saved to `docs/status/NNNN-status-<repo-slug>-YYYY-MM-DD.md` · scratch file, gitignored, not committed.

Say `untracked` in place of `gitignored` when the [write rules](#write-rules) skipped the `.gitignore` line.

**Skip only when asked** ("no file", "just print it"), and print the dashboard alone. A skip applies to that run only, unless the user or the repo's agent-guide file (`CLAUDE.md` or an equivalent) makes it standing. Skip silently when there's no writable filesystem (below).

**Where it goes.** `docs/status/NNNN-status-<repo-slug>-YYYY-MM-DD.md`, using the next serial, a short lowercase kebab-case slug (normally the repo name; use a narrower one such as the branch or issue when the snapshot covers a slice of the project), and the ISO creation date. To get the serial `NNNN`, take the highest leading four-digit serial in `docs/status/` across this worktree, every other worktree that `git worktree list` names, and `origin/<default branch>` (`git ls-tree --name-only origin/<base> docs/status/` after `git fetch origin <base>`), and add one; start at `0001` when there is none. Scan all three, because parallel worktrees otherwise take the same serial. Skip a source that fails, such as no remote, and without git list the directory only. The serial is per directory and never reused. Create `docs/status/` if it doesn't exist.

**One file per day: update, never add.** Before writing, list `docs/status/` and look for a snapshot already carrying **today's date**. If one exists, update it in place and keep its name, even if this run would have picked a different slug. Create a new file only when nothing is dated today. When today's snapshot covers a different project in a monorepo, make the slug specific to that project and match on slug + date. Never add a sequence suffix.

**Updating means merging, not overwriting.** Re-derive the whole survey from git and GitHub, never trusting what the file says, then carry over the **checked state** of every move that's still open, matching on its key (below) and nothing else. Rewrite every other word from the fresh survey: a move whose wording changed completely is the same move if its key matches, and a move that kept its wording is a different one if its key doesn't. A ticked move the fresh survey no longer supports goes to `## Done today`; an unticked one drops. Drop the `Done today` section on a day with nothing done.

**What it contains.** The dashboard as printed, plus:

- a **provenance line** recording when the snapshot was taken, against which commit, and how many times it's been rewritten today: `Snapshot: 2026-07-23 14:20 · <branch> @ <short-sha> · run 3 today (first 09:05)`;
- the ranked moves as a **checkbox list**, crowned move first and each carrying its kit/command:

```markdown
## Next moves

- [ ] **<the #1 move> (critical, unblocks 3)** · `<kit / command>` <!-- k: issue-12 -->
- [ ] <runner-up> (high, unblocks 1) · `<kit / command>` <!-- k: pr-34 -->
- [ ] <runner-up> · `<kit / command>` <!-- k: plan-debugkit -->

## Done today

- [x] <move, as it read when it was ticked> <!-- k: issue-9 -->

## Surfaced, not queued

- #34 approved + CI-green · merge when you're ready (`mergekit close 34`)
- #29 awaiting @someone's review
```

**Every move carries a key**, the trailing `<!-- k: … -->` comment. The merge matches on the key alone, because the wording is regenerated every run. Draw keys from this fixed vocabulary, never an improvised slug:

| Move's subject | Key |
|---|---|
| an issue | `issue-12` |
| a PR | `pr-34` |
| a plan doc | `plan-<slug>`, the plan's own slug |
| one phase of a plan | `plan-<slug>-phase-<n>` |
| a doc awaiting review | `review-<name>`, the file name minus its serial and date, such as `review-plan-sso-login` |
| a local branch | `branch-issue-12-retry-budget` |
| a stash entry | `stash-<sha>`, the stash commit's short SHA from `git stash list --format='%h'`; an index such as `stash@{0}` moves whenever a new stash is pushed |
| a ladder rung with no subject | one fixed slug per rung: `push`, `reconcile`, `triage`, `prioritize`, `repo-labels`, `declare-tracker` |

**Put priority and leverage in a queued move's line** when it carries a priority above `medium` or an `unblocks` count above zero: `**Start #12 (critical, unblocks 3)** · \`issuekit start 12\``. Omit `unblocks 0`, and omit `medium` or a blank priority. Priority leads when both are present.

**Every move needs an observable retire signal**: the PR merged, the issue closed, the labels now exist, the tree went clean. The next survey detects completion from that signal, never from the ticks. A move with no such signal is a decision, so route it to `plankit` or file it with `issuekit create`.

**One issue or PR per checkbox.** When a rung applies to several issues, split it into one item per issue, each with its own number, title, and command, in the rung's order. The `Surfaced, not queued` list follows the same rule: one line per PR. A long list keeps its length; cap it as the tables do, most-recently-updated first, then a `+N more` line.

All three tables (unblocked, waiting for review, blocked issues) go into the file as printed, in that order. Beyond the provenance line and the checkbox lists, the file adds nothing the dashboard didn't contain.

**Leave the file uncommitted.** Commit it only if the user explicitly asks.

#### Write rules

statuskit writes local files only, and this table is the complete list. Nothing here reaches a remote, a branch, or a tracker.

| Write | When | Gate |
|---|---|---|
| The snapshot, `docs/status/NNNN-status-<slug>-YYYY-MM-DD.md` (a `Write`) | Every run, unless the user asked to skip it or no filesystem is writable. Creates `docs/status/` when missing. | None. Say where it went in the saved line. |
| One `docs/status/` line appended to the root `.gitignore` (an `Edit`) | Before the first snapshot, only when a root `.gitignore` exists and `git check-ignore -q docs/status/x.md` fails. With no root `.gitignore`, create none: the snapshot stays untracked. | None. Say it in the saved line. |
| One declaration sentence appended to an existing agent-guide file (an `Edit`) | Only from [the declaration offer](declaration.md), on an empty-array unknown reading. | A preview and the user's OK. |

`Edit` makes only those two appends. On a host that strips it, the snapshot stays untracked and [the declaration offer](declaration.md) prints the line for the user to place.

**No filesystem?** Print the snapshot as a codeblock with the canonical `docs/status/NNNN-status-<repo-slug>-YYYY-MM-DD.md` path, with `0001` when you can't list their snapshots, so the user can save it themselves.
