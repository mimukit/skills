# Plan: Taste Skill ideas for uikit, motionkit and the eval loop

Review: pending

## Context

[0004](../research/0004-research-taste-skill-2026-10-24.md) read Leonxlnx/taste-skill at `6010f91` (v2.1.4) and ranked six ideas for this collection. This plan takes all six as drafted. The owner reviews and grills it later, so every choice below is a recommended default, not a confirmed one.

The goal behind the request has three parts. uikit should produce a signature that belongs to the subject and not to its category, and it should catch the frame and dashboard faults that a written pre-flight misses. motionkit should catch motion that hides content. The collection should be able to tell whether a design skill makes better output than no skill at all, which no kit can tell today. Taste Skill's own blind test (0004, "Its own test result") is the warning here: a skill can remove every tell and still lose to the baseline.

Facts checked for this plan:

- [0041](./0041-plan-impeccable-ideas-2026-10-24.md) is an open plan with no phase built. It edits the same uikit sections (the design read `surface` row, the catalog scope tags, the floor, Notes) and plans `scripts/evals.sh` behind `make evals` in its Phase 5. Neither the script nor the target exists yet.
- uikit's signature section (`skills/uikit/SKILL.md`, "The signature") has no competitor test. 0002 row 19 proposed one; it has not landed.
- uikit's rung 3 row names "the product's materials, vocabulary, and artifacts" as a principle, with no counted list and no completion criterion.
- motionkit's standard (`skills/motionkit/SKILL.md`, "The motion standard") has no rule about content that stays hidden when a script fails, a hidden start state outside `prefers-reduced-motion: no-preference`, or a preloader. Its review mode's escalate list (`modes/review.md`, "Judge each animation against the standard") has none of them either.
- uikit's pixel pass ("The pixel pass, opt-in") reads facts with an evaluate call first, but names no specific measurement.
- uikit's product catalog covers empty, loading and error states and icon buttons. It says nothing about charts, KPIs or table figures.
- `skills/motionkit/evals/triggers.md` is the only eval format in the collection, and it tests firing, not output quality.
- `playwright-cli` and Chromium are present on this box (`~/.cache/ms-playwright/chromium-1247`).

Targets:

- Ideas 1, 2, 3 and 5 are text changes to skills. Their check is a `make lint` pass plus the listed content in each phase.
- Idea 4: `Target: open, no baseline`. Phase 4 runs the three measurements on one real page, which gives the first numbers.
- Idea 6: `Target: open, no baseline`. The first A/B run in Phase 6 sets the baseline for uikit against no skill.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Which ideas | All six from 0004, as ranked there. |
| Order against 0041 | This plan lands after 0041's uikit phases where both touch one section. Phase 6 needs 0041's Phase 5 runner and waits for it. Phases 1 to 5 do not depend on 0041. |
| Competitor test (idea 1) | One added check in "The signature": put the nearest real competitor into the signature sentence; if the sentence still holds, the signature belongs to the category, so pick another. The pre-flight's "two signature checks" become three. At rungs 1 and 2 the competitor is the nearest product in the same category, named in the design read. |
| Subject inventory (idea 2) | At rung 3 only, the Build mode's "State the design read" step first lists 8 to 12 things that belong to this subject and to no competitor (its materials, vocabulary, artifacts, constraints, places, numbers). The signature names the item it came from. The list stays in the reply, not in a file. The step's completion criterion gains "the signature names its inventory item". Rung 4 keeps the stated-default path, because the subject is opaque there by definition. |
| Design read line | The line gains no sixth word. The signature value names its inventory item in parentheses, so the five-word shape and the hand-off repeat stay as they are. |
| First-frame rules (idea 3) | A new heading in motionkit's standard, "First frame and failure", placed after "Reduced motion and pointer gating". Four rules, each with its positive target: content above the fold is painted on the first frame; a hidden start state lives inside `prefers-reduced-motion: no-preference`; content is visible when the script fails or never runs; a loading screen or preloader covers no content that is already available. `build` follows it and `review` escalates a break on sight, with the heading cited. |
| Scope of idea 3 | It applies to reveals and entrances in product and marketing UI. motionkit's "scroll-driven marketing scenes are out of scope" line stays. |
| Frame measurements (idea 4) | When the pixel pass runs, it measures three facts with an evaluate call before any image: the line count of each `h1` and `h2` at 1440, 768 and 390 px; the left and right outer margins of the main content box; and any vertical gap taller than half the viewport with no content. Each fact gets a pass or a finding with the number. The pass stays opt-in, so the measurements run only on an explicit ask. |
| Thresholds for idea 4 | Two lines at most for a headline, margins equal within 8 px, and no empty gap over 50% of the viewport height. These come from Taste Skill's house rules and are proposed values; Phase 4 checks them on a real page. |
| Dashboard layer (idea 5) | A new satellite `skills/uikit/dashboards.md`, reached the way `mobile.md` is: surface `product` with charts, KPIs or data tables → read it, then apply it. It holds rules only, not a catalog, so the ~30-row catalog cap does not apply. Proposed rules: right-aligned tabular figures in numeric columns; one hue per chart, neutrals for the rest; no sparkline or tinted icon tile on each KPI; no status colour on a zero or undefined change; sentence-case table headers; a KPI value that reads as data, not as a hero figure. Each rule is checkable without rendering. |
| Credit | uikit's and motionkit's Notes each gain one credit line naming Leonxlnx/taste-skill (MIT) at `6010f91`. The text is authored from scratch. |
| Output A/B evals (idea 6) | A second eval kind beside trigger cases: `skills/<name>/evals/briefs.md` lists briefs, each with an expected outcome. The runner builds each brief twice in throwaway directories, once with the skill linked and once with no design skill, and a third run judges the two results blind from screenshots. The judge sees folders `A` and `B` in a random order, recorded only in the runner's output. |
| Runner for idea 6 | An `evals-ab` target that reuses 0041's `scripts/evals.sh` helpers, so the collection keeps one eval script. It writes no file in the repo, and it is opt-in and never part of `make lint` or CI. |
| Judge rubric | The judge scores design, usability, creativity and content on 1 to 10, with the weights 40, 30, 20, 10, and names the winner with one reason. The rubric is authored from scratch, with the weights credited to Taste Skill's `critique.md`. |
| First A/B subject | uikit, with three briefs: one marketing page at rung 3, one product settings screen at rung 2 in a fixture with shipped components, and one dashboard that exercises `dashboards.md`. |
| Test approach | No new test framework. Phases 1 to 5 check with `make lint` and the listed content. Phase 4 adds one live pixel-pass run. Phase 6's runner is itself the new kind of test; it drives `claude -p` as 0041 decides, and screenshots come from `playwright-cli`. |

## Approach

The work adds to existing structure and invents no new mechanism. uikit's signature section, rung 3 row, Build mode steps, pixel pass and the `mobile.md` pointer pattern take ideas 1, 2, 4 and 5. motionkit's standard and review escalate list take idea 3. 0041's eval runner and the trigger-case format take idea 6, and `make link` puts the repo copy of a skill live under its real name for the A/B runs.

Rejected, one line each. Adding Taste Skill's inspector as a dependency of uikit: it encodes house rules that override a project's system, and the open question in 0004 has not been run. Putting the dashboard rules into the catalog: it would break the ~30-row cap for one surface's needs. A separate eval script for A/B runs: two scripts would duplicate the run, link and parse logic.

### Phase 1: Competitor test in the uikit signature
- Add the competitor test to "The signature", with one worked example in the existing style.
- Change the pre-flight's "two signature checks" to three, and name the competitor check.
- Add the uikit credit line to Notes.

Done when: `make lint` passes; `grep -n "competitor" skills/uikit/SKILL.md` shows the test in "The signature" and in "Self-critique"; the pre-flight lists three signature checks.

### Phase 2: Subject inventory at rung 3
- Add the inventory to the Build mode's "State the design read" step for rung 3, per the Subject inventory decision.
- Extend that step's completion criterion with the inventory item.
- Update the rung 3 worked example (the letterpress print shop) so its signature names an inventory item.

Done when: `make lint` passes; the "State the design read" step names the 8 to 12 item count and the rung it applies to; its "This step is done when" line names the inventory item; the rung 4 path is unchanged.

### Phase 3: First-frame rules in motionkit
- Add the "First frame and failure" heading to the motion standard, per the First-frame rules decision.
- Add one escalate bullet to `modes/review.md` "Judge each animation against the standard" that cites the new heading.
- Add the motionkit credit line to Notes.
- Add one should-fire review case to `skills/motionkit/evals/triggers.md`, such as "The hero stays blank until the script loads".

Done when: `make lint` passes, including the anchor check for the new heading link; the standard has the four rules, each with a positive target; the review escalate list cites the heading.

### Phase 4: Frame measurements in the uikit pixel pass
- Add the three measurements to "The pixel pass, opt-in", per the Frame measurements decision, with the proposed thresholds.
- State the result shape: one pass or one finding per fact, with the measured number.
- Run the pixel pass once on a real page on this box and record the three results in this plan's Context.

Done when: `make lint` passes; one uikit pixel pass on a named page prints the headline line counts at all three widths, both margins in px, and the largest empty gap in px; those numbers are in Context.

### Phase 5: Dashboard layer for uikit
- Write `skills/uikit/dashboards.md` with the rules from the Dashboard layer decision, each as a rule with its target.
- Add "The dashboard layer" section to `SKILL.md` with the pointer in the trigger-carrying form, beside "The mobile layer".
- Add the layer to the Build step's floor line and to the audit Sweep step, so both apply it when the surface has charts, KPIs or data tables.

Done when: `make lint` passes and resolves the new pointer; the Sweep step's completion criterion names the dashboard layer; every rule in `dashboards.md` is checkable from source.

### Phase 6: Output A/B evals
Attended: the owner approves the token cost before the first run, and reads the judge's reasons for the baseline.

- Wait until 0041's Phase 5 runner is built. Stop here if it is not.
- Add the `evals-ab` target and its help line, reusing the runner's helpers, per the Runner for idea 6 decision.
- Define the `briefs.md` format and write `skills/uikit/evals/briefs.md` with the three briefs from the First A/B subject decision.
- Add a small fixture for the rung 2 brief: a scratch app with a Button, an Input and a Card, created in the throwaway directory at run time.
- Run uikit against no skill once per brief and record wins, losses and mean scores in this plan's Context as the baseline.
- Add one line to skillkit's Live test step: when the collection provides an A/B eval target, run it for skills that produce visible output.

Done when: `make evals-ab SKILL=uikit` prints one row per brief with both scores, the winner and the judge's reason; `git status --porcelain` after the run lists only the files this phase wrote; the baseline is in Context; `make lint` passes.

## Open questions

- The competitor at rungs 1 and 2. A settings screen inside an existing product may have no clear competitor. Does the test apply there, or only at rungs 3 and 4?
- Does the 8 to 12 inventory slow uikit inside unattended runs (afkkit) for no gain on product screens? It applies at rung 3 only, but most product work in this repo sits at rungs 1 and 2.
- Are 8 px of margin drift and 50% of the viewport the right thresholds for product UI, or only for marketing pages? Phase 4 gives one data point.
- Should the frame measurements run in `audit` as well as in the build pixel pass? `audit` is static today.
- Does `dashboards.md` belong in uikit, or does it cross into a chart skill's ground? The `dataviz` skill on this box covers chart colour and marks.
- One model judge per brief carries about half a point of noise by Taste Skill's own estimate. One run per brief, or three?
- Which model builds and which judges? The same model on both sides may favour its own defaults.
- The baseline arm has "no design skill". Does it still load the rest of the kits, or a clean skill set?
- How does the A/B runner stop a build from editing outside its temp directory under `bypassPermissions`? 0041 has the same question for trigger runs.
- The eval target for idea 6. grillkit sets it after the first baseline lands.

## Non-goals

- Installing Taste Skill, its plugins or its scripts anywhere.
- A dealt palette or type library in uikit.
- A motion floor (a minimum count of moving elements) in motionkit.
- House rules that override `DESIGN.md` or shipped components.
- Archival picture search and image credits.
- Scroll scenes, GSAP or Lenis in motionkit.
- A/B evals for skills other than uikit in this plan.
- Running the inspector comparison from 0004's open question. That is a separate spike.
