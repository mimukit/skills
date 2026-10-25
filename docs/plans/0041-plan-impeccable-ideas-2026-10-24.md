# Plan: Impeccable ideas for uikit and the eval loop

## Context

[0003](../research/0003-research-impeccable-2026-10-24.md) read pbakaus/impeccable in depth and ranked five ideas for this collection. The owner picked four of them on 2026-10-24: a deterministic detector pass in uikit `audit` (idea 1), browser surfaces on uikit's accessibility floor (idea 2), a `docs` surface in uikit's design read (idea 4), and an eval runner that checks triggering and mode loading across models (idea 5). Idea 3, a fresh-context pre-flight, is out.

The goal behind the request has two halves. uikit should catch more of the AI-design tells that ship today, and a skill edit should no longer be able to break its own triggering or mode loading without anyone noticing. Every check in uikit is the agent reading its own output; nothing deterministic backs it. The trigger cases in `skills/motionkit/evals/triggers.md` and `skills/seokit/evals/triggers.md` are run by hand, one fresh session per prompt, and `skillkit`'s Live test step asks the owner to do the same.

Facts checked for this plan:

- `npx impeccable detect` installs no skills and no hooks. The npm shim (`cli/bin/cli.js`) finds or downloads the engine binary into `~/.impeccable/bin/<version>/` and runs it. `detect` dispatches to the detect crate alone; `install`, `link`, `update` and `check` go to a separate crate. A plain `detect` reads files and probes `localhost` for a dev server with a 2 s deadline. It writes only when `ignores add` runs, and then into `.impeccable/config*.json` and `.git/info/exclude`.
- `~/.impeccable/bin/0.1.5/` already exists on this box from 2026-10-17. No Impeccable skill is installed in `~/.claude/skills`, `~/.agents/skills` or `~/.codex/skills`, and no settings file names it.
- `claude` is on PATH through mise. Codex is too, but this plan drives Claude only.
- `~/projects/saasaloy/modules/` holds 99 `.tsx` files.

Target: open, no baseline, for both measured halves. Phase 1 sets the detector's baseline (how many real findings it adds over uikit alone). The first eval run in Phase 5 sets the triggering baseline. The floor and the docs surface are text changes to uikit, so their check is a `make lint` pass plus the listed content.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Which ideas | 1, 2, 4 and 5 from 0003. Idea 3 is dropped. |
| Gate on idea 1 | A comparison spike on saasaloy runs first. The detector pass ships only when the owner marks it a go from the spike's results. |
| When uikit runs the detector | Only when the CLI is already installed: `impeccable` on PATH or `node_modules/.bin/impeccable` in the project. uikit never runs `npx impeccable`, never runs `install`, `update`, `hooks` or `ignores add`, and never installs the CLI. This matches uikit's existing "never install a browser" rule. The spike in Phase 1 may use `npx`, because the owner runs it attended. Chosen as the recommended default after the owner confirmed the no-skills point; the owner may redirect it. |
| Where the detector runs | uikit `audit` only, as part of the Sweep step. reviewkit stays out: it has no visual seam today, and uikit's audit already sits beside it as the visual half. |
| Detector evidence | Each detector finding keeps its rule id and carries a "detector" label, the same pattern as motionkit's "recorded" label. A finding the catalog already reports at the same `file:line` merges into one line with both labels. The coverage line states whether the detector ran, and if not, why. |
| Browser surfaces on the floor | One floor item lists the six surfaces with their positive target: text selection, the caret, scrollbars, focus rings, link underline offset, and `tabular-nums` on numbers in tables. Each takes its color from the palette, not the browser default. |
| The `docs` surface | `surface` takes `product`, `marketing` or `docs`. A new scope tag **D** joins **P** and **M**. **B** keeps its meaning of every surface. A row can carry two tags (`MD`). Retagging adds no rows, so the ~30-entry cap holds; a docs-only ban enters only by displacing a row. |
| Credit | uikit's Notes gain one credit line for the floor's browser surfaces and the detector pass, naming pbakaus/impeccable (Apache-2.0) and the commit read, `9368675`. The text is authored from scratch, so no NOTICE is owed. |
| Eval runner shape | `scripts/evals.sh`, reached through `make evals SKILL=<name>`, with an optional `MODEL=` to run one model. It reads `skills/<name>/evals/triggers.md`, runs each prompt once per model with `claude -p` and stream-json output in a throwaway temp directory, and prints one table. It writes no file in the repo. |
| What the runner checks | "Fired": the run's tool calls include a Skill call naming the skill. "Loaded": for a case under a mode subheading, the run reads that skill's `modes/<mode>.md`. A near-miss passes when the skill does not fire. |
| Models | Claude only for this plan: the `haiku`, `sonnet` and `opus` aliases. Codex and Gemini are a later plan. |
| Tool limits during an eval | Each run gets a turn cap and an allowlist of read-only tools plus Skill, so a prompt such as "animate this dropdown" cannot edit anything. The exact flags come from `claude --help` at build time. |
| Runner cost | `make evals` is opt-in and never part of `make lint` or CI, because every case spends model tokens. |
| Trigger files | uikit gains `skills/uikit/evals/triggers.md` in the same format as motionkit's, so the runner covers the skill this plan edits. |
| skillkit | Its Live test step gains one line: when the collection provides an eval runner (check the Makefile), run it for the trigger cases instead of the manual loop. The line names no repo path, so the public skill stays portable. |
| Test approach | No new test framework. Each phase checks with `make lint`, plus a live run where the phase says so. The eval runner is itself the new kind of test; its runner is `claude -p`, as above. |

## Approach

The work reuses what the collection already has. uikit's catalog, floor and `surface` word (`skills/uikit/SKILL.md`, "The design read", "The anti-slop catalog", "The accessibility floor") take the new content. motionkit's evidence labels give the detector findings their shape. The trigger-case files from skillkit's Draft step give the runner its input, and `make link` already puts a repo skill live under its real name. `scripts/lib.sh` holds the shared shell helpers the new script should use.

Rejected, one line each. Running the detector inside the uikit `build` pre-flight as well: it adds a binary call to every build before the spike shows the detector earns it; it stays an open question. A Node or Python eval harness like Impeccable's `tests/skill-behavior/`: the repo has only shell scripts behind make, and a shell runner keeps it that way.

### Phase 1: Detector comparison spike on saasaloy
Attended: the owner judges each detector-only finding as real or noise, and gives the go or no-go for Phase 2.

- Pick the saasaloy paths in scope, proposed as the UI files under `modules/billing` and `modules/admin`.
- Run `uikit audit` on those paths and save the report text.
- Run `npx impeccable detect --json` on the same paths and save the JSON outside the repo.
- Match the two lists by `file:line` and by tell, and count three groups: found by both, uikit only, detector only.
- Write the result into 0003's "Open question" section as a table, with each detector-only finding marked real or noise.

Done when: 0003 holds the three counts for the named paths, every detector-only finding carries the owner's real-or-noise mark, and a go or no-go line for Phase 2 follows the table; `git status --porcelain` in `~/projects/saasaloy` shows no file added by the spike.

### Phase 2: Detector pass in uikit audit
Attended: the owner installs the CLI on the box (`npm i -g impeccable`, then `devaloy update`), and only after a go in Phase 1.

- In `audit`'s Sweep step, check for `impeccable` on PATH or in `node_modules/.bin`, and run `impeccable detect --json` on the target paths when found.
- Read exit `0` and `2` as a completed scan, and exit `1` as a target it could not scan, named in the report.
- Merge, label and count the findings per the Detector evidence decision.
- State the forbidden subcommands (`install`, `update`, `hooks`, `ignores add`) and the no-npx rule once, as a guard with its positive target.
- Add the credit line to Notes.

Done when: `make lint` passes; one `uikit audit` on the Phase 1 saasaloy paths prints at least one line with the "detector" label and a coverage line saying the detector ran; the same audit with the CLI off PATH prints a coverage line saying the detector was not available, and no detector lines.

### Phase 3: Browser surfaces on the floor
- Add the floor item from the Browser surfaces decision to "The accessibility floor".
- Add the credit line to Notes if Phase 2 did not run.

Done when: `make lint` passes, and the floor names all six surfaces, each with the target it should take.

### Phase 4: The docs surface
- Add `docs` to the `surface` row of the design read table, with the audience it fits (a reader with a question).
- Add **D** to the scope-tag legend, and retag every catalog row that applies to docs pages.
- Update every sentence that names the two surfaces: the Sweep step, the pre-flight's catalog filter, and the surface row's reason.
- Grep the collection for other places that name uikit's `product` and `marketing` surfaces, and update each.

Done when: `make lint` passes; `grep -n "marketing" skills/uikit/SKILL.md` shows no sentence that lists the surfaces without `docs`; every catalog row carries one of P, M, D, B or a two-letter combination; the row count is still 31 or fewer.

### Phase 5: Eval runner
- Write `scripts/evals.sh` per the Eval runner decisions, and add an `evals` target with a help line to the `Makefile`.
- Parse both sections of the trigger file and the mode subheadings in the format `skills/motionkit/evals/triggers.md` uses; check that `skills/seokit/evals/triggers.md` parses the same way.
- Print a header naming the model, the date and the skills installed at run time, because a competing skill changes the result.
- Add `skills/uikit/evals/triggers.md`, with should-fire cases for `build` and `audit` and near-misses that belong to designkit, motionkit and reviewkit.
- Add the skillkit Live test line.
- Run the runner on motionkit, seokit and uikit, and write the pass counts per model into this plan's Context as the baseline.

Done when: `make evals SKILL=motionkit`, `SKILL=seokit` and `SKILL=uikit` each print one row per case per model for `haiku`, `sonnet` and `opus`, every row shows fired or not fired, every mode case also shows loaded or not loaded; `git status --porcelain` after the runs lists only the files this phase wrote; the baseline counts are in Context; `make lint` passes.

## Open questions

- Severity for a detector-only finding. Does it take 🟡 by default, or map from the rule to the catalog's 🔴, 🟡 and 🟢?
- Should uikit's `build` pre-flight also run the detector once Phase 1 shows a go?
- The saasaloy paths for the spike. `modules/billing` and `modules/admin` are a guess, not a reviewed choice.
- The detector scans source files here. A rendered-URL scan needs a running dev server, and uikit never starts one. Is a source-only scan enough to judge the go?
- Which catalog rows apply to docs pages, and does a docs-only ban earn a place by displacing a current row?
- Does an allowlist passed to `claude -p` hold when the box's default permission mode is `bypassPermissions`? Phase 5 must prove that before the first run.
- One run per prompt per model, or three, to see flaky triggering? Three triples the cost.
- The eval target. grillkit sets it after the first baseline lands.
- Installed-only is the default for the detector because the owner's answer addressed skills, not the npx question. Confirm it, or switch uikit to allow `npx`.

## Non-goals

- Installing the Impeccable skill, plugin or hooks anywhere, on this box or in any project.
- A detector pass in reviewkit.
- Idea 3, the fresh-context pre-flight.
- Codex or Gemini in the eval runner.
- Running evals in `make lint` or CI.
- Adding the Impeccable CLI to the devaloy image. That is a change in the devaloy repo, outside this plan.
- Changing motionkit's rules to match Impeccable's motion guidance.
