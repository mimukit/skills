---
name: ideakit
description: >-
  Think an idea through across many sessions, with one ideas repo holding a folder per idea, a jotpad for the thoughts that have none, and one idea open at a time. Use when the user says "jot this down", "promote that jot", "capture this idea", "let's think about the <X> idea", "where do my ideas stand", "research <X> for this idea", "is the <X> idea worth building", "I'm dropping the <X> idea", or runs "/ideakit".
license: MIT
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Bash, AskUserQuestion, WebSearch, WebFetch
metadata:
  internal: false
---

# ideakit

An idea is a subject someone wants to think about, not a project they have committed to building.

A jot is smaller again: a thought with no folder, no slug, and no commitment. The jotpad takes any subject at any time, and a jot earns a folder by coming back.

Eight modes. [`jot`](modes/jot.md) drops a loose thought into the pad. [`promote`](modes/promote.md) turns a jot that keeps returning into its own idea. [`capture`](modes/capture.md) writes an idea down and stops. [`session`](modes/session.md) is the mode that thinks. [`status`](modes/status.md) reports and writes nothing. [`research`](modes/research.md) and [`validate`](modes/validate.md) send a question out (`validate` through the user, who starts validatekit) and bring the answer back. [`close`](modes/close.md) records a verdict.

**`jot`, `promote`, `capture`, and `close` write on their own. Every other mode offers its writes and takes no for an answer.** See [Saving is a demand, not a default](#saving-is-a-demand-not-a-default).

## Mode selection

Resolve on intent, not on phrasing.

- A loose thought to record → `jot`. It records and stops.
- A jot that should get its own folder → `promote`.
- A new idea to write down, or an ask that says "capture this" or "write this down" → `capture`. It records and stops.
- Thinking about one idea → `session`.
- Where ideas stand, or what to think about next → `status`.
- An external fact the idea needs (a tool, a library, a market, a cost) → `research`.
- Whether the idea is worth building or would sell, including "would anyone pay for this" → `validate`.
- A verdict: drop, build, or park → `close`.

**An ask that wants a picture or wants to think, but names no idea, is `status` or `session`, never a guess between them.** `status` reports every idea; `session` asks which one to open. When the ask wants a picture, run `status`. When the ask wants to think, run `session` and ask for the idea.

**An explicit phrase in the list above beats every tie-break below.** "capture this" runs `capture` even when the text reads as a loose thought and never says "idea".

When the ask is ambiguous between `capture` and `session`, run `capture` first.

**When the ask is ambiguous between `capture` and `jot`, run `jot`.** The word "idea" is the discriminator: a user who calls the thought an idea gets `capture`.

## The ideas repo

All state lives in one repo outside the user's work repos, at `~/ideas` unless `$IDEAKIT_HOME` names somewhere else.

```
~/ideas/                            ← one git repo; $IDEAKIT_HOME overrides
  INDEX.md                          ← the router
  jotpad/
    INDEX.md                        ← the jot router
    YYYY-MM-DD.md                   ← that day's jots, append-only
  topics/<slug>/
    IDEA.md                         ← a stable head plus an ## Open block
    NOTES.md                        ← the dated log, append-only
    SOURCES.md                      ← collected links, created lazily
    docs/plans/                     ← a plan skill writes here
    docs/research/                  ← research answers, kept on request
    docs/validation/                ← validation write-ups, kept on request
    docs/sessions/                  ← full session records, on request only
    docs/adr/                       ← decision records
    assets/                         ← diagrams and screenshots
```

**Resolve `$IDEAKIT_HOME` first and write absolute paths.** No mode changes the working directory. A mode fired from a work repo touches no file in that repo, so the host repo's own conventions never apply to what ideakit writes.

Create the repo on first use and run `git init` in it. **Never commit automatically.** Offer a commit at the end of a run that wrote a file, and take no for an answer.

### The router

`INDEX.md` carries one row per idea, with aliases, so a loose ask routes without opening anything:

```markdown
| Idea | Slug | Also called | Summary | Open question | Status | Last touched |
|------|------|-------------|---------|---------------|--------|--------------|
| Agent memory substrate | `agent-memory` | memory layer, agent recall, context store | A shared store an agent writes facts to and reads back across sessions | Does retrieval beat a bigger window | active | 2026-08-19 |
```

Status is `active`, `building`, `parked`, or `closed`. `building` means implementation runs in another repo, and its cell carries that repo: `` `building` · owner/repo ``. `parked` means the user stopped. `closed` means a verdict is written in that idea's `NOTES.md`.

**The router cell bound: `Summary` and `Open question` are one line each.** Each states *what* the idea is and *what* is open. Neither carries a reason, a position, or a half-formed argument. A Markdown table gets read whole, so this bound is what keeps the isolation guard below.

### Read one idea folder, never two

**The isolation guard beats every other rule here.** Read `INDEX.md`. Resolve the ask to exactly one slug. Then read only `topics/<slug>/`. Never glob across `topics/`, and never grep the repo for context. Listing `topics/` is fine, because listing a directory is not reading it.

Ideas contaminate each other: the second idea in the window inherits the first one's framing without anyone noticing. `status` reports on every idea and opens none of them.

**One bounded exception.** Open a second topic folder only when the user names that idea in the ask ("does this connect to the agent memory idea?"). That folder is **read-only** for the session, and the connection is written into the primary idea's `NOTES.md` alone. One session, one owner of the log. When a link looks obvious and the user has not asked, say the link in one sentence and leave the folder shut.

**The rule holds across the pad in both directions.** A topic mode opens no file under `jotpad/`, and a jotpad mode opens no folder under `topics/`. See [The jotpad](#the-jotpad) for how a jot session bounds its own reads, and [`promote`](modes/promote.md) for the one mode that touches both.

### The three topic files

**`IDEA.md` is the living statement, in two parts.** The head says what the idea is, who it is for, and what has to be true for it to matter. An `## Open` block below it lists the open questions and the possible next moves.

Rewrite the head when a session changed what the idea *is*. Draft a refreshed `## Open` block every session without exception, and save it with the entry it matches. That split gives a checkable bound: **the `## Open` block matches the last `NOTES.md` entry.**

**`NOTES.md` is the log, and it is append-only.** One `## YYYY-MM-DD` heading per saved session, recording what was decided, what was rejected and why, and the open question the session stopped on. Leave earlier entries alone; a change of mind gets a new dated entry. The log is the record and `IDEA.md` is a cache of it, so rewrite `IDEA.md` from `NOTES.md` when the two disagree.

**`SOURCES.md` collects links**, one row per link with the date read and one line on what it settles. Create it on first use, not at capture. Check it before searching.

### The jotpad

**`jotpad/` holds a thought that has no folder.** Any subject, no slug, no commitment.

`jotpad/INDEX.md` is the jot router, one row per jot:

```markdown
| Jot | Id | Summary | Entries | State |
|-----|----|---------|---------|-------|
| Cheap OCR for receipts | `j-042` | A phone photo of a receipt turned into a line-item table, run locally | 2026-08-24, 2026-09-02 | live |
```

State is `live`, `promoted`, or `dropped`. A `promoted` cell carries the slug it became: `` `promoted` · `agent-memory` ``. A `dropped` row stays, so the same thought does not come back as a new jot. **The `Summary` cell is one line and carries the same bound as the idea router**, because this table also gets read whole.

`jotpad/YYYY-MM-DD.md` holds that day's jots, one block each:

```markdown
## j-042 · Cheap OCR for receipts

Two to six lines in the user's own words: what the thought is, and what set it off.
```

**A dated file is append-only, like `NOTES.md`.** A block, once written, is never edited, and new blocks go only into today's file. Every state change lands in `jotpad/INDEX.md` instead.

**An id is permanent and never reused.** Allocate it by taking the highest id in `jotpad/INDEX.md` or in today's file, whichever is higher, and adding one. Reading today's file too keeps a block whose row never got written from losing its id to the next jot. A jot the user returns to on a later day gets a new block under the same id in that day's file, and its row gains that date. A return on the same day appends a second block under the same id in today's file and leaves the `Entries` cell alone, because the cell counts days. **Three entries is the promotion signal.**

**Dropping a jot is a one-cell edit.** When the user says a jot is nothing, set its state to `dropped` and write nothing else. It needs no mode and no verdict entry.

**The isolation guard covers the pad.** A `jot` run reads `jotpad/INDEX.md` and `INDEX.md`, both bounded routers, plus today's dated file, which it appends to. A jot discussion reads those plus only the dated files that one jot's row names. [`promote`](modes/promote.md) reads one jot and writes one topic folder.

### The router is a cache, so repair it

Repair runs at two levels, and each mode repairs only what it can see.

- **Offer a topic's router row rewrite whenever a mode has that folder open and changed it**, in the same save offer as the entry that changed it. `capture` and `close` write their row without asking.
- **Report an unregistered folder rather than opening it.** `status` names the folder and says to run `session` on it to register it.
- **Repair the jot router without asking.** Write a jot's row whenever a mode changes that jot's state.

### Recover a partial write

Every multi-file write runs in a fixed order: the record first, then the caches. In a topic folder that is `NOTES.md`, then `IDEA.md`, then the router row. In the pad it is the dated block, then the jot router row. A run that stops midway leaves the record ahead of its caches, and each case has one repair:

- **`IDEA.md` disagrees with the last `NOTES.md` entry.** The next mode that opens the folder offers the rewrite from the log, in its own save offer.
- **A topic folder has no router row**, the trace of a `capture` or `promote` that stopped early. `status` reports it as unregistered, and `session` on it writes the row.
- **A block in today's file has no jot router row.** The next `jot` run sees the id in today's file and writes the missing row without asking, as for any jot router repair.

### The slug is permanent

A slug is short, lowercase, kebab-case, and taken from the idea's core noun. **`capture` proposes it and confirms it with the user before creating anything**, because no mode renames a folder afterwards. The router's `Idea` column carries the current human name and stays free to change.

### Artifacts land inside the topic folder

**The artifact root is the topic folder, not the repo root.** A skill that documents a path under `docs/` writes it under `topics/<slug>/docs/` instead, keeping its own subpath and filename convention intact. `docs/plans/0001-plan-sso-2026-07-23.md` becomes `topics/<slug>/docs/plans/0001-plan-sso-2026-07-23.md`.

The swap holds for every skill. The repo root has no `docs/` directory and does not gain one.

Filenames follow `NNNN-<type>-<slug>-YYYY-MM-DD.md`, with a four-digit serial in front and the artifact's creation date at the end. The serial counts per directory inside the topic folder: take the highest leading serial in that directory across this worktree, every other worktree that `git worktree list` names, and `origin/<default branch>` when the topic folder is in a git repo, and add one, starting at `0001`. Scan all three, because parallel worktrees otherwise take the same serial. Skip a source that fails, such as no remote, and without git list the directory only. Keep the whole name stable when the file is edited later.

## Saving is a demand, not a default

**The discussion is the deliverable. A file is what the user asks for when the discussion earned one.** Every write runs through one gate:

1. **Compose the write anyway.** Draft the `NOTES.md` entry, the `## Open` block, and the router row in full.
2. **Print the draft as a code block, under the absolute path it would land at.**
3. **Ask save, edit, or drop.** Take a no for an answer, and write nothing.

**The gate covers every file, the router row included.** An unsaved session leaves `Last touched` where it was.

**`jot`, `promote`, `capture`, and `close` are exempt, because in each the ask is the write.** There are no other exemptions. `promote` still confirms the slug before it creates anything.

**The user can say "save that" at any point.** Write the entry then, and carry on. Offer a save unprompted only once mid-session, when the discussion settles something that would cost real work to reconstruct.

## The modes

The mode bodies live in one file each under `modes/`. Route with [Mode selection](#mode-selection), read that one file, and follow it. Everything above this line, and the shared sections below, apply to every mode and are not restated in the mode files.

- Mode `jot` → read [modes/jot.md](modes/jot.md), then follow it.
- Mode `promote` → read [modes/promote.md](modes/promote.md), then follow it.
- Mode `capture` → read [modes/capture.md](modes/capture.md), then follow it.
- Mode `session` → read [modes/session.md](modes/session.md), then follow it.
- Mode `status` → read [modes/status.md](modes/status.md), then follow it.
- Mode `research` → read [modes/research.md](modes/research.md), then follow it.
- Mode `validate` → read [modes/validate.md](modes/validate.md), then follow it.
- Mode `close` → read [modes/close.md](modes/close.md), then follow it.

## The dispatch contract

`research` sends its question to a sibling skill. `validate` cannot, because validatekit is invocation-only, so the user runs it and brings the answer back; the rules below govern that answer the same way. Four rules govern every dispatch:

- **Let the sibling answer inline.** researchkit and validatekit both default to answering in the conversation and saving nothing. Do not answer their save prompt on the user's behalf.
- **Suppress the sibling's hand-off and print ideakit's own.**
- **Offer the artifact after the answer, never before.** Ask once whether to keep it. On a yes, write the file yourself from the sibling's inline answer, at `topics/<slug>/docs/…`, keeping the sibling's own subpath and filename convention. Re-running the sibling to save would land the file in the working directory, because a sibling skill documents its own root and defers to no host.
- **Fold back only what gets saved.** On a yes, offer the dated `NOTES.md` entry naming the question, the answer, and the artifact path, together with the `IDEA.md` and router updates. On a no, the answer stays in the conversation and the log stays as it was.

## Hand off

_Write this section in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

**What changed.** Name the entry written, the artifact saved, and the status set. Name what did not change too: a save the user declined, a folder you reported and did not open, a dispatch that ran the short version, a verdict you refused to write without a reason.

**Say when a run wrote nothing.** State it in one line: this session leaves no record in the repo. Do not soften it, and do not imply the discussion was saved. Offer the save once more only if the user asks.

**Where it landed.** Give the topic folder path. Give the jot file path and the jot id when a mode wrote a jot. Give the artifact path when a mode wrote one. Give the repo path when this run created the repo.

**Next.** Crown one move, chosen by state:

Take the first rule that matches, top to bottom.

- The run gave a `live` jot its third entry or a later one → run `promote` on that jot.
- The run wrote any other jot → say there is no next step. Do not offer a session on it.
- The jot just became an idea → run `session` on the new slug.
- The session stopped on an open question → run `session` again on that question.
- The open question needs an external fact → run `research`.
- The idea is a business with no verdict → run `validate`.
- The idea is settled enough to shape work → plan it in the project repo, with a plan skill (**plankit** when installed).
- Nothing is open → run `close`, and name which verdict fits.
- The idea just closed → say there is no next step. Do not invent a follow-up.
- The run was `validate` and the user chose to run validatekit → run `/validatekit` with the idea path, then ask ideakit to keep the verdict.

Then offer a commit of the ideas repo. Never run it without a yes. **Skip the commit offer on a run that wrote nothing.**

**A `status` run closes differently.** Its whole output is a hand-off, and the dashboard already crowns the move. State that nothing changed. Do not print the move twice, and do not offer a commit.

## Notes

- **This repo ships no code.** ideakit never writes application code and never opens issues.
- No writable filesystem (a browser-based agent)? The save offer becomes a print. Say so plainly, print the `NOTES.md` entry and any artifact as code blocks for the user to save, and give the paths they belong at. Do not report a write that did not happen. `status` still runs when the filesystem is readable.
