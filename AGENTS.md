# AGENTS.md

Conventions for AI agents authoring or maintaining skills in this repository — a personal collection of AI agent skills. Follow these whenever you create, rename, or edit a skill.

## Skill naming: the `kit` convention

Every skill uses a **`kit` suffix** — a personal brand hidden in the owner's name, mu**kit**, that also reads as "a kit for X."

Rules:
- **One word, lowercase**, functional term first with `kit` appended: `commitkit`, `humankit`, `diffkit`.
- **The functional word must lead** so the skill stays searchable — people search `commit`, not `kit`. Never bury the term behind a prefix.
- **Shorten an awkward root** rather than force a clumsy join: `humanize` → `humankit`, not `humanizekit`.
- **Avoid collisions** with well-known tools: `speckit` (GitHub spec-kit), `shipkit` (SaaS boilerplate), and anything already popular.
- The `name:` field in a skill's frontmatter **must match its directory name exactly**.

## Descriptions

- Every `SKILL.md` `description` must front-load an English **"Use when …"** trigger, so agent triggering and text search work regardless of the branded name.

## Prose formatting

- **No hard wrapping.** Write each paragraph and list item as one continuous line; let the editor and renderer soft-wrap. Fixed-width line breaks mid-sentence buy nothing here — the agent reads the text regardless of newlines, and every Markdown renderer soft-wraps anyway. Keeping prose on one line per paragraph makes editing and reflowing painless.
- This applies to prose and bullets only. Leave line structure intact where it is meaningful: code fences, tables, and YAML frontmatter (a folded `description: >-` scalar is fine).

## Layout

- Flat: `skills/<name>/SKILL.md` — one skill per directory.
- Skills are **authored from scratch, never forked.**
- For a skill that is "my version of" an upstream skill, record provenance in the root `baselines.json` (repo, path, branch, last-reviewed marker). Snapshots cache in the gitignored `.baselines/`. Use the `diffkit` skill to compare against upstream.
- Bash lives in `scripts/`, surfaced through the `Makefile` (`make help`).

## Frontmatter template

```yaml
---
name: <matches directory>
description: >-
  <what it does>. Use when <explicit English trigger>.
license: MIT
allowed-tools: <only if the skill needs a restricted set>
---
```
