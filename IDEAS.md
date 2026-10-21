# Skill ideas

The backlog of skills I want to build next. This file only ever holds **unfinished work** — for the list of skills already built, see the [README Skills table](./README.md#skills).

**How this backlog works**

- **Capture** — new idea? Add a row below, placed by priority (top = build next; row order carries priority).
- **Promote** — pick the top row and run `/skillkit` to author it (skillkit scaffolds the conventions and tests).
- **Graduate** — on ship, **delete the row from this file** and add the skill to the [README Skills table](./README.md#skills). Per [AGENTS.md](./AGENTS.md), also update `skills.sh.json` if it's a public skill. Nothing lives in both files.

Naming follows the `kit` convention in [AGENTS.md](./AGENTS.md): functional word first, `kit` appended.

## Backlog

Ordered by priority (top = build next).

| Skill | What it does |
|-------|--------------|
| `jobkit` | Draft tailored job-application and interview answers grounded in `resume.md` + `context.md`, saved to markdown for copy-paste (chains into `humankit`) |
| `banglakit` | Write natural Bangla/Bengali content with fluent, context-appropriate language and tone |
| `evalkit` | Measure whether a production LLM app actually works — build a graded eval set from real traffic and failure reports, define task-specific metrics and LLM-judge rubrics, run the suite against prompt/model/RAG changes, and report a pass/regression verdict with per-case evidence so a change ships on numbers rather than vibes (pairs with `promptkit`) |
| `reflectkit` | Mine a finished session or recent transcripts under `~/.claude/projects/` for durable lessons, then route each one to a concrete edit on an existing kit, a `make lint` rule, or a backlog note, with approval before any edit lands. Starts as `internal: true`. Modeled on pstack `reflect` ([research](./docs/research/0001-research-pstack-skills-2026-08-19.md)) |
| `whykit` | Answer "why is this code shaped this way" from git, `gh`, issue, and doc evidence, with cited claims, calibrated confidence, and null results reported as findings. Grounds `plankit` and `refactorkit` proposals. Modeled on pstack `why` |
| `impactkit` | Pre-merge impact analysis: name the one fact the change is safe because of, walk a five-rung evidence ladder, and prove the fact with a script that runs the real code. Hunts breakage outside the diff, as a `mergekit` companion. Modeled on pstack `blast-radius` |
| `explainkit` | One-shot "how does X work" subsystem walkthrough via Explore-agent fan-out: overview, key concepts, flow, where things live, gotchas. Sits between `wikikit` (durable docs) and `tutorkit` (multi-session teaching). Modeled on pstack `how` |
| `trailkit` | Shared decision-trail layer: one append-only TSV per long run (what, why, evidence pointer, result), audited against the transcript before handback. `afkkit` is the first consumer; could land inside afkkit instead. Modeled on pstack `show-me-your-work` |
| `arenakit` | Fan out N independent attempts at one artifact, cross-judge against a rubric, pick a base, graft the losers' best ideas, and record the rejections. Decide first whether this is a `prototypekit` extension instead. Modeled on pstack `arena` |

**Merged / dropped** (don't re-add): `tddkit` → folded into `implementkit` as a mode; `taskkit` + `trackerkit` → merged into `issuekit`; `prdkit` / `speckit` → dropped (`plankit` + `grillkit` already produce the plan doc, and `speckit` collides with GitHub spec-kit).
