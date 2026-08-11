# refactorkit

Survey an existing codebase for the structural change worth making — shallow interfaces, adapter sprawl, poor locality, untested coupling — rank the candidates, crown one, and write it up as a reviewable proposal.

**Reach for it when** you're sitting in a brownfield repo that's become hard to change and you want one defensible answer to "where do I actually cut?"

| | |
|---|---|
| Modes | single procedure, optionally scoped (`/refactorkit src/payments`) |
| Tools | `Bash`, `Read`, `Grep`, `Glob`, `Write`, `Task`, `Agent` |
| Writes | `docs/refactor/refactor-<slug>-YYYY-MM-DD.md` — durable, committable, never committed by the skill |
| Visibility | public |

## The gap it fills

The other kits either look at a *change* or look *forward*. [`reviewkit`](./reviewkit.md) reads a diff for defects in work somebody just did. [`wikikit`](./wikikit.md) describes the architecture as it stands. [`domainkit`](./domainkit.md) records decisions after they're made. [`plankit`](./plankit.md) starts from an idea rather than from the code.

refactorkit is the survey step none of those cover: read the tree you already have, find where its *structure* is costing you, and come out with a single proposal worth arguing about.

## The name promises more than the skill does

It's called refactorkit and it never refactors anything. That's deliberate, and it's the most important thing to know before reaching for it.

**It writes exactly one Markdown file and touches no source.** No moves, no renames, no extractions, no tidy-up in passing. A survey that also edits has already decided, and what you'd be reading is a rationalization rather than a recommendation — the argument and the change would arrive together, with no moment in between where you could disagree.

The enforcement is as cheap as it gets: `Edit` is simply absent from the skill's `allowed-tools`. The one file it produces is new, so `Write` covers it and nothing in the tool set can modify code that already exists. The doing belongs to [`implementkit`](./implementkit.md), once the shape is settled.

The functional word still leads the name because that's what anyone searches for — nobody types "architecture survey kit." The boundary is stated in the skill's own first paragraph rather than hidden in the name.

## Why the pattern set is closed

refactorkit looks for exactly four things — shallow interface, adapter prevalence, untested coupling, poor locality — and looks for nothing else.

The closure is the feature. An open-ended hunt for "problems" is something the base model will happily do without a skill, and it produces the same list every time: the codebase has some duplication, some functions are long, error handling is inconsistent, consider extracting a service. That output is indistinguishable across repos, which is the tell that nothing was actually read. Four named patterns, each reducing to the same underlying question about depth, force every finding to be *about this codebase* or not exist.

**The signals are written as shapes, never as names.** No hunting for `*Mapper`, `*Adapter`, or `*DTO`. Those suffixes are conventions from one or two language communities and are meaningless in a Go, Rust, Elixir, or PHP repo — and worse, a named example is exactly what an agent pattern-matches on instead of reading. So the skill describes the *structure* ("a unit whose members each forward to exactly one member of one other unit") and has the agent derive the repo's own naming conventions first.

## Why the deletion test gates the list

Two gates run before a candidate is listed at all, and failing either one means silent discard — not a weaker finding, not a caveat.

**The deletion test** asks: if this module vanished and its callers absorbed it, does complexity *concentrate* where it belongs, or merely *relocate*? Relocation is churn wearing a refactor's clothes. It's also the majority of what an unguarded scan produces, because moving code around always looks like progress and nothing in the code itself objects.

**Interface as test surface** asks: after the change, can the behaviour be tested through the new interface alone, without reaching inside? A no means the seam is in the wrong place, which makes the candidate *unfinished* rather than merely modest.

Both verdicts are mandatory on every listed candidate, with a sentence of evidence each. A record that arrives without them is dropped rather than repaired — repairing it in the main session would mean asserting a verdict about code that session never read, which is the exact failure the gates exist to prevent.

## Why poor locality is the one pattern the fan-out can't own

The expensive half of the survey is reading code, and it parallelises cleanly: churn ranks the files, the hot ones cluster into three to five coherent areas, and one subagent takes each. Each agent runs the gates itself and returns a **fixed record** — pattern, files, proposed shape, both gate verdicts, blast radius, strength — because the main session has to rank findings it never gathered, and freeform prose can't be ranked without re-reading everything the agent read, which throws away the whole reason to fan out.

Poor locality is the exception, and it's a structural one. It means *files that keep changing together while living apart* — so an agent looking at one area is definitionally blind to it. Whatever it finds within its own slice isn't the pattern; the pattern is the pairs that cross slices. Hand it to an area agent and it is guaranteed never to be found.

So it stays in the main session, derived from the co-change pairs that the churn read already produced. It costs no extra file reads, which is a pleasant accident rather than the reason.

**Without a subagent tool, the skill scans the top churn slice inline** and says which path the run took. For a public skill installed into arbitrary environments that fallback is a large share of runs, not an edge case — so it's a real mode with a real coverage claim rather than a degraded apology.

## Nothing found is a real answer

When no candidate clears the gates, refactorkit says so, names its coverage, and **writes no file**.

A survey obliged to produce findings will manufacture them, and manufactured architecture advice reads exactly like the genuine article — same vocabulary, same confidence, same shape as something that came from reading the code. The deletion test is only a real gate if "nothing here" is a legal outcome, so it is one.

That's also why **every report carries a coverage line** — *"ranked 1,240 files by churn, read the top 40 across 4 areas"* — in the terminal and in the file. A cap nobody can see is a lie about completeness, and it's the difference between "there's nothing structurally wrong here" and "I looked at 3% of it."

## Strength is defined, not felt

Three levels, each pinned to evidence: `strong` (both gates pass, files in the churn top slice, blast radius named in actual files), `moderate` (both gates pass, but the code is cold or the radius is wide), `weak` (gates pass, but the win is stylistic).

`weak` is **never crowned**, whatever else is on the list — including when it's the only thing there. An undefined badge is a vibe wearing a label, and strength is the one column a reader trusts without checking the row it came from.

## Read-only shell, and only that

git history, file reads, greps. The skill never installs or runs an analysis tool to generate evidence — no dependency-graph pass, no dead-code scan, no coverage run. Probing for a tool and parsing its output couples the skill to a format that changes on a minor release, which is the brittle coupling that breaks a skill quietly a year later.

If such an artifact is already sitting on disk, refactorkit reads it. It just never creates one.

## Hands off to

[`grillkit`](./grillkit.md), on the crowned candidate. The write-up is already plan-shaped — problem, proposed shape, blast radius — so what it lacks is interrogation rather than drafting, and grilling it is what turns a proposal into something safe to build from. In a repo without the ecosystem the move is the same one stated plainly: interrogate the assumptions, the failure paths, and the blast radius yourself before anybody starts.

Runners-up: [`domainkit`](./domainkit.md) when the proposal supersedes an existing decision record, and [`implementkit`](./implementkit.md) once the shape is settled. On an empty result it says there is no next move rather than inventing one.

## Install

```sh
npx skills add mimukit/skills -s refactorkit
```

Source: [`skills/refactorkit/SKILL.md`](../../../skills/refactorkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`44c225d` on 2026-08-11._
