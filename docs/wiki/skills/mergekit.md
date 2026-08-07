# mergekit

Take an open GitHub PR and make it merge-ready on your machine — worktree, sync, project running, review pack — then merge it once you say so.

**Reach for it when** you review the PRs an agent opened overnight, or your own PR comes back needing changes.

| | |
|---|---|
| Modes | [`list`](#list) · [`start`](#start) · [`finish`](#finish) · [`fix`](#fix) |
| Tools | `Bash`, `Read`, `Write`, `Skill` |
| Writes | worktrees, commits, pushes; merges a PR behind a human gate |
| Visibility | public |

## What it does

mergekit is the other half of a pull request's life. Something else opened it — you, an agent, a teammate. mergekit is what you run when it's your turn to *judge* it.

It gets the PR into a worktree, syncs it with the base, gets the project running, and prints a **review pack** of everything you need to form an opinion. Then it waits.

It forms **no opinion about the code**. Judging the source is [`reviewkit`](./reviewkit.md)'s job; mergekit sets the review up and executes the decision you reach.

## The merge exception

mergekit is the **one skill permitted to merge a pull request** — a deliberate exception to the rule the rest of the collection holds.

That permission is earned by a single hard precondition: **a human confirms that specific PR, every time.** Without the confirmation, mergekit has no more authority than any other skill.

- **Never a batch.** "Merge them all" is not a confirmation for any individual PR.
- **Never inferred.** Green CI, an approving review, zero unresolved threads, a passing local gate — all *inputs to your decision*, none of them the decision. A perfectly green PR still waits.
- **Never default-yes.** No answer means no merge.
- **Never as a side effect.** `start` never merges. A fix round never merges.

Because the confirmation needs a human in front of it, **mergekit must never be dispatched inside an unattended pipeline** — "the orchestrator said yes" is not a human review. It also does no polling, enables no auto-merge, and acts on no schedule.

## Modes

### `list`

The morning dashboard: what's actually waiting on you, in one table.

Three facts matter more than anything `gh pr list` returns, so they get gathered per PR:

- **Unresolved review threads.** REST doesn't expose thread resolution state at all — only GraphQL does. A PR with a bot review sitting unanswered is not ready for your time.
- **Behind the base branch.** A PR that's behind is one you'd be reviewing in a state that will never exist.
- **A QA plan and proof.** Absence is a fact worth printing, not a silence.

It **does not crown a "next" PR**. Ranking work is [`statuskit`](./statuskit.md)'s job, and a reviewer's queue is theirs to order.

### `start`

Make a PR merge-ready.

The key step is **adopt first, create only if needed**. A PR's branch very often already has a worktree — it was implemented in one on this same machine. Git allows a branch in exactly one worktree, so creating a second doesn't merely duplicate work, it hard-fails. Re-running `start` is a normal thing a reviewer does and must never error or blow away work in progress.

If an adopted worktree is dirty, mergekit **reports what's uncommitted before doing anything else** — you're standing in someone's live workspace, possibly mid-change, not a scratch checkout.

Then it syncs with the base *before* you read the diff, so you review what will actually land. A PR branch is published, so that sync previews and waits. This is the one place [`gitkit`](./gitkit.md)'s merge exception genuinely fires: the review pack already counts unresolved threads, and a rebase outdates every one of them, so the count goes into the preview.

The **review pack** assembles everything so you don't go hunting: title, author, URL, body summary, the linked issue and its acceptance criteria, commits and diff shape, QA plan and proof, CI status per check — and **unresolved review threads with `file:line` and comment text**, which is the highest-value part, because it's what you'd otherwise re-derive by hand.

It **names what's missing**. "No QA plan in this repo's conventional location" is information; printing nothing where one would go is not.

### `finish`

Merge or fix, depending on which verdict you reached.

**Merge path** — confirm, approve when possible (GitHub doesn't permit approving your own PR, so a self-authored one skips it and says why), merge with a fixed subject, then hand the landing to [`issuekit`](./issuekit.md) `close`. Closing the issue, ticking a parent checklist, unblocking dependents, and reclaiming the worktree are one action owned in one place.

Cleanup covers **only what mergekit created** — the fork-PR case where it invented both the branch and its worktree. An *adopted* worktree is someone else's context, possibly with an editor and dev server pointed at it. It's left standing and named, so you know it's still yours.

**Fix path** — you want changes, and you already have the code checked out and running, so it's fixed right there rather than handed back to whatever opened the PR. Implement, gate, commit, push; the PR updates in place and you stay in the same worktree. Then back to the review. It does not merge — that's a fresh decision needing a fresh confirmation.

### `fix`

The mirror of `start`, for a PR **you authored** that came back with review comments, a change request, or red CI.

It overlaps `finish`'s fix path in mechanics but differs at both ends: that path implements a verdict *you* just reached on someone else's PR, whereas this starts from feedback *someone else* left on yours. So it opens by gathering the punch list — unresolved threads, failing checks with log tails, the review decision — and closes by answering it.

Nothing to service (no unresolved threads, green CI) means it says so and stops.

The thread count matters more here than anywhere: you're about to *answer* those threads, and a rebase outdates the ones you haven't replied to yet. So the punch list is gathered first and the number goes in the sync preview.

When answering: it replies and resolves each thread it actually fixed, pointing at the commit. **It never resolves a thread it didn't fix** — those stay open with a note on why. And it never merges; servicing feedback earns a fresh review, not a landing.

## What gitkit owns

mergekit doesn't implement worktrees, base-ref detection, or the rebase rule — [`gitkit`](./gitkit.md) does, and mergekit calls it for all three.

What mergekit owns is the *policy about when*: that a PR is worth pulling down, that a sync happens before a human reads the diff, that a merge needs a confirmation. A worktree path convention or base-ref ladder restated as mergekit's own would be a bug.

## Hands off to

After a merge: [`issuekit`](./issuekit.md) `start` on an issue this merge unblocked, otherwise the next PR waiting on you, otherwise [`statuskit`](./statuskit.md) to re-orient. When a dependent was unblocked *and* another PR is waiting, the PR wins — finishing outranks starting.

## Install

```sh
npx skills add mimukit/skills -s mergekit
```

Source: [`skills/mergekit/SKILL.md`](../../../skills/mergekit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`fd96414` on 2026-08-07._
