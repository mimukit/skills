# afkkit

Run a groomed `ready` GitHub issue through the whole build span unattended — worktree, implement, commit, verify, review, fix, QA plan, and open PR.

**Reach for it when** you want an issue taken to a reviewable PR with nobody at the keyboard.

| | |
|---|---|
| Modes | one issue, or [`all`](#batch-mode-all) |
| Tools | `Bash`, `Read`, `Task`, `Agent`, `Skill` |
| Writes | commits, a QA plan, a PR; issue labels; a git-excluded `.afkkit/` run directory |
| Visibility | public |

## What it does

afkkit is the **away-from-keyboard orchestrator**. It drives the middle of the workflow — the part that needs no human judgment once the issue is well-specified — from an isolated worktree to an open pull request.

The human gates stay where judgment lives: planning and grilling happen *before* (the `ready` label is the entry contract), review and merge happen *after*.

afkkit adds **no** worktree, tracker, or PR behavior of its own. It **sequences** companion kits and owns exactly one thing they don't: the **escalation policy** that decides, at every step, whether to keep going or stop cleanly.

It's the autonomous sibling of [`statuskit`](./statuskit.md): statuskit tells a human what to do next; afkkit does the next several things itself and stops where a human is genuinely required.

## The contract

| | |
|---|---|
| **Input** | an issue number, or `all` |
| **Success** | an open PR carrying documented assumptions, what the acceptance checks confirmed, unresolved nits, and a pointer to a committed QA plan — issue at `in-review` |
| **Blocked** | **no PR.** Worktree and commits intact, a comment naming the precise stuck-state, the issue labeled for whoever picks it up, and in a batch the next issue starts |

**afkkit never publishes half-broken work.**

## The safety property is the label, not who types the command

afkkit invokes [`issuekit`](./issuekit.md) `start` itself rather than acquiring the worktree directly. issuekit refuses anything not labeled `ready`, gets the worktree from [`gitkit`](./gitkit.md), and flips `ready → in-progress`.

That guard holds no matter who runs it: an issue only reaches `ready` after a human grill session, and **afkkit can neither promote an issue to `ready` nor start one that isn't.** It cannot get ahead of human judgment because the only door it has is locked against exactly that.

This is the one companion it will **not degrade around**. If issuekit isn't installed, afkkit refuses the run rather than reaching for `gh` to re-implement the guard — because a second copy of a gate is a gate that can drift open, and the copy inside an unattended orchestrator is exactly the one nobody would notice drifting.

**A GitHub tracker is required too, and that's a separate refusal.** The safety property is a label, so a project tracking its work in Linear, Jira, a file, or nobody's system has nothing for afkkit to stand on, even with every companion kit installed. afkkit is the one kit in the collection that genuinely cannot run without GitHub Issues, and unlike the rest it does not degrade to a plain `gh` fallback or a plan document — there is no substitute for a guard a human has to open.

It says that as the reason, rather than emitting a missing-dependency error. Those read as "go install issuekit," which sends you off to install a kit you already have and tells you nothing about the actual blocker. The route is [`issuekit`](./issuekit.md) `create` to file the plan first.

## How the conductor works

The session you invoke runs as a **conductor**, dispatching each heavy step as a subagent working inside the issue's worktree. That keeps the conductor's context small and lets each step run on the model that fits it.

The conductor's boundary is sharp: it **dispatches** subagents, **redistributes** their payloads, **reads** the workspace to verify a claim, and **decides** the next move. It **never writes to the workspace** — no editing code, no running a build, no staging, no committing. *Read yes, write no.*

It also **redistributes payloads rather than re-deriving them.** A later step usually needs an earlier one's result, and the conductor is the only thing holding it. Every payload class in the pipeline has a file, so a hand-off is a path plus the identifiers that matter — `apply B1, B3, N2 from .afkkit/findings-r1.md`, not a paragraph of re-quoted evidence.

**A dispatch has a floor**, and it's the rule that shapes the pipeline's step list. Every subagent pays a fixed cost before doing any work — spawn, orient, report — whether the step takes 175 tool uses or six. So a step that needs nothing but the previous agent's context doesn't get its own dispatch. That's why the commit is folded into implement and the fix rounds rather than dispatched: the agent that wrote the diff is still holding it, while a fresh one has to re-read all of it from cold to reach the same place. In the measured run, three standalone commit agents spent 92,839 tokens doing exactly that.

## The run directory

Every step after the spec gate needs the same handful of repo facts — the test and build commands, where output lands, the file establishing the pattern being followed. The gate discovers all of it.

Without somewhere to put it, that discovery is thrown away and each later step re-derives it from cold — **the single most expensive habit in this pipeline**, because every tool use re-bills the agent's whole accumulated context. The same argument covers every other payload: findings, assumptions, check results. Anything without a file gets re-typed by hand into the next prompt.

So everything lands in `.afkkit/` at the worktree root, excluded from git as a directory — one exclude line, however many payloads the run writes — so a reviewer never sees the agents' working notes.

| File | Written by | Read by |
|------|-----------|---------|
| `orientation.md` | spec gate | every later step |
| `assumptions.md` | spec gate | PR |
| `checks.md` | spec gate | verify, QA |
| `verified.md` | verify, refreshed by QA | review, QA |
| `findings-r<N>.md` | review round N | fix round N |

Each file carries **facts with sources, never conclusions**: not "the auth flow is fine" but "`src/auth/session.ts:40` sets the cookie `maxAge` from `SESSION_TTL`".

The trade is stated plainly: every downstream step inherits the gate's understanding, so a *wrong* orientation propagates silently, and a wrong check propagates the same way. That's the price of not paying for the same discovery five times — and it's why the gate stays on the strongest tier, and why the files carry facts rather than judgments. A wrong path is caught the moment a step opens it; a wrong conclusion is not.

## Why the spec gate writes the acceptance checks

`checks.md` is the least obvious file in that table and the most interesting one. It holds one entry per acceptance criterion: the observable that confirms it, a provisional command, and whether an agent can confirm it or only a human can.

The gate writes it for one reason that matters more than the cost saving: **it runs before any code exists.** A check list written afterwards tests what the code does. A check list written from the issue tests what the issue asked for. That's a test-first property the pipeline gets for free from a step it was already paying for, and it's why the command is deliberately provisional — the gate is describing an invocation that doesn't exist yet, so it writes the observable precisely and the command approximately.

## Model routing, and what a step actually costs

**Cost tracks context size × turns, not token volume and not how often a step fires.** A measured run bears this out sharply: the two steps that *explored the codebase* — each running exactly once — were over 40% of the bill between them, while three mechanical commit dispatches were under 9% for work the previous agent could have done in a handful of turns.

**The way to make a step cheap is to hand it what it needs, not to ask it to think less** — and the cheapest step of all is the one that never gets its own dispatch.

| Step | Model | Why |
|------|-------|-----|
| Spec gate | `opus` | gates the whole run; every later step inherits its orientation and its check list |
| Implement | `opus` | the bulk of the work, with implementkit's own gate underneath; commits its own work |
| Verify | `opus` | runs the code rather than reading it; small context, so the strong tier is cheap here |
| Review | `fable` | a **different model family** from the one that wrote the code |
| Fix | `opus` | applying findings against a concrete list; commits its own work |
| QA plan | `opus` | grounded generation against an already-green gate and an already-run check list |
| PR | `opus` | title and body from real commits plus handed-in payload paths |

**Commit has no row on purpose**, and the consequence is that no step routes to `haiku` any more. The arithmetic that made `haiku` the cheap tier still holds; the table simply has no mechanical-enough step left to spend it on.

**Review runs on a different family, not a "better" one.** An implementer and reviewer from the same family share blind spots by construction, so routing review to `fable` buys *independence*. It is explicitly **not the cheap option** — `fable` ran roughly 4× `opus`'s cost per token in the measured run. That's a deliberate purchase of a second opinion, priced so nobody mistakes it for a saving. Verify doesn't get the same tier even though independence is its point too: a fresh `opus` agent already has no memory of writing the code, which is the property Verify actually needs, and paying the premium twice buys very little.

**Implement, the spec gate, and Verify's probe are never budgeted.** Implement needed 175 tool uses because the work needed 175, the gate's exploration is what every later step depends on, and Verify's probe is where the run's three surprise defects came from. Nudging any of them toward a smaller number buys cheaper, worse output — the one trade this pipeline should never make.

## The pipeline

1. **Start the issue** — issuekit `start`, dispatched on the conductor's own model rather than the cheap tier, because issuekit can refuse four distinguishable ways and a relay that flattens them breaks the escalation policy silently. The conductor then verifies what came back rather than taking it on faith.
2. **Spec gate** — classify gaps between what the issue specifies and what building it requires, and write the run directory. **Missing decisions** escalate to `needs-planning` before any code is written, the cheapest possible failure point. **Missing mechanics only** proceed.
3. **Implement** — implementkit, which resolves its own mode and enforces the repo's gate. The same agent commits through commitkit before it returns.
4. **Verify** — run the gate's check list against the now-green code, then probe up to six adjacent behaviors. Writes `verified.md`, edits nothing, and never rebuilds.
5. **Review** — reviewkit against the branch diff plus `verified.md`, told it *is* the fresh reviewer so it doesn't delegate again and pay for a second full read.
6. **Fix loop** — bounded at two rounds, re-review **delta-scoped** to the fix commits. Round 1 sweeps every cheap nit alongside the blockers; a delta re-review's nits go to the PR body instead of earning a round, so only a blocker can extend the loop.
7. **QA plan** — qakit, handed the check list, the recorded outcomes, the green gate, and the build location. It re-runs the checks against the final code and writes the human plan; it never rebuilds.
8. **Open the PR** — prkit, handed paths: the assumptions file, the findings files and the unresolved nit IDs, `verified.md`, unmet criteria, and the QA-plan path.

## Why verification moved before review

In the measured run, QA ran last and caught three defects both review rounds missed. That's not a smarter agent — **review reads the code and the checks run it**, and running it is a lens reading doesn't have. But because it ran last, nothing it learned could reach the fix loop.

Splitting the step by job fixes that without losing either half. Running the checks is defect discovery, so it wants to happen as early as the code is green. Writing the manual plan is grounded generation, so it wants the final diff. They now sit at opposite ends of the pipeline, and QA arrives holding results it no longer has to produce.

A ❌ from Verify is **evidence, not an escalation** — review ranks it through reviewkit's own requirement-completeness pass, so afkkit adds no second severity classifier. The one exception is total: code that doesn't run at all is an execution gap, and there's no point paying for a review of it.

Verify is also the one step that invokes no companion kit — it runs the check list the spec gate wrote, nothing more. That's a degradation guard: a missing qakit blocks the QA *plan*, never the *checks*, so an unattended run still gets its defect discovery even on a host where only afkkit's hard requirements are installed.

## The escalation contract

The one policy afkkit owns. Whenever a step can't proceed, it escalates rather than pushing forward.

**First, it verifies a "pre-existing" claim before accepting it.** A step reporting a gate as red-but-already-broken is asking to be excused from the one check standing between an unattended run and a shipped regression — and it's the easiest thing for a subagent to get wrong, because a failure it caused and one it inherited look identical from inside the worktree. The conductor re-runs that command against the **base branch** first.

**A step that needs consent, with nobody to ask, escalates.** No prompt can be answered in an unattended run, so a step reaching a preview-and-confirm gate stops rather than waiting or assuming a yes — an execution gap, commented and left `in-progress`. Two mutations in this pipeline are exempt at the *mode*, not by afkkit's asking: [`issuekit`](./issuekit.md) `start`'s `ready → in-progress` flip and [`prkit`](./prkit.md)'s advance to `in-review`. Both run unprompted for every caller, which is why the pipeline reaches an open PR without a human. afkkit relies on exemptions the owning skill already wrote and never widens one.

Then escalation always means the same five things:

1. **No PR.**
2. **Keep the work** — worktree and every commit intact.
3. **Comment the stuck-state** precisely.
4. **Set the label by *cause*** — a **planning gap** (a missing *decision*) flips to `needs-planning` and goes back to the grill queue; an **execution gap** (tests won't go green, blockers survive) **keeps `in-progress`**, because the issue isn't waiting on a decision.
5. **Continue the batch.**

**Escalation is a success, not a failure.** Stopping cleanly at a wall is afkkit doing its job. The failure mode it exists to prevent is pushing a half-broken change all the way to a PR.

## Batch mode: `all`

Takes its queue from `gh issue list --label ready` and walks it **sequentially** — a conclusion, not an unexamined v1 limit. Implement alone was 44% of the measured wall clock and is irreducibly serial, so perfect parallelization of everything else caps the saving near 55%. The one genuinely independent pair, QA and review, is unsafe: a QA plan written from a diff the fix loop then changes describes behavior that no longer exists. Moving live verification to its own early step captures the useful part of that overlap without the staleness.

**The queue is ordered by [`issuekit`](./issuekit.md) priority** — `critical` first, then `high`, `medium`, `low`, unassessed last, with oldest-updated breaking ties within a level. The labels come back in the same `labels` array the call already fetches, so the ordering costs nothing. It matters more here than anywhere else in the workflow because an unattended batch is the one place nobody is watching to reorder it: a run that stops early after four of nine issues has silently *chosen* which four shipped, and priority is what makes that choice yours rather than the tracker's arbitrary sort. With no priorities set anywhere it falls back to oldest-first and says so, rather than implying a ranking that isn't there.

**Priority orders the queue and relaxes nothing.** A `critical` issue goes first and is otherwise an ordinary run — it still needs `ready`, still faces the spec gate, still escalates rather than guessing. An unattended agent is precisely where that has to hold, since the human who declared the emergency isn't there to catch what a relaxed gate would let through.

**One confirmation, up front** — the queue is printed with each issue's priority, in walk order, and waits for a single OK. The human is by definition still at the keyboard the moment they type `afkkit all`, so this costs nothing and is the last chance to pull an issue promoted too early. After that OK the run is unattended, whatever happens.

**The queue is fixed at that OK**, not re-read before each issue. The run mutates labels as it goes, so re-reading would drain issues nobody approved.

**Issues start just in time**, each at the top of its own run — so a worktree branches off a freshly fetched base rather than one that went stale in a queue, and a batch that stops early leaves untouched issues in `ready` rather than orphaned at `in-progress`.

Each issue's payloads are **dropped once it terminates**, so a batch working its tenth issue isn't still paying for the first one's findings on every turn.

## Hands off to

By outcome. **Opened** → [`mergekit`](./mergekit.md) `start`, which pulls the PR into the worktree it was built in. **Escalated to `needs-planning`** → [`grillkit`](./grillkit.md) on the open questions, then re-run — re-running as-is would stop at the same wall. **Escalated still `in-progress`** → pick it up in the existing worktree by hand.

Nobody watched the run, so the report *is* the handover — and it always names the worktree path, because on an escalation those commits are real work sitting on disk and a human who doesn't know where they are will start over.

It also prints a **per-step metrics table** — model, time, tool uses, and tokens where the harness reports them. The conductor fills it from what each dispatch hands back and measures nothing itself. That table exists so the routing table's baselines get corrected from real runs rather than one remembered one, which is why it prints only the columns the host actually provides: an estimated number would defeat the entire point. The metrics live in the report and nowhere else — writing them to disk would put the conductor inside the workspace its own boundary rules out.

## Install

```sh
npx skills add mimukit/skills -s afkkit
```

Source: [`skills/afkkit/SKILL.md`](../../../skills/afkkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`06848f6` on 2026-08-20._
