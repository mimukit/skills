---
name: testkit
description: >-
  Retrofit an automated test suite onto a working codebase that has none: rank the untested surface, crown a slice, stand up a runner, and write tests that were each watched to fail before they were kept. Use when the user says "this project has no tests", "add test coverage" to code that already runs, or "what should I test first". Tests for code still being built belong to implementkit.
license: MIT
allowed-tools: Bash, Read, Grep, Glob, Edit, Write, AskUserQuestion
metadata:
  internal: false
---

# testkit

Two modes. `audit` ranks the untested surface and writes nothing but a ledger. `cover` writes the tests.

Every kept test is observed red under a mutation, and takes its expectation from outside the implementation.

## When this fires

When the request is tests for code that does not exist yet, or for the feature being built right now, route it to a build skill: **implementkit** in TDD mode for test-first, or in tests-after mode for tests right after the build. Without implementkit, say the tests belong with the build.

## It never fixes, and it never restructures

**Retrofitting tests uncovers bugs. testkit reports them and does not fix them.** When observed behaviour contradicts the external expectation, do not edit the source to match the test, and do not edit the test to match the source. Write the test asserting the **intended** behaviour, mark it skipped or expected-to-fail with a one-line pointer, and report it.

**Some code cannot be tested without restructuring it. testkit does not restructure it.** No extracted interface, no injected dependency, no "small seam while I'm in here." Untestable code becomes a **testability blocker** in the ledger, routed onward.

The only source edits testkit ever makes are the temporary mutations of [The failure gate](#the-failure-gate), and every one is reverted.

## Mode selection

Take the first tier that answers:

1. **The user said a mode**, as in `/testkit audit` or `/testkit cover src/billing`. Explicit always wins.
2. **A ledger exists** → `cover`. **No ledger** → `audit`.

A `cover` request against a repo with no ledger **does not bounce.** Run the ranking inline, crown a slice, say which path the run took, and proceed.

An optional scope argument narrows what gets ranked in either mode. It never changes what gets written.

## The ledger

One file per repository: `docs/tests/NNNN-testplan-<repo>-YYYY-MM-DD.md`, where the date is its **creation** date and the whole name stays fixed forever. To get the serial `NNNN`, take the highest leading four-digit serial in `docs/tests/` across this worktree, every other worktree that `git worktree list` names, and `origin/<default branch>` (`git ls-tree --name-only origin/<base> docs/tests/` after `git fetch origin <base>`), and add one; start at `0001` when there is none. Scan all three, because parallel worktrees otherwise take the same serial. Skip a source that fails, such as no remote, and without git list the directory only. The serial is per directory and never reused. `audit` creates it. Every run after that finds it by `testplan-<repo>-`, with or without a leading serial, and updates it in place. A scoped run appends under a scoped heading in the same file, and it never spawns a second one.

It carries:

- the ranked untested surface, stamped `ranked against <sha> on <date>`;
- what each run covered, with its date and its declared-versus-actual count;
- what was deferred, and why;
- **testability blockers**, meaning code that cannot be tested without restructuring;
- **unproven tests**, meaning pre-existing tests that survived a mutation they should have caught;
- **over-broad tests**, meaning pre-existing tests that failed under a mutation aimed at a behaviour they do not name.

Durable and committable. testkit never commits it.

**When the repo already has a home or naming scheme for test-planning documents, that convention wins**, so say that you followed it. No writable filesystem (a browser-based agent) means printing the ledger as a codeblock under its canonical path instead.

## Mode: `audit`

Read-only. It writes the ledger and nothing else: no test file, no source edit.

### 1. Derive the untested surface

Find what source exists, what tests exist, and what those tests actually reach. **Read a coverage report only if one is already on disk. Never generate one, and never install or run a tool to produce evidence.**

Exclude before ranking, not after: generated code, vendored trees, thin configuration, and pure delegation.

The step is done when every source file sits either in the candidate list or in a named exclusion class.

### 2. Rank

One read of the history gives both signals at once: `git log --format= --name-only --since=<about a year>` yields how often each file changes and which files keep changing *together*.

Rank on four signals:

- **Churn.** How often it changes.
- **Fan-in.** How many modules depend on it.
- **Failure cost.** Money, authentication, data loss, migrations, anything irreversible.
- **Testability cost.** Divide by this.

**No git history**, meaning a shallow clone or not a repository, means no ranking. Scan by structure instead and say plainly that the prioritisation was skipped.

The step is done when every candidate has a rank, or the run has said that ranking was skipped and why.

### 3. Crown one slice

Group the top of the ranking into coherent slices along the co-change clusters, then crown **exactly one**, with runners-up in order.

### 4. Write the ledger

Every run carries a **coverage line**, in the terminal and in the file: *"ranked 1,240 files, read the top 40 across 3 slices."*

**An audit that finds no meaningful untested surface writes no file and says so.**

## Mode: `cover`

Writes the tests.

### 1. Take the slice, and check the ranking is still true

Take it from the ledger, from the user, or from an inline ranking when neither exists, and **say which**.

The ledger's ranking is stamped with the commit it was computed against. Compare `HEAD`. **Re-rank when the commits since that sha touched files in the ledger's top slice.** Otherwise trust it *out loud*, naming the sha you trusted.

The step is done when the run has named the slice, its source, and either the sha it trusted or the fresh ranking.

### 2. Stand up a runner, if there is none

Skip this when the repo already has one.

- **Inherit the ecosystem's default**, the runner the language's own documentation reaches for. When the choice is contested, route to a research skill rather than deciding it here.
- **Wire it into the repo's existing entry point**, such as `npm test`, `make test`, or `pytest`.
- **Test-file placement follows the repo.** Where an ecosystem carries two live conventions (colocated specs versus a `tests/` tree), follow whatever the repo's existing layout already implies.
- **Ask once before installing a dependency.**
- **Land one green smoke test before writing anything real.**

**When no standard runner can be wired up**, because the language, build system, or dependency situation defeats it, report the specific obstacle and stop. **Never improvise a harness.**

The step is done when one smoke test passes through the repo's entry point, or the run has stopped on a named obstacle.

### 3. Declare the size before writing anything

State it before the first test file exists: **"N behaviours in this slice, this run covers M."**

You pick the numbers. They go on the record in advance, and the hand-off reports actual against declared. A run that wants to exceed its declaration **stops and says so** rather than drifting.

### 4. Write the tests

**Source every expectation from outside the implementation**, meaning the docstring, the README, the issue, the type signature, the caller's actual usage, or the domain. Where nothing outside speaks, the test is a **characterization test**: a change-detector that locks current behaviour and makes no claim about correctness.

**Every test carries a one-line provenance comment, whichever kind it is:**

```
// per README: "amounts are stored in cents"
// characterization: no docstring, no issue, no caller assertion
```

**Fake only at the process boundary**, meaning network, clock, randomness, filesystem, or third-party service, and only where the real thing is unavailable or nondeterministic. Never fake a collaborator that lives inside the boundary. **Never assert that a call happened.**

**One behaviour per test, named for the behaviour** rather than for the function it happens to enter through.

**A contradiction becomes a skipped test plus a report**, never a source edit, never a weakened assertion. See [It never fixes, and it never restructures](#it-never-fixes-and-it-never-restructures).

The step is done when each of the M declared behaviours has a test with a provenance comment, or a skipped test plus a report.

### 5. Verify every target before running against it

**Nothing runs against a datastore or service testkit has not verified as disposable.**

Qualifying targets: `localhost`, a container testkit or the user started, or an explicitly named test URL. **A value inherited from an ambient `.env` never qualifies, however the file is named.**

Where no disposable target exists, **ask once** to scaffold one. If the answer is no, defer the integration work to the ledger as a blocker and carry on with the unit tier.

### 6. The e2e tier, when it applies

Opt-in and narrow. It runs only when the app already launches non-interactively **and** a driver is installed or the user approves installing one. Cap it at a handful of critical-path specs, such as the sign-in and the one transaction that matters, never a mirror of the UI.

**testkit never opens a browser as a session action.** It authors the spec; the only thing that ever drives a browser is the repo's own test command executing that spec. The failure gate applies to an e2e spec as it does to a unit test, through the runner.

## The failure gate

**Every test testkit keeps has been observed red.**

The code already exists, so red-then-green is unavailable. The substitute: break the behaviour, run the test, watch it fail, restore.

**A valid break is a semantic mutation, never a deletion.** Change a returned value, flip a comparison, drop a branch, skip a write. A deletion fails every test, including one that asserts nothing. Use the smallest edit that changes the behaviour the test claims to check.

**Run the narrowest selection the runner supports.** The target test plus the others in its file. Never the full suite. Confirm the expected one goes red, then read every neighbour that also went red. Where the runner cannot select a file or a pattern, lower the declared behaviour count and say why.

**A red neighbour is one of two things, and the gate tells them apart.**

- **Valid overlap.** The neighbour's own named behaviour depends on the mutated code, so it should fail. Two tests of one pricing function both fail when the rounding flips. Keep both, and record the overlap in the mutation row.
- **Overly broad assertion.** The neighbour names a different behaviour, and it failed because it asserts more than that behaviour: a whole object, a full snapshot, an unrelated field. When testkit wrote that test this run, narrow the assertion to its named behaviour and run the gate again for it. When the test is pre-existing, record it in the ledger as *over-broad* and leave it alone.

The test is the neighbour's name and provenance comment against the mutation: if the behaviour it names cannot be correct with the mutation in place, the overlap is valid.

**The gate is never skipped for slowness.** Full-suite runs happen exactly twice, at the done-gate, and nowhere else.

**A test testkit wrote this run that stays green under its mutation is deleted**, and the deletion is reported.

**A pre-existing test that stays green is recorded, not deleted.** Log it in the ledger as *unproven*, with the mutation that missed it, and route it to the user.

## The mutation ledger

Mutations are edits to tracked source. **The user may have had uncommitted work when the run started, and reverting a mutation must never revert it.**

- **Take a baseline first.** Keep the ledger in a directory outside the working tree. Before the first mutation, run `git stash create`, and record `git rev-parse HEAD`, `git diff --binary --cached`, and `git status --porcelain=v1 --untracked-files=all` in the ledger.
- **Record whether the snapshot exists.** `git stash create` writes an unreferenced commit of tracked changes and touches no ref and no file. On a clean tree, and on a tree whose only changes are untracked files, it prints nothing. Write `none` then, and never print a recovery line for an object that does not exist. When it exists, print the SHA and its `git stash apply <sha>` recovery line in the hand-off. Git prunes unreachable objects on its own schedule; say so rather than overselling the net.
- **Preserve untracked files separately.** The snapshot never covers them. Before a mutation touches an untracked source file, copy it into the ledger.
- **Record every mutation as its own patch, against the state just before it.** Before each mutation, copy the file to a fresh `mutation-NN/` directory in the ledger. After it, diff that copy against the file. Before the first mutation on a file, also keep a `.base` copy. A patch taken against an older copy carries earlier mutations too, and reversing it reverts them twice. Keep a row per mutation: the file, the patch, and the behaviour it was testing.
- **Revert by reverse-applying the recorded patch with `patch -R`. Never restore a file.** `git checkout -- <file>` silently destroys a pre-existing uncommitted edit. The ban has **no exception** for files that looked clean at baseline.
- **On a reverse-apply conflict, stop the run and report.** Do not force. Do not fall back to a restore.
- **Verify the baseline before declaring done.** Every mutated file matches its `.base` copy, HEAD and the index match their records, and the untracked-file list matches apart from the test files testkit created. Every untracked file a mutation touched matches its ledger copy. Name by path anything deliberately left in place.
- **Never revert, stash, or discard a change testkit did not make.**

## The done-gate

"Done" means green, twice, shuffled, and clean. Discover the commands from the repo itself (`package.json` scripts, `Makefile`, `pyproject.toml`, `justfile`, CI config) rather than guessing.

- The new suite **passes**.
- Every kept test was **observed red**, against a named mutation.
- The suite **runs twice in a row and passes both times**, in randomised order where the runner supports it.
- The repo's own **build/typecheck** still passes.
- The source tree carries **no leftover mutation**.

If the gate fails, fix your own output and re-run, **bounded to roughly three attempts**. Then report it red. Never declare done on a failing gate, and never weaken an assertion to pass it.

## Coverage numbers

**Never a goal, never a stopping condition.** Report a percentage only as a before-and-after fact, and only when the toolchain already produces one.

The stopping condition is the declared count.

## Hand off

_Write this section in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

**After `audit`.** Report the coverage line, the crowned slice, and the runners-up in order. Give the ledger path. Name the testability blockers and the unproven pre-existing tests, if the run found any. Say there is no test code yet. Then crown one next move: run `cover` on the crowned slice. When the audit wrote no file, say the surface is already covered and state that there is no next step.

**After `cover`.** Report:

- the **mode** and where the slice came from, whether the ledger, the user, or an inline ranking;
- **declared against actual**, as in "declared 8 behaviours, covered 8";
- the **files** created and changed, including the runner wiring;
- the **gate result**, meaning the commands that ran, that every kept test was observed red, and that the suite passed two consecutive runs;
- **deletions**, meaning tests testkit wrote and then removed because they stayed green;
- **unproven** and **over-broad** pre-existing tests, by path;
- the **baseline snapshot**: `baseline snapshot: <sha> · recover with git stash apply <sha>`, or `baseline snapshot: none (no tracked change at start) · mutation patches in <ledger>`;
- **tree state**, meaning the result of each baseline check: mutated files, index, and untracked files, or the paths that still carry a mutation.

Leave every change **unstaged**. Do not `git add`. Do not commit.

Then crown one next move:

- **Deferred work remains in the ledger** → run `cover` again on the next slice.
- **The run found a contradiction** → route it to a debugging skill when one is installed, otherwise say plainly that somebody must decide whether the behaviour or the expectation is wrong.
- **The run found testability blockers** → route them to a refactoring skill when one is installed, otherwise say the code needs a seam before it can be tested.
- **Nothing remains** → say the slice is done and name committing as the next move. Name **commitkit** when it is installed; otherwise suggest the type and scope `test(<area>)` for a `git commit` the user runs. Never commit automatically.

## Notes

- **No filesystem or shell?** You cannot write files, run a gate, or mutate anything, so the failure gate cannot run, and no test may be presented as verified. Print the proposed tests as fenced blocks with their paths, print the ledger as a codeblock under its canonical path, and list the gate commands the user must run themselves.
