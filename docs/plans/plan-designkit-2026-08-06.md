# Plan — designkit

Grilled: 2026-08-06

## Context

A design system that lives in someone's head, or in Figma, is invisible to the agent writing the UI. `DESIGN.md` is the answer the ecosystem converged on: Google Labs published it under Apache-2.0 at [`google-labs-code/design.md`](https://github.com/google-labs-code/design.md), detached from Stitch, with a CLI (`npx @google/design.md`) that lints, diffs, exports, and prints the spec itself. It is deliberately the design counterpart to `CLAUDE.md`/`AGENTS.md` — a persistent, structured contract in the repo root that survives sessions.

So the format is settled, and the consumer already exists: any DESIGN.md-aware agent reading a repo-root file. What doesn't exist is anything that **derives the file from the UI you already shipped, and keeps it true as the code moves**. Every leading tool hands you a design system from somewhere else:

| Prior art | What it gives you | What it doesn't do |
|---|---|---|
| [google-labs-code/design.md](https://github.com/google-labs-code/design.md) | the spec, plus `lint` / `diff` / `export` / `spec` | nothing derives a file from *your* code; `alpha`, actively moving; no motion, dark-mode, or breakpoint tokens in the schema |
| [awesome-design-md](https://github.com/VoltAgent/awesome-design-md) · [getdesign.md](https://getdesign.md/) | 73+ / 300+ files reverse-engineered from Stripe, Linear, Vercel, Apple | you ship *their* visual identity; untethered from your codebase, and it never updates |
| [anthropics `design-system`](https://github.com/anthropics/knowledge-work-plugins/blob/main/design/skills/design-system/SKILL.md) | audit / document / extend; audit counts hardcoded hex and token coverage | assumes a system already exists; component-doc and Figma oriented |
| [ui-ux-pro-max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) | 84 styles, 192 palettes, 161 reasoning rules, anti-pattern lists | taste retrieved from a product-type lookup table, not derived from you; heavy install |

That's designkit: **the extraction and maintenance layer on a standard that already has a format and a validator.**

**Success:** run it on a real project and get a `DESIGN.md` that passes `npx @google/design.md lint`, describes tokens that actually appear in the code, declares what it couldn't derive instead of inventing it, and can later tell you — from the code — when it has gone stale.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Artifact format | **Adopt the DESIGN.md spec**, don't invent one. Spec-compliant YAML front matter plus the eight canonical `##` sections, so the official linter and every DESIGN.md-aware tool works on our output unchanged. |
| Section order | **Overview · Colors · Typography · Layout · Elevation & Depth · Shapes · Components · Do's and Don'ts.** (Not the nine-section list awesome-design-md publishes — that's their extended variant, and conflating them trips `section-order`.) |
| Extensions | **Effectively none.** The grill dissolved all three into spec-native structures: interaction states ride the existing related-key pattern (`button-primary`, `button-primary-hover`), voice folds into Do's and Don'ts, and anti-patterns *are* Do's and Don'ts. Only two unknown **prose** sections remain — Motion and Dark Mode — placed after Do's and Don'ts, where the spec preserves them silently. |
| No custom YAML | **Never emit custom token-shaped YAML keys.** The `token-like-ignored` rule warns on unknown keys carrying token-shaped values, so a `motion:` block would make every run warn on a file we called clean. Unknown *sections* are safe; unknown *tokens* are not. |
| Consumer | **Standalone.** designkit doesn't ship to uikit's contract — the consumer is any DESIGN.md-aware agent. uikit becomes one future reader, removing a dependency on an unbuilt skill. |
| Provenance | **Extract-first, interview only as fallback.** Read the shipped UI and codify what exists; interview only when there's no UI to read. This is the wedge — no prior-art tool does it. |
| Inventing values | **Never.** Every token must be a value that appears in the codebase. Clustering near-duplicates is derivation; picking a nicer neighbouring hex is invention. Anything underivable goes in the spec's native `omitted` field. |
| No-system codebases | **Cluster and propose, consent-gated.** 40 greys become a scale, with each token marked `extracted` (used as-is), `consolidated` (clustered from N near-duplicates, which are listed), or `omitted`. |
| Dark mode | **Extract when the code has one** — `.dark`, `prefers-color-scheme`, and Tailwind `dark:` variants are all trivially greppable — and write it as a prose `## Dark Mode` section with semantic naming rules. No dark mode in code means `omitted`, not an invented palette. |
| Token sync | **Write the shapes the official exporter already emits; route anything needing real conversion.** Tailwind and plain `:root` custom properties get written (`css-tailwind` emits a v4 `@theme` block of custom properties, so `:root` is transcription, not conversion). SCSS maps, CSS-in-JS, and WordPress `theme.json` get DTCG plus a named translator. Never introduce a token system where none exists. |
| Spec churn | **The CLI is the runtime source of truth** — `npx @google/design.md spec` rather than a hardcoded copy that rots. SKILL.md carries a schema summary as a documented offline fallback, labelled with the alpha version it was captured at. |
| Validation | **Shell out to `npx @google/design.md lint`.** designkit is not a second implementation of the spec, and never reimplements contrast math — `contrast-ratio` already enforces WCAG AA 4.5:1. |
| Degradation | **Degrade loudly.** With no `npx`, no network, or no CLI: extract and write from the fallback schema, skip lint and export, and name the gap in the same breath as the result — "wrote DESIGN.md; `lint` not run (no npx), schema from bundled alpha fallback." Never claim validation that didn't happen. |
| Preview | **Disposable review scaffolding, never an artifact.** A gitignored swatch sheet generated to make the consolidation proposal reviewable, then discarded. Reviewing "40 greys → 6" as a YAML diff is not realistic; a swatch sheet is not application UI. |
| Provenance stamp | **A visible line after the last section** — ``_Extracted from `main`@`a1b2c3d` on 2026-08-06._`` Invisible provenance is worse than none, since a stale file then reads as current. |
| `audit` baseline | `git show <stamped-sha>:DESIGN.md` piped into the CLI's `diff`. When a squash-merge has orphaned the SHA, fall back to the date — wikikit's existing precedent. |
| Modes | `init` · `update` · `audit`, reusing wikikit's mode vocabulary rather than inventing a third for this repo. |
| Location | **Repo-root `DESIGN.md`** — the spec's convention, and how DESIGN.md-aware tools discover it. Not `docs/`. |
| Visibility & layout | `internal: false`, a single self-contained `SKILL.md`, matching every skill here except verifykit. |

## Approach

**Reused from this repo:** wikikit's mode vocabulary, its *verify before you write* grounding rule, its visible provenance stamp, its restraint rule for `update`, and its "never introduces an engine" posture (here: never introduces a token system); domainkit's consent-gate-before-write; gitkit for the base ref; statuskit's disposable-gitignored-output precedent for the preview.

**Reused from the ecosystem:** the spec, the eleven lint rules, the contrast check, the Tailwind and DTCG exporters, `diff`, and `spec` itself.

### Phase 1 — The artifact contract

Pin down what designkit emits before writing any procedure.

- Wire `npx @google/design.md spec` in as the runtime schema source, and capture the current alpha schema into SKILL.md as the labelled offline fallback: `version`, `name`, `description`, `omitted`, `colors`, `typography`, `rounded`, `spacing`, `components`; `{colors.primary}` reference syntax; typography objects carrying `fontFamily`, `fontSize`, `fontWeight`, `lineHeight`, `letterSpacing`.
- Fix the eight canonical sections and their aliases (`Overview`/`Brand & Style`, `Layout`/`Layout & Spacing`, `Elevation & Depth`/`Elevation`), plus the two trailing prose sections.
- **Verify `token-like-ignored` empirically.** Draft a file with a custom token-shaped key, run `lint`, and confirm it warns. The no-custom-YAML rule rests on a reading of the rule table, not on observed behavior — if it turns out custom keys are silent, the Motion decision is worth revisiting.
- Define the stamp format and its position after the last section.

### Phase 2 — The extraction engine

The core of the skill, the part with no prior art to copy, and — after the grill — the single mechanism all three modes run on.

- Detect the token home in precedence order: Tailwind theme (v4 `@theme` or v3 config) → CSS custom properties (`:root`) → SCSS/Less variables → a CSS-in-JS theme object → WordPress `theme.json` → nothing.
- Derive from real usage, not just declarations: cluster the hex/oklch values actually used, the type scale actually applied, the spacing values that recur, and the interaction states actually styled.
- Grep for dark mode: `.dark`, `prefers-color-scheme`, `dark:` variants.
- Classify every token `extracted`, `consolidated`, or `omitted`, and keep the near-duplicates behind each consolidation so the proposal is reviewable.
- Emit the disposable swatch sheet for the consent gate.

### Phase 3 — `init`

- Run the ladder; say which rung matched before writing anything.
- No UI to read → fall back to the interview, and say plainly the result is *proposed*, not extracted.
- Consent-gate on the swatch sheet plus the extracted/consolidated/omitted breakdown.
- Write `DESIGN.md`, stamp it, run `lint`, report — including anything that didn't run.

### Phase 4 — `update` and `audit`, one engine

Both are *extract → diff → act*; only the write policy differs. This is what replaces wikikit's manifest: nothing to keep in sync, and no way to miss a change.

- Re-run the extraction engine against the current code.
- Diff the result against the committed `DESIGN.md`, and against the stamped baseline via `git show` where one is recoverable.
- **`update`** applies: edits land directly under the restraint rule; new sections and deletions are consent-gated; re-stamp. Resolve the target the way reviewkit does — uncommitted working tree first, else the branch diff against gitkit's base ref, never assuming `main`.
- **`audit`** reports and writes nothing: `lint` findings as-is, plus the drift only designkit can see — tokens in the file that no longer appear in code, and values in code that no token covers.

### Phase 5 — Token sync

- On consent, and only where a token home already exists.
- Tailwind → the official `json-tailwind` / `css-tailwind` export.
- Plain `:root` → written directly, transcribed from the `css-tailwind` output shape.
- Everything else → `dtcg` plus a named translator. No hand-rolled converters.

### Phase 6 — Ship

Draft `skills/designkit/SKILL.md`, live-test against a real project with existing messy UI (the no-token-home case is the one that matters), run `make lint`, then graduate: delete the row from IDEAS.md, add designkit to the README Skills table, and add it to a `skills.sh.json` group — Planning & Design is the closest fit today, though a design group may be warranted once uikit lands.

### Rejected alternatives

- **Our own format** — abandons a standard with a validator, an exporter, and a 300-file corpus to re-solve a solved problem.
- **Interview-first** — how getdesign.md and ui-ux-pro-max work; on an existing app it writes a spec the code contradicts.
- **A curated palette/style library** (ui-ux-pro-max's approach) — canned taste, heavy, and the opposite of deriving the system from your own code.
- **Custom YAML for motion and dark tokens** — machine-readable, and it makes every run emit a lint warning we caused.
- **Shipping `preview.html` as an artifact** — crosses into generated UI, which is the boundary designkit exists to hold.
- **A manifest of globs for `update`** — one more file that can be wrong while looking right, when re-extraction is both cheaper to maintain and impossible to fool.
- **Reimplementing contrast checking** — a second, worse implementation of a rule the official linter already runs.

## Open questions

The grill closed the frontier. Two residuals are genuinely deferred to build time rather than settled here:

- **Consolidation threshold.** "Cluster near-duplicates" needs a concrete rule — how close is close enough to merge two greys, and does the answer differ for colors, spacing, and type? This is a heuristic to tune against a real codebase during the live test, not a decision that can be made in the abstract.
- **`token-like-ignored`'s exact behavior**, which the artifact-contract phase verifies by running the linter. The no-custom-YAML rule depends on it.

## Non-goals

- **Not uikit.** No components, no pages, no application CSS.
- **Not a taste library.** No palettes, no font pairings, no style catalog — designkit derives them from your project or asks.
- **Not a spec implementation.** Linting, contrast, export, and the schema itself belong to the official CLI.
- **Not non-web platforms.** The spec is web-shaped (CSS color functions, `rem`, a Tailwind exporter); native iOS and Android are out for v1.
- **Not Figma.** No design-tool sync in either direction.
- **Not the glossary or ADRs** — that's domainkit. Not marketing or brand prose — that's humankit.
- **Not a design critique.** designkit records the system; judging whether it's any good is a human's call.
