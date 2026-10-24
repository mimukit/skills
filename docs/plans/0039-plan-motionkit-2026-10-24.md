# Plan: motionkit

Grilled: 2026-10-24

## Context

Agents pick the wrong ingredients for UI motion. They put `ease-in` on an entrance, scale a popover up from `scale(0)`, animate a toast with keyframes that cannot be interrupted, write `transition: all`, and animate a command palette that people open fifty times a day. None of it fails a test, and every one of those choices makes an interface feel slower or cheaper than it is. The collection has no skill for this. `uikit` carries three lines on motion (`skills/uikit/SKILL.md:109` and `:247`), which say to justify motion in one sentence, to animate only `transform` and `opacity`, and to honor `prefers-reduced-motion`. Nothing covers easing, duration, springs, interruption, exits, dropped frames, or a review of motion code.

Emil Kowalski's [emilkowalski/skills](https://github.com/emilkowalski/skills) (MIT, read at commit `2d22863`, 2026-10-11) has the best public material on this, spread across seven web-motion skills. motionkit is this collection's version of that material, authored from scratch under the kit conventions and credited to the source. It is one public skill with four modes: `build` makes one animation, `review` judges motion in a diff, `audit` sweeps a codebase for motion fixes and missing motion, and `perf` finds why an animation drops frames. A fifth, file-less branch answers "what is it called when…" from the shared glossary.

It is a separate skill and not a `uikit` mode. `uikit`'s shared material (the precedence ladder, the design read, the signature, the anti-slop catalog) is not used by any motion branch, motion has its own trigger vocabulary (easing, spring, jank, "feels off"), and `perf` is profiling work rather than taste. `uikit build` still decides whether motion fits the design read. motionkit decides how the motion moves.

Success: every mode fires on its trigger phrases and none of `uikit`'s phrases fire motionkit; one live run per mode on a real repo with motion produces the outcome the mode promises; `make lint` passes.

Target: every trigger case in `skills/motionkit/evals/triggers.md` returns the expected fired or not-fired result, and one live run per mode passes on `~/projects/brainaloy` (its motion lives in `apps/web`: 22 `@keyframes`, 3 `transition-all`, 13 `ease-in-out`). Size target, proposed: the whole skill stays at or under 9,000 words, with the root at or under 3,000 (proposed; baseline about 14,200 words across the six upstream motion skills kept below and their satellites, excluding `emil-design-eng`, by `wc -w` at `2d22863`).

## Source analysis

Seven upstream skills were read (structure in full, bodies where a decision depends on them).

| Source | Words | Keep | Drop |
|--------|-------|------|------|
| `animate` + `RECIPES.md` | 3,000 | The build order: should it animate, purpose, cheapest tool, properties, curve and duration or spring, interruption and exit, reduced motion and pointer gating. "Make the call, give the reason in one line, write the code", never a menu. Extend the project's tokens, never fork them. The component recipes (button press, dropdown, tooltip, modal, drawer, toast, accordion, stagger, hold to confirm, tab indicator, scroll reveal, drag to dismiss, crossfade masking, no-library fallback). | The persona framing ("you are a senior design engineer"). The cross-references to sibling upstream skills. |
| `review-animations` + `STANDARDS.md` | 2,550 | The standards body: the frequency table, easing, duration, physicality, springs, interruptibility, asymmetric timing, performance, transforms and `clip-path`, gestures, masking, stagger, accessibility, cohesion. Default to flagging, so approval is earned. The remedy order (remove the motion, then fix the ingredient, then add). Findings table plus verdict. | The "Emil's philosophy" branding as the authority; ours cites the reason behind each rule instead. |
| `improve-animations` + `AUDIT.md` + `PLAN-TEMPLATE.md` | 2,750 | The recon-first sweep, the eight audit lenses, and "vet before you rank". | The per-fix plan files written for other agents. Our audit reports in chat and crowns one fix (settled below). |
| `find-animation-opportunities` | 1,500 | The four-gate test for adding motion (frequency, purpose, speed, function), the hunt list, and the required "rejected candidates" section, which keeps the search from adding motion everywhere. | Its separate existence. It becomes the "missing motion" half of `audit`. |
| `animation-performance` | 2,200 | The symptom table, the frame budget, the property cost ladder, CSS vs WAAPI vs rAF, React state per frame, inherited CSS variables, blur cost, `will-change` as the last step. Name the cause before changing code. Label every finding "from code" or "needs a recording". Report, then fix on ask. | Nothing material. |
| `animation-vocabulary` | 2,200 | The glossary of effect names by group, for naming an effect precisely in output and for "what is it called" lookups. | The standalone skill. It becomes a shared satellite. |
| `emil-design-eng` | 3,900 | Nothing new. Its animation sections repeat the standards above. | The general design advice, which `uikit` covers. |

The upstream set states one body of standards (frequency, easing, duration, springs, interruption, accessibility) in five places. motionkit states it once, in the root, as **the motion standard**, and every mode applies it. That single source is most of the size saving.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Separate skill or `uikit` mode | Separate skill. No shared material, a distinct trigger vocabulary, and four branches of its own. |
| Name | `motionkit`, kept without a namekit run. The neighbors are `amizenda/motion-kit` (an agent skill, 0 stars, created 2026-10-05) and Motion's official `/motion` skill in `motiondivision/ai-kit` (57 stars), and neither is the well-known tool the collision rule names. "Motion" is the word people search for. |
| Visibility | Public, `metadata.internal: false`. Portable: no repo-relative links, conventions inlined. |
| Provenance | "My version of" `emilkowalski/skills`, authored from scratch. The Notes section credits Emil Kowalski, links the repo, and records the upstream commit `2d22863`, so a later refresh can diff against it. No upstream prose is copied. |
| Platforms | Web only: CSS transitions and keyframes, WAAPI, Motion (formerly Framer Motion), `tw-animate-css` and Tailwind utilities, and rAF as the fallback. |
| Modes | `build`, `review`, `audit`, `perf`, plus a file-less lookup branch. `audit` merges `improve-animations` and `find-animation-opportunities`. The lookup branch triggers on "what's it called when an element…", answers from `vocabulary.md`, writes nothing, and states that there is no next step. |
| Mode routing | Split by verb. "Fix", "add", "make", and "animate" run `build`. "Feels off", "check", "review", and an ask with no verb run `review`. "Janky", "stutters", and "drops frames" run `perf`. "Audit", "what should animate", and "make the app feel alive" run `audit`. |
| Layout | Routing root plus `modes/<mode>.md`, the collection's mode-satellite shape. Root: mode selection, guards, the motion standard, stack detection, credits. `recipes.md` is read by `build` only. `vocabulary.md` is read by the lookup branch and by any mode that names an effect. Trigger cases go in `evals/triggers.md`. |
| Mode outputs | `build` writes code. `review` writes nothing and returns a findings table and a verdict. `audit` writes nothing, ranks fixes and missing motion with rejected candidates, crowns one, and routes it to `build`. `perf` writes nothing until asked, then applies the fixes it named. |
| Evidence | Every finding in `review`, `audit`, and `perf` cites `file:line` and is labeled "from code", "recorded", or "needs a recording". When `playwright-cli` is present, `review` and `perf` may slow the page's animations and capture frames, labeled "recorded". The run never depends on a browser. Proof for a pull request stays with verifykit. |
| Loop integration | Pointer only. `uikit`'s motion line keeps its one-line conclusion (`transform` and `opacity`, reduced motion) and names **motionkit** when it is installed. `uikit audit`'s "extra animation" tell stays in `uikit` and routes the finding to `motionkit audit` when installed, so `uikit` flags too much motion and motionkit judges it. `implementkit` is unchanged, because it already delegates UI to `uikit`, which carries the pointer. `reviewkit` gets no pointer, because it runs often and "review the animations" fires motionkit on its own trigger. Nothing invokes motionkit automatically. |
| Tools | `allowed-tools: Read, Write, Edit, Grep, Glob, Bash, AskUserQuestion`. Bash covers the stack detection and the optional browser recording. |
| Collection wiring | `README.md` skills table row, `skills.sh.json` "Building" group beside `uikit`, `docs/wiki/index.md`, `make cheatsheet`, and a `motionkit` paragraph in `docs/wiki/workflow.md` under the `uikit` section. |
| Test approach | Trigger cases per skillkit (two or three should-fire prompts per mode, plus near-misses from `uikit`, `reviewkit`, and `debugkit`), then one live run per mode in a fresh session on `~/projects/brainaloy`. No new test runner. |
| Use of upstream content | Carry the facts and values (curves, durations, gates, cause order). Rewrite all prose and tables in this skill's own structure. |
| Refresh policy | Frozen at `2d22863`. A refresh runs only on the owner's ask, as a diff of upstream against that commit. |
| Builder | implementkit builds Phases 1 to 6 from this plan in an attended session. skillkit checks the result in Phase 8. |
| Build spec | AGENTS.md plus skillkit's Quality bar, Portability, and Conventions sections. implementkit reads them as input before Phase 1, because it does not carry the kit conventions itself. |
| Commit | The owner approves one commit per phase during the build, each a Conventional Commits subject such as `feat(motionkit): add the motion standard root`. No push until Phase 8 passes, because a pushed public skill appears on skills.sh untested. |

## Approach

implementkit builds the draft from this plan, with skillkit's rules as its spec, and commits each phase. The owner then reviews the draft, and skillkit's maintain check plus a live test close it. The root carries the motion standard because every mode applies it; mode files carry only their own procedure and hand-off. `recipes.md` is the only satellite that is large and single-branch, so it sits behind a pointer in `build`.

Rejected alternatives, one line each:

- **A `motion` mode in `uikit`.** It would force a root-plus-modes split of a working 4,400-word skill, and every motion run would load the anti-slop material it does not use.
- **Install the upstream skills as they are.** Cheapest today, but it adds up to seven always-loaded descriptions, none of which follow the kit conventions or hand off to the rest of the loop.
- **Motion reference in `skills/uikit/motion.md`.** Cheapest option, but it has no review mode and no frame-drop mode, and those are the parts worth taking.

### Phase 1: Root and the motion standard
Write `skills/motionkit/SKILL.md`: frontmatter, "When this fires" with one trigger per mode and the default mode for an ambiguous ask, the guards (web only; `review` and `audit` write nothing), stack detection (which motion tools and tokens the project already uses), and **the motion standard** as in-file reference: the frequency gate, purpose, easing, duration, springs, physicality and origin, interruptibility, asymmetric timing, property cost, `clip-path` and transforms, gestures, stagger, reduced motion and pointer gating, cohesion with tokens. Add one pointer per mode in the trigger-carrying form, the lookup branch pointer to `vocabulary.md`, the verb routing, and the Notes section with the credit and the upstream commit.
Done when: `make lint` reports no error for `skills/motionkit`, the description is under 1,024 characters with "Use when" inside the first 300, and every standard topic in the list above has a heading in the root.

### Phase 2: Build mode and recipes
Write `modes/build.md` (the build order, each step ending on a completion criterion, and its hand-off) and `recipes.md` (the component recipes from the source analysis, each giving the curve, duration, properties, and reduced-motion behavior).
Done when: `make lint` passes, and every recipe names its curve, duration, properties, and reduced-motion behavior.

### Phase 3: Review and audit modes
Write `modes/review.md` (target resolution from a diff or a path, flag by default, the remedy order, findings table, verdict, hand-off) and `modes/audit.md` (recon, the fix lenses, the four-gate test for missing motion, the rejected-candidates section, rank, crown one, route to `build`).
Done when: `make lint` passes, and both modes state that they write nothing, both cite `file:line` with an evidence label, and `audit`'s hand-off crowns exactly one item.

### Phase 4: Perf mode
Write `modes/perf.md`: list what animates and its driver, diagnose down the ordered cause list, report each finding with cause, before, after, and evidence label, then apply fixes only when asked.
Done when: `make lint` passes, and every cause in the symptom table maps to a named fix.

### Phase 5: Vocabulary and trigger cases
Write `vocabulary.md` (effect names by group, each with a one-line definition) and `evals/triggers.md` (should-fire and should-not-fire lists per mode).
Done when: every mode and the lookup branch has at least two should-fire and two should-not-fire prompts, and the near-misses include at least one prompt each for `uikit`, `reviewkit`, and `debugkit`.

### Phase 6: Collection wiring and the uikit pointer
Add `motionkit` to the `README.md` skills table, the `skills.sh.json` "Building" group, and `docs/wiki/index.md`, run `make cheatsheet`, add the `workflow.md` paragraph, and change `skills/uikit/SKILL.md:109` and `:247` to keep the conclusion and name **motionkit** when installed, and add the routing clause to `uikit audit`'s extra-animation tell.
Done when: `make lint` passes with no new warning, `git diff docs/wiki/cheatsheet.md` shows the motionkit line, and `wc -w` over `skills/motionkit/**/*.md` is at or under 9,000.

### Phase 7: Draft review
Attended: the owner reads the draft and approves it in words.
Read `skills/motionkit/` against the build spec. Fix each point the owner raises, in a commit per fix round.
Done when: the owner has approved the draft in words.

### Phase 8: skillkit check and live test
Attended: the owner runs the fresh sessions and judges each output.
Run `/skillkit` with "I changed motionkit, check it". Dev-link the skill with `make link`. Run every prompt in `evals/triggers.md` in a fresh session and record fired or not fired. Run each mode and the lookup branch once on `~/projects/brainaloy`. Unlink when done.
Done when: every trigger case has a recorded result that matches its list; the five live runs produced their promised outcomes (code for `build`, a findings table and verdict for `review`, one crowned item for `audit`, a cause per finding for `perf`, a named effect for the lookup); every mismatch led to an agreed edit; `make lint` reports 0 errors.

## Open questions

None. Every question from the draft was settled in the grill on 2026-10-24.

## Non-goals

- React Native, Expo, Reanimated, and native platforms (upstream `animate-expo`, `mobile-native`, `write-swift`, `apple-design`).
- General UI taste and design advice, which `uikit` owns (upstream `emil-design-eng`).
- Showpiece scroll scenes, WebGL, canvas, and GSAP timelines for marketing pages.
- Motion graphics and video.
- Library-specific guides (upstream `ask-sonner`, `pick-ui-library`) and worst-case data testing (upstream `break-ui`).
- Any change to `implementkit`.
