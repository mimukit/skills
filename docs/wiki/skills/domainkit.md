# domainkit

Maintain a project's domain model as a consented byproduct of design work — a `CONTEXT.md` glossary and `docs/adr/` decision records.

**Reach for it when** a term needs pinning down, a hard-to-reverse decision gets settled, or another skill needs the domain model kept current.

| | |
|---|---|
| Modes | single procedure, consent-gated |
| Tools | `Read`, `Write`, `Edit`, `Grep`, `Glob` |
| Writes | `CONTEXT.md`, `docs/adr/adr-NNNN-<slug>-YYYY-MM-DD.md` |
| Visibility | public |

## What it does

domainkit is the **scribe** of two living artifacts: `CONTEXT.md`, a glossary of the project's ubiquitous language, and `docs/adr/`, the log of architectural decisions and why they were made.

Its loop is narrow on purpose — **detect the moment, offer to record it, write on consent** — so vocabulary and the reasoning behind hard choices stay pinned down without anyone remembering to do it.

It runs primarily as a **byproduct of design work**. While a decision is being grilled, a plan drafted, or code written, a term crystallizes or a decision lands. That's when it fires.

## Two things it is not

- **Not the interrogator.** Challenging a term, inventing edge cases, stress-testing whether a decision holds — that's [`grillkit`](./grillkit.md). domainkit records the *settled* understanding. A term still genuinely unresolved gets routed, not written down as a guess.
- **Not a status tracker.** There is no `status.md` and no "current state" file. Project status is ambient: issues track what's planned, git and session history track what happened, [`handoffkit`](./handoffkit.md) compacts state on demand. domainkit persists only what those *can't* recover — the vocabulary, and the reasoning behind irreversible choices.

## Consent holds even when auto-fired

Every write is gated. Being model-invoked never means writing unprompted; the offer always comes first, and a misfire costs one dismissible offer rather than a spurious file.

The bias runs toward the high bar. Better to fire on a genuinely conflicting term or a genuinely irreversible decision than to nag on every noun — when in doubt, it stays quiet.

## How it works

1. **Detect the moment** — a term used loosely or inconsistently, or a settled decision clearing the ADR bar. This surfaces mid-grill, mid-plan, mid-implementation; it doesn't wait to be called.
2. **Locate the artifacts** — read the repo-root `CONTEXT.md` (or `CONTEXT-MAP.md` → the right context file). For an ADR, scan `docs/adr/adr-*.md` and take the highest number.
3. **Offer** the proposed entry, tight enough to accept or redirect at a glance.
4. **Write on consent.**
5. **Defer when unsettled** — route to grillkit rather than manufacturing certainty.

## `CONTEXT.md` — the glossary

The single source of truth for **what words mean** here. A Domain-Driven-Design ubiquitous language, not a spec and not a status file.

```markdown
# <Context name>

<1–2 sentence description of this context.>

### <Term>
<Tight definition — what it *is*, in 1–2 sentences.>
_Avoid: <synonym to reject>, <another>_
```

- **Allowed** — terms specific to *this* project's domain.
- **Forbidden** — general programming concepts (timeouts, error types, utility patterns), however heavily used. Not domain-specific means it doesn't belong.
- **Define what a term is**, not what it does.
- **Be opinionated.** When several words compete for one concept, pick one canonical term and push the rest under `_Avoid_`.
- **No size cap.** A glossary grows with the domain; a real term is never evicted to hit a length target.
- **Multiple contexts** get a `CONTEXT-MAP.md` at the root, but split lazily — only once one file stops making sense.

## The ADR bar

An ADR gets written only when **all three** hold:

1. **Hard to reverse** — changing course later carries real cost.
2. **Surprising without context** — a future reader will question the approach from the code alone.
3. **A genuine trade-off** — real alternatives existed and were weighed.

Typical qualifiers: architectural structure, integration approaches between contexts, technology choices with high switching cost, boundary definitions, deliberate deviations from convention, constraints invisible in code, and non-obvious rejections of an alternative.

```markdown
# NNNN — <Title>

<1–3 sentences: the context, what was decided, and why.>

## Status
proposed | accepted | deprecated | superseded by ADR-NNNN

## Considered Options
- <rejected alternative worth remembering, and why it lost>

## Consequences
- <non-obvious downstream effect>
```

A single paragraph is already a valid ADR. The three sections are **optional** — included only when they add value.

Files are `adr-NNNN-<slug>-YYYY-MM-DD.md`, zero-padded and sequential. The number is the authoritative decision order; the date is creation. An ADR is **never renamed** because its status changed later.

**ADR content is immutable once shipped.** `Status` is the one mutable field, so a later ADR can mark an old record `deprecated` or `superseded by ADR-NNNN`. Parallel branches may claim the same number — the later one gets renumbered during merge.

## Hands off to

Normally, back to whatever it interrupted. domainkit usually fires *inside* someone else's work, so a long report is an interruption on top of an interruption — it names the grill, plan, or implementation it fired inside and hands straight back.

Two things outrank that: a new ADR superseding an older one leaves the old `Status` stale, so it offers that flip; a term that turned out contested isn't settled at all, so it routes to [`grillkit`](./grillkit.md).

## Install

```sh
npx skills add mimukit/skills -s domainkit
```

Source: [`skills/domainkit/SKILL.md`](../../../skills/domainkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`d2e9d3b` on 2026-08-24._
