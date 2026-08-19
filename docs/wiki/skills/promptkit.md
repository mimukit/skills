# promptkit

Sharpen the prompt before you send it — the one-shot instruction you're about to hand a coding agent, or the system prompt your application ships.

**Reach for it when** the sentence you're about to send is vaguer than the work it's asking for — or when your app's system prompt has never been checked against what it does under a bad input.

| | |
|---|---|
| Modes | [`task`](#task) (default) · [`system`](#system) |
| Tools | `Read`, `Write`, `Edit`, `Grep`, `Glob`, `AskUserQuestion` |
| Writes | nothing in `task`; `docs/prompts/…` in `system`, plus the prompt string on confirmation |
| Visibility | public |

## What it does

Every other skill in this collection starts *after* a prompt has been written. Nothing looks at the sentence you're about to send, and that sentence is the cheapest artifact in the whole workflow — and the highest-leverage one.

A vague instruction doesn't fail loudly. It produces a plausible wrong thing, and the cost lands three steps later in a review pass, a rebuild, and a re-run.

promptkit sharpens the prompt. It **never does the work the prompt describes** — handed "add auth", it writes a prompt about adding auth and does not add auth. That's the load-bearing safety rule and the most likely failure mode, because the model is perfectly capable of just doing the task and will drift toward it.

## Why the split is by artifact, not by effort

Every other kit here names its modes after a verb — `create`, `start`, `audit`, `init`. This one names them after the artifact, and that's deliberate: the two modes' rules genuinely **contradict** each other, so the artifact is the load-bearing signal.

| | `task` | `system` |
|---|---|---|
| Lifespan | ephemeral — one send, then it's dead | durable — runs on every request |
| Context | baked in | arrives through variables |
| Placeholders | **forbidden**, scanned for before delivery | **required** — the variables *are* the interface |
| Instruction files | can lean on them and omit what they cover | there are none at runtime |
| Threat model | none — you wrote it, you're sending it | has to survive input written to break it |

Calling them `quick` and `deep` would imply the same job at two efforts. That's the misread that produces a broken prompt: get the branch wrong and you ship one that fails in exactly the way the other mode guards against.

## Modes

### `task`

**The default.** `system` needs a positive signal that the prompt is durable — it ships in an app, runs every request, holds variables something else fills. Everything else, ambiguity included, runs as `task`. That's a default rather than a question because `task` is what almost every ask is, and because the mode is named in the delivery: a wrong branch costs one word to correct, where asking costs an answer before anything has happened.

The receiver is **an agent with filesystem access in this repo** — a fresh session, a subagent, an unattended run, an issue body. Every rule in this mode is only correct for that receiver.

**Repo grounding is the differentiator**, and the one thing a browser-based prompt optimizer structurally cannot do. Before writing anything, vague references resolve against the real tree: *"the auth file"* becomes `src/lib/session.ts`, *"make sure tests pass"* becomes the repo's actual command discovered from `package.json`, a `Makefile`, `pyproject.toml`, or a `justfile`.

Then the **five-part contract** — goal · file scope · constraints · done signal · stop condition. Five rather than seven, because a checklist nobody completes is worse than a short one they do. The done signal is a concrete check (a command, a test, an observable state), never "when it works".

The output is the prompt in a fenced block **first**, then the ledger. You scroll past nothing to reach the thing you came for. The `SKILL.md` carries a worked run end to end — a four-word bug report becoming a five-part prompt, with the ledger that shows every vague phrase getting a row.

### `system`

**"Codebase-blind" describes the prompt, not the skill.** The prompt this mode produces is codebase-blind *at runtime* — it ships to production and can't reference a repo path. promptkit while authoring reads the calling code freely, and grounding depends on it: the existing prompt, which model, whether tools are attached, whether a schema is already enforced. A prompt that duplicates a schema the API enforces is waste.

Then the **six-part contract** — role and scope · response shape · out-of-scope behavior · missing-input behavior · injection posture · variable contract. The last four are the ones people skip and the ones that cause production incidents, so they're mandatory parts rather than a best-practices list.

And a **must-pass table**: concrete inputs paired with the behavior each must produce, with three failure classes mandatory — missing input, out-of-scope request, injection attempt. No harness, no scoring, no metrics, no A/B versioning. A table you read in ten seconds gets run; a framework you have to wire up doesn't.

## The resolution ledger

Grounding with no gate is a claim, not a mechanism. An agent that reads two files and declares itself grounded emits the same generic prompt every web optimizer emits, while reporting that it didn't.

So the **What changed** block *is* the ledger — every vague reference paired with what it became, and every one that didn't resolve named as unresolved:

```
resolved "the auth file" → src/lib/session.ts
resolved "make sure tests pass" → pnpm test && pnpm typecheck
assumed the change is server-side only — stated in the prompt
could not resolve "the old flow" — left named as unresolved
```

It bites because it's **reader-checkable**: an empty ledger on an obviously vague input is visibly wrong on the page. A minimum-reads quota would be gameable and wrong on a one-file repo; refusing to emit would make the skill a gate you argue with.

An unresolved reference is never a blocker. It stays in the prompt as a visible stated assumption — a stated wrong assumption is correctable, a silent one isn't.

## The no-rewrite verdict

promptkit may return **"this is fine, send it"** with the input unchanged.

This is named as a first-class outcome because the alternative is the failure every rewrite skill has: changing something to justify having been invoked. It's gated on the three mechanical checks the run already performed, not on a feeling — **every contract part present · no placeholder surviving the bracket scan · no catalog entry firing**. Pass all three and the ledger prints what the prompt already had instead of what changed.

Distinct from the **review-only** path, which you ask for. That one returns a diagnosis and no rewrite, and runs inside both modes rather than being a third one.

## The prompt-slop catalog

Folklore that survives in prompts because it once helped on a 2023-era model: role preambles, chain-of-thought bolted onto a reasoning model, ALL-CAPS imperative stacking, bribery and threats, *take a deep breath*, Tree-of-Thought scaffolding in a single-turn prompt, emoji headers, politeness padding.

Every entry carries **the reason it's slop**, not just a ban. The technique may be correct on a different model or a different task, and a rule you understand survives a model generation that a rule you memorized does not.

The cap is **~30 entries, enforced by displacement: adding one means deleting one** — the same mechanism [`uikit`](./uikit.md) uses on its anti-slop catalog.

**The mode filter is load-bearing, not cosmetic.** Each entry is tagged `task`, `system`, or both, and only the running mode's entries fire — because the catalog's most-cited entry *inverts* across the split. *"You are a world-class expert"* is slop in a `task` prompt, where the receiving agent is already configured. It's a **legitimate role line** in a system prompt, where "role and scope" is part one of the contract. An unfiltered list would be wrong about its own headline.

**Measured results beat the catalog.** Report that an entry tested better on your model and it stands down for the run *and gets named in the diagnosis*. This catalog has no maintained external source behind it the way [`humankit`](./humankit.md)'s has Wikipedia's, and its entries are model-generation-specific. A skill that argues with a measurement has become superstition — but deferring *silently* would be as bad, because the record of why this prompt has a role preamble is exactly what a later reader needs.

## The routing note

Handed something upstream-shaped — *"add auth to my app"* is three unsettled decisions, not an instruction — promptkit **still delivers the prompt**, then appends a one-line note naming what would help first.

Bouncing would make it a gate you have to argue with. Silence would hand over a beautiful prompt for work that shouldn't be prompted yet.

**The trigger is unsettled decisions, not size.** The note fires when the goal can't be stated without making a choice you haven't made — which provider, which storage, which of two incompatible shapes. That reuses the ledger already running rather than adding a second mechanism. A scope threshold would fail: a thousand-file mechanical rename is enormous and needs no plan, while *"add auth"* is four words and needs one. A keyword trigger fails the same way — it fires on *"add a test"*.

It's **suppressed when the decisions are already made**: a plan document covering the work means no note, and the prompt points at that plan instead.

## Where the system prompt lands, and why it's written twice

`system` writes `docs/prompts/prompt-<slug>-YYYY-MM-DD.md` by default, because in that mode the artifact *is* the deliverable. What makes `docs/` defensible rather than merely consistent: the file holds the prompt **and its must-pass contract**, which is genuinely a document, not a source constant.

But the doc lives in `docs/`, the running app loads its prompt from somewhere else, and nothing links them — so six weeks on, the file is authoritative-looking and possibly wrong, which is worse than no file. A pointer-plus-stamp would make the drift *visible*, which beats nothing, but the drift still happens and the reader still has two candidate prompts.

So **the drift gets killed at the source**: promptkit writes the prompt into the source file too, under a narrow bound — **the prompt string, in the file that already holds it, on confirmation, in `system` mode only.** No call sites, no imports, no config, no wiring, no behavior.

That moves the safety boundary from *never writes application source* to **never implements the behavior the prompt describes** — which is the line that was actually load-bearing all along; "touches no file under `src/`" was only ever a proxy for it. Writing unprompted on detection isn't a sane default for a prompt-sharpening skill, and a refusal is honored without argument. When it **can't identify** the prompt's home it says so and stops at the doc — no guessed path, no new prompt module.

`task` writes nothing, ever. The artifact is a prompt you're about to paste into the session you're already in, and a file would be a detour on the way to the clipboard.

## Model shape, never model versions

A reasoning-native model wants the goal stated once, with no chain-of-thought scaffolding competing with its own process. A non-reasoning model benefits from explicit structure.

That's written as a **behavioral** test rather than a name test, because the sentence survives a model generation and a list of names does not. Every prompt-optimizer worth reading ships a model-recommendation table, and every one of them is already stale. This skill never ships one.

For the same reason it delivers **one prompt, never one per model family.** A Gemini variant plus an OpenAI variant plus a Claude variant reads as generous and is three artifacts to keep in sync, a decision handed back to you, and a per-vendor style table — the thing that goes stale — dressed as output. Where a vendor convention genuinely applies, it's applied silently inside the single prompt.

`system` infers the shape from the call site it already read; `task` assumes reasoning-native, because every current coding agent is, and spending one of three questions on it buys nothing.

## What it is not

- **Not the task executor.** It writes the prompt, never the code the prompt describes.
- **Not the skill author.** A `SKILL.md` is a prompt, and it belongs to [`skillkit`](./skillkit.md) exclusively — including improving one that already exists. `skillkit` in turn never sharpens a prompt.
- **Not prose editing.** [`humankit`](./humankit.md) has the same shape — a catalog of tells, a rewrite, a review-only path — and the **opposite goal**: it removes structure that reads as machine-made because a human is reading. promptkit *adds* structure because a machine is reading. The exclusion runs both ways now: humankit declines a prompt or a skill file and routes it here, rather than stripping the scaffolding that makes it work.
- **Not a status pass.** [`statuskit`](./statuskit.md) reads project state and crowns one move from a nine-rung ladder. promptkit reads **one sentence**; its note is a footnote on a delivered artifact, never a dashboard.
- **Not the interrogator.** `task` asks at most three questions and never blocks; `system` gets one capture round. Both ask in closed lists with labeled options — answerable as `1b, 2a`, and every list carries an option that hands the call back, because a question with no escape hatch is a block wearing a different hat. Neither is an interview; that's [`grillkit`](./grillkit.md).
- **Not an eval framework.** Must-pass cases are a table you read, not a harness that runs.
- **Not a prompt library.** One prompt for one job, not a catalog of reusable templates.
- **Never unattended.** The deliverable is a prompt a human reads and sends, so it sits outside [`afkkit`](./afkkit.md)'s span for the same reason [`prototypekit`](./prototypekit.md) does.

## Hands off to

`task` hands off to whatever you were about to run anyway: send the prompt. If it's meant to drive a build, the receiver is [`implementkit`](./implementkit.md) — promptkit names it and does not launch it. If the routing note fired, the crowned move is the upstream one instead: [`plankit`](./plankit.md) to draft the decisions, [`grillkit`](./grillkit.md) to settle them.

`system` hands off to running the must-pass table against the live prompt. That's the one move worth crowning, because the table is only worth having if it gets checked once. After that the change is uncommitted, so [`commitkit`](./commitkit.md).

## Install

```sh
npx skills add mimukit/skills -s promptkit
```

Source: [`skills/promptkit/SKILL.md`](../../../skills/promptkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`a3f3769` on 2026-08-19._
