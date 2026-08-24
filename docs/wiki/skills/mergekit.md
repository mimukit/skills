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

**Merge path** — confirm, approve when possible (GitHub doesn't permit approving your own PR, so a self-authored one skips it and says why), merge with a fixed subject, then hand the landing to [`issuekit`](./issuekit.md) — `close` first, then `sync`.

`close` takes the one issue the PR closes: closing it, ticking a parent checklist, unblocking dependents, and reclaiming the worktree are one action owned in one place. `sync` runs straight after it, **even when there was no issue to close**, because a merge shakes things loose that mergekit cannot see from where it stands — a second issue the PR body closed, a link the PR never carried, a parent still un-ticked, a dependent left `blocked` on a prerequisite that just landed. mergekit sees one PR; `sync` reads the whole tracker. Both preview before mutating, so the pair costs a confirmation rather than a surprise, and a sweep that finds nothing still gets reported — a clean tracker and an unexamined one look identical otherwise.

Cleanup covers **only what mergekit created** — the fork-PR case where it invented both the branch and its worktree. An *adopted* worktree is someone else's context, possibly with an editor and dev server pointed at it. It's left standing and named, so you know it's still yours.

**Fix path** — you want changes, and you already have the code checked out and running, so it's fixed right there rather than handed back to whatever opened the PR. Implement, gate, commit, push; the PR updates in place and you stay in the same worktree. Then back to the review. It does not merge — that's a fresh decision needing a fresh confirmation.

### `fix`

The mirror of `start`, for a PR **you authored** that came back with review comments, a change request, or red CI.

It overlaps `finish`'s fix path in mechanics but differs at both ends: that path implements a verdict *you* just reached on someone else's PR, whereas this starts from feedback *someone else* left on yours. So it opens by gathering the punch list — unresolved threads, failing checks with log tails, the review decision — and closes by answering it.

Nothing to service (no unresolved threads, green CI) means it says so and stops.

**It triages the punch list before touching code, and does not apply every comment on sight.** A review comment — bot or human — is a claim from outside the change, and a fair share of it is wrong for *this* project: a rule the repo deliberately opted out of, a suggestion that contradicts the plan the PR implements, a real point that belongs in its own issue. Applying all of it because it was written down is how a PR grows a second unreviewed change and how a project's conventions get quietly overwritten by a linter's defaults. So each item is judged against the repo's documented conventions, the surrounding code, and the PR's stated scope, and lands on one of three verdicts — **fix**, **decline** (with the reason named, because it goes in the reply), or **ask**.

The `ask` verdict is the pressure valve, and it has two rules worth knowing. Uncertain items are batched into **one round** — a compact table with a recommended verdict per item — rather than a thread-by-thread interrogation. And **when in doubt it asks rather than declines**, because a silent decline is the expensive failure: the reviewer believes the point was considered and never finds out otherwise. Red CI is exempt from all of this — a failing check is a fact about the branch, not an opinion about the code.

When answering: it replies and resolves each thread it actually fixed, pointing at the commit. **It never resolves a thread it didn't fix.** A declined thread gets a reply naming what it conflicts with and **stays open**, so the reviewer can overrule — declining is a position you state, not a thread you drop. And it never merges; servicing feedback earns a fresh review, not a landing.

## What gitkit owns

mergekit doesn't implement worktrees, base-ref detection, or the rebase rule — [`gitkit`](./gitkit.md) does, and mergekit calls it for all three.

What mergekit owns is the *policy about when*: that a PR is worth pulling down, that a sync happens before a human reads the diff, that a merge needs a confirmation. A worktree path convention or base-ref ladder restated as mergekit's own would be a bug.

## Hands off to

A merge hands straight off to [`issuekit`](./issuekit.md) `close` and then `sync`, which reconcile the tracker. From there: `start` on an issue the merge unblocked, otherwise the next PR waiting on you, otherwise [`statuskit`](./statuskit.md) to re-orient. When a dependent was unblocked *and* another PR is waiting, the PR wins — finishing outranks starting.

## Install

```sh
npx skills add mimukit/skills -s mergekit
```

Source: [`skills/mergekit/SKILL.md`](../../../skills/mergekit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`d2e9d3b` on 2026-08-24._
