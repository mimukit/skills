# grillkit

Interrogate any idea, plan, or design — a round of unblocked decisions at a time, each with a recommended answer, until you both share the same picture.

**Reach for it when** you want an idea stress-tested before committing to it. A rough concept, a plan file, an architecture, a PR — you don't need a formal plan to grill.

| | |
|---|---|
| Modes | single procedure, run in rounds |
| Tools | `Bash`, `Read`, `Grep`, `Glob`, `Write`, `Edit`, `AskUserQuestion`, `Task`, `Agent`, `Skill` |
| Writes | folds decisions back into the source plan file, stamped `Grilled: YYYY-MM-DD` |
| Visibility | public |

## What it does

grillkit maps an idea as a **design tree**: every decision branches into the decisions that hang off it. It works that tree in rounds until nothing is left silently assumed.

It does not start building. The point is to surface every unresolved decision *first*.

## The frontier

The mechanic that makes this work is the **frontier** — every decision whose prerequisites are already settled. The questions that can be asked *now*, without guessing at answers not yet heard.

grillkit asks the whole frontier in one numbered round, then waits. A question whose answer depends on another question still open in this round belongs to a *later* round. Each round's answers settle decisions, which pushes the frontier outward and unblocks what depended on them.

It opens by **reflecting the idea back** before the first question — restating the subject in its own words. That surfaces a misread up front, rather than diverging silently for ten questions.

The grill is done when the frontier is empty.

## Always recommend an answer

Every question states the option grillkit would pick, and why. A naked question offloads the thinking; a recommendation gives you something concrete to accept, reject, or refine.

It pushes hardest on unstated assumptions, hand-waved edge cases, error and failure paths, scope boundaries, and anything described vaguely. A thin answer gets followed up next round rather than left standing.

## The shape of a round

A grill is only as good as your ability to answer it fast. Dense paragraphs with choices buried mid-sentence make a good question unanswerable.

```
### Round 2 — 3 open decisions
Blocked behind this round: storage format, migration path.

❓ **Q4 — Where does the doc map live?**
Stakes: `update` needs a code-path → page lookup without reading every page.

- **(a) Per-page colocated metadata** — can't drift, one grep pass, invisible in every renderer
- **(b) YAML frontmatter** — GitHub renders it as a visible table, may collide with an engine's schema
- **(c) Central manifest** — one more file to keep in sync

➡️ **(a)** — as an HTML comment under the visible stamp

---

⏳ **Q6 — Which renderer serves these pages?** — waiting on a sub-agent checking
the repo for a docs generator. It gates the frontmatter decision, so it lands next round.

Reply `4a 5b`, or "go with your picks" to take both.
```

The rules that produce it:

- **Options are a list, never prose.** One per line, always, even for a binary. Options buried in a sentence are the single worst readability offender in a grill — and forcing a two-way choice into list shape surfaces seams you'd otherwise bury.
- **Each option carries its own trade-off.** The reason to reject (b) goes on (b)'s line, so you don't ping-pong up the round.
- **Stakes first, two sentences max** — what breaks or stays undecided downstream.
- **The recommendation is one line.** Point at the letter, then add only what the list couldn't carry: the exact syntax, path, or shape.
- **Number continuously across rounds.** Restarting at Q1 makes "Q2" ambiguous the moment anyone refers back.
- **Code spans are for literals only.** Code-spanning ordinary prose turns the round into rainbow noise and hides the spans that are real references.
- **Show what's pending.** A blocked question is listed with `⏳` and what it's waiting on. A visible branch that goes unasked reads as forgotten.
- **Head the round and close it** — a progress signal, and the reply format.

## The picker mirrors the round

With `AskUserQuestion` available, a round runs **hybrid**: the full text round first — stakes, trade-offs, recommendation — then the tool for the picks alone. You click instead of retyping letters, and the reasoning still gets read.

The widget is a *second view* of the round you just read, not a fresh presentation. Same questions in the same order, same options in the same order. Reorder either and the letters stop meaning anything: you read the case for `(c)`, click the third option, and get something else.

Labels carry their letter (`(a) Per-page metadata`) so correspondence is explicit rather than positional. The recommended option is written into the first slot when the list has no order of its own — one click, no arrow keys — but a spectrum, escalating scope, or a chronology keeps its own order, since scrambling that costs the reader more than the keystroke saves.

The tool caps at 4 questions and 4 options each. A wider frontier means batching calls in round order or falling back to the text round — **never trimming the frontier to fit the widget**.

## Facts are its job, decisions are yours

Anything discoverable by reading the codebase, docs, or config gets found rather than asked about. Questions are reserved for genuine *decisions* — the judgment calls that are yours to make.

When a frontier question needs an environmental fact and a sub-agent tool exists, grillkit **dispatches and doesn't block**. A running exploration is just an unsettled prerequisite: only downstream questions wait, the rest of the frontier gets asked now, and the blocked one shows as `⏳`.

## Where the decisions land

| Started from | What happens |
|---|---|
| **A plan file** | Settled decisions fold back into that same file by default, no asking. Rewritten in place — no parallel copy, no changed date suffix. |
| **Anything else** | No file to return to, so it **asks** where decisions should go. It never writes unprompted and doesn't own a plan-doc format. |

A hardened plan gets stamped `Grilled: YYYY-MM-DD` directly under the title. That stamp is durable, machine-readable provenance: [`issuekit`](./issuekit.md) reads it and only labels a plan's issues `ready` — safe for unattended work — when it's present, filing ungrilled plans as `needs-planning` instead.

The stamp is provenance rather than a tracker artifact, so it's written identically on a project that files no issues at all. There it clears the plan to be built directly instead of clearing it to be filed.

## Hands off to

Whatever the stamp unlocks on this project, because that is the whole point of finishing a grill. Where work is tracked in GitHub Issues, that's [`issuekit`](./issuekit.md): the hardened plan is ready to become issues. Where it's tracked in Linear, a file, or nowhere, the same stamp clears the plan to be built, so it names [`implementkit`](./implementkit.md) and the first phase instead.

It doesn't assume the first case. A project living on GitHub may still run its backlog elsewhere, and the prompt or the repo's agent-guide file is what says which.

Without a plan file, the decisions feed [`implementkit`](./implementkit.md) or a decision record via [`domainkit`](./domainkit.md). Any question raised and *not* resolved gets named — a deferred decision is not a decision, and it resurfaces downstream as a blocked build.

## Install

```sh
npx skills add mimukit/skills -s grillkit
```

Source: [`skills/grillkit/SKILL.md`](../../../skills/grillkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`06848f6` on 2026-08-20._
