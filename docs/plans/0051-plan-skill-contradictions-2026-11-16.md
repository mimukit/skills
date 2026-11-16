# Plan: Fix the contradictions the trim reviewers found

## Context

During plan 0050 the reviewers ran live trials on every trimmed skill. The trials found six faults that were already in the text before the trim, so the trim commits left them alone. Each one gives an agent two rules that disagree, or a rule it cannot follow:

1. **prkit** says "never force-push without an explicit ask" (Notes, `skills/prkit/SKILL.md:194`), but its sync step force-pushes with `--force-with-lease` with no preview (`:15`, `:85`), as gitkit's sync rule allows. A trial agent saw the conflict.
2. **issuekit** says the `triage` label is set by "create (ad-hoc), triage" (`skills/issuekit/SKILL.md:85`), but `create` gives every ad-hoc issue `needs-planning` (`modes/create.md:84`). No kit sets `triage` at all (`grep -rn 'add-label triage' skills/` prints nothing).
3. **statuskit** says it "never commits" (`skills/statuskit/SKILL.md:13`), but the snapshot section commits the file when the user explicitly asks (`:331`).
4. **tutorkit** `exam` "touches `INDEX.md` only to close a track" (`skills/tutorkit/modes/exam.md:21`), but the root says every mode that opens a topic folder rewrites that topic's row (`skills/tutorkit/SKILL.md:83`), and `exam` opens one.
5. **verifykit** has two gaps. A same-day re-run must keep its name, but nothing tells it how to find the directory it made before, so a fresh scan takes the next serial. And the serial scan reads `origin/<default branch>` (`skills/verifykit/SKILL.md:35`), although `docs/verify/` is gitignored and bundles publish to `refs/verify-assets/<slug>` (`modes/proof.md:32`), so origin never holds a serial.
6. **afkkit** has two gaps. It still says "a batch issue agent counts as a session with no subagent capability" (`skills/afkkit/SKILL.md:67`, and the tail of `:50`), but Claude Code subagents nest three layers deep (fact commit `4f7d840`). So a batch run self-checks where it could dispatch. And `all` waits for one up-front OK (`:300`), which a headless session cannot give. `relaunch.sh` accepts only an issue number (`skills/afkkit/relaunch.sh:44`).

The goal is skills an agent can follow without guessing which of two rules wins.

Target: no number fits, because each fault is one contradiction or gap. The check is that each fault's trial scenario from plan 0050 (the reviewer reports) now gives one behavior with no conflict reported by the trial agent, and `make lint` stays at 0 errors and 0 warnings.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Which rule wins in prkit | gitkit's sync rule. A `--force-with-lease` push of this branch after its own sync rebase needs no ask; a bare `--force`, or a force-push for any other reason, still needs one. The Notes line says exactly that. |
| issuekit `triage` label | Keep the label and fix its "Set by" cell to what is true: a human or an issue template sets it, issuekit never does, and `triage` mode reads it. The same cell in repokit's table stays aligned (lint compares names and colors only, so align the text by hand). |
| statuskit commit rule | The opening line names the one exception: "statuskit never commits, except its own snapshot when the user explicitly asks." |
| tutorkit `INDEX.md` row | The root rule wins. `exam` rewrites its topic's row like every other mode that opens a folder, and it is the only mode that writes the `learned` status. |
| verifykit serial scan | Scan this worktree and every other worktree only, and skip origin, because `docs/verify/` is never committed. |
| verifykit re-run | Before it takes a serial, a run looks for an existing `NNNN-<kind>-<slug>-<today>` directory in this worktree's `docs/verify/`, and reuses it when one exists. |
| AGENTS.md serial rule | Add one clause: skip the origin source when the artifact directory is gitignored. This covers verifykit and any other gitignored artifact directory. |
| afkkit nesting | Replace the "batch issue agent counts as a session with no subagent capability" sentence (and the matching tail at `:50`) with the host-neutral form: a batch issue agent counts as a session with no subagent capability only on a host that cannot nest subagents. The conductor keeps dispatching the acceptance check itself, so the checker's brief never comes from the agent that built the change. |
| Headless `afkkit all` | An explicit `afkkit all yes` is the up-front OK: the run prints the queue preview to the session and to the run log, then starts. A plain `afkkit all` in a session with nobody to answer prints the preview and stops, starting nothing. `relaunch.sh` stays single-issue. |
| Minor gaps | In scope as Phase 4: every pre-existing gap the plan-0050 reviewers reported, listed there. |
| Owner-curated values | Where a Phase 4 fix needs a new number (motionkit bands), derive it from the skill's existing bands and cite the source in the commit body, so the review can change it. |
| Commit shape | One `fix(<skill>)` commit per skill, plus one `docs(repo)` commit for the AGENTS.md clause. Commits go to local `main`, with `main:skill-trim-wip` pushed as the backup; `origin/main` waits for the owner's review. |

## Approach

Each fix is a one- to three-sentence edit to text that already exists. No new file, no new section. The proof reuses plan 0050's method: after each edit, a fresh subagent reads only the edited skill and answers the scenario that exposed the fault, and the fix holds when the answer shows one behavior and reports no conflict.

Rejected: retiring the `triage` label. It is cleaner, but it touches the shared label tables in issuekit and repokit, and every repo that already provisioned the label.

### Phase 1: Fix the four one-rule contradictions (built 2026-11-16)
- prkit Notes line, per the settled decision.
- issuekit lifecycle table "Set by" cell for `triage`, and the same row in `skills/repokit/modes/labels.md` if it carries a "set by" text.
- statuskit opening line.
- tutorkit `modes/exam.md:21`.

Done when: a trial subagent per skill answers its plan-0050 scenario with one behavior and no reported conflict (prkit: a branch behind its base that needs a sync and push; issuekit: an ad-hoc issue filed by `create`, then asked which label it carries; statuskit: the user asks to commit the snapshot; tutorkit: an exam that passes one gate), and `make lint` exits 0 with 0 warnings.

### Phase 2: Fix the verifykit serial scan and re-run (built 2026-11-16)
- In the root shared procedure, drop origin from the scan and add the re-run lookup.
- In `AGENTS.md` "Documentation artifact naming", add the gitignored-directory clause.

Done when: a trial subagent with two worktrees and a same-day earlier run names the `proof` bundle with the earlier directory's serial, and names a new run with the next serial across both worktrees, and `make lint` exits 0 with 0 warnings.

### Phase 3: Fix afkkit nesting and headless `all` (built 2026-11-16)
- Replace the no-subagent batch sentence and the `:50` tail with the host-neutral form.
- Add the headless-`all` rule.
- Give the Hand off a next move for an issue the batch skipped (in-progress, stacked, or refused): name it and say how to run it by number.

Done when: a trial subagent reading afkkit for a batch run on a nesting host dispatches implementkit's phase subagents and the invariant check rather than self-checking; a headless `afkkit all` trial prints the preview and starts nothing, and an `afkkit all yes` trial starts the queue; and `make lint` exits 0 with 0 warnings.

### Phase 4: Close the smaller gaps (built 2026-11-16)
- **motionkit:** a duration band for loops, hover, and badges; a reduced-motion rule for rotation; settle the "built-in keywords too gentle" line against the `ease` row for hover; settle "enter from almost there" against a request to slide in from an edge.
- **mergekit:** the root preview-and-confirm line defers to Sync consent; `fix` reads fork status before triage, not in step 3.
- **ideakit:** an explicit phrase rule beats the "idea" tie-break; "would anyone pay" routes to `validate`; `session` offers the save before the user switches mode.
- **implementkit:** a repo-declared gate command (in the agent-guide file) is the done-gate; the phase gate runs the same repo's own typecheck, lint, and affected-test commands.
- **dbkit:** a mechanism for creating future partitions ahead of time, and no DEFAULT partition when retention uses `DETACH … CONCURRENTLY`; a role-named foreign key (`owner_id`) when a table references the same table twice or the role differs from the table name.
- **testkit:** the `cover` report gets a line for contradictions found and tests skipped.
- **grillkit:** a ⏳ question keeps its number when it returns.
- **statuskit:** the `repo-labels` key gets a ladder rung or is dropped; the Issues panel render rule and the failed-call rule agree on where the failure is named.
- **commitkit:** the Message-only route can read an untracked file's content.
- **refactorkit:** the hand-off line names plankit as a next move, not an order to write the plan.

Done when: each fix has a trial subagent answer showing one behavior with no reported conflict, each new number cites its source in the commit body, and `make lint` exits 0 with 0 warnings.

## Open questions

None. The three questions of the first draft were settled by the owner's "fix all" instruction on 2026-11-16, with the recommended answers recorded in Design decisions; the owner checks them at review.

## Non-goals

- No trim. These are rule fixes, and each edit adds or changes at most a few sentences.
- No change to any `description:` field.
- No retirement of the `triage` label.
- No redesign of afkkit's acceptance-check relay beyond deleting the false no-subagent rule.
