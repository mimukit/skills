# Plan: Issue cleanup checks in issuekit triage
Grilled: 2026-10-25

## Context

The owner cleaned up an issue tracker with an ad hoc prompt. It asked for three lists: issues that can close with no code change (already built, or covered by another issue), issue pairs that can merge into one, and old issues to close on approval, each with a short description. The prompt worked, but it lives in chat history, and nothing makes the next run behave the same way.

`issuekit triage` already reports tracker drift and applies only the fixes the owner approves. It flags **Stale** issues by age and proposes a stale close, but it never reads issue bodies or the code, so it cannot see work that already shipped, two issues that describe the same work, or an issue a later decision replaced.

Goal: one manual `issuekit triage` run produces the cleanup lists the ad hoc prompt produced, with evidence on every close, and never deletes an issue.

Target: no number fits, because this is a skill text change. The check is that `make lint` passes and the new checks read as testable rules in `modes/triage.md`.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Where the cleanup lives | Inside `issuekit triage`, not a new skill or mode. triage already owns the report-then-approve batch and the stale close, and the owner would not choose between "triage" and "clean up" on purpose. |
| When the checks run | On every full triage run. A targeted request ("rename #42") still skips the report, as it does today. |
| Close, never delete | Every cleanup ends in `gh issue close`. `gh issue delete` is irreversible and drops the history, so triage never proposes it. |
| Which issues are in scope | **Already done** and **Obsolete** skip `in-progress` and `in-review` issues and route them to `sync`, because started work has its own close path. |
| Candidate selection for the code search | An issue is a candidate when it has a tracker signal (a merged linked PR from `closedByPullRequestsReferences`, or a commit found by `git log --grep '#N'`) or a name signal (its title or body names a path, symbol, or command that `grep` finds in the repo). A candidate becomes a proposed row only after the code search confirms the work. |
| Evidence for "already done" | Each row cites at least one of a `path:line`, a commit SHA, or a PR number. A row with no citation is not proposed. The close runs `gh issue close <n> --reason completed --comment "Closing as done: <evidence>. Reopen if this is wrong."`. |
| Partly done issues | Triage proposes a body edit, applied only on approval: an `## Already shipped` section with the citation, and acceptance criteria narrowed to the unshipped part. The issue stays open. |
| What counts as a duplicate | Two or more issues that describe the same work. Two issues where one blocks the other are never duplicates. A group of three or more applies the survivor rule across the whole group. |
| Which issue survives a merge | The one with the most settled content: started work (`in-progress`, `in-review`, a linked PR), then a `Grilled:` stamp or plan link, then acceptance criteria. On a tie, the older number survives. |
| How a merge runs | 1. Append a `## Merged from #N` section to the survivor's body with `gh issue edit <survivor> --body-file`; the preview shows that section only. 2. Move every native `blockedBy` and `blocking` edge from the loser to the survivor. 3. `gh issue close <loser> --duplicate-of <survivor>`, add the `duplicate` label, and strip any status label. |
| Older `gh` without `--duplicate-of` | Check `gh issue close --help` for the flag. When it is missing, close with a `Duplicate of #N` comment and the `duplicate` label, and say once that the native duplicate state was skipped. |
| Labels after a merge | The survivor keeps its own lifecycle and priority labels; a merge never promotes. When the loser carried `ready` or a higher priority, the report says so and points at the promotion or a rank change. |
| Duplicate of a closed issue | When the closed issue was completed, the open one is an **Already done** row that cites the closed issue and its PR. When the closed issue was not planned, propose a not-planned close that names it. |
| Stale vs obsolete | **Stale** stays the age check, and each stale row now carries a one-line summary and a keep or close recommendation. A stale close uses `--reason "not planned"`. **Obsolete** needs a named replacement (a later issue, plan, ADR, or merged PR) and closes with `--reason "not planned"` and a comment that names it. |
| A close and another fix on the same issue | The close wins. Triage drops that issue's relabel, rank, and rename rows from the batch. |
| Description trigger | The triage branch adds "clean up my issues". |
| Outward actions, tests, attended phases | None. implementkit edits files and leaves them uncommitted. `make lint` is the only check; no phase asks for a new kind of test, and no phase waits on a person. |
| Scheduling | Manual only. No scheduled run in this plan. |

## Approach

Extend `skills/issuekit/modes/triage.md` in place. It reuses triage's batch-approval table, the `duplicate` and `wontfix` side-exit labels from the lifecycle map in `skills/issuekit/SKILL.md`, the native dependency edges from **Recording a dependency**, and the strip-status-on-close rule that `sync` and the **Zombie label** check already apply. No satellite file: every full triage run takes this branch, so the branch test keeps it inline.

Rejected: a sixth mode `prune` (a second report-then-approve flow with no real choice behind it), and a disclosed `triage` branch that runs only on request (the owner chose every run).

### Phase 1: Add the cleanup checks to triage (built 2026-10-25)

- Step 1 (**Read the tracker**): add `body` and `closedByPullRequestsReferences` to the `--json` field list, so the bodies and the linked PRs come with one read.
- Step 2 (**Flag drift**): add three checks beside the existing ones, each with the candidate, evidence, scope, and closed-issue rules from Design decisions:
  - **Already done.** An open issue whose work exists in the code, a merged PR, or a commit. A partly done issue gets the narrowing edit instead of a close.
  - **Duplicate or overlap.** Two or more issues that describe the same work. Each hit names the group, the proposed survivor, and the survivor rule that picked it.
  - **Obsolete.** An open issue that a named later issue, plan, ADR, or merged PR replaced.
- Step 2: change **Stale** so each row carries a one-line summary of the issue and a keep or close recommendation.
- Step 3 (**Offer fixes**): add the apply rules for each kind, with their commands: the completed close with its citation comment, the narrowing body edit, the merge sequence with its `gh` fallback, and the not-planned close with its replacement comment. Add the close-wins rule for rows on the same issue. State that triage never runs `gh issue delete`.
- Step 3: say that a closed issue drops out of the "exactly one lifecycle and one priority label" done criterion.
- Step 4 (**Hand off**): report closes by kind (completed, duplicate, not planned, stale), the narrowed issues, any label gap a merge surfaced, and each declined row.

Done when: `modes/triage.md` lists the three new checks with a test per check, step 3 carries one command sequence per new fix kind, and no line in the skill proposes `gh issue delete`.

### Phase 2: Update the routing and the collection pages (built 2026-10-25)

- `skills/issuekit/SKILL.md` description: extend the triage branch to name cleanup ("triage the tracker for lifecycle, priority, and title gaps, and for issues that are done, duplicated, or obsolete"), and add the trigger "clean up my issues". Keep the description under 1,024 characters (532 today).
- `skills/issuekit/SKILL.md` **When this fires**: add the cleanup phrasings to the triage line, and update the `triage` bullet in the mode list at the top.
- `docs/wiki/workflow.md`: update the `issuekit triage` row in the mode table.
- Run `make cheatsheet` to regenerate `docs/wiki/cheatsheet.md` from the new what-clause.

Done when: `make lint` exits 0, and `git diff docs/wiki/cheatsheet.md` shows the regenerated triage line.

## Open questions

- **No trial run.** The owner accepted `make lint` as the only check. The first real triage on a tracker with open issues is the first behavioral test.

## Non-goals

- A scheduled or unattended cleanup run.
- Deleting issues, in any mode.
- Closing anything without the owner's approval of the batch.
- Changes to `sync`, `close`, `create`, or `start`.
