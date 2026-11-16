---
name: debugkit
description: >-
  Chase a symptom to its true cause: reproduce it, shrink it, write falsifiable hypotheses, and prove the cause by toggling the symptom on and off, then hand over a failing reproduction instead of a fix. Use when the user says "debug this", "why is this failing", "find the root cause", "what's causing this bug", "this test is flaky", "it broke after the upgrade", "it worked yesterday", "this got slower", or "/debugkit".
license: MIT
allowed-tools: Bash, Read, Grep, Glob, Edit, Write, WebSearch, WebFetch, AskUserQuestion
metadata:
  internal: false
---

# debugkit

## It diagnoses, it never fixes

**debugkit mutates the repo freely to learn, and reverts every one of those mutations.** Log lines, bisects, config probes, commented-out branches are all fair game, and none of them survive the run. What survives is the cause, a failing reproduction (a red test stays on disk as the hand-off artifact), and a fix *described* rather than applied. **Never apply the fix**, not even an obvious one-liner.

**Out of scope:** behaviour nobody ever built (see [the intake bar](#the-intake-bar)), "make this faster" with no prior fast state, and a suspected bug in a diff nobody has run, which is a review job. A performance regression is in scope.

## The intake bar

Before the ritual starts, you need three facts. **Ask once if any is missing, then stop until you have them.**

| Fact | Why it is required |
|---|---|
| **Expected** | what should have happened |
| **Actual** | what happened instead |
| **Where** | which environment, branch, or machine you saw it on |

Without expected vs actual, you debug an invented expectation. "Where" decides between the reproduce path and the [instrumentation-plan branch](#the-three-terminal-states).

**One bounce.** When "expected" turns out to be behaviour nobody ever built, this is a feature request rather than a bug. Say so and route to a planning skill: **plankit** when it is installed, otherwise say plainly that this needs a plan, not a diagnosis.

## The three terminal states

Every run ends in exactly one of these.

| Outcome | What it means | Where it goes |
|---|---|---|
| **Proven cause** | the on/off test passed, so you can switch the symptom on and off at will | a build skill, with the failing reproduction |
| **Reproduced, not explained** | the bug reproduces reliably and every hypothesis died | back to the user, with the shrunk reproduction and the eliminated candidates |
| **Instrumentation plan** | the bug could not be reproduced at all | back to the user, with ranked hypotheses and the measurement that would discriminate each |

**A plausible theory that was never tested is not a fourth state; it is a failure even when it happens to be right.** Report an unproven cause as unproven.

## The ritual

### 1. Reproduce

Find a command that makes it fail, every time, that anybody can run.

**The gate: no reproduction, no diagnosis.** Every production-only bug and every cause that cannot be toggled safely fails here, because [the proof gate](#4-prove) runs against the reproduction and nothing else.

The step is done when one command fails on three consecutive runs, or when you have declared the symptom intermittent and carry it to the statistical form of the proof gate.

When reproduction fails, **say so with a stated confidence** and drop to the instrumentation-plan branch.

### 2. Isolate

Shrink the reproduction until nothing can be removed without the symptom disappearing. The output is the smallest failing case.

**Force determinism while you shrink.** Pin the seed, serialize the concurrency, freeze the clock, fix the fixture ordering. The proof gate needs a symptom you can toggle.

Bisect over whatever axis the bug actually has: commits, inputs, config values, dependency versions, the delta between two environments.

**Run any commit bisect in a throwaway worktree, never in the user's tree.** `git bisect` moves `HEAD` and wants a clean tree, so in place it refuses or walks over the user's uncommitted work and your probe ledger:

```sh
git worktree add --detach <scratch-path> <known-good-ref>   # bisect lives here
git worktree remove <scratch-path>                          # before the run ends
```

A worktree skill owns this lifecycle when one is installed (**gitkit**). Either way, remove the worktree before the run ends, or name it by absolute path in the hand-off if removal failed.

**When forcing determinism makes the bug vanish entirely**, that is itself a finding, because the timing *is* the mechanism. Say so, keep the non-deterministic reproduction, and carry it into the statistical form of the proof gate.

### 3. Hypothesize

**Write the candidate causes down before testing any of them.** Each one carries a **prediction that could fail**: something you expect to observe that you would not observe if the hypothesis were wrong.

**Test the cheapest discriminating hypothesis first**, meaning the one that eliminates the most candidates.

**Prefer a probe that changes nothing.** Calling the unit directly, running it in a fresh process, or printing an intermediate value from the outside often discriminates just as sharply as an edit and needs no revert. Reach for [the ledger](#the-probe-ledger) only when the question requires changing the code.

**Stop when you can no longer write a new hypothesis carrying a falsifiable prediction.** When you hit it with the bug still reproducing, the run ends in **reproduced, not explained**.

### 4. Prove

**The on/off test, and nothing weaker.** You have the cause only when you can toggle the symptom by toggling the cause:

1. Cause present → it fails.
2. Cause removed → it passes.
3. Cause restored → it fails again.

Anything short of all three is correlation.

**Quote the evidence** for each of the three steps, never just the word "confirmed".

**One change at a time.**

**Never toggle against production, against real data, or against any system the user did not point at.** The test runs in the reproduction, with no unsafe-case exception: a cause too dangerous to toggle belongs in the instrumentation-plan branch.

**When determinism could not be forced**, the toggle takes a statistical form: three arms of N runs each, cause present, cause removed, and cause restored, reporting every failure rate. **Declare N before running, never after.** State N, state each rate, and state that the fallback was used.

**The evidence bar for the statistical form:** N is at least 20, the cause-removed arm shows zero failures, and the present and restored arms each show at least 5. At a 25% failure rate, 20 clean runs happen by chance about 0.3% of the time. Below that bar the run is not a proof. Report it as **reproduced, not explained**, with the three rates, and name the larger N that would settle it.

The step is done when all three toggles, or all three arms, have quoted evidence that meets the bar.

### 5. Report

Name the terminal state, then give it what it needs.

**Proven cause.** Give the cause in one sentence, the on/off evidence, the failing reproduction, and the fix **described rather than applied**. Write the reproduction as a red test in the repo's own test layout when a runner exists, and as a command otherwise.

**Reproduced, not explained.** Give the shrunk reproduction, every hypothesis you eliminated, and the evidence that killed each one.

**Instrumentation plan.** Give ranked hypotheses, each paired with the specific experiment or log line that would discriminate it. The deliverable answers *what to measure next*, never *what is wrong*. **Attach no confidence percentage to an untested theory.**

## The probe ledger

**Assume the user had uncommitted work when debugging started.** Reverting a probe must never revert that.

**Take a baseline before the first probe.** Keep the ledger in a directory **outside the working tree**, so nothing in it shows up in `git status`.

```sh
snap=$(git stash create)    # an unreferenced commit of tracked changes; empty on a clean tree
git rev-parse HEAD                          > <ledger>/head.pre
git diff --binary --cached                  > <ledger>/index.pre
git status --porcelain=v1 --untracked-files=all > <ledger>/status.pre
```

`git stash create` touches no ref, no file, and no index. **Record whether it produced an object.** On a clean tree, and on a tree whose only changes are untracked files, it prints nothing, and there is no snapshot to recover from. Write `none` in the ledger in that case, and never print a recovery line for an object that does not exist.

The snapshot never covers untracked files. **When a probe can touch an untracked file** (it edits one, or runs a command that writes into its directory), copy that file into the ledger before the probe. The copy is the only recovery path for it.

**Record every probe as its own patch, taken against the state just before that probe.** Before each probe, copy every file it will edit into a fresh probe directory in the ledger. After the probe, diff each copy against its file. Before the first probe on a file, also keep a `.base` copy for the final check.

```sh
cp <path> <ledger>/<name>.base                                # once, before the first probe on the file
cp <path> <ledger>/probe-NN/<name>.pre                        # before every probe
diff -u <ledger>/probe-NN/<name>.pre <path> > <ledger>/probe-NN/<name>.patch   # after it
```

Each patch holds that probe's change alone. A patch taken against the first-edit copy holds every earlier probe as well, and reverse-applying a set of such patches reverts an earlier probe twice or fails. Keep a ledger row per probe: the paths, the patches, and why you made it.

**Revert by reverse-applying your recorded patches, in reverse order. Never restore a file.**

```sh
patch -R -s <path> < <ledger>/probe-NN/<name>.patch   # correct
git checkout -- <path>                                # banned, without exception
```

**Use `patch -R`, not `git apply -R`.** `git apply` resolves the paths written in the patch header against the repository root, and a patch produced from an out-of-tree snapshot carries paths that do not resolve, so it fails with `invalid path` rather than applying. `patch -R` applies against the file you name and ignores the header, which is exactly the property you need here.

`git checkout -- <path>` silently destroys a pre-existing uncommitted edit. The ban covers files that looked clean at baseline too.

**When reverse-apply conflicts, stop and report.** Do not force it, and do not fall back to a restore. Name the file, the probe, and the patch location, and let the user resolve it.

**Finish by verifying all three parts of the baseline.** The cleanup is done when each check passes or its difference is reported:

- **Tracked content.** Every file a probe edited matches its `.base` copy (`cmp`), and `git rev-parse HEAD` matches `head.pre`.
- **The index.** `git diff --binary --cached` matches `index.pre`. debugkit never stages, so any difference is a fault to report.
- **Untracked files.** `git status --porcelain=v1 --untracked-files=all` matches `status.pre`, apart from the reproduction test. Every untracked file a probe touched matches its ledger copy.

**The reproduction test is the one write that survives.** It is the hand-off artifact for a proven cause, not a probe, so it is not in the ledger and is not reverted. Leave it red and unstaged, and name it by absolute path. Report by absolute path anything else deliberately left in place, and never touch a file the run did not modify.

**Print the baseline line in the [hand-off](#hand-off), every run**, because an unreferenced commit is invisible without `git fsck`. Say plainly that git prunes unreachable objects on its own schedule, so the snapshot is short-term recovery, not an archive. Write no ref: a ref would outlive the run.

## Web lookup decodes, it never diagnoses

- **In bounds.** Translating an opaque error string, a vendor status code, a stack frame from a library you do not know, a changelog entry for the version you just bisected to. Decoding a signal you already observed.
- **Out of bounds.** Sourcing a hypothesis from a blog post, or applying a fix an issue thread says worked. That is somebody else's diagnosis of somebody else's bug.

**In an instrumentation plan, drop any entry with no discriminating experiment.**

## The artifact

| Outcome | File? |
|---|---|
| Reproduced, not explained | **always** |
| Instrumentation plan | **always** |
| Proven cause, cause outside the code (environment, config, data, a dependency version) | **always** |
| Proven cause, cause in the code | **no**, report inline |

**The file records what the commit history will not capture.** A proven in-code cause is recorded by the fix and its test.

Write it to `docs/debug/NNNN-debug-<slug>-YYYY-MM-DD.md`, built from a four-digit serial, a lowercase type prefix, a short lowercase kebab-case subject slug, and the ISO creation date at the end. To get the serial `NNNN`, take the highest leading four-digit serial in `docs/debug/` across this worktree, every other worktree that `git worktree list` names, and `origin/<default branch>` (`git ls-tree --name-only origin/<base> docs/debug/` after `git fetch origin <base>`), and add one; start at `0001` when there is none. Scan all three, because parallel worktrees otherwise take the same serial. Skip a source that fails, such as no remote, and without git list the directory only. The serial is per directory and never reused. Keep the whole name stable when the file is edited, and update the same file in place when you return to the same bug rather than spawning a second copy. **When the repo already has an established home or naming scheme for postmortems, that convention wins**, so say that you followed it.

The file is durable and belongs in version control. debugkit never commits it.

**No writable filesystem** (a browser-based agent) → print the artifact as a codeblock under its canonical path and skip the write.

## Hand off

_Write this section in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

**What changed.** Name the terminal state. List every probe you made and confirm you reverted it. Report the result of each baseline check. State that you applied no fix. Name the reproduction test by absolute path, and say that it stays on disk, red and unstaged. Name any file you deliberately left in place, by absolute path. Name any bisect worktree you failed to remove, by absolute path.

**Where it landed.** Give the artifact path, or say that the outcome needed no file. Print the baseline line every run: the first form when `git stash create` produced an object, the second when it printed nothing.

```
baseline snapshot: <sha> · recover with git stash apply <sha>
baseline snapshot: none (no tracked change at start) · probe patches in <ledger>
```

**Next.** Crown one move, and match it to the outcome:

- **Proven cause** → hand the reproduction test and the described fix to a build skill. Name **implementkit** when it is installed, as a fix round with the reproduction test as its input: `implementkit fix round: make <test path> pass; cause: <one sentence>`. implementkit runs the test red first, keeps it, and shows it green at its done-gate. Otherwise say plainly that the next step is to write the fix, keep the test, and watch it pass.
- **Proven cause is a slow query** → name **dbkit** `tune` when it is installed, with the query as its input. Otherwise say plainly that the next step is to read the query's plan and fix the query or its index.
- **Reproduced, not explained** → tell the user what evidence would restart the hunt. Do not route to a build skill. Nothing is proven yet.
- **Instrumentation plan** → tell the user to deploy the measurements you listed. Say that they should run debugkit again when the evidence arrives.

Do not start the next step yourself.

## Notes

- **Follow the repo over these defaults.** A documented convention or a stated policy in the repo's agent-guide file (`CLAUDE.md` or an equivalent) wins, so say that you followed it.
