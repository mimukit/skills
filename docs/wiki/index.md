# Documentation

Documentation for `mimukit/skills` — the skills themselves, and the repo that produces them. [Getting started](./getting-started.md) splits by what you're here for: [installing the skills](./getting-started.md#install-and-use-the-skills) and using them in your own projects, or [working on the collection](./getting-started.md#work-on-the-collection). Everything below Start here is maintainer-facing; the per-skill pages are for both.

## Start here

| Page | What it covers |
|------|----------------|
| [Getting started](./getting-started.md) | Two paths — install from skills.sh and invoke a skill, or clone, link a skill into your agents, edit it live, and lint it |
| [Architecture](./architecture.md) | How the repo is put together — the two skill homes, the shell tooling, the gates, and how skills reach people |
| [Reference](./reference.md) | Every `make` target, environment variable, link-status badge, lint check, and security finding class |

## How to

| Task | Page |
|------|------|
| Add a skill to the collection | [Add a new skill](./how-to/add-a-new-skill.md) |
| Fix a dev link that won't behave | [Recover a wedged dev link](./how-to/recover-a-wedged-dev-link.md) |

## The skills

One page per skill — what it does, when to reach for it, how its modes work, and what it hands off to. For how they compose into one loop, read [the workflow](./workflow.md) instead.

**Git & GitHub**
[`gitkit`](./skills/gitkit.md) · [`commitkit`](./skills/commitkit.md) · [`prkit`](./skills/prkit.md) · [`mergekit`](./skills/mergekit.md) · [`issuekit`](./skills/issuekit.md) · [`repokit`](./skills/repokit.md) · [`orcakit`](./skills/orcakit.md)

**Planning & Design**
[`validatekit`](./skills/validatekit.md) · [`researchkit`](./skills/researchkit.md) · [`prototypekit`](./skills/prototypekit.md) · [`refactorkit`](./skills/refactorkit.md) · [`plankit`](./skills/plankit.md) · [`grillkit`](./skills/grillkit.md)

**Building**
[`implementkit`](./skills/implementkit.md) · [`uikit`](./skills/uikit.md)

**Testing & QA**
[`reviewkit`](./skills/reviewkit.md) · [`qakit`](./skills/qakit.md) · [`verifykit`](./skills/verifykit.md)

**Writing & Docs**
[`humankit`](./skills/humankit.md) · [`wikikit`](./skills/wikikit.md) · [`designkit`](./skills/designkit.md)

**Context & Handoffs**
[`handoffkit`](./skills/handoffkit.md) · [`domainkit`](./skills/domainkit.md) · [`statuskit`](./skills/statuskit.md)

**Authoring & Automation**
[`skillkit`](./skills/skillkit.md) · [`promptkit`](./skills/promptkit.md) · [`afkkit`](./skills/afkkit.md)

## Written by hand, not by this doc set

These predate the wiki and are maintained directly. They're mapped here so they're easy to find, not owned by any generator.

| Document | What it covers |
|----------|----------------|
| [The workflow](./workflow.md) | How the skills compose into one loop — every mode, every handoff, and a worked end-to-end day |
| [Publishing](../../PUBLISHING.md) | How skills.sh listing works, the pre-push checklist, and first-time repo setup |
| [Skill ideas](../../IDEAS.md) | The backlog of skills not yet built |
| [AGENTS.md](../../AGENTS.md) | Conventions for AI agents authoring skills here — the `kit` naming rule, prose formatting, hand-off requirements, visibility |

`AGENTS.md` is an instruction file for agents, not reader documentation. It's the authority on the conventions; the pages here describe the tooling that enforces them.

_Verified against `main`@`1f85177` on 2026-08-16._
