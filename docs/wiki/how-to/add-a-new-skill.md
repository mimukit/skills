# Add a new skill

Adding a skill means creating one directory — but shipping one means updating three other files that lint mostly can't check for you.

Prefer to have this driven for you? `skillkit` runs the whole path, from naming through testing. This page is what it does by hand.

## 1. Name it

One lowercase word, functional term first, `kit` appended: `commitkit`, `humankit`, `prkit`.

- **The functional word leads**, so the skill stays searchable — people search `commit`, not `kit`. Never bury the term behind a prefix.
- **Shorten an awkward root** rather than force a clumsy join: `humanize` → `humankit`, not `humanizekit`.
- **Check for collisions** with well-known tools. `speckit` (GitHub's spec-kit) and `shipkit` (a SaaS boilerplate) are already taken.

Lint warns if the name isn't a single lowercase word ending in `kit`, and errors if it doesn't match the directory.

## 2. Create the directory

```sh
mkdir -p skills/<name>
```

Public skills live in `skills/`. A repo-only meta skill that only makes sense inside this collection goes in `.agents/skills/<name>/` instead, where it's auto-discovered without a dev link and stays out of the `skills/`-based tooling. That directory is currently empty — every skill here is public.

## 3. Write the frontmatter

```yaml
---
name: <matches directory>
description: >-
  <what it does>. Use when <explicit English trigger>.
license: MIT
allowed-tools: <only if the skill needs a restricted set>
metadata:
  internal: false   # true = repo-only meta skill; false = public/publishable
---
```

Two fields do more work than they look like they do.

**`description` is a routing rule, not a title.** Agents and skills.sh decide whether to activate a skill primarily from this field, so it must front-load an explicit English "Use when …" trigger. That's what makes a branded name like `humankit` findable by someone who only knows they want to remove AI-isms.

**`metadata.internal` is a lint error if absent**, because an undeclared skill has undefined publication behavior. `false` publishes it; `true` hides it from skills.sh discovery entirely.

## 4. Write the body

Full conventions are in [AGENTS.md](../../../AGENTS.md). The three that lint enforces:

- **No hard wrapping.** One continuous line per paragraph and per list item. Code fences, tables, and YAML frontmatter keep their line structure.
- **Never cross-reference a step by number.** `see step 4` binds to a step's *position*, so inserting a step silently makes it point at the wrong one — and nothing can detect a stale-but-valid number. Link to the heading instead: `see [Group the work](#4-group-the-work)`. For a step with no heading, name the action in prose.
- **Close with `## Hand off`** — what changed, where it landed, and the single best next move. Crown one next move rather than listing five; route to the next kit by name without invoking it, and always give the plain fallback ("open a PR with **prkit**, otherwise `gh pr create`") since a public skill often lands in a repo that has none of the others.

If you marked it `internal: false`, it must also be **portable**: conventions inlined rather than linked, no repo-relative links, no dependency on `make` or `AGENTS.md` or `scripts/`, and it should print its output as a code block when there's no filesystem to write to. It will be installed alone into repos that have none of the machinery here.

## 5. Lint it

```sh
make lint name=<name>
```

Fix errors; warnings are advisory but usually worth clearing. Then check it doesn't trip the scanners:

```sh
make security name=<name>
```

`Med` is normal for a skill that drives the shell. `High` means detection-evasion phrasing or a destructive command pattern, and blocks the run.

## 6. Test it live

```sh
make link name=<name>
```

The skill is now readable by every AI tool on the machine. Invoke it, edit, save, invoke again — no build, no reload. `make unlink name=<name>` puts things back.

## 7. Update the three files lint won't fully catch

This is the step that gets missed.

| File | Change |
|------|--------|
| `README.md` | Add a row to the skills table with a one-line description and its visibility. |
| `skills.sh.json` | Add the skill to the best-fitting group's `skills` array. Never list `internal: true` skills. Create a new group only if none fits — a skill left out of every group falls into "Other skills". |
| [`docs/wiki/workflow.md`](../workflow.md) | Add it to the loop phase it belongs to, or to the side kits if it isn't part of the loop. |
| [`IDEAS.md`](../../../IDEAS.md) | If the skill was on the backlog, **delete its row.** Nothing lives in both `IDEAS.md` and the README table. |

Lint catches only the workflow map, and only partially — it verifies that skills and modes the map *names* still exist, not that a new skill was added to it. `README.md`, `skills.sh.json`, and `IDEAS.md` are on the [pre-push checklist](../../../PUBLISHING.md#pre-push-checklist) instead.

`skills.sh.json` affects only how the directory page groups things. It changes nothing about how the CLI installs skills.

## 8. Run the full gate and push

```sh
make lint
make security
git push origin main
```

The full run adds the cross-file checks a scoped run skips. There's no publish step beyond the push — skills.sh re-reads the repo on the next install.

## Next

If you changed how skills are structured rather than just adding one, [Architecture](../architecture.md) is the page that will go stale.

_Verified against `main`@`fd96414` on 2026-08-07._
