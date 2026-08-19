# ideakit

Think an idea through across many sessions — one ideas repo with a folder per idea, one idea open at a time, and every research or validation answer folded back into that idea's own log.

**Reach for it when** an idea arrives at the wrong moment and you have nowhere to put it, or when you sit down to think about one you started weeks ago and can't remember where you stopped.

| | |
|---|---|
| Modes | [`capture`](#capture) · [`session`](#session) · [`recap`](#recap) · [`research`](#research) · [`validate`](#validate) · [`close`](#close) |
| Tools | `Read`, `Write`, `Edit`, `Glob`, `Bash`, `AskUserQuestion`, `WebSearch`, `WebFetch` |
| Writes | an ideas repo at `~/ideas` (`$IDEAKIT_HOME` overrides) — Markdown only; nothing in `recap` |
| Visibility | public |

## What it does

An idea is a subject you want to think about, not a project you've committed to building. That distinction is the whole design. Most of what lands in an ideas repo stays notes, and a tool that treats every entry as a prospective product turns thinking into a backlog you feel guilty about.

So ideakit does four things and refuses the fifth. It writes an idea down the moment it arrives, runs the discussion sessions, reports where everything stands, and sends the research and validation work out to the skills that own those postures. It never writes application code, never opens issues, and never moves an idea's folder anywhere.

## Why a repo and a skill, not just a repo

`~/ideas` started as a plain repo with an `AGENTS.md` full of rules. That covers one case well and leaves three gaps.

An `AGENTS.md` loads only when the working directory *is* that repo. An idea that arrives while you're deep in a work repo has nowhere to go — the exact moment capture matters most.

A conventions file describes a procedure; it doesn't perform one. "Capture an idea" is six ordered steps with a confirmation in the middle, and prose in a repo root doesn't run them.

And a repo can't dispatch. Sending a question to a research skill and getting the answer back into the idea's own log needs something that knows both ends.

The `AGENTS.md` still exists, cut to about ten lines. It carries the isolation guard and the path rule, so both hold in a session where the skill never fires. Everything else moved into the skill, which is where the no-duplication seam falls: the file states the rule, the skill owns the derivation.

## Why the router carries labels and not thinking

`INDEX.md` is the router — one row per idea, with slug, aliases, a one-line summary, the open question, status, and last-touched date.

The summary and open-question columns are what make [`recap`](#recap) possible without opening a single folder. They're also the obvious place for the guard to leak, and the tempting fix — "read the row selectively" — is a fiction. A Markdown table gets read whole. You can't put a paragraph of reasoning about idea B in a file that every session on idea A reads top to bottom, then claim the reasoning didn't land in context.

So the guard is kept by bounding what the router is *allowed* to hold. Both cells are capped at one line, and each states what the idea is and what is open — never why, never a position, never a half-formed argument. Ten ideas cost ten lines to route and nothing to contaminate.

## Why one folder per session

Ideas contaminate each other in a way facts don't. Half-formed thinking about one subject bleeds into the next when both sit in the same window, and the second idea inherits the first one's framing without either party noticing. You get a session that sounds productive and quietly reasoned about the wrong thing.

The cost curve points the same direction. Thirty ideas cost about thirty router lines to route and tens of thousands of tokens to open. A skill whose whole purpose is to accumulate ideas cannot get worse as it accumulates them.

There is one exception, and it's bounded on both sides. When you name a second idea and ask for the connection, that folder opens **read-only**, and the connection gets written into the primary idea's `NOTES.md` alone. One session, one owner of the log. The cost is real and accepted: the second idea's log never learns it was cited.

## Why `IDEA.md` splits in two

The log is the record; `IDEA.md` is a cache of it. That leaves the question of when to refresh the cache, and "rewrite it when the idea changed" is not something an agent can check itself against — it ends when the agent feels finished, which is where run-to-run variance comes from.

Splitting the file fixes that. A stable **head** says what the idea is, who it's for, and what has to be true for it to matter; it gets rewritten only when a session changed what the idea *is*. An **`## Open` block** below it gets refreshed every session, no exceptions, and its bound is checkable: the block matches the last `NOTES.md` entry.

The split earns its keep in the other direction too. An inconclusive session — and plenty of them are — refreshes the block and leaves the head alone, instead of churning the whole file to say nothing changed.

## Modes

### `capture`

Writes the idea down and stops. That full stop is the feature. Capture matters most when an idea arrives at a bad moment, and a mode that answers "I just had an idea" with a brainstorming session is how the idea gets dropped instead of recorded.

It reads the router and nothing else, matching the ask against every slug, alias, and summary. **When anything is close it shows the candidate row and asks** whether this belongs on that idea or starts a new one. Two folders for one idea splits the log, and the isolation guard means a later session opens one of them with nothing signalling the other exists.

On a new idea it **proposes a slug and confirms it before writing anything**, because no mode renames a folder afterwards. That was a deliberate trade against a rename step: the cost lands once, at creation, rather than in machinery maintained for a rare event. The router's `Idea` column carries the human-readable name and stays free to change.

When it fires from a work repo, the first log entry records which repo. Where an idea arrived from is usually part of the idea.

### `session`

The mode that thinks, and the only one that discusses.

**Its posture is state the strongest version, then name what would kill it.** Building the case first isn't politeness — an idea argued down before it's stated properly never gets a fair test. The kill condition comes after, and it's the thing that gets recorded as the open question.

There's an escape: say you're thinking out loud and the stress pass is skipped. The kill condition still reaches the log either way, so an expansive night costs the record nothing.

**Every session appends to `NOTES.md`**, three to six lines at minimum. Making that optional is what empties an ideas repo — and it costs the isolation guard its payload, since the whole point of reading one folder is that the folder holds the thread.

With no idea named it **asks** rather than guessing, offering recent ideas plus "a new idea". It never falls through to `recap`; a session is a different transaction from a report, and silently swapping one for the other is worse than one question.

### `recap`

Reports and writes nothing but a router repair. It has two scopes, which is why there's no separate `list` mode — the difference between "where do all my ideas stand" and "where does this one stand" is an argument, not a posture.

**Cross-idea, it opens no topic folder at all**, getting everything from the router and a directory listing. Then it crowns one move, and the ranking rule is the interesting part: **the crown goes to the coldest active idea carrying an open question, not the warmest.**

Ranking on recency was the first draft, and it produced a crown that just restated row one of a table already sorted by recency. Inverting it makes the crown carry information. Cold plus an open question means you stopped mid-thought, which is the recoverable case; cold with nothing open means you drifted off, which isn't. And it's precisely the row a recency sort buries.

There's no stale marker. A tag most rows would wear within a year is a verdict on a repo whose entire premise is that ideas sit. It prints the age instead — `untouched 94 days` — and lets you judge.

**Its cache repair is detect-only**, which is the one place the guard and the self-heal genuinely conflict. Writing a router row needs five fields that all live inside the folder, so repairing an unregistered folder means opening it — for bookkeeping. So `recap` names the folder, says to run `session` on it, and stops. The modes that already have a folder open repair their own row.

### `research`

Classifies before it acts, because "research" covers three different asks with three different owners.

A tool, library, framework, or architecture decision goes to [`researchkit`](./researchkit.md). A build-or-drop question isn't research at all and gets redirected to [`validate`](#validate). A market, competitor, category, or customer-signal question has no owner among the kits, so ideakit runs that one itself — who else does this, what the category is called, how incumbents price it, what users publicly complain about, each with a source and a date.

### `validate`

Hands a startup or SaaS idea to [`validatekit`](./validatekit.md) and folds the verdict, the wedge, and the assignment back into the log.

It **honors validatekit's side-project off-ramp** rather than routing around it. That off-ramp fires often here, because most ideas in a personal ideas repo are not businesses, and "this is a side project, not a company" is a real answer worth writing down rather than an obstacle to a verdict.

### `close`

Records a verdict: `building`, `parked`, or `closed`. The reason is required, and the mode refuses to write a verdict without one — a status flip with no reason is a row edit pretending to be a decision.

**A closed idea keeps its folder.** Nothing is deleted, moved, or migrated. An idea you decide to build gets implemented in a separate project repo, and the folder stays here for the next thought about the same subject. Ideas outlive the projects they spawn, and the archive-on-success design loses exactly the folder you'd want when you revisit the subject in a year.

It was called `archive` first. The status flip is a one-line edit; the substance is the written verdict, and `close` names that.

## Why the dispatch is owned end to end

Both dispatch modes drive the sibling skill rather than suggesting it, and there are three concrete reasons — each one a thing that breaks otherwise.

The sibling writes to the wrong root. [`validatekit`](./validatekit.md) documents `docs/validation/` with no deference to a host convention, so left alone it writes into whatever directory you're standing in. ideakit passes the absolute path under `topics/<slug>/docs/`.

The sibling writes nothing by default. Both [`researchkit`](./researchkit.md) and validatekit answer inline and offer a file only if asked, which is right for their normal use and wrong here, because the fold-back needs an artifact to point at.

And two hand-offs help nobody. The dispatch is a sub-step, so the sibling's next-move line is suppressed and ideakit prints its own.

Then the answer goes into the idea's own `NOTES.md` as a dated entry naming the question, the answer, and the file. That fold-back is what keeps one thread authoritative — a later session reads one log and finds every answer, instead of reconstructing them from a directory of artifacts.

## What it is not

- **Not an implementation tool.** No code ships from the ideas repo; that's [`implementkit`](./implementkit.md) in a project repo.
- **Not a task tracker.** An idea is not a ticket. Real work moves to a project repo and gets issues there with [`issuekit`](./issuekit.md).
- **Not a scheduler.** No due dates, no review queue, no spaced retrieval. That's [`tutorkit`](./tutorkit.md) on a different repo with a different premise.
- **Not a theme sweep.** No mode reads every idea looking for connections; that breaks the guard wholesale for something rarely wanted.
- **Not a replacement for the kits it calls.** Its fallbacks without them are short and say so.
- **It never commits the ideas repo on its own.**

## Hands off to

Mostly to itself, chosen by state: another `session` on the question you stopped at, `research` when the block is an external fact, `validate` when the idea is a business with no verdict, `close` when nothing is open. [`recap`](#recap) is that routing rule made available on demand.

It leaves the repo when an idea is settled enough to shape work. Then the next move is [`plankit`](./plankit.md) in the project repo, not here — and the idea's folder stays put either way.

It shares a shape with [`tutorkit`](./tutorkit.md) and nothing else. Both keep one repo, one folder per subject, a router with aliases, and a hard one-folder-per-session guard. But tutorkit teaches a subject somebody already settled, on a schedule; ideakit thinks about one nobody has settled, on no schedule at all.

## Install

```sh
npx skills add mimukit/skills -s ideakit
```

Source: [`skills/ideakit/SKILL.md`](../../../skills/ideakit/SKILL.md)

_Verified against `main`@`86f5eb3` on 2026-08-20._
