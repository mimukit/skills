# Plan — context budget across the collection

_Created 2026-08-07._
_Grilled: 2026-08-07._

## Context

A `/usage` breakdown for the last 24h flagged two behaviours and offered two remedies:

> **18% of your usage was at >150k context.** Longer sessions are more expensive even when cached. `/compact` mid-task, `/clear` when switching to new tasks.
>
> **17% of your usage came from `/implementkit`.** Heavy skills can be scoped down or run with a cheaper model via skill frontmatter.

The attributed shares: implementkit 17%, commitkit 11%, mergekit 9%, grillkit 9%, plankit 7%, claude-api 3%, skillkit 2%, issuekit 2%.

Investigating those two suggestions turned up a third problem neither of them names, and closed off one of the two suggested remedies entirely. This plan is the result: a **context budget** convention for the collection, the six skill bodies that violate it today, and afkkit's answer to a compaction it cannot trigger.

It is the sequel to [plan-afkkit-cost-optimization-2026-08-06.md](plan-afkkit-cost-optimization-2026-08-06.md), which allocated cost *within a single afkkit run* and produced the model-routing table and the orientation file. That plan optimised what afkkit's subagents pay. This one optimises what every skill costs the session that loaded it, and what survives when the session is summarised.

## Evidence

Verified against Claude Code **2.1.220** and the current skills, hooks, and cost documentation. Every claim below was checked; the two that were disproved are recorded under [What was disproved](#what-was-disproved) rather than dropped.

### A skill body is a recurring cost, not a one-time one

> Once a skill loads, its content stays in context across turns, so every line is a recurring token cost.

> When you or Claude invoke a skill, the rendered `SKILL.md` content enters the conversation as a single message and stays there for the rest of the session. Claude Code does not re-read the skill file on later turns.

This is the mechanism behind the *18% at >150k context* flag as it applies to this collection specifically. Twenty-four skills averaging 188 lines are not free to have around; they are free only until invoked, and permanent afterwards.

### Auto-compaction silently truncates skills

The load-bearing finding, and the one nothing in the repo currently accounts for:

> Auto-compaction carries invoked skills forward within a token budget. When the conversation is summarized to free context, Claude Code re-attaches the most recent invocation of each skill after the summary, **keeping the first 5,000 tokens of each**. Re-attached skills share a combined budget of **25,000 tokens**. Claude Code fills this budget starting from the most recently invoked skill, so older skills can be dropped entirely after compaction if you have invoked many in one session.

Two consequences.

**Per-skill:** anything past ~5,000 tokens in a body stops applying after the first compaction — silently, with no warning, in exactly the long session where the rules matter most. Six bodies are over the line:

| skill | bytes | lines | ~tokens | must shed | what currently sits past the 5k mark |
|---|---|---|---|---|---|
| issuekit | 40,533 | 504 | ~10,133 | 20,533 | the later lifecycle modes |
| **afkkit** | 36,623 | 267 | ~9,155 | 16,623 | **the escalation contract, batch mode, hand-off** |
| wikikit | 31,544 | 427 | ~7,886 | 11,544 | audit + publish modes |
| uikit | 25,647 | 322 | ~6,411 | 5,647 | the audit half |
| mergekit | 22,357 | 241 | ~5,589 | 2,357 | `fix` mode |
| designkit | 21,281 | 296 | ~5,320 | 1,281 | tail of the spec |

afkkit is the worst case in kind, not just in size: an unattended orchestrator whose *escalation policy* — the one thing it owns — is the part that gets dropped.

**Combined:** a session that runs the kits inline (issuekit → implementkit → commitkit → reviewkit → qakit → prkit) re-attaches ~26k of skill content against a 25k budget, filled most-recent-first. The oldest — issuekit, which carries the `ready` guard — drops entirely. afkkit's subagent dispatch already avoids this by keeping those bodies out of the conductor's context; a human running the same kits by hand in one session does not.

### A reference file is deleted by compaction, not truncated by it

Established during the grill, and it constrains every split boundary below. Moving content from `SKILL.md` into `references/<topic>.md` changes *what kind* of context it becomes:

- **In the body:** re-attached after every compaction, up to the 5k ceiling. Above the ceiling it is truncated.
- **In a reference file:** absent until read, then it is ordinary conversation content — and ordinary conversation is what compaction *summarises away*. A guard moved to `references/` is not truncated after a compaction; it is gone, with no ceiling protecting the first part of it.

So `references/` is not a free win. It trades a permanent recurring cost for a per-use cost plus a tool round-trip, and it forfeits compaction protection entirely. That is a good trade for material read once or never; it is a bad trade for anything that must be true *before* the agent decides what to do.

### Two skills' bulk is shared, not per-mode

A heading census of the six oversized bodies splits them into two populations, which is why one split rule cannot serve all six:

- **Per-mode bulk** — issuekit (`create` ~160 lines of ~470), wikikit (`publish` ~139 of ~427), mergekit (`fix` ~46). The modes are where the weight is.
- **Shared bulk** — uikit (anti-slop catalog ~69, stack layer ~40, design read + precedence ladder ~57, against only ~66 lines in `build` + `audit` combined), designkit (the artifact spec ~73 plus the extraction engine ~57, against ~20 lines per mode), afkkit (single procedure, no modes).

### The frontmatter surface is larger than the collection uses

Claude Code 2.1.220 supports `model`, `effort`, `context: fork` (+ `agent`, `background`), `disallowed-tools`, `hooks`, `paths`, and more. **None of the 24 skills sets any of them.** The collection uses `name`, `description`, `license`, `allowed-tools`, `metadata`, and `disable-model-invocation` (handoffkit only).

Three constraints on using them, all verified against the current skills:

- **`context: fork` gives the subagent no conversation history.** "The skill content becomes the prompt that drives the subagent. It won't have access to your conversation history." A backgrounded fork also runs with the narrower background-subagent tool set, which excludes `AskUserQuestion`.
- **`agent: Explore` has no `Write`.** The Explore agent type runs with every tool *except* `Agent`, `Artifact`, `ExitPlanMode`, `Edit`, `Write`, `NotebookEdit`. statuskit declares `allowed-tools: Bash, Read, Write, Skill` and its snapshot step is explicitly *"the default, not an offer"* — so `agent: Explore` would silently disable statuskit's default output.
- **They are Claude Code extensions.** The Agent Skills spec's validator — claude.ai uploads, the Skills API, `package_skill.py` — accepts only `name`, `description`, `license`, `compatibility`, `metadata`, `allowed-tools`, and errors on anything else. These skills ship through skills.sh into `~/.claude/skills/`, where every field works, so the trade-off is accepted and recorded rather than avoided.

### skillkit already owns a stricter rule

`skills/skillkit/SKILL.md` states, in its quality bar:

> **Stay lean; progressive disclosure** — prefer one `SKILL.md`. Add a satellite file (`references/…`) only when content is *large* **and** needed *only sometimes*; guidance needed on every run belongs inline.

Phase 2 as originally drafted violated this on its face — issuekit's own heading reads `## Lifecycle labels (every mode)`. skillkit is `metadata.internal: false`, so it cannot point at `AGENTS.md`; it must carry the rewritten rule inline. `AGENTS.md` holds the canonical copy and skillkit holds the portable one, and **both change in the same commit** or the collection contradicts itself.

### What was disproved

**A skill cannot compact itself.** The `/usage` tip says "compact mid-task", and the obvious reading — have afkkit run `/compact` between issues — is not implementable. `/compact` is a built-in user command; there is no model-invocable compaction tool in this build (no `SlashCommand` tool, nothing compaction-shaped in the tool surface). Compaction is either user-typed or automatic at threshold.

**A `PostCompact` hook cannot restore context either.** The hook fires and its output is wrapped as a `userDisplayMessage` — it reaches the terminal, not the model. `PreCompact` receives `custom_instructions` as input; it does not get to set them. So there is no hook path that re-injects run state after a summary.

What *is* reachable, and is what Phase 3 builds instead:

- shrink the body so compaction has nothing to truncate;
- checkpoint run state to disk so a summary can't lose it;
- **re-invoke the skill**, which is free when nothing changed ("Claude Code adds a short note that the skill is already loaded rather than a second copy") and restores the full body after a compaction ("If the skill is large or you invoked several others after it, re-invoke it after compaction to restore the full content");
- point the user at the `# Compact instructions` block in `CLAUDE.md`, the one supported way to steer what summarisation preserves.

## Settled decisions

Settled with the user on 2026-08-07 — the first four before the grill, the rest during it.

| # | Decision | Resolution |
|---|---|---|
| — | **Adopt Claude Code-only frontmatter in public skills?** | **Yes.** These install into `~/.claude/skills/` via skills.sh, where `model`/`effort`/`context`/`hooks`/`disallowed-tools` all work. The cost — frontmatter that a claude.ai upload or `package_skill.py` run would reject — is recorded in `AGENTS.md` rather than avoided. |
| — | **How many oversized bodies to fix now?** | **All six.** Fixing afkkit alone leaves issuekit — the largest body, and the one holding the `ready` guard the whole unattended pipeline rests on — truncating after every compaction. |
| — | **Codify it?** | **`AGENTS.md` convention + `make lint` enforcement.** A documented-only rule drifts; the next skill written reintroduces the problem, and nothing catches it. |
| — | **Cap implementkit's model or effort?** | **No.** It is 17% because it does the most work, and the prior plan's finding holds: "The way to make a step cheap is to hand it what it needs, not to ask it to think less." Fix it by deleting rediscovery, not by dropping a tier. |
| Q1 | **What is the split rule?** | **Hybrid, chosen per skill by where the bulk sits.** Per-mode bulk → mode-dispatch (thin router body, `references/<mode>.md` read on dispatch). Shared bulk → execution-need (only never-executed material moves). **Carve-out that overrides both:** anything that must be true *before* dispatch stays in the body regardless of size. `skillkit`'s quality-bar line is rewritten in the same commit. |
| Q2 | **`context: fork` on statuskit and researchkit?** | **statuskit only,** with `background: false` and **no `agent:` line** — Explore has no `Write` and would kill the default snapshot. researchkit is **not forked**: it declares `AskUserQuestion`, which is the exact combination Phase 1's own new lint check exists to warn about. |
| Q3 | **Lint thresholds?** | **`E` at 20,000 bytes, `W` at 16,000,** with the byte→token basis in the message text. Four more skills warn on day one — reviewkit 18,296, orcakit 17,707, validatekit 17,600, gitkit 16,200 — and are **knowingly left warning**; `scripts/lint.sh` exits non-zero on errors only. |
| Q4 | **afkkit state files and `disallowed-tools`?** | **Two files, `disallowed-tools` kept.** The two roots map to two real lifetimes. The body states plainly that with `Bash` still allowed this is a **speed bump on the natural path to editing code, not a sandbox** — Phase 3 claims a raised bar plus declared intent, not enforcement. |
| Q5 | **Who writes `.kit-orientation.md`?** | **afkkit alone.** The four downstream kits get a *read-if-present* line only. implementkit does not write it: that would drop an untracked dotfile at any repo root, and implementkit has none of the `git rev-parse --git-path info/exclude` machinery that keeps afkkit's copy out of the PR diff. |
| Q6 | **`effort: low` on commitkit?** | **No — `effort: medium`.** An explicit floor so commitkit stops inheriting a high-effort session for a grouping call, without the tier where multi-commit splits degrade. Its body is already context-frugal, so the 11% is reasoning on volume; but a bad split is permanent in history. `low` still applies to repokit and orcakit. |
| Q7 | **Which half applies to uikit?** | **Execution-need.** Its `build` + `audit` modes are only ~66 lines of ~330; the anti-slop catalog, stack layer, and design read are shared. Mode-dispatch would barely move the number. designkit joins it in the shared-bulk camp on the same evidence. |
| Q8 | **Sequencing?** | **Pilot afkkit, then fan out.** Phase 1's checks land with the ceiling as `W`; afkkit's split + all of Phase 3 land next and are validated end-to-end; then one issue per remaining skill; the `W`→`E` flip is the final commit. |
| — | **`hooks: PostCompact` on afkkit?** | **Dropped.** Its only product is an on-disk marker, and the run ledger already writes one at every step boundary. |

## Changes

### Phase 0 — this document ✅

Written and grilled. Referenced by every phase below.

### Phase 1 — the convention, and the lint that enforces it

**`AGENTS.md`, new section "Context budget"** (after "Prose formatting"):

- **Body ceiling: ~5,000 tokens (~20,000 bytes).** State the mechanism, not just the number — a body over the line is silently truncated after every auto-compaction, so the rules at the bottom stop applying exactly when a long session needs them. **Front-load the guards**; never let one sit in the last third of a long body.

- **What `references/` actually costs.** Per [A reference file is deleted by compaction](#a-reference-file-is-deleted-by-compaction-not-truncated-by-it): a satellite file is absent until read, and once read it is ordinary conversation that compaction summarises away with no 5k floor protecting it. Splitting is a trade, not a free win, and the rule below is how to make it correctly.

- **The split rule — pick the half by where the bulk sits.**

  | the skill's bulk is… | rule | applies to |
  |---|---|---|
  | in its modes | **mode-dispatch** — body keeps identity, when-this-fires, shared preflight, the mode router, shared guards, and hand-off; each mode's procedure becomes `references/<mode>.md`, read on dispatch | issuekit, wikikit, mergekit |
  | shared across modes, or there are no modes | **execution-need** — only material never read *during* a run moves out: rationale essays, measurement tables, catalogues consulted on demand, degradation appendices, non-goals | uikit, designkit, afkkit |

- **The carve-out that overrides both.** Anything that must be true **before** the agent decides what to do stays in the body regardless of size — mergekit's never-merge-automatically, issuekit's `ready` guard, afkkit's escalation contract, statuskit's zero-mutation stance. A guard behind a `Read` is a guard the agent reaches after it has already chosen; a guard in a reference file is one compaction deletes outright.

- **How a satellite is named from the body.** Under `## Additional resources`, one line per file with a "load this when…" trigger. For mode-dispatch skills the router's mode entry carries the pointer directly, so the read happens at dispatch and not before.

- **Which knob for which class of skill:**

  | class | knobs | why |
  |---|---|---|
  | mechanical — humankit, repokit, orcakit | `effort: low`; `model: haiku` where output quality is cosmetic | reasoning tokens are the whole bill on a step with no judgment in it |
  | mechanical but permanent output — commitkit | `effort: medium` | a floor, not a cut: grouping is a judgment call and a bad split lands in history forever |
  | read-only survey with no interactivity — statuskit | `context: fork`, `background: false` | the sweep's reads never enter the session's context. **No `agent:` line** — Explore has no `Write` |
  | autonomous, never edits — afkkit | `disallowed-tools` | raises the bar on the natural path to editing code, and declares the intent |
  | interactive — plankit, grillkit, validatekit, skillkit, designkit, uikit, wikikit, researchkit | none | a background fork loses `AskUserQuestion` and all conversation history |
  | context-dependent — commitkit's diff path | never `context: fork` | its cheap path is "you wrote these changes in this same context"; a fork destroys exactly that |
  | heavy by nature — implementkit | none, ever | cheaper here buys worse code; fix it by deleting rediscovery |

- **Never re-derive a fact an artifact records.** When a kit discovers repo facts a later kit will need, it writes them down once and downstream kits read that file. This is the orientation-file principle from the prior plan, promoted from an afkkit internal to a collection convention.

- **Portability note** naming exactly which fields are Claude Code-only and what rejects them.

**`skills/skillkit/SKILL.md`, same commit.** Its quality-bar line currently says satellites are for content that is "large **and** needed only sometimes; guidance needed on every run belongs inline" — which forbids mode-dispatch. Rewrite it to carry the split rule and the pre-dispatch carve-out **inline**: skillkit is `internal: false` and cannot reference `AGENTS.md`.

**`scripts/lint.sh`, three checks:**

| check | severity | why |
|---|---|---|
| body over 20,000 bytes (warn at 16,000) | `E` / `W` | the compaction ceiling. Message carries the basis — `~4 bytes/token; bodies over ~5k tokens are truncated after every auto-compaction` — so the reason travels with the warning |
| `](references/<file>.md)` and `](references/<file>.md#anchor)` resolve | `E` | `check_anchors()` today validates only `](#anchor)`; splitting bodies would trade a checked link for an unchecked one |
| `context: fork` together with `AskUserQuestion` | `W` | a backgrounded fork cannot ask the user — a contradiction a grep can actually catch, and the one that caught researchkit in this plan's own draft |

**Known day-one warnings, accepted:** reviewkit 18,296, orcakit 17,707, validatekit 17,600, gitkit 16,200. They are a visible backlog, not in scope here. Per Q8 the upper threshold ships as `W` and is flipped to `E` in the final commit of Phase 2.

### Phase 2 — split the six oversized bodies

One rule, two halves, applied per the table above. For every skill: heading-size census, move **whole sections** (never half of one), leave a one-line pointer, rewrite `](#moved-anchor)` links to `](references/<file>.md#moved-anchor)`, re-measure.

**Mode-dispatch half:**

| skill | moves | body keeps |
|---|---|---|
| **issuekit** (shed 20,533) | `create.md`, `sync.md`, `close.md`, `triage.md` — ~336 of ~470 lines | when-this-fires, preflight, title convention, the lifecycle-label vocabulary (shared by every mode), the mode router, the `start` mode **with its `ready` guard inline**, the shared comment action, notes, hand off |
| **wikikit** (shed 11,544) | `publish.md` (~139 lines, the single largest block in the collection), `init.md`, `audit.md` | the doc map, page vocabulary, provenance stamp, grounding rules, the `update` mode — the most-run and smallest — writing standards, hand off |
| **mergekit** (shed 2,357) | `fix-mode.md`, and review-pack composition detail | **never merge automatically**, preflight, what gitkit owns, `list`/`start`/`finish` |

**Execution-need half:**

| skill | moves | body keeps |
|---|---|---|
| **uikit** (shed 5,647) | `anti-slop.md` (the tells catalogue + accessibility floor), `stack.md` (Tailwind v4 + shadcn/ui specifics) | the precedence ladder, the design read, both modes, the written pre-flight, degrade-loudly |
| **designkit** (shed 1,281) | `spec.md` (token schema, sections, what-never-goes-in-YAML, the stamp), optionally `extraction.md` | the CLI-is-source-of-truth rule, all three modes, token sync, degrade-loudly |
| **afkkit** (shed 16,623) | see Phase 3 | see Phase 3 |

**afkkit will not reach 20,000 on reference material alone, and that is the pilot's job to resolve.** Model routing (31 lines) + orientation rationale (18) + non-goals (10) + notes (5) is ~64 of 267 lines against a 121-line target. If front-loading and prose pruning don't close the gap, the fallback is a `references/pipeline.md` holding the nine steps' detail while the body keeps a step index, the conductor boundary, and the escalation contract. Deciding that on afkkit first — before the same question is answered five more times by guesswork — is precisely why Q8 makes it the pilot.

**Guard rails.** mergekit's never-merge-automatically rule, issuekit's `ready` guard, and afkkit's escalation contract stay in the body, above the halfway mark. This is the Phase 1 carve-out, restated where it gets violated.

### Phase 3 — afkkit: survive the compaction it cannot trigger

The emphasis of this work, and the Phase 2 pilot.

**1. Split and front-load.** Per Phase 2, reordered so the conductor boundary and the escalation contract sit early rather than after the pipeline. If the reference split alone doesn't reach 20,000, take the `references/pipeline.md` fallback above and record which lever actually worked — the answer sets the pattern for the other five.

**2. New body section, `## Surviving a compaction`.** Opens by saying plainly what [What was disproved](#what-was-disproved) established: the conductor cannot compact on demand, no such tool exists, and a long batch *will* auto-compact and replace the conversation with a summary. Then four mechanisms:

- **Run state file — `.afkkit-run.md`** at the worktree root, beside the orientation file and registered in the same private exclude (`git rev-parse --git-path info/exclude`, never a hardcoded `.git/info/exclude`). One appended line per step: issue, step, outcome, payload pointer, worktree path. Appended via a `Bash` redirect. Its lifetime is the worktree's — gitkit tears both down together, which is correct and is half the reason there are two files.
- **Batch state file — `.afkkit-batch.md`** at the repo root, written once at the up-front OK with the approved queue, then one outcome line per terminated issue. It must **outlive** any single worktree, which is the other half of the reason there are two. This is what makes the fixed-queue rule survive a compaction: the snapshot the human approved lives on disk instead of inside a message that gets summarised.
- **Recovery rule.** At every step boundary, if the conductor cannot name from memory the current issue, its worktree path, and the last completed step, it re-reads both files **before doing anything**. It never re-derives state and never restarts a completed step.
- **Re-invoke afkkit at each issue boundary in a batch.** Free when nothing compacted (Claude Code adds an "already loaded" note rather than a second copy), and restores the full body when something did. This is the closest legitimate thing to the `/usage` tip's "compact mid-task".
- **Optional, user-side:** document the `# Compact instructions` block a user can add to their `CLAUDE.md` so summarisation preserves the state-file paths, worktree path, and current step. afkkit describes it; afkkit does not write it.

**3. Frontmatter:**

```yaml
allowed-tools: Bash, Read, Task, Agent, Skill
disallowed-tools: Edit, Write, NotebookEdit
```

The body must say the quiet part out loud rather than implying enforcement: **`Bash` is still allowed, so this is a speed bump on the natural path to editing code, not a sandbox.** What it buys is real — `Edit`/`Write` are how an agent modifies code by reflex, and a heredoc into a source file is not a thing that happens by accident — plus a machine-readable declaration of intent. What it does not buy is a guarantee. `effort` and `model` stay unset: the escalation decision is the one thing afkkit owns, and it is not a cheap call.

**4. No `hooks:` block.** The `PostCompact` marker was considered and dropped — its output reaches the user's display and not the model's context, so its only product is an on-disk marker, and the run ledger already writes one at every step boundary.

### Phase 4 — knobs and the rediscovery fix elsewhere

**Frontmatter, per the Phase 1 table:**

- `effort: low` — **repokit**, **orcakit**.
- `effort: medium` — **commitkit**. A floor, not a cut. Its procedure is already context-aware (it reads `--stat` first and skips generated files), so its 11% is reasoning tokens on volume; but the multi-commit grouping call is genuine judgment and its output is permanent, so it does not go to `low` with the rest of its class. Its model is left to the session — afkkit already routes its own commit subagent to haiku, and a human typing `/commitkit` deserves a decent message.
- `effort: low` + `model: haiku` — **humankit**, a prose edit against a fixed rubric.
- `context: fork` + `background: false`, **no `agent:` line** — **statuskit** only. It is the clean case: zero conversation-history dependence, no `AskUserQuestion`, and git/gh sweeps that have no business in the session context. The `agent: Explore` from the original draft is dropped because Explore has no `Write` and statuskit's snapshot step is a default, not an offer.
- **Explicitly not forked, with a body note recording why:** **researchkit** (declares `AskUserQuestion`; its framing step is where a bad frame poisons the whole document, and it would trip this plan's own new lint check), **commitkit** (a fork destroys its cheapest path), **implementkit**, and every interactive kit.

**The rediscovery fix for implementkit (the 17%)** — no cap on model or effort; a **read-only** orientation contract:

- Rename afkkit's `.afkkit-orientation.md` to the neutral **`.kit-orientation.md`**, so it is a cross-kit artifact rather than one kit's private file.
- **afkkit's spec gate remains the sole writer.** It already owns the `git rev-parse --git-path info/exclude` registration that keeps the file out of the PR diff; no other kit has that machinery, and a public skill that drops an untracked dotfile at an arbitrary repo root is a side effect nobody asked for.
- **implementkit, qakit, reviewkit, prkit** each gain one *read-if-present* line: read `.kit-orientation.md` at the worktree or repo root before exploring, when it exists. qakit's is the highest-value — the measured run had it destroy and rescaffold a build implementkit had produced ten minutes earlier.
- Every mention is conditional and self-contained ("if a file named `.kit-orientation.md` exists at the repo or worktree root…"), so no public skill gains a hard dependency on another kit. Four one-sentence edits and one rename, not five skills restructured.

## Sequencing

Per Q8. The ordering is load-bearing: **Phase 1 cannot ship alone**, because an `E` at 20,000 bytes turns `make lint` red on six skills the moment it lands.

1. **Phase 1**, with the body-size ceiling shipped as `W` at both levels. `AGENTS.md` + `skillkit` + the three lint checks, one commit.
2. **afkkit pilot** — Phase 2's split applied to afkkit only, plus all of Phase 3. Validated end-to-end before anything else moves: `/context` for the body size, a real `/compact` for the re-attachment, one `/afkkit <n>` run for the state files.
3. **Fan out** — one issue per remaining skill (issuekit, wikikit, mergekit, uikit, designkit), each independently revertible, each following whichever lever the pilot proved.
4. **Phase 4** — frontmatter knobs and the orientation contract. Disjoint from Phases 2–3; can run in parallel with the fan-out.
5. **Flip `W` → `E`** at 20,000 as the final commit, once the six are under it.

## Files touched

- `AGENTS.md` — new "Context budget" section; a line in "Documentation artifact naming" covering `references/`.
- `skills/skillkit/SKILL.md` — the rewritten progressive-disclosure rule, inlined (it is `internal: false`). **Same commit as `AGENTS.md`.**
- `scripts/lint.sh` — three checks in `check_skill()`; extend `check_anchors()`.
- `skills/{afkkit,issuekit,wikikit,uikit,mergekit,designkit}/SKILL.md` + new `references/` files under each.
- `skills/{commitkit,repokit,orcakit,humankit,statuskit}/SKILL.md` — frontmatter only. **researchkit is no longer in this list.**
- `skills/{implementkit,qakit,reviewkit,prkit}/SKILL.md` — one read-if-present line each.
- `skills.sh.json` — **no change.** No public skill is added, renamed, or removed.

## Validation

1. `make lint` clean with the three new checks active. Deliberately oversize a scratch copy of a body to confirm the size check fires as an error rather than passing silently.
2. Size census — `for f in skills/*/SKILL.md; do wc -c "$f"; done | sort -rn` — the six target skills under 20,000 bytes; the four known warners still warning and not silently "fixed".
3. `make security` clean.
4. Frontmatter parses — `make link name=afkkit`, start a session, confirm afkkit lists and `/context` shows the smaller body. Repeat for statuskit to confirm `context: fork` genuinely runs it in a subagent, **and that it still writes `docs/status/…`** — the check that catches an accidental `agent: Explore`.
5. Cross-file links — open two moved anchors per split skill in GitHub's renderer, not just in lint.
6. **Compaction behaviour** — in a scratch session, invoke afkkit, drive context up, run `/compact`, and confirm the re-attached body is complete (escalation contract present) rather than truncated at 5k.
7. **afkkit end to end** — `/afkkit <n>` against one `ready` issue in a scratch repo. Confirm `.afkkit-run.md`, `.afkkit-batch.md`, and `.kit-orientation.md` are created, all land in `info/exclude`, and none reaches the PR diff.
8. **Guard survival read** — read each split body end to end as a whole document, not as a diff, and confirm every pre-dispatch guard is still in it. This is the check the lint cannot do.
9. No measurement re-run is planned against the prior plan's frozen baseline; that ledger stays the reference, and this plan's effect is judged on the next `/usage` breakdown rather than a synthetic run.

## Non-goals

- **No `/compact` automation.** Established as unreachable; the plan builds around it rather than faking it.
- **No `/clear` guidance baked into skills.** Clearing between tasks is a user habit, not something a skill can or should do.
- **No re-measurement run.** The prior plan's ledger is the frozen baseline by design.
- **No new skill.** This is a maintenance pass over what exists.
- **No change to afkkit's model routing table.** That was settled by the prior plan on measured evidence and is unaffected by anything here.
- **Not fixing the four known warners** (reviewkit, orcakit, validatekit, gitkit). They warn from day one and stay that way; scope here is the six over the error line.

## Risks

- **Splitting can strand a rule.** A guard moved into `references/` isn't truncated — it's deleted by the next compaction. Mitigated by the Phase 1 carve-out, the Phase 2 guard-rail list, and the whole-document read in validation.
- **afkkit may not reach the ceiling without moving procedure.** Named openly in Phase 2 rather than assumed away; it is the pilot's first real test and the reason afkkit goes first.
- **`context: fork` is a behaviour change, not a tuning knob.** A forked statuskit cannot see what you just discussed. If its dashboard reads worse in practice, drop the fork and keep the split — that is the reversible half.
- **`disallowed-tools` on afkkit is a speed bump, not a sandbox.** `Bash` remains, so nothing prevents a heredoc into a source file. The body must say so; a reader who mistakes it for enforcement is worse off than one who never saw the field.
- **Two conventions, one rule.** `AGENTS.md` and `skillkit` now both carry the split rule, and skillkit's copy must be inline because it is public. They will drift unless changed together — which is why they are pinned to the same commit.

## Hand off

**What changed** — this plan document, hardened by a two-round grill: eight decisions settled (the split rule and its pre-dispatch carve-out, the fork list, lint thresholds, afkkit's state-file shape, the orientation contract's read-only boundary, commitkit's `effort: medium`, uikit's classification, and the pilot-first sequencing), three defects in the draft fixed (`agent: Explore` would have disabled statuskit's snapshot; forking researchkit would have tripped this plan's own new lint check; `skillkit`'s existing rule forbade the split Phase 2 proposed), and the `hooks: PostCompact` option dropped. No skill, script, or convention has been edited.

**Where it landed** — `docs/plans/plan-context-budget-2026-08-07.md`, stamped `Grilled: 2026-08-07`.

**Next** — **issuekit** to file the sequencing above as issues; the stamp means it can file them `ready` rather than `needs-planning`. File them in the Sequencing order, with the afkkit pilot as a hard dependency of the fan-out issues — the pilot decides which lever the other five use, so filing them as parallel-ready would have five agents guessing at a question the pilot exists to answer. Without issuekit, start at Sequencing step 1 by hand: `AGENTS.md` + `skillkit` + the three lint checks, ceiling as `W`.
