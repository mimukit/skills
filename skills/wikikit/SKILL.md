---
name: wikikit
description: >-
  Generate and maintain a project's reader-facing documentation in-repo (getting-started, how-to guides, architecture overview, runbooks), every command verified against the code, in four modes: init, update, audit, and an opt-in publish that mirrors the set to the GitHub wiki. Use when the user says "write docs for this project", "update the docs", "our docs are stale", or "sync the docs to the GitHub wiki". Not an agent handoff, and not the glossary or ADRs.
license: MIT
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, AskUserQuestion
metadata:
  internal: false
---

# wikikit

The documentation a **reader** opens: how do I run this, how do I do the one task I came here for, how is it put together, and what do I do at 3am when it's down.

## What wikikit is not

- **Not the GitHub Wiki.** In-repo Markdown is the source of truth in every mode, versioned with the code and reviewed in the same PR. The wiki tab is at most a **derived, disposable mirror**, and only when [`publish`](modes/publish.md) is asked for by name. wikikit never reads the wiki as input and never treats it as canonical.
- **Not the domain model.** A glossary (`CONTEXT.md`) and decision records (`docs/adr/`) have one owner, which is **domainkit** when it's installed and the human otherwise. A page that needs a term **links** to the glossary instead of defining it; an architecture page that needs a rationale links the ADR by number instead of paraphrasing it. A term missing from the glossary is routed, never invented inline. When `CONTEXT.md` carries an `## Overview`, a page that states the product's purpose links that overview instead of restating it, and `architecture.md` opens with the link.
- **Not process artifacts.** Plans, QA plans, reviews, handoffs, and agent instruction files (`CLAUDE.md` and its equivalents) are never read as sources of truth for reader docs or written by this skill.
- **Not an API reference generator.** Where a generator exists (TypeDoc, Sphinx autodoc, an OpenAPI spec) wikikit links its output unchanged and never hand-writes that reference material.

## When this fires

- **`init`** bootstraps the set from the codebase.
- **`update`** refreshes only what a change invalidated, including a docs pass right after a feature lands.
- **`audit`** is a read-only sweep for stale, broken, and undocumented surface. **Writes nothing, ever.**
- **`publish`** installs a workflow that mirrors the set to the GitHub wiki. **Explicit ask only.**

**If no mode is clear, ask.** `audit` is free and `init` writes a dozen files; never guess between them.

**`publish` is never inferred.** It is not part of the doc loop, no other mode routes into it, and "the docs are out of date" or "publish the docs" *alone* means [`update`](modes/update.md), not this. It fires only when the request names the GitHub wiki, the wiki tab, or the sync workflow itself. A repo that never asks for it never learns it exists.

## Locate the doc sets

Every mode opens here. **Name every set found in the mode's first line of output.**

### Find existing sets

One `**/.wikimap.yaml` glob, scoped to the repo root plus the workspace globs (`pnpm-workspace.yaml`, `package.json` `workspaces`, `go.work`, a Cargo workspace), honoring `.gitignore` so a vendored tree can't inject a set.

### Run the detection ladder for a repo with no set

Take the first rung that matches, and **say which rung matched before writing anything**:

| # | Rung | Where docs go |
|---|---|---|
| 1 | **A configured docs engine**: `mkdocs.yml`, `docusaurus.config.*`, `.vitepress/`, `astro.config.*` with Starlight, `conf.py`, a Nextra config | that engine's configured content directory, with its nav/sidebar updated in the same pass |
| 2 | **An existing reader-doc tree**: a populated `docs/` that isn't only agent artifact directories, or `documentation/`, `website/docs/` | adopt it as-is; do not migrate |
| 3 | **Fallback** | `docs/wiki/`, created on first write |

**An existing engine always wins.** wikikit writes into the site the repo already runs, and never introduces a docs engine into a repo that doesn't have one.

**In a workspace, the root set is always written; a package earns its own set only when it is independently published or independently runnable.** Run the ladder once for the root, then once per qualifying package (`packages/<x>/docs/`). State the split before writing anything.

### Reconcile the manifest against disk

Every mode checks the manifest against disk **before any work starts**:

- pages on disk with no manifest entry,
- entries whose page is gone,
- `documents:` globs matching nothing,
- a `home:` that no longer matches the ladder, usually a docs engine that arrived after `init`.

`init` and `update` repair on consent. `audit` reports drift as its own row and repairs nothing, because it writes nothing. **A migration is never implicit**: when rung 1 starts matching where rung 3 matched before, name both paths and offer the `git mv` plus nav update as one consented step. Declined, wikikit keeps writing where the manifest says and reports the divergence each run.

## The doc map

The doc map is the unit all three modes operate on. It lives at `<doc home>/.wikimap.yaml`, dotfile-prefixed so GitHub's folder view and every engine build skip it without a config edit, and carries one entry per page with its Diátaxis mode and the globs of code it documents:

```yaml
home: docs/wiki
engine: none                    # or mkdocs | docusaurus | vitepress | starlight | sphinx | nextra
pages:
  - path: getting-started.md
    mode: tutorial
    documents: [package.json, src/index.ts, .env.example]
  - path: how-to/deploy-to-staging.md
    mode: how-to
    documents: [.github/workflows/deploy.yml, infra/**]
  - path: architecture.md
    mode: explanation
    adopted: true               # a human wrote it; wikikit maps it, never claims it
    documents: [src/**]
```

`documents:` gives `update` its code-path → page lookup and `audit` its recency prefilter.

### The page vocabulary

| Page | Diátaxis mode | Documents |
|------|---------------|-----------|
| `index.md` | none | entry point and table of contents |
| `getting-started.md` | tutorial | install → run → first successful thing |
| `how-to/<task>.md` | how-to | one task per page, goal-shaped |
| `how-to/set-up-a-dev-environment.md` | how-to | the derivable half of contributor docs |
| `how-to/cut-a-release.md` | how-to | release steps that actually exist in the repo |
| `architecture.md` | explanation | opens with a link to the `CONTEXT.md` overview when one exists; components, boundaries, data flow, links to ADRs |
| `runbooks/<scenario>.md` | how-to (operator) | deploy, rollback, incident response, backup/restore |
| `reference.md` | reference | declared surface only: commands, flags, env vars, config keys |

**This table is the vocabulary, not a quota.** The map is derived from the repo: a library with no deployment gets no runbooks, a CLI gets a commands page, a repo with a TypeDoc build gets no `reference.md` at all.

Diátaxis governs internally: never print its mode names on a page.

Three boundaries the vocabulary encodes:

- **`CONTRIBUTING.md` is linked, never written.** Dev-environment setup and release steps are in the repo and verify like any other how-to. PR etiquette, a code of conduct, and review norms exist nowhere in code, so wikikit never writes them. `index.md` links the file if it exists.
- **`reference.md` covers declared surface only**, meaning things declared in a single place and re-verifiable in a single grep: CLI commands, flags, env vars, config keys. Library symbols and hand-maintained HTTP endpoint tables are refused and routed to a generator.
- **No mirror pages.** A mirror page restates one source file that already documents itself: one page per skill, plugin, module, command, or package, each copying its own `README`, `SKILL.md`, or doc comment. Cover such a series with **one index page** that names each item in a line and links its source, generated from the source's own metadata when the repo has a script for it. A page earns its place by saying what no single source file says: how parts connect, how to do a task across them, what to do when it breaks. Write a mirror series only when the user asks for it after you name the cost (every source edit owes a second edit), and record the choice in the manifest entry's comment.

### The provenance stamp

Every page wikikit authors ends with one line:

```markdown
_Verified against `main`@`a1b2c3d` on 2026-08-06._
```

`audit` diffs from the SHA while it is still reachable, and falls back to the date when a rebase or squash-merge has orphaned it.

**A stamp asserts that every claim on the page was verified, and its SHA is a commit on the default branch.** Stamp a page only after a pass that checked the whole page, not only the claims a change moved. On a feature branch the verified commit does not exist on the default branch yet, so leave the old stamp in place (a new page gets none) and name the page in the hand-off as due a stamp after merge. The operator stamps it on the default branch after the merge, and until then `audit` keeps reporting it as due.

**A page with no stamp is not stale, it is unverified.** That's how adopted pages are marked: a page found under rung 2 gets a manifest entry with `documents:` globs and `adopted: true`, and no stamp. It earns its first stamp the first time a verification pass covers the whole page.

## Grounding: verify before you write

**Every factual claim is verified against the repo before it ships.** Commands come from the actual `package.json`, `Makefile`, `pyproject.toml`, or `justfile`; paths exist; env vars are actually read somewhere; endpoints are actually routed. **A feature wikikit cannot find in code does not get documented.**

Static reading is the default, and it proves a script is *declared*, not that it runs. So wikikit may also execute a **fixed allowlist of side-effect-free probes**, after **one consent ask per run**:

| Allowed | Never |
|---|---|
| `<command> --help`, `-h` | anything that installs (`npm install`, `pip install`, `brew`) |
| `<command> --version`, `-V` | anything that builds, compiles, or bundles |
| `make -n <target>`, `make help` | anything that migrates a database or seeds data |
| bare script listings (`npm run`, `pnpm run`, `yarn run`, `just --list`) | anything that deploys, publishes, or pushes |
| read-only git (`git log`, `git diff`, `git show`, `git rev-parse`) | anything that writes outside the doc set, or calls a live service |

The allowlist is written here and **never inferred**. A command that looks harmless but isn't on the list is not run, so report the claim as unverified instead. `audit`'s "read-only" means *it writes no files*, so probes are available there too.

## The modes

_Write every hand-off in this skill in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

The mode bodies live in one file each under `modes/`. Route with [When this fires](#when-this-fires), read that one file, and follow it. Everything in this root applies to every mode and is not restated in the mode files.

- Mode `init` → read [modes/init.md](modes/init.md), then follow it.
- Mode `update` → read [modes/update.md](modes/update.md), then follow it.
- Mode `audit` → read [modes/audit.md](modes/audit.md), then follow it.
- Mode `publish` → read [modes/publish.md](modes/publish.md), then follow it.

## Writing standards

- **One Diátaxis mode per page.** A how-to answers one goal and leaves the architecture to the explanation page; an explanation stays an explanation to the end.
- **Every command copy-pasteable and verified.** Real flags, real paths, real names.
- **Open at the first useful sentence.** An overview of what the page is about is a sentence the reader skips.

For general AI-writing tells, offer a **humankit** pass when it's installed.

## Notes

- **Consent, by operation.** The `init` map, new pages, deletions, the README markers, a doc-home migration, and the probe run all ask. Edits to existing pages in `update` do not. `audit` asks for nothing except probes.
- **No marketing copy, no translation.** Landing pages, feature blurbs, changelogs, and localization are all out.
- **Existing project convention wins.** A repo with its own docs location, page naming, or engine layout gets followed, not overridden, and wikikit says which convention it followed.
- **No filesystem** (e.g. a browser-based agent)? Print each page as a fenced block labeled with its path, print the manifest the same way, and name the probes the user should run themselves. Never report a page written that you could not write.
