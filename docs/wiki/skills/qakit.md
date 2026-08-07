# qakit

Generate a step-by-step manual QA plan for a feature just implemented, grounded in the actual code changes.

**Reach for it when** a coding session wraps and you want to hand-test the result.

| | |
|---|---|
| Modes | single procedure |
| Tools | `Read`, `Bash`, `Write` |
| Writes | `docs/qa/qa-<feature-slug>-YYYY-MM-DD.md` |
| Visibility | public |

## What it does

qakit turns a feature an agent just implemented into a **manual QA plan a human can actually run** — concrete steps, expected results, and pass/fail boxes, grounded in what the code changed rather than a generic checklist.

The key word is manual. These are steps that genuinely need a human to perform and judge: click through a flow, read a screen, feel out the UX.

## The split that makes it useful

Anything an agent or script can confirm on its own — running a command and reading output, hitting an endpoint, asserting a return value — does **not** belong in the human's checklist.

qakit runs those itself and records the outcomes in an **Automated verification** section at the end of the plan. The human sees them confirmed without re-running them by hand.

So as cases are generated, each gets sorted: does confirming this *require a human*, or can a script do it? Only the human-only cases become numbered test cases.

## The dimensions

Every dimension gets walked, and one that's genuinely irrelevant gets **said to be skipped** in the plan — so the tester knows it was considered, not forgotten:

Happy path · edge and boundary · negative and error handling · regression · security and permissions · data and state · concurrency and timing · compatibility · accessibility · performance · usability.

Each case is tagged with a tier carrying an emoji, so urgency reads at a glance:

- 🔴 **Critical** — must pass to ship; a failure blocks release.
- 🟡 **Normal** — a real bug, but not a blocker.
- 🟢 **Low** — polish or minor-impact edges.

It doesn't pad. One clear case per behavior beats ten redundant ones, and the count scales to the feature's surface area and risk.

## Two commands it will never run

Both rules have the same shape: **inspect what exists, don't reproduce it.**

- **Anything that destroys or rebuilds state** — a `*:reset`, a teardown-and-rescaffold, a database drop, a `clean` that wipes a build. It gets described for the human in Preconditions, never executed. qakit is writing a plan *about* an environment, not administering one, and a QA agent that resets state can wipe the very build the human was about to test.
- **A gate a prior step this session already ran green** — the test, build, or lint chain that just passed. Re-running produces the same answer at full price, and it's the most common way this step becomes the most expensive one in a pipeline. It re-runs only if the change under test *is* that gate, or if something modified the tree since.

## Rules for a good case

- **Concrete and reproducible** — real values and exact steps. Not "test the login" but "enter `bad@example.com` / blank password, click Sign in".
- **One behavior per case**, so a failure points at exactly one thing.
- **Observable expected result** — what the tester sees or measures, not internal state they can't check.
- **Expected results as bullets**, never a paragraph, so they get ticked off one at a time.
- **Every command gets its own `sh` block** — never inlined in prose or a table cell, never stacked. The tester copies each one with a single click. Commands that must run together chain with `&&` inside one block.
- **Every API endpoint gets a runnable `curl`** — method, full URL, every required header, and a concrete JSON body with real sample values. Copy-paste ready, no placeholders to guess at. This is the single biggest speedup in a QA pass: the tester runs the request instead of reconstructing it.
- **Honest about gaps** — what the plan can't verify goes under *Not covered*, rather than pretending coverage.

## The plan shape

```markdown
# QA Plan: <Feature name>

## Summary            — what it does, what "working" means
## Preconditions      — environment, seed data, credentials, flags, launch command
## Test cases at a glance   — a table with priorities
## Test cases         — TC-N, steps, expected bullets, Actual, Pass/Fail boxes
## Regression checks
## Automated verification (by AI agent)
## Not covered / needs human judgment
```

## Hands off to

The human, to run the plan in a fresh checkout. qakit reports how many manual cases (and how many 🔴 critical) plus the automated result.

It never marks a *manual* case as passed — those are yours to execute. The agent only fills the Automated verification section.

If what you actually want is automated tests, qakit says so and stops rather than producing a manual plan for it.

## Install

```sh
npx skills add mimukit/skills -s qakit
```

Source: [`skills/qakit/SKILL.md`](../../../skills/qakit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`fd96414` on 2026-08-07._
