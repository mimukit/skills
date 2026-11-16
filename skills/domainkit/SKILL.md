---
name: domainkit
description: >-
  Maintain a project's domain model as a consented record of settled understanding: the CONTEXT.md overview and glossary of the ubiquitous language, and docs/adr/ decision records. Use when a domain term needs pinning down, when a hard-to-reverse trade-off decision gets settled, when the user says "update the glossary" or "write an ADR", or when another skill needs the domain model kept current; when the user says "set up CONTEXT.md" or "write the project overview"; or when the user asks "is CONTEXT.md still accurate" or says "audit the glossary".
license: MIT
allowed-tools: Read, Write, Edit, Grep, Glob, AskUserQuestion, Bash(git log:*)
metadata:
  internal: false
---

# domainkit

domainkit keeps `CONTEXT.md` and `docs/adr/` current: detect the moment, offer the entry, write on consent.

## When this fires

Route to one of three modes:

- **`record`**, the default. A **domain term** needs pinning down, because it's vague, overloaded, or two words are being used for one concept. Or a **decision** gets settled that meets the [ADR bar](#the-adr-decision-record-format). Also on an explicit ask to record a term or a decision, and when another skill needs the domain model kept current.
- **`init`.** The user asks to seed the domain model. It reads the repo, interviews the owner once, and proposes a whole `CONTEXT.md`.
- **`audit`.** The user asks whether the model still holds. statuskit routes here when `CONTEXT.md` has fallen behind the code.

**A model-fired run always routes to `record`.** `init` and `audit` run only when the user asks for them.

## Consent (every mode)

Every write is **consent-gated**: domainkit writes only after an explicit yes. `record` offers each entry on its own. `init` and `audit` show the whole proposed change, the full file or the full diff, and write it once on one yes.

## The modes

The mode bodies live in one file each under `modes/`. Route with [When this fires](#when-this-fires), read that one file, and follow it. Everything in this file applies to every mode and is not restated in the mode files.

- Mode `record` → read [modes/record.md](modes/record.md), then follow it.
- Mode `init` → read [modes/init.md](modes/init.md), then follow it.
- Mode `audit` → read [modes/audit.md](modes/audit.md), then follow it.

## The CONTEXT.md format

`CONTEXT.md` is the single source of truth for **what the product is and what its words mean**: a short overview, then a Domain-Driven-Design ubiquitous language.

```markdown
# <Context name>

<1–2 sentence description of this context.>

## Overview

### What it is
<3 lines or fewer.>

### Who it is for
<3 lines or fewer.>

### The problem it solves
<3 lines or fewer.>

### Core capabilities
- <7 bullets or fewer, one capability each>

### Non-goals
- <3 lines or fewer: what the product deliberately does not do>

## <Optional grouping subheading>

### <Term>
<Tight definition. What it *is*, in 1–2 sentences.>
_Avoid: <synonym to reject>, <another>_
```

**The overview.** It gives the glossary its frame and fits on one screen.

- **Five parts, in this order.** What it is, Who it is for, The problem it solves, Core capabilities, Non-goals. Each part is 3 lines or fewer, and Core capabilities is 7 bullets or fewer.
- **What it is is required.** Any other part may be left out when the owner says it does not matter.
- **Purpose and audience, never usage.** The overview states why the product exists and for whom. It never repeats install or usage text from the README; link the README instead.
- **Optional for an existing file.** A `CONTEXT.md` with no overview stays valid. `init` offers to add one, and nothing flags a file only because it lacks one.

**The glossary.** Every `##` section other than `## Overview` holds terms.

- **Content allowed.** Terms specific to *this* project's domain; concepts unique to the work.
- **Content forbidden.** General programming concepts (timeouts, error types, utility patterns), however heavily used. If it isn't domain-specific, it doesn't belong here.
- **Definition style.** Define *what a term is*, not what it does; one or two sentences.
- **Be opinionated.** When multiple words exist for one concept, choose the best and push the others to `_Avoid_`.
- **No size cap.** A glossary grows with the domain; never evict a real term to hit a length target.

**The content rule: overview and glossary only.** No status, stage, roadmap, or metrics, because those go stale and live in the tracker. No decisions, because those are ADRs; a term may link the ADR that shaped it. No install or usage steps, because those are the README.

**Multiple contexts.** When bounded contexts clearly diverge, keep a `CONTEXT-MAP.md` at the repo root listing each context, where its file lives, and the relationships between them; split lazily, only once one file stops making sense. In a multi-context project the `## Overview` block lives in `CONTEXT-MAP.md`, above the context list, because it describes the whole product. Each per-context `CONTEXT.md` keeps its 1–2 sentence description and its glossary, with no overview of its own.

## The ADR decision record format

ADRs live in `docs/adr/` and use `NNNN-adr-<slug>-YYYY-MM-DD.md`, numbered sequentially with zero-padding: `0001-adr-use-postgres-2026-07-23.md`, `0002-adr-adopt-event-log-2026-07-24.md`, … The number leads so a listing reads in decision order, matching the serial every other `docs/` artifact carries. The number is the authoritative decision order and the ISO suffix is the creation date; never rename an ADR merely because its status changes later. A repo whose ADRs still use the older `adr-NNNN-<slug>-YYYY-MM-DD.md` shape keeps its numbers; write the new ADR in the new shape, and point the user at repokit's `docs` mode (when installed) to rename the older ones. Create the directory only when the first ADR is needed. Parallel branches may claim the same number; when that happens, renumber the later ADR during merge and update any references to it, including `Status` lines that name it.

```markdown
# NNNN: <Title>

<1–3 sentences: what the context was, what was decided, and why.>

## Status
proposed | accepted | accepted, supersedes ADR-NNNN | deprecated | superseded by ADR-NNNN

## Considered Options
- <rejected alternative worth remembering, and why it lost>

## Consequences
- <non-obvious downstream effect>
```

Title, the context/decision/why paragraph, and `Status` make a complete ADR. `Status` is **required** on every new record, because supersession has to flip it. `Considered Options` and `Consequences` are **optional**; include one only when it adds value. A record that supersedes others says so in its own `Status` line: `accepted, supersedes ADR-NNNN`.

**Write an ADR only when all three hold:**

1. **Hard to reverse.** Changing course later carries real cost.
2. **Surprising without context.** A future reader will question the approach from the code alone.
3. **A genuine trade-off.** Real alternatives existed and were weighed.

## Notes

- **Bias toward the high bar.** Fire on a conflicting term or an irreversible decision, not on every noun; when in doubt, stay quiet.
- **No filesystem or shell** (e.g. a browser-based agent)? Print the proposed glossary entry, ADR, or whole `CONTEXT.md` as a codeblock for the user to save, and skip the file write. With no `git log`, `audit` compares against the current tree only. Everything else is unchanged.