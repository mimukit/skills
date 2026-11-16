---
name: researchkit
description: >-
  Research the credible options for a technical decision and recommend one (a tool, library, framework, architecture, or service) grounded in primary sources with cited, dated evidence. Use when the user asks "which should I use, A or B", "compare X and Y", "evaluate options for Z", "what's the best tool/library/service for …", "should we use X or Y", "research X before we build", or runs "/researchkit", the decision research that front-runs a plan.
license: MIT
allowed-tools: WebSearch, WebFetch, Read, Grep, Glob, Write, AskUserQuestion
metadata:
  internal: false
---

# researchkit

Never write or run code to settle a claim; log it in Open questions and route a spike to prototypekit.

Research the external landscape only. Reading this codebase for patterns to reuse is planning work.

## Procedure

### 1. Frame the decision
Pin down what's actually being chosen and the constraints that decide it: the stack it plugs into, scale, budget, team familiarity, must-have features, hard constraints. If the ask is a bare one-liner, ask scoping questions first, in one round, only about the constraints the ask leaves open.

**Done when** the decision is one sentence and every deciding constraint has a value or an explicit "does not matter".

### 2. Find the credible options
Enumerate the real contenders, the ones a knowledgeable engineer would weigh. If only one option survives the constraints, say so and write a cited explainer of that option instead of a comparison.

**Done when** every option that meets the hard constraints and that a knowledgeable engineer would weigh is on the list, and each well-known option left off carries a one-line reason.

### 3. Investigate against primary sources
Read the **authoritative** origin for each load-bearing claim (official docs, the source, the spec, the first-party API, a maintainer-published benchmark) over secondary interpretation. For every source, note its **version and date**, and flag when the evidence may be stale (a benchmark from an old major version, a doc that predates a rewrite).

**Refresh a source before you rely on it** when any of these holds: it describes a version older than the option's current release line; it predates the option's latest major release or a rewrite; it is more than 12 months old in a fast-moving area (frameworks, hosted services, AI tooling); or you are updating a saved research artifact, in which case re-fetch every load-bearing source in it. A source with no newer replacement stays in, marked ⚠ stale with its date.

**No web access?** Say so plainly, then give a best-effort comparison from knowledge under the **Provisional comparison** heading of the [artifact format](#artifact-format), and **never fabricate a citation**.

**A claim the sources won't settle** (a performance number for your exact workload, whether two libraries actually interop, whether an API does what its docs imply) stays unverified. Carry it into Open questions with what a measurement would need to show.

**Done when** every load-bearing claim in the comparison has a source with its version and date, or sits in Open questions as unverified.

### 4. Compare
Lay the options against the constraints that matter (from [Frame the decision](#1-frame-the-decision)), not a generic feature grid.

**Done when** every row of the comparison holds a value for every constraint axis, and each value either cites its source or is marked unverified.

### 5. Recommend
Pick one. Give a one-line why, and state the condition under which you'd pick differently ("Drizzle, for its lighter runtime and no codegen; choose Prisma if you need its migration tooling and admin GUI"). When any load-bearing claim behind the pick is unverified or comes from recall, label the recommendation **provisional** and name the claim.

### 6. Hand off

_Write this section in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

**What changed.** Print the recommendation. Then ask once whether to save it. On yes, write the artifact to `docs/research/NNNN-research-<slug>-YYYY-MM-DD.md`, using the next serial, a short lowercase kebab-case subject slug, and the artifact's ISO creation date (for example, `0003-research-auth-providers-2026-07-23.md`). To get the serial `NNNN`, take the highest leading four-digit serial in `docs/research/` in this checkout and in every other worktree of the repo, and add one; start at `0001` when there is none. This skill has no shell, so find the worktrees with Read and Glob: in a linked worktree, `.git` is a file that names `<main>/.git/worktrees/<name>`; `<main>` is the main checkout, and each `<main>/.git/worktrees/*/gitdir` holds another worktree's path. Scan them all, because parallel worktrees otherwise take the same serial. The serial is per directory and never reused. Keep the whole name stable on later edits and update the same artifact in place. Follow any established research/notes/RFC location or naming scheme the repository already uses.

**Where it landed.** Give the file path, or say the report is in the chat only.

**Next.** Crown one move, and start none of them:

- **A load-bearing open question needs a measurement** → spike it with **prototypekit** when installed, otherwise a throwaway test the user asks for by name. The pick waits on that answer.
- **Otherwise** → turn the chosen direction into a plan with **plankit** when installed, otherwise write the plan directly. The open questions carry into the plan.

## Artifact format

Print inline by default; write to a file only when asked. Either way, the shape:

```markdown
# Research: <the question>

## Recommendation
<the pick>: <one-line why>. Choose <alternative> instead if <condition>.

## Options compared
| Option | <constraint A> | <constraint B> | Fit |
|--------|----------------|----------------|-----|
| ...    | ...            | ...            | ... |

## Evidence (primary sources)
- <load-bearing claim> → <source URL> (<version/date>), ⚠ note if stale
- ...

## Provisional comparison (from recall, not verified)
- <claim> (as of <your knowledge cutoff>)

## Open questions
Unresolved or thin spots to settle when planning, including any claim that needs a measurement, with what the measurement would show.
```

**Evidence holds only claims you fetched in this run.** A claim from recall goes under **Provisional comparison**, never under Evidence. Drop the Provisional section when every claim is sourced; drop Evidence when there was no web access.

Scale it to the decision. A two-way library pick is a short block; an architecture choice earns more. Drop any section that would be filler.

## Notes

- **No filesystem or shell** (e.g. a browser-based agent)? Skip the save-to-file offer.
