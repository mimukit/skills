# implementkit

Implement a plan, spec, or issue into working code — then stop, gated on the repo's own tests and build.

**Reach for it when** you have a settled plan or a groomed issue and want it built, or you have a list of review findings to apply.

| | |
|---|---|
| Modes | straight-through or TDD, resolved by precedence |
| Tools | `Bash`, `Read`, `Grep`, `Glob`, `Edit`, `Write` |
| Writes | application code — unstaged, never committed |
| Visibility | public |

## What it does

implementkit is the build step between a settled plan and a clean commit. It reads an explicit input, works out *how* to build, writes the code, and proves it with the repo's own test and build gate before calling the work done.

Two hard boundaries define it:

- **It never commits or stages.** Work is left as unstaged changes. Grouping and committing is [`commitkit`](./commitkit.md)'s job, and pre-staging actively fights its grouping.
- **It never designs.** An input too thin to build without inventing the design gets bounced back to [`plankit`](./plankit.md) or [`grillkit`](./grillkit.md), naming the specific gaps. Bouncing is a success, not a failure — it's the boundary that keeps the skill honest.

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

## Hands off to

[`commitkit`](./commitkit.md) to group and commit the unstaged work. implementkit reports the mode used and which precedence tier decided it, the files touched, and the gate result — then stops.

## Install

```sh
npx skills add mimukit/skills -s implementkit
```

Source: [`skills/implementkit/SKILL.md`](../../../skills/implementkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`fd96414` on 2026-08-07._
