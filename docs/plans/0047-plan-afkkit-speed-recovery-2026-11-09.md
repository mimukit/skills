# Plan: afkkit runs that recover on their own and finish faster

Grilled: 2026-11-09

## Context

The afkkit run on primeshopr issue #189 (shopper wallet, PR #194) took 5 h 19 min, from 11:43 to 17:02 on 2026-11-09. The transcript is `~/.claude/projects/-home-dev-worktrees-primeshopr-issue-189-add-a-shopper-wallet-with-refund-and-withdraw/6688931b-eb6c-46a0-a441-b43a5eaa7671.jsonl` with its `subagents/` folder, and the run state is that worktree's `.afkkit/`. Four losses account for about 2 h 49 min of it:

| Loss | Minutes | Cause |
|------|---------|-------|
| Idle after a provider error | 52 | The error ended the session's turn at 13:52 while the Phase 5 agent ran. The Agent call returned "interrupted, outcome unknown". Nothing ran until a human typed "retry" at 14:44. A continuation agent then took 19 min to finish Phase 5. |
| Rework after the acceptance check | 52 | Phase agents logged assumptions 14 and 43, which broke plan 0048's core invariant: every wallet taka has a `payments` or `payment_refunds` row. Only the acceptance check at 16:02 compared assumptions with the plan (`findings.md` B1). The fix round took 36 min and the QA refresh 16 min. |
| Full test suite inside phase agents | about 61 | `brief-common.md` told every phase agent to run full `pnpm test` (2 to 5 min each, flaky at load 10 on 6 cores; `orientation.md` records the SIGABRT and worker timeouts). implementkit's conductor rule says the done-gate runs once, in the conductor. |
| QA, then the acceptance check, in series | about 4 | The checker starts only after qakit ends, though most of its passes do not need the QA results. |

The goal is an unattended run that needs no human keystroke to survive a transient provider error, and that spends its wall clock on building rather than on waiting, repeating gates, or rework found late.

Target: an issue the size of #189 reaches its PR in under 3 h (proposed; baseline 5 h 19 min from the run above). Measured after release, on the next comparable run started through `relaunch.sh` and invoked as `afkkit <n> with metrics`. Second target: after a session dies, the next session starts within 2 min after the backoff ends, and the total idle time across all restarts of one run stays at 21 min or less. Also measured after release, on that run's transcripts, are the checks that need a real run: Phase 3's full suite only in the conductor, once per boundary, at the recorded limit; Phase 4's checker dispatch before the `qa` line and final return after it.

Estimated saving per phase, from the table above minus the new cost each phase adds: Phase 1 about 52 min, Phase 2 about 40 min (52 min of rework less about 2 min of checker per group), Phase 3 about 45 min (61 min less one full suite per boundary at the recorded concurrency, about 15 min on #189), Phase 4 about 4 min. Phases 2 and 3 are close; the order follows the request.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Skill text and hosts | No skill text names T3 Code or any host tool. Phase 1 removes the T3 sentence from afkkit's "When this fires". The qakit hand-off mention is a separate change. |
| Which start path session recovery covers | Headless runs only. An unattended run starts through `relaunch.sh`. A run in an interactive session counts as attended and gets only the in-session recovery. |
| Where the in-session recovery rule lives | afkkit's Dispatch rules, because they already bind every agent the run starts (phase groups, the acceptance check, batch issue agents). implementkit points to it, as it already does for the brief rules. |
| How many continuation agents per failed dispatch | One. A second interrupted or errored return for the same unit escalates keeping `in-progress`. |
| How the conductor finds a dead agent's processes | A new run-directory folder, `.afkkit/pids/`. Every agent that starts a process writes `<role>-<name>.pid` there. The ports in `orientation.md` are the fallback (`lsof -ti :<port>`). |
| How the relauncher tells a deliberate stop from a crash | afkkit appends `escalated <label> <reason>` to `progress.md` on every escalation. The relauncher stops when it sees that line. Without it, an execution-gap escalation (still `in-progress`, no PR) would match the relaunch condition and restart into the same wall. |
| Relauncher home and path | `skills/afkkit/relaunch.sh`, beside SKILL.md, the same shape as `skills/verifykit/verify-assets.sh`. Not under `scripts/`, which lint flags in a public skill. It installs with the skill; nothing changes in devaloy. |
| Relauncher CLI | `relaunch.sh [--agent '<cmd>'] <n>` runs `<cmd> "afkkit <n>"` in the main checkout. `--agent` defaults to `claude -p`; a Codex user passes `--agent 'codex exec'`. |
| Relauncher process model | The script detaches itself with `setsid` and `nohup`, prints its PID and log path, and refuses a second start for the same issue while the first PID lives. State files: `${XDG_STATE_HOME:-$HOME/.local/state}/afkkit/<owner>-<repo>-<n>.pid` and `.log`, outside the worktree because the worktree may not exist yet. |
| Relauncher compatibility | Bash 3.2 compatible. It needs `git`, `gh`, and the agent CLI. A missing dependency stops it with a message. The skill names the fallback: run the headless command once, with no restart. |
| Restart limit and backoff | 3 restarts per wrapper invocation, with waits of 1, 5, and 15 min. A new manual start resets the count. |
| Relauncher at the limit | It posts one comment on the issue with the log tail, keeps `in-progress`, and exits. |
| Batch scope | `relaunch.sh` covers a single issue only. Batch recovery is a non-goal. |
| What the invariant check reads | Only the `assumptions.md` lines the group added, against the binding sections of the input: the issue body, and the linked plan's Design decisions table, Approach invariants, and Non-goals. It does not read the diff; the acceptance check owns the diff. |
| Invariant blocker policy | Block. A blocker is fixed before the next group starts, by a new fix-round agent for that group (implementkit's fix round). The invariant check then runs once more; a surviving blocker escalates keeping `in-progress`. An assumption that shows the plan's invariant cannot hold at all escalates to `needs-planning`. |
| Where the gate-scope rule lives | implementkit owns it, because the phase gate and the done-gate are its terms. afkkit's Dispatch rules carry the answer in one line plus the afkkit-only part: the conductor records the full-suite concurrency limit in `orientation.md`. Both skills are public, so this is the licensed portability duplication, stated as answer, not derivation. |
| Phase gate for a phase agent | Typecheck, lint, and the tests of the packages the group changed (in a single-package repo, the affected test files). Never the full suite. |
| When the conductor runs the full suite | At every phase-group boundary, at the recorded concurrency limit, so every commit `progress.md` names is green for a resume. |
| How the checker gets the QA results without polling | The conductor dispatches the checker at QA start. The checker runs every pass that needs no QA result, writes interim findings, and returns. When the `qa` line lands, the conductor continues the same agent with the QA plan path. A host that cannot continue an agent runs the check in series, as today. |
| Interim findings on a resume | Lost. The resume row "a `qa` line, no `check`" runs the full check again (about 4 min). No new progress line. |
| Test approach for `relaunch.sh` | Throwaway stubs in the session scratchpad, not committed: PATH shims stand in for `gh`, and `--agent` takes a stub agent. No GitHub writes. |
| Proof for Phases 3 and 4 | Text checks at build time. The transcript checks move to Context, measured after release on the next real run. No sandbox run and no outward action during the build. |
| Description budget | No description changes. The four changes are rules inside existing steps, not new branches. |

## Approach

Change two public skills, `skills/afkkit/SKILL.md` and `skills/implementkit/SKILL.md`, and add `skills/afkkit/relaunch.sh`. The work reuses what exists:

- the resume table in afkkit's "Resume an interrupted run" section, which already makes a re-run idempotent;
- the `progress.md` line vocabulary and the run-directory table;
- the conductor rule in implementkit's "Build in the resolved mode" step, and its done-gate step;
- the continuation pattern of batch mode, which already continues an issue agent with the host's message-to-agent tool;
- `skills/verifykit/verify-assets.sh` as the pattern for a script bundled in a public skill.

Every phase also keeps `make lint` green and `make cheatsheet` unchanged. Each new or moved heading keeps its anchors resolving, and no new `step N` reference appears.

Rejected alternatives, one line each. A devaloy subcommand as the relauncher: only this box would get it. A T3 scheduled task: it polls instead of owning the child, and it puts a host into the skill. A per-group full suite inside the phase agent: it keeps the load spike that made the suite flaky. Moving the invariant check into the phase agent's own brief: the author of an assumption is the worst grader of it, which is the same reason afkkit's acceptance check is a fresh agent.

### Phase 1: self-recovery (built 2026-11-09)

Tasks, in-session recovery (afkkit):

- Add a Dispatch rules bullet: when a dispatched agent returns interrupted, errored, or with no result file, the conductor (1) stops each process named in `.afkkit/pids/` for that agent, then checks the `orientation.md` ports; (2) reads `progress.md`, `git -C <worktree> status --porcelain`, and the agent's result file if one exists; (3) dispatches one continuation agent with the original brief plus "the previous agent stopped; its partial work is in the tree; read `git diff` first, then finish the unit". A second failed return for the same unit escalates keeping `in-progress`, and the comment names the unit and both failures.
- Add a Dispatch rules bullet that every agent writes the PID of each process it starts to `.afkkit/pids/<role>-<name>.pid` and removes the file when it stops the process.
- Add `pids/` to the run-directory table (written by any agent that starts a process, read by the conductor's recovery).
- In implementkit's conductor bullets, add one line: a phase-group agent that returns interrupted gets one continuation; when afkkit is installed its Dispatch rules hold the full rule. Attended runs report the failure instead.

Tasks, session relauncher:

- Add `escalated <label> <reason>` to the `progress.md` line list, written as item 3 of the escalation contract's five things. Add a resume-table row above the `in-progress` rows: an `escalated` line → report the escalation and stop; a human removes the line to allow a re-run.
- Write `skills/afkkit/relaunch.sh` to the settled CLI, process model, and compatibility rows. After the child exits, it relaunches only when all four hold: the issue reads `in-progress`; no PR has a head branch that starts `issue-<n>-`; the worktree's `progress.md` (found through `git worktree list` for that branch, when the worktree exists) has no `escalated` line; the restart count is under 3. It waits the backoff before each restart and logs each one: time, attempt number, previous exit code, last `progress.md` line. At the limit it comments the log tail on the issue once and exits.
- In afkkit's "When this fires", replace the T3 sentence with the start path for an unattended single-issue run: `relaunch.sh <n>`, by its path in the skill directory, with the fallback of the headless command run once. Add `relaunch.sh` to the `allowed-tools` explanation only if the skill lists its bundled files.

Done when: (a) a stub-agent dry run in the scratchpad that returns "interrupted" makes the conductor stop the PID in `.afkkit/pids/`, dispatch one continuation, and escalate on a second stub failure, as the transcript shows; (b) with PATH-shimmed `gh` reporting `in-progress` and no PR, a stub agent that exits 1 makes `relaunch.sh --agent <stub>` log 3 restarts, with a PATH-shimmed `sleep` that records waits of 60, 300, and 900 s and returns at once, then post one comment through the shim and exit; (c) a stub run that writes an `escalated` line, and one where the shim reports a PR, each make the script exit with no restart; (d) a second `relaunch.sh <n>` while the first PID lives exits with a refusal; (e) `bash -n` passes under bash 3.2 rules and `grep -n 'T3' skills/afkkit/SKILL.md` prints nothing; (f) `make lint` passes.

### Phase 2: per-group invariant check (built 2026-11-09)

Tasks:

- In afkkit's Implement step, after each phase-group commit and its `implement` line, dispatch a new agent under the Dispatch rules. Its brief carries, by path: the issue, the linked plan, and the `assumptions.md` line range the group added. It reads only those lines against the binding sections named in Design decisions and returns blockers with IDs (`I1`, `I2`), each quoting the assumption line and the plan text it breaks. It edits no code.
- Before the commit, the conductor records the `assumptions.md` line count, so the range is exact.
- Append `invariant <group> <first>-<last> <n blockers>` to `progress.md`. When a blocker exists, dispatch the fix-round agent, commit its fix, append `invariant-fix <group> <sha>`, and run the invariant check once more. A surviving blocker escalates keeping `in-progress`; a blocker that shows the plan's invariant cannot hold escalates to `needs-planning`.
- Add resume-table rows above "`implement` lines for some groups": an `implement` line for a group with no `invariant` line → run the invariant check for that group; an `invariant` line with blockers and no `invariant-fix` line → the fix round.
- Update the run-directory table: `assumptions.md` is also read by the invariant check.

Done when: replaying issue #189's assumptions 14 and 43 (copied into a scratch run directory with plan 0048) through the invariant brief returns at least one blocker that quotes the plan's "every taka that moves between an order and the wallet also shows as a `payments` or `payment_refunds` row", and a group whose new lines break nothing returns zero blockers; `progress.md` grammar and the resume table name both new line kinds; `make lint` passes.

### Phase 3: gate scope (built 2026-11-09)

Tasks:

- In implementkit's conductor bullets, replace "builds and runs the gate" with the phase gate as text the brief must carry: typecheck, lint, and only the changed packages' tests (the affected test files in a single-package repo), each once into a log. State that the conductor runs the full suite and the build as the done-gate.
- In afkkit's Dispatch rules, add a third command rule that every phase-group brief carries the phase-gate line verbatim, plus: the conductor finds a full-suite command and concurrency limit that pass on the box once, records both in `orientation.md` as a fact with its source, and runs the full suite with that limit at every phase-group boundary.
- Update the `orientation.md` description in afkkit's run-directory section: it also holds the full-suite command and its concurrency limit.

Done when: `grep` finds the phase-gate sentence in implementkit's conductor bullets and the brief rule in afkkit's Dispatch rules; a phase brief written from the new rules for issue #189's Phase 3 contains the phase-gate line and no full-suite command; `make lint` passes.

### Phase 4: acceptance check beside qakit (built 2026-11-09)

Tasks:

- In afkkit's Acceptance check step, dispatch the checker when QA starts. Its first return covers the base verification of pre-existing claims, the diff passes, and the assumptions pass, written to `findings.md` as interim. When the `qa` line lands, the conductor continues the checker with the QA plan path; it compares each agent criterion with its QA result, finalizes `findings.md`, and returns the blocker count.
- The base verification runs the full suite at the concurrency limit in `orientation.md`, because it runs beside qakit's dev server.
- In batch mode, the issue agent returns after Implement, so the conductor can dispatch the checker and continue the issue agent for QA at the same time.
- Keep `check <n>` as the only progress line, written after the final return. The resume row "a `qa` line, no `check`" stays, and runs the full check in series.
- Keep the series path for a host that cannot continue an agent.

Done when: `grep` finds the two-part checker dispatch in the Acceptance check step, the series fallback, and the batch issue agent's new return point after Implement; the resume table still holds "a `qa` line, no `check`"; `make lint` passes.

## Non-goals

- No recovery for `afkkit all`. `relaunch.sh` takes one issue; start one per issue.
- No recovery for a run in an interactive session once the conductor's own turn ends. That run is attended.
- No T3 Code or other host-specific instruction in any skill text.
- No change to devaloy, qakit, reviewkit, prkit, or issuekit. The qakit T3 mention is a separate change.
- No committed test for `relaunch.sh` and no `make test` target.
- No parallel phase groups and no parallel batch issues. Batch stays sequential.
- No change to which model any step uses.
- No relaunch of an issue that escalated, whatever its label.
- No recovery for a dead acceptance checker beyond the one-continuation rule.
- No timing metrics written to disk; metrics stay on request, in the report.
