## Mode `fix <n>`: service review feedback on your own PR

`fix` takes a PR *you authored* that came back with review comments, a change request, or red CI. It **judges which feedback is worth acting on**, drives those changes, pushes, and answers every thread. It never merges.

### 1. Gather the feedback

**Read the fork status first**, with `gh pr view <n> --json isCrossRepository`. A fork PR takes no push, per [Sync consent](../SKILL.md#sync-consent), so on `true` say so and stop before you gather or triage anything.

Assemble the punch list before touching code:

- **Unresolved review threads** with `file:line` and comment text, bot or human, via the same GraphQL `reviewThreads` query [`list`](./list.md) uses. These are the change requests.
- **Failing checks** from `gh pr checks <n>`, with each failing job's name and, where reachable, its log tail. Red CI is feedback too.
- **The review decision** from `gh pr view <n> --json reviewDecision`, so you know whether a re-request of review is warranted at the end.

If there is nothing to service, meaning no unresolved threads and green CI, say so and stop. Ends when every unresolved thread and every failing check is on the punch list, or on a stop for a fork PR.

### 2. Triage the punch list

**Give each item a verdict before any edit; feedback can be wrong for this repo.**

Judge each item against what the project actually is, in this order: its **documented conventions** (the repo's agent-instructions file, its contributing guide, ADRs, lint and formatter config), the **surrounding code**, and the **stated scope** of this PR and the issue or plan it implements. Then assign one of three verdicts:

- **Fix.** Correct, in scope, and consistent with the above. This is the default for anything that is plainly a bug, a real failure, or a convention the repo does hold.
- **Decline**, with the reason named, because it goes in the reply. The recurring ones: it contradicts a documented convention or a settled decision; it is a bot false positive or a misreading of the code; it is already handled elsewhere in the diff; it is real but **out of scope**, meaning a separate change that deserves its own issue.
- **Ask.** You cannot tell from the repo alone: trade-offs, anything that conflicts with the implementation plan or a direction the user has stated, anything that widens the change's blast radius, and anything where your confidence is low.

Rules:

- **Ask in one round.** Batch every `ask` item into a single compact table (item, what it wants, your recommended verdict and why) and let the user rule on them together.
- **When in doubt, ask rather than decline.**
- **A declined item is still answered** in [Answer the feedback](#5-answer-the-feedback).
- **Red CI is not triaged away.** If a job fails for a reason you consider illegitimate, surface it; don't file it under "declined" and push.
- **Print the triage before you start.** Triage ends when every punch-list item carries a verdict and every `ask` item has the user's ruling. One line per item with its verdict, so the user can overrule any of it. If most of the list came back declined, say so plainly: the reviewer and the PR likely disagree about the change itself, which needs a conversation, not a fix round.

### 3. Get the worktree and sync

Adopt the branch's existing worktree as [`start` does](./start.md#2-get-a-worktree-adopting-first-and-creating-only-if-needed). Then **sync it**, per [Sync consent](../SKILL.md#sync-consent). Hand the sync to gitkit; without gitkit, rebase onto the base and push with `--force-with-lease`.

A rebase outdates the threads you have not replied to yet, so gather and triage the punch list first, and report the outdated count in the hand-off. On conflict, resolve it yourself by gitkit's conflict rule: write mechanical resolutions without asking, and ask the user to rule on any resolution that is a decision. Without gitkit, resolve additive conflicts directly and ask before any resolution that drops either side's code. Run the repo's test and build gate before you push. Ends when the worktree is on the latest base and `origin` matches it, or on a declined or stopped sync.

### 4. Fix, gate, commit, push

For each item you decided to **fix**, in the live worktree:

1. Implement the change, preferring an installed implementation skill.
2. Run the repo's test and build gate.
3. Commit in the repo's own style, preferring an installed commit skill.

Then push with a plain `git push`, and the PR updates in place. If an item turns out to be ambiguous once you are inside the code, or you can't get the gate green, stop and surface it. An item can still flip to **ask** here. Ends when every **fix** item is in a pushed commit or flipped to **ask**, and the gate passed on the pushed head.

### 5. Answer the feedback

Answer every item, fixed *and* declined, with each mutation previewed and confirmed:

- **Reply and resolve exactly the threads a pushed commit fixed**, pointing at the commit that did it.
- **Reply to each declined thread with the reason, and leave it open.** Name what it conflicts with, whether the convention, the decision, or the PR's scope. For an out-of-scope item, offer to file the follow-up issue.
- **Re-request review** when the decision was `CHANGES_REQUESTED` (`gh pr edit <n> --add-reviewer <login>`, or the `requested_reviewers` REST endpoint).
- **Do not merge.** Merging is `close`'s job, behind its human gate.

Ends when every punch-list thread has a reply, and only the fixed threads are resolved.

### 6. Hand off

**What changed.** Report the punch-list items you fixed and the commits that did it, the gate result, and which threads you replied to, resolved, or left open. **Report the declines with their reasons**, not just the fixes.

**Where it landed.** Give the branch pushed and the PR updated in place, plus the worktree path you worked in.

**Next.** The reviewer acts next: the re-requested review, or CI re-running on the push. Name first what you *couldn't* service and what you *declined*; those need the reviewer, not another fix round. Once they approve, `close <n>` lands it.
