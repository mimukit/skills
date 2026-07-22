# Skill ideas

The backlog of skills I want to build next. Shipped skills live in the [README Skills table](./README.md#skills) — this file only ever holds unfinished work.

**How this backlog works**

- **Capture** — new idea? Add a row below, placed by priority (top = build next; row order carries priority).
- **Promote** — pick the top row and run `/skillkit` to author it (skillkit scaffolds the conventions and tests).
- **Graduate** — on ship, **delete the row from this file** and add the skill to the [README Skills table](./README.md#skills). Per [AGENTS.md](./AGENTS.md), also update `skills.sh.json` if it's a public skill. Nothing lives in both files.

Naming follows the `kit` convention in [AGENTS.md](./AGENTS.md): functional word first, `kit` appended.

## The development workflow

The skills here aren't a random pile — they compose into one end-to-end flow for building a software feature. This is the target the backlog builds toward.

```
issuekit     ← (optional entry) pick/triage an existing issue, or start fresh
   ▼
plankit      → brainstorm, write docs/plans/plan-*.md
   ▼
grillkit     → interrogate + harden that same doc
   ▼
issuekit     → create GitHub issues from the hardened plan-*.md
   ▼
implementkit → code only; mode (straight vs TDD) resolved by precedence
   ▼           (prompt → CLAUDE.md → repo inference → ask once); runs its tests
commitkit    → one clean Conventional commit
   ▼
reviewkit    → convention-fit self-review (working tree OR branch diff)
   ▼
verifykit    → browser/computer-use: drive the real feature, capture screenshots + video
   ▼
prkit        → open PR: "Fixes #", attach verifykit's proof artifacts
   ▼
issuekit     → sync PR→issue, close, triage
```

**On-demand, off the default path:** `qakit` (manual test checklist for risky/release features), `researchkit` (feeds `plankit`), `debugkit` (when something breaks), `testkit` (brownfield test retrofit).

**Cross-cutting, any step:** `humankit` (polish plan/PR/issue prose), `handoffkit` (session handoff).

Shipped skills already wired into the flow: `plankit`, `grillkit`, `implementkit`, `commitkit`, `reviewkit`, `prkit`, `qakit`, `issuekit`, `verifykit`. The `prkit` ↔ `verifykit` coupling is done: `verifykit` publishes screenshots + a GIF to a hidden `refs/verify-assets/*` ref (zero clone bloat, renders inline via SHA-pinned raw URLs), and `prkit` embeds them in a Proof section of the PR body. The core flow is fully wired end to end; remaining work is the off-flow tools below.

## Backlog

Ordered by priority — these are all off-flow tools now that the core workflow is shipped.

| Skill | What it does |
|-------|--------------|
| `debugkit` | My root-cause ritual — reproduce, isolate, find the true cause, propose a fix; covers infra (docker/dokploy failures) and WordPress local→prod migration cases |
| `testkit` | Write automated tests — unit, integration, and e2e — for an existing brownfield project that has none |
| `jobkit` | Draft tailored job-application and interview answers grounded in `resume.md` + `context.md`, saved to markdown for copy-paste (chains into `humankit`) |
| `seokit` | SEO audit and improvement report, authored from scratch to fit these conventions |
| `banglakit` | Write natural Bangla/Bengali content with fluent, context-appropriate language and tone |

**Merged / dropped** (don't re-add): `tddkit` → folded into `implementkit` as a mode; `taskkit` + `trackerkit` → merged into `issuekit`; `prdkit` / `speckit` → dropped (`plankit` + `grillkit` already produce the plan doc, and `speckit` collides with GitHub spec-kit).
