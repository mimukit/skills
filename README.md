# mimukit/skills

[![lint](https://github.com/mimukit/skills/actions/workflows/lint.yml/badge.svg)](https://github.com/mimukit/skills/actions/workflows/lint.yml)

<!-- wikikit:front-door:start -->
My personal collection of AI agent skills for day-to-day development, installable and managed with [skills.sh](https://www.skills.sh).

Every skill here is **authored from scratch**, never forked. Some are *my version of* a popular upstream skill, rewritten to fit this collection's conventions.

Each skill works standalone, but they're built as one loop: **decide → plan → file → build → ship → land**. [The workflow guide](./docs/wiki/workflow.md) covers the day-to-day, including every skill's modes, the handoffs between them, and the order to run them in. If you're not sure what to run, `statuskit` will tell you.

Full documentation lives in [`docs/wiki/`](./docs/wiki/). [Getting started](./docs/wiki/getting-started.md) splits by what you're here for: [installing the skills](./docs/wiki/getting-started.md#install-and-use-the-skills) and using them, or [working on the collection](./docs/wiki/getting-started.md#work-on-the-collection). The architecture and command reference sit alongside it.
<!-- wikikit:front-door:end -->

## Naming philosophy

Skills here follow one convention: a **`kit` suffix**, functional word first (`commitkit`, `humankit`, `prkit`).

The suffix is personal. It's hidden in my name, mu**kit**, and it reads as "a kit for X." Leading with the functional term keeps the names searchable, so a search for `commit` still surfaces `commitkit` while searching `kit` surfaces the whole collection. Names are one word and lowercase, and an awkward root gets shortened rather than forced (`humanize` → `humankit`, not `humanizekit`).

The repo itself isn't renamed. `mimukit/skills` is branded by the owner handle, the emerging convention for a developer's personal skill collection. See [AGENTS.md](./AGENTS.md) for the full convention.

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
| `skillkit` | author a new skill from scratch — conventions, testing, and publishing included | public |
| `promptkit` | sharpen the prompt before you send it — a one-shot agent instruction grounded in the real repo, or the system prompt your app ships | public |
| `gitkit` | the shared git layer — worktree convention and lifecycle, base-ref resolution, rebase-vs-merge policy | public |
| `commitkit` | conventional git commits from the diff | public |
| `prkit` | draft & open a GitHub PR from the branch diff | public |
| `mergekit` | pull an open PR into a worktree, sync it, set it up for manual review, then merge it on your say-so | public |
| `releasekit` | cut a release from the Conventional Commits already in the log — derive the semver bump and changelog, bump the manifest, tag it, publish the GitHub release | public |
| `issuekit` | create, start, close, sync, and triage GitHub issues across the workflow | public |
| `repokit` | set a repo's About description + topics, and provision the issuekit lifecycle labels | public |
| `orcakit` | reconcile the Orca app's workspace list with your git worktrees — link them to their issues, and clean out the ones whose work merged | public |
| `paseokit` | push your git worktrees into Paseo's workspace registry and reap the rows whose directories are gone — Paseo discovers nothing on its own | public |
| `designkit` | derive a project's design system from the UI it already ships into a spec-compliant `DESIGN.md`, and keep it true as the code moves | public |
| `humankit` | strip AI-writing tells from prose | public |
| `wikikit` | generate and maintain in-repo reader docs — getting-started, how-tos, architecture, runbooks — with every command verified against the code | public |
| `qakit` | generate a manual QA/test plan for a just-built feature | public |
| `validatekit` | pressure-test a startup idea and grade the evidence behind it before you build | public |
| `plankit` | turn a rough idea into a structured plan doc before any code | public |
| `grillkit` | interrogate any idea one decision at a time before you commit | public |
| `researchkit` | research the options for a technical decision against primary sources and recommend one | public |
| `prototypekit` | answer a question by building a throwaway — a drivable state model, a measurement script, or competing UI mocks — then delete the code and keep the answer | public |
| `implementkit` | implement a plan, spec, or issue into code (straight-through or TDD), gated on tests + build | public |
| `uikit` | build production UI that reads as a deliberate choice for the project, and audit shipped UI for the tells that give it away | public |
| `refactorkit` | survey an existing codebase for the structural change worth making, rank the candidates, and crown one — proposes, never edits | public |
| `reviewkit` | review AI-written changes in four passes — convention-fit, agent-slop, completeness, correctness — against the working tree or branch diff | public |
| `verifykit` | drive a built frontend feature in a browser and capture screenshots + a GIF as PR-ready proof, published to a hidden git ref | public |
| `testkit` | retrofit an automated suite onto a codebase that has none — rank the untested surface, crown a slice, and keep only tests that were watched to fail | public |
| `debugkit` | chase a symptom to its root cause — reproduce, shrink, test falsifiable hypotheses, prove it with an on/off toggle — and hand over a failing reproduction instead of a fix | public |
| `handoffkit` | compact the session into a handoff another agent can pick up cold | public |
| `domainkit` | scribe the domain model as a byproduct of design — a CONTEXT.md glossary and docs/adr/ decision records | public |
| `statuskit` | survey a project read-only and crown one finish-first next move, routing to the kit that does it | public |
| `afkkit` | run a grilled `ready` issue to an open PR unattended — worktree, implement, commit, review, fix, QA, PR — escalating cleanly when it hits a wall | public |
| `tutorkit` | teach a topic across sessions from one learning repo, with lessons pitched at what you know and spaced review that makes it stick | public |
| `ideakit` | think an idea through across sessions from one ideas repo — a folder per idea, one open at a time, research and validation folded back into its own log | public |

[The workflow guide](./docs/wiki/workflow.md) covers how these fit together in practice: the modes each one exposes, what hands off to what, and a worked end-to-end day.

Skills I want to build next live in the backlog at [IDEAS.md](./IDEAS.md). A shipped skill graduates from there into the table above.

**Visibility** is declared per skill as `metadata.internal` in frontmatter. `internal` skills are repo-only maintenance tools that skills.sh hides from discovery, so they never get published. There are none right now, and the slot lives at `.agents/skills/`. `public` skills are portable and self-contained, and pushing them to this repo is all it takes for skills.sh to list them via install telemetry. See [AGENTS.md](./AGENTS.md) for the convention.

## Using a skill

Install any skill into your agents via skills.sh:

```sh
npx skills add mimukit/skills               # all skills
npx skills add mimukit/skills -s commitkit  # just one
```

## Developing a skill

Fast inner loop: symlink your working copy into every AI tool's skills dir at once (`~/.claude/skills` for Claude Code, `~/.agents/skills` for Codex, opencode, antigravity, and the rest):

```sh
make link name=commitkit     # save-and-test against the live repo
make unlink name=commitkit   # remove the dev symlink
```

Run either with no `name=` to get an interactive picker showing each skill's current link status. `make list` prints the same status table, and `make lint` checks every skill against the repo conventions in [AGENTS.md](./AGENTS.md). `make security` runs a heuristic security scan, a local stand-in for the scanners skills.sh runs at publish time (Gen / Socket / Snyk), so a risky flag surfaces here before it lands on the public directory page.

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

If you've already installed a skill from skills.sh and want to iterate on the repo copy under the same name, just `make link` it. When the dev link collides with a real install, `make link` moves the published one aside to a `<name>.skshbak` sibling (status becomes `⇄ swapped`) and symlinks the repo copy in its place. `make unlink` removes the symlink and restores the backup, so you test the real thing and get your published install back untouched. If a `.skshbak` backup already exists, `make link` refuses that dir rather than clobber it.

Ship a skill by committing + pushing, then consume it through skills.sh like any other skill. See [PUBLISHING.md](./PUBLISHING.md) for how the skills.sh directory listing works, the pre-push checklist, and first-time repo setup.

## License

[MIT](./LICENSE) © 2026 Mukitul Islam Mukit
