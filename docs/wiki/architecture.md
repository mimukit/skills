# Architecture

This repo has no application code. It's a collection of Markdown instruction files plus the shell tooling that keeps them consistent and gets them onto machines. Understanding it means understanding four things: where skills live, how they reach an agent, what enforces the conventions, and how they get published.

## A skill is a directory with one file

```
skills/<name>/SKILL.md
```

That's the whole unit. YAML frontmatter declares the skill's identity and routing; the body is the instructions an agent reads. No manifest ties the collection together — `skill_names()` in `scripts/lib.sh` enumerates the collection by globbing `skills/*/` and keeping directories that contain a `SKILL.md`. Adding a skill is creating a directory; there is nothing to register.

The frontmatter carries the contract:

- **`name`** must match the directory exactly, and be one lowercase word ending in `kit`. The suffix is a personal brand that reads as "a kit for X"; the functional word leads so a search for `commit` still finds `commitkit`.
- **`description`** front-loads an English "Use when …" trigger. This is a routing rule, not a title — agents and skills.sh decide whether to activate a skill primarily from this field, so the branded name never has to be the thing that matches.
- **`metadata.internal`** declares visibility, and is the one field with consequences outside this repo.
- **`allowed-tools`** scopes what the skill may do. Every skill here declares it. A skill that leaves it out inherits every tool the host offers, Bash included — lint warns and the security scan flags it.

## Two homes, one boundary

| Location | For | Discovery |
|----------|-----|-----------|
| `skills/<name>/` | public skills, and any skill being dev-linked for testing | `make` tooling, `make lint`, skills.sh |
| `.agents/skills/<name>/` | internal skills that only make sense inside this repo | auto-discovered by tools that read `.agents/skills`, plus a committed relative symlink at `.claude/skills/<name>` |

The split exists because internal skills would otherwise pollute the public surface. A skill in `.agents/skills/` is always on inside this repo, needs no dev link, and stays out of the `skills/`-based lint, list, and skills.sh machinery by design.

`.agents/skills/` is empty — no skill has needed it yet. All 34 skills live in `skills/`, and every one is `metadata.internal: false`.

**`internal: true` is effectively unpublished.** skills.sh honors the field natively and hides such skills from discovery — they install only when someone sets `INSTALL_INTERNAL_SKILLS=1`. That's why the marker is a lint *error* rather than a warning: an undeclared skill has undefined publication behavior.

The price of `internal: false` is portability. A public skill gets installed alone into repos that have none of the others, so it must be self-contained — conventions inlined rather than linked, no dependency on this repo's `Makefile` or `AGENTS.md`, no repo-relative links, and it has to degrade to printing its output when there's no filesystem to write to. Lint checks the mechanical half of this.

## How a skill reaches an agent

Skills are tool-agnostic, but AI tools disagree about where skills live. The repo targets both conventions at once:

```
skills/<name>/  ──┬──▶  ~/.claude/skills/<name>     (Claude Code)
                  └──▶  ~/.agents/skills/<name>     (Codex, opencode, antigravity, …)
```

`scripts/lib.sh` holds both destinations in `SKILL_DEST_DIRS`, each overridable via `CLAUDE_SKILLS_DIR` and `AGENTS_SKILLS_DIR`. Every operation loops over that array, which is why one `make link` makes a skill live everywhere simultaneously.

### The status model

The interesting design problem is that a dev symlink and a real skills.sh install compete for the same path. `lib.sh` resolves this in two layers.

`link_status()` classifies one destination directory: **linked** (our symlink), **foreign** (a symlink pointing elsewhere), **real** (a genuine file or directory), or **unlinked** (nothing there).

`agg_status()` then folds the per-directory answers into the single badge you see in `make list`, and the folding rules encode a policy:

- Any `real` anywhere wins the whole verdict, because a non-symlink install is something the tooling must not silently modify.
- All destinations `linked` gives `linked` — or `swapped` when a `.skshbak` backup exists alongside, meaning the repo copy is running in place of a published install.
- Present in some destinations but not cleanly linked in all gives `partial`, which is the signature of an interrupted `link` or `unlink`.

**Nothing is ever deleted to make room.** When `link` meets a `foreign` or `real` entry it renames it to `<name>.skshbak` (the suffix is `SKILL_BACKUP_SUFFIX`) and symlinks over it; `unlink` removes the symlink and moves the backup back. If a backup already exists, `link` refuses that directory rather than clobber it — the one case where the tooling stops instead of resolving. [Recover a wedged dev link](./how-to/recover-a-wedged-dev-link.md) covers getting out of it.

`lib.sh` is sourced, never executed, and is kept bash 3.2 safe so it runs on macOS's system bash.

## What enforces the conventions

Two scripts, both surfaced through the `Makefile` and both run in CI by `.github/workflows/lint.yml` on pushes to `main` and on every pull request.

### `make lint`

Per skill, it checks frontmatter validity — `SKILL.md` exists with frontmatter, `name` matches the directory and fits the `kit` pattern, `description` carries a "Use when" trigger, `license` is present, `metadata.internal` is declared as a boolean — and then three more things:

**A declared tool surface.** `allowed-tools` is a warning rather than an error, because a skill can have a defensible reason to inherit everything. The escape hatch is `TOOLS_EXEMPT` in the script, currently empty, and joining it means writing the reason into the skill's own Notes. The field is load-bearing here rather than decorative: `researchkit` withholds Bash precisely so a host that honors the declaration cannot run a spike instead of reading sources. An undeclared surface should be a decision somebody made, not one nobody noticed.

**Reference integrity.** It builds the set of GitHub heading anchors for the document (mirroring github-slugger's rules) and checks every intra-doc `](#anchor)` link against it. A broken anchor is an error. It also flags `step N`-style cross-references as warnings, because a bare number binds to a step's *position* — reorder the steps and the reference silently points at the wrong one, with no tool able to detect it. A named anchor binds to identity instead and breaks loudly right here.

**A closing hand-off section.** Every skill is required to end by recapping what it did and naming the next move. Lint can only verify such a section exists; whether its content is any good is a review judgment. `gitkit` is the sole exemption, as the primitives layer other skills call into.

Full runs add three cross-file checks that a per-skill run (`make lint name=<skill>`) deliberately skips:

- **Shared-contract tables.** Two tables are duplicated across skills on purpose, because each skill must stand alone once installed and so neither pair can point at a shared source: the lifecycle label map between `issuekit` and `repokit`, and the commit-type table between `commitkit` and `issuekit`. Nothing else keeps the copies aligned, so lint diffs them.
- **The workflow map.** [`docs/wiki/workflow.md`](./workflow.md) duplicates skill facts deliberately so a reader gets one map. Lint guards the three that rot on a rename: every skill it names must exist, every `<kit> <mode>` invocation must name a mode that skill actually defines, and every lifecycle label in its vocabulary section must still live in `issuekit`. These are greps over backtick spans — a loud tripwire, not a proof.
- **The per-skill wiki pages.** [`docs/wiki/skills/`](./skills/) carries one reader-facing page per skill, which likewise duplicates skill facts on purpose. Lint checks page-per-skill in **both** directions — a skill with no page, and a page documenting no skill — plus mode parity, so a renamed mode breaks loudly instead of leaving a page that lies. It checks two more registrations the same way, because a page can exist and still be lost: one the doc map [`.wikimap.yaml`](./.wikimap.yaml) doesn't list is one no audit will sweep, and one [`index.md`](./index.md) doesn't link is one no reader can reach. Both failures are invisible at a glance — the file is on disk, the headings parse, the gate is green — and between them they slipped past six skill launches before the checks existed. Presence is all they enforce; the index groups by theme, and no linter can tell a skill filed under the wrong heading from one filed right. It also warns when a commit touching exactly one skill lands without that skill's page — the shape of a forgotten page edit. That scoping is the whole design: a repo-wide prose sweep touches most of the collection at once and genuinely owes no page edit, so an unscoped version of this check would open at a warning per skill touched, with nearly all of them correct to ignore, which is how a warning gets muted and stops working.

Errors fail the run; warnings are reported and don't.

### `make security`

A heuristic scan that is explicitly *not* trying to be byte-identical to the scanners skills.sh runs at publish time (Gen Agent Trust Hub, Socket, Snyk). It catches the same **classes** of finding so a flag surfaces locally before it appears publicly on the directory page.

Six classes, each mapped to the scanner it mirrors, each carrying a severity. A skill's tier is the maximum severity across its findings, and the run fails when the worst tier reaches `SECURITY_FAIL_TIER` — `high` by default. In practice `Med` is the normal resting state for a skill that legitimately drives the shell, which is most of them; `High` means detection-evasion phrasing or a destructive command pattern, and is a real signal.

## How skills get published

**There is no publish step.** skills.sh discovers a repo through install telemetry: the first time anyone runs `npx skills add mimukit/skills` against a public GitHub repo containing a valid `skills/<name>/SKILL.md`, the repo gets a directory page. Publishing a change is therefore `git push`, and nothing else triggers it.

That inverts the usual dependency. Because the directory reads the repo directly, the repo's own state *is* the published state — which is why the conventions are enforced by CI rather than by a release process, and why `skills.sh.json` (which groups how skills render on the directory page, and affects nothing about how the CLI installs them) has to be updated in the same change that adds or renames a public skill. Lint doesn't check that file; the [pre-push checklist](../../PUBLISHING.md#pre-push-checklist) does.

## Documentation layout

`docs/` holds two kinds of thing that should not be confused.

| Path | Kind | Tracked |
|------|------|---------|
| `docs/wiki/` | reader documentation — this set | yes |
| `docs/plans/` today, joined by `docs/research/`, `docs/reviews/`, `docs/qa/`, `docs/handoffs/`, `docs/debug/`, `docs/refactor/`, `docs/prompts/`, `docs/validation/`, `docs/adr/` as skills write them | process artifacts written for a maintainer mid-flow; they expire | yes |
| `docs/status/`, `docs/tests/`, `docs/verify/` | disposable scratch output | no — gitignored |

Process artifacts record what was decided at a moment in time and are never read as sources of truth for reader documentation. A plan that describes a skill's intended design may have been superseded by the skill itself.

Artifacts are named `<type>-<slug>-YYYY-MM-DD.md` using their **creation** date, which stays fixed when the file is edited.

_Verified against `main`@`d2e9d3b` on 2026-08-24._
