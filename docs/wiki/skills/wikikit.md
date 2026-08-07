# wikikit

Generate and maintain a project's reader-facing documentation in-repo — getting-started, how-to guides, architecture, runbooks — with every command verified against the code.

**Reach for it when** a project has no docs, or the docs it has have gone stale.

| | |
|---|---|
| Modes | [`init`](#init) · [`update`](#update) · [`audit`](#audit) · [`publish`](#publish) |
| Tools | `Read`, `Write`, `Edit`, `Grep`, `Glob`, `Bash`, `AskUserQuestion` |
| Writes | a doc set under the resolved doc home, plus `.wikimap.yaml` |
| Visibility | public |

## What it does

wikikit writes the documentation a **reader** opens: how do I run this, how do I do the one task I came here for, how is it put together, and what do I do at 3am when it's down.

A repo built by agents accumulates plans, reviews, QA docs, and decision records, and still ships a README saying `npm install` because that's what the scaffold wrote a year ago. The knowledge exists; it's just scattered across artifacts nobody outside the project will ever read. wikikit is the half that faces outward.

**It is not the GitHub Wiki.** Everything it writes is in-repo Markdown, versioned with the code and reviewed in the same pull request.

## Four things it isn't

- **Not the GitHub Wiki.** In-repo Markdown is the source of truth in every mode. The wiki tab is at most a **derived, disposable mirror**, and only when [`publish`](#publish) is asked for by name. It never reads the wiki as input.
- **Not the domain model.** A glossary and decision records have one owner — [`domainkit`](./domainkit.md). A page needing a term **links** to the glossary instead of defining it; a term missing from it is routed, never invented inline.
- **Not process artifacts.** Plans, QA plans, reviews, handoffs, and agent instruction files are written for a maintainer mid-flow, expire, and are never read as sources of truth for reader docs.
- **Not an API reference generator.** Where a generator exists — TypeDoc, Sphinx autodoc, an OpenAPI spec — it links the output unchanged rather than hand-writing reference material that drifts within a week.

## Grounding is the rule that separates docs from fiction

**Every factual claim is verified against the repo before it ships.** Commands come from the actual `package.json`, `Makefile`, or `justfile`; paths exist; env vars are actually read somewhere; endpoints are actually routed.

**A feature wikikit cannot find in code does not get documented.**

Static reading proves a script is *declared*, not that it runs. So it may also execute a **fixed allowlist of side-effect-free probes**, after one consent ask: `--help`, `--version`, `make -n`, bare script listings, and read-only git.

Never: anything that installs, builds, migrates, deploys, publishes, or calls a live service. **The allowlist is written down and never inferred** — a command that looks harmless but isn't on the list is not run, and the claim is reported as unverified instead.

## The doc map

The unit all modes operate on, living at `<doc home>/.wikimap.yaml` — dotfile-prefixed so GitHub's folder view and every engine build skip it. One entry per page with its Diátaxis mode and the globs of code it documents.

That `documents:` field is what makes `update` cheap — a code-path → page lookup that doesn't read every page — and what gives `audit` its recency prefilter.

Diátaxis governs internally and stays **out of the reader's face**. The four modes are the rule that keeps doc types unmixed, not jargon to print on the page.

Two boundaries the vocabulary encodes:

- **`CONTRIBUTING.md` is linked, never written.** Dev-environment setup and release steps are in the repo and verify like any other how-to. PR etiquette, a code of conduct, and review norms are a social contract that exists nowhere in code — writing them would break the grounding rule on the repo's most visible contributor page.
- **`reference.md` covers declared surface only** — CLI commands, flags, env vars, config keys: things declared in one place and re-verifiable in a single grep. Library symbols and hand-maintained endpoint tables are refused and routed to a generator.

## The provenance stamp

Every page wikikit authors ends with one line: `_Verified against `main`@`a1b2c3d` on 2026-08-06._`

Both halves earn their place — `audit` diffs from the SHA while it's reachable and falls back to the date when a squash-merge has orphaned it.

**A page with no stamp is not stale, it is unverified.** That's how adopted pages are marked: a page wikikit found rather than wrote gets a manifest entry and `adopted: true`, and no stamp. It can see the page and route to it, and has never checked a claim on it. **Adoption is a mapping act, not an authorship claim** over prose a human wrote.

## Modes

### `init`

For a repo with no doc set. It runs a **detection ladder** and says which rung matched before writing anything: a configured docs engine wins outright, then an existing reader-doc tree gets adopted as-is, and only then does it fall back to `docs/wiki/`.

That fallback keeps reader docs quarantined from the agent artifact directories sharing the `docs/` parent, so a reader never lands in a QA plan. But **an existing engine always wins** — wikikit writes into the site the repo already runs and never introduces MkDocs or Docusaurus into a repo that doesn't have one.

The consent gate that matters is the **map proposal**: the page list with a one-line scope each, which entries are newly authored versus adopted, and **what wikikit could not determine from code**. You accept, trim, or redirect before a single file is written.

It also owns exactly one zone of the README — what this is, the quickstart, and the links into the doc set — delimited by marker comments, inferred positionally on the first run and exact thereafter. Refuse the markers and it writes nothing to the README at all, and says so.

### `update`

For a change that just landed. **The diff is the input**; reading the repo instead is how a one-flag change turns into a six-page rewrite.

Changed code maps to affected pages through the manifest's globs, and **which pages are deliberately untouched gets stated before editing, not in the report afterward**. That untouched list is the load-bearing half — it's what tells you the skill knew what it was leaving alone.

**The discipline here is restraint.** A changed flag edits the flag; it does not regenerate the page. A skill that rewrites six pages because one function moved is worse than no skill, because now the PR diff is unreviewable.

Edits land directly. **New pages and deletions are consent-gated** — that split is the whole write-mode policy.

### `audit`

**Read-only. Writes nothing, ever.** It reports and routes; fixing is a separate invocation, deliberately.

Three checks, cheapest first: **recency** (the stamp against commits touching the documented code — a prefilter, not a verdict), **claim verification** (the load-bearing one, budgeted and spent highest-risk-first), and **coverage** (documentable surface with no page at all).

Verdicts are `current`, `stale`, `broken`, `unverified` — an adopted page never claim-checked, distinct from stale — and `missing`.

Every report **opens** with a mandatory coverage line, because an audit that silently covered 12% reads exactly like a clean bill of health. The not-claim-checked pages are **listed, not summarized as a count**.

### `publish`

**Opt-in, explicit-ask-only.** Nothing routes into it, and a request has to name the GitHub wiki to reach it. A repo that never asks never learns it exists.

It installs a workflow mirroring the doc set to the wiki tab. Three properties get said out loud before anything is written:

1. **The sync is destructive and one-way.** The action clears the wiki repo and force-pushes. Any page created or edited in the wiki's web UI is **deleted on the next sync**. The wiki becomes read-only in practice; the edit button stays there and lies.
2. **The page namespace is flat.** `how-to/deploy.md` and `runbooks/deploy.md` both resolve to `/wiki/deploy` and one silently wins, so the workflow flattens path segments into the page name and a collision scan runs before install.
3. **The wiki must be created by hand, once.** A repo's wiki has no git backend until a first page exists, and no API creates one.

Existing wiki content gets a **rescue** offered before anything else — cloned into the repo as adopted pages — and the workflow installs with `dry-run: true`, so the first run is a rehearsal. A destructive force-push should never be something you discover happening.

## Writing standards

Stated as bans: no restating the code · no documenting the aspirational · no unmixed modes · no ceremonial preamble · every command copy-pasteable and verified · task-shaped how-to titles.

For general AI-writing tells, it offers a [`humankit`](./humankit.md) pass rather than re-carrying that list.

## Hands off to

After `init`: read the set — it's new prose about your project and the one thing a human should actually check — then [`commitkit`](./commitkit.md). After `update`: commitkit then [`prkit`](./prkit.md), because docs land in the same PR as the code that changed them; that's the whole point of in-repo docs.

`audit` crowns the single most-broken page and routes it to `update`, or to `init` when the gap is a missing page rather than a wrong one. **Nothing to fix is a valid, stated result.**

## Install

```sh
npx skills add mimukit/skills -s wikikit
```

Source: [`skills/wikikit/SKILL.md`](../../../skills/wikikit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`fd96414` on 2026-08-07._
