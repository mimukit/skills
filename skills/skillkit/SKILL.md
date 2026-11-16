---
name: skillkit
description: >-
  Create a new AI agent skill from scratch (kit-convention naming, drafting, trigger cases, live testing, publishing), or re-check an existing one after a change. Use when the user says "help me make a skill for X", runs "/skillkit", or says "I changed this skill, check it".
license: MIT
disable-model-invocation: true
allowed-tools: Read, Edit, Write, Bash, AskUserQuestion, WebSearch, WebFetch
metadata:
  internal: false
---

# skillkit

Authoring skill for a personal skill collection.

## Invocation

Drive the procedure below one step at a time, and settle intent, visibility, provenance, and name before drafting.

A request to check or update a skill that already exists skips the creation steps: go to [Maintain an existing skill](#maintain-an-existing-skill).

## Procedure

### 1. Gather intent
Ask what the skill should do and *when it should trigger* (the real user phrasings). If the user offers example skill links, skim them for structure ideas when fetching is available; no step waits on them. Capture the job, the trigger conditions, and any hard constraints (tools it needs, things it must not do).

Then check that a **new skill** is the right shape. A skill earns its own directory when a person wants to choose it deliberately, at a distinct moment. When the agent should make the choice from context instead, it belongs as a **mode inside an existing skill**, which costs one branch in that skill's description instead of a new entry the user has to remember. Name the existing skill and let the user decide; don't refuse the request. Done when you can state the job, every branch it handles with at least one real phrasing each, and the user's choice between a new skill and a mode.

### 2. Visibility (internal or public?)
Ask whether this is an **internal** repo-only skill or a **public** publishable one.
- **internal**: a maintenance/meta skill for the host repo. It may reference the repo's conventions doc and build tooling, and use repo-relative links. Stamp `metadata.internal: true`. skills.sh hides it from discovery.
- **public**: a shareable skill. It **must** follow [Portability](#portability-public-skills-only) below and stamp `metadata.internal: false`. skills.sh discovers and lists it automatically once it is pushed to a public collection repo.

Done when the user has picked one.

### 3. Provenance (original vs. "my version of")
Ask: is this **original**, or **your version of an upstream skill**? Either way, author it from scratch here, and use the upstream only for structure ideas. Done when the user has answered, with the upstream link when there is one.

### 4. Propose names
Follow the host collection's naming convention when it has one. Otherwise suggest **3–5 `kit` names** and recommend one: one lowercase word, the **functional term leads** so it stays searchable (people search `commit`, not `kit`), `kit` appended, and shorten an awkward root rather than force a clumsy join (`humanize` → `humankit`, not `humanizekit`). Avoid collisions with well-known tools (`speckit`, `shipkit`, anything already popular): when network access exists, search the candidate on the web and in the skills.sh directory; when offline, state that the popularity check was skipped. Let the user pick. The chosen name **must** equal the directory name. Done when the user has picked a name and its collision check is run or reported as skipped.

### 5. Draft
Create the skill in the host collection's documented layout from the [Frontmatter template](#frontmatter-template) below, applying the [Quality bar](#quality-bar), and stamp `metadata.internal` from [Visibility](#2-visibility-internal-or-public). In a collection repo this is commonly `skills/<name>/SKILL.md`; standalone, use the agent's discovered skills directory such as `.claude/skills/<name>/SKILL.md`. Use one file for a straight-through skill, and the mode-satellite shape from [Information hierarchy](#information-hierarchy) when modes are skipped branches.
- If **public**, apply the **Portability** checklist below as a hard gate: the skill must stand alone once installed.
- Write the **trigger cases** beside the draft: for each branch, two or three realistic prompts that *should* fire the skill, plus two or three near-misses that should *not* (a prompt that belongs to a neighboring skill, or a request the model handles alone). Save them where the collection keeps such cases; without one, use `evals/triggers.md` in the skill's own directory, as two lists headed `Should fire` and `Should not fire`.

Done when every frontmatter field is filled, every step carries a completion criterion, the skill ends on a hand-off, and every branch has trigger cases.

### 6. Review loop
Show the draft. Take edits and iterate until the user explicitly approves. Done when the user has approved the draft in words; testing starts only then.

### 7. Live test
Don't install the skill yourself. Hand the user the commands to drive the live trial. If the collection provides dev-link tooling (check its README or Makefile for a link/unlink target), tell them to inject the skill with that; otherwise have them symlink or copy `skills/<name>` into their agent's skills directory (e.g. `~/.claude/skills/<name>`). Then test in a **fresh session**, so each trigger test starts from a clean context. Test live, with no scratch test-plan file. Suggest they exercise it against reality:
- run every prompt in the trigger cases file, one fresh session each, and note which ones fired the skill (the near-misses guard against overtriggering);
- confirm the real run follows the drafted procedure end to end and produces the artifact or outcome the skill promises;
- settle each suspected **no-op** by running it: delete the suspect line, run the same phrasing again, and keep the line only when the behavior changes.

When done testing, they remove the dev link the same way it was added (the collection's unlink command, or deleting the symlink/copy). Done when every trigger case has a fired or not-fired result, and any mismatch has led to a description edit or a changed case the user agreed to.

### 8. Hand off

_Write this section in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

First update every surface the collection uses to list or document its skills, when the repo has it:

- the README skills table;
- a `skills.sh.json` directory-grouping file (public skills only);
- the skill's link in the docs index (for example `docs/wiki/index.md`);
- a generated cheatsheet: run the collection's command for it (for example `make cheatsheet`).

Then run the collection's skill lint if it has one, fix errors, and address warnings. Without one, self-check against the [Conventions](#conventions), the [Quality bar](#quality-bar), and, for public skills, **Portability**. Done when every surface the repo has is updated and lint reports no errors. Then close:

**What changed.** Report the skill created (name, visibility, file count), the listing and docs surfaces updated, the trigger-case results, and the lint or self-check result.

**Where it landed.** Give the skill's directory path, and whether a dev link from [Live test](#7-live-test) is still in place (it should be removed by now; say so if it isn't).

**Next.** The work is uncommitted, so the move is to commit it: suggest a conventional message (e.g. `feat(<name>): add <name> skill`) for the user to run. **Never commit automatically**; the user runs the commit.

## Maintain an existing skill

For a skill that already exists and has just changed. Run each check, then close with the same three-beat hand-off as creation.

1. **Re-run the trigger cases.** Run every case in the skill's trigger cases file in a fresh session; when the skill has none yet, write them first, as in [Draft](#5-draft). Done when every case has a result and every mismatch is fixed or reported.
2. **Check the description against the branches.** Every mode or branch has one trigger, and no trigger names a branch the skill no longer has. Done when each branch maps to one trigger.
3. **Update the docs surfaces** from [Hand off](#8-hand-off) that the change touched: regenerate the cheatsheet after a changed description, and update the README row and docs index after a changed visibility or rename. Done when every surface the change touched is updated.
4. **Run the collection's lint.** Done when it reports no errors.

## Conventions

### Frontmatter template

```yaml
---
name: <matches directory>
description: >-
  <what it does>. Use when <explicit English trigger>.
license: MIT
allowed-tools: <only if the skill needs a restricted set>
metadata:
  internal: true   # true = repo-only meta skill; false = public/publishable
---
```

### Information hierarchy
A skill is built from **steps** (the ordered actions the agent performs) and **reference** (definitions, rules, and facts consulted on demand). The two mix freely: all steps, all reference, or both. Place each piece on a ladder ranked by how immediately the agent needs it. An **in-file step** is the primary tier; **in-file reference** is consulted on demand, and a flat peer-set of rules on one rung is fine; **disclosed reference** is pushed into a satellite file inside the skill's own directory and loaded only when its pointer fires.

**Disclose by branch, not by size.** Inline what every branch needs, and push behind a pointer what only some branches reach. Push too much down and you hide material the agent needs; push too little and the top bloats.

**Mode satellites have a fixed shape.** A skill whose modes are skipped branches (each run takes one mode and never reads the others) splits into a routing root `SKILL.md` plus `modes/<mode>.md`, one file per mode. The root keeps mode selection, guards, and the vocabulary every mode shares, plus one pointer per mode: a list item that names the mode, links its `modes/<mode>.md` file, and says to read it, then follow it. A mode file assumes the root is loaded and never repeats it; each mode's hand-off moves with its mode body. A straight-through skill, whose every run walks the whole body, stays one file whatever it weighs.

**Add a script or satellite file only when the skill needs one**, and keep it in the skill's own directory, never in a repo-root location.

**Co-locate a concept**: keep a definition, its rules, and its caveats under one heading.

**Sprawl** is a skill too long even when every line is live and unique. The cure is the ladder, not a trim pass.

### Completion criteria
**Every step ends on a completion criterion, the condition that tells the agent the work is done.** A step without one ends when the agent feels finished, which is the largest single source of run-to-run variance. Two properties matter. **Clarity**: can the agent tell done from not-done? A vague bound ("understanding reached", "keep it lean") invites **premature completion**, where the step ends early because attention has already slipped to the steps still visible ahead of it. **Demand**: how much the wording requires. Prefer the exhaustive form ("every modified model accounted for") to the productive one ("produce a change list"). "Every rule applied" binds a body of flat reference the same way, so an all-reference skill still carries a bar.

**Sharpen a rushed step's bound first.** Split the sequence only when the bound is irreducibly fuzzy *and* you have watched the rush happen. Splitting works only across a real context boundary, meaning a hand-off document or a subagent dispatch; an inline call leaves the later steps in context and hides nothing.

### Prose formatting
**No hard wrapping.** Write each paragraph and list item as one continuous line; let the editor and renderer soft-wrap. Keep line structure only where it is meaningful: code fences, tables, and YAML frontmatter (a folded `description: >-` scalar is fine).

### Prose register
**A skill writes for two different readers, and they need opposite prose.** Text a skill writes back to *its own operator* (QA steps, handoff documents, status snapshots, `Hand off` sections, next-move lines, preview-and-confirm lines) is procedural: write it in ASD-STE100 Simplified Technical English. One instruction per sentence. Procedural sentences 20 words or fewer, descriptive sentences 25 or fewer. Active voice, present tense, name the actor. No metaphor, idiom, or second meaning. Pick one term per concept and keep it *within a single document*; the rule never reaches across documents. Text a person reads *to form an opinion* (plan context, research recommendations, ADR rationale, review verdicts) is explanatory and keeps uneven rhythm and a stated position; do not apply STE to it. Machine-read or format-bound text is exempt: commit subjects, issue titles, prompts, design tokens, code, paths, commands, and quoted source. **Content the skill produces for a third-party audience is out of scope entirely**, including project documentation, published prose, and UI copy. Precedence: an explicit user instruction, then the target repository's documented convention, then the register. Inline this rule in a public skill rather than linking it.

### Documentation artifact naming
When a skill creates a durable Markdown artifact under `docs/`, follow the host collection's convention when it has one. Otherwise use `NNNN-<type>-<slug>-YYYY-MM-DD.md`: a four-digit serial, a lowercase type prefix, a short lowercase kebab-case subject slug, and the artifact's ISO creation date at the end (for example, `docs/plans/0001-plan-sso-login-2026-07-23.md`). The serial is per directory, zero-padded, monotonic, and never reused: take the highest leading serial in the directory across this worktree, every other worktree that `git worktree list` names, and `origin/HEAD`, and add one, starting at `0001`. Scan all three, because parallel worktrees otherwise take the same serial. Skip a source that fails, such as no remote, and without git list the directory only. Keep the whole name stable when the file is edited, and update the same artifact in place. ADRs use their decision number as the serial: `docs/adr/NNNN-adr-<slug>-YYYY-MM-DD.md`. Multi-file artifacts put the convention on their bundle directory, such as `docs/verify/NNNN-verify-<slug>-YYYY-MM-DD/`, while structural child names remain fixed. A skill that finds an artifact by name matches an optional leading `NNNN-`, so it still sees files written before the serial. Inline the applicable rule in every public skill that creates such an artifact, so the installed skill remains self-contained.

### Cross-referencing steps
**Never reference a step by its number** (a bare "see step N" citation), because the number points at the wrong step once steps move. Reference the step's *identity* instead: for a step with a heading, link to it by name with a GitHub anchor (`[Gather intent](#1-gather-intent)`, since GitHub builds the anchor from the full heading text by lowercasing it, dropping punctuation, and turning spaces into hyphens); for a list item with no heading, name the action in prose rather than citing its ordinal.

### Closing hand-off
**Every skill ends by reporting what it did and naming what comes next**, in a closing section titled `## Hand off` (or `### N. Hand off` inside a numbered procedure; a mode-per-section skill gets one per mode). Three beats, in order. **What changed**: the mutations, concretely, including the ones that didn't happen. **Where it landed**: paths, branches, URLs, so nothing has to be hunted for. **Next**: the single best move, crowned, not a menu of equals. Route, don't launch: name the follow-up and its one-line invocation without invoking it, name a sibling skill only when it's installed, and always give the plain fallback ("open a PR with a PR skill, otherwise `gh pr create`"). A terminal skill says plainly there is no next step rather than inventing one; a read-only skill may drop an empty beat, never pad it.

## Quality bar

Apply every Conventions section, and these rules while drafting:

- **Front-load the leading word.** Put the compact term that names what the skill does first in `name` and `description`. Prefer a word the model already knows (`commit`, `review`, `slop`, `ledger`) to a coined one, which costs definition tokens. Repeat it as a *token* through the body; never restate it as a sentence.
- **"Use when" trigger.** The `description` starts with what it does, then a plain-English "Use when …" clause that names each branch's real phrasing plainly. The description loads on every turn whether or not the skill fires, so spend it on **one trigger per branch, not per synonym**: cover every mode, and collapse the phrasings that rename a single one. Cut identity the body already carries, such as the skill's rules or scope disclaimers. Prune synonyms, never coverage; a branch with no trigger silently never fires.
- **Write only what the model cannot already do.** A no-op is an instruction the model already obeys by default; settle a suspected one during [Live test](#7-live-test), and delete the whole sentence rather than trimming its words. Give one clause of why, and only when the reason is a non-obvious fact.
- **Keep the body to rules.** A skill body carries no argument after a rule, no trigger list (the description carries the triggers; the body keeps only routing rules), no Notes that repeat the body, and no note to a future maintainer.
- **Intent over incantation.** Pin an exact command only when it is a stable public contract (`git commit`, `gh pr create`, `grep`, `jq`), and make it self-correcting ("if a flag is rejected, check `gh pr create --help`"). Otherwise state the goal and let the agent read the docs.
- **One meaning, one place.** For internal skills, point to the host repo's conventions doc instead of restating it; for public skills, inline what they need (see Portability). The **environment** is a source of truth too (`package.json` scripts, a `Makefile`, a config file, `--help` output). Cache only what the agent cannot find by looking, such as the unwritten convention or the reason behind a choice.
- **Prompt the positive.** State the target behavior ("write one-line comments" beats "don't write long comments"), because a prohibition makes the forbidden behavior more available. A prohibition earns its place only as a hard guardrail you cannot phrase positively, and even then it gets a positive target beside it.

## Portability (public skills only)

A public skill is installed on its own into arbitrary environments. Only its own directory travels, so it must stand alone:

- **Self-contained.** Inline the conventions it relies on. No repo-relative links (`../…`), and no hard dependency on the host repo's Makefile, conventions doc, or helper tooling. If it needs a helper script, bundle it inside the skill's own directory.
- **Machine/OS-agnostic.** No absolute paths, no platform-specific assumptions; prefer instructions that work on any shell or none.
- **Environment-degrading output.** When a filesystem and shell are available, write/edit files directly; when they aren't (e.g. a browser-based agent), print the finished artifact as a codeblock for the user to save, and skip repo-only steps like dev-linking and linting.

Internal skills are exempt and may use their repo's machinery freely.
