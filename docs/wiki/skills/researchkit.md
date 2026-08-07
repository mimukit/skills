# researchkit

Research the credible options for a technical decision and recommend one, grounded in primary sources with cited, dated evidence.

**Reach for it when** you're choosing between tools, libraries, frameworks, architectures, or services and the answer isn't obvious.

| | |
|---|---|
| Modes | single procedure |
| Tools | `WebSearch`, `WebFetch`, `Read`, `Grep`, `Glob`, `Write`, `AskUserQuestion` |
| Writes | inline by default; `docs/research/research-<slug>-YYYY-MM-DD.md` on request |
| Visibility | public |

## What it does

researchkit enumerates the credible options, investigates each against **primary sources** — official docs, source code, specs, first-party APIs, maintainer benchmarks, not blog hearsay — compares them on the constraints that actually matter, and picks one with a cited, dated rationale.

It's decision research. The goal is a choice you can act on, not a neutral pile of notes.

It front-runs planning: answer "Drizzle or Prisma?", "which queue for this workload?", "REST or gRPC here?" first, then turn the chosen direction into a plan with [`plankit`](./plankit.md).

## Never build to find out

This is the boundary users most often see crossed, and crossing it is always a bug — so it's worth stating plainly.

researchkit **never writes, runs, or scaffolds code to test a hypothesis.** No spike, no prototype, no benchmark harness, no throwaway repo, no `npm install` to see what happens. Not even a quick one.

The failure mode is specific, and it feels helpful from the inside: research turns up a claim the docs don't settle, building a small test looks like the fastest way to settle it, and twenty minutes later you're reading about a prototype you never asked for. You asked which option to pick. An implementation answers a question you didn't ask, spends your time and tokens without consent, and buries the comparison you wanted.

So an unsettleable claim gets surfaced in **Open questions** — "settling this needs a spike: *what it would measure*" — and researchkit stops. Building one is a separate, explicitly requested job: [`prototypekit`](./prototypekit.md)'s when it's installed, and otherwise a throwaway you ask for by name. It is never researchkit's — and it is not the build step's either. [`implementkit`](./implementkit.md) needs a settled intent and ships production code, which is the wrong shape entirely for answering a question you're still holding open.

`allowed-tools` deliberately withholds shell and file-editing tools, so a host that honors the field *can't* run a spike even if the model talks itself into wanting one. The prose is the real rule; the tool list is the backstop.

## Three things it isn't

- **Not a neutral note-taker.** It always ends in a recommendation. If only one credible option survives, it degrades to a **cited explainer** of that option rather than dumping opinion-free notes.
- **Not repo grounding.** Reading *your* codebase to reuse existing patterns is planning work. researchkit investigates the *external* landscape.
- **Not implementation.** See above.

## How it works

1. **Frame the decision** — what's actually being chosen, and the constraints that decide it: the stack it plugs into, scale, budget, team familiarity, must-haves, hard limits. Constraints are what turn a generic comparison into a real recommendation.
2. **Find the credible options** — the ones a knowledgeable engineer would actually weigh. No strawmen padding the field to look thorough.
3. **Investigate against primary sources** — read the authoritative origin for each load-bearing claim. Every source carries its **version and date**, with staleness flagged (a benchmark from an old major, a doc that predates a rewrite).
4. **Compare** on the constraints that matter, not a generic feature grid.
5. **Recommend** — pick one, give a one-line why, and state the condition under which you'd pick differently.

## The artifact

```markdown
# Research — <the question>

## Recommendation
<the pick> — <one-line why>. Choose <alternative> instead if <condition>.

## Options compared
| Option | <constraint A> | <constraint B> | Fit |

## Evidence (primary sources)
- <claim> → <source URL> (<version/date>) — ⚠ note if stale

## Open questions
Including any claim that would need a spike — named, not acted on. Those hand off to prototypekit.
```

Scaled to the decision: a two-way library pick is a short block, an architecture choice earns more.

A recommendation reads "Drizzle — lighter runtime, no codegen; choose Prisma if you need its migration tooling and admin GUI." Something to accept, reject, or redirect — not a shrug.

## When there's no web access

It says so plainly, gives a best-effort comparison from knowledge with an explicit staleness warning, and **never fabricates a citation**. A missing source is stated as missing, not invented. Evidence over recall is the whole reason this beats asking a model directly — a recommendation with no traceable evidence is a guess wearing a table.

## Hands off to

[`plankit`](./plankit.md), to turn the chosen direction into a plan. Leftover uncertainties become the open questions plankit and [`grillkit`](./grillkit.md) pick up.

An open question that needs *evidence* rather than more argument goes to [`prototypekit`](./prototypekit.md) instead. Grilling sharpens a decision someone has already made; it can't settle a claim nobody has watched run.

It also offers to save the report, but inline is the default — a durable file only when you want one.

## Install

```sh
npx skills add mimukit/skills -s researchkit
```

Source: [`skills/researchkit/SKILL.md`](../../../skills/researchkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`c9d55aa` on 2026-08-07._
