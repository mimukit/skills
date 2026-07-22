# AGENTS.md

Conventions for AI agents authoring or maintaining skills in this repository — a personal collection of AI agent skills. Follow these whenever you create, rename, or edit a skill.

## Skill naming: the `kit` convention

Every skill uses a **`kit` suffix** — a personal brand hidden in the owner's name, mu**kit**, that also reads as "a kit for X."

Rules:
- **One word, lowercase**, functional term first with `kit` appended: `commitkit`, `humankit`, `prkit`.
- **The functional word must lead** so the skill stays searchable — people search `commit`, not `kit`. Never bury the term behind a prefix.
- **Shorten an awkward root** rather than force a clumsy join: `humanize` → `humankit`, not `humanizekit`.
- **Avoid collisions** with well-known tools: `speckit` (GitHub spec-kit), `shipkit` (SaaS boilerplate), and anything already popular.
- The `name:` field in a skill's frontmatter **must match its directory name exactly**.

## Descriptions

- Every `SKILL.md` `description` must front-load an English **"Use when …"** trigger, so agent triggering and text search work regardless of the branded name.

## Prose formatting

- **No hard wrapping.** Write each paragraph and list item as one continuous line; let the editor and renderer soft-wrap. Fixed-width line breaks mid-sentence buy nothing here — the agent reads the text regardless of newlines, and every Markdown renderer soft-wraps anyway. Keeping prose on one line per paragraph makes editing and reflowing painless.
- This applies to prose and bullets only. Leave line structure intact where it is meaningful: code fences, tables, and YAML frontmatter (a folded `description: >-` scalar is fine).

## Cross-referencing steps

- **Never reference a step by its number** (`see step 4`, `from step 2`). A bare number binds to a step's *position*, so inserting or reordering steps silently makes it point at the wrong one — and no tool can detect a stale-but-valid number. Reference the step's *identity* instead.
- For a step that has a heading, link to it by name with a GitHub anchor: `see [Group the work into multiple commits](#4-group-the-work-into-multiple-commits)`. GitHub builds the anchor from the full heading text (lowercase, punctuation dropped, spaces → hyphens, consecutive hyphens preserved, `'` removed — `what's` → `whats`). Numbered headings are fine to keep; the anchor and the link move together.
- For a step that's a list item inside a section (no heading, no anchor), name the action in prose (`` `start`'s **Adopt check** step``) rather than citing its ordinal.
- `make lint` enforces both halves: every intra-doc `](#anchor)` link must resolve to a real heading (error), and any surviving `step N` reference is flagged (warning). Rename or move a referenced heading and the link breaks *loudly* in lint instead of rotting silently.

## Visibility: internal vs public

Skills here fall into two classes, declared explicitly in frontmatter as `metadata.internal: true|false`:

- **`internal: true`** — a repo-only maintenance/meta skill (e.g. `skillkit`). It may lean on this repo's machinery: `AGENTS.md`, the `Makefile`, repo-relative links. skills.sh honors this native field by **hiding the skill from discovery** — it only installs when someone sets `INSTALL_INTERNAL_SKILLS=1`, so internal skills are effectively unpublished.
- **`internal: false`** — a publishable skill (e.g. `commitkit`, `humankit`). It must be **portable**: self-contained (conventions inlined, no repo-relative links, no hard dependency on `make`/`AGENTS.md`/`scripts/`), machine/OS-agnostic, and environment-degrading — it writes files when a filesystem is available and otherwise prints its output as a codeblock. Once pushed to the public repo, skills.sh discovers `skills/<name>/SKILL.md` automatically and lists it via install telemetry; there is no separate publish step.

`make lint` enforces the marker on every skill and flags likely portability breaks in public skills.

## Directory page: `skills.sh.json`

The repo-root `skills.sh.json` groups how public skills render on the skills.sh directory page (it does not affect CLI installs). **Whenever you add, rename, or remove a public (`internal: false`) skill, update `skills.sh.json` in the same change** so the grouping stays in sync:

- Add every new public skill to the most fitting group's `skills` array (create a new group only when an existing one doesn't fit); rename or drop entries when a skill is renamed or removed.
- Never list `internal: true` skills — skills.sh hides them from discovery, and they are silently ignored here anyway.
- Skills left out of every group fall into an "Other skills" section positioned by `notGrouped` — that's an acceptable landing spot until a skill earns a group.

## Layout

- Flat: `skills/<name>/SKILL.md` — one skill per directory. This is home for **public** skills and any skill you dev-link for testing.
- **Internal, always-on repo skills live in `.agents/skills/<name>/`** instead (e.g. `skillkit`). Checked in there, they're auto-discovered by any tool that reads `.agents/skills` and by Claude Code via a committed relative symlink at `.claude/skills/<name>` — no `make link` needed. This is the right home for a meta-skill that only makes sense *inside this repo*; it keeps such skills off the global tool dirs and out of the `skills/`-based `make lint`/`make list`/skills.sh machinery by design.
- Skills are **authored from scratch, never forked.** A skill may be "my version of" an upstream skill, rewritten to fit these conventions.
- Bash lives in `scripts/`, surfaced through the `Makefile` (`make help`). `make link`/`unlink` mirror a dev symlink into **both** `~/.claude/skills` and `~/.agents/skills` so the skill is live in every AI tool at once. When a dev link collides with a **real install of the same name** (e.g. a `skills.sh` install of `commitkit`), `make link` moves the real one aside to a `<name>.skshbak` sibling and symlinks over it — the skill shows as `⇄ swapped` in `make list` — and `make unlink` restores the backup, so you can live-test the repo copy under its real name without losing the published install.

## Frontmatter template

```yaml
---
name: <matches directory>
description: >-
  <what it does>. Use when <explicit English trigger>.
license: MIT
allowed-tools: <only if the skill needs a restricted set>
metadata:
  internal: true   # true = repo-only meta skill; false = public/publishable
---
```
