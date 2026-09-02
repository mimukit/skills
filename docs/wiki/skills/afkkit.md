# afkkit

Run a groomed `ready` GitHub issue through the whole build span unattended: worktree, implement, commit, verify-and-review, fix, QA plan, and open PR.

**Reach for it when** you want an issue taken to a reviewable PR with nobody at the keyboard.

| | |
|---|---|
| Modes | one issue, or [`all`](#batch-mode-all) |
| Tools | `Bash`, `Read`, `Task`, `Agent`, `Skill` |
| Writes | commits, a QA plan, a PR; issue labels; a git-excluded `.afkkit/` run directory |
| Visibility | public |

## What it does

afkkit is the **away-from-keyboard orchestrator**. It drives the middle of the workflow, the part that needs no human judgment once the issue is well-specified, from an isolated worktree to an open pull request.

The human gates stay where judgment lives: planning and grilling happen before (the `ready` label is the entry contract), review and merge happen after. Deep code review also sits after the span now: a PR-level review bot covers the diff once the PR opens, which is why afkkit runs exactly one review round in-span instead of a bounded fix-and-re-review loop.

afkkit adds **no** worktree, tracker, or PR behavior of its own. It **sequences** companion kits and owns exactly one thing they don't: the **escalation policy** that decides, at every step, whether to keep going or stop cleanly.

It's the autonomous sibling of [`statuskit`](./statuskit.md): statuskit tells a human what to do next; afkkit does the next several things itself and stops where a human is genuinely required.

## The contract

| | |
|---|---|
| **Input** | an issue number, or `all` |
| **Success** | an open PR carrying documented assumptions, what the acceptance checks confirmed, unresolved nits as known follow-ups, and a pointer to a committed QA plan; issue at `in-review` |
| **Blocked** | **no PR.** Worktree and commits intact, a comment naming the precise stuck-state, the issue labeled for whoever picks it up, and in a batch the next issue starts |

**afkkit never publishes half-broken work.**

## The safety property is the label, not who types the command

afkkit invokes [`issuekit`](./issuekit.md) `start` itself rather than acquiring the worktree directly. issuekit refuses anything not labeled `ready`, gets the worktree from [`gitkit`](./gitkit.md), and flips `ready → in-progress`.

That guard holds no matter who runs it: an issue only reaches `ready` after a human grill session, and **afkkit can neither promote an issue to `ready` nor start one that isn't.**

This is the one companion it will **not degrade around**. If issuekit isn't installed, afkkit refuses the run rather than reaching for `gh` to re-implement the guard, because a second copy of a gate is a gate that can drift open, and the copy inside an unattended orchestrator is exactly the one nobody would notice drifting.

**A GitHub tracker is required too, and that's a separate refusal.** The safety property is a label, so a project tracking its work in Linear, Jira, or a file has nothing for afkkit to stand on, even with every companion kit installed. It says that as the reason rather than emitting a missing-dependency error, and routes to [`issuekit`](./issuekit.md) `create` to file the plan first.

## How the conductor works

The session you invoke runs as a **conductor**, dispatching each heavy step as a subagent working inside the issue's worktree. That keeps the conductor's context small and lets each step run on the model that fits it.

The conductor's boundary is sharp: it **dispatches** subagents, **redistributes** their payloads, **reads** the workspace to verify a claim, and **decides** the next move. It **never writes to the workspace**. *Read yes, write no.*

It also **redistributes payloads rather than re-deriving them.** Every payload class in the pipeline has a file, so a hand-off is a path plus the identifiers that matter (`apply B1, B3, N2 from .afkkit/findings.md`), not a paragraph of re-quoted evidence.

**A dispatch has a floor**, and it's the rule that shapes the step list. Every subagent pays a fixed cost before doing any work, whether the step takes 175 tool uses or six. So a step that needs nothing but the previous agent's context doesn't get its own dispatch. That's why the commit is folded into implement, and why the fix, QA plan, and PR now share one tail dispatch: the agent that applied the fixes is already warm in the diff and the run files that the QA plan and PR body are written from. The floor's converse keeps implement's per-phase dispatches: phase N+1 needs phase N's committed code, not its transcript.

## The run directory

Every step after the spec gate needs the same handful of repo facts, and the gate discovers all of them. Without somewhere to put them, each later step re-derives them from cold, the single most expensive habit in the pipeline, because every tool use re-bills the agent's whole accumulated context.

So everything lands in `.afkkit/` at the worktree root, excluded from git as a directory, so a reviewer never sees the agents' working notes.

| File | Written by | Read by |
|------|-----------|---------|
| `orientation.md` | spec gate | every later step |
| `assumptions.md` | spec gate | fix-and-finish (PR body) |
| `checks.md` | spec gate | verify-and-review, fix-and-finish |
| `verified.md` | verify-and-review, refreshed by fix-and-finish | fix-and-finish (QA plan) |
| `findings.md` | verify-and-review | fix-and-finish |

Each file carries **facts with sources, never conclusions**: not "the auth flow is fine" but "`src/auth/session.ts:40` sets the cookie `maxAge` from `SESSION_TTL`".

The trade is stated plainly: every downstream step inherits the gate's understanding, so a wrong orientation propagates silently. That's the price of not paying for the same discovery five times, and it's why the files carry facts rather than judgments. A wrong path is caught the moment a step opens it; a wrong conclusion is not.

## Why the spec gate writes the acceptance checks

`checks.md` holds one entry per acceptance criterion: the observable that confirms it, a provisional command, and whether an agent can confirm it or only a human can.

The gate writes it for one reason that matters more than the cost saving: **it runs before any code exists.** A check list written afterwards tests what the code does. A check list written from the issue tests what the issue asked for. That's a test-first property the pipeline gets for free from a step it was already paying for, and it's why the command is deliberately provisional: the gate writes the observable precisely and the command approximately.

## Model routing

Routing collapsed to two rules plus a spoken override, with no per-step table and no config file:

- **Every step runs on the host's primary writer model** (`opus` on Claude-compatible hosts, `gpt-5.6-sol` on Codex).
- **Verify-and-review runs on a different model family** (`fable`, or `gpt-5.5` on Codex). An implementer and reviewer from the same family share blind spots by construction, and the independence is bought exactly once, on the run's only review round.

Cost tracks **context size × turns**, not token volume, so the way to make a step cheap is to hand it what it needs, not to ask it to think less. The mechanical tail work (QA transcription, PR body) gets an explicit "don't explore" budget in its prompt; implement, the spec gate, and the verify probe are never budgeted, because nudging them toward fewer tool uses buys cheaper, worse output.

## The pipeline

1. **Start the issue**: issuekit `start`, sharing one dispatch with the spec gate. On a refusal the agent returns issuekit's reason verbatim and never begins the gate; the conductor verifies the returned worktree, branch, and label in one batched shell call.
2. **Spec gate**: the same agent classifies gaps between what the issue specifies and what building it requires, writes `orientation.md`, `assumptions.md`, and `checks.md`, and returns the issue's phases grouped into dispatch groups. **Missing decisions** escalate to `needs-planning` before any code is written, the cheapest possible failure point. **Missing mechanics only** proceed, logged to `assumptions.md`.
3. **Implement**: implementkit, one dispatch per phase group, each committing through commitkit before it returns. Every step after this one runs once, over the whole branch diff.
4. **Verify and review**: one dispatch on the independent model runs the gate's check list, probes up to six adjacent behaviors, writes `verified.md`, then invokes reviewkit on the full branch diff and writes `findings.md` with stable blocker and nit IDs. It runs code but edits nothing, never rebuilds, and records the exact server start and stop commands it used. Code that doesn't run at all escalates before any review is paid for.
5. **Fix and finish**: one tail dispatch on the writer model applies every blocker plus the cheap nits by ID, re-runs the checks its changes touch, refreshes `verified.md`, commits, then writes the QA plan through qakit (pure transcription, nothing re-run) and opens the PR through prkit, which commits the QA doc, pushes, and advances the issue to `in-review`. A blocker it cannot fix escalates, and no PR opens with known blockers in it.
6. **Hand off**: the outcome line, the worktree path, and one crowned next move. Per-step metrics print only when the invocation asks for them ("afkkit 42 with metrics").

## Why verify and review share one dispatch

Review reads the code; the checks run it, and running it is a lens reading doesn't have. In a measured run, live verification caught three defects two review rounds missed. Merging the two puts that live evidence directly in the reviewer's hands: it ranks a failing check through reviewkit's own requirement-completeness pass instead of receiving `verified.md` second-hand, and the pipeline sheds a dispatch floor plus a file relay.

The merged step keeps verification's hard rules (no edits, no rebuilds) because a failure is evidence for the review, not something to work around. And it inherits the independent model, so the one review round the run has is still a different family from the one that wrote the code.

## Why there is only one review round

The old pipeline ran up to three review rounds with a bounded fix loop between them. The delta rounds bought the least: they re-checked named fixes against a findings list the run already trusted, which is where independence buys nothing, and an unscoped delta round once read `node_modules` and outgrew round 1. A PR-level review bot now covers the diff again after the PR opens, so surviving depth has a home outside the span. One in-span round on the independent model, one fix pass, then the bot and the human reviewer take over.

## The escalation contract

The one policy afkkit owns. Whenever a step can't proceed, it escalates rather than pushing forward.

**It verifies a "pre-existing" claim before accepting it.** A step reporting a gate as red-but-already-broken is asking to be excused from the one check standing between an unattended run and a shipped regression. The conductor re-runs that command against the **base branch** first: green base means the failure belongs to this branch and escalates; red base means the claim holds, and any acceptance criterion that cannot be met from repo state goes into the PR body explicitly.

**A step that needs consent, with nobody to ask, escalates.** The only exemptions are label writes the owning skills already run unprompted for every caller: [`issuekit`](./issuekit.md) `start`'s `ready → in-progress` flip and [`prkit`](./prkit.md)'s advance to `in-review`. afkkit never widens one.

Then escalation always means the same five things: **no PR**, **keep the work**, **comment the stuck-state**, **set the label by cause** (a missing decision flips to `needs-planning`; a stuck execution keeps `in-progress`), and **continue the batch**.

**Escalation is a success, not a failure.** The failure mode afkkit exists to prevent is pushing a half-broken change all the way to a PR.

## Batch mode: `all`

Takes its queue from `gh issue list --label ready` and walks it **sequentially**. Implement dominates the wall clock and is irreducibly serial, parallel branches off one base make merge behavior unpredictable, and parallel conductor sessions share one usage budget and stall each other into session limits.

The queue is ordered by [`issuekit`](./issuekit.md) priority, highest first, oldest-updated breaking ties, unassessed last. **Priority orders the queue and relaxes nothing**: a `critical` issue still needs `ready`, still faces the spec gate, still escalates rather than guessing.

One confirmation, up front: the queue prints with priorities in walk order and waits for a single OK, after which the run is unattended, whatever happens. The queue is **fixed at that OK**, never re-read, so the run cannot drain issues nobody approved. Issues start just in time, so a batch that stops early leaves unreached issues untouched in `ready`.

`in-progress` and `stacked` issues are passed over, and the preview names them with their priorities and says why. Silence would read as "unworkable" when the truth is that only this runner declines them; name one explicitly (`afkkit 44`) to run it.

Each issue's payloads are dropped once it terminates, so a batch working its tenth issue isn't still paying for the first one's findings on every turn. The batch summary lists PRs opened, escalations by state, skips, and any unreached issues with their priorities, then crowns one next move.

## Hands off to

By outcome. **Opened** → [`mergekit`](./mergekit.md) `start`, which pulls the PR into the worktree it was built in. **Escalated to `needs-planning`** → [`grillkit`](./grillkit.md) on the open questions, then re-run. **Escalated still `in-progress`** → pick it up in the existing worktree by hand.

Nobody watched the run, so the report is the handover, and it always names the worktree path, because on an escalation those commits are real work sitting on disk.

## Install

```sh
npx skills add mimukit/skills -s afkkit
```

Source: [`skills/afkkit/SKILL.md`](../../../skills/afkkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`7687f62` on 2026-09-02._
