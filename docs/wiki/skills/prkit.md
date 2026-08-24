# prkit

Draft and open a GitHub pull request from your branch — title, summary, and test plan written from the actual commits and diff.

**Reach for it when** the commits are in and the work is ready for review.

| | |
|---|---|
| Modes | single procedure; open or draft-only |
| Tools | `Bash`, `Read`, `Write`, `Skill` |
| Writes | a pull request via `gh`; pushes the branch |
| Visibility | public |

## What it does

prkit turns the commits on the current branch into a clean pull request: a title in the repo's commit style, a body explaining *what changed and why*, and a test plan — all inferred from the real diff. Creation goes through the [`gh` CLI](https://cli.github.com), reusing the repo's PR template when one exists.

## It reads the commits, not the diff — when it can

On a branch built through this workflow, the commit messages already are the material a PR body needs. [`commitkit`](./commitkit.md) wrote each one from the change itself, so re-deriving the description from the raw diff produces a worse result at many times the cost.

So prkit reads `git log` first and reaches for the full diff only when the commits don't explain the change: thin or generic messages (a branch of `wip` and `fix typo`), work that came from outside this workflow, files in the stat that no commit accounts for, or a specific detail needed for the test plan.

## gitkit owns the git questions

prkit doesn't re-derive them:

- **The base ref** comes from [`gitkit`](./gitkit.md). Repos whose default is `develop` or `trunk` are real, and getting this wrong silently produces an empty or enormous diff — both of which look like a valid PR. Without gitkit, `gh repo view --json defaultBranchRef` is the authoritative fallback.
- **Branch naming**, when a PR is attempted from the default branch and a feature branch has to be created.
- **The sync rule**, which resolves to rebase.

Everything is diffed against `origin/<base>` after a fetch, not a local `<base>` that may be behind.

## The sync step

A PR opened from a stale branch either merges outdated code or lands with GitHub's conflicts banner. So before pushing, prkit checks whether the branch is behind and rebases if so.

Whether that needs your OK turns on one thing: an **unpublished** branch rebases straight through, because nothing outside your machine points at the commits being rewritten. A branch already pushed previews the rebase and its `--force-with-lease` together and waits. At PR-open time the branch is usually unpublished, which is why this normally runs without a prompt.

**Rebase conflicts stop everything.** The conflicted files get listed and resolved before any push or PR.

A clean rebase doesn't trigger a re-read — replaying commits onto a new base doesn't change what they say. The exception is a rebase you resolved conflicts in, where real edits happened during the replay; then just the touched files get re-read, not the whole branch.

## Proof artifacts embed inline

When a [`verifykit`](./verifykit.md) bundle exists at `docs/verify/verify-<slug>-YYYY-MM-DD/`, prkit splices its ready-made `proof.md` into the body under a **Proof** section.

There's no upload work — the images are already published to a hidden `refs/verify-assets/*` ref with SHA-pinned raw URLs that render inline. prkit only *reads* the fragment; it never runs the publish itself.

No bundle means no Proof section and prkit works exactly as it otherwise would. A bundle whose `proof.md` points at local paths — verifykit couldn't publish, typically a private repo — gets a note listing those paths for manual attachment rather than embedded dead links.

## Update, don't duplicate

Before creating anything, prkit checks for an existing open PR on the branch and edits that one instead of opening a second. Bodies go through `--body-file` rather than `--body`, because multi-line markdown with checkboxes is flaky through the flag.

## It advances the linked issue

Opening the PR is the moment a linked issue moves from being worked to awaiting review, so its lifecycle label flips `in-progress` → `in-review` — the same transition [`issuekit`](./issuekit.md)'s sync mode performs.

This only happens when the PR actually references an issue, and prefers issuekit when installed, falling back to a plain `gh issue edit`.

**It runs without asking** — prkit's one exemption from its own preview rule. Opening the pull request *is* the instruction to move the issue to review, so a confirmation asks a question the invocation already answered, and the cost of asking is an issue that keeps advertising itself as being worked while its PR sits open. The exemption belongs to the step rather than to whoever called it, so a human at the keyboard and an unattended [`afkkit`](./afkkit.md) run get identical behavior. That symmetry is the point: a caller-granted bypass can drift open, and the copy inside an unattended orchestrator is the one nobody would notice drifting.

The exemption is narrow in two directions. It covers exactly two starting states — `in-progress` gets the flip, `ready` gets `in-review` added with no removal — because those are the only two a PR legitimately arrives from. Every other lifecycle state is drift rather than a transition, so prkit changes nothing, reports what it found, and either asks or escalates. And it covers this one label move: creating the PR, committing a handed-in path, and force-pushing a sync all still preview.

## Hands off to

[`mergekit`](./mergekit.md), which pulls the PR down into a worktree for local review and QA. The PR now waits on review, so the next move is on the reviewer's side.

Small follow-ups — adding a reviewer, a label, marking a draft ready — get offered rather than auto-run. prkit never merges, closes, or force-pushes without an explicit ask.

## Install

```sh
npx skills add mimukit/skills -s prkit
```

Source: [`skills/prkit/SKILL.md`](../../../skills/prkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`d2e9d3b` on 2026-08-24._
