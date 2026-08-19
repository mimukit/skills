# Plan — ideakit

Grilled: 2026-08-20

## Context

`~/ideas` exists as of 2026-08-19: a git repo with `INDEX.md` as a router, `topics/<slug>/` folders, and an `AGENTS.md` carrying four rules. One folder per idea, kit artifacts written inside the topic folder, cross-referencing only on request, and one idea folder read per session.

`AGENTS.md` loads only when the working directory is `~/ideas`. That covers the common case and leaves three gaps. An idea that arrives while I sit in a work repo has nowhere to go. Capturing an idea, recapping one, and closing one out are each a shaped procedure that a conventions file describes but does not perform. And the repo has no way to send a question to `researchkit` or `validatekit` and get the answer back into the idea's own log.

`ideakit` closes those three. It owns the repo contract, performs the procedures, and routes the outside work to the kits that already do it.

Success means one thing: I can say "capture this" or "let's think about the agent memory idea" from any directory, and end up with the right folder open, the right file written, and no other idea in context.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Skill or conventions file | Both, with a clean seam. `ideakit` owns the layout, the router schema, the mode procedures, and the artifact paths. `~/ideas/AGENTS.md` shrinks to a backstop of about ten lines carrying the isolation guard and the path rule, so both still hold in a session where the skill never fires. |
| Visibility | `internal: false`. The repo it manages is generic, and the skill must be self-contained: no repo-relative links, and every sibling kit named only when installed, with a plain fallback beside it. |
| Repo location | `~/ideas`, overridable by `$IDEAKIT_HOME`. Mirrors `tutorkit`'s `$TUTORKIT_HOME`. |
| Path resolution | Every mode resolves `$IDEAKIT_HOME` and writes absolute paths. No mode changes the working directory. A mode fired from a work repo touches no file in that repo, so the host repo's own conventions do not apply. |
| Mode set | Six: `capture`, `session`, `recap`, `research`, `validate`, `close`. `validate` stays a mode rather than a `research` branch, because "validate this as a business" is a distinct ask made on a different day, and merging the two would put `validatekit`'s adversarial posture on a factual question. |
| No `list` mode | `recap` covers both scopes. Named with no idea, it reports every idea and crowns what to discuss next. Named with one idea, it reports that idea and crowns the next move on it. |
| The router carries labels, not thinking | `INDEX.md` gains a `Summary` and an `Open question` column, so the cross-idea view reads one file however many ideas exist. Both cells are capped at one line and state *what* an idea is and *what is open*, never why and never a position. A table gets read whole, so the guard cannot be enforced by reading selectively; it is enforced by bounding what the router is allowed to hold. |
| The cross-idea crown ranks coldest-first | An `active` idea that is cold *and* carries a recorded open question means I stopped mid-thought, which is the recoverable case. Cold with no open question means I drifted off. Ranking on recency would have made the crown a restatement of the sort order, since it always names row one. |
| No `stale` marker | `recap` prints the age in the row (`untouched 94 days`) and I judge. A tag most rows wear within a year is a verdict on a repo whose whole point is that ideas sit, and the crown already promotes the cold ones. |
| Cache repair is detect-only in `recap` | Writing a router row needs the idea's name, aliases, summary, open question and status, all of which live inside the folder. So `recap` lists `topics/`, names any unregistered folder, and stops. The modes that already have a folder open repair their own row. |
| `ideakit` owns the dispatch path and the ending | `validatekit` hardcodes `docs/validation/` with no deference line, and both dispatch kits write a file only when asked. So `ideakit` passes the absolute write path, answers the save prompt yes, suppresses the sibling hand-off, and prints its own. `validatekit`'s side-project off-ramp is the one sibling decision `ideakit` honors instead of overriding. |
| `archive` renamed to `close` | The status flip is a one-line edit. The substance is the written verdict, and `close` names that. |
| An idea that gets built stays put | `close` never moves, migrates, or deletes a topic folder. Implementation runs in a separate repo, and the idea folder stays open for future thinking about the same subject. |
| Status vocabulary | `active`, `building`, `parked`, `closed`. `building` means implementation runs elsewhere; its `INDEX.md` cell carries the repo, as `` `building` · owner/repo ``. |
| Topic folder holds three root files | `IDEA.md` is the living statement. `NOTES.md` is the append-only dated log. `SOURCES.md` collects links, created lazily. Kit artifacts go under `docs/`, pasted material under `assets/`. |
| `IDEA.md` splits into a stable head and an `## Open` block | The log is the record and the statement is a cache of it. The head is rewritten when a session changed what the idea *is*; the `## Open` block is refreshed every session without exception. That gives a checkable completion criterion — the `## Open` block matches the last `NOTES.md` entry — which "rewrite when it changed" alone does not, and it stops an inconclusive session churning the file for no change. |
| `session`'s posture, with an escape | State the strongest version of the idea, then name what would kill it. When the ask is explicitly exploratory, build only. Either way the kill condition still gets recorded as the open question, so an expansive night costs the log nothing. |
| `session` with no idea named asks | It never guesses and never falls through to `recap`. It offers the recent ideas plus "a new idea", through `AskUserQuestion` when four or fewer candidates fit, and a numbered list otherwise. |
| The slug is permanent | No mode renames a folder. `capture` proposes a slug and confirms it with me before creating anything, so the cost lands once at creation instead of in rename machinery for a rare event. The router's `Idea` column carries the current human name and is free to change. |
| `capture` matches before it creates | It matches the ask against every slug, alias and summary in `INDEX.md`, and asks when anything is close, showing the candidate row. It reads only the router, so the guard holds. Two folders for one idea would split the log, and the guard means a later session reads one of them with nothing signalling the other. |
| Every `session` appends to `NOTES.md`; a full record is opt-in | A short entry of three to six lines is the spine the next session reads. Making it optional empties the repo and costs the isolation guard its payload. A fuller session write-up goes to `topics/<slug>/docs/sessions/` only when asked. |
| `research` and `validate` stay separate | Different postures. `research` produces a cited comparison or landscape; `validate` produces an adversarial build-or-drop verdict. |
| No `link` mode | Opening a second idea folder is a bounded exception inside `session`, fired only when I name the other idea. That folder is read-only for the session, and the connection is recorded in the primary idea's `NOTES.md` only. `tutorkit` handles its multi-topic read the same way, as a rule rather than a mode. |
| No cross-cutting theme sweep | Reading every idea to find themes breaks the isolation guard wholesale for something rarely wanted. |
| The description carries three triggers, not six | Capture an idea, discuss or recap one, and the ideas repo by name. `research`, `validate` and `close` are reached from inside a session or from a crown, never cold. The three dropped branches overlap siblings that should win a cold ask anyway — "should I build this" belongs to `validatekit`. |

## Approach

**What it reuses.** The router and isolation pattern comes from `tutorkit`: `INDEX.md` with slugs and aliases, resolve exactly one slug, open one folder, repair the cache when it drifts, and keep every field the cross-topic view prints in the router itself. The crowned-move dashboard and its rank table come from `statuskit`. The artifact naming convention (`<type>-<slug>-YYYY-MM-DD.md`) is already the repo standard and every dispatched kit already writes it. The four dispatch targets are `researchkit`, `validatekit`, `plankit`, and `grillkit`, all installed.

**What is genuinely new.** The path root swap, the six mode procedures, the `IDEA.md` and `NOTES.md` split, and the fold-back rule that puts every dispatched answer into the idea's own log so one thread stays authoritative.

### Phase 1 — The repo contract

The reference half of the skill, written before any mode depends on it.

**Layout.**

```
~/ideas/                              $IDEAKIT_HOME overrides
  INDEX.md                            the router
  topics/<slug>/
    IDEA.md                           stable head plus an ## Open block
    NOTES.md                          the dated log, append-only
    SOURCES.md                        collected links, created lazily
    docs/plans/                       plankit
    docs/research/                    researchkit, and the landscape scan
    docs/validation/                  validatekit
    docs/sessions/                    full session records, on request only
    docs/adr/                         decision records
    assets/                           diagrams and screenshots
```

- `$IDEAKIT_HOME` resolution, absolute paths in every mode, and repo creation with `git init` on first use. No mode changes the working directory.
- `INDEX.md` schema: `Idea | Slug | Also called | Summary | Open question | Status | Last touched`. Document the four status values and the `building` cell format.
- **The router cell bound.** `Summary` and `Open question` are one line each, stating what the idea is and what is open. Neither carries a reason, a position, or a half-formed argument. This is what keeps the guard true while the router stays cheap to read.
- `IDEA.md` format: a stable head (what the idea is, who it is for, what has to be true for it to matter) and an `## Open` block (the open questions and the possible next moves). The head is rewritten when a session changed what the idea is. The `## Open` block is refreshed every session.
- `NOTES.md` format: `## YYYY-MM-DD` per entry, recording what was decided, what was rejected and why, and the open question the session stopped on. Never rewritten.
- `SOURCES.md` format: one row per link, with the date read and one line on what it settles. Created on first use, not at capture.
- The isolation guard, stated as the load-bearing rule: read `INDEX.md`, resolve exactly one slug, open only that folder, never glob `topics/`. Name the two reasons, context cost and idea contamination.
- The bounded exception: open a second topic folder only when I name that idea in the ask. That folder is read-only for the session, and the connection is written into the primary idea's log.
- Cache repair, at two levels. Rewrite a topic's router row whenever a mode that has the folder open touches it. Report an unregistered folder rather than opening it. Rewrite `IDEA.md`'s head from `NOTES.md` when the two disagree.
- Slug rules: short lowercase kebab-case from the idea's core noun, proposed by `capture` and confirmed with me before the folder is created. Permanent afterwards.
- The path root swap, stated once: the artifact root is the topic folder, so a kit's documented `docs/…` path becomes `topics/<slug>/docs/…`.
- Commits stay manual. Offer one at session end and accept no.

**Done when** every mode below can be written without inventing a path, a status value, or a file format.

### Phase 2 — The core loop

`capture`, `session`, and `recap`. These three carry the skill.

**`capture`** — match the ask against every slug, alias and summary in `INDEX.md` and show the candidate row when anything is close, letting me pick append or create. On create, propose a slug and confirm it before writing anything, because the slug is permanent. Then create the folder, write `IDEA.md` and the first `NOTES.md` entry in my own words, and add the router row with two or three aliases, the one-line summary, and the open question if one is obvious. When the mode fires from another repo, record that repo in the first `NOTES.md` entry, since where an idea arrived from is usually part of the idea. Then stop. It does not discuss, research, or offer a session more than once. Done when the router row exists and `IDEA.md` states the idea.

**`session`** — the mode that thinks.

1. Route. With an idea named, resolve one slug. With an unknown slug, open the topic first. With no idea named, ask: offer the ideas by last touched plus "a new idea", through `AskUserQuestion` when four or fewer candidates fit and a numbered list otherwise. Never guess, and never fall through to `recap`.
2. Read only `topics/<slug>/`. Read `IDEA.md`, then `NOTES.md`, then only the artifacts they name.
3. Print the single-idea recap as the opening step, so the session starts from where the last one stopped.
4. Discuss. The posture rule: state the strongest version of the idea, then name what would kill it. When I say I am thinking out loud, build only and skip the stress pass. Record the kill condition as the open question either way.
5. Close. Append the dated `NOTES.md` entry, refresh `IDEA.md`'s `## Open` block and rewrite its head if the idea itself changed, and refresh the router row. A `parked` or `closed` idea that gets a session returns to `active` under a new dated entry.

Done when the log entry names a decision, a rejection, or an open question, and `IDEA.md`'s `## Open` block matches that entry, and the router row matches both.

**`recap`** — reports, and writes nothing.

*Cross-idea scope, no idea named.* Read `INDEX.md`, list `topics/`, and open no topic folder. Print one table sorted by last touched, grouped by status, with each row's age in days. Name any folder missing from the router and say to run `capture` or `session` on it to register it; do not open it. Then crown one move:

| # | State | Move → |
|---|-------|--------|
| 1 | An `active` idea carries a recorded open question | `session` on the coldest such idea, naming its age |
| 2 | An `active` idea carries no open question | `session` on it, to find one |
| 3 | A `building` idea carries an open question | `session` on it |
| 4 | Every idea is `parked` or `closed`, or none exists | say there is no next move, and offer `capture` |

Within rule 1 the crown goes to the coldest idea, not the warmest. A cold idea carrying an open question is one I stopped mid-thought, and it is the row the sort order buries.

*Single-idea scope, one idea named.* Read `IDEA.md`, the last two or three `NOTES.md` entries, and a listing of `docs/` without reading the artifacts. Print what the idea is, where it stands, and the open questions. Then crown one move:

| # | State | Move → |
|---|-------|--------|
| 1 | An open question blocks the others | `session` on that question |
| 2 | The idea rests on an unresearched external fact | `research` |
| 3 | The idea is a business and has no validation verdict | `validate` |
| 4 | The idea is settled enough to shape work | plan it in the project repo |
| 5 | Nothing is open and no next question exists | `close`, naming which verdict fits |

Done when the printed state matches the files read and exactly one move is crowned.

### Phase 3 — The dispatch modes

`research` and `validate`. Both route to a slug first, both own the dispatch end to end, and both fold the answer back into `NOTES.md` as a dated entry naming the question, the answer, and the file. Both then refresh `IDEA.md` and the router row.

**The dispatch contract**, stated once and used by both. Pass the sibling kit the absolute write path under `topics/<slug>/docs/…`, because `validatekit` hardcodes `docs/validation/` and will otherwise write to the wrong root. Answer its save prompt yes, because both kits default to inline-only and the fold-back needs the artifact. Suppress the sibling's hand-off and print `ideakit`'s own, because the dispatch is a sub-step and two competing next-step lines help nobody.

**`research`** classifies before it acts. A tool, library, framework, or architecture decision goes to `researchkit`. A build-or-drop question is redirected to `validate`. A market landscape, competitor, category, or customer-signal question has no owner among the kits, so `ideakit` runs it: who else does this, what the category is called, how incumbents price it, what users publicly complain about, each with a source and a date. Artifacts land in `topics/<slug>/docs/research/`. Without `researchkit` installed, it runs the comparison itself against primary sources and says it is the short version.

**`validate`** hands a startup or SaaS idea to `validatekit`, with the write path set to `topics/<slug>/docs/validation/`. It honors `validatekit`'s side-project off-ramp rather than working around it, which will fire often here, since most ideas in a personal ideas repo are not businesses. It folds the verdict, the wedge, and the assignment into `NOTES.md`, and updates the router status when the verdict moves it. Without `validatekit` installed, it runs a short forcing-question set and a graded verdict, and says it is the short version.

**Done when** each mode names its classifier branches, its write path, its fold-back entry, and its degradation without the sibling kit.

### Phase 4 — `close`

Route to a slug. Ask which verdict applies: `building`, `parked`, or `closed`. Require the reason, and write a dated verdict entry into `NOTES.md` recording what was decided, what evidence decided it, and what would reopen it. Rewrite `IDEA.md` to carry the verdict at the top of its head. Update the router row. On `building`, record the implementation repo in both the status cell and the entry.

The mode never deletes a topic folder, never moves a file out of one, and never migrates anything to another repo. Done when the verdict entry, `IDEA.md`, and the router row agree, and nothing else in the folder changed.

### Phase 5 — Reconcile `~/ideas`

- Cut `AGENTS.md` to the backstop: the isolation guard and the path rule, naming `ideakit` as the owner of everything else.
- Migrate `INDEX.md` to the seven-column schema.
- Update `README.md` for the four status values, the three topic files, and the fact that a built idea keeps its folder.

**Done when** no rule states its full derivation in both the skill and `AGENTS.md`.

### Phase 6 — Publish

- Frontmatter: `name: ideakit`, `internal: false`, and a description carrying three triggers — capture an idea, discuss or recap one, and the ideas repo by name.
- `allowed-tools`: `Read`, `Write`, `Edit`, `Glob`, `Bash`, `AskUserQuestion`, `WebSearch`, `WebFetch`. `Bash` covers `git init` and the directory listing; the two web tools are what the landscape scan in `research` runs on when `researchkit` is absent.
- `docs/wiki/skills/ideakit.md`, registered in `docs/wiki/.wikimap.yaml` and linked from `docs/wiki/index.md`.
- An entry in `skills.sh.json`.
- `make lint` clean, then `make link` and run every mode against the real repo.

**Done when** lint passes and each of the six modes has run once end to end.

## Open questions

Twelve questions were settled in the 2026-08-20 grill. Two things stay open, and neither blocks the build.

- **Does the three-trigger description undertrigger?** `research`, `validate` and `close` have no cold trigger by design, on the argument that a cold "should I build this" belongs to `validatekit`. Undertriggering is the failure that leaves no trace, so this can only be settled by using the skill and noticing a mode that never fires.
- **The cross-reference write-back.** Settled by derivation rather than by asking: a second idea folder opened during a session is read-only, and the connection is written into the primary idea's `NOTES.md` alone. The cost is that the second idea's log never learns it was cited.

## Non-goals

- **No implementation.** Code for an idea ships from a separate repo. `ideakit` never writes application code and never opens issues.
- **No moving or deleting.** No mode migrates a topic folder, archives files out of it, or removes it.
- **No renaming.** The slug is fixed at creation. No mode renames a folder.
- **No cross-idea sweep.** No mode reads every topic to find themes.
- **No schedule.** No due dates, no review queue, no spaced retrieval. That is `tutorkit`'s job on a different repo.
- **Not a replacement for the kits it calls.** `ideakit` never reimplements `researchkit`'s comparison discipline or `validatekit`'s diagnostic beyond a short, self-declared fallback.
- **Not a task tracker.** An idea is not a ticket.
