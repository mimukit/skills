# namekit

Name a project to a naming convention you already use, then prove the name is free before you commit to it.

**Reach for it when** you have a project and no name, or a name you like and no idea whether anyone else has it.

| | |
|---|---|
| Modes | [`generate`](#generate) · [`check`](#check) |
| Tools | `Bash`, `Read`, `Write`, `AskUserQuestion`, `WebSearch`, `WebFetch` |
| Writes | nothing by default; `docs/names/names-<slug>-YYYY-MM-DD.md` on request |
| Triggering | **explicit only** — model invocation is disabled |
| Visibility | public |

## What it does

Naming is two jobs that get done badly together. The creative half wants range, and a model asked for names returns ten spellings of one idea. The clerical half wants exactness, and nobody runs it until they have already fallen for a name that turns out to be a Series B startup.

namekit splits them and runs them in that order. It mines roots from four separate sources so the candidate set is genuinely plural, joins each one to your convention under a stated rule, and shows you the ranked list. You pick two or three you actually like, and only those go to the registries.

## Why a convention and not a blank page

The owner's projects are `codealoy`, `growaloy`, and `saasaloy`. The suffix is the point: it makes three unrelated products read as one portfolio, and it removes the hardest part of naming, which is the shape.

So namekit is a convention engine rather than a name generator. It resolves your convention from what you say, from names you cite, or from your own repos when you point at them, and it generates against that. There is no config file and no environment variable, on purpose. A convention stored in a dotfile goes stale the day you change your mind, while a convention read from the names you already shipped cannot.

It does not teach the `kit` convention that this collection's own skills use. [`skillkit`](./skillkit.md) owns that rule and states it inline, so namekit points at nothing and repeats nothing.

## Why the names come before the probes

The first version of this skill probed all twelve candidates before printing anything, on the theory that a shortlist you cannot act on is worthless. Two things went wrong in the first real run. RDAP rate-limits a burst and answers 429, so a sweep of sixty names threw away its own domain results. And the whole creative half of the job disappeared behind a wall of registry calls the user never asked for.

So the order is inverted. You see the ranked twelve first, with root, seam, and rubric and no availability column. You pick two or three. Those get probed, nothing else does. A batch that comes back all taken reprints what is left and asks for the next pick, and the pick is always yours.

The verdict itself is still hard. A probe hit removes that name rather than scoring it down, because a taken name is not a slightly worse name. One exception keeps the strict version honest: **a namespace you already own passes, and reads *yours*.** Without it a house convention rejects its own portfolio, and `codealoy` fails on the grounds that `codealoy` exists. namekit resolves your owner from the git remote, or from the repos that sourced the convention, and treats a match as a pass.

The pool stays wide for a different reason now. Twelve candidates feed four or five pick rounds, so the list has to outlast several batches before regenerating is worth it. Regeneration happens only when all twelve are probed and taken, and two passes is the cap.

## Why one web search, at the end

RDAP, npm, and the GitHub API are exact-match lookups against real registries. They are cheap, they are unambiguous, and they miss the thing that actually hurts: a product with your name that never registered the `.com` you wanted, or a live trademark.

A web search catches that, and it is fuzzy enough that running it per candidate returns noise for every short common root. namekit runs exactly one, on the crowned name, after the probes clear it. That is the single point where the answer changes a decision, and a hit re-crowns the next free name.

## Modes

### `generate`

A description in, a ranked shortlist out, then a probe loop you drive. It restates your description back before anything else, so a misread costs one line rather than a whole run.

Then it interviews, every time. That was a deliberate choice over asking only when the description looked thin, because "AI growth platform for SMBs" reads complete and still names no audience, no tone, and no surface the name has to fit. The questions come from a fixed pool of six, it asks only the ones you have not already answered, and it caps at five. The pool's least obvious member is **where the name gets typed**, which sets the length tolerance and decides which probes run at all: a CLI-only tool needs no npm name, and an internal tool needs no domain.

The join is where bad names come from, so the seam gets its own rule in three cases. A **hard join** where the letters do not collide, an **elision** where they overlap (`data` + `aloy` is `dataloy`, never `dataaloy`), and a **reject** where the seam makes a vowel pileup or a syllable nobody says. The cases are about the letters meeting at the join rather than about any one affix, which is what makes the rule hold for a prefix convention too.

Non-English roots are in scope, gated on one test: a single Latin transliteration has to dominate in common use. A root people genuinely spell two ways drops out rather than scoring low, because a name your audience types three ways has failed at the only job a name has.

### `check`

Names in, verdicts out. Same three probes, same owner exception, no generation and no ranking.

It is a mode rather than a step inside `generate` because "is this taken" is a question you arrive with, and folding it in would mean generating a shortlist nobody asked for to answer it.

## What it will not do

It names the thing and stops. No logo, no tagline, no positioning. It reports what it probed and never registers a domain, publishes a package, or creates an org, because those are purchases and namekit does not spend your money. It also skips social handles entirely: headless checks against those platforms are rate-limited, and a false "taken" is worse than no answer.

## Hands off to

[`repokit`](./repokit.md) to set the new repo's About description and topics, or `gh repo create` without it. When the name came out of an idea session, [`ideakit`](./ideakit.md) takes the decision back into that idea's log.

## Install

```sh
npx skills add mimukit/skills -s namekit
```

Source: [`skills/namekit/SKILL.md`](../../../skills/namekit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`d2e9d3b` on 2026-08-24._
