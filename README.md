# mimukit/skills

My personal collection of AI agent skills for day-to-day development — installable and managed with [skills.sh](https://www.skills.sh).

Every skill here is **authored from scratch**, never forked. Some are *my version of* a popular upstream skill; for those, [`baselines.json`](./baselines.json) records the upstream link purely as a **reference for improvement**, surfaced on demand by [`diffkit`](./skills/diffkit/SKILL.md).

## Naming philosophy

Skills here follow one convention: a **`kit` suffix** — functional word first, `kit` appended (`commitkit`, `humankit`, `diffkit`).

- **`kit` is personal** — it's hidden in my name, mu**kit** — and reads naturally as "a kit for X."
- **Still searchable** — the functional term leads, so a search for `commit` still surfaces `commitkit`; searching `kit` surfaces the whole collection.
- **One word, lowercase.** Shorten an awkward root rather than force it (`humanize` → `humankit`, not `humanizekit`).

The repo itself isn't renamed — `mimukit/skills` is branded by the owner handle, the emerging convention for a developer's personal skill collection. See [AGENTS.md](./AGENTS.md) for the full convention.

## Layout

```
skills/<name>/SKILL.md   one flat skill per directory
baselines.json           upstream provenance (repo, path, branch, last-reviewed marker)
.baselines/              gitignored snapshot cache for the diffkit change-feed
scripts/                 bash helpers (link, unlink, list, lint, baseline)
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

Run either with no `name=` to get an interactive picker showing each skill's current link status. `make list` prints the same status table, and `make lint` checks every skill against the repo conventions in [AGENTS.md](./AGENTS.md).

Ship a skill by committing + pushing, then consume it through skills.sh like any other skill.

## Keeping "my version" skills fresh with diffkit

Because these skills are rewritten from scratch rather than forked, they don't get upstream updates for free. [`diffkit`](./skills/diffkit/SKILL.md) closes that gap: it turns the reference link in `baselines.json` into two concrete comparisons and, if you want, drafts the improvements straight into your skill.

### The mental model

`baselines.json` is a **reference for improvement, not a fork relationship**. diffkit never overwrites your skill with upstream — it reads upstream, tells you what's worth adopting, and only edits when you say so. Two independent comparisons drive that:

- **Semantic gap analysis** (yours vs. upstream *now*) — reasons about *capabilities*, not wording, since your version shares no lines with upstream. It surfaces sections, edge cases, or guardrails the base covers that yours doesn't, and notes where you deliberately differ so those choices aren't "fixed" by mistake.
- **Change feed** (upstream *now* vs. upstream *at your last review*) — a plain line diff against a cached snapshot, so you see exactly what moved upstream since you last looked. Cheap and precise.

The workflow separates **looking** from **acknowledging**: reviewing never records anything, so the same pending changes keep surfacing until you explicitly mark a skill as caught up.

### Prerequisites

- The skill has an entry in [`baselines.json`](./baselines.json) (skip this for originals like diffkit itself — it has no baseline).
- `jq` and `curl` on your `PATH` (the baseline helper uses both).
- Network access to fetch the raw upstream `SKILL.md` from GitHub.

### Running it

The everyday path is the skill itself — from your agent, run:

```
/diffkit <name>          # e.g. /diffkit commitkit
/diffkit                 # no name → lists skills that have a baseline, asks which
```

diffkit walks the full loop: load your skill and the baseline, fetch upstream, run both comparisons, print a report, offer to draft the improvements you accept, and — only on your confirmation — mark the skill reviewed.

Under the hood it leans on `scripts/baseline.sh` (surfaced through the Makefile) for the mechanical half. You can also drive that directly, without the skill, when you just want the raw diff or to reset the watermark:

```sh
make diff name=commitkit     # fetch upstream + line-diff vs the snapshot (read-only)
make diff                    # no name → interactive picker of baselined skills
make save name=commitkit     # mark reviewed: refresh snapshot + stamp baselines.json
scripts/baseline.sh list     # list every skill that has a baseline entry
```

`make diff` **only looks** — it writes nothing. `make save` is the single "I've caught up" action: it refreshes the cached snapshot in `.baselines/` **and** stamps `last_reviewed_sha` (best-effort from the GitHub API, `null` if rate-limited) and `last_reviewed_at` (today) into `baselines.json`. Never hand-edit the snapshot cache or those `last_reviewed_*` fields — `make save` owns them.

### Registering a new baseline

To start tracking a skill against an upstream, add an entry to `baselines.json`. Each skill maps to one or more `sources` (a skill can draw from several upstreams):

```json
{
  "commitkit": {
    "sources": [
      {
        "repo": "github/awesome-copilot",
        "path": "skills/git-commit/SKILL.md",
        "branch": "main",
        "last_reviewed_sha": null,
        "last_reviewed_at": null
      }
    ]
  }
}
```

diffkit builds the fetch URL as `https://raw.githubusercontent.com/<repo>/<branch>/<path>` (falling back to `master` if the branch 404s). Leave the two `last_reviewed_*` fields `null` — the first `make save` fills them in. From then on, `make diff` shows only what changed since that watermark.

## License

[MIT](./LICENSE) © 2026 Mukitul Islam Mukit
