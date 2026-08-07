# handoffkit

Compact the current conversation into a handoff document another agent or session can pick up cold.

**Reach for it when** a session is about to end — context running out, work passing to another agent, or you're stopping mid-task and want to resume cleanly tomorrow.

| | |
|---|---|
| Modes | single procedure |
| Tools | `Read`, `Write` |
| Writes | `docs/handoffs/handoff-<slug>-YYYY-MM-DD.md` |
| Triggering | **explicit only** — model invocation is disabled |
| Visibility | public |

## What it does

A conversation accumulates state that exists nowhere else: what you tried and abandoned, why a decision went the way it did, which of three plausible approaches turned out to be wrong. When the session ends, that evaporates. The next agent starts from the code and re-derives it — badly, and at your expense.

handoffkit writes that state down. The point is **transfer, not archival**: it captures the reasoning that only lives in this session and *points* at everything that's already written down elsewhere.

That distinction is the whole design. A handoff that pastes the diff, the spec, and the PR description back in is noise — the next agent can read those. What it can't read is that you already ruled out the obvious approach for a reason that isn't in any commit message.

## Explicit invocation only

Alone among these skills, handoffkit sets `disable-model-invocation: true` in its frontmatter. An agent cannot decide on its own to run it.

That's deliberate. A skill that fires when context gets tight would interrupt work mid-flow to write a document nobody asked for — and it would do so precisely when the session is most loaded and least able to spare the tokens. You invoke it, or it doesn't run.

You can pass a focus argument (`/handoffkit finishing the migration`), which becomes the **goal of the next session**: the document slants toward it, leading with what that goal needs and pruning what it doesn't.

## What goes in, and what stays out

| | |
|---|---|
| **Include** | the goal and why it matters; done vs. still open; the immediate next action; decisions and their reasoning; dead ends already ruled out; gotchas and constraints; how to run and verify |
| **Reference, don't copy** | specs, ADRs, plans, issues, commit messages, diffs, PR descriptions — link by path or URL |
| **Redact** | API keys, tokens, passwords, PII. Refer to them by name ("the staging DB password in `.env`"), never by value |

## The document shape

Eight sections, each dropped rather than padded when genuinely empty:

**Goal** · **Current state** · **Next steps** · **Key files & artifacts** · **Decisions & constraints** · **Open questions / blockers** · **How to run / verify** · **Suggested skills**

The last one names capabilities **by function**, not by tool — "a commit skill to land the work" rather than `commitkit`. The next session may be a different agent in a different environment with none of this collection installed.

## How it works

1. **Reread the session** for the goal, current state, decisions, and loose ends.
2. **Separate carry-over from reference** — does this live only in the chat, or is it already an artifact?
3. **Draft** in the shape above, slanted toward the focus argument if given. A new agent should read it in a minute and act.
4. **Redact** secrets and PII.
5. **Save or print.**

## Where it lands

Writes `docs/handoffs/handoff-<slug>-YYYY-MM-DD.md` by default, using the creation date — which stays fixed if the handoff is later edited. Prints as a code block instead when you explicitly ask for inline output, or when no writable filesystem exists.

## Hands off to

Nothing in the current session, by design. The handoff exists so this context can end. The crowned next move is to start a fresh session pointed at the document, beginning with its own first next-step — which handoffkit names in its report so you don't have to open the file to learn it.

## Install

```sh
npx skills add mimukit/skills -s handoffkit
```

Source: [`skills/handoffkit/SKILL.md`](../../../skills/handoffkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`fd96414` on 2026-08-07._
