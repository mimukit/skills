# AGENTS.md

Conventions for AI agents authoring or maintaining skills in this repository — a personal collection of AI agent skills. Follow these whenever you create, rename, or edit a skill.

## Skill naming: the `kit` convention

Every skill uses a **`kit` suffix** — a personal brand hidden in the owner's name, mu**kit**, that also reads as "a kit for X."

Rules:
- **One word, lowercase**, functional term first with `kit` appended: `commitkit`, `humankit`, `prkit`.
- **The functional word must lead** so the skill stays searchable — people search `commit`, not `kit`. Never bury the term behind a prefix.
- **Shorten an awkward root** rather than force a clumsy join: `humanize` → `humankit`, not `humanizekit`.
- **Avoid collisions** with well-known tools: `speckit` (GitHub spec-kit), `shipkit` (SaaS boilerplate), and anything already popular.
- The `name:` field in a skill's frontmatter **must match its directory name exactly**.

## Descriptions

A `description` is a **context pointer** — it names material the agent isn't holding and encodes the condition for reaching it. Every description in the collection loads on every turn whether or not its skill fires, so the wording does the triggering work and the whole set shares one budget.

- **Front-load an English "Use when …" trigger**, so agent triggering and text search work regardless of the branded name.
- **One trigger per branch, not per synonym.** A branch is a distinct case the skill handles, usually a mode. Cover every branch; collapse the phrasings that rename a single one. "teach me X" and "I want to learn X" are one branch written twice, where "teach me X" and "quiz me" are two branches.
- **Cut identity the body already carries.** A pointer states what the material is and when to reach it. It doesn't restate the skill's rules, its guarantees, or its scope disclaimers.
- **Undertriggering is still the expensive failure.** Prune synonyms, never coverage — a branch with no trigger silently never fires, and no lint rule can see that.

## The two loads

Every document, pointer, and skill you add spends one of two budgets. Name the one it spends before you add it.

- **Context load** — the cost of always-loaded material on the agent's window: a description, a line in this file, anything sitting in context every turn whether or not it fires.
- **Cognitive load** — the cost on the human: knowing which skills exist and when to reach for each. The human is the index. This one is not a cost to minimize; it is the price of human agency. Spend it where human judgement matters and remove it where it doesn't.

Material behind a pointer escapes context load for the price of the pointer's own line. Material with no pointer at all rides entirely on cognitive load.

**This is the gate on a new skill.** A skill earns its own directory when a human genuinely wants to choose it — a distinct moment, a distinct decision they'd make deliberately. When the choice is one the agent should make from context instead, it's a mode inside an existing skill: a mode costs one branch in a description, where a skill costs a permanent entry in the index a person has to hold.

## Information hierarchy

A skill is built from **steps** (the ordered actions the agent performs) and **reference** (definitions, rules, and facts consulted on demand). The two mix freely — all steps, all reference, or both. The decision is where each piece sits on a ladder ranked by how immediately the agent needs it:

1. **In-file step** — the primary tier: what the agent does, in order.
2. **In-file reference** — consulted on demand. A flat peer-set is fine here (every rule of a review sitting on one rung); flatness is not a smell.
3. **Disclosed reference** — pushed into a satellite file inside the skill's own directory, reached by a pointer, loaded only when that pointer fires.

- **Disclose by branch, not by size.** Inline what every branch needs; push behind a pointer what only some branches reach. "Large and needed only sometimes" is the blurrier older version of this test — the branch test is checkable.
- **Mode satellites have a fixed shape.** A skill whose modes are skipped branches splits into a routing root plus `modes/<mode>.md`, one file per mode (issuekit, wikikit, mergekit, ideakit, tutorkit). The root keeps mode selection, guards, and the vocabulary every mode shares, plus one pointer per mode in the trigger-carrying form: ``mode `close` → read [modes/close.md](modes/close.md), then follow it``. A satellite assumes the root is already loaded and never repeats its material; per-mode hand-offs move with their mode bodies. The gate stays the branch test above, never raw size — a straight-through skill (statuskit, afkkit) stays one file whatever it weighs, because every run walks its whole body and a split would only add reads. `make lint` resolves every relative pointer, runs the anchor and step-ref checks on satellites, and accepts a split skill's closing sections in the root or in every mode file.
- **Push too much down and you hide material the agent needs.** Push too little and the top bloats. That tension is the whole decision, and neither direction is the safe default.
- **Co-locate a concept.** Keep a definition, its rules, and its caveats under one heading rather than scattered through the file. Scattering is not duplication — duplication repeats one meaning in two places, scattering fragments one meaning across many — and it fails differently: the agent reads one part and never meets the rest.
- **Sprawl is the failure mode here** — a skill simply too long, even when every line is live and unique. Attention thins across the excess. The cure is the ladder, not a trim pass.

## Steps and completion criteria

**Every step ends on a completion criterion — the condition that tells the agent the work is done.** A step without one ends when the agent feels finished, which is the largest single source of run-to-run variance. Two properties make the criterion a lever:

- **Clarity** — can the agent tell done from not-done? A vague bound ("understanding reached", "keep it lean") invites **premature completion**: the step ends early because attention has already slipped to the steps still visible ahead of it.
- **Demand** — how much the wording requires. "Every modified model accounted for" forces real digging where "produce a change list" does not. Prefer the exhaustive form to the productive one. Demand is not step-bound: "every rule applied" binds a body of flat reference the same way, which is how an all-reference skill still carries a bar.

The strongest criteria are both checkable and exhaustive.

**Sharpen a rushed step's bound first** — that edit is local and cheap. Split the sequence only when the bound is irreducibly fuzzy *and* you have watched the rush happen. Splitting works only across a real context boundary, meaning a hand-off document or a subagent dispatch; an inline call leaves the later steps in context and hides nothing.

## Pruning

- **Keep each meaning in a single source of truth**, so changing the behavior is a one-place edit. Duplication costs maintenance and tokens, and it inflates a meaning's rank on the hierarchy past its real one. [Portability](#visibility-internal-vs-public) is the one licensed exception, bounded by the conclusion-vs-derivation seam stated there.
- **The environment is a source of truth too** — `package.json` scripts, a `Makefile`, a config file, `--help` output. A skill that restates one is a **cache**, and a cache earns its load only when the lookup is expensive. Cache what the agent cannot find by looking: the unwritten convention, the reason behind a choice, the gotcha no config confesses. Leave the one-command lookups to the environment, where they cannot go stale.
- **A repeated term is a lever, not a metaphor slip.** A compact word the model already knows (`crown`, `slop`, `ledger`, `cache`) anchors a whole region of behavior in one token — but only when it is repeated as a *token* and never restated as a sentence. Reach for a pretrained word before coining one: a made-up term recruits no priors, so you pay in definition tokens what an existing word gives free. This is what "one term per concept, kept" in [Prose register](#prose-register) is buying.
- **Prompt the positive.** Steering by prohibition drags the forbidden behavior into context and makes it *more* available, not less; the negation is a weak modifier over a strongly activated concept. State the target behavior instead ("write one-line comments" beats "don't write long comments"). A prohibition earns its place only as a hard guardrail you cannot phrase positively — "never commit automatically" is one — and even then it gets a positive target beside it.
- **Hunt no-ops sentence by sentence.** An instruction the model already obeys by default pays load to say nothing. The test is model-relative rather than reader-relative: two people disagreeing about a no-op disagree about the *default*, and they settle it by running the skill, not by arguing. When a sentence fails, delete the whole sentence rather than trimming its words.

## Prose formatting

- **No hard wrapping.** Write each paragraph and list item as one continuous line; let the editor and renderer soft-wrap. Fixed-width line breaks mid-sentence buy nothing here — the agent reads the text regardless of newlines, and every Markdown renderer soft-wraps anyway. Keeping prose on one line per paragraph makes editing and reflowing painless.
- This applies to prose and bullets only. Leave line structure intact where it is meaningful: code fences, tables, and YAML frontmatter (a folded `description: >-` scalar is fine).

## Prose register

**This register governs what a skill writes back to its own operator.** It does not govern content a skill produces for a third-party audience — project documentation, published prose, UI copy, PR and issue bodies. That is production writing for readers who are not in the session, and it needs the freedom to explain a concept and to use the sentence length the idea requires. A content-generating skill such as `humankit` or `wikikit` keeps its own standards, and this section does not reach them.

Within agent-to-operator text, every artifact has one of three registers. Classify it before writing it.

- **Procedural** — text a person reads *while doing something*: QA steps, handoff documents, status snapshots, `Hand off` sections, next-move lines, acceptance criteria, preview-and-confirm lines. Write it in ASD-STE100 Simplified Technical English. One instruction per sentence. Procedural sentences 20 words or fewer, descriptive sentences 25 or fewer. Active voice, present tense, name the actor. Keep the articles, and use a plain verb in place of a gerund. No metaphor, idiom, or second meaning. Six sentences per paragraph at most. Within a single document, pick one term per concept and keep it — this rule is scoped to the document, never to the repository, so `crown` and `rank` may still mean different things in two different skills.
- **Explanatory** — text a person reads *to form an opinion*: plan context, research recommendations, ADR rationale, review verdicts. The AI-tells rules govern this, and `humankit` owns the catalog. Do not apply STE here; it strips the register that makes a position readable.
- **Exempt** — machine-read or format-bound text: Conventional Commits subjects, issue titles, prompts, design tokens, code, paths, commands, and anything quoted from another source.

Precedence: an explicit user instruction, then the target repository's own documented convention, then the register.

A skill's closing hand-off is procedural, whatever that skill produces for its reader. See [Closing a skill: the hand-off](#closing-a-skill-the-hand-off) for its structure.

## Documentation artifact naming

When a skill creates a durable Markdown artifact under `docs/`, use `<type>-<slug>-YYYY-MM-DD.md`: a lowercase type prefix, a short lowercase kebab-case subject slug, and the artifact's ISO creation date at the end. Examples: `docs/plans/plan-sso-login-2026-07-23.md`, `docs/research/research-auth-providers-2026-07-23.md`, `docs/qa/qa-login-throttling-2026-07-23.md`, `docs/reviews/review-auth-refactor-2026-07-23.md`, and `docs/handoffs/handoff-auth-migration-2026-07-23.md`.

- **Creation date, not modification date.** Keep the filename stable when the artifact is edited; record a later update date inside the document if useful.
- **Same subject means update in place.** Do not create a second file for the same artifact. For genuinely distinct artifacts that would collide on type, slug, and date, make the slug more specific; only as a last resort insert a sequence immediately before the date (`research-auth-providers-02-2026-07-23.md`) so the filename still ends with the date.
- **ADRs keep their sequence.** Use `docs/adr/adr-NNNN-<slug>-YYYY-MM-DD.md`, with a zero-padded monotonically increasing decision number. The number is the decision order; the date is its creation date.
- **Bundles put the convention on the directory.** For a multi-file artifact such as visual verification, use `docs/verify/verify-<slug>-YYYY-MM-DD/` and keep structural children such as `notes.md` and `proof.md` fixed inside it.
- **Existing project convention wins.** A public skill may honor a target repository's established artifact location or naming scheme. Its own documented fallback must follow this convention and inline the rule because public skills cannot depend on this file.

## Cross-referencing steps

- **Never reference a step by its number** (`see step 4`, `from step 2`). A bare number binds to a step's *position*, so inserting or reordering steps silently makes it point at the wrong one — and no tool can detect a stale-but-valid number. Reference the step's *identity* instead.
- For a step that has a heading, link to it by name with a GitHub anchor: `see [Group the work into multiple commits](#4-group-the-work-into-multiple-commits)`. GitHub builds the anchor from the full heading text (lowercase, punctuation dropped, spaces → hyphens, consecutive hyphens preserved, `'` removed — `what's` → `whats`). Numbered headings are fine to keep; the anchor and the link move together.
- For a step that's a list item inside a section (no heading, no anchor), name the action in prose (`` `start`'s **Adopt check** step``) rather than citing its ordinal.
- `make lint` enforces both halves: every intra-doc `](#anchor)` link must resolve to a real heading (error), and any surviving `step N` reference is flagged (warning). Rename or move a referenced heading and the link breaks *loudly* in lint instead of rotting silently.

## Closing a skill: the hand-off

**Every skill ends by reporting what it did and naming what comes next.** A skill that goes quiet at the end leaves the user to reconstruct both — what actually changed on disk, and which of a dozen kits owns the next move. That reconstruction is the exact work these skills exist to remove, and it's most expensive right at the point the user has stopped paying attention.

- **Name the closing section `## Hand off`** (or `### N. Hand off` inside a numbered procedure; a mode-per-section skill gets one per mode). Some skills predate this and close under `Report`, `Output`, `Finish`, or `After creating` — those are grandfathered and lint accepts them, but anything new or rewritten uses `Hand off`.
- **Three beats, in order.** *What changed* — the mutations, concretely, including the ones that didn't happen. *Where it landed* — paths, branches, URLs, so nothing has to be hunted for. *Next* — the single best move. Fold a beat into a line when it's trivial; drop one only when it's genuinely empty (a read-only skill changed nothing), never pad it.
- **Crown one next move, not a menu.** Ranking is the skill's job — it just did the work and knows what the state is. Runners-up are fine after the crowned move; a list of five equal options isn't a recommendation.
- **Route, don't launch.** Name the kit and its one-line invocation; don't invoke it. The user decides whether to take the suggestion, and a skill that chains itself into the next one takes that call away.
- **Name a sibling kit only when it's installed, and always give the plain fallback** ("open a PR with **prkit**, otherwise `gh pr create`"). Public skills get installed alone into repos that have none of the others — a next step that assumes the ecosystem is a dead end there.
- **Say when there is no next step.** A terminal skill that invents a follow-up to look useful is worse than one that stops.
- **Write it in the procedural register.** A hand-off is read at the moment attention is lowest, so it follows the rules in [Prose register](#prose-register): one instruction per sentence, active voice, present tense, no metaphor. This holds even for a skill whose own output is public-facing prose, because a hand-off is the skill talking to its operator, not the artifact it just produced.
- `make lint` warns when a skill has no recognized closing section at all. It can't judge whether the three beats are any good — that's a review job, not a grep.

## Visibility: internal vs public

Skills here fall into two classes, declared explicitly in frontmatter as `metadata.internal: true|false`:

- **`internal: true`** — a repo-only maintenance/meta skill. It may lean on this repo's machinery: `AGENTS.md`, the `Makefile`, repo-relative links. skills.sh honors this native field by **hiding the skill from discovery** — it only installs when someone sets `INSTALL_INTERNAL_SKILLS=1`, so internal skills are effectively unpublished.
- **`internal: false`** — a publishable skill (e.g. `commitkit`, `humankit`). It must be **portable**: self-contained (conventions inlined, no repo-relative links, no hard dependency on `make`/`AGENTS.md`/`scripts/`), machine/OS-agnostic, and environment-degrading — it writes files when a filesystem is available and otherwise prints its output as a codeblock. Once pushed to the public repo, skills.sh discovers `skills/<name>/SKILL.md` automatically and lists it via install telemetry; there is no separate publish step.

**Portability outranks the no-duplication rule, and the seam is conclusion vs derivation.** A public skill installs alone, so one that needs a fact another skill owns must carry enough of it to keep working. It may state the other skill's **answer** together with a degradation fallback ("gitkit owns the sync rule, and it resolves to rebase; without gitkit, rebase onto the base"). It may not reproduce the **reasoning that produces** that answer — a full resolution ladder, a path formula, a policy argument. An answer is one line that breaks loudly on a rename; a derivation is a second implementation that drifts silently.

`make lint` enforces the marker on every skill, flags likely portability breaks in public skills, and warns when a skill declares no `allowed-tools` — the field is a real backstop here (researchkit withholds the shell precisely so a host that honors it cannot run a spike), so an undeclared surface should be a deliberate, documented choice rather than an omission.

## Directory page: `skills.sh.json`

The repo-root `skills.sh.json` groups how public skills render on the skills.sh directory page (it does not affect CLI installs). **Whenever you add, rename, or remove a public (`internal: false`) skill, update `skills.sh.json` in the same change** so the grouping stays in sync:

- Add every new public skill to the most fitting group's `skills` array (create a new group only when an existing one doesn't fit); rename or drop entries when a skill is renamed or removed.
- Never list `internal: true` skills — skills.sh hides them from discovery, and they are silently ignored here anyway.
- Skills left out of every group fall into an "Other skills" section positioned by `notGrouped` — that's an acceptable landing spot until a skill earns a group.

## Per-skill wiki pages: `docs/wiki/skills/`

Every skill has a reader-facing page at `docs/wiki/skills/<name>.md`. **`SKILL.md` is written for the agent that runs the skill; the wiki page is written for the human deciding whether to reach for it** — what it does, when it fires, how its modes work, what it hands off to. The two have different audiences, which is why the page is not a copy and not a summary.

**Whenever you change a skill, update its page in the same change.** This is the rule that keeps the set honest, and it is not optional bookkeeping — a page that describes a mode the skill no longer has is worse than no page, because a reader has no way to know it's lying.

What actually obliges an edit:

- **A new or renamed mode** — the page's mode section, and its heading. Lint errors on a mode heading naming a mode the `SKILL.md` doesn't define.
- **A changed `description`, `allowed-tools`, or `metadata.internal`** — the page's summary table carries all three.
- **A changed hand-off target** — the page's *Hands off to* section names the next kit; a rename or reroute leaves it pointing at nothing.
- **A materially changed rule, guard, or default** — the page explains the *why* behind the load-bearing ones. Reword a guard and the explanation goes stale with it.
- **Adding or removing a skill** — add or delete the page, **register or unregister it in `docs/wiki/.wikimap.yaml`, and link or unlink it in `docs/wiki/index.md`**. A page is only really there when all three agree: the map is what a docs audit sweeps, and the index is what a reader navigates. Lint errors both ways on all three, so a missing page, an unregistered one, and an unreachable one each break the gate. It cannot check *placement* — a skill linked under the wrong theme in the index passes — so filing it sensibly stays a judgment call.

Prose changes that don't move any of those don't need a page edit. Use judgment; the test is whether a reader who only read the page would now be wrong.

**Page conventions**, so lint can check what it can and a reader gets a consistent shape:

- **Open with the one-line description, then a bold "Reach for it when" trigger, then the summary table** (modes · tools · writes · visibility).
- **Write a mode section as `` ### `mode` ``** — a backticked `h3` under a `## Modes` heading. That backticked form is what lint checks against the `SKILL.md`, so it is an opt-in: a skill whose modes genuinely aren't backticked in its own source (implementkit's straight-through and TDD) uses a plain heading and is simply not mode-checked.
- **Link sibling skills as `` [`gitkit`](./gitkit.md) ``**, and link the source as `` [`skills/<name>/SKILL.md`](../../../skills/<name>/SKILL.md) `` at the foot.
- **End with the install command and the provenance stamp** — `` _Verified against `main`@`<sha>` on YYYY-MM-DD._ `` The stamp is what a later docs audit diffs from; a page without one has never been verified. **Re-stamping asserts a re-read.** Moving the stamp forward is a claim that somebody looked at the skill and confirmed the page still describes it — so re-stamp when that happened, and leave the stamp alone when it didn't. A stamp bumped as a formality is worse than a stale one, because it launders an unverified page as a checked one.
- **Explain the why, don't restate the what.** The page earns its place on the reasoning behind a rule — why `gitkit` refuses to delete a branch it didn't create, why review runs on a different model family. Restating the procedure step by step is what `SKILL.md` already does better.

**The cheatsheet is derived from these pages, so run `make cheatsheet` after you edit one.** `docs/wiki/cheatsheet.md` lists every skill and every mode, one line each, and every line comes from a skill page — the skill's row from the page's opening sentence, a mode's row from the first sentence under its `` ### `mode` `` heading. Nothing on it is authored, and `make lint` diffs the committed page against a fresh generation, so a stale cheatsheet is an error rather than a rot. When a page's own prose doesn't reduce to a good row, pin the row where the prose lives with `<!-- cheatsheet: … -->` under the heading; the page stays the single source, and the comment renders as nothing.

`make lint` enforces the mechanical half on every full run — page-per-skill, map-entry-per-skill, and index-link-per-skill, each in both directions, plus mode parity. It also **warns when a commit touching exactly one skill lands without that skill's page**, which is the shape of a forgotten page edit. A repo-wide prose sweep touching many skills at once is exempt by construction, because that is the shape where a page edit genuinely isn't owed. Lint still cannot tell whether the prose is true; that's a review job.

## Layout

- Flat: `skills/<name>/SKILL.md` — one skill per directory. This is home for **public** skills and any skill you dev-link for testing.
- **Internal, always-on repo skills live in `.agents/skills/<name>/`** instead (none currently). Checked in there, they're auto-discovered by any tool that reads `.agents/skills` and by Claude Code via a committed relative symlink at `.claude/skills/<name>` — no `make link` needed. This is the right home for a meta-skill that only makes sense *inside this repo*; it keeps such skills off the global tool dirs and out of the `skills/`-based `make lint`/`make list`/skills.sh machinery by design.
- Skills are **authored from scratch, never forked.** A skill may be "my version of" an upstream skill, rewritten to fit these conventions.
- Bash lives in `scripts/`, surfaced through the `Makefile` (`make help`). `make link`/`unlink` mirror a dev symlink into **both** `~/.claude/skills` and `~/.agents/skills` so the skill is live in every AI tool at once. When a dev link collides with a **real install of the same name** (e.g. a `skills.sh` install of `commitkit`), `make link` moves the real one aside to a `<name>.skshbak` sibling and symlinks over it — the skill shows as `⇄ swapped` in `make list` — and `make unlink` restores the backup, so you can live-test the repo copy under its real name without losing the published install.

## Frontmatter template

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
