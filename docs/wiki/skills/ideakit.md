# ideakit

Think an idea through across many sessions: one ideas repo with a folder per idea, a jotpad for the thoughts that have none, one idea open at a time, and nothing written to disk until you ask for it.

**Reach for it when** an idea arrives at the wrong moment and you have nowhere to put it, when a stray thought is too small to deserve a folder, or when you sit down to think about one you started weeks ago and can't remember where you stopped.

| | |
|---|---|
| Modes | [`jot`](#jot) · [`promote`](#promote) · [`capture`](#capture) · [`session`](#session) · [`status`](#status) · [`research`](#research) · [`validate`](#validate) · [`close`](#close) |
| Tools | `Read`, `Write`, `Edit`, `Glob`, `Bash`, `AskUserQuestion`, `WebSearch`, `WebFetch` |
| Writes | an ideas repo at `~/ideas` (`$IDEAKIT_HOME` overrides), Markdown only. `jot`, `promote`, `capture`, and `close` write; `session`, `research`, and `validate` write only on your yes; `status` never writes |
| Visibility | public |

## What it does

An idea is a subject you want to think about, not a project you've committed to building. That distinction is the whole design. Most of what lands in an ideas repo stays notes, and a tool that treats every entry as a prospective product turns thinking into a backlog you feel guilty about.

So ideakit does four things and refuses the fifth. It writes an idea down the moment it arrives, runs the discussion sessions, reports where everything stands, and sends the research and validation work out to the skills that own those postures. It never writes application code, never opens issues, and never moves an idea's folder anywhere.

Below the folders sits the jotpad, which takes the thoughts that aren't ideas yet. A jot has no folder, no slug, and no subject requirement, and it becomes an idea only by being one you keep coming back to.

## Why a repo and a skill, not just a repo

`~/ideas` started as a plain repo with an `AGENTS.md` full of rules. That covers one case well and leaves three gaps.

An `AGENTS.md` loads only when the working directory *is* that repo. An idea that arrives while you're deep in a work repo has nowhere to go — the exact moment capture matters most.

A conventions file describes a procedure; it doesn't perform one. "Capture an idea" is six ordered steps with a confirmation in the middle, and prose in a repo root doesn't run them.

And a repo can't dispatch. Sending a question to a research skill and getting the answer back into the idea's own log needs something that knows both ends.

The `AGENTS.md` still exists, cut to about ten lines. It carries the isolation guard and the path rule, so both hold in a session where the skill never fires. Everything else moved into the skill, which is where the no-duplication seam falls: the file states the rule, the skill owns the derivation.

## Why saving is something you ask for

The first version wrote on every mode. A session always appended to `NOTES.md`, a research run always saved its artifact, and the reasoning was that an optional write empties the repo.

That reasoning holds for the sessions worth keeping and gets the common case backwards. Most nights you open an idea, push it around for twenty minutes, and land nowhere in particular. Recording that produces a log of entries you never meant to write, and the cost is not disk. It is that [`status`](#status) reads every row as something you decided, so a repo padded with exploratory noise gives worse answers than a thin one.

So the gate inverted. The discussion is the deliverable, and a file is what you ask for when the discussion earned one. The mechanism matters more than the rule: the agent **composes the entry anyway**, prints it under the path it would land at, and then asks. An offer with the draft attached is nearly free to accept. An offer that asks "want me to save this?" with nothing to look at gets declined because judging it costs more than skipping it.

Two modes are exempt, and they are exempt for the same reason. `capture` and `close` have the file as their entire output, so the ask you made is the write. Prompting there asks you to confirm what you just requested.

The router row goes through the gate with everything else, rather than repairing itself quietly. `INDEX.md` carries a summary and an open question, which are thinking and not bookkeeping, so the row travels with the entry that changed it. A session you didn't save didn't touch the idea, and `Last touched` should say so.

The cost is real and the skill states it rather than hiding it. `session` opens on a status report, `status` crowns the coldest idea with an open question, and both read the log. Sessions you decline to save leave those reads behind what you actually think. What holds it is the hand-off: every run that writes nothing says so in one line, so a thin log never passes for a quiet month.

## Why the router carries labels and not thinking

`INDEX.md` is the router — one row per idea, with slug, aliases, a one-line summary, the open question, status, and last-touched date.

The summary and open-question columns are what make [`status`](#status) possible without opening a single folder. They're also the obvious place for the guard to leak, and the tempting fix — "read the row selectively" — is a fiction. A Markdown table gets read whole. You can't put a paragraph of reasoning about idea B in a file that every session on idea A reads top to bottom, then claim the reasoning didn't land in context.

So the guard is kept by bounding what the router is *allowed* to hold. Both cells are capped at one line, and each states what the idea is and what is open — never why, never a position, never a half-formed argument. Ten ideas cost ten lines to route and nothing to contaminate.

## Why one folder per session

Ideas contaminate each other in a way facts don't. Half-formed thinking about one subject bleeds into the next when both sit in the same window, and the second idea inherits the first one's framing without either party noticing. You get a session that sounds productive and quietly reasoned about the wrong thing.

The cost curve points the same direction. Thirty ideas cost about thirty router lines to route and tens of thousands of tokens to open. A skill whose whole purpose is to accumulate ideas cannot get worse as it accumulates them.

There is one exception, and it's bounded on both sides. When you name a second idea and ask for the connection, that folder opens **read-only**, and the connection gets written into the primary idea's `NOTES.md` alone. One session, one owner of the log. The cost is real and accepted: the second idea's log never learns it was cited.

## Why there's a pad under the folders

A folder is a commitment. It costs a permanent slug, an `IDEA.md`, a log, and a row in a router you read every time you sit down. That price is right for a subject you mean to think about for months and wrong for a thought you had while making tea. Charge it on every thought and one of two things happens: you stop writing them down, or the router fills with rows you would never choose to open.

The jotpad charges nothing. Say "jot this down" and the thought lands as a block in that day's file with an id and a one-line row. No subject requirement, no relevance test against the ideas you already have, no naming decision on the night it arrives.

What makes it more than a scratch file is that promotion is earned rather than judged. A jot you come back to gets another block under the same id, and the router's `Entries` cell counts the returns. At three, [`status`](#status) crowns `promote` on it. So you never decide on the first night whether a thought deserves a folder. Coming back twice is the decision, and your own behaviour makes it instead of a guess.

Both costs are stated rather than hidden. A dated file holds unrelated jots side by side, so reading one thread carries its neighbours into the window. That is exactly the contamination the [one-folder guard](#why-one-folder-per-session) exists to stop, and it is accepted here because the pad holds loose thoughts by construction and `promote` is the way out of it. The second cost is that a block is never edited after the day it lands. Every state change goes to the router instead, which is what keeps a thought's arrival date true and why a promoted jot leaves its text where it was.

## Why `IDEA.md` splits in two

The log is the record; `IDEA.md` is a cache of it. That leaves the question of when to refresh the cache, and "rewrite it when the idea changed" is not something an agent can check itself against — it ends when the agent feels finished, which is where run-to-run variance comes from.

Splitting the file fixes that. A stable **head** says what the idea is, who it's for, and what has to be true for it to matter; it gets rewritten only when a session changed what the idea *is*. An **`## Open` block** below it gets redrafted every session, no exceptions, and travels with the log entry in the same save offer. Its bound is checkable: the block matches the last `NOTES.md` entry.

The split earns its keep in the other direction too. An inconclusive session — and plenty of them are — refreshes the block and leaves the head alone, instead of churning the whole file to say nothing changed.

## Modes

### `jot`

Records a loose thought and stops. It proposes no slug, creates no folder, and does not ask what the thought is for.

It reads the two routers and nothing else: the jot router, to see whether this is a thought you have had before, and the idea router, because that table is bounded and cheap to check. **When the thought plainly belongs to an idea you already have, it says so in one line and writes the jot anyway.** Routing on the way in is the friction the pad exists to remove, and [`promote`](#promote) can move it later without losing anything.

A jot that matches one you already have gets a fresh block under the same id, and its row gains today's date. That accumulation is the whole promotion signal.

### `promote`

Turns a jot into an idea. It is [`capture`](#capture) with a source, and the only mode that reads the pad and writes a topic folder.

It runs capture's match step against the idea router first, so a jot about something you already track appends to that idea rather than starting a rival folder. On a new idea it confirms the slug before creating anything, for the same reason capture does.

**The jot's text stays in the pad.** Its row flips to `promoted` with the slug it became, and nothing is cut out of any dated file. Moving the text would tidy the pad and destroy the record of when the thought first arrived, which is the one thing the pad knows that the folder cannot reconstruct. The new folder's first log entry names the jot id and that original date instead.

The reverse case needs no mode at all. A jot that turns out to be nothing gets state `dropped`, a single cell edit, and the row stays so the same thought does not come back as a new jot next month.

### `capture`

Writes the idea down and stops. That full stop is the feature. Capture matters most when an idea arrives at a bad moment, and a mode that answers "I just had an idea" with a brainstorming session is how the idea gets dropped instead of recorded.

It reads the router and nothing else, matching the ask against every slug, alias, and summary. **When anything is close it shows the candidate row and asks** whether this belongs on that idea or starts a new one. Two folders for one idea splits the log, and the isolation guard means a later session opens one of them with nothing signalling the other exists.

On a new idea it **proposes a slug and confirms it before writing anything**, because no mode renames a folder afterwards. That was a deliberate trade against a rename step: the cost lands once, at creation, rather than in machinery maintained for a rare event. The router's `Idea` column carries the human-readable name and stays free to change.

When it fires from a work repo, the first log entry records which repo. Where an idea arrived from is usually part of the idea.

### `session`

The mode that thinks, and the only one that discusses.

**Its posture is state the strongest version, then name what would kill it.** Building the case first isn't politeness — an idea argued down before it's stated properly never gets a fair test. The kill condition comes after, and it's the thing that gets recorded as the open question.

There's an escape: say you're thinking out loud and the stress pass is skipped. The kill condition still reaches the log either way, so an expansive night costs the record nothing.

**Every session composes a `NOTES.md` entry, three to six lines at minimum, and then offers it.** You get the draft, its path, and a save-edit-drop choice. Say no and the folder is untouched. See [Why saving is something you ask for](#why-saving-is-something-you-ask-for) for what that trade costs and why the draft comes with the offer.

With no idea named it **asks** rather than guessing, offering recent ideas plus "a new idea". It never falls through to `status`; a session is a different transaction from a report, and silently swapping one for the other is worse than one question.

### `status`

Reports and writes nothing at all. It has two scopes, which is why there's no separate `list` mode — the difference between "where do all my ideas stand" and "where does this one stand" is an argument, not a posture.

**Cross-idea, it opens no topic folder and no dated jot file**, getting everything from the two routers and a directory listing. The pad gets one line under the table: how many jots are live, and which ones have three or more entries. Then it crowns one move, and the ranking rule is the interesting part: **the crown goes to the coldest active idea carrying an open question, not the warmest.**

Ranking on recency was the first draft, and it produced a crown that just restated row one of a table already sorted by recency. Inverting it makes the crown carry information. Cold plus an open question means you stopped mid-thought, which is the recoverable case; cold with nothing open means you drifted off, which isn't. And it's precisely the row a recency sort buries.

There's no stale marker. A tag most rows would wear within a year is a verdict on a repo whose entire premise is that ideas sit. It prints the age instead — `untouched 94 days` — and lets you judge.

**Its cache repair is detect-only**, which is the one place the guard and the self-heal genuinely conflict. Writing a router row needs five fields that all live inside the folder, so repairing an unregistered folder means opening it — for bookkeeping. So `status` names the folder, says to run `session` on it, and stops. The modes that already have a folder open offer their own row with the entry that changed it.

### `research`

Classifies before it acts, because "research" covers three different asks with three different owners.

A tool, library, framework, or architecture decision goes to [`researchkit`](./researchkit.md). A build-or-drop question isn't research at all and gets redirected to [`validate`](#validate). A market, competitor, category, or customer-signal question has no owner among the kits, so ideakit runs that one itself — who else does this, what the category is called, how incumbents price it, what users publicly complain about, each with a source and a date.

The answer arrives inline whichever branch runs. Keeping it as a file is a separate yes, asked once, after you've seen what the answer was worth.

### `validate`

Hands a startup or SaaS idea to [`validatekit`](./validatekit.md), takes the verdict inline, and offers the verdict, the wedge, and the assignment as one log entry.

It **honors validatekit's side-project off-ramp** rather than routing around it. That off-ramp fires often here, because most ideas in a personal ideas repo are not businesses, and "this is a side project, not a company" is a real answer worth offering to write down rather than an obstacle to a verdict.

### `close`

Records a verdict: `building`, `parked`, or `closed`. The reason is required, and the mode refuses to write a verdict without one — a status flip with no reason is a row edit pretending to be a decision.

**A closed idea keeps its folder.** Nothing is deleted, moved, or migrated. An idea you decide to build gets implemented in a separate project repo, and the folder stays here for the next thought about the same subject. Ideas outlive the projects they spawn, and the archive-on-success design loses exactly the folder you'd want when you revisit the subject in a year.

It was called `archive` first. The status flip is a one-line edit; the substance is the written verdict, and `close` names that.

## Why the dispatch is owned end to end

Both dispatch modes drive the sibling skill rather than suggesting it, and there are three concrete reasons, each one a thing that breaks otherwise.

The sibling writes to the wrong root. [`validatekit`](./validatekit.md) documents `docs/validation/` with no deference to a host convention, so left alone it writes into whatever directory you're standing in. When you keep the answer, ideakit writes the file itself at the absolute path under `topics/<slug>/docs/`, rather than re-running the sibling and hoping it lands right.

The sibling's inline-only default is now the right one. Both [`researchkit`](./researchkit.md) and validatekit answer in the conversation and offer a file only if asked. The first version overrode that and answered their save prompt yes, because the fold-back wanted an artifact to point at. That override is gone. The sibling's default and ideakit's are the same default now, and the save question gets asked once, by ideakit, after the answer exists.

Asking after rather than before is the load-bearing half. A question posed before the dispatch asks you to commit to keeping an answer you haven't read.

And two hand-offs help nobody. The dispatch is a sub-step, so the sibling's next-move line is suppressed and ideakit prints its own.

What you keep goes into the idea's own `NOTES.md` as a dated entry naming the question, the answer, and the file. That fold-back is what keeps one thread authoritative: a later session reads one log and finds every saved answer, instead of reconstructing them from a directory of artifacts.

## What it is not

- **Not an implementation tool.** No code ships from the ideas repo; that's [`implementkit`](./implementkit.md) in a project repo.
- **Not a task tracker.** An idea is not a ticket. Real work moves to a project repo and gets issues there with [`issuekit`](./issuekit.md).
- **Not a scheduler.** No due dates, no review queue, no spaced retrieval. That's [`tutorkit`](./tutorkit.md) on a different repo with a different premise.
- **Not a theme sweep.** No mode reads every idea looking for connections; that breaks the guard wholesale for something rarely wanted.
- **Not a replacement for the kits it calls.** Its fallbacks without them are short and say so.
- **Not an autosaver.** Outside `jot`, `promote`, `capture`, and `close`, it writes when you say yes and not before.
- **The jotpad is not an inbox.** Nothing in it is due, nothing expires, and no mode sweeps it for triage. A jot sits until you return to it or say it was nothing.
- **It never commits the ideas repo on its own.**

## Hands off to

Mostly to itself, chosen by state: `promote` when a jot has come back three times, another `session` on the question you stopped at, `research` when the block is an external fact, `validate` when the idea is a business with no verdict, `close` when nothing is open. [`status`](#status) is that routing rule made available on demand. A run that writes a jot hands off to nothing, which is the point of the mode.

It leaves the repo when an idea is settled enough to shape work. Then the next move is [`plankit`](./plankit.md) in the project repo, not here — and the idea's folder stays put either way.

It shares a shape with [`tutorkit`](./tutorkit.md) and nothing else. Both keep one repo, one folder per subject, a router with aliases, and a hard one-folder-per-session guard. But tutorkit teaches a subject somebody already settled, on a schedule; ideakit thinks about one nobody has settled, on no schedule at all.

## Install

```sh
npx skills add mimukit/skills -s ideakit
```

Source: [`skills/ideakit/SKILL.md`](../../../skills/ideakit/SKILL.md)

_Verified against `main`@`542b1cf` on 2026-08-24._
