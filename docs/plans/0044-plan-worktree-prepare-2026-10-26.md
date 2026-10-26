# Plan: Worktree prepare and teardown in gitkit
Grilled: 2026-10-26

## Context

A new worktree is a bare checkout. Before anyone can review or build in it, someone has to install the dependencies, create a dev database for that worktree, migrate it, and seed it. Today only mergekit `start` does part of this: its step 4 (`skills/mergekit/modes/start.md`, "Set the project up") infers the install from the lockfile and starts the app. issuekit `start` does none of it, so afkkit and implementkit inherit a worktree with no dependencies and no database. Nothing drops a per-worktree database when the worktree goes, so the databases outlive their branches.

primeshopr shows the shape a real repo already has. Its README and AGENTS.md declare `pnpm db:setup --server` (create this checkout's database, named `primeshopr_dev_<branch>`, and migrate it), `pnpm db:seed` (an upsert, safe to re-run), `pnpm db:drop`, and `pnpm db:prune` (drop every database whose branch is gone). The repo owns the naming. What is missing is a skill that knows when to run these commands.

Goal: a worktree that issuekit `start` or mergekit `start` hands over is ready to run, with its own database when the repo has one, and gitkit's removal drops that database. The owner runs no setup command by hand.

Target: no number fits, because this is a skill text change. The check is that `make lint` passes and each phase's rules read as testable steps in the files they touch. A live run on a real repo is left to normal use (Q15).

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Owner of prepare and teardown | gitkit. It already owns the worktree lifecycle, and every removal in the collection goes through its [Remove](../../skills/gitkit/SKILL.md#remove) rule (gitkit `clean`, issuekit `close`, mergekit `close`, orcakit `clean`, paseokit `clean`). One teardown step there reaches every caller. |
| gitkit invents no commands | gitkit runs only what the repo declares, plus the install a lockfile implies. It never names a database, picks a port, or guesses a seed command. gitkit decides *when*, the repo decides *what*. |
| Q1. Where the repo declares the commands | A `## Worktree setup` section in the repo's agent-guide file (`AGENTS.md`, else `CLAUDE.md`). Fixed labels, each followed by one fenced block: `setup:` (required), `update:` (optional), `teardown:` (optional), and `watch:` (optional, one glob per line). A block may call a repo script, such as `./scripts/worktree-setup`. This matches how qakit finds a declared disposable target. |
| Q2. A repo that declares nothing | gitkit runs only the install the lockfile implies (`pnpm-lock.yaml` → `pnpm install`, `uv.lock` → `uv sync`, and so on). There is no database step. The report says "lockfile install only, no worktree setup declared" and prints the section template. With no lockfile either, prepare reports that and does nothing. |
| Q3. Adopted worktree | Prepare re-runs when a watched path changed between the marker's SHA and `HEAD` (`git diff --name-only <sha> HEAD`). Otherwise it skips and reports the SHA and how far `HEAD` moved. An explicit "prepare again" always re-runs. |
| Q12. Watched paths | The lockfiles are always watched. `watch:` adds the repo's own globs, such as `packages/db/drizzle/**`. gitkit keeps no built-in list of migration directories. |
| Q13. What re-runs on a change | The `update:` block when declared, otherwise the full `setup:` block. The template states that `setup:` must be safe to re-run. Example for primeshopr: `update:` is `pnpm install && pnpm --filter @repo/db db:migrate`, so a change never re-seeds over a reviewer's test data. |
| Q14. After gitkit `sync` | When `gitkit-prepared` exists, the sync runs the Q3 change check after it takes commits, and it runs `update:` (or `setup:`) when a watched path changed. This covers mergekit `fix` and the "start and sync" opt-in through the same rule. |
| Q5. Untracked files such as `.env` | The repo's own commands copy them. gitkit exports `GITKIT_REPO` (main checkout), `GITKIT_WORKTREE`, and `GITKIT_BRANCH` to every declared block. gitkit never reads or copies a secret file. Example: `cp "$GITKIT_REPO/apps/api/.env" apps/api/.env && pnpm db:setup --server`. |
| Where the procedure lives | A satellite `skills/gitkit/prepare.md`. The root gets one row in the mode table, one pointer at the end of [Create, or adopt](../../skills/gitkit/SKILL.md#create-or-adopt), one teardown line in Remove, and one line in `sync`. debugkit and afkkit cut scratch worktrees with plain `git worktree add` and never reach it. |
| Ownership marker | gitkit writes `gitkit-prepared` in the worktree's admin directory, next to `gitkit-created`, after a `setup:` or `update:` that exits 0. The file holds the `HEAD` SHA of that run. Teardown runs only when the marker exists, so gitkit never drops a database it did not create. |
| Order inside a removal | Teardown runs from inside the worktree, before `git worktree remove`, because the declared command and its scripts live there. A dirty worktree still stops the removal first, so teardown never runs on a worktree that stays. |
| Q6. Teardown fails | gitkit keeps the worktree and reports the command and the last lines of its output. A removed worktree would lose the only handle on the orphan database. (defaulted) |
| Q4. Merged-PR exception | Teardown runs with no prompt when `gitkit-prepared` exists. The marker proves gitkit ran the setup, and the merge instruction covers the removal. The hand-off names the teardown command and its exit code. |
| mergekit `start` sync | Opt-in only: "start 34 and sync". The ask is the consent, as in gitkit `sync`. `start` hands the sync to gitkit before prepare, so the install matches the synced lockfile. A fork PR refuses the opt-in at setup time. A plain `start` still never syncs. |
| Callers keep a fallback | mergekit `start` keeps one line: without gitkit, run the repo's declared `setup:`, else the lockfile install. issuekit `start` already stops without gitkit. issuekit `close` and mergekit `close` add one line each: without gitkit, run the declared `teardown:` before the removal. |
| Q11. afkkit and a failed prepare | Escalate and keep `in-progress`, with the failed command's output commented, as afkkit already does for an execution gap. Prepare is part of "acquire the worktree through issuekit `start`", so the run's existing authorization covers it. (defaulted) |
| Q10. The section template | gitkit's "no worktree setup declared" report prints the template. repokit does not change. (defaulted) |
| Q15. Live check | No live-check phase. `make lint` is the check, and the first real run happens in normal use. |

## Approach

The recommended approach adds a `prepare` mode to gitkit and a teardown step to its Remove rule, then points the two `start` modes at it. It reuses gitkit's ownership-marker pattern (`gitkit-created`, `branch.<b>.gitkitCreated`), its idempotent create-or-adopt, its "return the path to the caller" contract, and qakit's declared-target precedent.

Rejected alternatives, one line each:

- **Minimal: extend mergekit `start` step 4 only.** Smallest diff, but issuekit `start` and afkkit still get a bare worktree, and nothing drops the database.
- **Lateral: a repo-managed git `post-checkout` hook.** git fires it on `git worktree add`, but git has no hook for worktree removal, the hook fails silently, and an agent cannot see that it ran.
- **A new shared skill.** Fails the AGENTS.md gate: the agent makes this choice from context, and the human would not choose it on its own.

### Phase 1: gitkit prepare and teardown

- Write `skills/gitkit/prepare.md`. It finds the `## Worktree setup` section, exports the three `GITKIT_*` variables, and runs `setup:` inside the worktree on a first prepare. On a later prepare it runs the change check against the marker SHA and runs `update:` (else `setup:`) on a change. It writes the marker with the `HEAD` SHA on exit 0 and reports each command and its exit code. A failed command stops prepare and reports the command and the last lines of its output.
- In `prepare.md`, cover the undeclared repo: the lockfile install, the "no worktree setup declared" line, and the section template with all four labels and the "safe to re-run" rule for `setup:`.
- Add the `prepare` row to the mode table, and add a trigger to the description ("set up this worktree", "make this worktree's dev database").
- End Create, or adopt with a pointer to prepare for callers that hand a worktree to a person or an agent.
- Add the teardown line to Remove: when `gitkit-prepared` exists, run `teardown:` from inside the worktree before `git worktree remove`. A failed teardown keeps the worktree. The merged-PR exception runs teardown with no prompt. Add one sentence to `clean.md` that names the step.
- Add one line to `sync`: after it takes commits on a prepared worktree, run the prepare change check.

Done when: `prepare.md` exists with the declared, undeclared, adopt, and change-check paths. Remove names the teardown step, its marker condition, and its failure rule. `sync` names the change check. `make lint` passes.

### Phase 2: mergekit start

- Replace the install half of step 4 in `skills/mergekit/modes/start.md` with a call to gitkit `prepare`. Keep the app start and its observable result, and keep the one-line fallback without gitkit.
- Add the "and sync" opt-in to step 3: hand the sync to gitkit, refuse it on a fork PR, and report the outdated thread count.
- Update `skills/mergekit/SKILL.md:62`, which says only `fix` syncs, so it names the opt-in.
- Update the hand-off: report what prepare ran, and whether a sync ran on request.
- Add the teardown fallback line to `skills/mergekit/modes/close.md` step 7.

Done when: `start.md` calls gitkit `prepare`, step 3 names the opt-in and the fork refusal, `close.md` names the teardown fallback, and `make lint` passes.

### Phase 3: issuekit start and afkkit

- Add a step to `skills/issuekit/modes/start.md` after the worktree step: call gitkit `prepare`. An unattended caller gets the prepare result returned with the path.
- Report the prepare result in issuekit's `start` hand-off.
- Add the teardown fallback line to `skills/issuekit/modes/close.md` step 4.
- In `skills/afkkit/SKILL.md`, name a failed prepare as an execution gap that escalates and keeps `in-progress`, and state that the run's authorization covers prepare.

Done when: issuekit `start` calls prepare, issuekit `close` names the teardown fallback, afkkit names the prepare-failure route, and `make lint` passes.

### Phase 4: collection docs

- Update `docs/wiki/workflow.md` where it maps issuekit `start` and mergekit `start` to gitkit.
- Run `make cheatsheet` if the gitkit what-clause changed.

Done when: `make lint` passes with the regenerated cheatsheet.

## Open questions

None. Every question from the draft was settled in the grill on 2026-10-26.

## Non-goals

- gitkit names no database, picks no port, and writes no setup script for a repo.
- No vendor setup formats (T3 Code project scripts, Orca setup hooks, Conductor config). gitkit reads the repo's agent-guide file only.
- No orphan sweep. gitkit `clean` runs no declared `prune:`; primeshopr's `pnpm db:prune` stays a manual command. (Q8, defaulted)
- No qakit link. Declaring the worktree database as qakit's disposable target changes qakit's safety rule and needs its own plan. (Q9, defaulted)
- No production migration. mergekit `close` step 8 keeps that check.
- No dev server start inside gitkit. mergekit `start` still starts the app.
- No change to debugkit's or afkkit's scratch worktrees.
- No live-check phase on a real repo. (Q15)
