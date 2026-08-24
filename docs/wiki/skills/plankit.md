# plankit

Turn a rough feature or change into a structured plan document, before any code.

**Reach for it when** you have an idea worth thinking through — a feature, a project, a spec, a PRD — and want it grounded and written down before building.

| | |
|---|---|
| Modes | single procedure |
| Tools | `Read`, `Grep`, `Glob`, `Write`, `Edit`, `AskUserQuestion` |
| Writes | `docs/plans/plan-<slug>-YYYY-MM-DD.md` |
| Visibility | public |

## What it does

plankit is generative. It brainstorms the approach, settles the decisions a coherent draft needs, and writes a plan grounded in the real codebase rather than a guess.

It's the front of a flow whose last step depends on the project: **plankit drafts → [`grillkit`](./grillkit.md) hardens → [`issuekit`](./issuekit.md) files** where work is tracked in GitHub Issues, and **plankit drafts → grillkit hardens → [`implementkit`](./implementkit.md) builds** where it isn't. Either way the document it writes is the exact input the next step expects.

That branch used to be missing, and the flow was stated as three fixed steps ending in issuekit. Plenty of teams plan in a repo on GitHub and track their work in Linear, Jira, or a file, and telling them on every run to go file GitHub issues is a confident recommendation built on an assumption nobody checked.

plankit **plans only**: no application code, no issues.

## The distinction that matters

plankit is not the adversarial interrogator. That's [`grillkit`](./grillkit.md).

plankit asks enough to draft something coherent and records the thin spots as **Open questions**. grillkit is what pressure-tests them, one decision at a time. Trying to be both produces a plan that's simultaneously over-interrogated on the easy parts and under-interrogated on the hard ones — so plankit deliberately stops early and leaves grillkit a target.

## How it works

1. **Capture the idea** — the concept, the problem, who it's for, and what success looks like. Scoping questions only: generative "what are we building and why", not adversarial "what did you miss".
2. **Ground it in reality** — read the relevant code, docs, and config to find the patterns and utilities the plan should build on. Facts get looked up, not asked about. Never propose new code where a suitable implementation already exists; name the existing thing instead. Greenfield work skips this and grounds in stated goals.
3. **Diverge** — explore the real options and recommend one.
4. **Converge** — settle the structural decisions a coherent draft needs, then deliberately stop.
5. **Write the document.**

## Options that are actually plural

Step 3 has a specific failure mode, and plankit names it directly: options that only *look* like a choice.

> **Variants (avoid)** — cache the response · cache it with a shorter TTL · cache it behind a flag we can tune later.
>
> One idea in three hats. There's no real decision to make.

> **Distinct (aim for)** — cache the response, smallest diff, ships this week, goes stale on writes · denormalize the read path so there's nothing to cache, a migration but the whole staleness class disappears · don't fix it here at all, it's only slow because it's called in a loop, so batch upstream.

The default spread is a **minimal viable** (smallest diff that ships and is useful), an **ideal** (what you'd choose with time to do it properly), and where one exists a **lateral** (a reframe that dissolves the problem instead of solving it). Each names what it **reuses** from the research, so the plan stays anchored to the code just read.

Collapsing to one approach is fine when the work warrants it. "No credible alternative" beats an invented Option B.

## The plan-doc format

```markdown
# Plan — <title>

## Context
The problem, why it matters now, and the outcome that means success.

## Design decisions (settled)
| Decision | Resolution |

## Approach
The chosen approach and what it reuses, then the body as phases/milestones/tasks.

## Open questions
Thin spots, written as targets for grillkit.

## Non-goals
Explicit scope boundaries.
```

This is a contract, not a suggestion — grillkit and issuekit both read it. The body stays phase/task-shaped so issuekit can decompose it into issues.

A hardened plan carries a **`Grilled: YYYY-MM-DD` line directly under the title**. grillkit writes it when a plan survives a session, and issuekit reads it as the gate for filing issues as `ready`. plankit never writes the stamp itself — a fresh draft is ungrilled by definition.

### The phase-heading annotation slot

A phase heading ends in an optional annotation, and two other kits write into it. plankit writes the bare heading and never annotates one, because a fresh plan has been neither filed nor built.

```markdown
### Phase 2: auth (#41) (built 2026-08-20)
```

`(#41)` is [`issuekit`](./issuekit.md) saying where the phase is tracked. `(built …)` is [`implementkit`](./implementkit.md) saying the phase is done, written after its gate goes green. They coexist.

The slot is documented here because plankit owns the plan-doc format, and issuekit's `(#41)` arguably belonged here all along. It matters most on projects that file no issues: those plans are their own work list, and something has to be able to answer "what's left in this plan?" from the plan alone.

**A plan with no annotation anywhere makes no claim about itself.** Nothing may read its phases as unbuilt. That's what lets the convention arrive with no migration and no backfill — plans written before it stay silent and correct, and a plan starts making claims the first time something stamps it.

## Hands off to

[`grillkit`](./grillkit.md) to pressure-test the draft, which can update the same file in place. Then [`issuekit`](./issuekit.md) to turn the hardened plan into GitHub issues, or [`implementkit`](./implementkit.md) to build straight from it when the project files no issues. It names whichever applies, and both when nothing settles which.

If the planning surfaced project vocabulary worth pinning down or a hard-to-reverse trade-off, it offers [`domainkit`](./domainkit.md) — otherwise, recording a glossary entry or ADR directly.

## Install

```sh
npx skills add mimukit/skills -s plankit
```

Source: [`skills/plankit/SKILL.md`](../../../skills/plankit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`d2e9d3b` on 2026-08-24._
