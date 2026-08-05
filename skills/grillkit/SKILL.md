---
name: grillkit
description: >-
  Grill the user relentlessly about any idea, plan, or design — a round of unblocked decisions at a time, each with a recommended answer, until you both share the same picture. Use when the user wants to stress-test or pressure-test an idea, says "grill me", "grill this plan", "poke holes in this", "interrogate my design", or otherwise asks to interrogate a concept before committing to it — a rough idea, a plan file, an architecture, or a PR.
license: MIT
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, AskUserQuestion, Task, Agent, Skill
metadata:
  internal: false
---

# grillkit

Interview the user relentlessly about their idea until the two of you reach a genuinely shared understanding. The subject can be anything — a rough concept, a design in their head, an existing plan file, an architecture, a PR — you don't need a formal plan to grill. Map it as a **design tree**: every decision branches into the decisions that hang off it. Do not start building; the point is to surface every unresolved decision *first*.

## How to grill

- **Open by reflecting the idea back.** Before the first question, restate the subject in your own words — the goal you understand, the shape you're about to grill. This surfaces a misread up front, so you and the user are grilling the same idea rather than diverging silently for ten questions.
- **Work the tree in rounds.** The **frontier** is every decision whose prerequisites are already settled — the questions you can ask *now* without guessing at answers you haven't heard yet. Ask the whole frontier in one round, numbered, then wait for the user's answers before the next round. A question whose answer depends on another question still open in this round belongs to a *later* round, not this one.
- **Each round reshapes the tree.** The answers settle decisions, which pushes the frontier outward and unblocks the questions that depended on them. Recompute the frontier and ask the next round.
- **Always recommend an answer.** For every question, state the option you'd pick and why. A naked question offloads the thinking; a recommendation gives the user something concrete to accept, reject, or refine.
- **Probe the soft spots.** Push hardest on unstated assumptions, hand-waved edge cases, error and failure paths, scope boundaries, and anything described vaguely. If an answer is thin, follow up in the next round rather than letting it stand.

Format every question like so:

```
❓ **Q1** - **<question title>**: <question body, might be multiple paragraphs, including multiple choices>

➡️ <your recommended answer>
```

## Facts are your job, decisions are theirs

Finding *facts* is never the user's job. If something is discoverable by reading the codebase, docs, or config, find it yourself instead of asking — reserve your questions for genuine *decisions*, the judgment calls that are the user's to make.

When a frontier question needs a fact from the environment (filesystem, tools, config) and you have a sub-agent tool, **dispatch a sub-agent to find it — and don't block on it.** A running exploration is just an unsettled prerequisite, so only the questions downstream of it wait for the sub-agent to report; ask the rest of the frontier now. With no sub-agent tool available, look the fact up inline before you put the dependent question to the user.

## When to stop

The grill is done when the frontier is empty — every branch of the design tree visited, nothing left silently assumed. Then hand off, and do not begin implementing until the user explicitly says to proceed.

## What to do with the result

grillkit's job is the shared understanding, not a particular file — but where that understanding lands depends on how the session started:

- **Started from a plan file** — when the input was an existing plan document (e.g. a `plan-<slug>-YYYY-MM-DD.md`), **fold the settled decisions back into that same file by default**, without asking. The user handed you a plan to harden; returning it hardened is the expected outcome. Rewrite that same file in place — don't spawn a parallel copy or change its creation-date suffix — and tell the user you updated it. Only skip or redirect the write if the user explicitly asked for something else (a standalone note, no file, a different location). **Stamp the hardened plan** with a `Grilled: YYYY-MM-DD` line directly under the title (today's date; update it on a re-grill). The stamp is a durable, machine-readable signal that this plan has survived a grill — downstream tooling reads it as provenance: issuekit, for one, only labels a plan's issues `ready` (safe for unattended work) when the source carries this stamp, and files ungrilled plans as `needs-planning` instead. No filesystem? Print the stamp line with the recap for the user to add themselves.
- **Started from anything else** — a rough idea, a design in someone's head, an architecture, a PR — there's no file to return to, so **ask** where the decisions should go: update some existing file in place, write a standalone note in the current directory, or nothing at all. Don't write a file unprompted and don't assume a location; grillkit doesn't own a canonical plan-doc format or a `docs/plans` convention.

If grilling settled a domain term or a hard-to-reverse trade-off decision worth keeping, **domainkit** is the scribe when installed; otherwise note the settled decision for the user to record as a glossary entry or ADR. grillkit does the interrogating rather than owning that format.

## Hand off

Close every grill the same way, naming a sibling skill only when it's installed and otherwise describing the action plainly:

**What changed** — a brief recap of the decisions you settled together, each in a line. Name any question you raised and *didn't* resolve; a decision the user deferred is not a decision, and it will surface again downstream as a blocked build.

**Where it landed** — the plan file you rewrote in place and its `Grilled:` stamp, or the file you were asked to write instead, or nothing at all when the user declined a file.

**Next** — the stamp is the whole point of finishing a grill, so say what it unlocks: a hardened plan is ready to become issues, and **issuekit** reads that stamp to file them as `ready` (safe to work unattended) rather than `needs-planning`. Without a plan file, name what the decisions feed instead — the build itself (**implementkit**), or a decision record (**domainkit**). Don't start either; grilling ends at the shared understanding.
