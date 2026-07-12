# mimukit/skills

[![lint](https://github.com/mimukit/skills/actions/workflows/lint.yml/badge.svg)](https://github.com/mimukit/skills/actions/workflows/lint.yml)

My personal collection of AI agent skills for day-to-day development — installable and managed with [skills.sh](https://www.skills.sh).

Every skill here is **authored from scratch**, never forked. Some are *my version of* a popular upstream skill, rewritten to fit this collection's conventions.

## Naming philosophy

Skills here follow one convention: a **`kit` suffix** — functional word first, `kit` appended (`commitkit`, `humankit`, `prkit`).

- **`kit` is personal** — it's hidden in my name, mu**kit** — and reads naturally as "a kit for X."
- **Still searchable** — the functional term leads, so a search for `commit` still surfaces `commitkit`; searching `kit` surfaces the whole collection.
- **One word, lowercase.** Shorten an awkward root rather than force it (`humanize` → `humankit`, not `humanizekit`).

The repo itself isn't renamed — `mimukit/skills` is branded by the owner handle, the emerging convention for a developer's personal skill collection. See [AGENTS.md](./AGENTS.md) for the full convention.

## Layout

```
skills/<name>/SKILL.md   one flat skill per directory
scripts/                 bash helpers (link, unlink, list, lint)
Makefile                 command surface (run `make help`)
```

## Skills

| Skill | What it does | Visibility |
|-------|--------------|------------|
| `skillkit` | Author a new skill from scratch — conventions, testing, and publishing included | internal |
| `commitkit` | conventional git commits from the diff | public |
| `prkit` | draft & open a GitHub PR from the branch diff | public |
| `humankit` | strip AI-writing tells from prose | public |

**Visibility** is declared per skill as `metadata.internal` in frontmatter. `internal` skills (`skillkit`) are repo-only maintenance tools — skills.sh hides them from discovery, so they aren't published. `public` skills are portable and self-contained; pushing them to this repo is all it takes for skills.sh to list them via install telemetry. See [AGENTS.md](./AGENTS.md) for the convention.

## Using a skill

Install any skill into your agents via skills.sh:

```sh
npx skills add mimukit/skills               # all skills
npx skills add mimukit/skills -s commitkit  # just one
```

## Developing a skill

Fast inner loop — symlink your working copy straight into `~/.claude/skills`:

```sh
make link name=commitkit     # save-and-test against the live repo
make unlink name=commitkit   # remove the dev symlink
```

Run either with no `name=` to get an interactive picker showing each skill's current link status. `make list` prints the same status table, and `make lint` checks every skill against the repo conventions in [AGENTS.md](./AGENTS.md).

Ship a skill by committing + pushing, then consume it through skills.sh like any other skill. See [PUBLISHING.md](./PUBLISHING.md) for how the skills.sh directory listing works, the pre-push checklist, and first-time repo setup.

## License

[MIT](./LICENSE) © 2026 Mukitul Islam Mukit
