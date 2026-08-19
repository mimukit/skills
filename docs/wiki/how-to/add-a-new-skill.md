# Add a new skill

Adding a skill means creating one directory — but shipping one means writing a reader-facing page for it and updating five other files, most of which lint can't check for you.

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

Public skills live in `skills/`. A repo-only meta skill that only makes sense inside this collection goes in `.agents/skills/<name>/` instead, where it's auto-discovered without a dev link and stays out of the `skills/`-based tooling. That directory is still empty — every skill here is public.

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

Spend it on **one trigger per branch, not per synonym**. Every description in the collection loads on every turn, and what that budget buys is coverage of the distinct cases the skill handles, usually one per mode. Rephrasing the same case three ways buys nothing. Dropping a case buys silence, and lint can't see a skill that never fires — so cut synonyms, never coverage.

**`metadata.internal` is a lint error if absent**, because an undeclared skill has undefined publication behavior. `false` publishes it; `true` hides it from skills.sh discovery entirely.

## 4. Write the body

Full conventions are in [AGENTS.md](../../../AGENTS.md). The three that lint enforces:

- **No hard wrapping.** One continuous line per paragraph and per list item. Code fences, tables, and YAML frontmatter keep their line structure.
- **Never cross-reference a step by number.** `see step 4` binds to a step's *position*, so inserting a step silently makes it point at the wrong one — and nothing can detect a stale-but-valid number. Link to the heading instead: `see [Group the work](#4-group-the-work)`. For a step with no heading, name the action in prose.
- **Close with `## Hand off`** — what changed, where it landed, and the single best next move. Crown one next move rather than listing five; route to the next kit by name without invoking it, and always give the plain fallback ("open a PR with **prkit**, otherwise `gh pr create`") since a public skill often lands in a repo that has none of the others.

The three above are the ones a grep can check. Two more decide whether the skill runs the same way twice, and nothing but review will catch them.

**Every step ends on a completion criterion** — the condition that says the work is done. A step without one ends when the agent feels finished, which is where run-to-run variance actually comes from. Write a bound the agent can check, and prefer the exhaustive form ("every modified model accounted for") to the productive one ("produce a change list").

**Decide what each piece needs to be, by branch.** Inline what every run reads; push into a satellite file inside the skill's own directory what only some runs reach. Keep a concept's definition, rules, and caveats under one heading rather than scattered, since the agent that reads one part may never meet the rest. A skill can be too long even when every line is live and unique, and no trim pass fixes that — only moving material down a rung does.

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

## 7. Write its reader-facing page

```
docs/wiki/skills/<name>.md
```

This one is a lint **error** if you skip it, so the gate will stop you — but it's worth understanding why it exists rather than treating it as a box to tick. `SKILL.md` is written for the agent that runs the skill. The page is written for the person deciding whether to reach for it. Different audience, different document: the page is not a summary of `SKILL.md` and shouldn't read like one.

Copy the shape from any existing page — [`commitkit`](../skills/commitkit.md) is a short one:

- Open with the one-line description, then a bold **"Reach for it when"** trigger, then a summary table of modes, tools, what it writes, and visibility.
- Write each mode as `` ### `mode` `` — a backticked `h3` under `## Modes`. Lint diffs those headings against the modes `SKILL.md` actually defines, so a renamed mode breaks here instead of leaving a page that lies. A skill whose modes genuinely aren't backticked opts out by using a plain heading.
- Name the next kit under **Hands off to**, linking siblings in the form `` [`prkit`](./prkit.md) `` — page-relative, since every skill page sits in the same directory.
- **Explain the why, not the what.** The page earns its place on the reasoning behind a load-bearing rule. Restating the procedure step by step is what `SKILL.md` already does better.
- End with the install command, a link to the skill's own `skills/<name>/SKILL.md`, and the provenance stamp: `` _Verified against `main`@`<sha>` on YYYY-MM-DD._ `` Only stamp what you actually read — moving a stamp forward asserts somebody verified the page, and a stamp bumped as a formality is worse than a stale one.

Every later change to the skill obliges a page edit in the same commit. Lint warns when a commit touching exactly one skill lands without its page.

Then register the page in the doc map, [`docs/wiki/.wikimap.yaml`](../.wikimap.yaml), beside the other skill entries:

```yaml
  - path: skills/<name>.md
    mode: reference
    documents: [skills/<name>/SKILL.md]
```

The map is what tells a later docs audit the page exists and which source it tracks. An unregistered page is the quietest failure in this repo — it renders, it's linked, the gate is green, and the only symptom is that no audit ever sweeps it. It was missed on three skills in a row before lint started checking it, which it now does as an **error** in both directions.

## 8. Update the five files lint won't fully catch

This is the step that gets missed.

| File | Change |
|------|--------|
| `README.md` | Add a row to the skills table with a one-line description and its visibility. |
| `skills.sh.json` | Add the skill to the best-fitting group's `skills` array. Never list `internal: true` skills. Create a new group only if none fits — a skill left out of every group falls into "Other skills". |
| [`docs/wiki/workflow.md`](../workflow.md) | Add it to the loop phase it belongs to, or to the side kits if it isn't part of the loop. |
| [`docs/wiki/index.md`](../index.md) | Add it to the right group under *The skills*. Lint errors if the link is missing entirely, but **cannot check the group** — see below. |
| [`IDEAS.md`](../../../IDEAS.md) | If the skill was on the backlog, **delete its row.** Nothing lives in both `IDEAS.md` and the README table. |

Lint catches the workflow map only partially — it verifies that skills and modes the map *names* still exist, not that a new skill was added to it. `README.md`, `skills.sh.json`, and `IDEAS.md` are on the [pre-push checklist](../../../PUBLISHING.md#pre-push-checklist) instead.

**The `index.md` row used to be the dangerous one, and half of it still is.** Lint now errors when a skill has no link on the index at all, which closes the failure that bit three times running: `refactorkit` shipped with a correct page that was missing from `index.md` for eight days, and `debugkit` and `tutorkit` each repeated it. Every one of those runs passed a clean gate, because a page that exists but that nothing links to looks identical to a finished one.

What lint still cannot judge is **placement**. The index groups skills by theme, and a skill dropped under the wrong heading links exactly as correctly as one filed right. So a green run means the page is reachable, never that it's filed sensibly — that half remains yours.

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

_Verified against `main`@`e14d201` on 2026-08-19._
