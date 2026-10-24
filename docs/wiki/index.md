# Documentation

Documentation for `mimukit/skills` — the skills themselves, and the repo that produces them. [Getting started](./getting-started.md) splits by what you're here for: [installing the skills](./getting-started.md#install-and-use-the-skills) and using them in your own projects, or [working on the collection](./getting-started.md#work-on-the-collection). Everything below Start here is maintainer-facing; the skill links at the bottom are for both.

## Start here

| Page | What it covers |
|------|----------------|
| [Getting started](./getting-started.md) | Two paths — install from skills.sh and invoke a skill, or clone, link a skill into your agents, edit it live, and lint it |
| [Cheatsheet](./cheatsheet.md) | Every skill, one line each — the recall page, generated from each skill's `description` |
| [The workflow](./workflow.md) | How the skills compose into one loop — every phase, every handoff, and a worked end-to-end day |
| [Architecture](./architecture.md) | How the repo is put together — the two skill homes, the shell tooling, the gates, and how skills reach people |
| [Reference](./reference.md) | Every `make` target, environment variable, link-status badge, lint check, and security finding class |

## How to

| Task | Page |
|------|------|
| Add a skill to the collection | [Add a new skill](./how-to/add-a-new-skill.md) |
| Fix a dev link that won't behave | [Recover a wedged dev link](./how-to/recover-a-wedged-dev-link.md) |

## The skills

Each name links to the skill's `SKILL.md`, the one source for what it does, its modes, and what it hands off to. For a one-line-per-skill recall list, read [the cheatsheet](./cheatsheet.md); for how they compose into one loop, read [the workflow](./workflow.md).

**Git & GitHub**
[`gitkit`](../../skills/gitkit/SKILL.md) · [`commitkit`](../../skills/commitkit/SKILL.md) · [`prkit`](../../skills/prkit/SKILL.md) · [`mergekit`](../../skills/mergekit/SKILL.md) · [`releasekit`](../../skills/releasekit/SKILL.md) · [`issuekit`](../../skills/issuekit/SKILL.md) · [`repokit`](../../skills/repokit/SKILL.md) · [`orcakit`](../../skills/orcakit/SKILL.md) · [`paseokit`](../../skills/paseokit/SKILL.md)

**Planning & Design**
[`validatekit`](../../skills/validatekit/SKILL.md) · [`namekit`](../../skills/namekit/SKILL.md) · [`researchkit`](../../skills/researchkit/SKILL.md) · [`prototypekit`](../../skills/prototypekit/SKILL.md) · [`refactorkit`](../../skills/refactorkit/SKILL.md) · [`plankit`](../../skills/plankit/SKILL.md) · [`grillkit`](../../skills/grillkit/SKILL.md)

**Building**
[`implementkit`](../../skills/implementkit/SKILL.md) · [`uikit`](../../skills/uikit/SKILL.md) · [`motionkit`](../../skills/motionkit/SKILL.md)

**Testing & QA**
[`reviewkit`](../../skills/reviewkit/SKILL.md) · [`qakit`](../../skills/qakit/SKILL.md) · [`verifykit`](../../skills/verifykit/SKILL.md) · [`testkit`](../../skills/testkit/SKILL.md) · [`debugkit`](../../skills/debugkit/SKILL.md)

**Writing & Docs**
[`humankit`](../../skills/humankit/SKILL.md) · [`wikikit`](../../skills/wikikit/SKILL.md) · [`designkit`](../../skills/designkit/SKILL.md)

**Search & Visibility**
[`seokit`](../../skills/seokit/SKILL.md)

**Context & Handoffs**
[`handoffkit`](../../skills/handoffkit/SKILL.md) · [`domainkit`](../../skills/domainkit/SKILL.md) · [`statuskit`](../../skills/statuskit/SKILL.md)

**Skill & Prompt Authoring**
[`skillkit`](../../skills/skillkit/SKILL.md) · [`promptkit`](../../skills/promptkit/SKILL.md)

**Automation & Orchestration**
[`afkkit`](../../skills/afkkit/SKILL.md)

**Thinking & Learning**
[`ideakit`](../../skills/ideakit/SKILL.md) · [`tutorkit`](../../skills/tutorkit/SKILL.md)

## Written by hand, not by this doc set

These predate the wiki and are maintained directly. They're mapped here so they're easy to find, not owned by any generator.

| Document | What it covers |
|----------|----------------|
| [Publishing](../../PUBLISHING.md) | How skills.sh listing works, the pre-push checklist, and first-time repo setup |
| [Skill ideas](../../IDEAS.md) | The backlog of skills not yet built |
| [AGENTS.md](../../AGENTS.md) | Conventions for AI agents authoring skills here — the `kit` naming rule, description pointers, the two loads, information hierarchy, completion criteria, pruning, prose formatting and register, artifact naming, step cross-references, hand-off requirements, visibility, the `skills.sh.json` directory page, layout, and the frontmatter template |

`AGENTS.md` is an instruction file for agents, not reader documentation. It's the authority on the conventions; the pages here describe the tooling that enforces them.

_Verified against `main`@`e7a6a61` on 2026-10-20._
