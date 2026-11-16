---
name: designkit
description: >-
  Derive a project's design system from the UI it already ships and keep it true as the code moves, producing a spec-compliant DESIGN.md at the repo root, validated by the official linter. Use when the user says "write a DESIGN.md", "document our design system", "extract our design tokens", "our design system is out of date", "audit our design tokens", "what colors does this project actually use", "sync DESIGN.md to our Tailwind theme", or "/designkit".
license: MIT
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, AskUserQuestion
metadata:
  internal: false
---

# designkit

designkit writes `DESIGN.md`, the Google Labs format ([google-labs-code/design.md](https://github.com/google-labs-code/design.md)): design tokens in YAML front matter, rationale in prose.

**The grounding rule: every token is a value that appears in the codebase**, or, in a repo with no UI, a value the user supplied in [`init`'s interview](#2-interview-only-when-theres-nothing-to-read). Clustering near-duplicates into a scale is derivation. Picking a nicer neighbouring hex is invention, and designkit never does it.

designkit writes no UI, ships no palettes, and does no contrast math. The glossary and ADRs belong elsewhere.

## When this fires

- **`init`.** No `DESIGN.md` yet. Derives the file from the codebase.
- **`update`.** The design system changed, or a design pass right after UI work lands. Applies what the code now says.
- **`audit`.** Is the file still accurate, and what has drifted. Read-only. **Writes nothing, ever.**
- **`sync`.** Export the tokens, or the follow-up `init` names when the file and the token home disagree. Writes the project's existing token home from `DESIGN.md`.

**If no mode is clear, ask.**

What each mode may write:

| Mode | Writes | Gate |
|---|---|---|
| `init` | `DESIGN.md`; the swatch sheet and its `.gitignore` line | the proposal |
| `update` | token and prose edits in `DESIGN.md`; the swatch sheet and its `.gitignore` line when a gated change needs one | new sections, deletions, and drift outside the target |
| `audit` | nothing | none |
| `sync` | the existing token home (Tailwind theme, `:root` block) or a DTCG export file | every write |

## The artifact

`DESIGN.md` lives at the **repo root**, not `docs/`, because DESIGN.md-aware tools discover it there.

**Existing project convention wins.** A repo with its own token names, its own file location, or its own design-doc layout gets followed, and designkit says which convention it followed.

### The token schema

Front matter opens with a line of exactly `---` and closes the same way. This is the alpha schema as captured on 2026-08-06 and rechecked against CLI v0.4.0 on 2026-11-16; prefer [reading it live](#the-cli-is-the-source-of-truth) when the CLI is available.

```yaml
version: <string>          # optional, current: "alpha"
name: <string>
description: <string>      # optional
omitted: <string[] | OmittedSection[]>   # optional; sections deliberately excluded
colors:
  <token-name>: <Color>            # "#1A1C1E", "oklch(62% 0.18 250)", CSS named
typography:
  <token-name>: <Typography>       # fontFamily, fontSize, fontWeight, lineHeight,
                                   # letterSpacing, fontFeature, fontVariation
rounded:
  <scale-level>: <Dimension>       # 4px, 0.5rem, 9999px
spacing:
  <scale-level>: <Dimension | number>
components:
  <component-name>:
    <token-name>: <string | token reference>   # "{colors.primary}"
```

Values cross-reference with `{path.to.token}` syntax. Prefer a reference over a repeated literal, because an unreferenced token trips `orphaned-tokens`.

**Recommended token names** (non-normative, but follow them unless the project already has its own vocabulary): colors `primary`, `secondary`, `tertiary`, `neutral`, `surface`, `on-surface`, `error`; typography `headline-display`, `headline-lg`, `headline-md`, `body-lg`, `body-md`, `body-sm`, `label-lg`, `label-md`, `label-sm`; rounded `none`, `sm`, `md`, `lg`, `xl`, `full`.

### The sections

Eight canonical `##` headings, in this order. Out-of-order sections trip `section-order`; a **duplicate heading is a hard error that rejects the file**.

| # | Section | Alias | Carries |
|---|---------|-------|---------|
| 1 | Overview | Brand & Style | the visual intent, in prose |
| 2 | Colors | none | palette rationale; `colors` tokens |
| 3 | Typography | none | the type hierarchy; `typography` tokens |
| 4 | Layout | Layout & Spacing | grid, whitespace; `spacing` tokens |
| 5 | Elevation & Depth | Elevation | shadow and surface hierarchy |
| 6 | Shapes | none | corner language; `rounded` tokens |
| 7 | Components | none | component guidance; `components` tokens |
| 8 | Do's and Don'ts | none | guardrails, anti-patterns, **and UI copy voice** |

Two further sections are permitted **after** Do's and Don'ts, because the spec preserves unknown headings without error: **`## Motion`** and **`## Dark Mode`**. Both are prose only.

Keep prose to what a token cannot carry: intent, and when *not* to reach for something. For a general pass over that prose, use **humankit** when installed.

### What never goes in YAML

Two shapes produce linter warnings:

| Shape | What the linter does | Do this instead |
|---|---|---|
| A top-level `motion:` token map | ⚠️ `token-like-ignored`, *"looks like a design-token map but is not a recognized schema key … will be silently ignored by export commands"* | prose in `## Motion` |
| `transitionDuration:` on a component | ⚠️ `broken-ref`, *"not a recognized component sub-token"* | prose in `## Motion` |

**The complete set of valid component sub-tokens is `backgroundColor`, `textColor`, `typography`, `rounded`, `padding`, `size`, `height`, `width`.** There is no duration, no easing, no border, no gap. Anything else warns.

**Motion has no token home in the schema.** Durations and easing curves are prose.

What *is* token-legal is **interaction state**, through the related-key pattern the spec defines: `button-primary`, `button-primary-hover`, `button-primary-active`. Extract those as real component entries. Never invent a custom key to hold a state the pattern already expresses.

### The stamp

Every file designkit writes ends with one visible line, after the last section:

```markdown
_Extracted from `main`@`a1b2c3d` on 2026-08-06._
```

[`audit`](#mode-audit) recovers the baseline with `git show <sha>:DESIGN.md` while the SHA is reachable, else it uses the date. Keep the stamp visible, never in an HTML comment.

A file with **no** stamp was written by a human. Adopt it, work with it, never silently claim it, and say plainly that you're editing a file designkit didn't author.

## The CLI is the source of truth

The format is at version `alpha`. **Read the spec at run time** and treat the summary above as a dated fallback:

| Command | Use |
|---|---|
| `npx @google/design.md spec [--rules] [--format json]` | the current schema and rule set |
| `npx @google/design.md lint <file> [--format json]` | validate; JSON by default |
| `npx @google/design.md diff <before> <after>` | compare two versions |
| `npx @google/design.md export --format {json-tailwind\|css-tailwind\|dtcg\|css-vars} <file>` | emit tokens; `tailwind` is an alias for `json-tailwind` (v0.4.0, checked 2026-11-16) |

Exit codes: `0` success, `1` errors or regressions, `2` file read failure. On Windows PowerShell use the `designmd` alias, because the `.md` file association hijacks the other form.

The eleven lint rules run on every file: `broken-ref` (error), `contrast-ratio`, `orphaned-tokens`, `missing-primary`, `missing-typography`, `section-order`, `unknown-key`, `token-like-ignored` (warnings), and `token-summary`, `missing-sections`, `omitted-rules` (info). **`contrast-ratio` already enforces WCAG AA at 4.5:1**, so never write your own contrast math.

## The extraction engine

One engine, shared by `init`, `update`, and `audit`. `init` writes its output, `update` diffs and applies it, `audit` diffs and reports it. `audit` skips [Show the work](#show-the-work), the engine's only write.

### Find the token home

First rung that matches, and **say which one matched before writing anything**:

| # | Rung | Looks like |
|---|---|---|
| 1 | Tailwind | `@theme` in CSS (v4), or `tailwind.config.*` `theme.extend` (v3) |
| 2 | CSS custom properties | a `:root` block of `--token: value` |
| 3 | Preprocessor variables | SCSS `$vars`, Less `@vars`, a map file |
| 4 | CSS-in-JS theme | a theme object passed to a provider |
| 5 | WordPress | `theme.json` `settings.color.palette`, `settings.typography` |
| 6 | **Nothing** | no declared tokens anywhere; see [when there's no system](#when-theres-no-system) |

### Derive from usage, not declarations

A declared token nobody uses is not the design system; forty hardcoded hexes are. Read both:

- every color literal in stylesheets, templates, and components, meaning hex, `rgb()`, `hsl()`, `oklch()`, and named colors
- the font sizes, weights, and line heights actually applied
- the padding, margin, and gap values that recur
- corner radii and shadows in use
- the interaction states actually styled: `:hover`, `:focus-visible`, `:active`, `disabled`, and their framework equivalents
- dark mode: grep `.dark`, `prefers-color-scheme`, `dark:` variants, `[data-theme]`

Count occurrences.

### Classify every token

Each token carries one of four states, and the classification is shown at the consent gate:

| State | Means |
|---|---|
| `extracted` | the value appears in the code as-is, used enough to be systematic |
| `consolidated` | clustered from N near-duplicates; **list them**, so the merge is reviewable and reversible |
| `omitted` | not derivable from the code; goes in the spec's native `omitted` field, never invented |
| `supplied` | given by the user in `init`'s interview, in a repo with no UI to extract from |

Put anything not derivable in `omitted`. The field also suppresses missing-section warnings.

### When there's no system

With hardcoded values and no token home, designkit **clusters and proposes**. It does not refuse, and it does not fall through to the interview when the code has UI.

Cluster near-duplicates, choose the most-used member of each cluster as the representative, and list the members it absorbs.

Tune the cluster threshold to the project and **state the threshold you used**. Perceptual distance for color, nearest-step for spacing and type. When a cluster is too loose to call one system, split it rather than forcing a merge, and say so.

### Show the work

This step runs in `init`, and in `update` only when a gated change needs review.

Before writing anything, emit a **disposable swatch sheet**: a plain HTML page of color chips, type specimens, spacing bars, and radii, each labelled with its token name, its state, and the values it absorbed. Write it to a gitignored scratch path, add that path to `.gitignore` if it isn't covered, name it in the consent ask, and don't keep it.

## Mode: `init`

### 1. Ground it

Run [the extraction engine](#the-extraction-engine). Name the rung that matched, the number of distinct values found per category, and the dark-mode verdict, before proposing anything. This step is done when every category (color, type, spacing, radius, shadow, state, dark mode) has a count or a "none found".

### 2. Interview only when there's nothing to read

No UI in the repo means nothing to extract. Ask for the essentials (brand intent, an existing palette, type preferences). Every value the user gives becomes a `supplied` token; designkit adds no value of its own. Say plainly in the report and in the file's Overview that the result is **proposed, not extracted**. Anything still unknown is `omitted`. Skip this step when the engine found UI. This step is done when every schema category holds `supplied` tokens or is `omitted`.

### 3. Propose, and gate on it

Show the swatch sheet plus the `extracted` / `consolidated` / `omitted` / `supplied` breakdown, the cluster threshold, and every inconsistency found. The user accepts, trims, or redirects before a file exists. This step is done when the user accepts the proposal, with or without trims.

### 4. Write, stamp, validate

Write `DESIGN.md` at the repo root, append the stamp, then run `lint` and report its findings verbatim, including any that remain. A warning you chose to accept is reported as accepted, never suppressed. This step is done when `lint` exits `0`, or every remaining finding is reported, or the lint gap is named.

### 5. Hand off

_Write every hand-off in this skill in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

**What changed.** Report the file created, the rung that matched, how many tokens landed in each state, and what was omitted.

**Where it landed.** Give `DESIGN.md` at the repo root, the swatch sheet's scratch path (and that it's disposable), and the lint result.

**Next.** Read the file. Then commit it with **commitkit** when installed, otherwise `git add DESIGN.md` and commit. If the project has a token home and the file's values differ from it, [`sync`](#mode-sync) is the follow-up; if it doesn't, there is nothing to sync and no next step to invent.

## Mode: `update`

### 1. Resolve the target

Uncommitted working-tree changes first (`git status --porcelain` non-empty → `git diff HEAD`, plus untracked files, which `git diff` never shows). Otherwise the branch diff against the base ref, from **gitkit** when it's installed, else the repo's default branch via `gh repo view --json defaultBranchRef`. **Never assume `main`.** Say which target you chose in one line. The target scopes what `update` applies, in [Apply, with restraint](#3-apply-with-restraint). This step is done when the target line names the range and lists the changed UI files, untracked ones included.

### 2. Re-extract and diff

Run the engine against the current code and diff its result against the committed `DESIGN.md`. Where the stamped SHA is still reachable, also run `npx @google/design.md diff <baseline> <current>` for the structured token-level comparison. Re-extract the whole codebase, not only the target, so a usage count stays true. Then sort each drift: **in target** when its value occurs in a changed hunk or untracked file of the target, **outside target** otherwise. This step is done when every drift is sorted.

### 3. Apply, with restraint

A changed brand color edits the color token. It does not regenerate the file. **State which sections are affected and which are deliberately untouched before editing.**

Edits to existing tokens and prose land directly when the drift is in target. **New sections, deletions, and outside-target drift are consent-gated.** List outside-target drift and apply it only on a yes; otherwise route it to `audit`. This step is done when every in-target drift is applied and every gated item has a verdict.

### 4. Re-stamp and validate

Re-stamp with the current ref and SHA, run `lint`, report. This step is done when the stamp names the current SHA and the lint result is reported.

### 5. Hand off

**What changed.** Report tokens edited (one line each, naming the value that moved), sections proposed and their verdict, outside-target drift and its verdict, and sections deliberately untouched.

**Where it landed.** Give `DESIGN.md`, and the lint result.

**Next.** Run **commitkit**, then **prkit** if this is branch work (otherwise `git commit` and `gh pr create`). Commit `DESIGN.md` in the same commit as the UI change that moved it.

## Mode: `audit`

**Read-only. Writes nothing, ever.** It reports and routes.

Three checks:

- **Lint.** Run `npx @google/design.md lint`, findings reported as-is.
- **Drift.** Two directions: tokens in the file that no longer appear in the code, and values in the code that no token covers.
- **Baseline.** Run `npx @google/design.md diff` against `git show <stamped-sha>:DESIGN.md`, when the SHA is reachable. Write the baseline copy to the system temporary directory (`mktemp`), never into the repo.

Run the extraction engine without its swatch sheet. The audit is done when each of the three checks has a result or a named gap.

### The report

| Verdict | Means |
|---|---|
| `current` | the file's tokens match what the code uses |
| `stale` | a token's value has moved in the code |
| `orphaned` | a token in the file appears nowhere in the code |
| `uncovered` | a value used in the code that no token covers |
| `unverified` | a human-written file designkit has never checked |

Open with a coverage line, naming how many files were scanned and how many skipped. Then crown one next move.

### Hand off

**What changed.** Nothing.

**Where it landed.** Inline in this reply. There's no audit artifact by default; offer to save one only if asked.

**Next.** Crown the single worst drift and route it to [`update`](#mode-update), or to [`init`](#mode-init) when the file is missing rather than wrong. **"Nothing has drifted" is a valid, stated result**, so say the system is current and stop.

## Mode: `sync`

**On consent, and only where a token home already exists.** designkit never introduces a token system to a project that doesn't have one. With no token home, say so and stop; there is nothing to sync.

### 1. Find the home and the gap

Run the engine's [Find the token home](#find-the-token-home) and name the rung. Compare each `DESIGN.md` token with the home's value. This step is done when every token is marked same, different, or absent from the home.

### 2. Export and write, on consent

Show the token changes the write would make, and ask once. On a yes, write by the table below:

| Token home | How |
|---|---|
| Tailwind | the official `export --format json-tailwind` or `css-tailwind` |
| Plain `:root` custom properties | the official `export --format css-vars`, which emits a `:root` block (`--prefix` adds a name prefix) |
| SCSS maps, CSS-in-JS, WordPress `theme.json` | `export --format dtcg`, then route to a translator such as Style Dictionary |

Never hand-roll a converter. When the official exporter does not emit the home's shape, emit DTCG and name the translator.

This step is done when every different or absent token is written, or exported as DTCG with the translator named, or the user declined.

### 3. Hand off

**What changed.** Report the token home written, one line per token that moved, or that the user declined.

**Where it landed.** Give the token home path, or the DTCG export path and the translator to run.

**Next.** Commit the token home and `DESIGN.md` together with **commitkit** when installed, otherwise `git commit`.

## Degrade loudly

With no `npx`, no network, or no CLI, extract and write from the fallback schema above, skip lint and export, and **name the gap in the same breath as the result**:

> Wrote `DESIGN.md` (12 colors, 6 type styles). `lint` not run, because no `npx` was available. Schema from the bundled `alpha` fallback captured 2026-08-06.

No filesystem at all (a browser-based agent)? Print the finished `DESIGN.md` as a fenced block labelled with its path, describe the swatch sheet rather than writing it, and name the commands the user should run themselves.

