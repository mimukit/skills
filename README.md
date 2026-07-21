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
skills/<name>/SKILL.md          one flat skill per directory (published + dev-linked)
.agents/skills/<name>/SKILL.md   internal, project-scoped skills, always on in this repo
scripts/                        bash helpers (link, unlink, list, lint)
Makefile                        command surface (run `make help`)
```

## Skills

| Skill | What it does | Visibility |
|-------|--------------|------------|
| `skillkit` | Author a new skill from scratch — conventions, testing, and publishing included | internal · lives in `.agents/skills/` |
| `commitkit` | conventional git commits from the diff | public |
| `prkit` | draft & open a GitHub PR from the branch diff | public |
| `issuekit` | create, sync, and triage GitHub issues across the workflow | public |
| `repokit` | set a repo's About description + topics, and provision the issuekit lifecycle labels | public |
| `humankit` | strip AI-writing tells from prose | public |
| `qakit` | generate a manual QA/test plan for a just-built feature | public |
| `plankit` | turn a rough idea into a structured plan doc before any code | public |
| `grillkit` | interrogate any idea one decision at a time before you commit | public |
| `implementkit` | implement a plan, spec, or issue into code (straight-through or TDD), gated on tests + build | public |
| `reviewkit` | review AI-written changes in four passes — convention-fit, agent-slop, completeness, correctness — against the working tree or branch diff | public |
| `handoffkit` | compact the session into a handoff another agent can pick up cold | public |

Skills I want to build next live in the backlog at [IDEAS.md](./IDEAS.md) — a shipped skill graduates from there into the table above.

**Visibility** is declared per skill as `metadata.internal` in frontmatter. `internal` skills (`skillkit`) are repo-only maintenance tools — skills.sh hides them from discovery, so they aren't published. `public` skills are portable and self-contained; pushing them to this repo is all it takes for skills.sh to list them via install telemetry. See [AGENTS.md](./AGENTS.md) for the convention.

## Using a skill

Install any skill into your agents via skills.sh:

```sh
npx skills add mimukit/skills               # all skills
npx skills add mimukit/skills -s commitkit  # just one
```

## Developing a skill

Fast inner loop — symlink your working copy into every AI tool's skills dir at once (`~/.claude/skills` for Claude Code, `~/.agents/skills` for Codex, opencode, antigravity, …):

```sh
make link name=commitkit     # save-and-test against the live repo
make unlink name=commitkit   # remove the dev symlink
```

Run either with no `name=` to get an interactive picker showing each skill's current link status. `make list` prints the same status table, `make lint` checks every skill against the repo conventions in [AGENTS.md](./AGENTS.md), and `make security` runs a heuristic security scan — a local stand-in for the scanners skills.sh runs at publish time (Gen / Socket / Snyk) — so a risky flag surfaces here before it lands on the public directory page.

### Link status

`make list` (and the pickers) report each skill's dev-link status, aggregated across both target dirs (`~/.claude/skills` and `~/.agents/skills`):

| Badge | Status | Meaning |
|-------|--------|---------|
| `●` | **linked** | Your dev symlink is in place in *every* target dir, pointing at the repo copy — live for save-and-test, no conflict. |
| `⇄` | **swapped** | Linked, but over a backed-up real install. A same-named install (e.g. a skills.sh `commitkit`) was moved aside to `<name>.skshbak` so the repo copy can run under its real name. `make unlink` restores it. |
| `◑` | **partial** | Present in some target dirs but not a clean link in all — usually a half-finished link/unlink. Re-run `make link` to fix. |
| `◆` | **foreign** | A symlink exists but points somewhere other than this repo's copy (an old location or another checkout). `make link` replaces it. |
| `■` | **real** | A non-symlink install lives there (typically from skills.sh). Plain operations won't touch it; `make link` turns it into `swapped`. |
| `○` | **unlinked** | Not present in any target dir — the skill exists only in the repo, not active in any AI tool. |

Quick model: `●`/`⇄` mean the repo copy is what's live; `○`/`■`/`◆` mean it isn't; `◑` means the two dirs disagree and need a re-link.

### Swapping over a published install

If you've already installed a skill from skills.sh and want to iterate on the repo copy under the same name, just `make link` it. When the dev link collides with a real install, `make link` moves the published one aside to a `<name>.skshbak` sibling (status becomes `⇄ swapped`) and symlinks the repo copy in its place. `make unlink` removes the symlink and restores the backup — so you test the real thing, then get your published install back untouched. If a `.skshbak` backup already exists, `make link` refuses that dir rather than clobber it.

Ship a skill by committing + pushing, then consume it through skills.sh like any other skill. See [PUBLISHING.md](./PUBLISHING.md) for how the skills.sh directory listing works, the pre-push checklist, and first-time repo setup.

## License

[MIT](./LICENSE) © 2026 Mukitul Islam Mukit
