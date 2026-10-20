# Add a new skill

Adding a skill means creating one directory — but shipping one means updating up to six other files. Lint now checks most of them, but not all.

Prefer to have this driven for you? `skillkit` runs the whole path, from naming through testing. This page is what it does by hand.

## 0. Check it earns a skill

A new skill spends two budgets. Its `description` sits in the agent's context on every turn whether or not it fires, and its existence sits in *your* head forever — you're the index of which skill owns which moment, and nothing pages you out.

The second cost is the one worth thinking about, and it isn't a reason to keep the collection small. It's the price of choosing yourself. So the test is whether a person genuinely wants to make this call — a distinct moment, a decision you'd reach for deliberately. If the agent should be picking it from context anyway, it's a **mode inside an existing skill**, which costs one branch in that skill's description rather than a permanent new entry to remember.

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

Public skills live in `skills/`. A repo-only meta skill that only makes sense inside this collection goes in `.agents/skills/<name>/` instead, where it's auto-discovered without a dev link and stays out of the `skills/`-based tooling. That directory does not exist yet, because every skill here is public.

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

**`description` is a routing rule, not a title.** Agents and skills.sh decide whether to activate a skill primarily from this field, so it must front-load an explicit English "Use when …" trigger. Lead with one what-clause, start the trigger within the first 300 characters, and keep the whole field under 1,024, the Agent Skills limit; lint warns on both. That's what makes a branded name like `humankit` findable by someone who only knows they want to remove AI-isms.

Spend it on **one trigger per branch, not per synonym**. Every description in the collection loads on every turn, and what that budget buys is coverage of the distinct cases the skill handles, usually one per mode. Rephrasing the same case three ways buys nothing. Dropping a case buys silence, and lint can't see a skill that never fires — so cut synonyms, never coverage.

**`metadata.internal` is a lint error if absent**, because an undeclared skill has undefined publication behavior. `false` publishes it; `true` hides it from skills.sh discovery entirely.

## 4. Write the body

Full conventions are in [AGENTS.md](../../../AGENTS.md). Three shape every body, and lint checks the last two:

- **No hard wrapping.** One continuous line per paragraph and per list item. Code fences, tables, and YAML frontmatter keep their line structure.
- **Never cross-reference a step by number.** `see step 4` binds to a step's *position*, so inserting a step silently makes it point at the wrong one — and nothing can detect a stale-but-valid number. Link to the heading instead: `see [Group the work](#4-group-the-work)`. For a step with no heading, name the action in prose.
- **Close with `## Hand off`** — what changed, where it landed, and the single best next move. Crown one next move rather than listing five; route to the next kit by name without invoking it, and always give the plain fallback ("open a PR with **prkit**, otherwise `gh pr create`") since a public skill often lands in a repo that has none of the others.

Lint warns on a step-number reference and on a missing or routeless hand-off; it does not check wrapping. Two more decide whether the skill runs the same way twice, and nothing but review will catch them.

**Every step ends on a completion criterion** — the condition that says the work is done. A step without one ends when the agent feels finished, which is where run-to-run variance actually comes from. Write a bound the agent can check, and prefer the exhaustive form ("every modified model accounted for") to the productive one ("produce a change list").

**Decide what each piece needs to be, by branch.** Inline what every run reads; push into a satellite file inside the skill's own directory what only some runs reach. Keep a concept's definition, rules, and caveats under one heading rather than scattered, since the agent that reads one part may never meet the rest. A skill can be too long even when every line is live and unique, and no trim pass fixes that — only moving material down a rung does.

**A skill whose modes are skipped branches has a fixed shape.** Keep mode selection, the guards, and the shared vocabulary in `SKILL.md`, then give each mode its own file at `modes/<mode>.md` with one pointer per mode in the trigger-carrying form:

```markdown
- Mode `close` → read [modes/close.md](modes/close.md), then follow it.
```

A satellite assumes the root is already loaded, so it never repeats the root's material, and its hand-off section moves with its mode body. The gate is the branch and never raw size: a straight-through skill walks its whole body on every run, so splitting it only adds reads. Lint holds satellites to the root's anchor and step-reference checks, and resolves every relative pointer from the file that wrote it, so a pointer at a mode file you never created fails the run.

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

## 7. Regenerate the cheatsheet

```sh
make cheatsheet
```

[`docs/wiki/cheatsheet.md`](../cheatsheet.md) holds one row per skill, built from the what-clause of each `description`. Run it again after any later description change. A full `make lint` rebuilds it in a temp file and errors when the committed copy differs.

There is no per-skill reader page to write. `SKILL.md` is the one source, and an agent answers questions about a skill by reading it.

## 8. Update the five collection files

This is the step that gets missed. A full `make lint` now catches four of the five, so the gate tells you what you forgot. The workflow map is the one it can't.

| File | Change |
|------|--------|
| `README.md` | Add a row to the skills table with a one-line description and its visibility. Lint errors when the table and `skills/` disagree. |
| `skills.sh.json` | Add the skill to the best-fitting group's `skills` array. Never list `internal: true` skills. Create a new group only if none fits — a skill left out of every group falls into "Other skills". Lint errors when a group here and the `index.md` group of the same title disagree. |
| [`docs/wiki/workflow.md`](../workflow.md) | Add it to the loop phase it belongs to, or to the side kits if it isn't part of the loop. |
| [`docs/wiki/index.md`](../index.md) | Add it to the group under *The skills* that matches its `skills.sh.json` group. Lint errors if the link is missing or the group members differ. |
| [`IDEAS.md`](../../../IDEAS.md) | If the skill was on the backlog, **delete its row.** Nothing lives in both `IDEAS.md` and the README table. Lint warns on a row for a shipped skill. |

Lint catches the workflow map only partially — it verifies that skills and modes the map *names* still exist, not that a new skill was added to it. That row is yours to remember.

**The `index.md` row used to be the dangerous one.** `refactorkit` shipped missing from `index.md` for eight days, and `debugkit` and `tutorkit` each repeated it. Every one of those runs passed a clean gate, because nothing checked the link. Lint now errors on a missing link, and it checks placement too: each index group must hold the same skills as the `skills.sh.json` group of the same title. Filing the skill in the JSON first and copying that group to the index is the shortest path to a green run.

`skills.sh.json` affects only how the directory page groups things. It changes nothing about how the CLI installs skills.

## 9. Run the full gate and push

```sh
make lint
make security
git push origin main
```

The full run adds the cross-file checks a scoped run skips. There's no publish step beyond the push — skills.sh re-reads the repo on the next install.

## Next

If you changed how skills are structured rather than just adding one, [Architecture](../architecture.md) is the page that will go stale.

_Verified against `main`@`e7a6a61` on 2026-10-20._
