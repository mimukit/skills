# designkit

Derive a project's design system from the UI it already ships and keep it true as the code moves — a spec-compliant `DESIGN.md`, validated by the official linter.

**Reach for it when** you want your design system documented from what you actually built, not imported from somewhere else.

| | |
|---|---|
| Modes | [`init`](#init) · [`update`](#update) · [`audit`](#audit) |
| Tools | `Read`, `Write`, `Edit`, `Grep`, `Glob`, `Bash`, `AskUserQuestion` |
| Writes | `DESIGN.md` at the repo root |
| Visibility | public |

## What it does

A design system that lives in someone's head, or in Figma, is invisible to the agent writing the UI. `DESIGN.md` is what the ecosystem converged on instead: an open format from Google Labs pairing machine-readable tokens in YAML front matter with human-readable rationale in prose — deliberately the design counterpart to the agent instruction files coding agents already read.

designkit does the half the ecosystem left empty. Every other tool hands you a design system from *somewhere else* — reverse-engineered from Stripe, or retrieved from a product-type lookup table. **designkit derives yours from the UI you already shipped, and tells you later when it has gone stale.**

## The grounding rule is the whole skill

**Every token must be a value that appears in your codebase.**

Clustering forty near-identical greys into a scale is derivation. Picking a nicer neighbouring hex because it rounds better is invention, and it's the one thing designkit never does.

The rule outranks completeness. A sparse, honest file beats a full, invented one — when the choice is between omitting a scale and guessing at it, it omits and says so.

## Five things it is not

- **Not a UI generator.** It records the system and writes no components. A skill that both defines the taste and applies it can't be held to the grounding rule — that's [`uikit`](./uikit.md)'s job, and uikit never writes `DESIGN.md`.
- **Not a taste library.** No palettes, no font pairings, no style catalog. A project with no design system gets one proposed *from its own values*, or gets told it can't be done.
- **Not a spec implementation.** Linting, contrast checking, token export, and the schema belong to the official CLI. designkit shells out and reports rather than being a second, worse implementation.
- **Not a design critique.** Whether the system is any *good* is a human's call. It reports what's there, including when what's there is a mess.
- **Not the glossary or the decision log.** Those are [`domainkit`](./domainkit.md)'s.

## The CLI is the source of truth

The format is at version `alpha` and openly under active development. Hardcoding the schema into a skill is how the skill becomes confidently wrong, so designkit **reads the spec at run time** and treats its own bundled summary as a dated fallback.

`npx @google/design.md spec` for the current schema, `lint` to validate, `diff` to compare versions, `export` to emit tokens.

**`contrast-ratio` already enforces WCAG AA at 4.5:1** — designkit never writes its own contrast math.

## What never goes in YAML

Verified by running the linter, not inferred from the docs. Two shapes look reasonable and both produce warnings on a file you'd otherwise call clean:

| Tempting | What the linter does | Instead |
|---|---|---|
| a top-level `motion:` token map | ⚠️ `token-like-ignored` — silently dropped by export | prose in `## Motion` |
| `transitionDuration:` on a component | ⚠️ `broken-ref` — not a recognized sub-token | prose in `## Motion` |

The complete set of valid component sub-tokens is `backgroundColor`, `textColor`, `typography`, `rounded`, `padding`, `size`, `height`, `width`. There's no duration, no easing, no border, no gap.

**So motion has no token home anywhere in the schema.** Durations and easing curves are prose, and that's the honest representation until the spec grows a place for them.

What *is* token-legal is **interaction state**, through the related-key pattern: `button-primary`, `button-primary-hover`, `button-primary-active`.

## The extraction engine

One engine, shared by all three modes. `init` writes its output, `update` diffs and applies it, `audit` diffs and reports it. There's no manifest of watched paths to maintain, and therefore no change that goes unnoticed because a glob failed to cover it.

**It derives from usage, not declarations.** A declared token nobody uses is not the design system; forty hardcoded hexes are. So it reads both — every color literal, the font sizes actually applied, the padding that recurs, the interaction states actually styled, the dark-mode variants — and **counts occurrences**. A value used ninety times and a value used once are not equally part of the system, and the counts are what make the result defensible.

Every token then carries one of three states, shown at the consent gate:

| State | Means |
|---|---|
| `extracted` | appears in the code as-is, used enough to be systematic |
| `consolidated` | clustered from N near-duplicates — **listed**, so the merge is reviewable and reversible |
| `omitted` | not derivable; goes in the spec's native `omitted` field, never invented |

**`omitted` is a feature, not a failure.** A DESIGN.md that honestly omits elevation beats one that invents a shadow scale.

## When there's no system

The likeliest real input: hundreds of hardcoded values, no token home, no consistency. designkit **clusters and proposes** — it doesn't refuse, and it doesn't fall through to an interview when the taste is already on screen, just messily.

The proposal stays bound by the grounding rule: cluster near-duplicates, choose the most-used member as representative, list what it absorbs, and **never emit a value the codebase has never contained**. The cluster threshold is a judgment call, so it gets **stated** — an unstated one is unreviewable.

## Show the work

Before writing anything, it emits a **disposable swatch sheet** — a plain HTML page of color chips, type specimens, spacing bars, and radii, each labelled with its token name, state, and absorbed values.

Reviewing "forty greys became six" as a YAML diff isn't realistic. As swatches it takes seconds.

This is **review scaffolding, not a deliverable** — written to a gitignored scratch path, named in the consent ask, and not kept. It's emphatically not the generated UI this skill refuses to write; it's a proof sheet for a decision.

## Modes

### `init`

Ground it with the engine, naming the rung that matched and the counts found, before proposing anything. A repo with no UI at all gets an interview instead, and the result is labeled **proposed, not extracted** in both the report and the file's Overview.

Then the gate that matters: the swatch sheet plus the state breakdown, the cluster threshold, and every inconsistency found. You accept, trim, or redirect **before a file exists**.

Write, stamp, then run `lint` and report its findings **verbatim, including any that remain**. A warning accepted is reported as accepted, never suppressed.

### `update`

Resolve the target — uncommitted changes first, otherwise the branch diff against a base from [`gitkit`](./gitkit.md), never an assumed `main`.

Re-extract, diff against the committed file, and **apply with restraint**. A changed brand color edits the color token; it does not regenerate the file. Which sections are affected *and which are deliberately untouched* get stated **before** editing — the untouched list is the load-bearing half, because it's what shows the skill knew what it was leaving alone.

Edits land directly. **New sections and deletions are consent-gated.** A skill that rewrites a design system because one button changed is worse than no skill.

### `audit`

**Read-only. Writes nothing, ever.**

Three checks: **lint**, reported as-is; **drift**, the check only designkit can do because the linter validates the file against *itself* and has no view of the codebase — tokens in the file that no longer appear in the code, and values in the code no token covers; and **baseline**, diffing against the stamped SHA while it's reachable.

Verdicts are `current`, `stale`, `orphaned`, `uncovered`, or `unverified` — that last one meaning a human-written file designkit has never checked, which is distinct from stale.

Every report opens with a **coverage line**, because an audit that silently covered a fraction of the UI reads exactly like a clean bill of health.

## The stamp

Every file designkit writes ends with a visible line: `_Extracted from `main`@`a1b2c3d` on 2026-08-06._`

Both halves earn their place — `audit` recovers the baseline from the SHA while it's reachable and falls back to the date once a squash-merge has orphaned it. An HTML comment would be invisible in every renderer, which is exactly how a stale file comes to read as current.

**A file with no stamp was written by a human.** It gets adopted and worked with, never silently claimed.

## Degrade loudly

No `npx`, no network, or no CLI is a normal condition. designkit extracts from the fallback schema, skips lint and export, and **names the gap in the same breath as the result**:

> Wrote `DESIGN.md` (12 colors, 6 type styles). `lint` not run — no `npx` available. Schema from the bundled `alpha` fallback captured 2026-08-06.

**Never claim validation that didn't happen.** A file reported clean when nothing checked it is worse than one reported unchecked.

## Hands off to

Read the file — it's a claim about your project's visual identity and the one thing here a human should actually check. Then [`commitkit`](./commitkit.md).

If the project has a token home whose values differ from the file, **token sync** is the follow-up — on consent, and only where a token home already exists. designkit never introduces a token system to a project that doesn't have one; that's a build-tooling decision, not a documentation one.

## Install

```sh
npx skills add mimukit/skills -s designkit
```

Source: [`skills/designkit/SKILL.md`](../../../skills/designkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`fd96414` on 2026-08-07._
