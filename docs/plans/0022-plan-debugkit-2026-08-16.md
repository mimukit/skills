# Plan — debugkit

Grilled: 2026-08-16

## Context

Every skill in this collection takes *intent* as its input — a plan, an issue, a diff, a settled decision. None of them takes a **symptom**: something is broken, and nobody knows why. That is the gap `debugkit` fills, and it is the top row of `IDEAS.md`.

The reason it needs a ritual rather than a prompt is specific. An agent asked to debug has one dominant failure mode: it changes several things at once, the symptom disappears, and it declares victory. The cause was never found, so the bug returns next week wearing a different symptom — and the report reads exactly like a real diagnosis, with the same confidence and the same vocabulary. Every rule below exists to make that outcome structurally hard rather than merely discouraged.

Success means a run ends in one of **three honest states**, never in a fourth. A **proven cause**, demonstrated by toggling the symptom on and off, handed to `implementkit` with a failing reproduction it can turn green. A **reproduced but unexplained** bug, handed forward as a shrunk reproduction plus every hypothesis that died and the evidence that killed it. Or an **instrumentation plan**, when the bug could not be reproduced at all — ranked hypotheses each paired with the measurement that would discriminate it, handed back to the user rather than to a build step, because nothing has been proven and there is nothing yet to fix. A plausible theory that was never tested is the fourth state, and it is a failure even when it happens to be right.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Does it fix? | **No, never.** debugkit mutates freely to *learn* — log lines, bisects, config probes — and reverts every one. The deliverable is the cause plus a failing reproduction. `implementkit` lands the fix. The skill that finds the cause does not also decide the cure, so the report is a diagnosis rather than a rationalization of an edit already made. |
| The intake bar | **Three facts, or ask once: expected, actual, and where you saw it.** Expected-versus-actual *is* the symptom, and an agent handed only "it's broken" invents the expectation it then debugs against — which is the root of confidently fixing the wrong thing. "Where" sorts the run onto the reproduce path or into evidence-only immediately. The bar is answerable in one sentence, which is what stops it being skipped. When "expected" turns out to be behaviour nobody ever built, this is a feature request: bounce it to `plankit`. |
| The reproduce gate | **No reproduction, no diagnosis** — with an explicit degraded mode rather than a silent one. An unreproduced bug yields a theory that sounds identical to a finding. This gate carries more traffic than it looks: every production-only bug and every cause that cannot be safely toggled lands here, so the degraded path is a first-class branch with a stated confidence, never a quiet fallback. |
| The proof gate | **The on/off test.** You have the cause only when you can toggle the symptom by toggling the cause — on it fails, off it passes, on again it fails. Anything short of that is correlation. This is the single gate separating debugkit from "I changed something and it stopped." |
| The proof gate never runs against production | **The gate needs no unsafe-case exception, because the reproduce gate already filtered for one.** Toggling happens in the reproduction, never in the live system, against real data, or against anything the user did not point at. A cause too dangerous to toggle is a bug that was never safely reproduced, so it belongs in evidence-only mode by the gate that already exists rather than by a new escape hatch. An escape hatch here would be a door marked *skip the proof* in exactly the situation that most tempts an agent to walk through it. |
| Intermittent bugs | **Isolate must force determinism first** — pin the seed, serialize the concurrency, freeze the clock. Only when that genuinely fails does the toggle take a statistical form: N runs with the cause and N without, reporting both failure rates. The one rule that makes the fallback honest instead of a loophole is that **N is declared before running, never after**. The loophole was never statistics; it was running until the numbers looked convincing. |
| Where `git bisect` runs | **In a throwaway worktree, never the user's.** `git bisect` moves `HEAD` and wants a clean tree, so running it in place either refuses outright or walks over both the user's uncommitted work and debugkit's own probe ledger. A detached-head worktree keeps probes and bisects in separate trees where they cannot interfere. `gitkit` owns worktree lifecycle when installed; the plain fallback is `git worktree add`. The worktree is removed before the run ends, or named by path in the hand-off if it is not. |
| Terminal states | **Three, each with its own exit.** Proven cause, reproduced-but-unexplained, and instrumentation plan. The middle one is the outcome the original draft had no room for, and it is the most common result of genuinely hard debugging: the bug reproduces cleanly and every hypothesis dies. Reporting it as a real outcome ships the shrunk reproduction and the eliminated candidates, so the next attempt starts from a much smaller box instead of from zero. |
| When to stop hypothesizing | **When you can no longer write a hypothesis carrying a falsifiable prediction.** Tied to the Hypothesize beat rather than to a counter, so it needs no arbitrary number and fails loudly: an agent that wants to keep going has to produce a real prediction to justify it. |
| What evidence-only mode may say | **An instrumentation plan, never a cause.** Ranked hypotheses, each paired with the specific experiment or log line that would discriminate it — the deliverable answers *what to measure next*, not *what is wrong*. A confidence percentage on an untested theory is precisely what the reproduce gate exists to prevent, wearing a number. |
| The handoff shape | **Two different exits, not one.** A proven cause hands `implementkit` a failing reproduction — a command or a red test — plus the cause and a described fix. That needs no new machinery: `implementkit` already accepts a *fix round* (findings that each name what's wrong and where) and treats that class as passing its thin-input bar by construction, so a diagnosis is that shape with one finding, and it gives implementkit TDD for free. The other two exits hand back to **the user**, because nothing was proven and there is no fix to implement. |
| The probe revert primitive | **Reverse-apply your own recorded diff; never restore a file.** `git checkout -- <file>` is the reflex move and the one that silently destroys a pre-existing uncommitted edit, so the prohibition is stated outright rather than implied. Each probe's diff is recorded when it is made and undone by applying it in reverse. When reverse-apply hits a conflict, the run stops and reports rather than forcing. |
| The baseline net | **`git stash create` before the first probe, and its SHA is always reported.** The call writes an unreferenced commit object and touches no ref and no file, which is what makes it free. It is also what makes it invisible — an object the user cannot find without `git fsck` is not a safety net — so the hand-off prints `baseline snapshot: <sha> · recover with git stash apply <sha>`, with the honest caveat that git prunes unreachable objects on its own schedule. No ref is written, because a ref would outlive the run. |
| Performance | **Regressions are in scope; optimization is out.** The seam is regression-versus-optimization, not performance-versus-correctness. "It used to be fast" has a change to bisect and a clean before-and-after, so the ritual runs unmodified. "It has always been slow" has no cause to find, only a profile to read, and the entire ritual presumes a working state that stopped working. Write it as a trigger distinction — "it got slower" fires, "make it faster" does not. |
| Artifact policy | **Keyed on outcome, not on hypothesis count.** The original trigger ("more than one hypothesis tested") describes nearly every real bug, which makes "conditional" a fiction. Always write for reproduced-but-unexplained and for evidence-only, since both exist to be picked up later. For a proven cause, write only when the cause sat **outside the code** — environment, config, data, a dependency version. The rule states its own reason: the file exists for what the commit history will not capture. A proven in-code cause is fully recorded by `implementkit`'s fix and its test. |
| Artifact path and durability | `docs/debug/debug-<slug>-YYYY-MM-DD.md`, **durable and committable** like refactorkit's proposal rather than scratch like statuskit's snapshot. A postmortem earns tracking. debugkit still never commits it, and `docs/debug/` stays out of `.gitignore`. Writing no file remains a legal outcome, following refactorkit's precedent. |
| Web lookup | **Allowed, and bounded structurally rather than by tool withholding or by a rule to remember.** Search **decodes** a signal; it never **sources** a hypothesis. In the reproducible branch the on/off test enforces this for free — an untested idea cannot reach the report whatever its origin. In evidence-only mode nothing is tested, so the enforcement is instead that **every instrumentation-plan entry must name its discriminating experiment or be dropped**. A fix lifted from an issue thread has no experiment attached: it says *do this*, not *measure this*. That filters it without any rule about sources. |
| Domain playbooks | **Out of scope.** The `IDEAS.md` row named docker/dokploy failures and WordPress local-to-prod migration; the skill ships the domain-agnostic ritual only. Those are the owner's stack rather than every installer's, and the ritual has to carry its own weight without them. Narrow the `IDEAS.md` row's wording when the skill graduates. |
| Structure | **One `SKILL.md`, no modes.** Every skill in the collection is a single file (verifykit's shell script aside), and the ritual runs the same way on every bug. The three-exit split is a branch inside the procedure, not a mode. |
| Tools | `Bash, Read, Grep, Glob, Edit, Write, WebSearch, WebFetch, AskUserQuestion`. `Edit` is present *because* probes are edits to tracked files, which is what makes the revert discipline load-bearing rather than decorative. `Bash` additionally carries the worktree, bisect, and snapshot operations. |
| Directory group | Fold into **Testing & QA** in `skills.sh.json` and widen that group's description. Diagnosis sits next to verification; a group of one is thinner than the adjacency is loose. |

## Approach

**What this reuses.** `refactorkit` supplies two patterns almost directly: the closed set of things to look for, and the rule that an empty result is a real outcome that writes no file. `prototypekit` supplies the disposal discipline — it registers a guard *before* the first file exists and confirms every deletion individually — though debugkit's probes edit **tracked** files, so the private-exclude mechanism does not carry over and the revert needed its own design. `gitkit` supplies the worktree lifecycle for the bisect branch, and its stance on uncommitted work ("show exactly what would be lost, never `--force` on the human's behalf") is the posture the probe ledger inherits. `implementkit`'s fix-round input class is the proven-cause handoff target and needs no change on its side. `AGENTS.md` supplies the artifact naming and the hand-off structure.

**What is genuinely new.** No skill in this collection has a working-tree restore primitive — `statuskit` reads `git stash list` and nothing writes one — so the reverse-apply ledger in Phase 2 is the collection's first, and it is the only place in the plan where a bug in the skill can destroy the user's work.

### Phase 1 — Draft the skill

The whole of `skills/debugkit/SKILL.md`. One file, one unit of work.

**The intake bar, before the ritual starts.** Expected, actual, where. Missing any of the three, ask once. Behaviour nobody ever built is a feature request, and the route is `plankit`.

**The ritual, in five beats:**

1. **Reproduce** — a command that makes it fail, every time, that anyone can run. Gate: no reproduction, no diagnosis. When reproduction genuinely fails — including when it fails because reproducing safely is impossible — drop to the evidence-only branch and say so out loud with a stated confidence.
2. **Isolate** — shrink the reproduction until nothing can be removed without the symptom disappearing, and **force determinism** while doing it: pin the seed, serialize the concurrency, freeze the clock. Bisect over whatever axis exists — commits, inputs, config, dependency versions, the environment delta — and run any commit bisect in a throwaway worktree. The output is the smallest deterministic failing case.
3. **Hypothesize** — write the candidate causes *before* testing any of them, each carrying a **prediction that could fail**. A hypothesis with no falsifiable prediction is a guess wearing a label. Test the cheapest **discriminating** hypothesis first — the one that eliminates the most candidates, not the one that is easiest to type. Stop when you can no longer write a new falsifiable one.
4. **Prove** — the on/off test, mandatory, with its evidence quoted. Never against production or real data. One change at a time; two changes at once teaches you nothing about either. Where determinism could not be forced, N runs each way with N declared in advance and both failure rates reported.
5. **Report** — one of the three terminal states, with the matching exit. Proven cause goes to `implementkit` with the failing reproduction and a fix described rather than applied. The other two go back to the user.

Also in this phase: the bounce conditions (a feature request routes to `plankit`; a symptom in a diff that was never run is not a debugging job), the boundary lines against `reviewkit`, `qakit`, and `prototypekit`, the performance trigger distinction, and the web rule in both its forms.

Acceptance criteria:

- [ ] The intake bar names its three facts and its `plankit` bounce.
- [ ] The reproduce gate names its degraded mode and requires a stated confidence when it fires.
- [ ] The on/off test is mandatory, is forbidden against production and real data, and the skill says an unproven cause is reported as unproven.
- [ ] Hypotheses are written before testing, each carries a falsifiable prediction, and the stop condition is stated.
- [ ] The statistical fallback requires N to be declared before running.
- [ ] All three terminal states are named, and the two non-proven ones exit to the user rather than to `implementkit`.
- [ ] The web rule is enforced by the discriminating-experiment requirement, not by a prohibition.
- [ ] `SKILL.md` carries `metadata.internal: false`, an `allowed-tools` line, a "Use when" trigger, and a `## Hand off` section.
- [ ] The skill states that it never applies the fix.

### Phase 2 — The probe ledger

The safety property that makes free mutation acceptable, and the only part of the plan with a real hazard behind it: **the user may have had uncommitted work when debugging started**, and reverting a probe must never revert that.

- Take `git stash create` before the first probe. It writes an unreferenced commit and touches nothing, so it costs the user nothing and is recoverable.
- Keep a ledger of every probe: the file, the diff, and why the probe was made.
- **Revert by reverse-applying the recorded diff. Never restore a file.** `git checkout -- <file>` is banned outright, including on files that looked clean at baseline, because the ban is only useful if it has no exceptions to reason about.
- When reverse-apply conflicts, stop and report. Do not force, and do not fall back to a restore.
- Verify the tree matches the baseline at the end. Report by path anything deliberately left in place, and never touch a file the run did not modify.
- Remove any bisect worktree, and name it by path in the hand-off if removal failed.
- Print the baseline SHA and its recovery command in the hand-off, every run.

Acceptance criteria:

- [ ] A probe on a file with pre-existing uncommitted changes reverts the probe and preserves the user's edit.
- [ ] A reverse-apply conflict stops the run and reports, rather than forcing or restoring.
- [ ] The hand-off states the tree is clean of probes, or names what remains and where.
- [ ] The hand-off prints the baseline SHA and its `git stash apply` recovery line.
- [ ] Any bisect worktree is removed, or reported by path.
- [ ] The skill never reverts, stashes, or discards a change it did not make.

### Phase 3 — Live-test it on a real bug

The phase that actually validates the ritual, because the failure this skill exists to prevent only appears under pressure. Run the drafted skill against a genuine bug — a real one if the collection has one to hand, otherwise a planted defect in a scratch project with a known cause.

Watch specifically for the collapses:

- Hypotheses written *after* probing rather than before.
- The on/off test skipped in favour of "the symptom went away."
- N chosen after the runs rather than before.
- Probes left on disk, or reverted with a file restore.
- The reproduced-but-unexplained exit quietly upgraded to a proven cause.

Feed the findings back into Phase 1's file. This phase is sequential with Phase 1 by design, not parallel.

Acceptance criteria:

- [ ] The skill runs end to end on a real or planted bug and reaches a proven cause.
- [ ] A run against an unreproducible symptom terminates in an instrumentation plan rather than a theory.
- [ ] A run where every hypothesis dies terminates in the reproduced-but-unexplained state, with the shrunk reproduction attached.
- [ ] Every probe made during the test runs is gone from the tree afterwards, and no user edit was lost.

### Phase 4 — File it into the collection

Repo integration, per `AGENTS.md`. Four files, none of them touched by the phases above.

- `docs/wiki/skills/debugkit.md` — the reader-facing page, with the summary table, the *why* behind the two gates, the hands-off-to section, the install command, and the provenance stamp.
- `skills.sh.json` — add to **Testing & QA** and widen that group's description.
- `README.md` — add the skills-table row.
- `IDEAS.md` — delete the `debugkit` row on ship, per the file's own graduate rule.

Acceptance criteria:

- [ ] `make lint` passes with 0 errors and 0 warnings.
- [ ] The wiki page exists, its provenance stamp reflects a real read, and it explains rather than restates.
- [ ] `debugkit` appears in `skills.sh.json` and the README table, and no longer appears in `IDEAS.md`.

## Open questions

The grill closed the five that were here. These three are genuinely undecidable from a desk and should be settled by the live test in Phase 3, not before it.

- **What N defaults to in the statistical fallback.** The rule that N is declared before running is what makes it honest, but the skill still needs a starting number to suggest, and the right one depends on how rare the failure is. A stated default risks anchoring; no default risks an agent picking three.
- **Whether reproduced-but-unexplained deserves its own artifact slug.** It currently shares `debug-<slug>-YYYY-MM-DD.md` with the other outcomes. A distinct marker would make the resumable ones findable, at the cost of a second naming rule to remember.
- **How aggressively Isolate should force determinism.** Serializing concurrency can make an intermittent bug vanish entirely — the forcing changes the thing being measured. The beat needs a stated response for that case, and only a real intermittent bug will show what it should be.

## Non-goals

- **Applying the fix.** Not conditionally, not for one-liners, not when it is obvious. `implementkit` owns it.
- **Proving a cause in production.** The on/off test runs in the reproduction. A bug that only exists in production exits as an instrumentation plan.
- **Optimization and profiling.** A performance *regression* is in scope. "Make this faster" is not — it has no cause to find, and the ritual presumes a working state that stopped working.
- **Domain playbooks.** No docker, dokploy, or WordPress migration content, despite the `IDEAS.md` row. Narrow that row when the skill ships.
- **Building a test suite.** debugkit may produce one failing test as the reproduction; standing up automated tests for a project that has none is `testkit`, the next backlog row.
- **Reviewing a diff for defects.** `reviewkit` reads work someone just did. debugkit chases a symptom in code that already ran.
- **Planning how to verify a feature.** That is `qakit`, and it runs before the bug, not after.
- **Answering a design question by building.** `prototypekit` builds to settle an *unsettled intent*. debugkit probes to explain an *observed failure*.
- **Committing anything**, including its own artifact.
