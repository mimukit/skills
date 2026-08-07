# afkkit

Run a groomed `ready` GitHub issue through the whole build span unattended — worktree, implement, commit, review, fix, QA plan, and open PR.

**Reach for it when** you want an issue taken to a reviewable PR with nobody at the keyboard.

| | |
|---|---|
| Modes | one issue, or [`all`](#batch-mode-all) |
| Tools | `Bash`, `Read`, `Task`, `Agent`, `Skill` |
| Writes | commits, a QA plan, a PR; issue labels |
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
| **Success** | an open PR carrying documented assumptions, unresolved nits, and a pointer to a committed QA plan — issue at `in-review` |
| **Blocked** | **no PR.** Worktree and commits intact, a comment naming the precise stuck-state, the issue labeled for whoever picks it up, and in a batch the next issue starts |

**afkkit never publishes half-broken work.**

## The safety property is the label, not who types the command

afkkit invokes [`issuekit`](./issuekit.md) `start` itself rather than acquiring the worktree directly. issuekit refuses anything not labeled `ready`, gets the worktree from [`gitkit`](./gitkit.md), and flips `ready → in-progress`.

That guard holds no matter who runs it: an issue only reaches `ready` after a human grill session, and **afkkit can neither promote an issue to `ready` nor start one that isn't.** It cannot get ahead of human judgment because the only door it has is locked against exactly that.

This is the one companion it will **not degrade around**. If issuekit isn't installed, afkkit refuses the run rather than reaching for `gh` to re-implement the guard — because a second copy of a gate is a gate that can drift open, and the copy inside an unattended orchestrator is exactly the one nobody would notice drifting.

## How the conductor works

The session you invoke runs as a **conductor**, dispatching each heavy step as a subagent working inside the issue's worktree. That keeps the conductor's context small and lets each step run on the model that fits it.

The conductor's boundary is sharp: it **dispatches** subagents, **redistributes** their payloads, **reads** the workspace to verify a claim, and **decides** the next move. It **never writes to the workspace** — no editing code, no running a build, no staging, no committing. *Read yes, write no.*

It also **redistributes payloads rather than re-deriving them.** A later step usually needs an earlier one's result, and the conductor is the only thing holding it. Pass by reference where one exists, by value only when genuinely small, and never re-type a fact a subagent already wrote down.

## The orientation file

Every step after the spec gate needs the same handful of repo facts — the test and build commands, where output lands, the file establishing the pattern being followed. The gate discovers all of it.

Without somewhere to put it, that discovery is thrown away and each later step re-derives it from cold — **the single most expensive habit in this pipeline**, because every tool use re-bills the agent's whole accumulated context.

So the gate writes `.afkkit-orientation.md` at the worktree root once, excluded from git via the repo's private exclude file so a reviewer never sees the agents' working notes. It carries **facts with sources, never conclusions**: not "the auth flow is fine" but "`src/auth/session.ts:40` sets the cookie `maxAge` from `SESSION_TTL`".

The trade is stated plainly: every downstream step inherits the gate's understanding, so a *wrong* orientation propagates silently. That's the price of not paying for the same discovery five times — and it's why the gate stays on the strongest tier, and why orientation carries facts rather than judgments. A wrong path is caught the moment a step opens it; a wrong conclusion is not.

## Model routing, and what a step actually costs

**Cost tracks context size × turns, not token volume and not how often a step fires.** A measured run bears this out sharply: the highest-frequency step (commit, three times) was under 2% of the bill, while the two steps that *explored the codebase* — each running exactly once — were over 40% between them.

**The way to make a step cheap is to hand it what it needs, not to ask it to think less.**

| Step | Model | Why |
|------|-------|-----|
| Spec gate | `opus` | gates the whole run; every later step inherits its orientation |
| Implement | `opus` | the bulk of the work, with implementkit's own gate underneath |
| Commit | `haiku` | mechanical; a weak message is cosmetic and rewritable |
| Review | `fable` | a **different model family** from the one that wrote the code |
| Fix | `opus` | applying findings against a concrete list |
| QA plan | `opus` | grounded generation against an already-green gate |
| PR | `opus` | title and body from real commits plus handed-in payloads |

**Review runs on a different family, not a "better" one.** An implementer and reviewer from the same family share blind spots by construction, so routing review to `fable` buys *independence*. It is explicitly **not the cheap option** — `fable` ran roughly 4× `opus`'s cost per token in the measured run. That's a deliberate purchase of a second opinion, priced so nobody mistakes it for a saving. The cheap tier is `haiku`.

**Implement and the spec gate are never budgeted.** Implement needed ~47 tool uses because the work needed 47, and the gate's exploration is what every later step depends on. Nudging either toward a smaller number buys cheaper, worse output — the one trade this pipeline should never make.

## The pipeline

1. **Start the issue** — issuekit `start`, dispatched on the conductor's own model rather than the cheap tier, because issuekit can refuse four distinguishable ways and a relay that flattens them breaks the escalation policy silently. The conductor then verifies what came back rather than taking it on faith.
2. **Spec gate** — classify gaps between what the issue specifies and what building it requires. **Missing decisions** escalate to `needs-planning` before any code is written, the cheapest possible failure point. **Missing mechanics only** proceed, returning an assumptions list that reaches the PR body.
3. **Implement** — implementkit, which resolves its own mode and enforces the repo's gate.
4. **Commit** — commitkit, banking the implementation before review.
5. **Review** — reviewkit against the branch diff, told it *is* the fresh reviewer so it doesn't delegate again and pay for a second full read.
6. **Fix loop** — bounded at two rounds, re-review **delta-scoped** to the fix commits. Zero blockers still earns one round if a nit is cheap and concrete, but **a nit never triggers a re-review**, so the loop always terminates.
7. **QA plan** — qakit, told the gate is already green and where the build output is. Without that it re-runs the whole verification chain; in the measured run it destroyed and rescaffolded a build from ten minutes earlier for no new information.
8. **Open the PR** — prkit, handed the assumptions list, unresolved nits, unmet criteria, and the QA-plan path.

## The escalation contract

The one policy afkkit owns. Whenever a step can't proceed, it escalates rather than pushing forward.

**First, it verifies a "pre-existing" claim before accepting it.** A step reporting a gate as red-but-already-broken is asking to be excused from the one check standing between an unattended run and a shipped regression — and it's the easiest thing for a subagent to get wrong, because a failure it caused and one it inherited look identical from inside the worktree. The conductor re-runs that command against the **base branch** first.

Then escalation always means the same five things:

1. **No PR.**
2. **Keep the work** — worktree and every commit intact.
3. **Comment the stuck-state** precisely.
4. **Set the label by *cause*** — a **planning gap** (a missing *decision*) flips to `needs-planning` and goes back to the grill queue; an **execution gap** (tests won't go green, blockers survive) **keeps `in-progress`**, because the issue isn't waiting on a decision.
5. **Continue the batch.**

**Escalation is a success, not a failure.** Stopping cleanly at a wall is afkkit doing its job. The failure mode it exists to prevent is pushing a half-broken change all the way to a PR.

## Batch mode: `all`

Takes its queue from `gh issue list --label ready` and walks it **sequentially**.

**One confirmation, up front** — the queue is printed and waits for a single OK. The human is by definition still at the keyboard the moment they type `afkkit all`, so this costs nothing and is the last chance to pull an issue promoted too early. After that OK the run is unattended, whatever happens.

**The queue is fixed at that OK**, not re-read before each issue. The run mutates labels as it goes, so re-reading would drain issues nobody approved.

**Issues start just in time**, each at the top of its own run — so a worktree branches off a freshly fetched base rather than one that went stale in a queue, and a batch that stops early leaves untouched issues in `ready` rather than orphaned at `in-progress`.

Each issue's payloads are **dropped once it terminates**, so a batch working its tenth issue isn't still paying for the first one's findings on every turn.

## Hands off to

By outcome. **Opened** → [`mergekit`](./mergekit.md) `start`, which pulls the PR into the worktree it was built in. **Escalated to `needs-planning`** → [`grillkit`](./grillkit.md) on the open questions, then re-run — re-running as-is would stop at the same wall. **Escalated still `in-progress`** → pick it up in the existing worktree by hand.

Nobody watched the run, so the report *is* the handover — and it always names the worktree path, because on an escalation those commits are real work sitting on disk and a human who doesn't know where they are will start over.

## Install

```sh
npx skills add mimukit/skills -s afkkit
```

Source: [`skills/afkkit/SKILL.md`](../../../skills/afkkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`fd96414` on 2026-08-07._
