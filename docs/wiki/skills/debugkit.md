# debugkit

Chase a symptom to its true cause — reproduce it, shrink it, write falsifiable hypotheses, and prove the cause by toggling the symptom on and off — then hand over a failing reproduction instead of a fix.

**Reach for it when** something is broken, nobody knows why, and you want an answer you can check rather than a change that makes the red go away.

| | |
|---|---|
| Modes | single procedure, no modes — the branches are decided by evidence, not by the request |
| Tools | `Bash`, `Read`, `Grep`, `Glob`, `Edit`, `Write`, `WebSearch`, `WebFetch`, `AskUserQuestion` |
| Writes | `docs/debug/debug-<slug>-YYYY-MM-DD.md`, conditionally — durable, committable, never committed by the skill |
| Visibility | public |

## The gap it fills

Every other kit in the collection takes **intent** as its input. [`plankit`](./plankit.md) starts from an idea, [`implementkit`](./implementkit.md) from a settled plan, [`reviewkit`](./reviewkit.md) from a diff somebody just wrote, [`qakit`](./qakit.md) from a feature that was just built.

debugkit is the only one whose input is a **symptom** — something misbehaved, and the cause is unknown. That difference drives everything else about it, because a symptom is the one input where the agent's first job is to find out what is true rather than to act on what it was told.

## Why it never applies the fix

debugkit changes the repo freely to learn and reverts every one of those changes. The deliverable is a cause, a failing reproduction, and a fix *described*.

The reason isn't caution. A skill that finds the cause and also lands the cure has already committed to an answer by the time it writes the report — so what you read is a rationalization of an edit that already happened, not a diagnosis you could disagree with. Splitting them puts a moment in between where the reasoning has to stand on its own.

`Edit` is deliberately *present* in the tool list, which is the opposite of how [`refactorkit`](./refactorkit.md) enforces its own no-edit boundary. Probes genuinely are edits to tracked files, so the restraint here can't come from a missing tool — it has to come from the ledger, which is why the ledger gets so much of the skill's text.

## The failure it exists to prevent

An agent asked to debug has one dominant failure mode: it changes several things at once, the symptom disappears, and it declares victory. The cause was never found, so the bug returns next month wearing a different symptom.

What makes this worth a whole skill rather than a warning is that the bad output is **indistinguishable from the good one**. Same confidence, same vocabulary, same structure. You cannot review your way out of it, because there is nothing in the text to catch. So every rule in the skill is structural — something the agent must *produce* — rather than something it must remember not to do.

## Why the on/off test is the whole spine

You have the cause only when you can toggle the symptom by toggling the cause: present it fails, remove it passes, restore it fails again. All three, with the evidence quoted.

Two steps would be satisfied by coincidence. The third — restoring the cause and watching the symptom come back — is what rules out the thing that changed in between. It is also the step an agent skips first, because by then it already believes it has the answer.

**Nothing else in the skill needs an escape hatch, because this gate has none.** An untested idea cannot reach the report regardless of where it came from, which is how the web-lookup rule enforces itself for free in the normal case.

## The unsafe-to-toggle problem dissolves rather than gets an exception

The obvious objection: what about a destructive migration, a production-only race, data corruption — bugs where toggling the cause is expensive or dangerous?

The answer is that the question is already handled one gate earlier. The proof gate runs against the **reproduction**, never against a live system. So a cause too dangerous to toggle is a bug that was never safely reproduced, and it belongs in the instrumentation-plan branch by the reproduce gate that already exists.

This matters more than a tidiness argument. An explicit "when toggling is unsafe, skip the proof" clause would be a door marked *skip the gate*, positioned in exactly the situation that most tempts an agent to walk through it. Routing the case somewhere else instead means the proof gate stays absolute, and absolute gates are the only kind that survive contact with a hard bug.

## Three terminal states, because two was a lie

A run ends as a **proven cause**, as **reproduced but not explained**, or as an **instrumentation plan**.

The middle one is the state most debugging skills lack, and its absence is what quietly manufactures bad diagnoses: if the bug reproduces cleanly and every hypothesis dies, an agent with only two exits has to either invent a cause or claim it couldn't reproduce something it demonstrably did. Naming the state gives it somewhere honest to go — and the shrunk reproduction plus the list of eliminated candidates is genuinely valuable, because the next attempt starts from a far smaller box.

**Only the first state hands off to a build step.** The other two hand back to the user, since nothing was proven and there is therefore nothing to implement. An earlier draft of the design sent all three to [`implementkit`](./implementkit.md), which would have handed a build skill a theory and called it a finding.

## Why hypotheses are written before probing

Each candidate cause is written down first, and each carries a prediction that could fail.

Hypotheses written *after* probing are reverse-engineered from whatever happened to be observed, which makes every one of them fit and none of them discriminating. And a hypothesis with no falsifiable prediction can never be eliminated — so it survives the entire run and is still standing at the end, which is precisely how it ends up in the report as the answer.

The stop condition follows the same shape: stop when you can no longer write a new hypothesis carrying a falsifiable prediction. No arbitrary count, and an agent that wants another round has to produce a real prediction to earn it.

## Intermittent bugs, and the one rule that keeps the fallback honest

A test failing one run in twenty cannot be toggled on and off, so `Isolate` is required to force determinism first — pin the seed, serialize the concurrency, freeze the clock.

When that genuinely fails, the toggle takes a statistical form: N runs each way, both failure rates reported. The rule that makes this a fallback rather than a loophole is that **N is declared before running, never after**. The loophole was never statistics — it was running until the numbers looked convincing.

## `patch -R`, never `git checkout --`

The probe ledger is the only place in the skill where a bug could destroy somebody's work, because the user usually *does* have uncommitted changes when they ask you to debug something.

Each probe is snapshotted outside the working tree before the edit and recorded as its own patch, so it is cleanly separated from whatever the user had already changed in the same file. Reverting reverse-applies that patch. **`git checkout -- <path>` is banned without exception** — it restores the file to `HEAD` and takes the user's edits with it, and it is the move an agent reaches for by reflex.

The ban has no exceptions on purpose, including for files that looked clean at baseline. A prohibition you have to reason about is one you will talk yourself out of at the wrong moment.

The recipe specifies `patch -R` rather than `git apply -R` for a concrete reason found while testing the skill: `git apply` resolves the paths in the patch header against the repository root, and a patch generated from an out-of-tree snapshot carries paths that don't resolve, so it fails outright with `invalid path`. `patch -R` applies against the file you name and ignores the header.

A `git stash create` snapshot is taken before the first probe as a net. It writes an unreferenced commit and touches no ref, no file, and no index — and because an unreferenced object is invisible without `git fsck`, the skill prints its SHA and recovery command in every hand-off. A net nobody can find isn't one.

## Bisecting happens somewhere else entirely

`git bisect` moves `HEAD` and wants a clean tree, so running it in the user's working tree either refuses outright or walks over both their uncommitted work and the probe ledger. Any commit bisect therefore runs in a throwaway detached worktree that is removed before the run ends.

[`gitkit`](./gitkit.md) owns worktree lifecycle when it's installed; without it, `git worktree add --detach` and `git worktree remove` are the whole story.

## Regressions are in, optimization is out

"It got slower" fires; "make it faster" doesn't.

The seam is regression-versus-optimization rather than performance-versus-correctness. A regression has a change to bisect and a clean before-and-after, so the ritual runs completely unmodified. An endpoint that has always been slow has no cause to find — only a profile to read — and every gate in the skill presumes a working state that stopped working.

Leaving it unstated was the worse option: the skill would fire on "make this faster" anyway and then quietly fail the proof step, since there is no toggle, only a threshold.

## Web lookup decodes, it never diagnoses

Translating an opaque error string or a vendor status code is in bounds. Sourcing a hypothesis from a blog post, or applying a fix an issue thread says worked, is not.

The tools aren't withheld to enforce this, because withholding wouldn't be what enforces it — the mandatory on/off test already does, for free. In the instrumentation-plan branch nothing is tested, so the enforcement changes shape: **every entry must name its discriminating experiment or be dropped.** A fix lifted from an issue thread has no experiment attached, because it says *do this* rather than *measure this*. The requirement filters it structurally, with no rule about sources for anyone to remember.

## The artifact keys on outcome, not on effort

Always written for the two non-proven outcomes and for a proven cause that sat outside the code — environment, config, data, a dependency version. Never for a proven in-code cause.

The rule states its own reason: the file exists for what the commit history won't capture. A proven in-code cause is fully recorded by the fix and its test, so a document would only duplicate them. A stale environment variable and a list of dead hypotheses are recorded nowhere else, and they're exactly what nobody remembers next month.

An earlier version keyed the file on how many hypotheses were tested, which described nearly every real bug and made "conditional" a fiction.

## Hands off to

[`implementkit`](./implementkit.md), on a proven cause only. The diagnosis arrives as a *fix round* — a finding naming what's wrong and where — which implementkit accepts as passing its thin-input bar by construction, so the failing reproduction becomes its red test with no translation step. Without the ecosystem the move is the same one stated plainly: write the fix and make the reproduction pass.

The other two outcomes hand back to **the user**, deliberately, with no build step named. A feature request bounces to [`plankit`](./plankit.md) at the intake bar, before the ritual starts.

## Install

```sh
npx skills add mimukit/skills -s debugkit
```

Source: [`skills/debugkit/SKILL.md`](../../../skills/debugkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`d2e9d3b` on 2026-08-24._
