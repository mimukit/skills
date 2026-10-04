# prkit

Draft and open a GitHub pull request from your branch — title, summary, and test plan written from the actual commits and diff.

**Reach for it when** the commits are in and the work is ready for review.

| | |
|---|---|
| Modes | single procedure (open or update) · read-only draft route |
| Tools | `Bash`, `Read`, `Write`, `Skill` |
| Writes | a pull request via `gh`; pushes the branch; commits a handed-in QA plan; issue lifecycle labels |
| Visibility | public |

## What it does

prkit turns the commits on the current branch into a clean pull request: a title in the repo's commit style, a body explaining *what changed and why*, and a test plan — all inferred from the real diff. Creation goes through the [`gh` CLI](https://cli.github.com), reusing the repo's PR template when one exists.

## The draft route writes nothing

Asking for the title and body only ("draft the PR description") takes a separate read-only route. It skips `git fetch`, reads the remote base tip with `git ls-remote` instead, writes the title and body, prints them, and stops. It hashes the commit, the staged diff, and the refs before and after, and the records must match. The route exists because the older wording said "do everything except `gh pr create`", which still rebased, committed, pushed, edited an existing PR, and relabelled issues.

## Preview, and who can answer it

prkit previews creating or editing the PR, committing a handed-in path, and a force-push after a sync. A caller that carries the user's recorded authorization answers that preview for the actions the authorization names. [`afkkit`](./afkkit.md) is the reason: the user's unattended request authorizes the commits on the issue's branch, the push, and the PR, so a run that reaches the PR step finishes instead of stopping at a prompt nobody can answer. The authorization does not stretch. A force-push, a push to another branch, or a merge still previews, and an unattended caller escalates it.

## It reads the commits, not the diff — when it can

On a branch built through this workflow, the commit messages already are the material a PR body needs. [`commitkit`](./commitkit.md) wrote each one from the change itself, so re-deriving the description from the raw diff produces a worse result at many times the cost.

So prkit reads `git log` first and reaches for the full diff only when the commits don't explain the change: thin or generic messages (a branch of `wip` and `fix typo`), work that came from outside this workflow, files in the stat that no commit accounts for, or a specific detail needed for the test plan.

## gitkit owns the git questions

prkit doesn't re-derive them:

- **The base ref** comes from [`gitkit`](./gitkit.md). Repos whose default is `develop` or `trunk` are real, and getting this wrong silently produces an empty or enormous diff — both of which look like a valid PR. Without gitkit, `gh repo view --json defaultBranchRef` is the authoritative fallback.
- **Branch naming**, when a PR is attempted from the default branch and a feature branch has to be created.
- **The sync rule**, which resolves to rebase.

Everything is diffed against `origin/<base>` after a fetch, not a local `<base>` that may be behind.

## Hotfix branches

A branch named `hotfix-<slug>` takes the type `hotfix` in its PR title: `hotfix(scope): restore session cookie on refresh`. The branch name decides the type rather than the severity, so a scan of the PR list separates the urgent patches from ordinary fixes without anyone re-arguing how bad each bug was. Where a repo's PR-title lint validates types against the Conventional Commits set, prkit falls back to `fix(scope):` and says so once.

The body changes shape too. It leads with the symptom a user saw and the trigger, then the fix, and it carries a **Rollback** line naming the revert. A hotfix gets reviewed under time pressure, which is exactly when the undo should already be on the page instead of being worked out during an incident.

## The sync step

A PR opened from a stale branch either merges outdated code or lands with GitHub's conflicts banner. So before pushing, prkit checks whether the branch is behind and rebases if so.

Whether that needs your OK turns on one thing: an **unpublished** branch rebases straight through, because nothing outside your machine points at the commits being rewritten. A branch already pushed previews the rebase and its `--force-with-lease` together and waits. At PR-open time the branch is usually unpublished, which is why this normally runs without a prompt.

**Rebase conflicts stop everything.** The conflicted files get listed and resolved before any push or PR.

A clean rebase doesn't trigger a re-read — replaying commits onto a new base doesn't change what they say. The exception is a rebase you resolved conflicts in, where real edits happened during the replay; then just the touched files get re-read, not the whole branch.

## Proof artifacts embed inline

When a [`verifykit`](./verifykit.md) bundle exists at `docs/verify/NNNN-verify-<slug>-YYYY-MM-DD/`, prkit splices its ready-made `proof.md` into the body under a **Proof** section.

There's no upload work — the images are already published to a hidden `refs/verify-assets/*` ref with SHA-pinned raw URLs that render inline. prkit only *reads* the fragment; it never runs the publish itself.

**A bundle must show the branch head.** verifykit opens `notes.md` with the `commit:` it captured and a `dirty:` flag. prkit embeds the bundle only when it reads `dirty: no` and the code is unchanged since that commit; a later commit that touches only `docs/qa/` or `docs/verify/` is allowed, because the QA plan and the bundle itself are committed after the capture. Anything else is stale: a newer filename does not prove the screenshots show the code under review. A stale bundle is skipped and named in the hand-off.

No bundle means no Proof section and prkit works exactly as it otherwise would. A bundle whose `proof.md` points at local paths — verifykit couldn't publish, typically a private repo — gets a note listing those paths for manual attachment rather than embedded dead links.

## It commits the QA plan it is handed

[`qakit`](./qakit.md) writes the manual QA plan under `docs/qa/` and hands its path on, directly or through [`afkkit`](./afkkit.md). prkit commits that one path before the push with a pathspec commit (`git commit -- <path>`), then checks that the commit holds exactly that path. Anything else you had staged stays staged and out of the commit; work nobody named is pointed out, never swept in.

## Update, don't duplicate

Before creating anything, prkit checks for an existing open PR on the branch and edits that one instead of opening a second. Bodies go through `--body-file` rather than `--body`, because multi-line markdown with checkboxes is flaky through the flag.

## It advances the linked issue

Opening the PR is the moment a linked issue moves from being worked to awaiting review, so its lifecycle label flips `in-progress` → `in-review` — the same transition [`issuekit`](./issuekit.md)'s sync mode performs.

This only happens when the PR actually references an issue, and prefers issuekit when installed, falling back to a plain `gh issue edit`.

**It runs without asking** — label writes are prkit's one exemption from its own preview rule. A label is cheap, visible, and reversible with one command, while the cost of asking is an issue that keeps advertising itself as being worked while its PR sits open. The exemption belongs to the skill rather than to whoever called it, so a human at the keyboard and an unattended [`afkkit`](./afkkit.md) run get identical behavior. That symmetry is the point: a caller-granted bypass can drift open, and the copy inside an unattended orchestrator is the one nobody would notice drifting.

The transition itself stays narrow. It covers exactly two starting states, `in-progress` and `ready`, because those are the only two a PR legitimately arrives from: one went through [`issuekit`](./issuekit.md) `start`, and the other is work somebody just built without picking the issue up first. Both **replace** their label rather than gaining one. [`issuekit`](./issuekit.md)'s map carries a single status label at a time, so an issue reading `ready, in-review` is a broken row, not a more detailed one, and every reader downstream that treats the lifecycle label as one value starts disagreeing about the same issue. Every other lifecycle state is drift rather than a transition, so prkit changes nothing, reports what it found, and either asks or escalates. The exemption reaches label writes and nothing else: creating the PR, committing a handed-in path, and force-pushing a sync all still preview.

## Unblocking what the PR makes stackable

Opening a PR is the exact moment an issue waiting on *this* one can become workable, because the code now exists on a branch even though nothing has merged. Such a dependent moves `blocked` → `stacked` and can be built immediately on a layer cut from this branch.

**Every prerequisite has to permit it, not just this one.** If issue C waits on A and B, opening A's PR must not advertise C while B has no PR. A dependent flips only when each other prerequisite is closed or already sits on a branch this one contains. When a second prerequisite has its own open PR on a separate branch, C would need two stack parents; a layer has one, so prkit leaves C `blocked` and reports both PRs instead of picking one.

**This runs without asking too**, under the same label exemption, but it is reported in one line because the issue being relabelled is a **different** one — not the issue you named, and now advertised as ready to pick up. Nothing about the sequencing is hidden from you; if the stack call is wrong, one `gh issue edit` puts the label back, and [`issuekit`](./issuekit.md) `sync` is the sweep that repairs it later. A draft PR skips the step entirely, because a draft isn't something to build on.

## Stacked PRs

A branch that's a layer in a stack targets the branch below it rather than trunk, and prkit gets that base from [`gitkit`](./gitkit.md) like any other. Three things follow. The diff is the layer's own slice rather than the whole chain, which is the point of stacking. The "current branch equals base" stop can't fire, because a layer's base is never itself. And a sync rebase becomes **cascading** — replaying one layer moves every layer above it, so it goes through gitkit rather than rebasing one branch and stranding the rest.

The body gains a short **stack map**: position, the layer below, what merges first. GitHub renders its own navigation, so this stays to a few lines — it exists for the reader seeing the PR in a notification email, where that navigation is absent, and for whom a diff against a non-trunk base otherwise reads as incomplete.

### The issue link is inert on a layer

GitHub honours a closing keyword only when the PR targets the repository's **default branch**. On any other base `Closes #123` is plain text, so every layer above the bottom one ships an issue link that resolves to nothing and `closingIssuesReferences` comes back empty. Nothing in the PR body is wrong; the platform simply doesn't look.

prkit writes the keyword anyway, because it starts working on its own the moment the layer below merges and GitHub retargets the PR to trunk. What it adds is the fallback in writing: the stack map names the issue the layer closes and says the link registers after the retarget, so a reviewer who finds an empty sidebar doesn't read it as a missing reference and add a duplicate.

After creating a layer PR, prkit queries `closingIssuesReferences` and **reports an empty result as expected rather than as a failure**, naming the sequence that resolves it. That report is the whole point: silence here is what let a broken-looking link ship unnoticed, since the body reads perfectly and nothing else in the workflow contradicts it.

**prkit never retargets the PR to force the link.** Retargeting to trunk discards the base the stack depends on and turns the layer's small diff into the whole chain. There is no API that registers the link early either — `gh issue develop` and the `createLinkedBranch` mutation both refuse a branch that already exists — so waiting for the merge below is the only path, and saying so plainly beats letting somebody go looking for a workaround that doesn't exist.

`gh stack submit` opens a PR per layer with every base set correctly, and **prkit owns that command** — gitkit deliberately doesn't run it, because gitkit never opens anything. A single layer stays a plain `gh pr create --base <parent>`, which is simpler and leaves the layers above untouched.

## Hands off to

[`mergekit`](./mergekit.md), which pulls the PR down into a worktree for local review and QA. The PR now waits on review, so the next move is on the reviewer's side.

A dependent that just moved to `stacked` outranks that: it is work you can start right now while review happens, so the hand-off offers [`issuekit`](./issuekit.md) `start` on the highest-priority one.

Small follow-ups — adding a reviewer, a label, marking a draft ready — get offered rather than auto-run. prkit never merges, closes, or force-pushes without an explicit ask.

## Install

```sh
npx skills add mimukit/skills -s prkit
```

Source: [`skills/prkit/SKILL.md`](../../../skills/prkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`634d5d7` on 2026-09-19._
