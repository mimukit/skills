---
name: afkkit
description: >-
  Run a groomed `ready` GitHub issue through the whole build span unattended — worktree, implement, commit, review, fix, QA plan, and open PR — so one issue reaches a reviewable PR with no human at the keyboard. Use when the user says "afkkit", "run issue #N unattended", "work the ready issues while I'm away", "autopilot this issue", "take this issue to a PR without me", or wants the middle of the kit workflow driven end to end on its own.
license: MIT
allowed-tools: Bash, Read, Task, Agent, Skill
metadata:
  internal: false
---

# afkkit

The **away-from-keyboard** orchestrator. Hand it a groomed `ready` issue and it drives the middle of the dev workflow — the part that needs no human judgment once the issue is well-specified — from an isolated worktree to an open pull request: implement, commit, review, fix, write a manual QA plan, open the PR, and flip the issue to `in-review`. The human gates stay where judgment lives: planning and grilling happen *before* (the `ready` label is the entry contract), review and merge happen *after*.

afkkit adds **no** worktree, tracker, or PR behavior of its own. It **sequences** companion kits — issuekit `start` at the very front, then implementkit, commitkit, reviewkit, qakit, prkit — and owns exactly one thing they don't: the **escalation policy** that decides, at every step, whether to keep going or stop cleanly and leave the issue for a human. It is the autonomous sibling of statuskit: statuskit tells a human what to do next; afkkit does the next several things itself and stops at the boundary where a human is genuinely required.

## The contract

- **Input:** an issue number, or `all`. afkkit invokes **issuekit `start <n>`** itself to acquire the worktree — issuekit refuses anything not labeled `ready`, gets the worktree from gitkit (off a freshly resolved base ref, adopting an existing one rather than recreating it), and flips `ready → in-progress`. That guard is the safety property, and it holds no matter who types the command: an issue only reaches `ready` after a human grill session (see the lifecycle below), and afkkit can neither promote an issue to `ready` nor start one that isn't (see [Start the issue](#1-start-the-issue)).
- **Output on success:** an open PR whose body carries the implementation's documented assumptions, any unresolved review nits, and a pointer to a committed QA plan — and the issue moved to `in-review`.
- **Output on a blocked run:** **no PR.** The worktree and its commits stay intact, a comment on the issue names the precise stuck-state, the issue is labeled for whoever must pick it up, and — in a batch — the next issue starts. afkkit never publishes half-broken work.

Everything between input and output is mechanical sequencing plus the escalation policy.

## When this fires

The user wants an issue taken through the build span without sitting through it:

- **one issue** — "afkkit 42", "run #42 unattended", "autopilot issue 42", "take #42 to a PR".
- **the whole ready queue** — "afkkit all", "work the ready issues while I'm away", "drain the ready backlog".

If they name neither an issue number nor `all`, ask which. afkkit never plans, grills, merges, or responds to PR review feedback — those are human or out-of-scope (see [Non-goals](#non-goals)).

## Preflight (once per invocation)

Before touching anything, confirm the tooling and the conductor:

```sh
gh --version && gh auth status                          # GitHub CLI installed + authenticated
gh repo view --json nameWithOwner -q .nameWithOwner     # inside a repo on GitHub
```

- If `gh` is missing or unauthenticated, stop and point to `https://cli.github.com` / `gh auth login` — don't work around it.
- **Companion-kit check.** afkkit is glue: it needs implementkit, commitkit, reviewkit, qakit, and prkit to do the actual work. Check which are installed. If a kit a step needs is absent, **stop and name it** rather than improvising its job badly — an orchestrator missing its steps degrades by refusing clearly, not by half-doing the work. (Each step below also names the plain `gh` fallback where the action is trivial enough to run directly.)
- **issuekit is required, and has no fallback.** It owns the `ready` guard afkkit's whole safety property rests on (see [Start the issue](#1-start-the-issue)). If it isn't installed, **refuse the run and say to install it** — do not reach for `gh` and re-implement the guard. This is the one companion afkkit will not degrade around, because a second copy of a gate is a gate that can drift open, and the copy inside an unattended orchestrator is exactly the one nobody would notice drifting.
- **No shell / CLI available** (e.g. a browser-based agent)? You can't run `gh`, git, or spawn subagents. Say so and stop — afkkit is an execution orchestrator; there's nothing to reason out in prose. Point the user at running the individual kits interactively instead.

## How the conductor runs each step

afkkit runs as a **conductor session**: the session you invoke it in sequences the pipeline, and each heavy step runs as a **subagent** dispatched to work inside the issue's worktree. This keeps the conductor's context small (the bulk of the tokens live in the subagents) and lets each step run on the model that fits it.

- **Dispatch a subagent per step** with the Task tool (agent type `general-purpose`), passing it three things: the **worktree path** that [Start the issue](#1-start-the-issue) returned for *this* issue, the **companion skill to invoke** for that step, and the **model** from the table below. The subagent's first action is to work inside that worktree path (operate on its absolute paths, or `cd` into it).
- **The worktree path is carried run state, not the conductor's location.** The conductor's own working directory is irrelevant and never changes — it holds each issue's path and dispatches into it. That's what lets one conductor session walk a batch of issues, each in its own worktree, without ever being inside any of them.
- **Each subagent returns a small structured result** the conductor acts on: pass/fail, and the step's payload (the gate's assumptions list, the review's blocker/nit findings, the QA doc path). The conductor holds the thread; the subagents hold the work.
- **The conductor never edits code or runs the build itself** — it dispatches, reads the result, and decides the next move (continue, loop, or escalate). That decision — the escalation policy — is the one thing afkkit owns. The single exception is [Start the issue](#1-start-the-issue), which the conductor runs inline: acquiring the workspace is not work *in* the workspace, and the conductor needs the returned path in its own hands to dispatch everything else into.
- **No subagent capability?** Degrade to running the steps inline in sequence in the conductor session. You lose per-step model routing (everything runs on the conductor's model) but the pipeline and escalation policy are unchanged. Say you're running inline.

## Model routing

Default per-step models. Two things drive each assignment: **what a mistake costs** — a missed decision at the spec gate poisons every step after it, while a clumsy commit message is cosmetic — and **how often the step runs**, since commit fires up to four times per issue and the PR exactly once. Savings come from the frequent, low-stakes steps; capability is bought where a single wrong call sinks the run.

| Step | Model | Runs | Why |
|------|-------|------|-----|
| Spec gate | `opus` | 1× | Gates the whole run — a missed decision-gap poisons every step after it. Runs once, so buying capability here is nearly free. |
| Implement | `opus` | 1× | The bulk of the work; implementkit's own test + build gate is the safety net underneath it. |
| Commit | `haiku` | ≤4× | Mechanical — group the diff, write the message. Highest frequency, lowest stakes: a weak message is cosmetic and rewritable. |
| Review — round 1 | `fable` | 1× | The quality gate, on the strongest model, over the full branch diff. |
| Review — rounds 2–3 | `fable` | ≤2× | Same model, delta-scoped to the fix commits (see [Fix loop](#6-fix-loop)). |
| Fix | `opus` | ≤2× | Applying review findings against a concrete list. |
| QA plan | `opus` | 1× | Grounded generation from the diff. |
| PR | `opus` | 1× | Title and body from the real commits, plus the three payloads handed in. |

Write the **alias** (`opus`, `fable`, `haiku`), never a pinned model ID — an alias follows its tier as the tier moves, a pinned ID rots.

**Effort is not a dispatch parameter.** Reasoning effort can only be set in an agent definition's frontmatter, not passed when the conductor spawns a subagent, and it defaults to `high`. So the cheap steps state their deliberation budget **in the subagent's prompt** instead — "this is a mechanical step: read the diff, produce the output, don't go exploring the codebase." That is an instruction the subagent follows, not a setting the harness enforces. Treat it as a nudge; when you need a real cost floor, drop a tier rather than asking harder.

**Inline override.** The user can override any step's model at invocation in plain language — "afkkit 42, implement on opus", "afkkit all, review on fable". Honor the override for the named step(s); everything else keeps the table. There is no config file — the table plus the spoken override is the whole routing surface.

## The pipeline (per issue)

Run these in order for each issue. Any step that can't proceed hands to [the escalation contract](#the-escalation-contract) and the issue stops there — cleanly, with no PR.

### 1. Start the issue

Invoke **issuekit** `start <n>` to acquire the worktree. afkkit adds nothing to it and re-implements none of it: issuekit refuses any issue not labeled `ready`, asks **gitkit** for the worktree (branch `issue-<n>-<slug>`, cut from the resolved base ref, adopting an existing one rather than recreating it), and flips the label `ready → in-progress`.

This runs **inline in the conductor**, not as a dispatched subagent — it's a handful of `gh` and git calls, and the conductor needs the returned path in its own hands to dispatch every step below into.

**Say the run is unattended when you invoke it.** issuekit previews every mutation and waits for an OK, and it carves out exactly one exemption for an unattended caller: `start`'s `ready → in-progress` flip. That exemption is safe precisely because the guard has already refused everything unworkable — the flip only ever happens to an issue a human grilled into `ready`. Nothing else afkkit touches is exempt, and afkkit never asks for a broader one.

Then verify what came back rather than taking it on faith:

```sh
git -C <worktree> rev-parse --show-toplevel              # the returned path is a real worktree
git -C <worktree> branch --show-current                  # the issue's branch is checked out there
gh issue view <n> --json labels -q '.labels[].name'      # now reads in-progress
```

Hold that path as this issue's run state; every subagent below is dispatched into it.

**If issuekit refuses, that's a preflight stop, not [an escalation](#the-escalation-contract)** — nothing has happened yet, so there's no comment and no label churn. Report the reason issuekit gave and, in a batch, move to the next issue:

- **`needs-planning`** → the decisions aren't settled; it needs a human grill session first.
- **`blocked`** → name the `Blocked by #N` prerequisite and its state.
- **closed, or carrying no lifecycle label** → say which; issuekit `triage` is what classifies it.

An issue already `in-progress` is **not** a refusal. issuekit takes its adopt path — gitkit hands back the existing worktree, the label is left alone — and afkkit continues. That covers both the re-run path (an issue escalated to `needs-planning`, grilled back to `ready`, and re-run) and a worktree a human staged by hand, on the same code path as a first run rather than as a special case.

### 2. Spec gate

Dispatch a subagent (worktree) to read the issue body and the relevant code, and classify any gaps between what the issue specifies and what building it requires. The classification is the whole point:

- **Missing decisions** — product choices or trade-offs a human would have to make (which behavior is correct, which of two designs, an unstated requirement). These are exactly what a grill session settles. → **Escalate as a planning gap:** stop before writing any code, this is the cheapest possible failure point. Comment the exact open questions on the issue (phrased as the grill-questions a human should answer), and flip the label `in-progress → needs-planning` so the issue lands in the human's planning queue. Move to the next issue.
- **Missing mechanics only** — file names, minor edge cases, naming, small ambiguities a competent implementer fills uncontroversially. → **Proceed.** The subagent returns an **assumptions list** — every mechanical choice it's making — which the conductor carries forward to the PR body so the reviewer sees exactly what was assumed.

A `ready` issue *should* clear this gate — grilling is what earns `ready`. The gate is the backstop for a decision that slipped through, and routing it to `needs-planning` rather than guessing is the design's core stance: never build on an un-made decision.

### 3. Implement

Dispatch a subagent (worktree) to invoke **implementkit** against the issue spec. implementkit resolves its own straight-through-vs-TDD mode and enforces the repo's own test + build gate before it reports done — afkkit doesn't second-guess that. Two failure shapes route differently:

- implementkit **bounces the spec as too thin** — it hit a genuine *decision* gap the [spec gate](#2-spec-gate) missed. Treat it as a planning gap: escalate to `needs-planning` with the specific gap commented.
- implementkit **can't get the gate green** after its own bounded fixes — an *execution* failure, not a spec problem. Escalate keeping `in-progress`, with the failing gate output commented.

Otherwise, implementkit leaves green, unstaged changes in the worktree and afkkit continues.

### 4. Commit

Dispatch a subagent (worktree) to invoke **commitkit**, which groups the unstaged changes and writes Conventional-Commits messages from the diff. This banks the initial implementation before review. If commitkit isn't installed, the fallback is a single `git add -A && git commit` with a conventional subject derived from the issue title.

### 5. Review

Dispatch a subagent (worktree) to invoke **reviewkit** against the branch diff. reviewkit returns severity-ranked findings across its passes. The conductor splits them into **blockers** (correctness, completeness, security — must fix) and **nits** (polish, style — fix once, don't gate on). This split drives the fix loop.

### 6. Fix loop

Bounded at **two fix rounds**. Per round:

1. Dispatch a subagent (worktree) to invoke **implementkit** in fix mode against the concrete blocker list from [Review](#5-review).
2. Commit the fixes (**commitkit**).
3. Re-review (**reviewkit**) — **delta-scoped**: point it at the fix commits and the surviving blocker list, not the whole branch diff again. Round 1 already covered the untouched code, and re-reading all of it on the strongest model is the most expensive thing this pipeline can do. Only re-review while **blockers** remain; nits are fixed once in the first round and never trigger another round.

Stop the loop when no blockers survive. If blockers still survive after the second round, or a fix round can't get the gate green, **escalate keeping `in-progress`** — comment the surviving blockers (or the red gate) and move on. No PR opens with known blockers in it. Nits that were never worth a round are carried to the PR body as "known follow-ups".

### 7. QA plan

Dispatch a subagent (worktree) to invoke **qakit**, which writes a manual QA plan grounded in the diff to `docs/qa/qa-<slug>-YYYY-MM-DD.md` and runs any agent-verifiable checks itself. Then commit that doc (**commitkit**) so it travels with the branch. The PR body will point at it.

### 8. Open the PR

Dispatch a subagent (worktree) to invoke **prkit**, handing it three things to fold into the PR body: the **assumptions list** from the [spec gate](#2-spec-gate), the **unresolved nits** carried from the fix loop, and the **QA-plan path**. prkit writes the title and body from the real commits and diff, pushes the branch, opens the PR, and — its existing behavior — advances the linked issue `in-progress → in-review`. afkkit relies on prkit for that label flip rather than duplicating it; only if prkit is absent does the conductor fall back to `gh issue edit <n> --remove-label in-progress --add-label in-review` after opening the PR by hand.

This is the successful terminus: an open PR, a QA plan, and an `in-review` issue.

### 9. Hand off

Nobody watched this run, so the report *is* the handover — a human is reading it cold, after the fact, to work out what they now have to do.

**What changed** — one outcome line for the issue: **opened** (PR link), **escalated** (which label, one-line reason, issue link), or **skipped** (issuekit refused it at [Start the issue](#1-start-the-issue) — the reason, and the fact that nothing was mutated). In a batch, accumulate these; the batch summary is emitted at the end (see [Batch mode](#batch-mode-all)).

**Where it landed** — the worktree path and branch, which survive both an open PR and an escalation. On an escalation this is load-bearing: the commits are real work sitting on disk, and a human who doesn't know where they are will start over. A skipped issue has no worktree — say that plainly rather than printing a path that doesn't exist.

**Next** — route by outcome, naming a sibling kit only when it's installed and otherwise describing the action plainly:

- **opened** → the PR needs a human reviewer, which is exactly where afkkit's span ends. **mergekit `start <n>`** pulls it down into the worktree it was built in, syncs it, and prints the review pack; the QA plan committed in [QA plan](#7-qa-plan) is what they run by hand.
- **escalated to `needs-planning`** → a decision is missing, so the move is a grill session — **grillkit** on the issue's open questions — then re-run afkkit once it's back to `ready`. Don't suggest re-running afkkit as-is; it will stop at the same wall.
- **escalated, still `in-progress`** → execution is stuck, not the spec. Point at the commented gate output or surviving blockers and name the plain action: pick it up in the existing worktree by hand.

Crown **one** next move even after a batch — the oldest open PR usually, since review is the bottleneck a returning human clears first. Route, don't launch: afkkit never invokes mergekit or grillkit itself, because both want a human in front of them.

## The escalation contract

The one policy afkkit owns. Whenever a step can't proceed, **escalate** rather than push forward — and escalation always means the same five things:

1. **No PR.** Never open a pull request from a run that hit a wall.
2. **Keep the work.** Leave the worktree and every commit intact — the next human (or the re-run) picks up from real progress, not a clean slate.
3. **Comment the stuck-state** on the issue, precisely: the open questions for a planning gap, the failing gate output for an execution gap, the surviving blockers for a review gap.
4. **Set the label by *cause*** — this is the load-bearing distinction:
   - **Planning gap** (the [spec gate](#2-spec-gate) or implementkit found a missing *decision*) → flip `in-progress → needs-planning`. The spec itself is incomplete, so it goes back to the human's grill queue. A re-run after grilling adopts the existing worktree.
   - **Execution gap** (tests won't go green, or review blockers survive the fix loop) → **keep `in-progress`**. The spec was fine; execution is stuck. The comment and batch summary carry the detail for a human to unstick — no label churn, because the issue isn't waiting on a *decision*.
5. **Continue the batch.** One escalated issue never sinks the run — the next `ready` issue starts.

## Batch mode: `all`

`afkkit all` takes its queue straight from the tracker — `gh issue list --label ready` — and walks it **sequentially**, running the full pipeline from [Start the issue](#1-start-the-issue) onward on each.

**One confirmation, up front.** Print the queue it's about to drain — number and title per issue — and wait for a single OK before starting anything. The human is by definition still at the keyboard the moment they type `afkkit all`, so this costs nothing, and it's the last chance to pull an issue that was promoted to `ready` too early. After that OK the run is unattended: no further prompts, whatever happens. A single-issue invocation (`afkkit 42`) needs no confirmation — naming the number *is* the intent.

**The queue is fixed at the moment of that OK** — the snapshot the human saw, not a live `gh issue list` re-read before each issue. The run mutates labels as it goes (`ready → in-progress`, and `→ needs-planning` on a planning escalation), so re-reading would drain issues nobody approved and could re-pick one the run itself just moved. Approve the list, work the list.

**Issues start just in time**, each at the top of its own pipeline run, never all up front. Two reasons, both about what a half-finished batch leaves behind: a worktree branches off a base ref fetched at the moment it's created rather than one that went stale waiting its turn in a queue, and a batch that stops early leaves the issues it never reached untouched in `ready` instead of flipped to `in-progress` with orphaned worktrees behind them.

**`all` drains `ready` only.** An issue already `in-progress` may have a human sitting in its worktree, so the batch passes over it; name it explicitly (`afkkit 42`) to include it, and issuekit's adopt path picks up the existing worktree. List any such issues in the up-front preview so it's clear what was left out and why.

Sequential, not parallel: v1 keeps merge-conflict and resource behavior predictable, and a returning human faces one PR at a time rather than a pile of concurrent branches off the base. Process oldest-first (or by the order the user names). Each issue is independent — an escalation is logged and the walk continues to the next.

At the end, print the **batch summary**: how many PRs opened (with links), how many escalated and to which state (`needs-planning` vs still `in-progress`, with links and one-line reasons), how many were skipped before starting and why, then the single crowned next move from [Hand off](#9-hand-off). That summary plus GitHub's own PR notifications is the whole signal surface — afkkit writes no run-report artifact and sends no push notifications. Success is the PR itself; a blocked issue is a comment and a label the human sees on return.

## Non-goals

afkkit is deliberately narrow — the middle of the workflow, nothing else:

- **No planning or grilling.** It never invents product decisions; a thin spec goes back to the human queue as `needs-planning`. plankit and grillkit stay interactive and out of the unattended path.
- **No PR-feedback loop, no merge, no teardown.** The span ends at PR open. Responding to a human's review comments is a designed-for *later phase*, not v1. Merging is a human gate. The land-side reconciliation — issuekit `close` (close the issue, unblock dependents, remove the worktree via gitkit) — runs *after* merge, also out of span.
- **No parallel batches, no browser verification, no notifications** in v1 — issues run sequentially, verification is qakit's manual plan (not verifykit's browser capture), and GitHub plus the session summary are the only signal.
- **No new worktree, tracker, or PR logic.** gitkit owns the worktree lifecycle and the base ref; issuekit owns the tracker vocabulary and the `ready` guard, which afkkit *invokes* but never re-implements, overrides, or works around (see [Start the issue](#1-start-the-issue)); prkit owns the PR. afkkit only sequences them and owns the escalation policy. Invoking a gate is not owning one — the moment afkkit would have to decide *whether* an issue is workable, it has left its span.
- **No config file.** Model routing is the table above plus a spoken inline override.

## Notes

- **The `ready` label is the safety property — not who types the command.** Human judgment enters at the grill session that *earns* an issue its `ready` label; typing `issuekit start 42` adds none of its own. So afkkit invoking `start` itself preserves the gate verbatim rather than weakening it: issuekit still refuses everything not `ready`, and afkkit can neither promote an issue to `ready` nor start one that isn't. It cannot get ahead of human judgment because the only door it has is the one locked against exactly that.
- **Escalation is a success, not a failure.** Stopping cleanly at a wall — no PR, work preserved, issue labeled by cause — is afkkit doing its job. The failure mode it exists to prevent is pushing a half-broken or wrongly-assumed change all the way to a PR.
- **Idempotent per issue.** Re-running afkkit on an issue whose worktree already exists picks up from it and continues: issuekit `start` adopts that worktree through gitkit rather than recreating it, and leaves the `in-progress` label alone. That's the intended path for an issue escalated to `needs-planning`, grilled back to `ready`, and re-run — and it runs the same code as a first run.
- **Follow the repo over these defaults.** If a repo has its own review depth, QA location, or PR template, the companion kits already honor those; afkkit doesn't override them.
