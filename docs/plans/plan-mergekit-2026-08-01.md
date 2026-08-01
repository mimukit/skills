# Plan — mergekit

Status: draft, 2026-08-01. Not yet built.

## Context

The kit currently ends at PR open. afkkit's declared terminus is "an open PR, a QA plan, and an `in-review` issue" (`skills/afkkit/SKILL.md:144`), and its non-goals reserve everything past that as a later phase (`:173`). orcakit `finish` refuses to run until a PR is already merged (`skills/orcakit/SKILL.md:70`). Between those two points — PR open, human hasn't looked at it yet — nothing is owned.

That gap is about to become the owner's main daily surface. The plan is a remote devbox (VPS, Docker Compose, Claude Code CLI) triggered from a phone, running issue → implement → review → commit → PR unattended. Then each morning, on the local machine: check the ready-for-review PRs, pull each one down, sync it with main, exercise it by hand, and merge it. That morning half is entirely manual today — checking out a branch, getting it running, hunting for the QA plan, remembering what the automated review already flagged.

mergekit owns it: **take an open PR and make it merge-ready, then merge it when the human says so.**

A second, separate gap exists on the remote side — CodeRabbit reviews the PR minutes after it opens and nobody addresses those comments before the human sits down. That is a different skill on a different machine and is out of scope here; see [Non-goals](#non-goals).

## Design decisions (settled)

1. **Name: `mergekit`.** Chosen over `vetkit`, `peerkit`, and `prreviewkit`. It collides externally with [arcee-ai/mergekit](https://github.com/arcee-ai/mergekit) (7.3k stars, "Tools for merging pretrained large language models"), which also owns the PyPI and npm names — an accepted cost, since the domains never overlap functionally. It was preferred over `prreviewkit` because that name creates *internal dispatch ambiguity* with `prkit` and `reviewkit`, and a misfiring skill is worse than a branding collision.

2. **A separate skill, not a `review` mode inside prkit.** The deciding argument is safety: prkit is dispatched unattended by afkkit on the devbox (`skills/afkkit/SKILL.md:140`), and merge capability must live somewhere the unattended pipeline structurally cannot reach. Secondary: opposite roles on the same object — prkit authors, mergekit reviews — mirroring the split the kit already makes between verifykit (agent-driven) and qakit (human-run).

3. **Native `git worktree` only. No orcakit, no Orca.** orcakit stays responsible for Orca workspace management and nothing else. mergekit must run unchanged on the devbox, where Orca will not exist. There is no "prefer orcakit when installed" fallback — the native path is the only path. This also satisfies the public-skill portability rule.

4. **Three modes:** `list` (the morning dashboard), `start <pr>` (worktree, sync, setup, review pack), `finish <pr>` (merge or fix locally, then tear down).

5. **Never merge automatically. Ever.** Every merge requires an explicit, per-PR confirmation from a human who has just reviewed that specific PR — never a batch "merge them all", never inferred from a green CI or a clean review, never a default-yes prompt. This is the one skill in the kit permitted to merge at all, a deliberate exception to a rule stated three times elsewhere (`skills/issuekit/SKILL.md:44`, `:360`, `skills/prkit/SKILL.md:112`). The exception is earned only by the human confirmation; without it, mergekit has no more authority than prkit. The SKILL.md must state both halves — the exception and its precondition — explicitly.

6. **Merge style: a merge commit with a fixed subject.** `gh pr merge <n> --merge --subject "chore(repo): merge pull request #<n>"`. No squash, no rebase-merge.

7. **Sync at the start of `start`, and merge rather than rebase.** Bring `origin/main` into the PR branch before the human reviews, so they review what will actually land and the PR is already conflict-free by the time they decide. Deliberately the opposite of prkit's rebase-and-force-push (`skills/prkit/SKILL.md:57`): at PR-open time the branch is fresh and nobody has read it, but at review time it carries review threads anchored to commits, and a rebase + force-push marks every one of them `isOutdated` and rewrites history a reviewer may already have read. The final merge is a merge commit anyway, so there is no history purity left to protect.

8. **Conflicts are resolved during the sync, with the human in the loop.** Surface each conflicted file, propose a resolution, confirm it, then run the repo's test/build gate before pushing — a conflict resolution is a code change and can break things that CI passed on five minutes earlier. Push the sync merge so the PR itself becomes mergeable.

9. **Request-changes is fixed locally in the live worktree**, not sent back to the devbox. The reviewer already has the code checked out and running, so handing off to implementkit and commitkit in place is strictly faster than a round trip. The devbox is not involved.

10. **Approval is skipped for self-authored PRs.** GitHub does not permit approving your own pull request, so when the PR author is the current user — the common case, since the devbox authenticates as the owner — mergekit says so once and merges directly rather than attempting a rejected `gh pr review --approve`. If the devbox is ever given its own identity (machine user or GitHub App), the approve step becomes available and should be offered.

11. **Worktrees live in `.worktrees/pr-<n>-<slug>/` at the repo root**, ignored via `.git/info/exclude` rather than `.gitignore` — a local-only ignore that never dirties the tracked tree. Adopt an existing worktree for the same PR rather than erroring.

12. **No polling, no queue, no auto-merge.** mergekit runs when invoked.

## Approach

### Phase 1 — `skills/mergekit/SKILL.md` (new, the bulk of the work)

Frontmatter: `name: mergekit`, `license: MIT`, `metadata.internal: false`, `allowed-tools: Bash, Read, Write`. The description must front-load the *review* triggers, not the merge — "Use when you sit down to review the PRs an agent opened overnight, say 'pull PR #34 down so I can test it', 'review the ready PRs locally', 'get this PR merge-ready'…" — so the skill fires at the start of a review session rather than only at its end.

**Mode `list`** — the morning dashboard. Open PRs, filtered to those actually awaiting the owner:

```sh
gh pr list --state open --json number,title,headRefName,isDraft,statusCheckRollup,reviewDecision,author,updatedAt
```

For each, add three facts `gh pr list` cannot give: whether unresolved review threads remain (GraphQL `reviewThreads` with `isResolved`/`isOutdated` — REST does not expose resolution state), whether the branch is behind `origin/main`, and whether a QA plan and proof bundle exist. One table, most-ready first. Do not crown a "next" PR — that is statuskit's job.

**Mode `start <pr>`** — make it merge-ready and hand it to the human.

1. Preflight: `gh auth status`, the PR exists and is open.
2. Resolve the head: `gh pr view <n> --json headRefName,isCrossRepository,author`.
3. Create the worktree. Same-repo: fetch the head branch, add a tracking worktree. Fork: `git fetch origin "pull/<n>/head:pr-<n>"`, add the worktree on that local branch, and say plainly that pushing is unavailable. An existing worktree for this PR is adopted, not an error.
4. **Sync with `origin/main`** — fetch, check whether the branch is behind, and if so merge `origin/main` in. On conflict, resolve with the human per the settled decision, run the repo's gate, then push so the PR is mergeable. Never rebase, never force-push.
5. Set the project up — detect the manifest (`package.json`, `pyproject.toml`, `go.mod`, …) and run the install the repo actually uses. Prefer a project-local run/dev skill when one exists; never invent a command.
6. Assemble the **review pack** and print it: PR title and body, linked issue, commits, the QA plan path, the proof bundle, unresolved bot threads with `file:line`, and any known follow-up nits the PR body carries. Name what is missing rather than staying silent about it.
7. End with the worktree path and the one command that starts the app.

**Mode `finish <pr>`** — the fork.

- **Merge path:** confirm this specific PR with a human, then merge per the settled decision. Hand tracker reconciliation to issuekit `sync` or orcakit `finish` when installed, falling back to plain `gh` calls. Remove the worktree, delete the local branch.
- **Fix path:** hand the live worktree to implementkit with the concrete findings as its spec, then commitkit, then push. Re-run the gate. The PR updates in place; the reviewer stays in the same worktree.
- Teardown is idempotent — a missing worktree reports "already gone" rather than erroring.

Every outward-facing mutation — merge, comment, relabel, push — previews and waits for an OK, matching `skills/issuekit/SKILL.md:44`.

Close with the no-shell degradation clause every public gh skill carries.

### Phase 2 — wire-up (repo housekeeping)

- `skills.sh.json` — add `mergekit` to the **Git & GitHub** group, alongside `prkit`, `issuekit`, `orcakit`.
- `README.md` — add the Skills-table row.
- `skills/statuskit/SKILL.md:82` — ladder rung 1 routes "your PR is red or change-requested" to `implementkit` / `prkit`, neither of which does this. Point it at mergekit.
- `skills/prkit/SKILL.md` — its final step offers follow-ups after the PR URL prints; name mergekit as the reviewer's next step.

## Verification

1. `make lint` — frontmatter, the `internal` marker, anchor-link resolution, portability.
2. `make link mergekit`, then run all three modes against real PRs in a scratch repo: `list` with two open PRs, `start` on one, `finish` merging it.
3. **Sync-with-conflict is the case most likely to be wrong** — construct a PR that genuinely conflicts with `origin/main`, confirm mergekit surfaces the conflict, resolves it with confirmation, runs the gate, and pushes; and confirm the PR flips to mergeable on GitHub afterward.
4. Confirm review threads survive the sync — that they are **not** marked outdated, which is the whole reason for merging instead of rebasing.
5. Re-run `start` on the same PR to confirm it adopts rather than errors.
6. Run `start` against a fork PR to confirm the read-only degradation is stated, not silently broken.
7. Confirm mergekit refuses to merge without an explicit confirmation, including when CI is green and no threads remain.
8. Run with `gh` logged out to confirm the preflight fails cleanly.

## Non-goals

- **Bot review feedback.** Fetching CodeRabbit's threads, triaging, fixing, replying and resolving belongs to a separate skill running on the devbox after prkit. mergekit only *reports* unresolved threads in the review pack.
- **Orca.** No dependency, no detection, no fallback. A future Orca-free worktree skill, if ever written, is a separate decision mergekit must not presuppose.
- **Auto-merge, watching, or queueing.** mergekit runs when invoked and merges only on an explicit human OK.
- **Judging the source.** That is reviewkit. mergekit sets up the review and executes the human's decision; it forms no opinion about the code.
