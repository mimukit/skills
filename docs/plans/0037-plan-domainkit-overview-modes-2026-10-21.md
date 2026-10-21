# Plan: domainkit overview, init, and audit modes
Grilled: 2026-10-21

## Context

A project has no place that states what the product is, who it is for, and what problem it solves, in a form an agent reads before work starts. domainkit keeps the glossary in `CONTEXT.md`, but it only adds terms one at a time as design work settles them. Nothing seeds the glossary for an existing project in one pass, and nothing checks later whether `CONTEXT.md` still matches the code.

The owner first asked for a separate `OVERVIEW.md` and `GLOSSARY.md`. Both would collide with domainkit, which owns `CONTEXT.md`, and with wikikit, which already routes every term to domainkit. The decision is to extend domainkit instead of adding a skill.

Success: on a new or existing repo, `domainkit init` produces a `CONTEXT.md` with a five-part overview and the first glossary entries, from the code plus an owner interview. Later, statuskit flags drift, and `domainkit audit` lists every place where `CONTEXT.md` disagrees with the code or the ADRs and applies the accepted fixes.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| New skill or extend domainkit | Extend domainkit. One owner for overview, glossary, and ADRs; no new entry in the human's index. |
| One file or two | One. `CONTEXT.md` gets an `## Overview` section above the glossary. The overview gives the terms their frame and fits on one screen. |
| Glossary file name | Keep `CONTEXT.md`. wikikit and refactorkit already read it, and existing projects need no rename. |
| Overview sections | What it is, Who it is for, The problem it solves, Core capabilities, Non-goals. No "current stage": it is status, and domainkit refuses status on purpose. |
| Overview length | Each subsection 3 lines or fewer; Core capabilities 7 bullets or fewer. |
| Multi-context projects | The overview goes in `CONTEXT-MAP.md`. Each per-context `CONTEXT.md` keeps its 1–2 sentence description and its glossary. |
| The "pure glossary" rule | Becomes "overview and glossary only: no status, no decisions, no install or usage steps". Decisions stay in ADRs; usage stays in the README. |
| Skill structure | Routing root plus `modes/record.md`, `modes/init.md`, `modes/audit.md`, per the AGENTS.md mode-satellite shape. The root keeps the routing, the `CONTEXT.md` format, the ADR format, and the consent rule. |
| Default mode and invocation | `record`, the current scribe loop, unchanged in behavior. A model-fired run always routes to `record`; `init` and `audit` run only when the user names them. |
| Consent | Every mode writes only after an explicit yes. `init` and `audit` show the whole proposed diff before one write. |
| `init` on an existing `CONTEXT.md` | Additive merge: add a missing overview and propose new terms; never rewrite an existing entry; send each conflict to `audit`. |
| `init` interview | One batch, at most 6 questions (5 overview parts + 1 for terms), each with a recommended answer. "Does not matter" drops that subsection, except What it is, which is required. |
| Tool surface | `allowed-tools` adds `AskUserQuestion` (the interview) and `Bash(git log:*)` (audit only). No other shell command. |
| `audit` history read | Find the last commit that touched `CONTEXT.md`, list the files changed since, read those first. With no git or a refused command, compare against the current tree and the ADR `Status` lines. |
| `audit` trigger | statuskit adds one cheap signal at its lowest rung. `CONTEXT.md` missing while `docs/adr/` or `docs/plans/` exists routes to `domainkit init`. The newest ADR, or 50+ commits, newer than the last `CONTEXT.md` commit routes to `domainkit audit`. Plain fallback: "update `CONTEXT.md` by hand". |
| README boundary | The overview states purpose and audience. It never repeats install or usage text from the README. |
| wikikit link | A wikikit page that states the product's purpose links the `CONTEXT.md` overview; `architecture.md` opens with that link. |
| Description triggers | record: "update the glossary", "write an ADR". init: "set up CONTEXT.md", "write the project overview". audit: "is CONTEXT.md still accurate", "audit the glossary". |
| Outward actions | None. The build leaves every change uncommitted for the owner. |
| Tests | No test runner. Each phase checks with `make lint` plus a structure check; the live interview check is the attended final phase. |

## Approach

Reuse the existing domainkit body as `record` mode, and the issuekit root as the template for the routing section (``Mode `x` → read [modes/x.md](modes/x.md), then follow it.``). Reuse the worktree-scan text already in domainkit for the ADR serial. `init` reuses the wikikit `init` research pass as a model for reading a repo (manifests, entry points, README, existing `CONTEXT.md` and `docs/adr/`), and the grillkit batching rule for the interview. The statuskit signal follows the pattern of its existing stale-tracker signal: one cheap count, never itemized.

Rejected alternatives:
- A separate `OVERVIEW.md` owned by domainkit: a second root file with a blurred border against `CONTEXT.md`, and a second read for every agent.
- A new skill (`briefkit` or similar): two glossary owners, and wikikit's routing would point at the wrong file.
- Overview as a wikikit page: wikikit writes for readers outside the repo, and the overview is agent context first.

### Phase 1: split domainkit into a routing root and `record` mode

- Move the Procedure section of `skills/domainkit/SKILL.md` (Detect, Locate, Offer, Write, Defer, Hand off) into `skills/domainkit/modes/record.md` with no behavior change.
- Keep in the root: the intro, When this fires (now per mode, with the rule that a model-fired run routes to `record`), the `CONTEXT.md` format, the ADR format, the consent rule, and Notes.
- Add the mode list and one pointer per mode in the trigger-carrying form.
- Fix every intra-doc anchor that moved.

Done when: `make lint` passes, `skills/domainkit/modes/record.md` holds the six procedure steps, and a diff of the old Procedure against `record.md` shows only heading and anchor changes.

### Phase 2: add the overview to the shared `CONTEXT.md` format

- Add an `## Overview` block to the format template in the root, with the five subsections and the length caps.
- Rewrite the content rules: overview and glossary only, no status, no decisions, no usage steps; the README boundary; the overview's home in `CONTEXT-MAP.md` for a multi-context project.
- Keep every existing glossary rule (domain terms only, opinionated `_Avoid_` lines, no size cap).

Done when: the root's format section shows the overview above the first glossary term with its length caps, and the multi-context bullet names `CONTEXT-MAP.md` as the overview's home.

### Phase 3: write `init` mode

- Read the repo first: manifests, entry points, README, routes or CLI surface, existing `CONTEXT.md`, `CONTEXT-MAP.md`, and `docs/adr/`. Look up every fact the code answers before asking anything.
- Draft the overview and a candidate term list from what the code shows; mark each part as read from code or as an assumption.
- Interview the owner in one batch of at most 6 questions, only on the parts the code leaves open, each with a recommended answer, through `AskUserQuestion` when available.
- On an existing `CONTEXT.md`, merge additively and list each conflict as a route to `audit`.
- Show the full proposed `CONTEXT.md` or the diff, and write on a yes.
- Greenfield path: with no code, the interview carries every overview part.
- Hand off in the procedural register.
- Add `AskUserQuestion` to `allowed-tools`.

Done when: `make lint` passes, `modes/init.md` exists, and every step in it ends on a `Done when` criterion.

### Phase 4: write `audit` mode

- Read the history with `git log` only: the last commit that touched `CONTEXT.md`, then the files changed since. Fall back to the current tree when git is missing or the command is refused.
- Read `CONTEXT.md` (or the map and its context files), the changed code first, the README, and every ADR with its `Status`.
- List each finding as one of: an overview capability the code no longer has, a capability the code has that the overview omits, a term the code uses that the glossary lacks, a glossary term the code no longer uses, a term defined against a superseded ADR, a status or usage line that breaks the content rule.
- Show the findings with a proposed edit for each, and apply the accepted ones.
- Report "no drift" plainly when there is none.
- Add `Bash(git log:*)` to `allowed-tools`.

Done when: `make lint` passes, `modes/audit.md` exists, every step in it ends on a `Done when` criterion, and it names all six finding types.

### Phase 5: update the description and the collection files

- Rewrite the `description`: one what-clause naming the overview, glossary, and ADRs, then the settled triggers per mode. Drop "it doesn't interrogate it" and keep the line that it records settled understanding. Stay under 1,024 characters.
- Update `skills/wikikit/SKILL.md` and `skills/wikikit/modes/init.md` per the wikikit-link decision.
- Update the domainkit entries in `docs/wiki/workflow.md` (the diagram labels and the "scribe the model" section) to name the three modes.
- Run `make cheatsheet`.

Done when: `make lint` passes with no new warnings, `git diff docs/wiki/cheatsheet.md` shows the new what-clause, and the description is under 1,024 characters.

### Phase 6: add the `CONTEXT.md` signal to statuskit

- Add the signal to statuskit's survey beside the stale-tracker signal, with the two conditions and the 50-commit threshold.
- Add a rung below every other rung: route to `domainkit init` or `domainkit audit`, with the plain fallback.
- Add the route to `docs/wiki/workflow.md` if the statuskit section lists its routes.

Done when: `make lint` passes, the statuskit ladder table shows the new rung last, and the survey section names both conditions.

### Phase 7: run `init` and `audit` live on this repo
Attended: the owner answers the `init` interview and reviews the `audit` findings.

- Run `domainkit init` on this repo and answer the interview; do not accept the write unless the owner wants the file.
- Remove one capability from a scratch copy of the overview, run `domainkit audit`, and check that it reports the gap.
- Fix any defect the run shows in `modes/init.md` or `modes/audit.md`.

Done when: `init` proposed a `CONTEXT.md` with all five overview parts and at least one glossary term, and `audit` reported the removed capability as a finding.

## Migration and rollback

The `CONTEXT.md` format change is additive. An existing `CONTEXT.md` without an overview stays valid; `init` offers to add one, and statuskit does not flag a file only because it lacks an overview. Rollback is a revert of the skill files; no project file depends on the new section.

## Non-goals

- No `OVERVIEW.md` or `GLOSSARY.md` file, and no rename of `CONTEXT.md`.
- No project status, stage, roadmap, or metrics in `CONTEXT.md`.
- No reader-facing product documentation. That stays with wikikit.
- No change to the ADR format, the ADR bar, or the ADR numbering.
- No new skill and no change to `skills.sh.json` grouping.
- No scheduled or automatic `audit` run. statuskit recommends it; a person starts it.
