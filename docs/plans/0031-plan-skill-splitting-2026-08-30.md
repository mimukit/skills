# Plan — split oversized skills into root + mode satellites

Grilled: 2026-08-30

_Created 2026-08-30._

## Context

The collection has held a one-file convention: every skill is a single `SKILL.md`, no satellites, no per-mode files. That convention is now losing to size. The three largest skills sit at 58–62 KB (roughly 15k tokens each), and seven more sit between 26 and 33 KB. When a skill fires, the host loads the whole body, but a typical run walks one mode. An `issuekit close` run pays for `create`, `start`, `sync`, and `triage` on every invocation and reads none of them.

`AGENTS.md` already licenses the fix. Its information hierarchy names a third tier, **disclosed reference**: material pushed into a satellite file inside the skill's own directory, reached by a pointer, loaded only when that pointer fires. Its rule for when to push is the one this plan runs on: **disclose by branch, not by size**. Inline what every branch needs; push behind a pointer what only some branches reach. `gitkit` already ships `stacks.md` and `verifykit` ships `verify-assets.sh`, so the one-file convention has two precedents against it.

The same rule cuts the other way for the two largest files. `statuskit` (62 KB) and `afkkit` (59 KB) are single straight-through procedures. Every run walks every step, so a split there adds read round-trips and saves zero tokens. Size alone is not the trigger; skipped branches are. Those two are out of scope, and if their size ever hurts, the cure is a prune pass under the existing pruning rules, not a split.

A survey of all 34 skills (2026-08-30, bytes ≈ tokens × 4):

| Skill | Size | Structure | Verdict |
|---|---|---|---|
| statuskit | 62 KB | one procedure | keep whole |
| issuekit | 60 KB | 5 modes | **split** |
| afkkit | 59 KB | one pipeline | keep whole |
| ideakit | 33 KB | 8 modes | **split** |
| wikikit | 32 KB | 4 modes, huge `publish` | **split** |
| promptkit | 31 KB | 2 modes + shared catalog | partial |
| mergekit | 30 KB | 4 modes | **split** |
| tutorkit | 28 KB | 6 modes | **split** |
| paseokit | 28 KB | 4 small modes | defer |
| uikit | 26 KB | 2 modes + stack layer | partial |
| remaining 24 | ≤ 24 KB | mostly single procedure | keep whole |

Expected effect on the best case: an `issuekit` run drops from ~15k tokens to roughly a ~5k root plus a ~2–3k mode file, about half the load. The other splits land smaller but in the same shape.

## Settled decisions

| # | Decision | Answer | Why |
|---|---|---|---|
| — | The test for splitting | Skipped branches, never raw size | `AGENTS.md` "disclose by branch, not by size". A straight-through skill needs its whole body every run, so a split only adds reads. This is why statuskit and afkkit, the two largest files, stay whole. |
| — | Satellite layout | `skills/<name>/modes/<mode>.md`, one file per mode | Mode is the branch unit in every candidate. A `modes/` directory keeps satellites visibly subordinate to the root and leaves room for non-mode satellites (`gitkit/stacks.md` stays where it is). |
| — | What stays in the root | Frontmatter, "when this fires", mode selection, guards, preflight, shared vocabulary (labels, catalogs, conventions), and the pointer per mode | The root must still route and guard on its own. `AGENTS.md` warns that pushing too much down hides material the agent needs; a bare index root is the over-split failure. |
| — | Pointer form | The mode-selection line names the file and the trigger: "mode `close` → read `modes/close.md`, then follow it" | A bare link under-triggers. The pointer carries the condition, same as a description does. |
| — | Shared-by-all-modes material | Never moves | promptkit's slop catalog and uikit's anti-slop catalog serve both modes, so they stay inline. Moving them would force a second read on every run. |
| — | Cross-file links | Root → satellite pointers are plain relative links; satellites do not link back into root sections | One direction keeps the dependency graph a tree. `make lint`'s intra-doc anchor check must learn to resolve (or explicitly skip) cross-file `](modes/x.md)` links before the first split lands. |
| — | Portability | Satellites live inside the skill directory, so a public skill stays self-contained | skills.sh installs the whole `skills/<name>/` directory. No repo-relative escape, no new portability class. |
| — | Wiki pages | Each split updates the skill's `docs/wiki/skills/<name>.md` in the same change, re-stamped | Required by `AGENTS.md`; the split changes no behavior, but the page's source-link foot and any line claiming a single file must stay true. |
| — | Order | issuekit → wikikit → mergekit → ideakit → tutorkit, then the partials | Largest win first, and issuekit is the cleanest mode structure. wikikit second because extracting the embedded `publish` workflow is the single biggest one-block win. |
| — | paseokit | Deferred | Four modes but each is short; the root-plus-pointer overhead eats most of the gain. Revisit if it grows. |
| G1 | Split set | Final as tabled; no paseokit, no statuskit/afkkit prune phase in this plan | A prune is editing, and the non-goal keeps this plan a pure relocation. Prune statuskit/afkkit under a separate later plan. |
| G2 | Lint depth on satellites | Full checks on every `.md` under a skill directory: anchors, number-based step refs, pointer-target existence | One `check_anchors` call per file, so depth is nearly free, and it closes the existing gap where `gitkit/stacks.md` is invisible to lint. |
| G3 | Per-mode hand-offs | Move with their mode bodies. Lint accepts a split skill (one with a `modes/` directory) when the root **or** every `modes/*.md` carries a closing section | The check follows the content. The or-form covers ideakit and tutorkit, whose single `## Hand off` serves all modes and therefore stays in the root as shared material. |
| G4 | Satellite self-containment | Satellites assume the root is loaded and never repeat root material; no header line | The agent always reads the root first to route, so the assumption holds by construction, and repeating guards per mode is exactly the duplication the pruning rules forbid. |
| G5 | Commit shape | One commit per skill, with the Phase 0 lint commit landing first and alone | Lint's forgotten-page tripwire is scoped to commits touching exactly one skill, so per-skill commits keep every split gated; a phase-bundled commit exempts itself by construction. The owner commits; the agent stages and describes. |

## The work

### Phase 0: lint groundwork (built 2026-08-30)

Teach `scripts/lint.sh` the satellite shape before any split lands, per G2 and G3. Cross-file `](modes/<mode>.md)` links from a `SKILL.md` must resolve to a real file (error). Every `.md` under a skill directory gets the anchor and step-ref checks, which also brings `gitkit/stacks.md` under lint for the first time. The closing-section warning treats a skill with a `modes/` directory as split: it passes when the root or every `modes/*.md` carries a closing section. The wiki mode-parity check needs no change, because backticked mode names stay in each root's mode-selection section. Done when `make lint` passes on a scratch branch containing one hand-made `modes/` satellite and fails when the pointer target is missing or a satellite anchor is broken.

### Phase 1: issuekit (built 2026-08-30)

Move the five mode bodies (`create`, `start`, `close`, `sync`, `triage`) to `skills/issuekit/modes/`. Root keeps preflight, title convention, lifecycle labels, priority labels, the shared comment action, and five pointers. Done when the root is under ~20 KB, `make lint` passes, and a dry read of each mode file contains every step its root section held before.

### Phase 2: wikikit (built 2026-08-30)

Extract the `publish` mode with its embedded workflow file first; then `init`, `update`, `audit`. Root keeps doc-set location, the doc map, the page vocabulary, the provenance stamp rule, grounding, and writing standards. Same completion gate as Phase 1.

### Phase 3: mergekit, ideakit, tutorkit (built 2026-08-30)

Same shape. mergekit's root keeps the never-merge-automatically guard and the gitkit boundary. ideakit's root keeps the repo layout, the router rules, and the saving-is-a-demand rule. tutorkit's root keeps the learning-repo layout, the router, the spacing schedule, and grading. Done per skill on the Phase 1 gate.

### Phase 4: partial extractions (built 2026-08-30)

- uikit: move the stack layer (Tailwind v4, shadcn/ui) to `skills/uikit/stack.md`, pointed to only when the project uses that stack. The anti-slop catalog stays inline.
- promptkit: move the worked `task` run to `skills/promptkit/worked-example.md`. The slop catalog stays inline.

Done when both roots shrink by their extracted block and lint passes.

### Phase 5: convention write-back (built 2026-08-30)

Record the outcome in `AGENTS.md`: one paragraph under the information hierarchy naming the `modes/` layout, the pointer form, and the branch test as the gate, so the next skill author splits (or refuses to) by rule rather than by taste. Update `docs/wiki/` pages for every touched skill in their phases, not here. Done when `AGENTS.md` states the layout and `make lint` is green repo-wide.

## Non-goals

- No split of statuskit or afkkit, and no split of any skill at or under ~24 KB.
- No prose rewrite while moving. A split is a move, and mixing it with editing hides regressions in the diff. Prune passes come separately.
- No change to descriptions, triggers, or mode behavior. A user-visible behavior change means the split leaked.
