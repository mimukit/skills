# Plan — afkkit cost & correctness optimization

_Created 2026-08-06._
_Grilled: 2026-08-06_

## Context

afkkit shipped and ran a real issue end to end for the first time. The run produced two independent measurements: a `/usage` session report (billed tokens by model) and a first-hand **run ledger** written by the conductor session itself (per-step tokens, tool uses, wall clock). Together they let us stop guessing about where afkkit's cost lives and start allocating it.

The headline: **one issue, from `ready` to open PR, cost $11.79 and 34 minutes of wall clock.** That is not obviously wrong for a feature that landed 1,380 lines — but roughly a quarter of it went to work that had already been done, and the run surfaced a genuine contradiction in the skill's own control flow that the conductor had to improvise around.

This plan ranks every improvement by measured contribution, separates spec bugs from cost bugs, and records what was disproved as well as what was found.

## Evidence

### Session totals (`/usage`)

| Model | Input | Output | Cache read | Cache write | Cost |
|---|---|---|---|---|---|
| opus | 274 | 119.3k | 7.7M | 400.7k | $9.66 |
| fable | 18 | 15.4k | 325.0k | 65.3k | $1.91 |
| haiku | 854 | 9.1k | 792.0k | 79.1k | $0.22 |
| **Total** | | | **8.8M** | **545k** | **$11.79** |

### Run ledger (conductor's own report)

Nine subagents, all dispatched synchronously, so wall clock is the sum. The conductor never edited code or ran a build.

| # | Step | Model | Tokens | Tool uses | Wall |
|---|---|---|---|---|---|
| 1 | Spec gate | opus | 69,421 | 29 | 3m27s |
| 2 | Implement | opus | 115,459 | 47 | 11m17s |
| 3 | Commit (impl) | haiku | 29,762 | 20 | 1m21s |
| 4 | Review r1 | fable | 68,183 | 16 | 3m35s |
| 5 | Fix (nits) | opus | 47,318 | 26 | 2m37s |
| 6 | Commit (fixes) | haiku | 21,305 | 8 | 38s |
| 7 | QA plan | opus | 85,002 | 35 | 8m27s |
| 8 | Commit (QA doc) | haiku | 28,672 | 9 | 33s |
| 9 | PR | opus | 32,759 | 13 | 2m0s |
| | **Total** | | **497,881** | **203** | **~33.9m** |

**This ledger is the frozen baseline.** No further measurement run is planned (see [Validation](#validation)), so these are the only numbers this plan will ever have. Preserve the table verbatim; it is what a future run would be compared against if anyone changes their mind.

### The two reports reconcile exactly

**Ledger tokens ≈ cache write, per tier.** haiku: ledger 79,739 vs 79.1k written. fable: 68,183 vs 65.3k. opus: 349,959 vs 400.7k. The ledger measures *distinct context built*; cache write measures the same thing from the billing side. The opus gap of ~50.7k is the **conductor's own context**, which the ledger explicitly excludes.

That gives us the cost model afkkit was missing:

> **Billed cost ≈ Σ over agents of (context size × turns).** Cache write is the context an agent builds; cache read is that context re-billed on every subsequent turn. The run's read:write ratio is **19:1** — every token an agent loads is paid for ~19 more times before that agent exits.

**Tool-use count is the cost multiplier, not token volume.** A step with 47 tool uses over a growing context costs far more than its token count suggests. Approximating each agent's cache read as `tokens × turns / 2` predicts **6.04M** opus cache read against an actual **7.7M** — close enough to allocate by, with the remainder being the conductor and the approximation's own slack.

### Where the money actually went

Allocating opus subagent cost by that proxy. These shares are **derived from measurement**, not projected — the proxy was validated against the actual cache-read figure above.

| Step | Weight | Share of opus subagent cost | ≈ $ |
|---|---|---|---|
| Implement | 2.71M | **45.0%** | ~$4.15 |
| QA plan | 1.49M | **24.6%** | ~$2.26 |
| Spec gate | 1.01M | **16.7%** | ~$1.54 |
| Fix | 0.62M | 10.2% | ~$0.94 |
| PR | 0.21M | 3.5% | ~$0.32 |

Plus **review r1 at $1.91** (the entire fable line — one agent, 68k of context, 16 turns) and **all three commits at $0.22 combined**.

Two facts jump out. **Implement is 45% and is irreducible** — it is the actual work. **QA plan is 24.6%**, second-costliest and 8m27s of wall clock, and the conductor reports most of it went to running `play:destroy && deps:verify` — a full destroy-and-rescaffold that Implement had already performed ten minutes earlier.

### Per-token price by tier

| Tier | Tokens | Cost | Blended $/Mtok |
|---|---|---|---|
| opus | ~8.22M | $9.66 | $1.18 |
| fable | ~0.41M | $1.91 | **$4.71** |
| haiku | ~0.88M | $0.22 | $0.25 |

**fable costs ~4× opus and ~19× haiku per token.** This is load-bearing in two directions. It kills any proposal to move a step *down* to fable as a saving — that would be a ~4× increase. And it means review's 16.2% share of the bill against 4.6% of tokens is a deliberate purchase that the routing table should price out loud.

### What was disproved

- **The nested-reviewkit hop did not fire.** `reviewkit`'s "delegate the passes to a fresh subagent" instruction, combined with afkkit already dispatching into a subagent, looked like a guaranteed double-hop that would re-read the whole diff. The ledger shows nine subagents total and Review r1 doing its own work in 16 tool uses. It remains a **latent** hazard worth closing, not an observed cost.
- **Commit-on-haiku is not where savings live, in dollars.** All three commits together are $0.22, 1.9% of the bill. The waste in commit #8 is real but it is a wall-clock and hygiene problem, not a budget one.
- **Conductor-resident `issuekit` + `gitkit` is real but second-order.** The conductor's ~50.7k context is ~41% skill markdown (afkkit 6.5k + issuekit 10.1k + gitkit 4.1k), loaded because `start` runs inline. Over ~15 conductor turns that is ~0.38M cache read, **~5% of opus cost** for a single issue. It grows with batch length, which is the reason to fix it, not the single-issue saving.

## Where the run deviated from the skill

The conductor had to improvise three times. Each is a spec gap, and each is worth fixing independently of cost.

1. **The zero-blocker nit case has no home in the control flow.** afkkit's Fix loop says *"nits are fixed once in the first round"* and *"Only re-review while blockers remain"* — but the loop is only entered when blockers exist. Review r1 returned zero blockers and three real nits, so by the literal text the loop never runs and the nits fall through to *"carried to the PR body as known follow-ups."* The conductor judged the nits cheap and concrete, ran a dedicated fix+commit round anyway (68,623 tokens, ~3m15s), and flagged that the skill should have made that call.
2. **The conductor acted as a manual context bus.** The spec gate produced an ORIENTATION block that later steps genuinely needed. The conductor hand-copied it — plus the same repo facts (the `deps:verify` chain, the base-template path, `copyTemplate`'s `{{WORD}}` substitution, what a prior issue landed) — into **five separate dispatch prompts**. The skill says subagents return "a small structured result the conductor acts on" and says nothing about the conductor *redistributing* it.
3. **A subagent's failure claim was verified by hand, unsanctioned.** Implement reported `deps:check` red-but-pre-existing. The conductor re-ran it in a clean checkout before accepting. That was the right call on a load-bearing acceptance criterion, and the skill neither describes nor permits it. The run hit this pattern twice.

One non-afkkit note: the conductor created three tracking tasks and `TaskList` returned empty at the end — they vanished mid-pipeline. Harness behavior, but afkkit says nothing about whether a conductor should use task tracking at all.

## Settled decisions

Settled with the user in a grillkit pass on 2026-08-06.

| Decision | Resolution |
|----------|-----------|
| **Run ledger** | **Stays on-request.** afkkit's existing non-goal — *"writes no run-report artifact and sends no push notifications"* — survives intact. The ledger that produced this plan came from asking for it after the fact, and that remains the mechanism. Rejected auto-printing it in the hand-off: the non-goal is about signal surface, and the discipline of asking is cheap. |
| **ORIENTATION home** | **`.afkkit-orientation.md` at the worktree root, registered in `.git/info/exclude`.** Per-clone, never committed, repo `.gitignore` untouched, invisible in the PR diff. Portable to any harness with a filesystem — which matters because afkkit is `internal: false`. Degrades to the conductor holding and pasting when there is no writable filesystem. Rejected the harness scratchpad (path is harness-specific) and a committed `docs/` artifact (agent scratch notes in a reviewer's diff). |
| **QA rebuild ownership** | **Both, weighted to qakit.** qakit already says *"if a verification step would modify state or need elevated access, describe it for the human instead of running it"* — `play:destroy` modifies state, so the rule existed and was not followed. The qakit half is about making an existing rule unmissable, not adding one; the afkkit half is one line of orientation. |
| **Validation budget** | **No re-run. Ship on reasoning.** Each measurement run is $11.79 and 34 minutes. This has a consequence the rest of the plan obeys: **every change must be defensible without evidence**, which is why the tier moves were dropped. |
| **QA doc commit** | **The PR step commits it.** prkit already pushes the branch, runs immediately after QA, and already receives the QA-plan path as one of its three payloads. Costs nothing, adds no exception to the conductor's charter, expands no kit's scope, and deletes an entire subagent. Rejected qakit committing its own doc (changes qakit for every caller, including interactive users who never asked for a commit) and the conductor committing directly (a second write-shaped exception). |
| **`issuekit start`** | **Dispatched, on the conductor's own model.** Evicts 14.2k of issuekit + gitkit from the conductor's resident context while keeping issuekit's four-way refusal taxonomy interpreted at full quality — each branch routes to a different escalation path, so a garbled relay breaks the safety property's legibility. Rejected haiku (weakest link in the one place the guard becomes legible) and a batch-mode-only dispatch (two code paths, against afkkit's own single-path idempotency argument). |
| **Model tier changes** | **None.** With no measurement to validate them, a tier move is an unhedged bet. The principle: **when you can't measure, prefer changes whose downside is zero.** Scoping (orientation + no rebuild) has no quality risk; tier-dropping does. PR at $0.32 is not worth risking the one artifact a human reads for a $0.25 saving. |
| **Review on fable** | **Kept — for diversity, not strength.** The rationale in the routing table changes from *"the quality gate, on the strongest model"* (unverifiable, and it rots as tiers move) to the observed behavior: fable's review **independently re-derived claims against the files** rather than trusting the conductor's prompt. Reviewing opus-written code with an opus reviewer shares blind spots; paying ~4× for a *different* model's eyes on the gate is the purchase being made. |
| **Tool-use budget** | **Documented in the table, nudged in the prompt only where exploration is avoidable.** Observed counts from the baseline ledger go in the routing table. A prompt nudge goes to QA, PR, and commit — the steps where P1-1 and P1-2 removed the reason to explore. **Never to Implement or the spec gate:** Implement needed 47 tool uses because the work needed 47, and nudging it toward a number buys cheaper, worse code. |
| **Forecast honesty** | **Measured and projected are labelled separately.** The cost allocation is derived from measurement and stays. The savings estimates carry an explicit unvalidated stamp, because no run will check them. |
| **Conductor boundary** | **A duty list with a read/write line, replacing the exception count.** The conductor dispatches, redistributes payloads, and *reads* the workspace to verify claims; it never *writes* to it. With the QA-doc commit going to prkit and `issuekit start` becoming a dispatch, the last write-shaped work leaves the conductor and the rule needs no caveats. |
| **Delivery** | **One PR, done by hand.** No measurement gate between phases means nothing justifies splitting interdependent changes. See the warning in [Hand off](#hand-off) about running afkkit on this. |

## Changes

Ranked. **P0** are spec defects — fix regardless of cost. **P1** are the measured cost wins. **P2** are hygiene and hardening.

### P0-1 — Resolve the zero-blocker nit case explicitly

The contradiction in the Fix loop is a real bug that forced the conductor to invent policy mid-run. Settle it in the direction the conductor chose, since that choice was sound: a cheap, concrete nit is worth one round; the loop still ends.

Add: *"A review with zero blockers still gets one fix round if any nit is cheap and concrete; nits that aren't worth a round go to the PR body. Either way the loop ends — a nit never triggers a re-review."*

### P0-2 — Name the pre-existing-failure verification pattern

Add to the escalation contract: **when a step reports a gate failure as pre-existing, the conductor verifies it against the base branch before accepting it.** And its corollary — **if an acceptance criterion turns out to be unmeetable from repo state, that goes in the PR body as an explicit unmet criterion, not a silent omission.**

Accepting a subagent's "it was already broken" on faith is exactly how an unattended run ships a regression. This is a *read* of the workspace, which P0-4 makes explicitly permitted rather than an exception.

### P0-3 — Define the conductor's redistribution duty

The skill describes the conductor as holding results and deciding the next move. The run shows it must also **feed results forward**. Say so, and bound it: the conductor redistributes *payloads*, never re-derives them. With P1-1 in place, redistribution mostly means pointing at a path.

### P0-4 — Rewrite the conductor's boundary as a duty list

Replace *"the conductor never edits code or runs the build itself"* plus its enumerated exception with a positive list: **the conductor dispatches, redistributes payloads, and reads the workspace to verify claims — it never writes to the workspace.**

*Read yes, write no* holds without a list. Counting exceptions invites more of them, and this plan removes the two candidates that would have been added (P1-3 sends the QA-doc commit to prkit; P2-2 makes `issuekit start` a dispatch).

### P1-1 — Make the spec gate's orientation a written run artifact

**The single highest-leverage change.** The spec gate writes `.afkkit-orientation.md` to the worktree root and registers it in `.git/info/exclude`; every later step's dispatch prompt begins "read this file first."

This collapses three problems at once:

- Kills the hand-copying in P0-3 — the conductor points at a path instead of re-typing ~2k tokens of repo facts five times, and drift between copies becomes impossible.
- Makes the spec gate's **29 tool uses of exploration reusable** instead of thrown away. Right now Implement re-derives from cold what the gate just learned. The gate is 16.7% of opus cost and its output currently evaporates.
- Shrinks the discovery phase of every downstream step, attacking the `tokens × turns` term directly rather than shaving token counts.

**Degradation:** with no writable filesystem, fall back to the conductor holding the block and pasting it, and say so. **Risk to state in the skill:** every downstream step now inherits the gate's understanding without re-deriving it, so a wrong orientation propagates silently. The gate stays on opus partly for this reason, and orientation records *facts with their source* (a path, a command, a symbol), never conclusions.

This supersedes the weaker option of folding the spec gate into Implement. The gate's early-stop value is real; the waste was never running it, it was discarding what it found.

### P1-2 — Stop the QA step re-running a gate that is already green

**The biggest single reclaimable number: ~24.6% of opus cost and 8m27s of wall clock**, most of it spent re-running a destroy-and-rescaffold Implement had just done.

**In qakit** — sharpen the existing destructive-verification rule into something unmissable, and name the pattern directly: *never re-run a gate a prior step just ran green; a verification step that destroys or rebuilds state is described for the human, not executed.* The rule already exists; it needs to be impossible to skim past.

**In afkkit** — the orientation file states the gate is green and where the build output lives. Free, once P1-1 exists.

QA legitimately needs built artifacts to inspect. It does not need to rebuild them. Reserve a rescaffold for when QA is actually testing the scaffold path itself.

### P1-3 — The PR step commits the QA doc

Commit #8 burned 28,672 tokens, 9 tool uses, and 33s to commit a single markdown file the previous step had just written. prkit already pushes the branch, runs immediately after QA, and already receives the QA-plan path as a payload — so it commits that path before pushing.

Small in dollars ($0.07); the point is that a cold-started agent rediscovering a file it was told about is the exact pattern this plan exists to remove. The `≤4×` commit budget in the routing table was designed around the fix loop, not around trivia.

### P1-4 — No model tier changes

**Resolved to no change.** Recorded here so the reasoning survives rather than being re-litigated: PR (3.5%, $0.32) and QA (24.6%) both looked like tier-down candidates, but with no validation run planned a tier move is an unhedged bet on quality, while P1-1 and P1-2 make both steps cheaper at zero quality risk. Revisit only if a measurement run is ever funded.

Note for anyone revisiting: **moving a step to fable is a cost increase, not a saving** — fable is ~4× opus per token.

### P1-5 — Reprice and re-explain the routing table

Three edits, no routing changes:

- **Correct the premise.** The table says "savings come from the frequent, low-stakes steps." The run refutes it — the frequent low-stakes step (commit, ×3) is 1.9% of the bill. Cost tracks `context size × turns`, so the expensive steps are the **1× steps that explore a codebase**. State the model: every tool use re-bills the agent's accumulated context, so the way to make a step cheap is to hand it what it needs, not to ask it to think less.
- **Add observed tool-use counts** from the baseline ledger as a column, and a prompt nudge for QA, PR, and commit only. Never for Implement or the spec gate.
- **Fix the review rationale.** Replace "the quality gate, on the strongest model" with the diversity argument and the observed evidence (fable re-derived claims against the files rather than trusting the prompt), and record the ~4× per-token premium next to the row so the purchase is visible.

### P2-1 — Close the latent reviewkit double-hop

Have afkkit's review dispatch state that the subagent **is** the fresh-eyes reviewer and must run the passes inline rather than delegating again. It did not fire this run; it costs one line to make sure it never does.

### P2-2 — Dispatch `issuekit start` instead of running it inline

A subagent on the conductor's own model, returning `{worktree, branch, label}` or a structured refusal. The current justification — "the conductor needs the returned path in its own hands" — does not require inline execution, and the `ready` guard lives inside issuekit wherever it runs.

The relay must preserve issuekit's refusal taxonomy exactly (`needs-planning` / `blocked` / closed-or-unlabeled / already-`in-progress`), because each routes to a different escalation path and the last one is not a refusal at all. Worth ~5% on a single issue; the case is batch mode, where 20.7k of skill markdown stays resident while turn count scales with issue count.

### P2-3 — Compress conductor state between issues

`/usage` flagged 12% of session usage above 150k context. Instruct the conductor to drop each issue's payloads once its PR opens, keeping only the one-line outcome for the batch summary. With P1-1, most payloads are already a path rather than a body.

### P2-4 — Say something about task tracking

The conductor reached for it, the harness dropped it, and afkkit is silent. Either sanction it with the caveat that it is not durable, or say plainly that the pipeline is the tracker.

## Expected effect

**Estimated, not validated.** No measurement run is planned, so nothing below will ever be checked. The cost *allocation* in [Evidence](#where-the-money-actually-went) is derived from measurement; the savings *forecast* here is reasoning.

| Change | Estimate | Basis |
|---|---|---|
| P1-2 (QA doesn't rebuild) | ~15–20% of run cost, ~5 min wall | The rebuild is identified, redundant, and already forbidden by qakit's own rule |
| P1-1 (orientation file) | ~10–15%, plus removes drift risk | Attacks the discovery phase across four steps |
| P1-3, P2-2, P2-3 | ~5% combined, more in batch | One subagent deleted, 14.2k evicted from resident context |
| P1-4 | 0% by decision | Tier moves dropped for lack of validation |

Roughly **25–35% off a single-issue run**, with the P0 items buying correctness rather than dollars. Implement's 45% is untouched and should stay that way.

## Non-goals

- **Do not optimize Implement.** It is 45% of cost and 11 minutes because it wrote 1,380 lines. That is the product.
- **Do not cut the spec gate.** Its output was valuable; the fix is to persist it, not to skip it.
- **No tier changes.** Settled above: unvalidatable bets are out of scope for this pass.
- **No run-report artifact.** afkkit's existing non-goal stands; the ledger stays something you ask for.
- **No config file.** The routing table plus a spoken inline override remains the whole surface.
- **No parallelism.** Sequential batching stays a v1 property; this plan is about per-issue cost, not concurrency.

## Validation

**There is none, by decision.** Each measurement run costs $11.79 and 34 minutes, and the changes here are individually defensible without one — that constraint is what removed the tier moves from scope.

If anyone ever funds a re-run: compare against the frozen baseline in [Evidence](#run-ledger-conductors-own-report) — 497,881 subagent tokens, 203 tool uses, 33.9 minutes, $11.79 — and note the *shape* of the issue in the comparison, since a 1,380-line feature and a typo fix are not the same measurement. Ask the conductor for the ledger explicitly at the end of the run; it is not produced by default.

## Hand off

**What changed** — nothing in any `SKILL.md` yet. This plan is the only artifact, now grilled: twelve decisions settled and recorded in [Settled decisions](#settled-decisions), three items resolved to *no change* with the reasoning preserved (tier moves, run-report artifact, validation run).

**Where it landed** — `docs/plans/plan-afkkit-cost-optimization-2026-08-06.md`, stamped `Grilled: 2026-08-06`.

**Next** — implement it as **one PR, by hand**, touching `skills/afkkit/SKILL.md` (most of it), `skills/qakit/SKILL.md` (the destructive-verification rule), and `skills/prkit/SKILL.md` (commit a handed-in path before pushing). P0 first, then P1, then P2. Run `make lint` before committing — it enforces the anchor links and closing-section rules these edits will touch.

**Do not run afkkit on this plan.** The conductor's own loaded skill text would be edited mid-run by the steps it is dispatching, and a `SKILL.md` change does not take effect until the next session anyway. This is the one plan in the repo that has to be done by hand — which is also why it is a PR rather than a set of issues.
