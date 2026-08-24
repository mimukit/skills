# testkit

Retrofit an automated test suite onto a working codebase that has none — rank the untested surface, crown a slice, stand up a runner, and write tests that were each watched to fail before they were kept.

**Reach for it when** a project you have to keep changing has no tests, and you want a suite that would actually catch a regression rather than a directory full of green checkmarks.

| | |
|---|---|
| Modes | `audit` · `cover` |
| Tools | `Bash`, `Read`, `Grep`, `Glob`, `Edit`, `Write`, `AskUserQuestion` |
| Writes | test files, runner wiring, and one ledger at `docs/tests/testplan-<repo>-YYYY-MM-DD.md` — durable, committable, never committed by the skill |
| Visibility | public |

## The gap it fills

Every kit in the collection that touches tests assumes a suite already exists. [`implementkit`](./implementkit.md) resolves TDD mode by looking for real test infrastructure *plus* a repo habit of shipping tests with features, and covers only new work. [`qakit`](./qakit.md) writes plans a human runs by hand and says outright that automated tests belong to a separate skill. [`debugkit`](./debugkit.md) produces exactly one failing test, as a reproduction. [`reviewkit`](./reviewkit.md) can flag a coverage gap and never closes it. [`refactorkit`](./refactorkit.md) names *untested coupling* as one of its four friction patterns and then proposes a restructure rather than a test.

testkit is the one whose input is **working code that nobody can safely change**. That is a different starting condition from every other build-adjacent kit, and it drives the two rules the skill is really about.

## The failure it exists to prevent

An agent asked to "write tests for this project" reliably produces coverage theater: tests that mirror the implementation line for line, assert that mocks were called, pass on the first run, and pin whatever the code does today — bugs included.

What makes this worth a whole skill rather than a warning is that **the bad output is indistinguishable from the good one**. Same directory layout, same green checkmarks, same coverage badge. You cannot review your way out of it at a glance, and it is worse than no suite at all: it charges maintenance rent forever, catches nothing, and produces a green checkmark that then gets cited as evidence in arguments it cannot support.

So every rule is structural — something the run must *produce* — rather than something it must remember not to do.

## Why a test has to be watched to fail

The defining rule: a test testkit keeps has been observed red.

On new code, red-then-green happens for free — the test is written first, so it fails by construction. On brownfield code that path is closed, and its absence is exactly what lets a disconnected test slip through. A test that asserts nothing, a test wired to the wrong function, a test whose fixture accidentally satisfies it: all three pass on the first run and look identical to a real one.

So testkit manufactures the failure. It breaks the behaviour, runs the test, watches it fail, and restores. This is [`debugkit`](./debugkit.md)'s on/off toggle run in the other direction — debugkit toggles a suspected *cause* to see whether a known symptom moves; testkit toggles a known *behaviour* to see whether a new test notices.

**The break must be a semantic mutation, never a deletion.** Deleting the function makes everything fail, including a test that asserts nothing, so it proves the import path resolves and nothing else. That distinction is the difference between a gate and a ritual.

**The gate has no slowness exemption**, which is deliberate. A slow suite is the condition that makes the gate most valuable, so an escape hatch would open in precisely the situation that most tempts an agent through it. The cost is controlled elsewhere instead: the gate runs the narrowest selection the runner supports — the target test plus its file — and full-suite runs happen exactly twice, at the done-gate.

## Why every test carries a citation

In brownfield code, the implementation is not the specification. A test whose expected value was read off the function it tests is a photograph of current behaviour, and it locks in the bugs alongside the features.

The honest name for that is a **characterization test**, and it is genuinely useful — as a change-detector before a refactor. The problem is telling one from a real specification test after the fact, because they look the same.

Labeling alone does not solve it, and this is the part that took a round of grilling to get right. A label that costs nothing gets stamped on everything until the distinction means nothing. A label that costs *more* than the alternative pushes an agent to invent an external expectation to dodge it — which is the exact dishonesty the rule exists to catch.

So **both directions carry a citation**. A specification test names where its expectation came from (`per README: "amounts are stored in cents"`). A characterization test names the sources it checked and found silent (`characterization: no docstring, no issue, no caller assertion`). Equal cost is the whole mechanism; neither is the cheap way out.

## Why it declares its size before it starts

`cover` states "N behaviours in this slice, this run covers M" before the first test file exists, and reports actual against declared at the end.

Nothing else bounds a run. A slice sounds like a boundary and isn't one — three tests and thirty both read as compliant after the fact, and the failure gate's cost scales linearly with a number nobody wrote down. This is [`debugkit`](./debugkit.md)'s declared-N discipline moved to a different quantity, for the same reason: the honesty comes from the number being on the record *in advance*, not from the number itself.

A fixed cap was rejected because no single value fits both a 200-line utility and a payments module. Asking each run was rejected because it makes an unattended run impossible.

## The refusals

Three things testkit will not do, each of which will feel wrong in the moment.

**It never fixes what it finds.** Retrofitting tests uncovers bugs — that is half the point. When behaviour contradicts the external expectation, testkit writes the test asserting the *intended* behaviour, marks it skipped, and reports it. It does not edit the source to match the test, and it does not edit the test to match the source. A skill that finds a defect and also lands the cure has decided the question before it writes the report.

**It never restructures code to make it testable.** No extracted interface, no injected dependency. Untestable code becomes a *testability blocker* routed to [`refactorkit`](./refactorkit.md), whose untested-coupling pattern is this exact finding with a proposal attached.

**It never touches a pre-existing test.** Mutating source hands testkit a free verdict on every test that was already there, and it uses that verdict for exactly one thing: recording the ones that failed to notice as *unproven* in the ledger. Deleting somebody else's test on evidence from a mutation aimed at something else is a scope the skill has not earned, and it turns a helpful signal into an unrecoverable one. The delete rule stays scoped to tests testkit wrote in that run.

## Why the datastore rule is a refusal, not a caution

Integration tests point at something. Nothing runs against a target testkit has not verified as disposable — localhost, a container, or an explicitly named test URL.

**A value inherited from an ambient `.env` never qualifies, however the file is named.** A config called *test* is a claim, not a fact, and trusting the claim is the assumption that destroys somebody's data. This is testkit's counterpart to debugkit's "never against production or real data", and it is the only rule in the skill whose failure is unrecoverable — which is why it reads as a refusal with a scaffolding offer attached rather than as advice.

## Modes

### `audit`

Read-only. It ranks the untested surface and writes nothing but the ledger — no test file, no source edit.

The ranking uses four signals: churn, fan-in, failure cost, divided by testability cost. One read of `git log --format= --name-only` yields both the churn order and the co-change clusters that define a slice, which is [`refactorkit`](./refactorkit.md)'s trick reused whole — it needs no tool beyond git, and a tool-free signal is one that cannot rot.

It crowns **exactly one** slice, with runners-up in order. Crowning one is the work; a list of five equal-looking candidates is the state you were already in.

Two honesty rules carry over from refactorkit. Every run prints a **coverage line** — "ranked 1,240 files, read the top 40 across 3 slices" — because a cap nobody can see reads as completeness. And an audit that finds no meaningful untested surface **writes no file** and says so, because a survey obliged to produce findings will manufacture them.

### `cover`

Writes the tests. It stands up a runner first when there is none, inheriting the ecosystem's default rather than the most featureful option — a project with no tests has no opinion to honour, so the choice least likely to be relitigated is whatever the language's own docs reach for. One green smoke test lands before anything real, so the harness is proven before forty tests start debugging it.

**When no standard runner can be wired up, the run reports the obstacle and stops.** It never improvises a harness — a hand-rolled test loop is something nobody else can run, maintain, or replace, and it would be the most durable thing the skill ever left behind.

The e2e tier is opt-in, narrow, and capped at a handful of critical-path specs. Its line against [`verifykit`](./verifykit.md) is drawn at **who invokes the driver**: testkit never opens a browser as a session action, and the only thing that ever drives one is the repo's own test command running the spec. Framing the seam as artifact lifetime was not enough, because both skills legitimately want the same launch command, fixtures, and driver config; framing it as who calls the driver survives that overlap.

## The ledger

One file per repository, created once and updated in place forever. A scope argument narrows what gets *ranked*, never what gets *written* — a scoped run appends under a scoped heading in the same file.

That single-file rule is what makes the second session cheap. A brownfield retrofit does not finish in one sitting, and a skill that writes a fresh dated survey per slice leaves a pile of surveys and no resumable state at all.

Because the ledger outlives the code it ranked, it stamps `ranked against <sha> on <date>`. A `cover` run compares HEAD and re-ranks only when the commits since touched the ledger's top slice; otherwise it trusts the ranking **out loud**, naming the sha. Re-ranking every run would be correct and would spend exactly the survey cost the ledger exists to remove.

## Why there is no coverage target

A percentage is reported only as a before-and-after fact, and only when the toolchain already produces one. It is never a goal and never a stopping condition.

Every rule above is expensive, and a coverage number can be reached without any of them. Naming a target is the single most reliable way to manufacture the pile the skill exists to prevent.

## Hands off to

Mostly to **itself**: deferred work stays in the ledger, and the next move after a `cover` run is usually another `cover` run on the next slice.

A contradiction it found routes to [`debugkit`](./debugkit.md) — somebody has to decide whether the behaviour or the expectation is wrong, and testkit deliberately does not. Testability blockers route to [`refactorkit`](./refactorkit.md). When a slice is finished and nothing remains, the move is [`commitkit`](./commitkit.md), or plainly grouping and committing the changes. Every route degrades to a plain action when the named kit is not installed; testkit is useful in a bare repo with nothing but git.

## Install

```sh
npx skills add mimukit/skills -s testkit
```

Source: [`skills/testkit/SKILL.md`](../../../skills/testkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`d2e9d3b` on 2026-08-24._
