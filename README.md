# mimukit/skills

My personal collection of AI agent skills for day-to-day development — installable and
managed with [skills.sh](https://www.skills.sh).

Every skill here is **authored from scratch**, never forked. Some are *my version of* a
popular upstream skill; for those, [`baselines.json`](./baselines.json) records the
upstream link purely as a **reference for improvement**, surfaced on demand by
[`diffkit`](./skills/diffkit/SKILL.md).

## Naming philosophy

Skills here follow one convention: a **`kit` suffix** — functional word first, `kit`
appended (`commitkit`, `humankit`, `diffkit`).

- **`kit` is personal** — it's hidden in my name, mu**kit** — and reads naturally as
  "a kit for X."
- **Still searchable** — the functional term leads, so a search for `commit` still surfaces
  `commitkit`; searching `kit` surfaces the whole collection.
- **One word, lowercase.** Shorten an awkward root rather than force it
  (`humanize` → `humankit`, not `humanizekit`).

The repo itself isn't renamed — `mimukit/skills` is branded by the owner handle, the
emerging convention for a developer's personal skill collection. See
[AGENTS.md](./AGENTS.md) for the full convention.

## Layout

```
skills/<name>/SKILL.md   one flat skill per directory
baselines.json           upstream provenance (repo, path, branch, last-reviewed marker)
.baselines/              gitignored snapshot cache for the diffkit change-feed
scripts/                 bash helpers (dev-link, unlink)
Makefile                 command surface (run `make help`)
```

## Skills

| Skill | What it does | Baseline |
|-------|--------------|----------|
| `diffkit` | Compare a skill against its upstream base; surface & optionally apply improvements | — (original) |
| `commitkit` | *(draft)* conventional git commits | `github/awesome-copilot` |
| `humankit` | *(draft)* strip AI-writing tells from prose | `blader/humanizer` |

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

Ship it by committing + pushing, then consume it through skills.sh like any other skill.

## Keeping "my version" skills fresh

For a skill with a `baselines.json` entry, run:

```
/diffkit <name>
```

It fetches the current upstream, does a semantic gap analysis (what the base covers that
yours doesn't) plus a change-feed diff (what changed upstream since your last review),
prints a report, optionally drafts the improvements you accept, and — only if you confirm —
marks the skill as reviewed.

## License

[MIT](./LICENSE) © 2026 Mukitul Islam Mukit
