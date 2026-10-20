# Plan: afkkit warm-session pipeline

## Context

afkkit is slower and more expensive than the prompt the owner now pastes by hand instead of running it. The pasted prompt chains `/implementkit start`, `/qakit`, `/commitkit all` and `/prkit` in one session and tells the agent to decide on its own and list its decisions at the end.

The evidence from session history, gathered 2026-10-20:

- **afkkit, 1 recorded run** (Codex, saasaloy #16): about 87 active minutes, 49M tokens, 11 subagents. Implement took 74% of the tokens across 7 agents for 5 phase groups. Each subagent started with about 45k tokens of forked conductor history. `pnpm deps:check` ran about 13 times across 9 agents, and the same red base was proven again in four steps. Two agents died at the usage limit and reran from zero (6M tokens wasted). The run used 2.6 five-hour windows.
- **The one review found nothing, because of a bug.** The reviewer was forked with the full conductor transcript, decided it was the conductor, self-reviewed, wrote "no blockers", and ran QA and the PR itself. The fix step never ran. A different model family bought no independence because the context was not fresh.
- **Pasted prompt, 41 runs** (Claude, 2026-09-20 to 2026-10-20): median 21.4 minutes and 17.3M tokens, 40 of 41 reached a PR, none escalated, none reviewed. Implement is 81% of the time; qakit, commitkit and prkit take about a minute each.
- **The pasted prompt leaks UI defects.** 6 of 41 runs (15%) drew a defect report afterward, all on UI work: design B shipped where A was chosen, a sidebar missing, links not opening in a new tab, blurry hero images. Most are spec-compliance misses, not code bugs. Each follow-up cost 15M to 21M tokens, more than a whole run.
- **No Claude transcript shows a fable dispatch.** The "fable burns the session" cost is not in the local record, so this plan drops fable on the owner's judgment that Opus 5.5 matches it, not on measured spend.

Success: the owner runs `afkkit <n>` instead of the pasted prompt. A single-issue run lands near 25 to 35 minutes and under 25M tokens on a typical issue, keeps every afkkit guard, and catches the spec-compliance class of defect before the PR opens.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Execution shape | One warm session per issue runs start, spec gate, implement, commit, QA and PR. The pasted prompt's speed comes from never moving context between agents. |
| Long builds | implementkit's own conductor rule decides when implement splits into per-phase subagents (more than one heavy phase, or a bulk mechanical phase). afkkit adds no second split rule. |
| Guards kept | issuekit `start` and its `ready` guard, the spec gate's `needs-planning` escalation (missing decisions, attended work), `no-push` until the PR step, the authorization list, the escalation contract, and the base-branch check on a "pre-existing" failure claim. |
| Decisions list | The agent appends each decision it takes on the owner's behalf to `.afkkit/assumptions.md` as it goes. prkit copies the entries into the PR body under **Assumptions**, and the hand-off repeats them. This is the list the pasted prompt asks for, kept in the PR. |
| Review | One fresh subagent on the session's own model runs an **acceptance check**: reviewkit's requirement-completeness and correctness passes only, blockers only. Its brief carries the issue body, the branch diff range, `assumptions.md` and `checks.md`, and no forked history. The warm session fixes the blockers. Deep review stays with the PR review bot. |
| Fresh context is the independence | The reviewer is dispatched as a new agent, never a fork. The brief states it is the reviewer and must not run QA, commit, or open the PR. This closes the role-confusion bug. |
| Model routing | Removed. Every step runs on the session model; an inline override ("afkkit 42, review on sonnet") still works. |
| Repeated-work caps | One dev server per run, started once and stopped once. A red base gate is proven once and recorded in `orientation.md` with its command and exit code, and no later step re-proves it. Each gate command runs once into a log, per implementkit's tool rules. |
| Run directory | Shrinks to `assumptions.md`, `checks.md`, `orientation.md` (known-red base gates and the dev-server command only), `findings.md` and `progress.md`. `verified.md` goes away: the warm session holds its own check results and hands them to qakit directly. |
| Batch `all` | One thin conductor walks the queue and starts one fresh single-session subagent per issue, so issue N's context never bills issue N+1. Sequential, priority order, one OK up front, as today. |

## Approach

Rewrite `skills/afkkit/SKILL.md` around the warm session, reusing what the companion kits already own. implementkit owns the conductor split and the gate-once rule (`skills/implementkit/SKILL.md`, "A long build runs as a conductor" and "Run the done-gate"). reviewkit owns the passes (`skills/reviewkit/SKILL.md`, Pass 3 and Pass 4) and its own "fresh subagent" rule, which the acceptance check satisfies by being dispatched fresh. qakit owns the QA plan and its revision rule. prkit owns the PR, the push, and the `in-review` advance. issuekit owns `start` and the label guard.

Rejected alternatives, one line each:

- **No in-span review, rely on the PR bot.** Matches the pasted prompt's speed exactly, but keeps the 15% UI defect rate, and the bot reviews code, not the issue's acceptance criteria.
- **Keep the conductor, trim each step.** Fixes the reruns but keeps the cold start per step, which is the cost the pasted prompt avoids by construction.
- **Keep a cross-family reviewer.** The one recorded cross-family review found nothing, and the failure was context, not model.

### Phase 1: warm-session pipeline in afkkit

- Replace "How the conductor runs each step" with a section on the warm session: which steps run inline, when implementkit splits implement, and the one dispatch the run always makes (the acceptance check).
- Fold the spec gate into the session after `start`. It still writes `assumptions.md` and `checks.md`, still escalates missing decisions and attended work to `needs-planning`, and writes `orientation.md` only for known-red base gates and the dev-server command.
- Replace "Verify and review" and "Fix and finish" with: run the agent-confirmable checks in the warm session, dispatch the acceptance check, apply its blockers, commit with `no-push`, run qakit, run prkit.
- Write the acceptance-check brief: inputs by path, the two reviewkit passes, blockers only, "you are the reviewer; do not run QA, commit, push or open a PR", findings to `.afkkit/findings.md` with `B1`… IDs.
- Add the repeated-work caps as hard rules in one place.
- Make the agent append to `assumptions.md` at every decision point, not only at the gate, and have the hand-off list the entries.
- Delete "Model routing" and the `verified.md` row; update the run-directory table and the resume table to the new step set.
- Keep "with metrics" reporting so the first runs can be compared against the 21.4-minute baseline.

Done when: `make lint` passes, `skills/afkkit/SKILL.md` contains no `fable` and no `gpt-5.5`, the pipeline names exactly one subagent dispatch per issue outside implementkit's own split, and the resume table has one row per remaining `progress.md` state.

### Phase 2: batch mode on the new shape

- Rewrite "Batch mode: `all`" so the conductor starts one fresh subagent per issue that runs the whole single-issue pipeline, and holds only each issue's one-line outcome.
- Keep the queue order, the single up-front OK, the fixed queue, and the skip rules for `in-progress` and `stacked`.

Done when: the batch section states that the conductor never writes to a worktree and keeps only outcome lines between issues, and `make lint` passes.

### Phase 3: companion kits and docs

- implementkit: replace "When afkkit is installed, its conductor section holds the full dispatch and payload rules" with a pointer that still resolves after the rewrite, or move the payload rules it needs into implementkit.
- `docs/wiki/skills/afkkit.md`: rewrite "How the conductor works", "Model routing", "Why verify and review share one dispatch" and "Why there is only one review round" to explain the warm session and the acceptance check, with the evidence above as the why. Update the summary table if `allowed-tools` changes.
- `docs/wiki/skills/implementkit.md` if its conductor text changed; run `make cheatsheet`.

Done when: `make lint` passes with no stale-cheatsheet error, and `grep -rn 'verified.md\|independent review model' skills docs/wiki` returns nothing that describes afkkit's current behavior.

### Phase 4: measure against the baseline

Attended: the owner picks the issues and runs them; this needs live repos and a session budget.

- Run `afkkit <n> with metrics` on three ready issues, at least one with UI work.
- Compare wall time, tokens, and blocker yield against the pasted-prompt median (21.4 min, 17.3M tokens).

Done when: three metric tables exist, and each blocker the acceptance check raised is marked real or noise in a short note.

## Open questions

- Should the spec gate keep its own pass at all, or should implementkit's "Assess implementability" step carry the `needs-planning` escalation alone? Two checks on one spec may be one too many in a warm session.
- Is `checks.md` still worth writing before code exists, now that no separate verifier reads it? The pasted prompt has no such file and still reaches a PR.
- Does the acceptance check need to see the running UI to catch "design B instead of A" and "sidebar missing", or is the diff plus the issue enough? A browser check costs time; the box may have no driver.
- Should a UI issue route to uikit's audit as part of the check, since all six leaked defects were UI?
- How does the warm session survive a usage-limit stop? The Codex run lost two agents to it; one session that dies loses more context at once. Resume from `progress.md` may need to cover a mid-implement stop.
- Should the run pace itself against the five-hour window, or only resume cleanly after one?
- Does dropping the conductor change what "the conductor never writes to the workspace" protects, and is anything lost when the session that decides is also the session that edits?
- Does the single-issue run still need its own subagent when invoked directly, so a long run does not fill the owner's interactive session?

## Non-goals

- No change to the entry contract: planning and grilling stay attended, and only `ready` issues run.
- No PR-feedback loop, merge, or teardown in span.
- No parallel batches.
- No new skill. This rewrites afkkit in place; the pasted prompt is the shape it adopts, not a second kit.
- No change to qakit or prkit behavior beyond what their inputs from afkkit need.
