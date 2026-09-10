# Plan — testkit

Grilled: 2026-08-18

## Context

Every skill in this collection that touches tests assumes a suite already exists. `implementkit` resolves TDD mode by looking for "real test infrastructure" plus a repo habit of shipping tests with features, and covers only *new* work. `qakit` writes manual plans and says outright that automated tests belong to "a separate test-suite skill." `debugkit` produces exactly one failing test, as a reproduction. `reviewkit` can flag a gap in coverage but never closes it. `refactorkit` names *untested coupling* as one of its four friction patterns and then proposes a restructure rather than a test.

Nothing in the collection stands a suite up on code that already exists and already works. That is `testkit`, the top row of `IDEAS.md`.

The reason it needs a ritual rather than a prompt is specific, and it is not the same failure as debugkit's. An agent asked to "write tests for this project" reliably produces **coverage theater**: a large pile of tests that mirror the implementation line for line, assert that mocks were called, pass on the first run, and pin whatever the code does today — bugs included. It looks exactly like a real suite. Same directory layout, same green checkmarks, same coverage badge. It is worse than no suite, because it charges maintenance rent forever and detects nothing, and because the green checkmark is now evidence in an argument it cannot support.

Two properties separate a real brownfield test from that pile, and both are structurally absent from the naive approach. First, **the test has been observed to fail** — code written before the test means red-then-green is unavailable, so the failure has to be manufactured deliberately or it never happens at all. Second, **the expectation came from outside the implementation** — a test whose expected value was read off the function it tests is a photograph of the current behavior, not a claim about the correct one. Every rule below exists to make those two properties mandatory rather than aspirational.

Success means an `audit` run ends with the untested surface ranked and one slice crowned, and a `cover` run ends with a suite where every kept test was watched to fail, the source tree is clean of the mutations that made it fail, and the run says plainly what it deliberately did not test.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Modes | **Two: `audit` and `cover`.** `audit` is read-only — it ranks the untested surface, crowns a slice, writes the plan artifact, and writes no test code. `cover` takes a slice and writes the tests. The split earns itself because the outputs are different classes of thing, and because a brownfield retrofit is a negotiation: somebody should be able to see the ranked surface and argue with the ordering before any test file lands. Bootstrap is **not** a third mode — standing up a runner happens once per repo, and a mode nobody invokes twice is a branch wearing a mode's name. It folds into `cover` as its first conditional. |
| Mode selection | **Explicit word wins; otherwise `audit` when no artifact exists, `cover` when one does.** A `cover` request against a repo with no artifact does **not** bounce — it runs the ranking inline, crowns a slice, says which path it took, and proceeds. Refusing to write a test until a survey document exists is bureaucracy, and it is the kind that gets the skill uninstalled. |
| The failure gate | **Every kept test is observed red before it is kept.** The code already exists, so red-then-green is unavailable; the substitute is to break the behavior under test, run the test, watch it fail, and restore. A test never observed failing is **deleted, not kept with a caveat** — it has demonstrated nothing about whether it is connected to the code at all. This is the single gate separating testkit from a file of green assertions, and it is `debugkit`'s on/off toggle run in the other direction: debugkit toggles a cause to move a symptom, testkit toggles a behavior to move a test. |
| What counts as a valid break | **A semantic mutation, never a deletion.** Change a returned value, flip a comparison, drop a branch, skip a write. Deleting the function or the file makes *everything* fail, including a test that asserts nothing, so it proves the import path works and nothing else. The mutation must be the smallest edit that changes the behavior the test claims to check. |
| Cost of the gate | **Run the smallest selection the runner supports — never the full suite.** Apply one mutation, run the target test plus the others in its file, confirm the expected one goes red and its neighbours stay green; that second half is free and catches an over-broad assertion. Full-suite runs happen exactly twice, at the done-gate, and nowhere else. A runner that cannot select a file or a pattern is a real constraint, not an excuse: the declared behaviour count drops and the run states why. The gate is never skipped for slowness — a slow suite is the condition that makes the gate valuable, so an escape hatch here would open in precisely the situation that most tempts an agent through it. |
| Reverting the mutations | **Reverse-apply the recorded diff. Never restore a file.** `git checkout -- <file>` is the reflex and it silently destroys a pre-existing uncommitted edit on the same file. testkit mutates tracked source exactly as debugkit's probes do, so it inherits the identical hazard: take `git stash create` before the first mutation and report the SHA with its recovery line, record every mutation's diff, undo by applying it in reverse, and stop and report on a conflict rather than forcing. These rules are **inlined rather than delegated** — testkit is public and installs alone, and this is the one place a bug in the skill destroys the user's work. |
| Where the expectation comes from | **Outside the implementation, or the test is labeled — and both directions carry a citation.** Source expectations from the docstring, the README, the issue, the type signature, the caller's actual usage, or the domain. When none of those say anything and the only available source is the code itself, the test is a **characterization test** — a change-detector that locks current behavior and makes no claim about correctness. Every test carries a one-line provenance comment either way: `per README: "amounts are cents"` for a specification test, `characterization: no docstring, no issue, no caller assertion` for a lock. **Making both sides cost the same is the entire mechanism.** A free label gets stamped on everything until the distinction means nothing; a label that costs more than the alternative pushes an agent to invent an external expectation to dodge it, which is the exact dishonesty the rule exists to catch. A citation requirement on both sides removes the dodge in both directions. |
| Behavior that contradicts the expectation | **Never fixed, and never encoded.** When the code does something the external expectation says it should not, testkit does not edit the source to match the test, and does not edit the test to match the source. It writes the test asserting the **intended** behavior, marks it skipped or expected-to-fail with a one-line pointer, and reports it. Routes to `debugkit` when nobody knows why, `implementkit` when the fix is obvious. Mirrors debugkit's own refusal to apply a fix, for the same reason: the skill that finds the defect does not also get to decide it was not one. |
| Pre-existing tests | **Reported, never touched.** The premise says a project with no tests; the common case is a project with a handful of stale, mocked-to-death ones. Mutating source hands testkit a free verdict on every one of them, and it uses that verdict for exactly one thing: an existing test that stays green under a mutation is recorded in the ledger as **unproven**, with the mutation that missed it, and routed to the user. The delete rule stays scoped to tests testkit authored **this run**. Deleting somebody else's test on evidence from a mutation aimed at something else is a scope testkit has not earned, and it converts a helpful signal into an unrecoverable one. |
| Untestable code | **Dropped from the slice and reported, never restructured.** testkit does not add a seam, extract an interface, or inject a dependency to make something testable. Code that cannot be tested without restructuring is a **testability blocker**, and it routes to `refactorkit`, whose *untested coupling* pattern is precisely this finding with a proposal attached. testkit's only source mutations are the temporary ones from the failure gate, and every one is reverted. |
| Mocking | **Fake at the process boundary only, and never assert on a call.** Network, clock, randomness, filesystem, third-party service — and only where the real thing is unavailable or nondeterministic. Never fake a collaborator that lives inside the boundary; that is how a test ends up asserting the wiring diagram it was handed. A test whose only assertion is a call count or an argument spy is checking that the implementation is the implementation, and it fails the failure gate honestly only by accident. |
| Coverage percentage | **Reported as a fact when the toolchain already produces one, never as a goal and never as a stopping condition.** The stopping condition is the slice. A number as a target is the most reliable way to manufacture exactly the pile this skill exists to prevent, because every rule above is expensive and a percentage can be reached without any of them. |
| What to test first | **Rank the untested surface, crown one slice.** Signals, in order: churn from `git log --format= --name-only` (refactorkit's one-read trick, which also yields the co-change clusters that define a slice), fan-in (how many modules depend on it), failure cost (money, auth, data loss, migrations, anything irreversible), divided by testability cost. Exclude generated code, vendored trees, thin config, and pure delegation outright — they inflate a count and prove nothing. Crown a **slice**, not a file, because a coherent behavior rarely lives in one. |
| No history to rank on | **Say the prioritization was skipped and rank by structure instead.** A shallow clone or a non-repo is a normal input. refactorkit's precedent: degrade, and never let a coverage claim read as more than it is. |
| Bootstrap | **Inherit the ecosystem's default runner, wire it into the repo's existing script surface, land one green smoke test first.** A project with no tests has no opinion to honor, so the choice least likely to be relitigated is whatever the language's own documentation reaches for. Wire it so the repo's normal entry point works (`npm test`, `make test`, `pytest`), because a suite reachable only by an incantation in a chat log is not a suite. **Ask once before installing a dependency** — a dev dep is a durable change to somebody else's project. When the runner choice is genuinely contested, route to `researchkit` rather than deciding; that is what it is for. **Test-file placement follows the same inherit-the-default rule** — and where an ecosystem carries two live conventions (colocated specs versus a `tests/` tree), follow whatever the repo's existing file layout already implies rather than importing a preference. |
| Bootstrap that fails | **Report what defeated it and stop. Never improvise a harness.** A repo whose language, build system, or dependency situation defeats a standard runner is a real input, and the honest output is the specific obstacle plus a request for direction. A hand-rolled test loop written to get past the blocker is a harness nobody else can run, maintain, or replace, and it would be the most durable thing this skill ever left behind. |
| The e2e tier | **Opt-in, narrow, and conditional on two facts.** It runs only when the app already launches non-interactively and a driver is installed or the user approves installing one. Cap it at a handful of critical-path specs — the sign-in, the one transaction that matters — never a mirror of the UI. |
| The e2e line against `verifykit` | **The seam is who invokes the driver.** `verifykit` opens a browser as a session action and its output is images for a pull request. **testkit never opens a browser as a session action at all** — it authors the spec, and the only thing that ever drives a browser is the repo's own test command executing that spec. The failure gate therefore applies to an e2e spec exactly as it does to a unit test, through the runner, with no exemption for the tier most likely to be written wrong. Stating the seam as *artifact lifetime* was not enough, because both skills legitimately want the same launch command, fixtures, and driver config; stating it as *who calls the driver* survives that overlap. |
| The done-gate | **Green, twice, shuffled, clean.** The new suite passes; every kept test was observed red; the suite runs **twice in a row** and passes both times, in randomized order where the runner supports it; the repo's own build/typecheck still passes; and the source tree carries no leftover mutation. Order dependence is the signature flakiness of a retrofitted suite, because tests written against existing shared state inherit it. Discover the commands from the repo rather than guessing — `implementkit`'s rule, unchanged. |
| Fix on red | **Bounded, then report red.** Roughly three attempts to fix testkit's own output, then stop. Never declare done on a failing gate. implementkit's rule, and it applies with more force here, because the tempting fix is to weaken the assertion. |
| Run size | **`cover` declares its behaviour count before the first test file exists.** "N behaviours in this slice, this run covers M." The agent picks the numbers, but on the record and in advance, and the hand-off reports actual against declared. A run that wants to exceed its declaration stops and says so rather than drifting. This is `debugkit`'s declared-N discipline moved to a different quantity, and for the same reason: the slice alone does not bound anything, three tests and thirty both read as compliant afterwards, and the failure gate's cost scales linearly with a number nobody wrote down. No fixed cap — a number that fits a 200-line utility is wrong for a payments module — and no per-run question, which would make an unattended run impossible. |
| Integration-test environment | **Refuse any target testkit has not verified as disposable, then offer to scaffold one.** A test may only run against localhost, a container testkit or the user started, or an explicitly named test URL. **A value inherited from an ambient `.env` is never sufficient**, however the file is named: a config called *test* is a claim, not a fact, and trusting it is exactly the assumption that destroys somebody's data. Where no disposable target exists, ask **once** to scaffold one and otherwise defer the integration work to the ledger as a blocker. The guard is stated as a refusal rather than a caution because this is testkit's counterpart to debugkit's "never against production or real data", and it is the only rule here whose failure is unrecoverable. |
| Artifact | **One ledger per repo: `docs/tests/testplan-<repo>-YYYY-MM-DD.md`, durable, committable, updated in place forever.** It carries the ranked surface, what each run covered with its date, what was deferred and why, the testability blockers, and the unproven pre-existing tests. **A scope argument narrows what gets ranked, never what gets written** — `/testkit audit src/payments` appends under a scoped heading in the same ledger. One file is what makes run N+1 cheap, and a retrofit that spawns a new dated artifact per slice has no resumable state at all, only a pile of surveys. The creation date in the filename stays fixed. An `audit` finding no meaningful untested surface writes no file and says so — refactorkit's precedent, and what keeps the ranking from manufacturing work. |
| Ledger staleness | **Stamp the ranking's commit, re-rank when the top slice moved.** The ledger carries `ranked against <sha> on <date>`. A `cover` run compares HEAD, and re-ranks when the commits since that sha touched files in the ledger's top slice; otherwise it trusts the ranking **out loud**, naming the sha it trusted. A durable ranking outlives the code it ranked, so an August ordering silently drives a November run straight at whatever used to be hot. Re-ranking every run would be correct and would spend exactly the survey cost the ledger exists to remove. |
| Commits | **Never**, including the artifact. House rule. |
| Tools | `Bash, Read, Grep, Glob, Edit, Write, AskUserQuestion`. `Edit` is present *because* the failure gate mutates tracked source and bootstrap edits `package.json` or its equivalent, which is what makes the revert discipline load-bearing. **No `WebSearch`/`WebFetch`** — the runner choice is a fact about the repo's ecosystem, and a genuinely contested one routes to `researchkit`. |
| Directory group | **Testing & QA** in `skills.sh.json`, alongside `reviewkit`, `qakit`, `verifykit`, and `debugkit`. Widen the group description to name suite-building. |
| Structure | **One `SKILL.md`.** Every skill in the collection is a single file. |

## Approach

**What this reuses.** `refactorkit` supplies the ranking method almost intact — one read of `git log --format= --name-only` yields both the churn order and the co-change clusters — plus the crown-exactly-one discipline, the optional subtree scope, and the rule that an empty result is a real answer that writes no file. `debugkit` supplies three things: the mutation-and-revert ledger wholesale, including the `git stash create` baseline and the ban on file restores; the declared-before-running discipline, moved from a run count to a behaviour count; and the never-against-production posture that the disposable-target refusal is a datastore-shaped restatement of. It also supplies the boundary — the skill that finds the defect does not fix it. `implementkit` supplies the done-gate's discover-from-the-repo rule, the bounded fix-on-red loop, and the red-before-green principle that the failure gate is a brownfield translation of. `qakit` already routes automated testing to "a separate test-suite skill" — testkit is that skill, so the line becomes a real destination instead of a shrug. `AGENTS.md` supplies the artifact naming, the hand-off shape, and the prose register.

**What is genuinely new.** No skill here deliberately breaks working code to validate an assertion. debugkit toggles a suspected cause to see whether a known symptom moves; testkit toggles a known behavior to see whether a new test notices. The direction is inverted and so is the thing being proven, which means the ledger is reused but the gate around it is not.

### Phase 1 — `audit`: rank the surface, crown a slice

The read-only half. One mode, one artifact, no test code.

- Derive the untested surface: what source exists, what tests exist, what the tests actually reach. Prefer the repo's own coverage output when it is already on disk; never generate one, and never install a tool to produce evidence.
- Rank by churn × fan-in × failure cost ÷ testability cost. Exclude generated code, vendored trees, thin config, and pure delegation before ranking, not after.
- Group the top of the ranking into coherent slices along the co-change clusters. Crown exactly one, with runners-up in order.
- Record every testability blocker found, each naming what makes the code unreachable and routing to `refactorkit`.
- Print a coverage line — how many files were ranked, how many were read — in the terminal and in the file. A cap nobody can see reads as completeness.
- Write the repo's single ledger at `docs/tests/testplan-<repo>-YYYY-MM-DD.md`, stamped `ranked against <sha> on <date>`, or write nothing and say so when the critical surface is already covered. A scope argument appends under a scoped heading in that same file.

Acceptance criteria:

- [ ] `audit` writes no test file and edits no source file.
- [ ] The ranking states all four signals for the crowned slice, with evidence for each.
- [ ] Exactly one slice is crowned; runners-up are ordered.
- [ ] Every run prints a coverage line naming what was ranked and what was read.
- [ ] A repo with no git history is ranked by structure, and the run says the prioritization was skipped.
- [ ] An audit finding nothing worth covering writes no file and reports that as a result.
- [ ] A second `audit`, scoped or not, updates the existing ledger and never creates a second file.
- [ ] The ledger carries the sha and date its ranking was computed against.

### Phase 2 — `cover`: bootstrap, then write

The building half, minus the gate that validates it.

**The bootstrap branch**, when no runner exists: pick the ecosystem default, ask once before installing anything, wire it into the repo's existing script surface, and land one green smoke test proving the harness runs before writing a single real test. A retrofit that starts by writing forty tests against an unproven harness debugs the harness through the tests.

**The writing rules**, which are the whole substance of the mode:

- Take the slice from the ledger, from the user, or from an inline ranking when neither exists — and say which. When the ledger's sha has moved and the commits since touched its top slice, re-rank first; otherwise name the sha being trusted.
- **Declare the behaviour count before writing anything.** "N behaviours in this slice, this run covers M." Stop and say so rather than exceeding it.
- Source every expectation from outside the implementation. Where nothing outside speaks, write a characterization test. **Either way the test carries a one-line provenance comment** — the source of the expectation, or the sources checked and found silent.
- Fake only at the process boundary. Assert observable outcomes, never that a call happened.
- **Verify any datastore or service target as disposable before running against it**, and refuse otherwise. Localhost, a container, or an explicit test URL qualifies; an ambient `.env` value never does. Ask once to scaffold a target where none exists, and defer the work as a blocker if the answer is no.
- One behavior per test, named for the behavior rather than the function.
- A contradiction between code and expectation becomes a skipped test asserting the intended behavior, plus a report — never a source edit, never a weakened assertion.
- Untestable code leaves the slice as a blocker and is reported, never restructured.
- Author e2e specs when the tier is in play, and execute them only through the repo's test command. Never open a browser as a session action.

Acceptance criteria:

- [ ] A repo with no runner gets one wired into its existing script surface, with a single green smoke test landing first.
- [ ] A repo where no standard runner can be wired up gets a named obstacle and a stopped run, not an improvised harness.
- [ ] No dependency is installed without asking once.
- [ ] Every test carries a provenance comment — its expectation's source, or the sources checked and found silent.
- [ ] No test asserts a call count or a spy argument as its only assertion.
- [ ] A discovered contradiction produces a skipped intent-asserting test and a report, and no source edit.
- [ ] A testability blocker is reported and routed, and the code is not restructured.
- [ ] `cover` on a repo with no ledger proceeds via an inline ranking and states that it did.
- [ ] `cover` declares its behaviour count before the first test file, and the hand-off reports actual against declared.
- [ ] A run against an unverified datastore target refuses, and offers to scaffold a disposable one exactly once.
- [ ] A target named only by an ambient `.env` value is treated as unverified.
- [ ] `cover` re-ranks when HEAD has moved over the ledger's top slice, and otherwise names the sha it trusted.
- [ ] No e2e spec is executed by opening a browser directly; every one runs through the repo's test command.

### Phase 3 — The failure gate and the revert ledger

The phase that makes the suite mean something, and the only one with a hazard behind it: **the user may have had uncommitted work when the run started**, and reverting a mutation must never revert it.

- Take `git stash create` before the first mutation. Print the SHA and its `git stash apply` recovery line in the hand-off, every run.
- For each behavior under test: apply the smallest semantic mutation that changes it, run **the smallest selection the runner supports** — the target test plus the others in its file, never the whole suite — confirm the expected one goes red **and its neighbours stay green**, then revert. Where the runner cannot select, lower the declared behaviour count and say why.
- Record any **pre-existing** test that stays green under a mutation it should have caught as *unproven* in the ledger, with the mutation that missed it. Never delete or edit it.
- Keep a ledger of every mutation — the file, the diff, the behavior it was testing.
- **Revert by reverse-applying the recorded diff. Never restore a file.** `git checkout -- <file>` is banned outright, with no exception for files that looked clean at baseline, because a ban with exceptions to reason about is not a ban.
- On a reverse-apply conflict, stop the run and report. Do not force, do not fall back to a restore.
- Verify the tree matches the baseline before declaring done. Name by path anything deliberately left in place.
- A test that stays green under its mutation is **deleted**, and the deletion is reported.

Acceptance criteria:

- [ ] Every kept test is recorded as observed red, against a named mutation.
- [ ] A test **testkit wrote this run** that does not go red under its mutation is deleted, and the run says so.
- [ ] A **pre-existing** test that does not go red is recorded as unproven and left untouched.
- [ ] The gate never runs the full suite; it runs the narrowest selection the runner offers.
- [ ] A mutation on a file with pre-existing uncommitted changes reverts the mutation and preserves the user's edit.
- [ ] A reverse-apply conflict stops the run and reports, rather than forcing or restoring.
- [ ] The hand-off states the tree is clean of mutations, or names what remains and where.
- [ ] The hand-off prints the baseline SHA and its recovery line.
- [ ] The skill never reverts, stashes, or discards a change it did not make.
- [ ] The done-gate runs the suite twice, shuffled where supported, and reports both results.

### Phase 4 — Live-test it on a real untested project

The phase that validates the ritual, because the collapses this skill exists to prevent only appear under real pressure. Run the drafted skill against a genuine brownfield project with no tests — a real one if there is one to hand, otherwise a scratch project with real behavior and a planted defect.

Watch specifically for the collapses:

- Tests kept without ever being observed red, because the gate felt slow.
- Mutations that delete rather than change, so everything goes red and the gate reads as passed.
- Expectations read off the implementation and not labeled as characterization — or a provenance comment citing a source that does not say what it claims.
- Every test labeled characterization because the label became free after all.
- The planted defect quietly encoded as the expected value instead of reported.
- Mocks standing in for collaborators inside the boundary, with call-count assertions.
- Mutations left on disk, or reverted with a file restore.
- The declared behaviour count quietly revised upward mid-run, or reported only after the fact.
- A datastore target accepted because a file called it a test config.
- The slice quietly widening until the run is a whole-repo sweep.

Feed the findings back into the earlier phases. Sequential with Phases 1–3 by design.

Acceptance criteria:

- [ ] The skill runs `audit` then `cover` end to end on a real or planted brownfield project.
- [ ] The planted defect is reported as a contradiction, not encoded as the expectation.
- [ ] Every mutation made during the test runs is gone from the tree afterwards, and no pre-existing edit was lost.
- [ ] A second `cover` run reads the artifact and continues rather than re-surveying.
- [ ] The suite passes two consecutive shuffled runs.

### Phase 5 — File it into the collection

Repo integration per `AGENTS.md`. Four files, none touched by the phases above.

- `docs/wiki/skills/testkit.md` — the reader-facing page: summary table, both mode sections as backticked `h3`s, the *why* behind the failure gate and the no-coverage-target rule, the hands-off-to section, the install command, and a provenance stamp that reflects a real read.
- `skills.sh.json` — add to **Testing & QA** and widen that group's description to name suite-building.
- `README.md` — add the skills-table row.
- `IDEAS.md` — delete the `testkit` row on ship, per the file's own graduate rule.

Also in this phase: narrow `debugkit`'s non-goal line and `qakit`'s "separate test-suite skill" line to name `testkit` directly, and check `verifykit`'s "a future testkit" aside.

Acceptance criteria:

- [ ] `make lint` passes with 0 errors and 0 warnings.
- [ ] The wiki page exists, its mode headings match the `SKILL.md`, and it explains rather than restates.
- [ ] `testkit` appears in `skills.sh.json` and the README table, and no longer appears in `IDEAS.md`.
- [ ] The three sibling skills that referenced a future test-suite skill now name `testkit`.

## Open questions

The grill closed all six that were here. These four are genuinely undecidable from a desk, and Phase 4's live test should settle them rather than another round of argument.

- **What a semantic mutation looks like outside imperative code.** "Flip the comparison, change the returned value, drop the branch" assumes a language with a togglable branch. A SQL migration, a declarative config, a template, or a schema definition has behavior worth testing and no obvious smallest-edit-that-changes-it. The gate either needs a per-shape catalogue or an honest statement that it does not apply there.
- **Whether "the tests that should care" can be identified before the tests exist.** The gate confirms the target test goes red and its neighbours stay green, which presumes testkit knows which existing tests touch the mutated line. Without a coverage map — which the plan forbids generating — that is a guess, and a wrong guess makes the neighbours-stay-green half of the gate meaningless.
- **Whether a datastore target can always be verified as disposable.** The refusal in Q3 depends on being able to *tell*. A connection string behind a cloud proxy, a unix socket, or an ORM's resolved config may not reveal its host at all. The rule's fallback — refuse when unverifiable — is correct and may turn out to refuse almost everything in practice, which would quietly collapse the integration tier.
- **Whether the declared count survives a slice that was mis-sized.** The declaration is made after ranking and before writing, at the moment testkit knows least about the slice. A slice that turns out to hold three times the behaviours the ranking suggested forces a stop-and-report on nearly every run, which trains the reader to ignore it.

## Non-goals

- **Fixing anything.** Not the defects the tests reveal, not the untestable code, not a one-liner that is obviously wrong. `debugkit` explains it, `implementkit` fixes it.
- **Refactoring source for testability.** No seams, no extractions, no dependency injection. `refactorkit`'s *untested coupling* pattern owns that finding, and testkit hands it over rather than acting on it.
- **A coverage percentage.** Not as a goal, not as a stopping condition, not in the hand-off as an achievement. Reported as a before-and-after fact only when the toolchain already produces one.
- **Mutation testing as a practice.** The failure gate is a per-test check that the test is connected to the code. It is not a `stryker`/`mutmut` run over the finished suite, and testkit never installs one.
- **Manual QA plans.** `qakit` writes those, for a human to execute. Nothing testkit produces is run by hand.
- **Judging or repairing the tests that were already there.** A pre-existing test that survives a mutation is recorded as unproven and handed back. testkit never deletes, rewrites, or re-labels somebody else's test.
- **Driving a browser as a session action.** `verifykit` does that and captures images for a pull request. testkit authors the spec; only the repo's test command ever opens a browser.
- **Browser proof for a pull request.** `verifykit` drives the app once and captures images. testkit writes specs that run forever.
- **Tests alongside new feature code.** `implementkit`'s TDD mode already owns red-then-green on work that has no code yet. testkit's entire premise is that the code is already there.
- **CI pipeline authoring.** The suite must be runnable by one discoverable command, and the hand-off names it. Writing the workflow file that calls it is a different job.
- **Committing anything**, including its own artifact.
