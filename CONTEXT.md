# mimukit/skills

A personal collection of AI agent skills, each named with the `kit` suffix, that together run one development loop from decide to land.

## Overview

### What it is
A set of AI agent skills, one directory per skill under `skills/`, installed into agents with skills.sh. Each skill works alone, and together they form one loop. See [README.md](./README.md) for install and use.

### Who it is for
The owner first, as the daily workflow on their own projects. Other developers can install any public skill on its own through skills.sh.

### The problem it solves
Without instructions, an agent does each task its own way and drops the hand-offs between tasks. The kits write down one workflow, so each run follows the same steps and ends on a clear next move.

### Core capabilities
- Decide and plan a change: validate, name, research, prototype, plan, grill.
- Run GitHub issues and PRs from filing to merge, each in its own worktree, attended or unattended, and keep repos and worktrees tidy.
- Build, review, verify, and QA a change, then cut a release.
- Keep in-repo contracts current: reader docs, the design system, the domain model.
- Audit a site for SEO and AI-search gaps.
- Survey a project, crown one next move, and hand a session to another agent.
- Author skills and agent prompts, and keep personal repos for ideas and learning.

### Non-goals
- No runtime: the collection holds instructions and lint scripts, never a framework, server, or agent runtime.
- No forks: every skill is written from scratch, even when it is a version of an upstream skill.

## Skills and their structure

### Skill
A directory holding one `SKILL.md`, with frontmatter and instructions that an agent loads to do one kind of work.
_Avoid: plugin, command, prompt_

### Kit
The naming convention for a skill: one lowercase word, the functional term first, `kit` appended (`commitkit`, `humankit`).

### Mode
A distinct case that one skill handles, chosen by the agent from context, such as `issuekit start` or `domainkit audit`. A mode costs one branch in a description where a new skill costs an entry the human must remember.
_Avoid: subcommand, sub-skill_

### Satellite
A file inside a skill's own directory that holds reference only some branches need, reached by a pointer from `SKILL.md`. A mode satellite lives at `modes/<mode>.md`.

### Description
The `description` frontmatter field: a context pointer of one what-clause and a "Use when" trigger, loaded on every turn whether or not its skill fires.
_Avoid: summary, blurb_

### Branch
A distinct case a description must trigger on, usually a mode. Phrasings that rename one case are synonyms, not branches.

### Step
An ordered action the agent performs inside a skill, ending on a completion criterion.

### Reference
Definitions, rules, and facts in a skill that the agent consults on demand rather than performs in order.

### Completion criterion
The condition that tells the agent a step is done. A strong one is both checkable and exhaustive.

### Public skill
A skill with `metadata.internal: false`: portable, self-contained, and listed on skills.sh.
_Avoid: published skill_

### Internal skill
A skill with `metadata.internal: true`: a repo-only maintenance skill that skills.sh hides from discovery.

## Load and register

### Context load
The cost that always-loaded material, such as a description or a line in AGENTS.md, puts on the agent's window every turn.

### Cognitive load
The cost on the human of knowing which skills exist and when to reach for each. It is the price of human agency, spent where human judgement matters.

### Register
The writing style an artifact takes toward its operator: procedural (ASD-STE100), explanatory (free of AI tells), or exempt (machine-read or format-bound).

## The loop

### The loop
The sequence the kits form: decide, plan, file, start, build, ship, land, then release when one is cut.
_Avoid: pipeline, workflow (as a noun for the sequence)_

### Layer
A skill that other skills call rather than a step the human takes, such as gitkit and domainkit.

### Side kit
A skill invoked on demand that enters from wherever the human already is, rather than from a fixed phase, such as debugkit or promptkit.

### Hand-off
The closing section of a skill, `## Hand off`, that reports what changed, where it landed, and the next move.
_Avoid: report, summary, wrap-up_

### Crowned move
The single next move a skill recommends in its hand-off, ranked above any runners-up.
_Avoid: suggestion, options menu_

### Lifecycle label
A GitHub issue label that records where an issue is in the loop: `ready`, `blocked`, `needs-planning`, `in-progress`, or `in-review`. repokit provisions the set and issuekit moves issues between them.
_Avoid: status tag_

## Artifacts and tooling

### Artifact
A durable Markdown file a skill writes under `docs/`, named `NNNN-<type>-<slug>-YYYY-MM-DD.md`. Reader-facing wiki pages are not artifacts.

### Serial
The four-digit, per-directory number that leads an artifact's filename and records creation order. It is never reused.

### Review stamp
A line in an artifact that records its review state, such as `Grilled:` on a plan or `Review: pending` and `Review: done YYYY-MM-DD` on a doc.
_Avoid: review marker_

### Dev link
A symlink from `~/.claude/skills` and `~/.agents/skills` to a skill's repo copy, made by `make link` for live testing.
