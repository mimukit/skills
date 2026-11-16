---
name: prkit
description: >-
  Draft and open a GitHub pull request from your branch, with title, summary, and test plan written from the actual commits and diff, then created with the gh CLI, embedding verifykit proof artifacts inline when a bundle is present. Use when the user asks to open a PR, says "create a pull request", "raise a PR", "submit this for review", or "gh pr create", even if they don't spell out the title or body.
license: MIT
allowed-tools: Bash, Read, Write, Skill
metadata:
  internal: false
---

# prkit

## Preview and authorization

prkit previews each mutation outside its [label exemption](#8-advance-the-linked-issue) and waits for an OK: creating or editing the PR, and committing a handed-in path. A sync and its force-push run without a preview, by gitkit's sync rule. **A caller that carries the user's recorded authorization satisfies the preview for the actions that authorization names.** afkkit is the case in point: the user's unattended request authorizes the commits on the issue's own branch, the push of that branch, and the PR, so prkit runs the handed-in QA-plan commit and `gh pr create` without a prompt, and names the authorization in the hand-off. An action outside the named scope still previews, and an unattended caller escalates it rather than answering for the user: a rebase of a published branch with its `--force-with-lease`, a push to another branch, a merge. prkit never infers an authorization the caller did not state.

## Draft-only route

A request for the title and body only ("draft the PR description") takes this route. It reads and prints. The index, the refs, the remote, the PR, and the issue labels stay as they were.

1. Run read commands only: no fetch, push, commit, rebase, or gh writes.
2. Run the read-only checks in [Preflight](#1-preflight). On the default branch or a detached HEAD, draft anyway, say that a branch is needed before the PR can open, and create nothing.
3. Run [Gather context](#2-gather-context) without `git fetch`. Read the remote base tip with `git ls-remote origin refs/heads/<base>`, compare it with `git rev-parse origin/<base>`, and say in the draft when the local base ref is behind.
4. Apply [Write the title and body](#5-write-the-title-and-body) and the bundle selection and freshness check in [Embed proof artifacts](#6-embed-proof-artifacts-if-present).
5. Print the title and the body as code blocks. When `gh pr view` shows an open PR on the branch, say that the draft would replace that PR's title and body.

**Done when** the title and body are printed, and no `git fetch`, `git push`, `git commit`, `git rebase`, `gh pr create`, `gh pr edit`, or `gh issue edit` ran. Hand off in one line: say nothing changed, and name the next move, which is to ask prkit to open the PR from this draft.

## Procedure

### 1. Preflight

- Stop and say so if `gh auth status` fails.
- If `git branch --show-current` is empty, stop: detached HEAD needs a branch before a PR can be opened. Offer to create or switch to one.
- If the current branch is the default branch, stop: a PR needs a feature branch. Offer to create one (`git switch -c <name>`) before continuing, and **get the name from gitkit**, which owns branch naming. Work that traces to an issue gets `issue-<n>-<slug>`; an urgent fix or a quick change that skips the issue gets `hotfix-<slug>`; anything else keeps whatever name the repo's convention or the human supplies.

### 2. Gather context
Get the base branch from **gitkit**, then read what the branch changes. Fetch first, and diff against `origin/<base>`, not a local `<base>`:

```sh
git fetch origin                                         # refresh remote-tracking refs before anything else
git log origin/<base>..HEAD --format='%s%n%b'            # commits in this PR, with their bodies
git diff origin/<base>...HEAD --stat                     # files touched
```

Read the full diff (`git diff origin/<base>...HEAD`) only when commits are thin or the stat shows unexplained files. Skip lockfiles, build output, and vendored directories.

**gitkit owns base-ref resolution.** A hotfix branch can target the branch production deploys from, and gitkit returns that branch. Without gitkit, `git config --get branch.<branch>.gh-merge-base` comes first when it is set, then `gh repo view --json defaultBranchRef -q .defaultBranchRef.name` is the authoritative fallback, and ask rather than guess when it can't answer. Re-check the current branch against the base gitkit returns and stop if they match.

**A stack layer's base is the branch below it, not the repo default.** When this branch is a layer in a stack, gitkit returns the parent branch, and every `origin/<base>` below means that branch instead. The diff is then the layer's own change, and the "current branch equals base" stop does not fire. Ask gitkit whether the branch is a layer rather than inferring it; without gitkit, `gh pr view --json baseRefName` on an existing PR is the fallback.

### 3. Sync with the base branch
Before pushing, check whether the branch is behind the base tip you just fetched:

```sh
git rev-list --left-right --count origin/<base>...HEAD   # "<behind>\t<ahead>"; left > 0 means behind
```

- **Behind by zero**: nothing to do, so go to [Push the branch](#4-push-the-branch).
- **Behind**: the branch needs `origin/<base>` brought in. **gitkit owns the sync rule**, and it resolves to **rebase** (`git rebase origin/<base>`). **Inside a stack, the rebase is cascading** (`gh stack rebase --upstack`), because replaying this layer moves every layer above it; hand that to gitkit rather than rebasing the one branch. The sync runs without an OK, published branch or not: gitkit stops to ask only on a problem, such as a conflict that needs a ruling or a rejected lease. Without gitkit, rebase and push with `--force-with-lease`, and stop on any of those problems.
- **Rebase conflicts**: if the rebase stops on a conflict, **resolve it yourself**; the user never edits a conflicted file. List the conflicted files (`git diff --name-only --diff-filter=U`). gitkit owns the conflict rule: it writes mechanical resolutions without asking and asks the user to rule on any resolution that is a decision, then writes the chosen one. Without gitkit, resolve additive conflicts directly and ask before any resolution that drops either side's code. Then complete the rebase (`git rebase --continue`). Do not push, and do not open the PR, until the working tree is clean and the sync is finished. If the user declines the sync, say the PR may show conflicts and proceed only if they confirm.

After a rebase with resolved conflicts, re-read only the resolved files (`git diff origin/<base>...HEAD -- <paths>`); after a clean rebase, keep the title and body you derived.

### 4. Push the branch

**First, commit any handed-in path.** When a caller hands prkit a file that must travel with the branch, most often the manual QA plan that **qakit** wrote at `docs/qa/NNNN-qa-<slug>-YYYY-MM-DD.md` and named in its hand-off (directly, or through afkkit), and that file is still uncommitted, commit it here:

```sh
git add -- <handed-in path> && \
git commit -m "docs(qa): add manual QA plan for <feature>" -- <handed-in path> && \
git show --name-only --format= HEAD
```

The trailing pathspec commits that path alone. Anything else already staged stays staged and stays out of the commit. A pathspec commit takes the working-tree copy of the path, which is right here, because the handed-in file travels whole. **The `git show` line must print exactly the handed-in path.** Any other path in the output means the commit is wrong, so stop and report it before the push.

Commit only a path the caller **named**. When `git status` shows other staged or unstaged work the user seems to want in the PR, point it out and offer to commit it first.

Push the branch:

```sh
git push -u origin HEAD
```

If the branch was rebased ([Sync with the base branch](#3-sync-with-the-base-branch)) and the remote rejects a normal push, use `git push --force-with-lease` (never bare `--force`). A rejected lease means somebody else pushed: fetch, show their commits, and ask before any retry.

### 5. Write the title and body
- **Title**: one line, imperative, in the repo's commit style (match `git log`, often Conventional Commits like `feat(auth): add SSO login`). No trailing period.
- **Title on a hotfix branch**: a fix on a branch named `hotfix-<slug>` takes the type `hotfix`, so the title reads `hotfix(scope): restore session cookie on refresh`. A quick change that is not a fix keeps the type of its commits, such as `docs(pricing): correct the annual price`. The branch name decides between `fix` and `hotfix`, not how bad the bug is. Drop back to `fix(scope):` in a repo whose PR-title lint validates types against the [Conventional Commits](https://www.conventionalcommits.org) set, and say once that you did.
- **Body**: if `.github/pull_request_template.md` (or `PULL_REQUEST_TEMPLATE.md`) exists, read it and fill it in *exactly*, matching its sections and checkboxes. Otherwise use: a one-paragraph **Summary** of what changed and why, a **Changes** bullet list, and a **Test plan** (how it was verified, or checkboxes for what to run). Reference the issue in the body (`Closes #123`) when there is one.
- **Decisions taken for the user go first.** When a caller hands in assumptions or decisions it made without the user (an unattended run's **Assumptions**, a build prompt's "decisions I took on your behalf"), put them as text in the body's first section, above the Summary, or at the top of the template's first section.
- **Body on a hotfix**: lead with the symptom a user saw and what triggered it, then the fix. For a quick change, lead with what changed and why it could not wait for the issue flow. Add a **Rollback** line naming the revert (`git revert <sha>`). Keep the test plan, and say plainly what you could not verify.
- **Stack map**, on a layer only. Add two or three lines naming this layer's position, the branch and PR directly below it, and what merges first. Say plainly that the PR targets the layer below rather than trunk.
- **On a layer, `Closes #123` is written but inert until the retarget.** GitHub honors a closing keyword only on a PR that targets the repository's **default branch**. Write `Closes #123` anyway: it takes effect once the layer below merges and GitHub retargets this PR to trunk. In the stack map, name the issue this layer closes and state that the link registers after the retarget.

### 6. Embed proof artifacts (if present)
This step runs only when a verifykit proof bundle exists. verifykit leaves a dated bundle at `docs/verify/NNNN-verify-<slug>-YYYY-MM-DD/` (slug = the linked issue number, else the feature slug; older bundles have no `NNNN-` serial) with a ready-to-embed `proof.md`. If more than one matches, use the highest serial, else the newest creation date; if that still leaves a tie, ask which run to use.

**Embed the selected bundle only when it shows this branch head.** verifykit opens the bundle's `notes.md` with fixed lines: `commit: <full sha>`, `dirty: <yes|no>`, `url:`, and `captured:`. The bundle is fresh when it reads `dirty: no` and the recorded commit is `HEAD`, or differs from `HEAD` in docs only:

```sh
git diff --quiet <recorded commit> HEAD -- . ':!docs/qa' ':!docs/verify'   # exit 0 = no code change since the capture
```

A bundle with no `commit:` line, with `dirty: yes`, with a recorded commit that `git diff` cannot resolve (a rebase rewrote it), or with any code change since the capture is **stale**. Embed nothing from a stale bundle, and say in the hand-off which bundle was stale and why; a fresh verifykit run is the fix. Splice the selected fresh `proof.md` into the body under a **Proof** section, as-is. prkit only reads the bundle; it never runs verifykit's publish. If a bundle exists but its `proof.md` points at local paths (verifykit couldn't publish, e.g. on a private repo), don't embed dead links: add a short note listing the local artifact paths for manual attachment instead.

### 7. Create or update the PR
Check for an existing PR on this branch:

```sh
gh pr view --json url,state 2>/dev/null
```

- **If the command returns a PR with `state` equal to `OPEN`**: update it with `gh pr edit --title "…" --body-file <file>` rather than opening a second.
- **If no PR exists, or the returned PR is merged/closed**: create a new one.

Use `--body-file` with a temp file in the system temp dir, and remove it afterward.

```sh
gh pr create --base <base> --title "…" --body-file <bodyfile>
# add --draft when the user wants a draft, or the work is incomplete
```

**Open several layers of a stack at once with one command.** `gh stack submit` creates a PR per branch with each base set correctly.

```sh
gh stack submit --auto        # a PR per layer, bases already correct
```

Write each layer's title and body first, exactly as above, then submit. Opening a **single** layer stays a plain `gh pr create --base <parent>`.

**On a layer, check the closing link and report it.** Run this once per layer PR, right after it is created or updated, and skip it on a PR whose base is the default branch:

```sh
gh api graphql -f query='{repository(owner:"<owner>",name:"<repo>"){pullRequest(number:<n>){closingIssuesReferences(first:5){nodes{number}}}}}'
```

- **An empty result on a layer is expected.** Report it as a fact, and say the link registers after the layer below merges and GitHub retargets this PR.
- **A non-empty result on a layer means GitHub already retargeted the PR.** Report the issue numbers it returns.
- **Do not retarget the PR to trunk to force the link.** No API registers the link on a non-default base; `gh issue develop` and the `createLinkedBranch` mutation both refuse a branch that already exists.

### 8. Advance the linked issue
Flip the linked issue's lifecycle label `in-progress` → `in-review` (the same transition issuekit's `sync` mode performs when a PR opens). Do this only when the branch name (`issue-123-…`) or the commits reference an issue (`#123`, `Closes #123`); skip this step if there is none.

- **Prefer issuekit when it's installed.** Invoke it to reconcile the label. Otherwise fall back to the equivalent `gh` call yourself:

```sh
gh issue edit <n> --remove-label in-progress --add-label in-review
```

- **Run it without asking.** Label writes are exempt from prkit's preview rule, in every step and for every caller. Report the flip in the hand-off.
- **The transition covers two starting states and no others, and both replace.** An issue carrying `in-progress` gets the flip above. An issue carrying `ready` gets `--remove-label ready --add-label in-review`, and you say in the hand-off that the issue arrived unstarted.
- **Never add a lifecycle label beside another one.** issuekit's map carries exactly one status label at a time.
- **Any other lifecycle state is drift, not a transition.** For `blocked`, `needs-planning`, `triage`, `needs-info`, already `in-review`, or no lifecycle label at all, stop and change nothing. Report the state you found. Ask when a human is present; escalate when the run is unattended.
- If the `in-review` label is missing from the repo, point the user at repokit or give `gh label create in-review --color 5319E7 --description "a PR is open, awaiting review or merge"`, and don't mutate around the gap.

### 9. Unblock what this PR makes stackable

A dependent of this issue can move `blocked → stacked` and be built on a layer cut from this branch before this PR merges. Run this only when the PR closes an issue that something else depends on:

```sh
gh issue view <n> --json blocking                              # issues waiting on this one
gh issue view <dep> --json blockedBy,labels                    # every prerequisite of one dependent
gh pr list --state open --json number,headRefName,isDraft      # open PRs, read once
gh issue edit <dep> --remove-label blocked --add-label stacked
```

**A dependent flips only when every prerequisite permits it.** Check each dependent labeled `blocked` against all its prerequisites, not just this one. A prerequisite other than this issue permits the flip when it is closed, or when its open, non-draft PR sits on a branch this branch already contains (`git merge-base --is-ancestor origin/<head> HEAD`). Find a prerequisite's PR by its `issue-<p>-` head branch. Below `gh` 2.94.0, read the `Blocked by #N` body lines instead of `blockedBy`.

- **A prerequisite is open with no PR** → leave the dependent `blocked`, and report which prerequisite holds it.
- **Another prerequisite has its own open PR on a branch this one does not contain** → the dependent would need two stack parents, and a layer has one. Leave it `blocked`, and report both PRs. Choose neither one.

**Run it without asking**, under the same label exemption as [the `in-review` flip](#8-advance-the-linked-issue). These labels relabel a **different** issue than the one the user named, so state the whole consequence in one line:

> PR #51 opened → #52 and #53 move `blocked → stacked`, so both can be started now on layers off `issue-51-oidc-provider`. #54 stays `blocked`: #49 has no PR yet.

- **`stacked` missing from the repo** → point at repokit or `gh label create stacked --color 006B75 --description "prerequisite is in flight with an open PR; workable now on a branch stacked on it"`, and don't mutate around the gap.
- **No dependents, or a draft PR** → skip the step.

**Done when** every dependent of this issue either moved to `stacked` with all its prerequisites checked, or stayed with its holding prerequisite or its competing stack parents named.

### 10. Hand off

_Write this section in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

**What changed.** Report the PR created or updated (title and number), whether a sync rebase ran, whether a handed-in path was committed, whether a proof section was embedded or a bundle was skipped as stale, whether the linked issue was flipped to `in-review`, which dependents moved to `stacked`, and which stayed `blocked` and why. When a caller's authorization replaced the preview, name the caller and the actions it covered.

**Where it landed.** Give the PR URL and the branch it points at. Mention that CI will run if configured. On a layer, name the branch it targets and say it is not trunk. On a layer, also report the closing-link check: say the issue link is inert for now, and say it registers after the layer below merges and GitHub retargets this PR.

**Next.** Route the PR to review: **mergekit** `start <n>` when it's installed pulls it down into a worktree for local review and QA; otherwise review it on GitHub. **A dependent that just moved to `stacked` outranks that**: offer **issuekit** `start <n>` on the highest-priority one. First offer, don't auto-run, the small follow-ups when they apply: `gh pr edit --add-reviewer <user>`, `--add-label <label>`, or `gh pr ready` for a draft.

## Notes

- **Never** merge, close, or force-push without an explicit ask. Creating or editing a PR is fine; `gh pr merge` is not, unless requested.
- If the branch is not ahead of the base (no commits), stop and say there's nothing to open a PR for.
- No shell or `gh` available (e.g. a browser-based agent)? Then you can't push or call `gh`. Instead read the diff the user provides and print the finished PR **title** and **body** as codeblocks for them to paste into the GitHub "New pull request" form.
