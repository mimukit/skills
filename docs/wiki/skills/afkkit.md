# afkkit

Run a groomed `ready` GitHub issue through the whole build span unattended: worktree, implement, commit, QA plan, acceptance check, fix, and open PR.

**Reach for it when** you want an issue taken to a reviewable PR with nobody at the keyboard.

| | |
|---|---|
| Modes | one issue, or [`all`](#batch-mode-all) |
| Tools | `Bash`, `Read`, `Grep`, `Glob`, `Edit`, `Write`, `Task`, `Agent`, `SendMessage`, `Skill` |
| Writes | commits (pushed once, at the PR step), a QA plan, a PR; issue labels; a git-excluded `.afkkit/` run directory |
| Visibility | public |

## What it does

afkkit is the **away-from-keyboard orchestrator**. It drives the middle of the workflow, the part that needs no human judgment once the issue is well-specified, from an isolated worktree to an open pull request.

The human gates stay where judgment lives: planning and grilling happen before (the `ready` label is the entry contract), review and merge happen after. Deep code review also sits after the span: a PR-level review bot covers the diff once the PR opens, which is why afkkit runs exactly one acceptance check in-span instead of a review loop.

afkkit adds **no** worktree, tracker, or PR behavior of its own. It **sequences** companion kits and owns exactly one thing they don't: the **escalation policy** that decides, at every step, whether to keep going or stop cleanly.

You run it from the main checkout, in the session you already have open. One command starts the issue, gets the worktree, and works inside it by path, so there is no second session to open in the worktree and no four-step build prompt to retype. A host that can attach a new conversation to a worktree, such as T3 Code, may show the run there, but the skill does not need one.

When the issue starts, afkkit also reports how many feature PRs you already have open, through [`issuekit`](./issuekit.md)'s open-PR check. An unattended run never stops on that count; at 3 or more the hand-off says so, and an `all` queue shows the count above the queue before its one OK.

It's the autonomous sibling of [`statuskit`](./statuskit.md): statuskit tells a human what to do next; afkkit does the next several things itself and stops where a human is genuinely required.

## The contract

| | |
|---|---|
| **Input** | an issue number, or `all` |
| **Authorization** | naming the issue, or the one OK on an `all` queue, authorizes the worktree, commits on the issue's own branch, one push of that branch, and its PR through prkit; nothing else |
| **Success** | an open PR that opens with the documented assumptions as text, what the acceptance checks confirmed, unresolved nits as known follow-ups, and a pointer to a committed QA plan; issue at `in-review` |
| **Blocked** | **no PR.** Worktree and commits intact, a comment naming the precise stuck-state, the issue labeled for whoever picks it up, and in a batch the next issue starts |

**afkkit never publishes half-broken work.** Every commit before the PR step uses [`commitkit`](./commitkit.md)'s `no-push`, so the branch reaches `origin` only when [`prkit`](./prkit.md) opens the PR. An escalated run leaves its commits on disk and nothing on the remote.

**Why the authorization is stated at entry.** prkit previews PR creation and its QA-plan commit, and afkkit escalates any preview it cannot answer. Without a stated scope, the normal successful run would stop at its last step. So the user's request is the answer, and afkkit hands it to every dispatch; prkit accepts it as the OK for exactly the actions it names. The list is closed: a force-push, a rebase of a published branch, a push to another branch, or a merge still needs a person, so the run escalates on it. The one way to widen it is in writing: an outward action the issue body pre-approves by name, such as "may file follow-up issues", joins the list for that issue. A grill is where such an approval gets recorded.

## The safety property is the label, not who types the command

afkkit invokes [`issuekit`](./issuekit.md) `start` itself rather than acquiring the worktree directly. issuekit refuses anything not labeled `ready`, gets the worktree from [`gitkit`](./gitkit.md), and flips `ready → in-progress`.

That guard holds no matter who runs it: an issue only reaches `ready` after a human grill session, and **afkkit can neither promote an issue to `ready` nor start one that isn't.**

This is the one companion it will **not degrade around**. If issuekit isn't installed, afkkit refuses the run rather than reaching for `gh` to re-implement the guard, because a second copy of a gate is a gate that can drift open, and the copy inside an unattended orchestrator is exactly the one nobody would notice drifting.

**A GitHub tracker is required too, and that's a separate refusal.** The safety property is a label, so a project tracking its work in Linear, Jira, or a file has nothing for afkkit to stand on, even with every companion kit installed. It says that as the reason rather than emitting a missing-dependency error, and routes to [`issuekit`](./issuekit.md) `create` to file the plan first.

## Why one warm session

afkkit used to run as a conductor that dispatched a fresh subagent for every step. The design bought clean per-step contexts and per-step model choice, and it lost on the numbers. The one recorded run of that shape (saasaloy #16) took about 87 active minutes and 49M tokens across 11 subagents. Over the same weeks, the owner stopped using afkkit and pasted a four-line prompt instead: `/implementkit`, `/qakit`, `/commitkit all`, `/prkit`, in one session, with "take the best decision and list it at the end". Across 41 such runs the median was 21 minutes and 17M tokens, and 40 reached a PR.

The difference was structural, not a matter of tuning. Every subagent starts cold and rediscovers what the last one knew: in the conductor run, `pnpm deps:check` ran about 13 times across 9 agents, and four steps re-proved the same red base. One session that holds the issue from start to PR pays for each discovery once.

So afkkit now runs the whole issue in the session you invoke it in, and keeps only what the pasted prompt lacked: the `ready` guard, the spec gate, the escalation contract, `no-push` until the PR, and one acceptance check. A long build still splits, but [`implementkit`](./implementkit.md) decides that under its own conductor rule, and afkkit adds no second one. Commits land at every phase boundary, so a usage-limit stop loses at most the phase in flight, and a re-run resumes from `progress.md`.

**Every subagent is a new agent, never a fork.** In the conductor run, the reviewer was forked with the conductor's whole transcript. It decided it was the conductor, reviewed its own work, wrote "no blockers", and opened the PR itself, so the fix step never ran. A fresh agent with a brief that names its role and its edge cannot make that mistake.

## The run directory

Each step writes its payload once, so a resumed run and the acceptance check read a path instead of re-deriving it. Everything lands in `.afkkit/` at the worktree root, excluded from git as a directory, so a reviewer never sees the working notes.

| File | Written by | Read by |
|------|-----------|---------|
| `assumptions.md` | spec gate, then every step that decides something | the PR body (as text), the acceptance check |
| `checks.md` | spec gate | qakit, the acceptance check |
| `orientation.md` | the step that starts the dev server or claims a pre-existing failure | every later step, the acceptance check |
| `findings.md` | the acceptance check | fix |
| `progress.md` | every step that lands work, one line each | a resumed run |

**`assumptions.md` is the pasted prompt's decisions list, kept.** The owner valued that list enough to ask for it on every run, and a list written from memory at the end of a long session is the one that drops items. So the run appends each decision as it takes it, and the PR body opens with those entries as text under an **Assumptions** heading, above the summary. They are the decisions the run took on your behalf, which is what a reviewer must check before anything else. The body never points into `.afkkit/`, because a reviewer on GitHub cannot open a git-excluded file.

`orientation.md` carries **facts with sources, never conclusions**, and only two kinds: the dev-server commands, and each pre-existing failure claim with its command and exit code. Those are the two facts the history shows being re-derived over and over.

## Why the spec gate looks for attended work

A run that reaches a design pick or an unapproved outward action in the middle stops with half the work built, and the person who could answer comes back to an escalation instead of a PR. Those stops are visible in the issue before any code exists, so the gate looks for them there. The fix is upstream: [`plankit`](./plankit.md) marks attended phases, and [`grillkit`](./grillkit.md) settles them or records the approval in the plan.

## Why the spec gate writes the acceptance checks

`checks.md` holds one line per acceptance criterion: the observable that confirms it, and whether an agent can confirm it or only a human can. It carries no commands; [`qakit`](./qakit.md) works those out from what shipped. The flag follows qakit's test: if a script can assert the pass condition, the check is the agent's. With a browser driver on the box, that includes most of what a page shows, so the manual cases that reach the PR are the ones that need taste.

The gate writes it for one reason that matters more than the cost saving: **it runs before any code exists.** A check list written afterwards tests what the code does. A check list written from the issue tests what the issue asked for. That's a test-first property the pipeline gets for free from a step it was already paying for, and it is what the acceptance check measures the result against.

## Model routing

There is none. Every step runs on the session's model, and you can name another one inline ("afkkit 42, acceptance check on sonnet").

The old rule sent the review to a different model family, on the theory that an implementer and a reviewer from one family share blind spots. The one recorded cross-family review found nothing, and the cause was context, not model: the reviewer had inherited the builder's transcript. A reviewer with a fresh context buys most of the independence, and the owner judged the current writer model strong enough that a second family was not worth its share of the session budget.

## The pipeline

1. **Start the issue**: issuekit `start`, which also returns the open-PR count. The session verifies the worktree, branch, and label in one shell call. On a refusal the run reports issuekit's reason verbatim and mutates nothing.
2. **Spec gate**: one read of the issue and the code it touches. **Missing decisions** and **attended work** escalate to `needs-planning` before any code. **Missing mechanics** proceed and go into `assumptions.md`. The gate writes `checks.md`.
3. **Implement**: [`implementkit`](./implementkit.md), split into phase-group subagents only when its own rule says so, with a [`commitkit`](./commitkit.md) `no-push` commit at every phase boundary.
4. **QA plan**: [`qakit`](./qakit.md) writes the plan, runs every agent check (in the headless browser when a driver is present), and captures a screenshot of each screen a human must judge. Code that does not run at all escalates here.
5. **Acceptance check**: the run's one dispatch, described below.
6. **Fix**: when the check found blockers, the session applies them through implementkit's fix round, commits, and has qakit update the plan in place.
7. **Open the PR**: [`prkit`](./prkit.md) commits the QA plan, pushes the branch for the first time, opens the PR with the assumptions first, and advances the issue to `in-review`.
8. **Hand off**: the outcome line, every assumption, the worktree path, and one crowned next move. Per-step metrics print only when the invocation asks for them ("afkkit 42 with metrics").

## Resuming an interrupted run

Adopting an existing worktree says nothing about which steps already passed, so a re-run reads the state before it dispatches anything. An open PR on the branch means the run stopped after PR creation, and only the `in-review` advance is left. The branch on `origin` with no PR means it stopped after the push, so it goes straight to the PR. Unpushed commits are matched against `progress.md`, where each phase group, the QA plan, the acceptance check, the fix commit, and the QA refresh leave one line, and the run resumes at the first step with no line. A usage-limit stop is the common case, and the per-phase commits are what keep it cheap. A commit named there but missing from the branch, a remote branch that disagrees with the local one, or uncommitted changes nobody recorded all escalate, because afkkit cannot tell whose work they are.

Because nothing is pushed before the PR step, the remote state alone separates "finished" from "not yet published", which is what makes this table short.

## The acceptance check

The pasted prompt had no review, and it showed: 6 of 41 runs drew a defect report afterward, all on UI work. Design B shipped where A was chosen, a sidebar was missing, links opened in the same tab, hero images were blurry. Each follow-up cost 15M to 21M tokens, more than a whole run. Most of those were not code bugs a diff reader would flag. They were misses against what the issue asked for.

So the one review the run keeps is aimed at that class. A new subagent gets the issue, the diff range, `assumptions.md`, `checks.md`, `orientation.md`, and qakit's plan with its screenshots, and nothing from the session. It runs [`reviewkit`](./reviewkit.md)'s requirement-completeness and correctness passes only, treats a screenshot that contradicts a criterion as a blocker even when the diff reads fine, and checks each assumption against the issue. It reports blockers only; style and taste belong to the PR review bot and the human.

**Why qakit runs first.** qakit now drives the browser itself, so it is the one step that opens it. Running the check after qakit hands the reviewer real screenshots and real ❌ results without a second dev server or a second browser loop. After a fix, qakit updates the plan in place, and its own revision rule decides what to run again.

**It also grades the pre-existing failure claims.** In a warm session, the agent that broke a gate would otherwise be the one excusing it. The checker re-runs each claimed command once on the base branch, so the builder never grades its own excuse.

## Why there is only one review round

The old pipeline ran up to three review rounds with a bounded fix loop between them, and the delta rounds bought the least. A PR-level review bot covers the diff again after the PR opens, so surviving depth has a home outside the span. One acceptance check, one fix pass, then the bot and the human reviewer take over.

## The escalation contract

The one policy afkkit owns. Whenever a step can't proceed, it escalates rather than pushing forward.

**It verifies a "pre-existing" claim before accepting it.** A step reporting a gate as red-but-already-broken is asking to be excused from the one check standing between an unattended run and a shipped regression. The acceptance check re-runs that command against the **base branch**: green base means the failure belongs to this branch and is a blocker; red base means the claim holds, and any acceptance criterion that cannot be met from repo state goes into the PR body explicitly.

**A step that needs consent, with nobody to ask, escalates.** Two things run without a prompt: the actions the entry authorization names, and label writes the owning skills already run unprompted for every caller: [`issuekit`](./issuekit.md) `start`'s `ready → in-progress` flip and [`prkit`](./prkit.md)'s advance to `in-review`. afkkit never widens one.

Then escalation always means the same five things: **no PR**, **keep the work**, **comment the stuck-state**, **set the label by cause** (a missing decision flips to `needs-planning`; a stuck execution keeps `in-progress`), and **continue the batch**.

**Escalation is a success, not a failure.** The failure mode afkkit exists to prevent is pushing a half-broken change all the way to a PR.

## Batch mode: `all`

Takes its queue from `gh issue list --label ready` and walks it **sequentially**. Implement dominates the wall clock and is irreducibly serial, parallel branches off one base make merge behavior unpredictable, and parallel sessions share one usage budget and stall each other into session limits.

**Each issue gets a new agent, and the invoking session becomes a thin conductor.** Issue N's context must not bill issue N+1's turns. The issue agent runs from start through the QA plan. The conductor then dispatches the acceptance check itself, because on Claude-compatible hosts a subagent cannot start one, and it continues the same issue agent with the findings so the fix and the PR keep the warm context.

The queue is ordered by [`issuekit`](./issuekit.md) priority, highest first, oldest-updated breaking ties, unassessed last. **Priority orders the queue and relaxes nothing**: a `critical` issue still needs `ready`, still faces the spec gate, still escalates rather than guessing.

One confirmation, up front: the queue prints with priorities in walk order and waits for a single OK, after which the run is unattended, whatever happens. The queue is **fixed at that OK**, never re-read, so the run cannot drain issues nobody approved. Issues start just in time, so a batch that stops early leaves unreached issues untouched in `ready`.

`in-progress` and `stacked` issues are passed over, and the preview names them with their priorities and says why. Silence would read as "unworkable" when the truth is that only this runner declines them; name one explicitly (`afkkit 44`) to run it.

Each issue's payloads are dropped once it terminates, so a batch working its tenth issue isn't still paying for the first one's findings on every turn. The batch summary lists PRs opened, escalations by state, skips, and any unreached issues with their priorities, then crowns one next move.

## Hands off to

By outcome. **Opened** → [`mergekit`](./mergekit.md) `start`, which pulls the PR into the worktree it was built in. **Escalated to `needs-planning`** → [`grillkit`](./grillkit.md) on the open questions, then [`issuekit`](./issuekit.md) `triage` to promote the issue back to `ready` on your word, then re-run. **Escalated still `in-progress`** → pick it up in the existing worktree by hand.

Nobody watched the run, so the report is the handover, and it always names the worktree path, because on an escalation those commits are real work sitting on disk.

## Install

```sh
npx skills add mimukit/skills -s afkkit
```

Source: [`skills/afkkit/SKILL.md`](../../../skills/afkkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`827b320` on 2026-10-20._
