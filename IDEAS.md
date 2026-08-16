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
| `testkit` | Write automated tests — unit, integration, and e2e — for an existing brownfield project that has none |
| `releasekit` | Cash in the Conventional Commits the collection already enforces — derive a changelog and a semver tag from the commit range, and cut the release |
| `jobkit` | Draft tailored job-application and interview answers grounded in `resume.md` + `context.md`, saved to markdown for copy-paste (chains into `humankit`) |
| `seokit` | SEO audit and improvement report, authored from scratch to fit these conventions |
| `banglakit` | Write natural Bangla/Bengali content with fluent, context-appropriate language and tone |
| `evalkit` | Measure whether a production LLM app actually works — build a graded eval set from real traffic and failure reports, define task-specific metrics and LLM-judge rubrics, run the suite against prompt/model/RAG changes, and report a pass/regression verdict with per-case evidence so a change ships on numbers rather than vibes (pairs with `promptkit`) |

**Merged / dropped** (don't re-add): `tddkit` → folded into `implementkit` as a mode; `taskkit` + `trackerkit` → merged into `issuekit`; `prdkit` / `speckit` → dropped (`plankit` + `grillkit` already produce the plan doc, and `speckit` collides with GitHub spec-kit).
