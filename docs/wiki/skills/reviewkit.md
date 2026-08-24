# reviewkit

Review AI-agent-implemented code specifically — four ordered passes, findings ranked by severity and backed by quoted evidence.

**Reach for it when** an agent has just finished a chunk of work and you want it judged before it ships.

| | |
|---|---|
| Modes | four ordered passes over one reading |
| Tools | `Read`, `Bash`, `Grep`, `Glob`, `Write`, `Task`, `Agent`, `Skill` |
| Writes | nothing by default; optional report to `docs/reviews/` |
| Visibility | public |

## What it does

A generic "find bugs" pass misses the three things agents get wrong most: writing code that is *correct in a vacuum but wrong for this repo*, padding a change with *plausible-looking cruft nobody asked for*, and quietly *leaving part of the job undone*.

reviewkit runs those three checks **first**, then a correctness pass. It is a **reviewer, not an editor** — it reads and judges, and never edits source.

## Review with fresh eyes

This is the design's sharpest point, and worth understanding before you trust a report.

reviewkit usually fires in the same session that just produced the code. That means the reviewer arrives carrying every rationalization it made while writing — the shortcut it already justified, the edge case it already decided didn't matter. **That is the single biggest way this review turns into a rubber stamp.**

So when a subagent tool exists, the passes get **delegated to a fresh subagent** with no memory of the implementation session. Without one, the passes run in-session but the report says plainly that it was a **self-review**, so you know how much weight the verdict carries.

It never quietly self-reviews a change it just wrote.

## Picking the target

| State | Target |
|---|---|
| Uncommitted changes present | the working tree — `git diff HEAD` plus staged |
| Clean tree, branch ahead of base | the branch diff, with the base from [`gitkit`](./gitkit.md) |
| Invocation names a target | that, detection skipped |

Two failure modes get explicit guards:

**`git diff` does not show untracked files.** A brand-new file an agent never staged is invisible to it, and a whole new module silently escaping review is the worst possible miss. Untracked source files are listed and read **in full, no exceptions** — only genuinely generated files (lockfiles, build output, vendored deps) get skipped, and even those get spot-checked for hand edits.

**A wrong base silently yields an empty diff or half the repo's history**, and both look like a real review target. So the base comes from gitkit rather than an assumption, and the range is validated as non-empty before anything is judged.

The diff is read **once**. The four passes are four questions asked of one reading, not four readings.

## Ground rules for every pass

- **Skip what tooling already enforces.** Formatting, import order, lint rules — CI catches those. The whole value of this review is what machines *miss*.
- **Every finding needs evidence.** A quote of the offending hunk and what it violates: a line of a convention doc, the stated intent, a real API signature, the concrete failing input. A finding you can't back with a quote is a guess.
- **Hold each finding to a confidence bar.** Confirmed by code, reproduction, or a test run — or strongly supported with no credible innocent explanation. Anything weaker is an **unverified area**, not a finding. Downgrading a hunch to "unverified" is a real result; dressing it up as a bug burns trust in the whole report.
- **Track what you could not judge.** Silence reads as "clean," so an unexamined area gets named.

## The four passes

### Pass 1 — Convention-fit

Does the change look like the rest of *this* repository wrote it? Agents default to generically-correct code that ignores local idiom, so the surrounding code is the spec.

Naming and structure against sibling files · established patterns the change reinvents instead of reusing · idiom the linter doesn't catch · dependencies added for something the repo already solves · documented repo rules, which always override abstract best practice.

Fowler's vocabulary shows up here: *Mysterious Name*, *Shotgun Surgery*, *Divergent Change*.

### Pass 2 — Agent-slop signatures

The padding that looks productive but earns its keep nowhere.

Over-engineering (abstraction for a single caller, config knobs nothing sets) · dead and unreachable code · **hallucinated or wrong APIs**, verified against the actual dependency rather than the model's guess · redundant comments that restate the code · scope creep the stated intent doesn't justify · fake robustness — try/catch that swallows errors, tests that assert nothing.

*Speculative Generality* is the signature agent smell.

### Pass 3 — Requirement-completeness

Agents under-deliver as often as they over-deliver. Measured against the change's captured intent: missing requirements, partial implementation (happy path only, interface without behavior), stubs and placeholders presented as done, and wrong interpretation — where the change solved a nearby, easier problem.

With no captured intent to measure against, this pass is **skipped and said to be skipped**, rather than inventing a spec.

### Pass 4 — Correctness

The classic review, on what survives: logic errors, edge cases, state and concurrency, security, and tests.

**A passing test suite is not evidence of a tested change.** Agents write tests that pass because they assert nothing that could fail. So each new test faces: *would it fail against a broken implementation?* — mentally invert the logic; if it still passes, it's decoration. Does it assert observable behavior, or re-implement production logic in the assertion and compare the code to itself? Is the scenario visible, or buried in mocks so thoroughly the test proves the mock works?

## The verdict is mechanical

Findings are tagged 🔴 **Blocker**, 🟡 **Should-fix**, or 🟢 **Nit**, each with a `file:line`, which pass caught it, the quoted evidence, one sentence of what's wrong, and the concrete fix.

The verdict follows from the findings rather than a vibe:

| Verdict | Means |
|---|---|
| `needs-work` | one or more 🔴 Blockers |
| `ready-with-fixes` | no Blockers, at least one 🟡 |
| `ready` | nothing above 🟢 Nits |

Never softened because the change is mostly good, never hardened to look rigorous.

Every report closes with a **coverage note** naming what wasn't verified, whether tests ran, and whether this was fresh-eyes or self-review. When a gap is serious enough to hide a real problem — an unreviewed security boundary, a migration nobody can validate here — the change is called **blocked on outside review** rather than given a verdict the evidence doesn't support.

An empty report on a clean diff is the honest outcome. It never invents findings to look thorough.

## Hands off to

[`implementkit`](./implementkit.md) as a **fix round** — the findings name the defects, so there's no design to invent, and implementkit applies them directly. Or fix by hand and re-run.

reviewkit never applies its own fixes; that's your call.

## Install

```sh
npx skills add mimukit/skills -s reviewkit
```

Source: [`skills/reviewkit/SKILL.md`](../../../skills/reviewkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`d2e9d3b` on 2026-08-24._
