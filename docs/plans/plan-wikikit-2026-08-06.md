# Plan — wikikit

_Created 2026-08-06._
_Grilled: 2026-08-06_
_Updated 2026-08-06 — the GitHub Wiki non-goal was reversed after shipping; see [Amendment](#amendment--github-wiki-publishing-reinstated-as-an-opt-in-mode)._

## Context

The collection documents **process** exhaustively and **the product** not at all. `domainkit` pins the vocabulary and the irreversible decisions. `handoffkit` compacts a session for the next agent. `plankit`, `qakit`, `reviewkit`, and `statuskit` each leave a dated artifact under `docs/`. Every one of those is written for a maintainer or an agent mid-flow. Nothing in the loop writes the thing a **reader** opens: how do I run this, how do I do the one task I came here for, how is it put together, and what do I do at 3am when it's down.

That gap has a predictable shape. A repo built through this loop ends up with a rich `docs/plans/` tree, a precise `CONTEXT.md`, a dozen ADRs — and a README that still says `npm install` from the day it was scaffolded. The knowledge exists; it's just scattered across artifacts nobody outside the project will ever read.

**wikikit** is the reader-facing half. It generates a documentation set from the codebase as it actually is, keeps that set true as code changes, and reports honestly when it has gone stale. It links to `domainkit`'s glossary and ADRs rather than restating them — the domain model has one owner, and it isn't this skill.

**Success:** point wikikit at a brownfield repo with no docs and get a doc set a new user could actually onboard from, with every command in it verified against the repo. Then change the code, run `update`, and watch exactly the invalidated pages change — no drive-by rewrites of pages the change didn't touch.

## Design decisions (settled)

Settled with the user on 2026-08-06 — the first block during the plankit scoping pass, the second during the grillkit pass the same day.

| Decision | Resolution |
|----------|-----------|
| **Name** | `wikikit` — kept. Functional word leads, one word, kit-suffixed, and "wiki" reads in plain English as "the project's documentation," which is what people search. Rejected `docskit` (generic, loose collision with the doc-site-starter genre) and `guidekit` (weaker search match — people search "docs," not "guide"). Accepted risk: "wiki" suggests the GitHub Wiki tab, which is explicitly out of scope; the skill body must say so in its first paragraph. |
| **Modes** | **Three: `init` / `update` / `audit`.** `init` bootstraps the set from the codebase, `update` refreshes only what a change invalidated, `audit` sweeps read-only for stale and missing docs. Matches "generate *and maintain*" and mirrors the multi-mode shape `issuekit`, `mergekit`, and `orcakit` already use. Rejected generate-only (docs rot immediately and nothing picks it up) and maintain-only (useless on the brownfield no-docs repo, which is the common case). |
| **Home** | **`docs/wiki/`.** Reader docs quarantined from the agent artifact dirs (`docs/plans/`, `docs/qa/`, `docs/reviews/`, `docs/handoffs/`) that share the `docs/` parent. One path to state, one path to check, and no chance of a reader landing in a QA plan. |
| **Existing docs engine wins** | When the repo already runs a docs site — MkDocs, Docusaurus, VitePress, Starlight, Sphinx, Nextra — wikikit writes into **that site's configured content directory** and updates its nav/sidebar config, rather than forcing `docs/wiki/`. `docs/wiki/` is the fallback for a repo with no engine. Same "existing project convention wins" rule the rest of the collection follows for artifact paths. |
| **README ownership** | **wikikit owns the README's front door** — what this is, quickstart, and the links into the doc set. It does **not** touch badges, license, acknowledgments, or anything else below that zone. The README is the most-read page in any repo; leaving it out of the maintained set is how it ends up lying about the install command. The zone is delimited by **marker comments**, bootstrapped positionally — see the grill row below. |
| **Taxonomy** | **Diátaxis, applied loosely.** The four modes (tutorial / how-to / reference / explanation) are the internal rule that keeps doc types unmixed — a how-to must not drift into explanation, an architecture page must not turn into a tutorial. Ships as the plain-English set: getting-started, how-to guides, architecture overview, runbooks. The framework governs; the jargon stays out of the reader's face. |
| **Grounding** | **Every factual claim is verified against the repo before it ships** — commands from the actual `package.json`/`Makefile`/`pyproject.toml`, paths that exist, env vars that are actually read, endpoints that are actually routed. A feature wikikit cannot find in code does not get documented. This is the single rule that separates a doc set from plausible fiction. |
| **Provenance stamp** | Each generated page carries a one-line footer anchored to **both a commit and a date**: `_Verified against `main`@`a1b2c3d` on 2026-08-06._` `audit` diffs from the SHA while it is still reachable and falls back to the date when a rebase or squash-merge has orphaned it — precise when it can be, degrading instead of lying when it can't. This is what makes `audit` cheap, the same way `grillkit`'s `Grilled:` stamp gives `issuekit` provenance. **A page with no stamp is not stale, it is unverified** — that is how adopted pages are marked. |
| **Boundary — domainkit** | wikikit **links, never rewrites.** `CONTEXT.md` and `docs/adr/` have one owner. A doc that needs a term defines nothing; it links to the glossary. An architecture page that needs a rationale links the ADR by number instead of paraphrasing it. If a term is missing from the glossary, route to `domainkit`; don't define it inline. |
| **Boundary — handoffkit** | `handoffkit` writes for the next **agent**, mid-flight, and expires. wikikit writes for a **reader**, and is durable. No overlap, but the description must be written so agent triggering never lands on the wrong one. |
| **Boundary — humankit** | wikikit carries its own anti-slop rules for documentation specifically (below). General prose tells stay `humankit`'s job, offered as an optional pass. |
| **Visibility** | **Public** (`internal: false`). Conventions inlined, no repo-relative links, no `make`/`AGENTS.md` dependency. Degrades to printing pages as codeblocks when there is no writable filesystem. |
| **Layout** | Single flat `skills/wikikit/SKILL.md`. No satellite files, no bundled scripts. |

Settled in the grill pass:

| Decision | Resolution |
|----------|-----------|
| **Contributor docs** | **Split on the derivable/social seam.** Dev-environment setup and release steps are *in the repo* and verify like any other how-to, so they join the map as `how-to/set-up-a-dev-environment.md` and `how-to/cut-a-release.md`. A `CONTRIBUTING.md` is a social contract that exists nowhere in code — PR etiquette, code of conduct, review norms — so wikikit never writes it, only links it from `index.md`. Writing it would break the grounding rule on the repo's most visible contributor page. |
| **Reference material** | **Declared surface only.** Where a generator exists (TypeDoc, Sphinx autodoc, OpenAPI), link its output — unchanged. Where none exists, wikikit writes **one `reference.md` limited to surfaces declared in a single place and re-verifiable in a single grep**: CLI commands, flags, env vars, config keys. Library symbols and hand-maintained HTTP API tables stay refused and route to a generator. This is the narrow exception that keeps a CLI with twenty flags and no docs tooling from getting nothing at all. |
| **Monorepos** | **Root set always; per-package sets only when a package earns one.** Earning it means independently published or independently runnable. Detect the workspace (`pnpm-workspace.yaml`, `workspaces`, `go.work`, Cargo workspace), write the root set (index, getting-started, architecture, runbooks), and add `packages/<x>/docs/` only for packages that qualify. State the split before writing anything. Rejected root-only (the architecture page becomes unusable past ~4 packages) and always-per-package (wrong for an app monorepo, where the reader wants one getting-started). |
| **Verification depth** | **Static by default, plus a fixed allowlist of side-effect-free probes.** Reading a manifest proves a script is *declared*, not that it runs, so wikikit may execute `--help`, `--version`, `make -n`, and script listing — the allowlist is written into the skill body, never inferred — after **one consent ask per run**. Anything that installs, builds, migrates, or deploys is never executed. `audit`'s "read-only" means *it writes no files*, so probes are available there too; that is where they pay off most. |
| **The doc map** | **A per-set manifest at `<doc home>/.wikimap.yaml`** — one entry per page carrying its Diátaxis mode and its `documents:` globs. `update` gets a code-path → page lookup without reading every page; `audit` gets the paths each page describes for its recency prefilter. Dotfile-prefixed so GitHub's folder view and every engine build skip it without a config edit. Rejected per-page frontmatter (visible on GitHub, collides with engine schemas) and re-deriving each run (throws away exactly the cheapness `audit` is designed around). |
| **Manifest drift** | **A reconcile pass at the top of every mode.** Pages on disk with no entry, entries with no page, `documents:` globs matching nothing, and a doc home that no longer matches the Phase 3 ladder are all reported *before* any work starts. `init` and `update` repair on consent; `audit` reports drift as its own row and repairs nothing, because it writes nothing, ever. A central manifest is the one map shape that can be wrong while looking right — this pass is the price of choosing it. |
| **Multi-set discovery** | **Glob for manifests** — one `**/.wikimap.yaml` sweep scoped to the repo's workspace globs plus the root, honoring `.gitignore` so a vendored tree cannot inject a set. No root registry to keep in sync, and a set added later is found automatically. Every mode names the sets it found in its first line, so a missing set is visible immediately rather than inferred from an empty result. |
| **Adoption** | **Pages wikikit did not write are mapped, not stamped.** Rung 2 adopts an existing docs tree as-is, which otherwise leaves those pages invisible to the skill that manages them. An adopted page gets a manifest entry with `documents:` globs and **no stamp** — `audit` reports it *unverified* rather than *stale*, `update` touches it only for a claim the diff actually broke, and it earns its first stamp the first time a verification pass genuinely covers it. Adoption is a mapping act, not an authorship claim over prose a human wrote. |
| **`update` write mode** | **Split on the operation.** Edits to existing pages write directly — they are already bounded by the restraint rule and land in a reviewable diff. **New pages and deletions stay consent-gated**, matching `init`. The affected/untouched page list is stated *before* editing, not in the report afterward. |
| **`audit` scale** | **Recency-ordered budget.** The recency prefilter is grep-cheap, so it runs over **every** page; the expensive claim pass spends its budget highest-risk-first. A scope argument (`audit how-to/`) is available as an explicit override. Every report carries a mandatory coverage line — `Recency: 312/312 · Claims verified: 40/312 (highest-risk first) · Not claim-checked: 272 (listed below)` — because an audit that silently covered 12% reads exactly like a clean bill of health. Rejected sampling (skips the page you needed) and a staged queue (breaks "writes nothing, ever"). |
| **Engine added after `init`** | **Reported as drift, migrated only on consent.** When rung 1 starts matching where rung 3 matched before, the reconcile pass names both paths. `audit` reports and stops; `init` and `update` offer the `git mv` plus nav update as a single consented step. Inherits Phase 3's rule that a migration is never implicit. Rejected auto-migration (a large diff nobody asked for) and dual-writing (two copies that diverge by the second `update`). |
| **afkkit wiring** | **Edits-only `update`, between `qakit` and `prkit`.** The unattended span writes the surgical edits to pages that already exist — precisely the half of the write-mode split that is safe without a human — and skips everything consent-gated. New pages and deletions become checklist lines in the PR body for whoever opens it. Docs land in the same reviewable diff as the code, which is the point of in-repo docs; nothing unreviewed is *created*. |
| **GitHub Wiki** | **Out of scope entirely** — promoted from open question to hard non-goal. Researched and rejected on three constraints: the wiki must be initialized by hand through the UI before any push works and `gh` cannot do it; its page namespace is flat, so `how-to/deploy.md` and `runbooks/deploy.md` collide; and a public repo's wiki is world-editable by default, so a one-way mirror destroys strangers' edits. No `publish` mode, no offered CI workflow. The skill body's first paragraph carries the disambiguation. |

## Approach

Reuses, rather than reinvents: `reviewkit`'s working-tree-then-branch-diff target resolution and its "name the base ref via gitkit when installed" pattern; `domainkit`'s consent-gated write loop for the `init` map; `orcakit`'s per-mode `Hand off` structure; the `plan-<slug>-YYYY-MM-DD.md` artifact-naming rule already in force across the collection.

### Phase 1 — Frontmatter and triggers

`name: wikikit`, `license: MIT`, `metadata.internal: false`, `allowed-tools: Read, Write, Edit, Grep, Glob, Bash, AskUserQuestion` (Bash for read-only repo inspection — `git log`, `git diff`, listing scripts — never for mutating the project).

The `description` front-loads what it does, then a pushy **"Use when …"** naming real phrasings: "write docs for this project", "document this repo", "update the docs", "our docs are stale", "write a runbook", "getting-started guide", "architecture overview", "/wikikit". It must also disambiguate away from `handoffkit` (agent-facing, ephemeral) and `domainkit` (glossary and ADRs) in the same line.

### Phase 2 — Body: identity and boundaries

One paragraph on the job, then what it is explicitly **not**:

- **Not the GitHub Wiki.** In-repo Markdown, versioned with the code, reviewed in the same PR. The wiki tab is out of scope.
- **Not the domain model.** Glossary and ADRs belong to `domainkit`; wikikit links to them.
- **Not process artifacts.** Plans, QA plans, reviews, handoffs, and agent instruction files (`CLAUDE.md`, `AGENTS.md`) are not reader docs and are never touched.
- **Not an API reference generator.** Where a generator exists (TypeDoc, Sphinx autodoc, OpenAPI), wikikit links to its output rather than hand-writing reference material that will drift within a week.

### Phase 3 — Shared: locate the doc sets

Every mode opens the same way — find the sets, then reconcile them — so all three agree on where docs live before anything reads or writes.

**a. Find existing sets.** One `**/.wikimap.yaml` glob, scoped to the repo root plus any workspace globs, honoring `.gitignore`. Every set found is named in the mode's first line of output.

**b. For a repo with no set, run the detection ladder:**

1. **A configured docs engine** — `mkdocs.yml`, `docusaurus.config.*`, `.vitepress/`, `astro.config.*` with Starlight, `conf.py`, `nextra` config. Found → use its content dir, and update its nav/sidebar in the same pass.
2. **An existing reader-doc tree** — a populated `docs/` that isn't just the artifact dirs, or `documentation/`, `website/docs/`. Found → adopt it as-is; don't migrate.
3. **Fallback** — `docs/wiki/`, created on first write.

In a workspace, the ladder runs once for the root set and again for each package that earns its own — independently published or independently runnable.

**c. Reconcile each set against disk** before doing any work: pages with no manifest entry, entries with no page, `documents:` globs matching nothing, and a `home:` that no longer matches the ladder (a docs engine arrived after `init`). `init` and `update` repair on consent; `audit` reports and repairs nothing.

State which rung matched before writing anything. A migration is never implicit.

### Phase 4 — Shared: the doc map

The doc map is the unit all three modes operate on, and it lives in `<doc home>/.wikimap.yaml` — one entry per page carrying its Diátaxis mode and the globs of code it documents:

| Page | Diátaxis mode | Documents |
|------|---------------|-----------|
| `index.md` | — | entry point and table of contents |
| `getting-started.md` | tutorial | install → run → first successful thing |
| `how-to/<task>.md` | how-to | one task per page, goal-shaped |
| `how-to/set-up-a-dev-environment.md` | how-to | the derivable half of contributor docs |
| `how-to/cut-a-release.md` | how-to | ditto — release steps that exist in the repo |
| `architecture.md` | explanation | components, boundaries, data flow, links to ADRs |
| `runbooks/<scenario>.md` | how-to (operator) | deploy, rollback, incident response, backup/restore |
| `reference.md` | reference | declared surface only — commands, flags, env vars, config keys; omitted entirely when a generator exists |

The map is derived from the repo, not from this table — a library with no deployment gets no runbooks, a CLI gets a commands page. The table is the vocabulary, not a quota.

A manifest entry without a stamp on its page means **adopted but unverified** — wikikit can see the page and route to it, and has never checked a claim on it.

### Phase 5 — Mode: `init`

For a repo with no doc set, or a partial one.

1. **Ground it.** Read the manifests and scripts, entry points, CLI surface, routes, env vars, config, Dockerfile/compose, CI, deploy config, existing README, and `CONTEXT.md`/`docs/adr/` when present. Ask once for consent to run the allowlisted probes (`--help`, `--version`, `make -n`, script listing) and use them to confirm the commands that will end up in `getting-started.md`. This is a research pass, and it is the bulk of the work.
2. **Adopt what's already there.** Pages found under rung 2 get manifest entries with `documents:` globs and **no stamp**. wikikit does not rewrite them and does not claim them.
3. **Propose the map** — the page list with a one-line scope each, which entries are newly authored versus adopted, and what wikikit could *not* determine from code. Consent-gated: the user accepts, trims, or redirects before a single file is written.
4. **Write the accepted pages**, each grounded per the verification rule and stamped with `<ref>@<sha>` plus the date.
5. **Rewrite the README front door.** First run infers the zone positionally, shows the exact proposed boundary, and writes `<!-- wikikit:front-door:start -->` / `<!-- wikikit:front-door:end -->` on consent — every later run is exact. Refuse the markers and wikikit writes nothing to the README and says so.
6. **Write the manifest** to `<doc home>/.wikimap.yaml`.
7. **Update the docs engine nav** when one was detected.

### Phase 6 — Mode: `update`

For a change that just landed. The target resolves the way `reviewkit`'s does: uncommitted working-tree changes first, otherwise the branch diff against the base ref (`gitkit` when installed, else the repo's default branch).

1. **Read the diff**, not the whole repo.
2. **Map changed code to affected pages** through the manifest's `documents:` globs, and state which pages are affected and which are deliberately untouched — before editing, not after.
3. **Edit only the affected pages**, surgically and **directly** — a changed flag edits the flag, it does not regenerate the page. These edits need no gate: they are bounded by the restraint rule and land in a reviewable diff. An adopted (unstamped) page is edited only for a claim the diff actually broke.
4. **Flag documentation-shaped gaps** the diff created: a new command with no how-to, a new env var absent from getting-started, a new failure mode with no runbook. **New pages and deletions are consent-gated** — propose, then write.
5. **Re-stamp** every page it touched, and update the manifest for anything created or removed.

The discipline here is restraint. A skill that rewrites six pages because one function moved is worse than no skill, because now the PR diff is unreviewable.

### Phase 7 — Mode: `audit`

**Read-only. Writes nothing, ever.** It reports, and routes to `update` or `init` for the fixing.

Three checks per page, cheapest first:

- **Recency** — the page's stamp against the commits touching the code it documents, diffing from the stamped SHA when it is still reachable and falling back to the date when it isn't. Grep-cheap, so it runs over **every** page. A prefilter, not a verdict; a stale stamp on an unchanged concept is fine.
- **Claim verification** — the load-bearing one. Every command, path, env var, flag, and endpoint on the page checked against the repo, with the allowlisted probes available on consent. A command that no longer exists is a **broken** claim; a described behavior that changed is **stale**. This pass is budgeted and spends highest-risk-first, ordered by the recency prefilter.
- **Coverage** — documentable surface with no page at all: an undocumented CLI command, a deploy path with no runbook, a public entry point missing from the architecture page.

Output is a table per page — `current` / `stale` / `broken` / `unverified` / `missing` — with quoted evidence for anything not `current`, plus a manifest-drift row, and one crowned next move. `unverified` is an adopted page wikikit has never checked, and is distinct from `stale`.

Every report opens with a mandatory coverage line, because an audit that silently covered 12% reads exactly like a clean bill of health:

```
Recency: 312/312 · Claims verified: 40/312 (highest-risk first) · Not claim-checked: 272 (listed below)
```

A scope argument (`audit how-to/`) narrows the run explicitly; the coverage line reports the narrowing either way.

### Phase 8 — Writing standards

The rules that separate documentation from generated filler, stated as bans with replacements:

- **No restating the code.** A page that narrates what a function does line by line is worse than the function.
- **No documenting the aspirational.** If it isn't in the repo, it isn't in the docs.
- **No unmixed modes.** A how-to answers one goal and does not explain the architecture; an explanation does not become a tutorial halfway down.
- **No ceremonial preamble.** "This document provides an overview of…" — cut. Start at the first useful sentence.
- **Every command copy-pasteable and verified.** Real flags, real paths, real names.
- **Task-shaped how-to titles** — "Deploy to staging", not "Deployment".
- Offer a `humankit` pass for general prose tells when it's installed; wikikit does not re-carry that list.

### Phase 9 — Hand off (per mode)

One closing section per mode, three beats each — what changed, where it landed, one crowned next move.

- **`init`** → review the set, then `commitkit`. If a term surfaced that belongs in the glossary, route to `domainkit`.
- **`update`** → `commitkit`, then `prkit`. Docs land in the same PR as the code that changed them; that's the whole point of in-repo docs.
- **`audit`** → the single most-broken page, routed to `update` (or `init` when the gap is a missing page). Nothing to fix is a valid, stated result.

### Phase 10 — Wire-up (repo housekeeping)

- Delete the `wikikit` row from `IDEAS.md` and add it to the README Skills table (`public`).
- Add to `skills.sh.json` — widen the **Writing** group to *Writing & Docs* and put `wikikit` in it alongside `humankit`.
- Add wikikit to `WORKFLOW.md`: a subsection under Phase 4 — Build (`update` sits beside `qakit`/`verifykit`, before `prkit`), and a line in the side-kits list for `init`/`audit` as on-demand entry points.
- Wire `afkkit`: an **edits-only** `wikikit update` step between `qakit` and `prkit` — surgical edits to existing pages land in the PR, consent-gated new pages and deletions become checklist lines in the PR body. This touches `afkkit`'s span, so it lands as its own issue after wikikit itself ships.
- `make lint name=wikikit` clean.
- Live-test with `make link` in a fresh session: `init` against a brownfield repo with no docs, `update` against a real branch diff, and `audit` against a repo whose docs are known-stale — confirming it reports `broken` rather than quietly fixing.

## Open questions

**None — the grill on 2026-08-06 closed all eleven.** Their resolutions live in the second decisions table above. Two rejections worth keeping as provenance, since both cost real research and will otherwise be re-proposed:

- **GitHub Wiki publishing — rejected, not deferred.** A wiki is a git repo at `<repo>.wiki.git`, so the mirror itself is a ~12-line Action ([`Andrew-Chen-Wang/github-wiki-action@v5`](https://github.com/Andrew-Chen-Wang/github-wiki-action) with `path: docs/wiki` and the built-in `GITHUB_TOKEN` + `contents: write`; [`spenserblack/actions-wiki`](https://github.com/spenserblack/actions-wiki) for PR-shaped edits; [`newrelic/wiki-sync-action`](https://github.com/newrelic/wiki-sync-action) for two-way sync). It was rejected on the three constraints around it, not the mirror: the wiki must be **initialized by hand** through the UI before any push works and `gh` cannot do it; the page namespace is **flat**, so `how-to/deploy.md` and `runbooks/deploy.md` collide; and a public repo's wiki is **world-editable** by default, so a one-way push destroys strangers' edits. No `publish` mode and no offered workflow file.
- **A central root registry of doc sets — rejected.** Considered as a `.wikikit.yaml` at the repo root keyed by set, which would survive a doc-home move for free. Lost to a per-set `.wikimap.yaml` plus a discovery glob: the manifest travels with the set it describes, and a monorepo needs no file that every package has to remember to update.

## Amendment — GitHub Wiki publishing, reinstated as an opt-in mode

**2026-08-06, after the skill shipped.** The owner asked for a wiki-sync mode anyway, scoped as optional and explicit-ask-only. Re-researching the three constraints before building it found that **one of them was wrong**, and turned up a fourth that is worse:

| Constraint from the grill | Status on re-check |
|---|---|
| Wiki must be **initialized by hand**; `gh` cannot do it | **Still true.** The action's own docs: "You must create a dummy page manually!" Handled as a preflight gate that refuses to install a workflow doomed to fail. |
| Page namespace is **flat**, so `how-to/deploy.md` and `runbooks/deploy.md` collide | **Still true** — Gollum's design; folders exist on disk but page URLs are built from the title alone. Handled by flattening path segments into the page name in the workflow, plus a collision scan that stops rather than tiebreaking. |
| Public-repo wikis are **world-editable by default** | **False as of now.** GitHub's docs: "only repository collaborators can edit a public repository's wiki," and *Restrict editing to collaborators only* is **on by default**. This constraint no longer exists. |
| — | **New, and worse than the one it replaces.** Reading `Andrew-Chen-Wang/github-wiki-action`'s source: it removes everything but `.git` from the wiki clone, copies the source dir in, and runs `git push -f origin master` — **under both strategies**, though `action.yml` documents force-push as `init`-only. `ignore` is appended to `.git/info/exclude`, which does not shield already-tracked pages from the wipe. So every wiki-UI edit dies at the next sync, on private repos too. |

The net: the mirror is *buildable* and the original blockers are handleable, but it is destructive and one-way, which is a real property to consent to rather than a footnote. So `publish` ships **fenced** — nothing routes into it, the loop never suggests it, the request must name the wiki, the preflight offers to rescue existing wiki pages before they're destroyed, and the installed workflow starts in `dry-run` so going live is a separate deliberate commit.

The rejection reasoning above is kept as written rather than edited, because the record of *why* it was rejected is what stops it being re-proposed on the old grounds — and one of those grounds turning out to be false is exactly the thing worth remembering.

## Non-goals

- **GitHub Wiki publishing is opt-in, never a default.** Superseded by the amendment above: a `publish` mode exists, fenced behind an explicit ask. The doc set remains in-repo Markdown, versioned and reviewed with the code, and the wiki is a derived, disposable mirror that is never read back as truth.
- **No glossary, no ADRs.** `domainkit` owns both; wikikit links to them and routes when one is missing.
- **No process artifacts.** Plans, QA plans, reviews, handoffs, and agent instruction files are never read as sources of truth for reader docs and never written.
- **No `CONTRIBUTING.md`.** The social contract half of contributor docs isn't in the repo, so it can only be invented. Linked, never written.
- **No hand-written API reference.** `reference.md` covers declared surface only — commands, flags, env vars, config keys. Library symbols and HTTP endpoint tables link a generator's output or don't exist.
- **No mutating execution.** The probe allowlist is fixed and side-effect-free. wikikit never installs, builds, migrates, or deploys to verify a claim.
- **No doc-site scaffolding.** wikikit writes content and updates nav for an engine that already exists. It never introduces MkDocs or Docusaurus into a repo that doesn't run one.
- **No marketing copy.** Landing pages, feature blurbs, and changelogs are out.
- **No translation or localization.**
- **No writes in `audit`.** Reporting a problem and fixing it are separate invocations, deliberately.
