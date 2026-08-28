# implementkit

Implement a plan, spec, or issue into working code — then stop, gated on the repo's own tests and build.

**Reach for it when** you have a settled plan or a groomed issue and want it built, or you have a list of review findings to apply.

| | |
|---|---|
| Modes | straight-through or TDD, resolved by precedence |
| Tools | `Bash`, `Read`, `Grep`, `Glob`, `Edit`, `Write`, `Skill` |
| Writes | application code, and a `(built …)` stamp on the phases it finished — unstaged, never committed |
| Visibility | public |

## What it does

implementkit is the build step between a settled plan and a clean commit. It reads an explicit input, works out *how* to build, writes the code, and proves it with the repo's own test and build gate before calling the work done.

Two hard boundaries define it:

- **It never commits or stages.** Work is left as unstaged changes. Grouping and committing is [`commitkit`](./commitkit.md)'s job, and pre-staging actively fights its grouping.
- **It never designs.** An input too thin to build without inventing the design gets bounced, naming the specific gaps. Bouncing is a success, not a failure — it's the boundary that keeps the skill honest.

**Where a bounce goes depends on *why* the input is thin.** Unresolved decisions route back to [`plankit`](./plankit.md) or [`grillkit`](./grillkit.md). But a design that's unsettled because nobody has *seen it work* — a state model that reads fine on paper, a screen never laid out — won't yield to more interrogation, because the missing input is evidence rather than a decision. That routes to [`prototypekit`](./prototypekit.md), or a deliberate throwaway spike when it isn't installed, and comes back here once the question is answered.

**A plan or an issue can be narrowed to one phase** — "implement phase 3 of `plan-sso-2026-07-23.md`", "implement phase 2 of #42". Both carry phases as headings, which is what makes the narrowing addressable at all, and it's the interface an unattended run uses to build a large issue one phase at a time. The whole document still gets read either way: phases above the named one say what the code may already assume, phases below say what it must not.

## Mode resolution is the defining feature

The same request builds differently depending on whether the repo wants test-driven development. implementkit works that out by a fixed precedence rather than defaulting blindly, taking the first tier that gives an answer:

| # | Tier | How it decides |
|---|------|----------------|
| 1 | **Prompt** | You said so — "do this TDD", "just write it, no tests". Explicit always wins. |
| 2 | **Agent instructions** | The repo's `CLAUDE.md` or equivalent declares a mode or test-first policy. |
| 3 | **Repo habit** | Inferred from the codebase — but only concludes TDD when **both** real test infrastructure exists *and* the repo actually ships tests with features. |
| 4 | **Ask once** | A user is present? Ask once. Non-interactive? Default to straight-through. |

Tier 3 is the interesting one. A lonely `jest.config.js` with tests lagging far behind the code is infrastructure without habit, and that is **not** TDD. The check is whether recent commits touch test and source files together and the ratio is healthy — evidence of practice, not evidence of intent.

Tier 4's non-interactive default matters for unattended runs: TDD is the heavier mode and is never imposed silently.

## The two build modes

### Straight-through

Implement the production code to satisfy the input. Write **no new tests**; run the existing suite as part of the gate. The build and typecheck are the real safety net here, since new code may be uncovered.

### TDD

Strict red → green → refactor, per unit of behavior:

1. **Red** — one focused failing test for the next slice, run it, and confirm it fails. A test that passes before the code exists is testing nothing.
2. **Green** — the minimal production code to pass it.
3. **Refactor** — clean up code and test while the suite stays green.

Either way, it matches the surrounding code's conventions and reuses what exists rather than reinventing it.

A **fix round** — a concrete list of review findings — skips mode resolution entirely. The findings name the defects, so there's no design to invent; the fixes are applied directly and the gate proves them. A fix round also passes the thin-input bar by construction and is never bounced.

## The done-gate

"Done" means the repo's checks are green, not that code was written. The commands are discovered from the repo itself — `package.json` scripts, `Makefile`, `pyproject.toml`, `justfile`, CI config — rather than guessed:

- the **test** command, and
- the **build / typecheck** command, plus **lint** if the repo runs one.

All must pass. If the gate fails, implementkit fixes its own output and re-runs, **bounded to roughly three attempts** — then stops and reports red. It never declares done on a failing gate and never loops indefinitely.

While building, it also typechecks and runs the single affected test file as each slice lands, so breakage surfaces where it's cheap. The full suite is saved for the gate.

## Visual surfaces delegate

When the work includes UI and [`uikit`](./uikit.md) is installed, implementkit applies it to those files rather than writing them blind — uikit carries the project's design constraint and runs its own visual pre-flight. Without it, the UI is written directly. Everything else is unchanged: the input contract, the resolved mode, and the done-gate, which remains the only gate.

## It stamps the phase it built

When the input was a plan file and the gate went green, implementkit appends `(built YYYY-MM-DD)` to the heading of each phase it finished:

```markdown
### Phase 2: auth (#41) (built 2026-08-20)
```

The slot is [`plankit`](./plankit.md)'s, shared with the `(#41)` [`issuekit`](./issuekit.md) writes when it files that phase. Both can sit there at once.

**Why implementkit and not something else:** it's the only skill that knows. A survey tool reading git history has to guess, and a human-maintained status line goes stale — this repo has one that spent weeks announcing "Not yet built" for a skill that had already shipped. The skill that finishes the work is the one that can say so without inferring anything.

Three rules keep the stamp trustworthy. It goes on **only the phases actually built**, so a run narrowed to one phase leaves every other heading alone. It goes on **after the gate passes**, never before, because the stamp is a claim that the work proved out. And it's left **unstaged** like everything else in the run, so commitkit picks up the plan alongside the code that implements it.

It stamps on every run, whatever the project's tracker is. Deciding whether this project files GitHub issues would be a judgment implementkit doesn't need, and keeping that judgment in exactly one skill ([`statuskit`](./statuskit.md)) is what stops four skills drifting into four different answers.

## Hands off to

[`commitkit`](./commitkit.md) to group and commit the unstaged work. implementkit reports the mode used and which precedence tier decided it, the files touched, the gate result, and which phases it stamped — then names the next unbuilt phase, or says the plan is fully built, and stops.

## Install

```sh
npx skills add mimukit/skills -s implementkit
```

Source: [`skills/implementkit/SKILL.md`](../../../skills/implementkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`fb4b4c1` on 2026-08-29._
