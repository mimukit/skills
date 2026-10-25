# Research: Taste Skill, and how it compares with the design kits

Source read on 2026-10-24 from a clone of [Leonxlnx/taste-skill](https://github.com/Leonxlnx/taste-skill) at commit `6010f91` (v2.1.4, 2026-10-20). Repo stats come from `gh api` on the same day. The kit side was checked against `skills/uikit`, `skills/motionkit` and `skills/designkit` in this repo at `3bb809b`. [0002](./0002-research-skill-ecosystem-2026-10-21.md) gave Taste Skill one row and [0003](./0003-research-impeccable-2026-10-24.md) read Impeccable, its nearest rival, in depth. This report reads Taste Skill the same way.

## What it is

Taste Skill is one Agent Skill, installed as `design-taste-frontend`, by Leonxlnx. It builds and reviews web pages and, since v2.1, app screens. The skill text tells the agent what to decide, and a set of Node scripts deals an art direction, finds real pictures and measures the result in a headless Chrome.

| Fact | Value |
|---|---|
| Stars / forks | 101,946 / 6,892 |
| Created | 2026-02-19 |
| Latest releases | v2.0.0 (2026-10-13), v2.1.0 to v2.1.4 (2026-10-18 to 2026-10-20) |
| License | MIT |
| Authorship | Leonxlnx 210 commits; next contributor 9 (`cursoragent`), then 5 |
| Harnesses | Any `npx skills` target, plus a Claude Code plugin and a Codex plugin |
| Skill text | `SKILL.md` 6,481 words; 11 reference files; about 56,000 words in total |
| Scripts | 5 entry scripts and 4 libraries, about 3,600 lines of plain Node 22, no npm dependencies |
| Data | `library/` holds 1.7 MB of JSON distilled from the studied sites |

The repo was a collection until last week. v2.1.1 and v2.1.3 moved the older skills out, so the repo now holds one skill. The commit history is almost all one author, and v2.1.2 fixed a frontmatter bug that had stopped the skill from loading in Claude Code at all.

## The ecosystem

"Ecosystem" here means one author's repos around the main skill. None of them is a dependency of `design-taste-frontend`.

| Repo | Stars | What it holds |
|---|---|---|
| `taste-skill` | 101,946 | `design-taste-frontend`, the one default skill |
| `taste-skill-classics` | 14 | The v1 styles: `high-end-visual-design`, `minimalist-ui`, `industrial-brutalist-ui`, `gpt-taste`, `stitch-design-taste`, v1 and v2-experimental. All set `disable-model-invocation: true` and run by name only. |
| `imagegen-skills` | 32 | `imagegen-frontend-web`, `imagegen-frontend-mobile`, `brandkit`, `image-to-code`: comps from an image model, then code |
| `unlazy` | 4,102 | An anti-laziness skill (the "Depth Tree" method), which replaced the removed `full-output-enforcement` |
| `tastecode` | 406 | TasteCode, a desktop app (Windows and macOS, beta 0.1.1) that runs Codex, Claude Code and Grok with a "Design Mode" built in |
| `cinetic` | 827 | Launch films and motion design from code |

The site at tasteskill.dev and the README sponsors (interfaces.dev, React Bits, IMG.LY, Kimi) show that this is a funded project now. Note that the `brandkit` name in `imagegen-skills` uses the same `kit` suffix as this repo. It does not collide with any kit here today.

## How it is built

### Page or app screen

The skill first sorts the work. A page is read and scrolled, and it follows "the run". An app screen is worked in, and it follows `references/app-screens.md`, which is the longest file at 15,402 words and has its own run, draw, house rules and checks. A product page that shows its app builds each interface fragment by the app rules.

### The run for a page

Ten steps, in order.

1. **Read the brief and inventory the subject.** The agent lists 8 to 12 things that belong to this client and no competitor: the street, the door number, the one constraint, the printed things of its world. When the brief is vague, the agent states its reading in one line and does not ask.
2. **Write the argument.** One claim per section, each with its proof. A section with no claim is deleted, which is how the stock hero, logos, three features, testimonial, pricing sequence is avoided.
3. **Draw the direction.** `draw.mjs --options 3` deals three of 20 researched directions. The agent picks one against the inventory and then deals the full sheet: a type system, a palette, a hero and a blueprint per section. A redraw needs a stated reason and goes in the report.
4. **Find the idea.** The agent fills one sentence: "On this page, [something of the subject] becomes [the device the direction calls for]." The competitor test checks it. If the sentence still works with the nearest real competitor in it, the idea belongs to the category. The page also gets "one live thing", an interaction made from the idea, with a phone version and a no-script fallback.
5. **Write the words.** A full copy deck before markup. Headlines hold to two lines at every width, about 32 characters. Sample details (dish names, room rates) are allowed and listed for the client. Proof (customers, quotes, statistics) is never invented.
6. **Build it, still.** Tokens first, then the hero, then each section from its blueprint. Imagery has a six-rung order of preference, and the page must carry at least four real pictures. `assets.mjs` searches Openverse, Wikimedia Commons, the Art Institute of Chicago, the Met, NASA and the Internet Archive, downloads the file and records the licence for a footer credit.
7. **Gate.** `lint.mjs` scans source and `inspect.mjs` measures the page at 1440, 768 and 390 px. Every `FAIL` gets fixed, and a `WARN` stays only with a one-sentence defence.
8. **Look.** The agent reads its own screenshots and scores them with `references/critique.md`, then fixes the top three problems. Three rounds at most.
9. **Move.** A motion layer is required. The inspector fails a page with fewer than eight moving elements.
10. **Report.** Six conditions must hold first, including 0 FAIL on the final page and every screenshot opened after the last change.

The README puts a build at 30 to 45 minutes and "a few hundred thousand tokens".

### The library and the deal

`draw.mjs` reads `library/`: 20 directions, 58 heroes, 185 section blueprints, 44 type systems, 56 palettes, 18 motions, a photo index served by picsum.photos, and 202 measured sites. `--keep palette,type` keeps a brand's colours and faces and deals only the composition. `--app` deals one of 7 app styles, 5 shells and 25 screen patterns.

The reason for the deal is stated plainly. "Asked to invent a look, a model picks the category default every time." Impeccable reached the same diagnosis and answers it with a remote roll API. Taste Skill answers it with a local random deal and makes the agent choose among three.

### The gate

`inspect.mjs` drives Chrome over a zero-dependency DevTools Protocol client. `lib/rules.mjs` holds 77 distinct finding IDs. They cover the slop tells (`eyebrow`, `mono`, `numbering`, `gradient-text`, `glass`, `icon-cards`, `palette-purple`, `palette-cream`, `palette-terracotta`), the type (`headline-lines`, `measure`, `small-text`, `font-fallback`), the frame (`off-centre`, `lopsided`, `blank-gap`, `empty-middle`, `untitled-section`, `edge-text`) and the app rules (`rainbow-chart`, `sidebar-phone`, `numeric-align`, `placeholder-data`). `lint.mjs` adds about 25 source patterns, among them `transition-all`, `ease-in`, `bounce`, `scale-zero`, `em-dash` and `lorem`. `scenes.mjs` photographs each scroll scene at 0 to 100% of its hold.

This is the same kind of tool as Impeccable's detector. The difference is that Taste Skill measures the rendered page only, in Node, with no binary download.

### The house rules

The house rules apply on every page, and the inspector measures them. Some come from the study, which found that sites scored 7.5 or higher used icon feature cards 1% of the time against 28% for sites under 6.5. Others the skill labels as "the owner's taste" and bans against gallery fashion: monospace labels, index numbers and hairline grids are more common on award sites, not less. The bans are wide. They cover all gradients, all shadows on resting elements, all thin rules and 1px outlined boxes, all monospace outside code, any violet or indigo, any cream with terracotta, any eyebrow, any styled accent word, and more than two typefaces. App screens relax ten of these with numeric limits.

### The study

`references/research.md` documents a 248-site sample from One Page Love and Awwwards, taken on 2026-10-05 at 1440 and 390 px and scored by 21 model reviewers on the Awwwards weights (design 40, usability 30, creativity 20, content 10). A second pass measured the latest 100 Awwwards Sites of the Day for motion and imagery, and a third measured 23 private product screens for the app rules. The limits section is candid. The reviewers are models, the sample is "fashion as much as quality", and the eyebrow detector over-counts (60% measured against 35% observed).

### Its own test result

§11 of the study is the most useful page in the repo. Six briefs, each built by a fresh agent with no skill, with another design skill (atelier) and with this skill, judged blind from screenshots.

| Round | This skill | Baseline | Wins |
|---|---|---|---|
| 1 | 6.6 | 7.7 | 1 of 4 |
| 2 | 7.1 | 8.0 | 0 of 3 |
| 3 | 7.5 | 7.5 | 1 of 3 |
| 4 (unseen briefs) | 6.9 | 7.9 | 0 of 3 |
| 5 (round 4 briefs again) | 7.7 | 7.8 | 2 of 3 |

The skill won 4 of 16 brief comparisons, and on the one round of unseen briefs it lost all three by a point. The final builds had 0 inspector FAILs where the baselines had 8 to 13, but the inspector encodes the skill's own house rules, so that number measures compliance, not quality. One model juror per brief gives about half a point of noise by the author's own estimate. The fair reading is that the skill reliably removes the tells and has not yet shown that it makes a better page than a strong model with no skill. The project deserves credit for publishing this.

### Loose ends

- `SKILL.md` step 6 and `motion.md` tell the agent to build two or three scroll scenes from `library/scenes.json` and to copy `assets/scenes/demo/<id>.html`. Neither exists at `6010f91`. The changelog moves the scene library to 2.2, and `draw.mjs` copes with the missing file, but the skill text still instructs the agent to use it.
- The scenes and `stage.js` load GSAP and Lenis from jsDelivr. A page built with them carries a third-party CDN dependency.
- There is no telemetry. The scripts call only the open collections, picsum.photos, Google Fonts and jsDelivr.
- On this box the inspector does not find a browser by itself. `findChrome()` checks `/usr/bin` paths only, so it needs `CHROME_PATH=~/.cache/ms-playwright/chromium-1247/chrome-linux64/chrome`.
- The description is 940 characters and fires on "build, design, redesign, restyle, polish or review" any public page in any stack, plus dashboards, admin, settings and inboxes.

## Comparison with the kits

### Step by step

| Taste Skill | Closest kit | How they differ |
|---|---|---|
| Page or app screen | uikit design read `surface` | Same split, `marketing` and `product`. Taste Skill gives each its own run and its own rule set; uikit filters one catalog by scope tag. |
| Inventory of 8 to 12 subject items | uikit rung 3 | Same idea, that distinctiveness comes from the subject. Taste Skill makes it a counted list that later steps consume; uikit leaves it as a principle. |
| Idea sentence and competitor test | uikit signature | uikit names one element the surface is remembered by. Taste Skill names one idea and checks it against a competitor. The competitor test is the sharper check, and 0002 row 19 already proposed it for uikit. |
| One live thing | uikit signature | Taste Skill demands an interaction on every page. uikit lets the signature be static. |
| Argument before design | none | No kit writes the page as claims before layout. plankit plans features, not section order. |
| `draw.mjs` deal | none, by design | uikit says it is "not a taste library". See [Where they disagree](#where-they-disagree). |
| `--keep palette,type` | uikit rungs 1 and 2 | uikit lets `DESIGN.md` and shipped components win outright. Taste Skill keeps colours and faces but still imposes its house rules on the brand, unless `--allow <rule>` is passed per rule. |
| House rules | uikit anti-slop catalog | Large overlap. Taste Skill's list is wider and absolute; uikit's is capped near 30 and scoped. |
| Copy deck, two-line headlines | uikit "strings as design material" | uikit governs interface strings and voice. Taste Skill does headline arithmetic and demands full content per section. |
| Imagery and `assets.mjs` | none | No kit sources pictures. uikit bans fake product shots but says nothing about finding real ones. |
| `inspect.mjs`, `lint.mjs` | uikit pixel pass (opt-in); verifykit `show` | uikit never blocks a build and only renders on request. verifykit takes screenshots but measures nothing. Taste Skill's gate is the largest capability gap, as Impeccable's detector was. |
| Critique with caps | uikit pre-flight | uikit runs four written checks. Taste Skill scores four weighted criteria with 16 caps that override the arithmetic. |
| Motion layer and `motion.md` | motionkit | Close agreement on curves and durations, opposite stance on how much motion. See below. |
| `app-screens.md` | uikit product catalog and state gaps | Taste Skill is far deeper on dashboards: KPI sizes, chart choice, table alignment, density, dark-theme neutrals. uikit covers empty, loading and error states and stops there. |
| Redesign route | uikit `audit`, then `build` | Taste Skill records a before and after in the browser and reports both sets of measurements. uikit's audit is static and writes nothing. |
| Nothing | designkit | Taste Skill neither reads nor writes `DESIGN.md`. It never names the file. |
| Nothing | uikit `stack.md`, `mobile.md` | Taste Skill is framework-agnostic and has no Tailwind v4, shadcn/ui or phone-web fixes like `100vh`, safe areas and input zoom. |

### Where they agree

The ban lists overlap on gradient text, violet accents, glass by reflex, eyebrow labels, `01 / 02 / 03` on non-sequences, icon-topped equal card grids, tracked uppercase micro-labels, lorem ipsum, invented customers and statistics, and fake dashboards made of grey bars. Both name cream with terracotta as an assistant default. Both treat removal as half the job: Taste Skill's `tells.md` calls an empty compliant page "the avoidance aesthetic", and uikit's signature exists for the same reason. On motion, `motion.md` and motionkit agree on strong ease-out curves for entrances, ease-in as a finding, `transform` and `opacity` first, no `transition: all`, a press scale near 0.97, and staggers of 50 to 90 ms.

### Where they disagree

- **Taste library.** uikit ships no palettes and says a lookup table "is exactly how every project styled from it ends up looking like every other one". Taste Skill ships 56 palettes and 44 type systems and deals them at random. Its defence is that the deal is random and the agent picks among three against the subject. The test table above is the only evidence either side has, and it does not settle the question.
- **Gates.** uikit is "not a gate" because taste is unfalsifiable. Taste Skill gates on 77 measurements and caps the critique score on any remaining FAIL. The two positions are closer than they look. Taste Skill gates only on measurable proxies (line counts, margins, colour families) and leaves taste to the critique.
- **System versus house style.** uikit's ladder lets a recorded system beat any taste rule, including uikit's own. Taste Skill's house rules beat the brand unless the agent opts out rule by rule. A product with hairline tables or a violet brand would fight Taste Skill on every build.
- **How much motion.** motionkit's frequency gate and uikit's "justified in one sentence or it doesn't ship" both treat motion as a cost. Taste Skill treats stillness as a defect: under eight moving elements is a FAIL and a still page caps design at 7. That rule fits award-gallery marketing pages and would be wrong on a settings screen, which is why the app run drops it.
- **Springs and overshoot.** Taste Skill bans overshoot outright. motionkit allows a 0.1 to 0.3 bounce for drag-to-dismiss and playful surfaces.
- **Shadows and rules.** Taste Skill bans every resting shadow and every thin rule on pages. uikit bans "a drop shadow on every surface" and decorative hairline grids, and keeps a shadow for elevation and a border for structure.
- **Demonstration content.** uikit bans placeholder people and invented data outright. Taste Skill allows sample menu items and room rates, listed in the report, and bans only invented proof. Impeccable sits in the same place as Taste Skill.
- **Index shape.** Taste Skill is one skill with one long description, so it costs one line of context load and nothing in cognitive load. The kits split the same ground across uikit, motionkit and designkit, each a distinct decision.
- **Weight.** About 56,000 words of skill text, 3,600 lines of script and 1.7 MB of data, against about 18,300 words across all files of uikit, motionkit and designkit. A full Taste Skill build costs a few hundred thousand tokens.

### Taste Skill against Impeccable

The two most popular design skills now look alike. Both started from the same diagnosis (the model picks the category default), both answer it with an external source of randomness, both gate on a deterministic detector and both run a critique on screenshots. Impeccable is broader: 24 commands, native iOS and Android, a live in-browser mode and a fresh-context finish reviewer. Taste Skill is more focused: a single run, real archival pictures and a published blind test. Taste Skill runs fully local apart from picture search; Impeccable's roll always calls impeccable.style.

### The trigger collision

0003 recorded `design-taste-frontend` as installed globally on this box. It is not installed now: `~/.claude/skills` and `~/.agents/skills` hold only the kits. That is the right state. Its description claims "build, design, redesign, restyle, polish or review" for any page and any dashboard, which is uikit's `build` and `audit` almost word for word. Installed next to uikit it would win many of uikit's triggers, and it would then apply house rules that ignore `DESIGN.md`. The Claude Code plugin namespaces the name as `taste-skill:design-taste-frontend`, but a namespace does not stop the model from choosing it. If you want to try it, install it into one marketing-site repo, not globally.

## Ideas worth taking

Ranked by value over cost. Each one is authored from scratch to fit the kit conventions. Taste Skill is MIT, so copied wording would need the copyright line.

| # | Kit | Idea | Cost |
|---|---|---|---|
| 1 | uikit signature | Add the competitor test to the signature check: put the nearest real competitor into the signature sentence, and if it still works, the signature belongs to the category. 0002 proposed this; it has not landed. | Low: two sentences. |
| 2 | uikit rung 3 | Make the subject read a counted inventory: before the design read at rung 3, list 8 to 12 things that belong to this subject and no competitor, and draw the signature from one of them. It turns a principle into a step with a completion criterion. | Low. |
| 3 | motionkit `review` | Add the first-frame rules: a headline, its sentence and its picture are painted on the first frame; hidden start states live inside `prefers-reduced-motion: no-preference`; nothing stays hidden if the script fails; no preloader. motionkit covers none of these today. | Low. |
| 4 | uikit pixel pass | When the pixel pass runs, measure three frame facts with an evaluate call, not by eye: headline line count at 1440, 768 and 390; equal outer margins; no blank stretch taller than half the viewport. These are Taste Skill's most-cited reader complaints, and the checks are cheap. | Medium. |
| 5 | uikit product surface | Borrow a short dashboard layer from `app-screens.md`: right-aligned tabular figures, one hue per chart, no sparkline or tinted icon on each KPI, status colour never on a zero change. Put it behind a pointer like `mobile.md`, read only on a `product` surface with charts or tables. | Medium: a new satellite file. |
| 6 | skillkit, evals | Copy the test design: a fresh agent with the skill against one without it, judged blind from screenshots, with the loss rounds kept in the record. motionkit's `evals/triggers.md` tests firing, not output quality. | High. |

Leave these out:

- The dealt library. It conflicts with uikit's "no taste library" rule, and Taste Skill's own test does not show that it beats a model with no library.
- The motion floor of eight moving elements. It conflicts with motionkit's frequency gate and fits only gallery pages.
- The absolute house rules over a brand. uikit's ladder is the better order for real projects.
- Archival picture search. It is genuinely useful for marketing pages with no assets, but it adds network calls, licence tracking and credits. It belongs in a separate skill only if you find yourself wanting it more than once.

## Open question

The case for running Taste Skill's inspector next to uikit depends on whether it finds problems that uikit `audit` misses on a real product, not on an award-style page. One run settles it. Pick a real project UI, run `uikit audit` and `CHROME_PATH=... node <skill>/scripts/inspect.mjs <url>` on the same route, and compare the two finding lists. Run Impeccable's `npx impeccable detect --json` in the same session to settle the open question in 0003 at the same cost.

## Sources

- https://github.com/Leonxlnx/taste-skill at `6010f91`: `README.md`, `CHANGELOG.md`, `skills/taste-skill/SKILL.md`, `references/{research,critique,motion,tells,app-screens}.md`, `scripts/{draw,inspect,lint,assets}.mjs`, `scripts/lib/{rules,cdp}.mjs`, `evals/evals.json`, `.github/workflows/check-skills.yml`
- `gh api repos/Leonxlnx/taste-skill`, `/releases` and `/contributors`, read 2026-10-24
- `gh api` on `Leonxlnx/taste-skill-classics`, `Leonxlnx/imagegen-skills`, `Leonxlnx/unlazy`, `Leonxlnx/tastecode` and the `Leonxlnx` repo list, read 2026-10-24
- https://tasteskill.dev and https://tastecode.dev, cited by the README; not fetched
