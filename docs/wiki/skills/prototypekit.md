# prototypekit

Build throwaway code that answers a question, fold the answer into the decision, then delete the code.

**Reach for it when** a decision can't be settled by reading — does this state model survive partial refunds, is this library fast enough, what should this screen actually look like.

| | |
|---|---|
| Modes | logic or UI, routed by what's being questioned |
| Tools | `Read`, `Write`, `Edit`, `Glob`, `Grep`, `Bash`, `AskUserQuestion` |
| Writes | throwaway `*.prototype.*` files, deleted at hand-off; one edit to a plan or issue you name |
| Visibility | public |

## What it does

The prototype is an instrument, not a draft. It is not a head start on the real thing, not a demo, and never gets promoted — every rule below exists to keep the code disposable and the answer durable.

That inversion is what separates it from its neighbours:

- **Not the build step.** [`implementkit`](./implementkit.md) turns a *settled* intent into production code behind a test-and-build gate. prototypekit runs when the intent isn't settled *because nobody has seen it work*, writes code that fails every production standard on purpose, and gates on nothing.
- **Not the research step.** [`researchkit`](./researchkit.md) answers from primary sources and refuses to build. prototypekit answers by building and cites nothing. The claims researchkit's sources won't settle land here.
- **Not the UI builder.** [`uikit`](./uikit.md) builds the screen that ships, conforming to the design system. prototypekit's mocks deliberately *break* conformity, because three variants that all conform are three variants of one idea.

## The gate: no question, no prototype

Before a line is written, the skill states **the question** and **the decision it unblocks**, one sentence each. Can't write both, and there's nothing to prototype yet.

This is the load-bearing guard, because the request most often arrives disguised. "Build me a demo", "make a proof of concept for the client", "just try something" — that's production work under a softer name, and it gets **bounced once** with the reason and the route named.

**If you reaffirm, the ask converts — not the skill.** You've made a decision, and arguing twice isn't its job. It says plainly that this is production work and then does it *as* production work: no marker, no exclude entry, no disposal, and it stays on disk. What it will never do is build a demo *as a marked, disposed prototype* — that hands you something to show a client and then deletes it.

## The scope box

The question sets what gets built; the scope box sets when to stop. It names the cases explicitly **in** and explicitly **out**, and it lives in the prototype file's own header comment — in front of you every time you reopen the file, which is exactly where the drift happens.

It exists because the drift is gradual and *feels productive*. A spike that works invites one more case, then error handling, then a component extraction, and the throwaway quietly becomes an app nobody chose to build. A case outside the box is treated as a new decision to agree on out loud, not something to absorb.

## The two modes

### Logic

For a state model, a reducer, a flow, a backend module, or a feasibility question. Two axes decide the shape:

**Does the code already exist?** If it does, the prototype imports the real module and drives it through the project's own runner. This is the only shape that tests the actual code — and it's why prototypes live in the working tree rather than off in a sandbox. **Re-typing logic you already have means the prototype is testing your typing.** If it doesn't exist yet, one self-contained file: for the web, HTML with no build step and no server, so it opens on a double-click and sends as a single attachment to someone without the repo.

**Who reads the output?** A human clicking gets **free-play controls** covering every transition plus **guided walkthroughs** that push the model through the specific hard cases in question, with full state rendered after every action — a non-developer has to be able to drive it, because "does this feel right" is often a question only a non-developer can answer. A number or a log gets a script that prints the measurement *and the conditions it was taken under*, since a number with no conditions attached isn't evidence.

### UI

**Three structurally different variations on one route**, switched by a URL search param with a small floating switcher. One route means one dev-server start covers all of them, and each variant has a link you can send someone.

**Divergence is the deliverable, and it's the part that actually fails.** Every variant must differ on a **structural axis — layout, information hierarchy, or interaction model — and must name the axis it takes.** Differing on color, spacing, or corner radius is a recolor. Three variants of one idea is a failed prototype: the effort is spent and there's still nothing to choose between. Fewer than three ships only when three genuinely distinct axes can't be named, and it says so rather than padding the set.

When [`uikit`](./uikit.md) is installed it borrows the anti-slop catalog and accessibility floor, but **overrides the design-system precedence for this job only, and says so out loud** — that precedence enforces conformity, and conformity is the opposite of what a variant set is for.

A winner is **evidence, not a starting point.** Building it for real is a fresh job against the real files, at full conformity, from scratch.

## Disposal is structural, not a cleanup step

Three mechanisms keep the code from surviving its usefulness, and the ordering between them is the point.

**The marker comes first.** Every file is named `*.prototype.*` and every directory `*.prototype/` — not cosmetic, but the thing the exclude entry matches. An unmarked prototype is one `git add -A` away from `main`.

**The exclude entry is registered before the first file exists**, and it goes in the repo's *private* exclude rather than the tracked `.gitignore`. A tracked ignore edit is itself an uncommitted change that commit and review tooling would pick up — the skill would leave a diff behind while claiming it left nothing. The path is resolved with `git rev-parse --git-path info/exclude` rather than hardcoded, because in a linked worktree `.git` is a file and the literal path doesn't exist.

**Deletion is confirmed per file**, and only for files created in that session. This isn't ceremony: an excluded file is untracked, so git cannot recover it — the delete is final in a way most deletes aren't. A park onto a throwaway branch is offered first, off by default. Anything you keep is reported by absolute path with its exclude line left in place, which is what keeps a leftover local-only and findable instead of quietly commit-able.

## The verdict

Four lines — question, built, showed, answer. **Built** is written straight from the scope box, naming the cases driven and transitions covered, and that specificity is what makes the answer durable without keeping the code. It's what someone needs six weeks later when the decision gets relitigated.

It lands in whatever asked the question. For a plan document that means **striking the open question and adding a row to the settled-decisions section** — prototypekit's one edit to a tracked file, deliberate, and only ever to a file you named. Leaving an answered question under "Open questions" would misrepresent the plan's state to everything downstream that reads it.

**When the prototype answers a *different* question than the one asked, it reports and stops.** Chasing the new question mid-run is the exact drift the scope box exists to catch, wearing a justification — and you may not want it chased at all. The one carve-out: a finding that *invalidates the premise* of the asked question is itself the answer.

## Never unattended

The deliverable is a human judgment, so a run with nobody watching produces a deleted file and an answer nobody read. It sits outside [`afkkit`](./afkkit.md)'s span for the same reason [`validatekit`](./validatekit.md) and [`researchkit`](./researchkit.md) do, and the per-file delete confirmation makes that structural rather than advisory.

`allowed-tools` withholds web search and fetch — the mirror of how researchkit withholds the shell. A question that turns out to be settleable from documentation is a research job, and the missing tools make the boundary hold on hosts that honor the field.

## Hands off to

Whatever the answer unblocks: [`plankit`](./plankit.md) or [`grillkit`](./grillkit.md) to fold a settled decision forward, [`uikit`](./uikit.md) to build a winning variant for real, or [`domainkit`](./domainkit.md) to record a hard-to-reverse trade-off as an ADR. The mock is never promoted.

## Install

```sh
npx skills add mimukit/skills -s prototypekit
```

Source: [`skills/prototypekit/SKILL.md`](../../../skills/prototypekit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`73826b0` on 2026-08-07._
