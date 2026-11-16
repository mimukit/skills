---
name: mergekit
description: >-
  Take an open GitHub PR and set it up for review on your machine (worktree, project running, review pack), then merge it once you say so, or service review feedback on a PR you authored. Use when you say "pull PR #34 down so I can test it", "merge PR #34", "address the review comments on my PR", or "my PR is red, fix the CI".
license: MIT
allowed-tools: Bash, Read, Write, Skill
metadata:
  internal: false
---

# mergekit

mergekit sets an open PR up for review in a [git worktree](https://git-scm.com/docs/git-worktree), prints a **review pack**, then merges it on your word, or fixes it in that same worktree. It forms no opinion about the code.

mergekit is the **one skill permitted to merge a pull request**, and only after a human confirms that specific PR, per [Never merge automatically](#never-merge-automatically).

## When this fires

The PR already exists, and you are either reviewing it, or you authored it and it has come back needing changes:

- **list.** The PRs waiting on you.
- **start `<n>`.** Set a PR up for review. "Start #34 and sync" adds a sync onto the latest base.
- **close `[<n>]`.** Merge the PR, or fix what the reviewer asks for. With no number, `close` takes the PR of the current branch.
- **fix `<n>`.** Service review comments or red CI on a PR you authored.

**`<n>` is a PR number in every mode**, even when a same-numbered issue exists. If the user means the issue, they say so, and that run belongs to issuekit's `start`.

If a PR is named but the action isn't, assume `start`.

**Not this skill:** opening a PR from your branch, or judging whether the code is any good. Those belong to a PR-authoring skill and a code-review skill.

## Never merge automatically

Every merge requires an explicit, per-PR confirmation from a human who has just reviewed *that* PR. **A direct instruction to merge or close one PR is that confirmation.** "Merge #34", "close this PR", and `mergekit close` in a worktree whose branch has one open PR all count, so mergekit merges without a second prompt. It asks only when the instruction leaves a doubt or the state shows an anomaly, as [the close mode](modes/close.md#merge-path) lists. Concretely:

- **Never a batch.** "Merge them all" is not a confirmation for any individual PR. Ask once per PR, naming the number and title.
- **A stack cascade takes one confirmation that names every PR, in merge order.** Merging a layer merges every unmerged PR below it, bottom-up, so an instruction that names only the top PR always gets the enumerated prompt, with each PR's number and title.
- **Bound to the reviewed head.** The confirmation covers one head SHA only: the head `start` recorded, or the head read when the instruction arrived. A push after the confirmation needs a fresh review and a fresh confirmation, and the merge call carries `--match-head-commit` so GitHub enforces it.
- **Never inferred.** Green CI, an approving review, zero unresolved threads, and a passing local gate are *inputs to the human's decision*, and none of them is the decision.
- **Never default-yes.** When mergekit does ask, don't phrase the prompt so silence merges. No answer means no merge.
- **Never as a side effect.** `start` never merges. A fix round never merges. Only `close` merges, and only after the confirmation.

The same preview-and-confirm rule covers every other outward-facing mutation, such as commenting or closing an issue. Show what will happen, wait for the OK. A sync push is the one exception: [Sync consent](#sync-consent) alone decides whether it runs, and it takes no second prompt.

**Label writes are exempt, in every mode.** Adding or removing a label on an issue or a PR runs straight through, with no prompt: strip a merged PR's status label, strip a closed issue's `in-review` or `in-progress`, flip its dependents `blocked → ready`, set a priority. Report every label move in the hand-off. The exemption reaches the labels and nothing else.

## Preflight

Every mode starts here:

```sh
gh --version && gh auth status              # GitHub CLI installed + authenticated
gh repo view --json nameWithOwner           # inside a repo
```

- If `gh` is missing or unauthenticated, say so and point to `https://cli.github.com` / `gh auth login`.
- **Get the base branch from gitkit.** Never assume `main`. Everything below written as `origin/<base>` means whatever gitkit returns.
- For `start` and `close`, confirm the PR exists and is open before touching the filesystem.

## What gitkit owns

**gitkit** owns worktrees, base-ref detection, the rebase-versus-merge rule, and a worktree's setup, and mergekit calls it for all four. When gitkit isn't installed, fall back to the plain git commands named inline, with the same convention.

### Sync consent

A sync rewrites a published branch and outdates review threads, so it runs only with consent:

- **`start`** reports how far the branch is behind and does not sync. The reviewer runs gitkit `sync` in the worktree when they choose. A request that asks for the sync in the same breath ("start #34 and sync") is the consent to the rebase and the push.
- **`fix`** always syncs, because the ask to fix your own PR covers the push.
- **Every sync push uses `--force-with-lease`**, never bare `--force`, and reports how many review threads it outdated. mergekit force-pushes only inside a sync, never to tidy history.
- **A fork PR takes no push.** You can review and merge it, but you cannot push to it, so it refuses a sync and a fix.

## The modes

The mode bodies live in one file each under `modes/`. Route with [When this fires](#when-this-fires), read that one file, and follow it. Everything above this line applies to every mode.

- Mode `list` → read [modes/list.md](modes/list.md), then follow it.
- Mode `start <n>` → read [modes/start.md](modes/start.md), then follow it.
- Mode `close [<n>]` → read [modes/close.md](modes/close.md), then follow it.
- Mode `fix <n>` → read [modes/fix.md](modes/fix.md), then follow it.

## Notes

- **Never run mergekit, in any mode, as a subagent inside an unattended pipeline, and never run `fix` unattended at all.** A merge and a [`fix` triage](modes/fix.md#2-triage-the-punch-list) both need a human present, and an orchestrator's yes is not a human review.
- **No polling, no queue, no auto-merge.** mergekit runs when you invoke it. It does not watch for PRs, does not enable GitHub's auto-merge, and does not act on a schedule.
- **Bot review feedback is reported, not resolved, on the reviewer's side.** `list` and `start` surface unresolved threads and stop there; `fix` answers them. A bot's finding is triaged like a human's.
- **No shell or `gh` available** (e.g. a browser-based agent)? Then you can't create a worktree or call `gh`. Print the review pack from what the user provides, and print the setup and merge commands as codeblocks for them to run, and never claim a merge happened that you could not perform.
