# Research: Impeccable, and how it compares with the design kits

Source read on 2026-10-24 from a shallow clone of [pbakaus/impeccable](https://github.com/pbakaus/impeccable) at commit `9368675` (Release 4.7.1). Repo stats come from `gh api` on the same day. The kit side was checked against `skills/uikit`, `skills/motionkit`, `skills/designkit`, `skills/verifykit`, `skills/qakit` and `skills/reviewkit` in this repo at `3bb809b`. [0002](./0002-research-skill-ecosystem-2026-10-21.md) gave Impeccable one row; this report reads it in depth.

## What it is

Impeccable is a design skill for coding agents by Paul Bakaus. It started from Anthropic's `frontend-design` skill and grew into a product: one skill, a Rust engine, editor hooks, a live browser mode, a Chrome DevTools extension, a VS Code extension and a website at impeccable.style.

| Fact | Value |
|---|---|
| Stars / forks | 86,047 / 5,141 |
| Created | 2025-11-16 |
| Latest releases | skill v4.7.0 (2026-10-19), engine v0.1.17 (2026-10-23) |
| License | Apache-2.0 |
| Authorship | pbakaus 1,885 commits; next human contributor 235 |
| Harnesses | 17, from Claude Code and Codex to Kiro, Trae and Antigravity |
| Skill text | `SKILL.md` 1,646 words; 41 reference files; about 63,000 words in total |
| Engine | 16 Rust crates, shipped as a prebuilt binary behind a shell launcher |

The pace is high. Five releases landed in the eight days before this read, and the commit log carries reviewed PRs with follow-ups, not drive-by edits.

## How it is built

### One skill, a command table

Everything runs as `/impeccable <command> <target>`. The root `SKILL.md` holds the principles, four visitor modes, and a 24-row command table. Each row points at one reference file, so a run loads the root plus one playbook. With no argument the skill shows a context-aware menu and never runs a command on its own. `pin audit` writes a standalone `/audit` shortcut for a command the user reaches for often.

The commands fall into six groups:

- Build: `init`, `shape`, `document`, `extract`, plus `craft` as a deprecated alias.
- Evaluate: `critique`, `audit`.
- Refine: `polish`, `bolder`, `quieter`, `distill`, `harden`, `onboard`.
- Enhance: `animate`, `colorize`, `typeset`, `layout`, `delight`, `overdrive`.
- Fix: `clarify`, `adapt`, `optimize`.
- Iterate: `live`, `generate`.

### Three context files

- `PRODUCT.md` holds durable product truth: users, purpose, positioning, operating context, constraints. `init` writes it after an interview of at most three questions per round.
- `DESIGN.md` holds the visual system in the Google Labs `design.md` format, the same spec designkit targets. A `.impeccable/design.json` sidecar carries extra data for the live panel.
- `.impeccable/surfaces/*.md` holds one brief per route or artifact, including a six-block "Direction contract" (THESIS, OWN-WORLD, STORY, FIRST VIEWPORT, FORM, FINISH) that later sessions reload.

Every run starts with `scripts/impeccable context`, which loads all three and prints directives. When the launcher fails, the skill reads the files by hand and says so before its next tool call.

### Four visitor modes

The mode names what success looks like for the visitor, and it is chosen per surface, not per product. Persuade covers landing and pricing pages. Operate covers app screens, dashboards and settings. Read covers docs and articles. Experience covers portfolios and galleries. Ambition scales with the mode: full commitment on Persuade and Experience, precision and restraint on Operate and Read.

### New work: a dealt hand of visual worlds

This is the most unusual part. For a new or replacement visual identity, `reference/new-work.md` asks the agent to:

1. Derive seven candidate visual systems from the audience's cultural world, spanning at least three material families.
2. Run `impeccable concept-seed`, which calls a roll API at impeccable.style. The roll assigns one direction and deals catalog "challenger" worlds. The stated reason is that dice break the ranking rut that makes every run land on the category default.
3. Judge each challenger on two axes, audience identification and product clarity, and record a verdict of wins, competitive or declined.
4. Serve a local decision page (`serve-question`) with the assigned direction, at most three challenger cards, one "Impeccable's pick" card, re-roll in plain, safer or bolder registers, and a "canon" exit that executes the category standard straight.

With image generation available, each card gets a full-fidelity comp. The engine falls back to the OpenAI image API when the harness has no native tool. The project records `buildPath` as `comp` or `code`. Operate and Read surfaces always build code-first.

### Comp-led build: a gated state machine

On the comp path, `impeccable build-phase` refuses to advance until each gate passes: comps, spec, plates, hero, sections, motion, responsive. The spec gate measures the comp on a grid. `font-match` ranks Google Fonts candidates by a glyph fingerprint against the comp's measured cap height. The hero gate runs `comp-diff` and passes at 72% overall with no hard veto (a missing region, an SVG standing in for an illustration, invented ink). The skill itself warns that this path is "a frontier-tier job" and that smaller models stall at the hero gate.

### Finish: a fresh reviewer, then a documenter

After at most two screenshot rounds, the build thread stops polishing and spawns `impeccable-finish-reviewer` with no forked history. The reviewer gets the request, the direction contract, the screenshots, the comp and the diff reports. It returns one of four dispositions: `recapture`, `rebuild`, `fix` or `ship`. Then `impeccable-documenter` writes `DESIGN.md` from the built world rather than from intentions. Two more subagents handle raster assets and live-mode copy edits.

### The detector and the hook

The engine ships 62 deterministic rules that need no LLM and no API key. They cover slop tells (`side-tab`, `gradient-text`, `dark-glow`, `bounce-easing`, `overused-font`, `cream-palette`, `kicker-above-heading`, `nested-cards`, `icon-tile-stack`) and general quality (`low-contrast`, `line-length`, `cramped-padding`, `skipped-heading`, `tiny-text`, `text-overflow`). There are also copy rules: `em-dash-overuse`, `marketing-buzzword`, `aphoristic-cadence`.

- `npx impeccable detect <dir|file|url>` scans source or a rendered URL. It prints `--json` or `--github` annotations and exits `2` on findings.
- Ignores live in `.impeccable/config.json` or inline as `impeccable-disable` comments.
- The installed hook runs on `SessionStart`, on `PostToolUse` for `Edit|Write`, and as a deeper pass on `Stop`. On Claude Code it lands in `.claude/settings.local.json`.

### Critique and audit

`critique` is the longest reference at 854 lines. It runs two assessments in parallel: an LLM design review, and detector plus browser evidence. The report scores Nielsen's ten heuristics, applies five personas (power user, first-timer, accessibility-dependent, stress tester, distracted mobile user), adds a cognitive-load check, and saves a snapshot to `.impeccable/critique/`. `audit` is the technical pass for a11y, performance, theming and responsive layout, with a health score.

### Live mode

`live` injects a localhost helper into a running dev server. The user picks an element in the browser, the agent writes three variants, and the user accepts, discards or steers. Copy edits made in the page go back to source through a subagent. It refuses deployed production sites.

### Other details worth knowing

- Model-specific blocks. `<claude>` and `<codex>` sections hold rules for one model family only. The Claude block names a "measured rendition prior": warm and child-facing subjects come out cream, serif and lamplit, so the first palette counts as spent.
- Behaviour tests. `tests/skill-behavior/` runs LLM-backed scenarios against Anthropic, OpenAI and Google models to check that the agent still follows the loading contract. A separate suite tests activation from the description.
- Telemetry. The roll request always goes to impeccable.style, because the roll is the feature. By default it also records which card won. `DO_NOT_TRACK=1` or `"telemetry": false` stops the recording, not the request.
- Footprint. A project gains `PRODUCT.md`, `DESIGN.md` and a `.impeccable/` tree whose `.gitignore` block lists 17 ephemeral paths.

## Comparison with the kits

### Command by command

| Impeccable | Closest kit | How they differ |
|---|---|---|
| `init` → `PRODUCT.md` | domainkit `CONTEXT.md`; uikit rung 3 | uikit infers the subject and states the inference without blocking. Impeccable interviews before it writes. |
| `document`, `extract` | designkit `init`, `update`, `sync` | Same spec. designkit holds a grounding rule (every token appears in the code) and runs the official linter. Impeccable asks the user for qualitative language, writes a sidecar, and has a seed mode that writes `DESIGN.md` before any code exists, which designkit refuses on purpose. |
| `critique`, `audit` | uikit `audit`; reviewkit | uikit's audit is a capped list of about 30 bans, checkable without rendering, plus an a11y floor. Impeccable adds heuristic scores, personas and detector evidence. uikit is lighter and greppable; Impeccable is deeper and more expensive. |
| `polish`, `bolder`, `quieter`, `distill`, `colorize`, `typeset`, `layout`, `delight`, `overdrive` | uikit `build` | No kit has these named dials. uikit runs one build mode and puts boldness in a single "signature" element per surface. |
| `harden` | qakit worst-case checks; reviewkit data bounds; uikit state gaps | The kits split this across three skills. Impeccable keeps it in one 362-line playbook. |
| `onboard`, `clarify` | uikit build (strings as design material) | uikit covers empty states and copy rules in its catalog. Impeccable gives each a full playbook. |
| `animate` | motionkit | motionkit is much deeper: a frequency gate, easing tokens, springs, gestures, property cost, a `perf` mode and a vocabulary lookup. Impeccable's `animate` is 89 lines. See [Where they disagree](#where-they-disagree). |
| `adapt`, native iOS and Android | uikit `mobile.md` | The kits are web-only. Impeccable has native audit and adapt variants plus `ios.md` and `android.md`. |
| `optimize` | motionkit `perf` (motion only) | No kit covers general UI performance. |
| `shape` | plankit; grillkit | plankit plans any feature. `shape` plans UX only. |
| `live`, `generate` | prototypekit mocks; uikit Mockups; verifykit `show` | No kit picks an element in a live page and swaps variants in place. |
| detector and hook | none | The largest gap. Every kit check is the agent reading its own output. uikit says plainly that it is "not a gate". |
| finish reviewer in a fresh context | uikit pre-flight (in-thread) | uikit critiques its own build in the same context. Impeccable insists on a reviewer that never saw the build thread. |

### Where they agree

The anti-slop lists overlap heavily. Both ban gradient text, glass by reflex, colored side stripes, eyebrow kickers, `01 / 02 / 03` markers on non-sequences, equal card grids and Inter as the whole type decision. Both name the same three "bold" defaults: cream with a serif and a terracotta accent, near-black with one neon accent, and broadsheet hairlines. Both want one authored moment rather than scattered effects, both say reduced motion means fewer and gentler rather than none, and both read `DESIGN.md` first when it exists. uikit's rung 3 and Impeccable's "seven candidates from the audience's cultural world" are the same idea: distinctiveness comes from the subject, not from a style list.

### Where they disagree

- **Taste library.** uikit says it is "not a taste library" and ships no palettes, because a lookup table makes every project look alike. Impeccable keeps a remote catalog of worlds, a local palette table of 128 seeded entries and a Google Fonts index, and uses dice to stop the agent ranking the same choice first every time. Both target the same failure from opposite ends.
- **Gates.** uikit never blocks a build. Impeccable's build-phase refuses to advance and its comp-diff sets a numeric bar.
- **Demonstration data.** uikit bans placeholder people, invented metrics and lorem ipsum outright. Impeccable allows synthetic demonstration content at full fidelity when it is labelled, and bans only invented commercial claims. It calls refusing a bold direction for lack of data "the timidity reflex".
- **Motion materials.** Impeccable says to "reach past transform and opacity" to blur, clip-path, mask and shadow. motionkit makes `transform` and `opacity` the default and asks for a reason for anything else, with a cost table to justify it. motionkit also allows a 0.1 to 0.3 spring bounce on drag-to-dismiss, where Impeccable lists `bounce-easing` as a detector finding.
- **Index shape.** Impeccable costs one description of context load and moves the load onto the human, who must learn 24 command names. The kits spend one description per skill and keep each skill a distinct decision, as AGENTS.md asks.
- **Weight.** About 63,000 words of references against about 11,600 words across the uikit, motionkit and designkit roots. The kits are roughly a fifth of the size and need no binary, no network and no hook.

### The trigger collision

Impeccable's description fires on "design, redesign, shape, critique, audit, polish, simplify, harden, animate" and on most UI nouns. Installed next to uikit, motionkit and designkit, it competes for "animate this", "audit our UI" and "write a DESIGN.md". `design-taste-frontend` is already installed globally on this box with an equally broad description. Three overlapping design skills make the routing unpredictable, so I would not install the Impeccable skill globally here. The detector CLI runs without the skill (`npx impeccable detect`) and carries most of the value that the kits lack.

## Ideas worth taking

Ranked by value over cost. Each one is authored from scratch to fit the kit conventions; Impeccable is Apache-2.0, so any copied wording would need a NOTICE.

| # | Kit | Idea | Cost |
|---|---|---|---|
| 1 | uikit `audit`, reviewkit | When `npx impeccable detect` is reachable, run it with `--json` on the target paths and merge its findings under a "detector" evidence label, the way motionkit labels "recorded" evidence. Degrade to the catalog alone when it is not. | Medium: a third-party binary and a first-run download. |
| 2 | uikit floor | Add browser surfaces to the accessibility floor: text selection, caret, scrollbar, focus ring, underline offset and `tabular-nums` in data. 0002 ranked this as row 19, and it has not landed yet. | Low: a few lines. |
| 3 | uikit pre-flight | When a subagent tool exists, run the written pre-flight in a fresh subagent that gets the design read, the paths and any screenshots, and no build history. uikit already lists `Task` and `Agent` in `allowed-tools`. | Low to medium. |
| 4 | uikit design read | Widen `surface` from `product` and `marketing` to add `docs` (Impeccable's Read mode). Docs pages currently get the marketing filter or none. | Medium: the catalog needs scope tags for it. |
| 5 | skillkit, evals | Copy the idea behind `tests/skill-behavior/`: scenario tests across model families that fail when the agent stops following a skill's loading contract. | High. |

Leave these out:

- The remote roll API and its telemetry. It adds a network dependency and runs against uikit's "no taste library" rule.
- The comp-led state machine. It needs image generation and a frontier model, and the skill admits smaller models stall at the hero gate.
- The 24 named dials. As separate skills they would fail the AGENTS.md gate; as uikit modes they would inflate the description for intents that a sentence in the request already carries.

## Open question

The case for idea 1 depends on whether the detector finds tells that uikit `audit` misses. Nobody has measured that. One run settles it: pick a real project UI, run `uikit audit` and `npx impeccable detect --json` on the same paths, and compare the two finding lists.

## Sources

- https://github.com/pbakaus/impeccable at `9368675`: `README.md`, `PRODUCT.md`, `skill/SKILL.src.md`, `skill/reference/{new-work,craft-floor,animate,critique,document,init,live,hooks,audit}.md`, `skill/agents/*.md`, `.claude/settings.json`, `tests/skill-behavior/README.md`, `crates/detect/src/`, `crates/context/src/`
- `gh api repos/pbakaus/impeccable`, `/releases` and `/contributors`, read 2026-10-24
- https://impeccable.style, cited by the repo for docs and privacy; not fetched
