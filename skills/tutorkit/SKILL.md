---
name: tutorkit
description: >-
  Teach a topic across many sessions, with one learning repo holding a folder per topic, lessons pitched at what you already know, and spaced retrieval that makes it stick. Use when the user says "explain how X works", "teach me X", "quiz me on what's due", "am I ready on X", "where am I with my learning", or runs "/tutorkit".
license: MIT
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebSearch, WebFetch, AskUserQuestion
metadata:
  internal: false
---

# tutorkit

Four postures, not four presentations: [`explain`](modes/explain.md) answers and writes nothing, [`lesson`](modes/lesson.md) teaches and is the only mode that opens a track, [`drill`](modes/drill.md) tests recall across topics, [`exam`](modes/exam.md) measures and refuses to teach.

[`status`](modes/status.md) is a fifth mode and not a fifth posture. It teaches nothing, asks nothing, and grades nothing. It reads the two router files, prints where every track stands, and crowns the next move.

## What tutorkit is not

- **Not a decision report.** "Which queue library should we use" is a research question, even though both read primary sources.
- **Not a spaced-repetition engine.** A fixed five-step interval ladder, no SM-2 or FSRS tuning, no Anki export, no retention modelling.

## Mode selection

Resolve on intent rather than phrasing: a question that wants an answer gets `explain`, and a request to end up knowing the thing gets `lesson`. A request to be quizzed, or to see what is due, gets `drill`. A request to measure readiness on a topic gets `exam`. A request for where every track stands gets `status`.

**An ask that names no topic is almost always `status`.** The other four modes need a slug, and `status` refuses one.

When the ask is ambiguous, run `explain` and offer the track at the end.

## The learning repo

All state lives in one repo outside the user's work repos, at `~/learning` unless `$TUTORKIT_HOME` names somewhere else.

```
~/learning/                          ← one git repo; $TUTORKIT_HOME overrides
  INDEX.md                           ← the router
  REVIEW.md                          ← cross-topic due queue, one row per topic
  NOTES.md                           ← how the user likes to be taught, global
  assets/lesson.css                  ← copied from the skill on first run, never overwritten
  topics/<slug>/
    MISSION.md                       ← append-only; why they are learning it, plus the grounding consent
    PROGRESS.md                      ← placement result, what stuck, what is shaky, where they are
    CUES.md                          ← retrieval cues, key points, due dates, interval step, last seen
    SOURCES.md                       ← vetted primary sources, so the agent stops re-searching
    lessons/0001-<dash-case>.html
    reference/<name>.html            ← printable cheat sheets and the glossary
    exercises/                       ← runnable practice, code topics only
```

Create the repo on first use and run `git init` in it. **Never commit automatically.** Offer a commit at the end of a session and take no for an answer.

**The routing rule overrides every other rule here.** Read `INDEX.md` and `NOTES.md` at session start, resolve exactly one slug, then read only `topics/<slug>/`. Never glob across `topics/`.

Two modes are exceptions, and both are bounded. `drill` resolves its slugs from `REVIEW.md` rather than from the ask, then opens the `CUES.md` of those topics only. It never reads their lessons, and it never globs.

`status` is the stricter exception: it reports on every topic and opens no topic folder at all. `INDEX.md` and `REVIEW.md` carry every field the dashboard prints, or the dates to derive it from.

**When cwd is the learning repo itself, treat it as the learning repo and not as a grounding source.** A `lesson` run from inside the learning repo skips the grounding question.

### The router

`INDEX.md` carries aliases so a fuzzy ask routes without opening anything:

```markdown
| Topic | Slug | Also called | Status | Last touched |
|-------|------|-------------|--------|--------------|
| Postgres MVCC | `postgres-mvcc` | transaction isolation, snapshot, vacuum, row locking | active | 2026-08-11 |
```

Status is `active` or `learned`. Three routing outcomes, all cheap:

- The ask matches a slug or an alias → open that folder.
- It matches nothing and the user wants depth → create the folder and open a track.
- It matches nothing and the user wants an answer → run `explain` and write nothing.

`REVIEW.md` holds one row per topic, never one per cue: `postgres-mvcc · due: 2026-08-18, 2026-08-18, 2026-08-21, 2026-09-08 · min step: 3d`. The `due` cell lists every cue's due date in that topic, sorted, and nothing else about the cue. **Derive the due count at read time** (the dates on or before today); never store one. `drill` reads the row, sees which topics are due, and opens only those `CUES.md` files.

**`min step` is the lowest interval step any cue in that topic has reached.** A topic whose `min step` is `60d` has passed the schedule half of the `learned` gate, so `status` can crown [`exam`](modes/exam.md) without reading a `CUES.md`.

**Both files are caches.** Repair runs only where a mode already has the topic folder open:

- **Every mode that opens a topic folder rewrites that topic's row in both files**, from the folder's own `CUES.md` and `MISSION.md`, whether or not the row looked wrong.
- **A slug with a folder on disk but no `INDEX.md` row** routes as if the row existed. `lesson`, `drill`, or `exam` on that slug opens the folder and writes the row.
- **`status` opens no topic folder, so it repairs nothing.** It names each folder missing from the routers and each row with a missing or old-format field, and says to run `lesson` on that slug.

A `REVIEW.md` row with no `min step`, or with a stored count in place of due dates, was written before the current format. The next mode that opens that topic writes the row in the current format.

### The stylesheet

`assets/lesson.css` ships beside this file. On first run, resolve this skill's own installed directory and copy the stylesheet to `<repo>/assets/lesson.css`, because the working directory is the user's project, not the skill directory, so a relative path will not find it. **Copy it once and never overwrite it.**

## The modes

The mode bodies live in one file each under `modes/`. Route with [Mode selection](#mode-selection), read that one file, and follow it. Everything above this line, and the shared sections below, apply to every mode and are not restated in the mode files.

- Mode `status` → read [modes/status.md](modes/status.md), then follow it.
- Mode `explain` → read [modes/explain.md](modes/explain.md), then follow it.
- Mode `lesson` → read [modes/lesson.md](modes/lesson.md), then follow it.
- Mode `drill` → read [modes/drill.md](modes/drill.md), then follow it.
- Mode `exam` → read [modes/exam.md](modes/exam.md), then follow it.

## The spacing schedule

Intervals: `1d → 3d → 7d → 21d → 60d`. Cues live per topic in `CUES.md`:

```markdown
| id | cue | key points | due | step | misses | last seen |
|----|-----|------------|-----|------|--------|-----------|
| 3 | Why does a long-running read never block a write in MVCC? | readers see a snapshot; writers make a new row version; visibility is decided per transaction | 2026-08-21 | 3d | 1 | 2026-08-18 |
```

- `got it` advances one interval.
- `partial` repeats at the same interval.
- `missed` resets to `1d` and re-teaches the cue inline.

**There is no decay for lateness.**

### Grading a free-text answer

Three grades, judged against the cue's 2–3 stored key points:

- **`got it`.** The answer covers the key points, in any words.
- **`partial`.** Some key points, or the right shape with a wrong detail.
- **`missed`.** The key points are absent, or the answer contradicts them.

**Offer the override on every grade, not only on a miss.**

## The lesson artifact

One self-contained HTML file at `topics/<slug>/lessons/NNNN-<dash-case>.html`, linking `../../../assets/lesson.css`. Tufte constraints: one column, generous margins, sidenotes rather than footnotes, and **roughly 700 words as a ceiling**.

Each lesson carries, in order:

1. The one-line tie back to the mission, **naming the dated `MISSION.md` entry it was written against**.
2. The prediction the user made, and where it was wrong.
3. The mechanism.
4. One worked example.
5. The practice, with its feedback loop.
6. The cues that were scheduled.
7. The primary source to read next.
8. Anchors to sibling lessons and reference sheets.
9. A closing line reminding the user that the agent is available for anything still unclear.

**Reuse before authoring.** Read `assets/` first and build from the components already there. Put a component a second lesson would duplicate in `assets/`, not inline.

**Reference sheets carry the compressed essence**: a table, a decision rule, a diagram, not a retelling. Write them to `reference/<name>.html`. A glossary, once written, binds every later lesson.

**Quiz options are the same length in words and characters**, so formatting leaks no answer.

Try the platform's opener (`open`, `xdg-open`, `start`) on the lesson once; when it fails, print the file path and continue.

## Citation discipline

Every non-obvious claim carries a primary source: the spec, the RFC, the source code, the official docs, the changelog. **Prefer reading source over reading blog posts.** When you cannot find a source, say "I believe X but could not source it" rather than asserting it.

Record what you read in `SOURCES.md`, with title, URL, date read, and one line on what it settles. Check `SOURCES.md` before searching.

## Hand off

_Write this section in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

**What changed.** Name the lesson written, the cues scheduled, the grades recorded, and what you marked as shaky. Name what did not change too: a declined track, a cue you could not source, a status you refused to write.

**Where it landed.** Give the topic folder path and the lesson path. Give the repo path when this run created the repo.

**Next.** Crown one move, chosen by state:

- Cues are due now → run `drill`.
- The track is mid-flight and nothing is due → run the next `lesson`.
- Every cue sits at step `60d` and the track looks finished → run `exam`.
- The track just closed as `learned` → say there is no next step.

Then offer a commit of the learning repo. Never run it without a yes.

**A `status` run closes differently.** The dashboard already names the crowned move, so do not print the move twice. State that nothing changed, and name each row that needs repair. Do not offer a commit.

**An `explain` run closes short.** State that nothing changed. When the user accepted the track offer, crown `lesson` on that topic. When they declined it, say there is no next step. Do not offer a commit.

Name a sibling skill only when it is installed, and otherwise describe the action plainly. Route to a research skill when the question turns out to be a tool decision rather than a knowledge gap. Route to a prototype skill when the only honest answer is to build the thing and find out.

## Notes

- **`status` reports; it never grades.** Judging whether the user knows a topic is [`exam`](modes/exam.md), and it needs an answer from the user. Never infer mastery from the `min step` column.
- **No writable filesystem** (a browser-based agent)? Say so plainly, print the lesson as a code block for the user to save, and note that spacing cannot persist without state. Do not pretend to schedule a cue you cannot write. `status` and `explain` still run, because neither writes.
