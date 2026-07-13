# Skill ideas

The backlog of skills I want to build next. Shipped skills live in the [README Skills table](./README.md#skills) — this file only ever holds unfinished work.

**How this backlog works**

- **Capture** — new idea? Add a row below, placed by priority (top = build next; row order carries priority).
- **Promote** — pick the top row and run `/skillkit` to author it (skillkit scaffolds the conventions and tests).
- **Graduate** — on ship, **delete the row from this file** and add the skill to the [README Skills table](./README.md#skills). Per [AGENTS.md](./AGENTS.md), also update `skills.sh.json` if it's a public skill. Nothing lives in both files.

Naming follows the `kit` convention in [AGENTS.md](./AGENTS.md): functional word first, `kit` appended.

## Backlog

| Skill | What it does |
|-------|--------------|
| `trackerkit` | Maintain GitHub issue trackers — sync issues ↔ merged PRs, cross-check status, update/prune scope, keep parent→child links, post plans and decisions as comments |
| `jobkit` | Draft tailored job-application and interview answers grounded in `resume.md` + `context.md`, saved to markdown for copy-paste (chains into `humankit`) |
| `debugkit` | My root-cause ritual — reproduce, isolate, find the true cause, propose a fix; covers infra (docker/dokploy failures) and WordPress local→prod migration cases |
| `reviewkit` | Review AI-agent-implemented code specifically — my convention-fit take on catching the failure modes of agent-generated changes |
| `testkit` | Write automated tests — unit, integration, and e2e — from the actual code under test |
| `tddkit` | Drive test-driven development — red → green → refactor, tests before implementation (builds on `testkit`) |
| `seokit` | SEO audit and improvement report, authored from scratch to fit these conventions |
| `taskkit` | The `TASK.md` → numbered plan doc → implement → append-summary loop for working issues one at a time |
| `repokit` | Generate a one-line GitHub "About" description + topics/tags from repo contents and apply them via `gh` |
| `plankit` | Brainstorm and plan a project, feature, spec, or PRD before any code — turn a rough idea into a structured plan document |
| `researchkit` | Research a topic, tech, tool, architecture, or service on demand — compare the options and recommend the right one |
| `implementkit` | Implement a plan, spec, issue, or fix — carry an agreed design through to working, committed code |