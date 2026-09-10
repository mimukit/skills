# Plan — refactorkit

_Created 2026-08-08._
_Grilled: 2026-08-08._

## Context

Nothing in this collection looks at *existing code and proposes structural change*. `reviewkit` reads a diff for defects, `wikikit` describes architecture as it is, `domainkit` records decisions after they are made, `plankit` starts from a rough idea rather than from the codebase. The gap is the survey step: sit down at a brownfield repo, find where its structure is actually costing you, and come out with one defensible refactor worth interrogating.

The seed is Matt Pocock's [`improve-codebase-architecture`](https://github.com/mattpocock/skills/blob/main/skills/engineering/improve-codebase-architecture/SKILL.md) — scan for "deepening opportunities", present them visually, grill the one you pick. Per this repo's rules the skill is **authored from scratch, never forked**; the upstream informs structure only. Two of its three dependencies already exist here as `grillkit` and `domainkit`; its third (`/codebase-design`, which carries the shared design vocabulary) does not, so **that vocabulary gets inlined** — which a public skill needs anyway.

## Settled decisions

| # | Decision | Answer | Why |
|---|---|---|---|
| — | Name | `refactorkit` | The functional word leads and is what anyone searches for. It overpromises the doing, which the skill answers with an explicit propose-never-edit boundary. |
| — | Report medium | Markdown under `docs/` + a terminal table | Matches the collection's artifact convention; Mermaid renders natively on GitHub and in editors, so the upstream's temp-file HTML report buys nothing and can't be reviewed in a PR. |
| — | Lens breadth | Depth spine, expressed through a closed pattern set | A closed set is what stops the output degrading into the generic smell-listing the base model already does without a skill. |
| — | Hand-off | `grillkit` on the crowned candidate | The write-up is already plan-shaped; what it lacks is interrogation, not drafting. `grillkit` names "an architecture" as a valid subject already. |
| Q1 | Zero candidates | A first-class outcome — say so, name the coverage, write no file | The deletion test is only a real gate if "nothing here" is legal. A survey obliged to produce findings will manufacture them, and manufactured architecture advice reads exactly like the real thing. |
| Q2 | Scan strategy | Fan out to subagents by area | The read-the-code work is the expensive half and it parallelises cleanly; keeping it out of the main session is what makes a whole-repo survey affordable at all. |
| Q3 | Evidence sources | Read-only shell only | `madge`/`knip`/coverage would mean probing per tool and parsing output shapes that change on a minor release — the brittle coupling this collection's quality bar warns against. Consume such an artifact if it's already on disk; never generate one. |
| Q4 | Strength rating | Three levels, each defined by evidence | An undefined badge is a vibe wearing a label, and it's the one column a reader trusts without checking. |
| Q5 | Fan-out partition | Churn clusters, fleet of 3–5; inline top-churn scan when no subagent tool exists | A public skill installs into environments with no subagent tool, so the fallback is a large share of runs, not an edge case. |
| Q6 | Subagent return shape | A fixed candidate record, empty return allowed | The main session ranks and crowns findings it never gathered. Freeform prose can't be ranked without re-reading what the agent read, which throws away the reason to fan out. |
| Q7 | Pattern signals | Language-agnostic shapes, not names | A public skill lands in Go, Python, Rust, and PHP repos where `*Mapper` and `*DTO` mean nothing. |
| Q8 | skills.sh group | Planning & Design | The output is a plan input, so the group's "before you write any code" framing holds. A new group would be a group of one. |

## The skill

**`skills/refactorkit/SKILL.md`**, single file, public.

```yaml
---
name: refactorkit
description: >-
  Survey an existing codebase for the structural change worth making — shallow interfaces, adapter sprawl, poor locality, untested coupling — rank the candidates, crown one, and write it up as a reviewable proposal. Use when the user says "where should I refactor", "what's wrong with this codebase's structure", "find refactoring opportunities", "this code is hard to change", "improve our architecture", "audit the module boundaries", or "/refactorkit". It proposes and never edits code.
license: MIT
allowed-tools: Bash, Read, Grep, Glob, Write, Task, Agent, Skill
metadata:
  internal: false
---
```

Single procedure with an optional scope argument (`/refactorkit src/payments`) — no modes. Modes here would be a presentation split rather than a behavioural one, and the wiki page's mode row stays honest at "single procedure, optionally scoped".

**`Edit` is absent from `allowed-tools` on purpose.** It's the cheapest possible enforcement of the propose-never-edit boundary, and it costs nothing: the skill's only write is one new Markdown file, which `Write` covers.

### The load-bearing boundary: it proposes, it never edits

The name says *refactor*, so the skill has to say early and plainly that it **writes exactly one Markdown file and touches no source**. `implementkit` does the doing. This mirrors `statuskit`'s zero-mutation stance and is the single most important guard in the draft — a skill called `refactorkit` that starts moving code is the failure mode.

Other boundaries, one line each: not `reviewkit` (diff, defects), not `wikikit` (describes structure, doesn't propose change), not `designkit` (visual design system — name adjacency only), not `domainkit` (records decisions; refactorkit routes to it).

### The lens — inlined vocabulary, a closed pattern set, two gates

**Vocabulary**, defined inline, about seven terms: *module* (anything with an inside and an outside), *interface* (everything a caller must know — signature plus ordering, config, side effects, error contract), *depth* (behaviour hidden, relative to interface size), *seam*, *adapter*, *locality*, *leverage*.

**The four friction patterns** — a closed set, all reducing to depth. **Signals are written as shapes, never as names** (Q7): a public skill lands in repos where `*Mapper` and `*DTO` are meaningless, and an example is what a model pattern-matches on. The skill instructs the agent to derive the repo's own naming conventions first — `CONTEXT.md` is already being read for vocabulary, so they're in hand before the hunt starts.

| Pattern | What it is | The shape to look for | Who finds it |
|---|---|---|---|
| Shallow interface | the interface costs about as much to learn as the implementation costs to read | a unit whose members each forward to exactly one member of one other unit | subagent |
| Adapter prevalence | modules existing only to reshape data between two others — the finding is that two sides disagree on a shape, not "delete adapters" | a cluster of translation-only units sitting on one boundary, in both directions | subagent |
| Untested coupling | behaviour testable only by standing up its collaborators | tests that construct more collaborators than assertions, or an untested unit whose neighbours are tested | subagent |
| Poor locality | one conceptual change fans out across many files | files that repeatedly change in the same commits while living apart | **main session** |

**Poor locality stays out of the fan-out** (Q5). It's derived from git co-change, costs no file reads, and a per-area subagent structurally *cannot* see files that change together while living in different areas. Handing it to an area agent guarantees it's never found.

**Two gates every candidate clears before it is listed at all:**

- **Deletion test** — if this module vanished and its callers absorbed it, does complexity *concentrate* where it belongs, or merely *relocate*? Relocation is churn and never gets printed. This is what keeps the report short and defensible.
- **Interface as test surface** — after the change, can the behaviour be tested through the new interface alone, without reaching inside? If not, the seam is in the wrong place and the candidate is unfinished, not ready.

**Strength scale** (Q4) — written out as a table, the way `statuskit` writes its priority scale, so the rating is checkable against the row rather than asserted:

| Strength | What it takes | How it ranks |
|---|---|---|
| `strong` | both gates pass, the files sit in the churn top slice, and the blast radius is named in files | crownable |
| `moderate` | both gates pass, but the code is cold or the blast radius is wide | crownable when nothing is `strong` |
| `weak` | gates pass, but the win is stylistic — no change in what a caller must know | listed, **never crowned** |

**Vocabulary constraint**, the sharpest instruction in the upstream and worth keeping: use the project's own domain terms; never fall back on generic "component", "service", "API".

### Procedure

1. **Read the guardrails first** — repo-root `CONTEXT.md` for the ubiquitous language, `docs/adr/` for decisions already made. A proposal that reverses an accepted ADR must *say so by number* and route to `domainkit` for a superseding record, rather than quietly re-suggesting a rejected design. Degrade silently when neither exists.
2. **Rank by churn and cluster** — `git log --format= --name-only --since=…` gives both the churn ranking and the co-change pairs, in one read, shell-only. Cluster the hot files into 3–5 coherent areas. Honour the scope argument when given; no git history (shallow clone, not a repo) means no ranking, so scan by structure and say the prioritisation was skipped.
3. **Fan out** — one subagent per cluster, each applying the three read-the-code patterns to its own slice and returning the fixed record below. The main session derives poor locality from the co-change pairs it already has. **No subagent tool available → scan the top churn slice inline instead**, and say which path ran; that fallback is a large share of runs for a public skill, not an edge case.
4. **Synthesize, gate, rank** — drop any record missing a gate verdict (unevidenced gates are exactly what the deletion test exists to catch), dedupe across areas, rank on strength then leverage then lowest blast radius, and crown one. `weak` is never crowned.
5. **Report** — terminal table first, then the artifact. Both carry a mandatory **coverage line**: *"ranked 1,240 files by churn, read the top 40 across 4 areas."* A cap nobody can see is a lie about completeness.
6. **Hand off** — below.

### The subagent contract

Each agent returns a list of candidate records, or an explicit empty result. Fixed fields, because the main session ranks findings it never gathered:

| Field | Content |
|---|---|
| `pattern` | one of the three read-the-code patterns |
| `files` | the paths involved |
| `shape` | the proposed structure, one line |
| `deletion_test` | verdict + one sentence of evidence |
| `test_surface` | verdict + one sentence of evidence |
| `blast_radius` | files touched, callers changed |
| `strength` | per the scale table |

A record missing a gate verdict is **dropped, not repaired**.

### The empty result is a real outcome

When nothing clears the gates, refactorkit says so, names the coverage, and **writes no file** (Q1). The terminal line has to carry the coverage — *"scanned 38 files across `src/`; nothing cleared the deletion test"* — or an empty result is indistinguishable from a scan that never ran.

### The artifact

`docs/refactor/refactor-<slug>-YYYY-MM-DD.md`, following the `<type>-<slug>-YYYY-MM-DD.md` convention — the rule gets **inlined** in the skill, since a public skill cannot cite this repo's conventions doc. Same-subject re-runs update in place, keeping the original creation date. An existing project convention for proposal docs wins when the target repo has one.

Contents: the coverage line, the ranked table, then one section per candidate — problem, proposed shape, why it is deeper, both gate verdicts, blast radius — with a **Mermaid before/after** diagram for the crowned candidate at minimum.

Unlike `statuskit`'s snapshot this file is **durable and committable**, not gitignored scratch: it is a proposal meant to be reviewed. refactorkit still never commits it.

**No filesystem** (a browser-based agent) → print the artifact as a codeblock under its canonical path and skip the write.

### Hand off

*What changed* — the report written, and explicitly: no source file touched. *Where it landed* — the path. *Next* — **`grillkit`** on the crowned candidate, with the plain fallback for a repo without the ecosystem ("interrogate it yourself before you build it"). Runners-up: `domainkit` when the proposal reverses or supersedes an ADR, `implementkit` once the shape is settled. On an empty result the hand-off says there is no next move, rather than inventing one.

## Repo bookkeeping — same change, all of it

- **`README.md`** — a row in the skills table near `reviewkit`/`implementkit`: survey an existing codebase for the structural change worth making, rank the candidates, crown one; proposes, never edits. Visibility `public`.
- **`skills.sh.json`** — append `refactorkit` to the **Planning & Design** group (`validatekit`, `researchkit`, `prototypekit`, `plankit`, `grillkit`) and extend that group's description to cover surveying code you already have.
- **`docs/wiki/skills/refactorkit.md`** — the reader-facing page: one-line description, bold *Reach for it when*, the summary table (modes · tools · writes · visibility), then the *why* — why the pattern set is closed, why the deletion test gates the list, why poor locality is the one pattern the fan-out can't own, why the name promises more than the skill does and where the doing lives. Link siblings as `` [`grillkit`](./grillkit.md) ``, close with the install command and `_Verified against `main`@`<sha>` on 2026-08-08._`
- **`docs/wiki/workflow.md`** — one bullet in **The side kits**. Do not write `refactorkit <word>` anywhere in it: lint parses that shape as a mode invocation and errors when the skill defines no such mode.
- **`IDEAS.md`** — no edit; `refactorkit` was never on the backlog, so there is no row to graduate.

Mirror while drafting: `skills/statuskit/SKILL.md` (crowned-move ranking, zero-mutation stance, scale tables, artifact-write rules), `skills/grillkit/SKILL.md` (the hand-off target's contract, and its non-blocking subagent pattern), `skills/domainkit/SKILL.md` (the `CONTEXT.md` and ADR formats to read, not rewrite), `skills/skillkit/SKILL.md` (quality bar and portability checklist).

## Verification

1. `make lint name=refactorkit` — clean: frontmatter marker, `Use when` trigger, resolving intra-doc anchors, no `step N` references, a `## Hand off` section, no portability warnings (no `../` links, no mention of `make` / the conventions doc / `scripts/`).
2. `make lint` full run — proves the wiki page exists, its mode headings match the skill, and `docs/wiki/workflow.md` still cross-checks.
3. `make link name=refactorkit`, then **a fresh session** (the skill list loads at startup) to live-test against a real brownfield repo:
   - phrasings that *should* fire it ("where should I refactor this", "the module boundaries here are a mess") plus a near-miss that should *not* (a diff review, which is `reviewkit`);
   - confirm it reads `CONTEXT.md` and `docs/adr/` when present, that the fan-out actually spawns and every listed candidate states both gate verdicts, that exactly one is crowned and no `weak` candidate ever is, and that the coverage line appears in both the terminal and the artifact;
   - **exercise the empty path** — point it at a small, well-factored repo and confirm it reports nothing found and writes no file, rather than crowning something weak;
   - **exercise the no-subagent fallback** — run it where the subagent tool is unavailable and confirm it scans inline and says which path it took;
   - confirm **`git status` shows no source file modified** — the artifact and nothing else.
4. `make unlink name=refactorkit` to remove the dev link.
5. Leave everything uncommitted; hand over `feat(refactorkit): add refactorkit skill` for the owner to run.

## Open question

One remains, and it is deliberately left for the live test rather than settled on paper: **whether four patterns are enough on a repo whose real problem is layering rather than depth.** If the report comes back empty on a codebase that visibly needs work, the answer is a fifth named pattern — not a wider lens, which is what the closed set exists to prevent.
