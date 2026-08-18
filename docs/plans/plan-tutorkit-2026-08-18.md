# Plan — tutorkit

Grilled: 2026-08-18

_Created 2026-08-18._

## Context

Nothing in this collection teaches. Every skill here assumes you already know the thing and helps you do it faster — `researchkit` hands you a decision, `wikikit` describes a project, `debugkit` finds a cause. None of them build durable knowledge in the person operating them, and none of them remember what you knew last week.

The gap is a tutor: a skill that keeps a picture of what you know, pitches the next thing at the edge of it, and comes back later to check whether it stuck. The owner learns software engineering topics continuously and wants that picture kept in one place rather than re-explained every session.

The seed is Matt Pocock's [`teach`](https://github.com/mattpocock/skills/blob/main/skills/productivity/teach/SKILL.md). Per this repo's rules the skill is **authored from scratch, never forked**; the upstream informs structure only. It contributes four ideas worth keeping — the lesson as the unit of teaching, beautiful printable artifacts, the mission as the thing that grounds every lesson, and the split between fluency and storage strength. It has five gaps, and closing them is most of what makes this a different skill:

1. **It hijacks the current directory.** `teach` treats cwd as a dedicated teaching workspace, so it can never teach you about the repo you are actually standing in. For software topics, a lesson built from your real code beats a generic one, and that is the single largest available differentiator.
2. **Spacing is named, not built.** It lists spacing as a retention principle and ships no schedule, no due dates, no review queue. A principle with no mechanism does not space anything.
3. **No placement.** It infers the zone of proximal development from past records, so session one has nothing to read and pitches blind.
4. **No misconception hunting.** It teaches what you are missing and never diagnoses what you believe that is wrong. The wrong belief is the higher-value target, because it actively blocks the correct model.
5. **No fast path.** Every ask becomes a multi-session commitment behind a mission interview. "How does Postgres MVCC work" should not open a track.

## Settled decisions

| # | Decision | Answer | Why |
|---|---|---|---|
| — | Name | `tutorkit` | Clean on npm, PyPI, and GitHub. A tutor is by definition someone who remembers you and adapts; a teacher delivers a lesson and needs no memory. Persistence is the whole design, so the name should carry it. `learnkit` was rejected on two counts: npm is taken and `learnkit-ai/learnkit` is an active AI learning-path product in the same niche, and it would be the only skill here named for the *user's* action rather than the agent's. |
| — | State location | `~/learning`, overridden by `$TUTORKIT_HOME` | Keeps learning notes out of work repos while still letting the skill read a work repo for examples. No Claude-specific path, so a public skill stays portable. |
| — | One repo or one per topic | **One repo**, `topics/<slug>/` | Per-topic repos break the two mechanisms that matter. Drill is cross-topic by nature, so it would have to open every repo anyway. Interleaving needs more than one topic in view. A registry to avoid that is just the parent repo with extra steps. |
| — | Routing | `INDEX.md` with aliases; open exactly one topic folder | This is the whole context story. Thirty topics costs about sixty lines to route; opening all thirty costs tens of thousands. |
| — | Artifact format | HTML lessons and reference sheets, Markdown state | Split on revisit-versus-rewrite. You print and re-read a lesson, so it earns HTML. The agent rewrites state every session, so it stays Markdown and diffable — state in HTML would make `git log` useless for tracking progress. |
| — | Modes | `explain`, `lesson`, `drill`, `assess` | Four genuinely different postures, not a presentation split. `explain` writes nothing, `lesson` teaches, `drill` tests recall, `assess` measures and refuses to teach. |
| — | Visibility | `public` | Conventions inlined, no repo-relative links, degrades without a filesystem. |
| — | skills.sh group | New **Learning** group | None of the eight existing groups fits. Writing & Docs is about producing documents for others; this produces skill in the operator. A group of one is honest here in a way that a bad fit is not. |
| — | `docs/wiki/workflow.md` | No entry | That document maps the build loop. tutorkit sits beside it, not inside it. Lint only validates mentions that exist, so omitting it is clean. |
| — | Committing the learning repo | Initialize as git on creation; **offer** a commit at session end, never automatic | The progress history is genuinely useful, and the repo is the user's own. Committing without asking is still the wrong default. |
| Q1 | Drill session cap | Cap 12 cues per run, sorted `due` ascending then miss count descending; overflow keeps its original `due` | An uncapped queue is what kills every spaced-repetition system — forty cues on return trains the user to stop opening it. Overdue-first stops the oldest cue starving. Leaving the overflow's `due` untouched keeps it first in line tomorrow instead of quietly rescheduling a debt. |
| Q2 | Grading a free-text answer | Three grades — `got it`, `partial`, `missed` — judged against 2–3 stored key points, with a user override offered on every grade | Binary grading forces a wrong call on the half-right answer, which is most answers. A third grade that repeats at the same step absorbs the ambiguity instead of resolving it wrongly in either direction. The whole interval ladder runs on this judgement, so the user has to be able to correct it. |
| Q3 | Who opens a track | `lesson` — on an unknown slug it runs a short mission interview, writes `MISSION.md` and the first `SOURCES.md` rows, then teaches | The original modes table filed `MISSION.md` under `assess` and never wrote `SOURCES.md` at all, so nothing opened a track and the source cache stayed empty. A separate `track` mode would make "teach me X" a two-step ask, which is the fast-path complaint this plan raises against the upstream. |
| Q4 | Repo-grounding consent | Ask once per topic, record `grounding: <repo path> \| declined` in `MISSION.md`, never ask again for that topic | Repo grounding is the largest differentiator, and a prompt that fires every lesson gets switched off. One prompt buys the whole track. Consent is scoped to the repo, so a different cwd on a later session asks again. |
| Q5 | Shared stylesheet | Ship `assets/lesson.css` beside `SKILL.md`; copy into the learning repo on first run only, never overwrite | `verifykit` already ships `verify-assets.sh` as a satellite file, so the one-file preference has a precedent against it. Generating per install means a lesson renders differently everywhere. Copying rather than linking means a skill update never restyles lessons already written. |
| Q6 | Placement | 3–5 scenario predictions, broad to narrow, graded on the Q2 scale; stop early on two consecutive misses | Reuses the predict-before-explain device the skill already owns rather than inventing a second assessment mechanism. Self-report is the weakest signal available, and a single transfer problem fails a genuine beginner flat on first contact. The wrong predictions become lesson 1's target. |
| Q7 | What marks a topic `learned` | Both gates — a passed transfer test **and** every cue at step `60d`; `drill` then fills its 12 slots from `active` topics first and lets `learned` cues take what is left | The transfer test alone would close a topic whose cues still sit at `1d`. Cues at `60d` alone measure recall of taught shapes, which this plan itself calls learning the surface. Retiring the cues at close is exactly when forgetting starts, so they keep coming due without competing with live tracks. |
| Q8 | Mission drift | `MISSION.md` is append-only under `## YYYY-MM-DD` headings; existing lessons are never rewritten or archived | Re-pitching rewrites files the user may have printed and annotated. Archiving hides work they did and breaks the sibling anchors between lessons. A lesson's tie-back line names the mission entry it was written against, so an old lesson reads as dated rather than wrong. |
| Q9 | Overdue decay | None. A miss resets to `1d` as planned; `CUES.md` gains a `last_seen` column | The cap can hold a cue 30 days past due, so a decay rule would punish the user for the skill's own backlog. One schedule rule is easier to reason about than two, and the `partial` grade already absorbs most of this. Showing "last seen 34 days ago" on the drill line lets the user override with the fact in view. |

## The skill

**`skills/tutorkit/SKILL.md`** plus one satellite, **`skills/tutorkit/assets/lesson.css`**, public. The satellite follows the precedent `verifykit` already sets with `verify-assets.sh`: resolve the installed skill directory to reach it, because cwd is the user's project rather than the skill directory.

```yaml
---
name: tutorkit
description: >-
  Teach a topic across many sessions — one learning repo with a folder per topic, lessons pitched at what you already know, and spaced retrieval that makes it stick. Use when the user says "teach me X", "tutor me on X", "I want to learn X", "explain how X works", "quiz me on what I learned", "what's due for review", "test me", "am I ready", or runs "/tutorkit". Tuned for software engineering topics and works for any other.
license: MIT
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, WebSearch, WebFetch, AskUserQuestion, Task, Agent
metadata:
  internal: false
---
```

`Bash` is present because the skill opens a lesson in a browser and runs practice exercises. `WebSearch` and `WebFetch` are present because the citation rule below is unenforceable without them.

### The learning repo

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

**The routing rule is the load-bearing guard.** Read `INDEX.md` and `NOTES.md` at session start, resolve exactly one slug, then read only `topics/<slug>/`. Never glob across `topics/`. Without this rule the skill degrades as the user learns more, which is the exact wrong direction.

`drill` is the one exception, and it is a bounded one. It resolves its slugs from `REVIEW.md` rather than from the ask, then opens the `CUES.md` of those topics only. It never reads their lessons, and it never globs. Interleaving needs more than one topic in view; it does not need more than one file per topic.

**When cwd is the learning repo itself, treat it as the learning repo and not as a grounding source.** The two roles never overlap, so a `lesson` run from inside `~/learning` skips the Q4 grounding question rather than offering to teach the user about their own notes.

`INDEX.md` carries aliases so a fuzzy ask still routes without opening anything:

```markdown
| Topic | Slug | Also called | Status | Last touched |
|-------|------|-------------|--------|--------------|
| Postgres MVCC | `postgres-mvcc` | transaction isolation, snapshot, vacuum, row locking | active | 2026-08-11 |
```

Three routing outcomes, all cheap. The ask matches a slug or alias, so open that folder. It matches nothing and the user wants depth, so create the folder and open a track. It matches nothing and the user wants an answer, so run `explain` and write nothing.

`REVIEW.md` holds one row per topic, never per cue — `2026-08-18 · postgres-mvcc · 4 due`. `drill` reads it, sees which topics are due, and opens only those `CUES.md` files. Storing cue text here instead would duplicate the answers and let them drift from the lessons that own them.

**Both files are caches, and a cache needs a repair path.** The skill rewrites the affected row whenever it touches a topic, and rebuilds both by scanning `topics/` when it finds a folder they do not list. Without the self-heal, one hand edit misroutes silently forever.

### What it adds over the reference skill

These are the load-bearing sections, not decoration.

- **Predict before you explain.** Before teaching a mechanism, pose a concrete scenario and make the user commit to a prediction. A wrong prediction names their broken mental model, which is the actual teaching target. This is the highest-value addition and the upstream has nothing like it.
- **A real spacing schedule.** Intervals `1d → 3d → 7d → 21d → 60d`, stored per topic in `CUES.md` as `| id | cue | key points | due | step | misses | last seen |`. `got it` advances one step, `partial` repeats at the same step, `missed` resets to `1d` and re-teaches the cue inline. There is no decay for lateness: a cue held back by the cap is the skill's debt, not the user's.
- **A cap that keeps the queue openable.** `drill` takes 12 cues per run, `due` ascending then misses descending, and prints how many it left — `12 of 41 · 29 still due`. The overflow keeps its original `due`, so it stays first in line rather than being quietly rescheduled. `active` topics fill the slots first and `learned` topics take what is left. An uncapped queue is the failure mode that ends every spaced-repetition habit, and hiding the backlog is only a nicer way to lose it.
- **Interleaving.** `drill` mixes cues from different topics in one session. This is the reason the parent repo exists rather than one repo per topic.
- **Repo grounding, consented once.** When cwd is a real project, ask once whether to read it, record the answer in `MISSION.md`, and never ask again for that topic. Then build the example out of the user's own code. A lesson on dependency injection written against their actual service container beats one written against `FooService`. A different cwd on a later session asks again, because the consent covered one repo.
- **Citation discipline, made operational.** Every non-obvious claim carries a primary source — the spec, the RFC, the source code, the official docs, the changelog. Prefer reading source over blog posts. When no source is found, say "I believe X but could not source it" rather than asserting. The upstream says "never trust your parametric knowledge" and supplies no procedure; this is the procedure.
- **Explain-back gate.** A lesson does not close until the user restates the concept in their own words. That retrieval is what converts fluency into storage strength, and it is the cheapest possible check that the lesson landed.
- **Placement, so session one does not pitch blind.** `assess` at track start poses 3–5 scenario predictions from broad to narrow and stops early on two consecutive misses. It writes `placed: <rung>` and every wrong belief into `PROGRESS.md`. This reuses the prediction device rather than inventing a second assessment mechanism, and the wrong beliefs it surfaces become lesson 1's target.
- **Transfer test.** `assess` closes a track with a problem the user has not seen that needs the concept without naming it. Solving only the taught shape means the surface was learned.
- **A track that can actually close.** A topic goes `learned` in `INDEX.md` only when it passes the transfer test *and* every cue has reached step `60d`. `assess` is the only mode that writes it. Its cues keep coming due afterwards, because retiring them at close is exactly when forgetting starts, but they never displace an `active` topic under the cap.

### The four modes

| Mode | Writes | What it does |
|---|---|---|
| `explain` | nothing | One-shot answer, then stop. No mission interview, no folder, no index row. Shortest correct answer first, then the mechanism, then one worked example, then a primary source. Offers a track once at the end and takes no for an answer. |
| `lesson` | lesson HTML, `MISSION.md`, `SOURCES.md`, `PROGRESS.md`, `CUES.md`, `INDEX.md`, `REVIEW.md` | The core loop, and the only mode that opens a track. On an unknown slug: run a short mission interview, ask once for grounding consent, write `MISSION.md`, create the folder and the index row. Every run: route, read progress, pick the target in the zone of proximal development, make the user predict, teach the minimum, practice against a feedback loop, gate on explain-back, write the lesson, append the sources it used, schedule the cues. |
| `drill` | `CUES.md`, `REVIEW.md`, `PROGRESS.md` | Read `REVIEW.md`, open the `CUES.md` of due topics only, interleave, cap at 12, ask one at a time with no answer visible, grade on three levels with an override offered, then advance, repeat, or reset each interval. |
| `assess` | `PROGRESS.md`, `INDEX.md` | Measures and never teaches. At track start it places the user with 3–5 predictions so lessons are not pitched low. At track end it runs the transfer test and, if every cue has also reached `60d`, writes status `learned`. |

`assess` has two entry points rather than two modes, because the posture is identical in both: ask, grade, record, refuse to explain. Splitting it would name a presentation difference as a behavioural one. It writes `PROGRESS.md` at both ends and touches `INDEX.md` only to close a track — the mission belongs to `lesson`, which is the mode that opens one.

**Mode selection is the skill's first decision, and the triggers overlap on purpose.** "Explain how X works" is `explain` and "teach me X" is `lesson`, but the wording is a weak signal. Resolve on intent rather than phrasing: a question that wants an answer gets `explain`, a request that wants to end up knowing the thing gets `lesson`. When the ask is genuinely ambiguous, take the cheap branch — run `explain` and offer the track at the end. Guessing `lesson` costs a mission interview the user did not want; guessing `explain` costs one extra sentence.

### The lesson artifact

One self-contained HTML file at `topics/<slug>/lessons/NNNN-<dash-case>.html`, linking the shared stylesheet in `assets/`. Tufte constraints: one column, generous margins, sidenotes rather than footnotes, roughly 700 words as a ceiling. Working memory is small and a long lesson is a lesson that does not finish.

Each lesson carries, in order: the one-line tie back to the mission — naming the dated `MISSION.md` entry it was written against — the prediction the user made and where it was wrong, the mechanism, one worked example, the practice with its feedback loop, the cues that were scheduled, the primary source to read next, anchors to sibling lessons and reference sheets, and a closing reminder that the agent is available for anything unclear. Naming the mission entry is what lets a mission change leave old lessons alone: a lesson written against a superseded mission reads as dated rather than wrong.

**The stylesheet ships with the skill.** `assets/lesson.css` lives beside `SKILL.md` and gets copied to `<repo>/assets/lesson.css` on first run. Copy it once and never overwrite it, so a later skill update ships a new default for new repos and leaves every existing lesson rendering the way it was written. Linking the installed path instead would break every lesson the moment the skill moves.

**Reuse before authoring.** Read `assets/` first and build from the components already there. The stylesheet is what makes a pile of one-off files read as one course; components the user's own topics earn accumulate beside it. Never inline something a second lesson would duplicate.

**Opening the lesson is best-effort and never blocking.** Try the platform's opener — `open` on macOS, `xdg-open` on Linux, `start` on Windows — and if none succeeds, print the file path and move on. A lesson that was written successfully must not report failure because a browser did not launch.

**Code topics still get a runnable exercise.** The lesson stays HTML, and for a code topic it links a file in `exercises/` and prints the command to run it. A test run is the tightest feedback loop available and a browser quiz cannot match it.

Two details worth keeping from the upstream: quiz options are the same length in words and characters, so formatting leaks no answer; and reference sheets are the thing that gets revisited, so they carry the compressed essence rather than the narrative. A glossary, once written, binds every later lesson.

**No writable filesystem** — a browser-based agent — then say so plainly, print the lesson as a code block, and note that spacing cannot persist without state.

### Hand off

*What changed* — the lesson written, the cues scheduled, and what was recorded as shaky. *Where it landed* — the topic folder and the lesson path. *Next* — the single best move, crowned by state: a due drill when cues are waiting, the next lesson when the track is mid-flight, `assess` when the track looks finished. tutorkit is largely terminal, so where there is no next move it says so instead of inventing one. Sibling routes exist but are narrow: `researchkit` when the question turned out to be a tool decision rather than a knowledge gap, `prototypekit` when the only honest answer is to go build the thing and find out.

## Repo bookkeeping — same change, all of it

- **`skills/tutorkit/SKILL.md`** — the skill, as above.
- **`skills/tutorkit/assets/lesson.css`** — the shipped stylesheet, copied into the learning repo on first run. Only the second satellite file in the collection, after `verifykit/verify-assets.sh`; mirror how that skill resolves its own installed directory.
- **`docs/wiki/skills/tutorkit.md`** — **lint errors without this file.** One-line description, bold *Reach for it when*, the summary table (modes · tools · writes · visibility), a `## Modes` section whose `` ### `mode` `` headings match the skill exactly, then the *why*: why one repo beats one per topic, why the index is a cache and what repairs it, why state is Markdown while lessons are HTML, why prediction comes before explanation, why the drill queue is capped and what the cap protects, why a `learned` topic keeps its cues, and why the stylesheet is copied rather than linked. Link siblings as `` [`researchkit`](./researchkit.md) ``, close with the install command and `_Verified against `main`@`<sha>` on 2026-08-18._`
- **`README.md`** — a row in the skills table: teach a topic across sessions from one learning repo, with lessons pitched at what you know and spaced review that makes it stick. Visibility `public`.
- **`skills.sh.json`** — a new **Learning** group containing `tutorkit`.
- **`docs/wiki/workflow.md`** — no edit. Do not write `tutorkit <word>` anywhere in it: lint parses that shape as a mode invocation.
- **`IDEAS.md`** — no edit; `tutorkit` was never on the backlog, so there is no row to graduate.

Mirror while drafting: `skills/validatekit/SKILL.md` (the numbered procedure with reference appendices, the posture section, the artifact-write-on-yes rule), `skills/grillkit/SKILL.md` (the fenced output exemplar followed by the rules that produce it), `skills/promptkit/SKILL.md` (backticked mode headings and the repo-grounding stance), `skills/skillkit/SKILL.md` (quality bar and portability checklist), `skills/verifykit/SKILL.md` (how a public skill reaches a satellite file in its own installed directory).

## Verification

1. `make lint name=tutorkit` — frontmatter marker, `Use when` trigger, resolving intra-doc anchors, no `step N` references, a `## Hand off` section, no portability warnings.
2. `make lint` full run — proves the wiki page exists and its mode headings match the skill.
3. `make security` — confirm the score is not `High`.
4. `make link name=tutorkit`, then **a fresh session**, since the skill list loads at startup and triggering cannot be tested in the session that wrote the skill.
5. Trigger tests that should fire: "teach me how Rust ownership works", "tutor me on Postgres MVCC", "what's due for review today", "quiz me on what I learned last week", "am I ready to call this learned".
6. Near-miss tests that must **not** fire: "explain this function to me" (a code question about the current repo), "research which queue library to use" (`researchkit`), "write docs for this project" (`wikikit`).
7. End to end on a real topic: open a track from zero and confirm `~/learning/` is created with `INDEX.md`, `NOTES.md`, and one topic folder; confirm the lesson HTML opens and links the shared stylesheet; confirm `CUES.md` carries due dates; run `drill` and confirm it reads `REVIEW.md` and opens only the due topic.
8. **Exercise the context guard** — open a second topic, then run a `lesson` on the first and confirm the second topic's folder is never read.
9. **Exercise the fast path** — ask a bare "how does X work" and confirm no directory is created and no index row is written.
10. **Exercise the repair path** — hand-create a topic folder that `INDEX.md` does not list, then confirm the next run rebuilds the index rather than misrouting.
11. **Exercise the drill cap** — hand-write 20 overdue cues across two topics, run `drill`, and confirm it asks 12, orders the most overdue first, and prints the count it left behind. Confirm the overflow keeps its original `due`.
12. **Exercise the grade override** — answer a cue correctly in different words, and confirm the skill offers the override before it writes the step.
13. **Exercise the stylesheet copy** — confirm the first run copies `lesson.css` into the repo, and confirm a second run does not overwrite a hand-edited copy.
14. **Exercise the track close** — with one cue below `60d`, confirm `assess` passes the transfer test and still refuses to write `learned`.
15. `make unlink name=tutorkit`.
16. Leave everything uncommitted; hand over `feat(tutorkit): add tutorkit skill` for the owner to run.

## Open questions

None. The grill on 2026-08-18 closed all six of the original questions and two more that the modes table was hiding — no mode wrote `MISSION.md` or `SOURCES.md`, so nothing opened a track, and mode selection itself was never specified. All nine answers are in [Settled decisions](#settled-decisions) with their reasoning.

Three items were reclassified as drafting details rather than decisions and settled in place: `drill`'s bounded exception to the one-folder routing guard, what happens when cwd is the learning repo itself, and the platform-specific command that opens a lesson.

## Non-goals

- **Not a code writer.** It never implements a feature in the user's project; `implementkit` does that.
- **Not a decision report.** "Which queue library should we use" is `researchkit`, even though both read primary sources.
- **Not project documentation.** It documents nothing about the user's repo; `wikikit` does that.
- **Not a spaced-repetition engine.** A fixed five-step interval ladder, no SM-2 or FSRS tuning, no Anki export, no retention modelling. The schedule exists to make review happen, not to be optimal.
- **Not a general-purpose tutor by design.** It works for any topic and it is tuned for software engineering — repo grounding, runnable exercises, and source-code citations are all sharper there.
- **It does not commit the learning repo on its own.**
