# tutorkit

Teach a topic across many sessions — one learning repo with a folder per topic, lessons pitched at what you already know, and spaced retrieval that makes it stick.

**Reach for it when** you want to end up *knowing* something rather than getting past it — and you're tired of re-explaining what you already learned to a session that has never met you.

| | |
|---|---|
| Modes | [`status`](#status) · [`explain`](#explain) · [`lesson`](#lesson) · [`drill`](#drill) · [`exam`](#exam) |
| Tools | `Bash`, `Read`, `Write`, `Edit`, `Grep`, `Glob`, `WebSearch`, `WebFetch`, `AskUserQuestion`, `Task`, `Agent` |
| Writes | a learning repo at `~/learning` (`$TUTORKIT_HOME` overrides) — HTML lessons, Markdown state; nothing in `explain` or `status` |
| Triggering | **explicit only** — model invocation is disabled |
| Visibility | public |

## What it does

Every other skill in this collection assumes you already know the thing and helps you do it faster. [`researchkit`](./researchkit.md) hands you a decision, [`wikikit`](./wikikit.md) describes a project, [`debugkit`](./debugkit.md) finds a cause. None of them build durable knowledge in the person operating them, and none of them remember what you knew last week.

tutorkit is the one that does. It keeps a picture of what you know, pitches the next thing at the edge of it, and comes back later to check whether it stuck.

The name is the design. A tutor is by definition someone who remembers you and adapts; a teacher delivers a lesson and needs no memory. Persistence is not a feature bolted onto this skill — it's the reason it exists, so the name carries it.

## Why one repo, not one per topic

A repo per topic is the obvious layout and it breaks the two mechanisms that matter.

**Drill is cross-topic by nature.** Mixing cues from different subjects in one session — interleaving — is most of what makes retrieval practice work. With one repo per topic, a drill run would have to open every repo you own to find what's due. The parent repo exists so it doesn't have to.

**Interleaving needs more than one topic in view at all**, which per-topic isolation structurally prevents. A registry file that lists the repos to avoid opening them all is just the parent repo with extra steps.

So: one git repo, `topics/<slug>/` inside it, initialized on creation. The history is genuinely useful — `git log` over Markdown state is a record of what you learned and when. tutorkit still never commits on its own; it offers at the end of a session and takes no for an answer.

## Why the index is a cache, and what repairs it

`INDEX.md` is the router, and it's the whole context story. Thirty topics costs about sixty lines to route. Opening all thirty costs tens of thousands of tokens.

So the load-bearing rule is: read `INDEX.md`, resolve **exactly one** slug, open **only** `topics/<slug>/`. Never glob across `topics/`. Without that rule the skill gets slower as you learn more, which is precisely the wrong direction for a thing whose job is to accumulate.

`REVIEW.md` is the same trick for due dates — one row per topic (`2026-08-18 · postgres-mvcc · 4 due`), never per cue. Storing the cue text there would duplicate answers that already live in `CUES.md` and let the two drift.

**Both files are caches, and a cache with no repair path rots silently.** One hand edit — a folder renamed, a row deleted — and the router misroutes forever with no error. So tutorkit rewrites the affected row whenever it touches a topic, and rebuilds both by scanning `topics/` the moment it finds a folder they don't list.

`drill` gets a bounded exception to the one-folder rule: it resolves its slugs from `REVIEW.md` rather than from the ask, then opens the `CUES.md` of due topics only. Never their lessons, never a glob. Interleaving needs more than one topic in view; it doesn't need more than one file per topic.

[`status`](#status) is the stricter case, and the one that proves the design. It reports on every topic you have and opens none of them, because the routers already hold what a dashboard needs.

## Why state is Markdown and lessons are HTML

The split is revisit-versus-rewrite.

You print a lesson, annotate it, and re-read it months later. That earns HTML — real typography, sidenotes, a printable page. The agent rewrites state every single session, so state stays Markdown and diffable. State in HTML would make `git log` useless for tracking progress, which is the main reason the repo is a git repo at all.

## Modes

### `status`

The front door. It answers "where am I with all of this," which is the question you actually have when you sit down after two weeks away and can't remember what you'd started.

It teaches nothing, asks nothing, grades nothing, and writes nothing. What it prints is one screen: every active track with its due count and last-touched date, how many cues are waiting across all of them, and a single crowned next move.

**The interesting constraint is that it opens no topic folder at all.** A cross-topic dashboard is exactly the read the one-folder rule exists to prevent, so `status` gets its answer entirely from `INDEX.md` and `REVIEW.md`. That's only possible because those two files already carry every column the table prints. It's the cleanest evidence the cache design was right: the mode that reports on thirty topics costs the same as the mode that reports on one.

That constraint did cost one field. Crowning `exam` means knowing a track's cues have all reached `60d`, which used to require reading its `CUES.md`. So `REVIEW.md` rows now carry `min step`, the lowest interval any cue in that topic has reached, and the row reads `2026-08-18 · postgres-mvcc · 4 due · min step: 3d`. It's the minimum rather than an average because the closing gate is *every* cue at `60d`, and one cue at `1d` fails it.

**Its ranking rule is retrieve-before-you-add.** Due cues outrank a new lesson, because a cue decays while it waits and a lesson doesn't. Ties go to the most recently touched track, since that's where your model is warmest and re-entry is cheapest.

Two things get surfaced and never crowned, because both are your call rather than a move the skill can defend: a track gone stale at 30 days untouched, and more than five active tracks at once. The second is the real failure mode. Starting a sixth track feels like progress, and attention doesn't scale with the number of things you've decided to learn.

**It writes no snapshot file, which is where it parts company with [`statuskit`](./statuskit.md).** statuskit saves one because a repo dashboard is a ranked to-do list that exists nowhere else, and its ticked boxes are the user's own annotation. Here every fact on the screen is already durable in the learning repo, and a saved copy would go stale the moment the next `drill` run moved a due date. A third cache with no reader is just a thing to keep honest.

### `explain`

The fast path, and the reason tutorkit isn't a commitment. "How does Postgres MVCC work" should not open a track.

It writes **nothing** — no folder, no index row, no mission interview. Shortest correct answer first, then the mechanism, then one worked example, then a primary source. It offers a track **once** at the end and takes no for an answer. A second offer would turn the fast path into the thing it exists to avoid.

**Mode selection resolves on intent, not phrasing.** "Explain how X works" and "teach me X" are weak signals — people say both for both. A question that wants an answer is `explain`; a request that wants to end up knowing the thing is `lesson`. When it's genuinely ambiguous, tutorkit takes the cheap branch: guessing `lesson` costs a mission interview you didn't want, guessing `explain` costs one extra sentence.

### `lesson`

The core loop, and **the only mode that opens a track**. That's a deliberate consolidation: a separate `track` mode would make "teach me X" a two-step ask, which is exactly the friction `explain` exists to avoid.

On an unknown slug it runs a short mission interview, writes `MISSION.md`, seeds `SOURCES.md`, creates the folder and the index row, then teaches. On a known slug it routes, reads progress, and picks the target.

**Predict before you explain** is the highest-value thing in the skill. Before teaching a mechanism, it poses a concrete scenario and makes you commit to a prediction. A wrong prediction names your broken mental model — and that model is the real teaching target, because a wrong belief actively blocks the correct one in a way a gap does not. Teaching without it is teaching blind.

**Repo grounding is the largest differentiator**, and the thing a browser-based tutor structurally cannot do. When cwd is a real project, tutorkit asks **once** whether it may read it, records `grounding: <repo path>` or `grounding: declined` in `MISSION.md`, and never asks again for that topic. One prompt buys the whole track; a prompt that fires every lesson gets switched off. Consent is scoped to the repo, so a different cwd later asks again. Then the example gets built from your own code — a lesson on dependency injection written against your actual service container beats one written against `FooService`.

The lesson closes on an **explain-back gate**: it doesn't end until you restate the concept in your own words. That retrieval is what converts fluency into storage strength, and it's the cheapest possible check that anything landed.

### `drill`

Retrieval practice, interleaved across topics, **capped at 12 cues per run**.

The cap is the part worth defending. An uncapped queue is what kills every spaced-repetition system ever built — you come back after two weeks, see forty cues, and stop opening it. Twelve is openable. Sorting `due` ascending then misses descending stops the oldest cue starving behind newer ones.

And it **prints what it left**: `12 of 41 · 29 still due`. Hiding the backlog is only a nicer way to lose it. The overflow **keeps its original `due`** rather than being pushed to tomorrow, so it stays first in line instead of having its debt quietly rescheduled.

Answers are graded on three levels against 2–3 stored key points, never two. Binary grading forces a wrong call on the half-right answer, and the half-right answer is most answers. `partial` repeats at the same interval and absorbs the ambiguity instead of resolving it wrongly in either direction.

**The override is offered on every grade, not just misses.** The entire interval ladder runs on that one judgement, so you have to be able to correct it — most often when you gave a correct answer in words the key points didn't anticipate.

### `exam`

Measures and refuses to teach. Two entry points, one posture — ask, grade, record, explain nothing. Splitting them into two modes would name a presentation difference as a behavioural one.

**The name is doing work against `drill`.** Both modes ask you questions, and that's the one place the mode set could genuinely confuse you at the moment you're picking one. You drill to practice and you sit an exam to be measured, so the pair carries its own distinction: `drill` repeats a cue for months and a miss costs you one reset, while `exam` runs twice per track and its verdict decides where lesson 1 starts or whether the track closes. It was called `assess` first, which is accurate and describes a thing nobody says out loud.

**At track start it places you**: 3–5 scenario predictions, broad to narrow, stopping early on two consecutive misses. This reuses the prediction device the skill already owns rather than inventing a second assessment mechanism. Self-report is the weakest signal available, and a single transfer problem fails a genuine beginner flat on first contact. The wrong predictions it surfaces become lesson 1's target.

**At track end it runs a transfer test** — a problem you haven't seen that needs the concept without naming it. Solving only the taught shape means you learned the surface.

## Why a topic needs both gates to close

`learned` requires the transfer test **and** every cue at step `60d`. Either gate alone is a lie in a different direction.

The transfer test alone would close a topic whose cues still sit at `1d` — you solved it today, which says nothing about next month. Cues at `60d` alone measure recall of the shapes you were taught, which the skill itself calls learning the surface.

And a `learned` topic **keeps its cues**. Retiring them at close is exactly the moment forgetting starts. They keep coming due — but `drill` fills its twelve slots from `active` topics first and lets `learned` cues take what's left, so a finished track can never crowd out a live one.

## Why there's no decay for lateness

A cue can sit 30 days past due because of the cap. That backlog is the skill's debt, not yours, so a decay rule would punish you for tutorkit's own queue management. A miss resets to `1d` and that's the only penalty.

One schedule rule is easier to reason about than two, and the `partial` grade already absorbs most of what a decay rule would catch. `CUES.md` carries a `last_seen` column instead, so the drill line can show "last seen 34 days ago" and let you override the grade with the fact in view.

## Why the stylesheet is copied, not linked

`assets/lesson.css` ships beside the `SKILL.md` and gets copied into the learning repo on first run — **once, never overwritten**.

Linking the installed path would break every lesson you've ever written the moment the skill moves or is uninstalled. Generating the CSS per install would make lessons render differently on every machine. Copying once means a later skill update ships a new default for new repos and leaves existing lessons rendering the way they were written.

It's the second satellite file in the collection, after [`verifykit`](./verifykit.md)'s `verify-assets.sh`, and it resolves the same way: find the installed skill directory, because cwd is your project, not the skill's.

## Why old lessons are never rewritten

`MISSION.md` is **append-only**, under dated `## YYYY-MM-DD` headings. When your reason for learning something drifts, that's a new entry, not an edit.

Re-pitching would rewrite files you may have printed and annotated. Archiving would hide work you did and break the sibling anchors between lessons. Instead every lesson names the dated mission entry it was written against, so a lesson written under a superseded mission reads as **dated rather than wrong**.

## What it is not

- **Not a code writer.** It reads your code to build examples and stops. [`implementkit`](./implementkit.md) implements.
- **Not a decision report.** "Which queue library should we use" is [`researchkit`](./researchkit.md), even though both read primary sources.
- **Not project documentation.** It documents nothing about your repo; that's [`wikikit`](./wikikit.md).
- **Not a spaced-repetition engine.** A fixed five-step ladder — `1d → 3d → 7d → 21d → 60d` — with no SM-2 or FSRS tuning, no Anki export, no retention modelling. The schedule exists to make review happen, not to be optimal.
- **Not general-purpose by design.** It works for any topic and it's tuned for software engineering, where repo grounding, runnable exercises, and source-code citations are all sharper.
- **It never commits the learning repo on its own.**

## Hands off to

tutorkit is largely terminal, and it says so rather than inventing a follow-up. Its crowned next move is usually another tutorkit run, chosen by state: `drill` when cues are due, the next `lesson` when the track is mid-flight, `exam` when every cue has reached `60d`. When a track closes as `learned`, there is no next step. [`status`](#status) is that same routing rule made available on demand, so you can ask for the next move without starting a session first.

It doesn't route to [`statuskit`](./statuskit.md) and statuskit doesn't route here. They survey different repos, rank on different rules, and neither can read the other's state. A learning ladder and a finish-first ladder share a shape and nothing else.

Two sibling routes exist and both are narrow. [`researchkit`](./researchkit.md) when the question turned out to be a tool decision rather than a knowledge gap. [`prototypekit`](./prototypekit.md) when the only honest answer is to go build the thing and find out.

## Install

```sh
npx skills add mimukit/skills -s tutorkit
```

Source: [`skills/tutorkit/SKILL.md`](../../../skills/tutorkit/SKILL.md)

_Verified against `main`@`d2e9d3b` on 2026-08-24._
