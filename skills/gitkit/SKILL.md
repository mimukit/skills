---
name: gitkit
description: >-
  The shared git layer other skills borrow: the worktree path, name, and lifecycle, a worktree's declared setup and teardown, the base branch, rebase versus merge, branch sync, hotfix branches, merged-branch cleanup, lost-work recovery, and stacked branches. Use when the user says "make me a worktree for #42", "where's the worktree for this branch", "tear down this worktree", "set up this worktree", "make this worktree's dev database", "what's the base branch here", "should I rebase or merge", "sync this branch with main", "start a hotfix for the login crash", "backport this hotfix", "clean up my merged worktrees", "I lost a commit", "stack this on #43", or runs "/gitkit", and whenever another skill needs any of those answers.
license: MIT
allowed-tools: Bash, Read
metadata:
  internal: false
---

# gitkit

The core is native [git worktree](https://git-scm.com/docs/git-worktree), with no vendor CLI and no state outside git, so every machine runs the same commands. Two branches go further. [Stacked branches](#stacked-branches) need `gh` and a GitHub remote, and degrade to plain git without them. [`prepare`](#prepare) runs only the commands the repository declares, or the install its lockfile implies when it declares none.

**Not this skill:** committing, opening a PR, reviewing a diff, judging code. gitkit answers *where and how*, never *what the change should be*.

## Modes

| mode | does | lives |
|---|---|---|
| `worktree` | create, adopt, look up, list, and remove a worktree | [below](#worktree) |
| `sync` | catch a feature branch up with its own remote, bring it onto the latest base, and force-push it with a lease | [below](#sync) |
| `prepare` | run the repository's declared setup in a worktree, and its teardown before removal | [prepare.md](./prepare.md), and [below](#prepare) |
| `hotfix` | cut a fix or a quick change from the branch production deploys from, with no issue, and backport it after the merge | [hotfix.md](./hotfix.md), and [below](#hotfix) |
| `clean` | sweep the merged worktrees and branches away, one confirmation each | [clean.md](./clean.md) |
| `rescue` | find work that looks lost and restore it onto a new branch | [rescue.md](./rescue.md) |
| `stack` | build and restack a chain of branches through `gh stack` | [stacks.md](./stacks.md), and [Stacked branches](#stacked-branches) |

**When the mode is not clear from the ask, pick it from the verb and name it in the first line.** "Tidy this up" after a merge is `clean`; "tidy this up" on a branch behind its base is `sync`.

Running inside a container with a bind-mounted repo, or a GUI worktree tool does not show gitkit's worktrees → read [container.md](./container.md), then follow it.

## The convention

### Path

```
$WORKTREE_ROOT/<repo-basename>/<local-branch-name>
```

`$WORKTREE_ROOT` defaults to `~/worktrees`; honor the environment variable when it is set. `<repo-basename>` is the main checkout's directory name.

**Slashes in a branch name flatten to dashes.** A branch `mimukit/6-marketing-site` gets the directory `mimukit-6-marketing-site`, not a nested `mimukit/` parent. The directory name does not round-trip to the branch, so [look a worktree up through git](#look-up-a-branchs-worktree). On a collision (branches `a/b` and `a-b` both flatten to `a-b`), `git worktree add` fails on the existing path: report it and let the human pick a name rather than append a suffix.

Worktrees live **outside** the repository, never in a `.worktrees/` directory inside it, because an in-repo worktree gets swept into docker build contexts, bind mounts, file watchers, and test globs.

### The invariant: one branch, one worktree

**A branch has at most one worktree, and the directory is named after it.** Git enforces this: `git worktree add` refuses a branch that another worktree holds. A worktree is keyed to a *branch*, not to a workflow stage, so implementing a feature and later reviewing its pull request use the same worktree. Never name a worktree by stage (`review-…`, `qa-…`).

**Look a worktree up by branch, through git**, never by reading or guessing a directory path. A worktree in an older root then keeps working.

### Branch naming

- **`issue-<n>-<slug>`** for work that starts from a tracker issue. Slug from the issue title: if it follows a conventional `type(scope): summary` form, strip the prefix; kebab-case the rest, cap at roughly 50 characters on a word boundary, drop a trailing hyphen. An empty slug degrades to a bare `issue-<n>`.
- **`hotfix-<slug>`** for an urgent fix or a quick change that goes straight to the branch production deploys from, with no issue first. Slug from the symptom for a fix, or from the change for a quick change, kebab-cased, capped at roughly 40 characters. A backport of a merged hotfix appends `-to-<target>`. When a hotfix traces to an issue, the branch keeps this shape and the pull request carries the `Closes #<n>` link. On a collision with an existing branch, add a short distinguishing word rather than a counter. **The separator is a hyphen: write `hotfix-<slug>`, never `hotfix/<slug>`.** The skills that read the type off the branch name (commitkit, prkit) match the hyphen form only.
- **`pr-<n>-<slug>`** only for a **fork** pull request, where no local branch exists yet and one must be invented to hold the fetched head. Slug from the head branch name, kebab-cased, capped at roughly 40 characters.
- Anything else takes a branch name the human or the repo's convention supplies. gitkit does not rename it.

**An agent that cuts a branch on its own uses one of the three shapes above.** It never invents another prefix (`feature/…`, `fix-…`, `claude/…`). A name the human types, or one the repo documents, is the only other kind of branch.

For a same-repo pull request there is already a local branch name: use it, never a `pr-*` name.

## `worktree`

All four operations are **idempotent**: a second run never errors and never destroys work.

**No skill may create or remove a worktree through a vendor CLI.** Use native git, so every machine stays in step. A vendor's own metadata about a worktree (the issue its card links to, a status, a comment) has no git equivalent, so a companion skill may reconcile it. gitkit never calls a vendor tool, and works where none is installed.

### Look up a branch's worktree

```sh
git -C "$REPO" worktree list --porcelain
```

Each record carries a `worktree <path>` line and, when a branch is checked out, a `branch refs/heads/<name>` line. Match on the branch to get the path.

### Create, or adopt

Always look first. **If a worktree already exists for the branch, adopt it: report the path and stop.** Never create a second one, never error.

When there is none:

```sh
WT="${WORKTREE_ROOT:-$HOME/worktrees}/$(basename "$REPO")/$(printf '%s' "$BRANCH" | tr / -)"   # slashes flatten to dashes
git -C "$REPO" fetch origin --prune
git -C "$REPO" worktree add -b "$BRANCH" "$WT" "$BASE"
```

- Fetch first, always.
- `$BASE` comes from [The base ref](#the-base-ref), never a hard-coded `origin/main`, and never a sibling feature branch. The one exception is a [stack layer](#stacked-branches), whose base *is* the branch below it, named deliberately by the caller.
- Drop `-b` when the branch already exists locally (a same-repo PR you have fetched, a branch you made earlier); `git worktree add <path> <branch>` checks it out.
- For a **fork** pull request, fetch the head into a local branch first with `git fetch origin "pull/<n>/head:pr-<n>-<slug>"`, then add the worktree on that branch, no `-b`.

Then record what gitkit made, because a later session has no other way to tell its own worktrees from someone else's:

```sh
touch "$(git -C "$WT" rev-parse --absolute-git-dir)/gitkit-created"   # gitkit made this worktree
git -C "$REPO" config "branch.$BRANCH.gitkitCreated" true             # only after -b: gitkit made the branch too
```

- **Both records live in git's own storage.** The worktree marker sits in the worktree's admin directory under `.git/worktrees/`, and `git worktree remove` deletes it with the worktree. The branch key sits in the branch's config section, and `git branch -d` deletes it with the branch.
- **Write the branch key only when this run passed `-b`.** A branch that already existed belongs to whoever made it, and an adopted worktree gets no marker.
- **No record means not gitkit's.** A worktree or branch with no record reads as adopted, and [Remove](#remove) leaves it alone.

When the caller hands the worktree to a person or an agent to work in, run [`prepare`](#prepare) next, on a created and an adopted worktree alike. A scratch worktree that only runs one command skips it.

Report the path and the branch. When the user asked gitkit for the worktree directly, end the reply with [the workspace block](#the-workspace-block). Creating a worktree does not imply doing anything in it. Ends when the worktree exists at `$WT` on `$BRANCH` and its records are written.

### The workspace block

A skill that hands a worktree to a human to work in ends its reply with this block. The labels are fixed; fill the values.

```
Workspace ready
- repo: <absolute path of the main checkout>
- worktree: <absolute worktree path>
- branch: <branch>
- base: <base ref the branch was cut from or tracks>
- state: created | adopted
- for: issue #<n> | PR #<n> | none
```

- **The block names no harness and no app.** A host that can open a session bound to a worktree reads it; any other host shows six plain lines.
- **It starts nothing.** It carries no prompt and no command to run in the worktree. The human decides how the work begins.
- **Print it once, last, and only to a human.** When another skill called gitkit, return the path and the branch to that caller, and the caller prints the block in its own hand-off. An unattended run prints no block, because it works in the worktree by path in its own session.

### Remove

```sh
test -e "$(git -C "$WT" rev-parse --absolute-git-dir)/gitkit-created"   # gitkit made this worktree?
git -C "$REPO" config --get "branch.$BRANCH.gitkitCreated"              # gitkit made this branch?
git -C "$REPO" worktree remove "$WT"
git -C "$REPO" branch -d "$BRANCH"
```

**This is the one removal rule in the collection.** Every skill that removes a worktree or deletes a branch, whether a sweep here, a workspace tool's cleanup, or an issue close-out, follows these five rules:

- **A dirty worktree stops teardown.** Show exactly what would be lost (uncommitted changes, untracked files, unpushed commits) and let the human decide. Never reach for `--force` on their behalf.
- **Remove only a worktree whose marker says gitkit created it.** A worktree without the marker was adopted, and you do not know what is open in it.
- **Delete only a branch whose `gitkitCreated` key is set, and delete it with `-d`**, so git refuses an unmerged branch.
- **One confirmation per removal.** A list of worktrees and branches takes one answer per row, never one answer for the set.
- **A prepared worktree runs its teardown first.** When the `gitkit-prepared` marker exists and the worktree declares `teardown:`, run it after the dirty check and the confirmation, before `git worktree remove`. A failed teardown keeps the worktree and reports the failure. [Teardown](./prepare.md#teardown) holds the procedure.

**The squash exception is the only `-D` gitkit runs.** A squash-merged branch never passes `-d`, because the squash commit has no ancestry link back to the branch. Use `-D` only when `gh` reports a merged pull request for the branch and that pull request's `headRefOid` equals the local branch tip:

```sh
gh pr list --head "$BRANCH" --state merged --json number,headRefOid --jq '.[0]'
git -C "$REPO" rev-parse "$BRANCH"     # must equal headRefOid, or -D is off the table
```

A tip that moved after the merge holds commits the merge never saw, so the branch stays and the report names it. Name the pull request number in that row's confirmation.

**The merged-PR exception lifts the marker rule and the confirmation rule for one PR's own workspace.** When a human tells a caller to merge or close one pull request, and the caller then sees it merged, that instruction is the confirmation to remove the worktree of the PR's head branch and the local head branch. They go whether gitkit created them or not, with no further prompt. The caller passes the PR number, and the exception reaches that one branch and its worktree only. These guards still hold, and each one keeps its item and names it in the report:

- **The human said keep.** "Merge it but keep the worktree" keeps the worktree, and "keep the branch" keeps the branch.
- **The worktree is dirty.** The dirty rule above still stops the removal.
- **The teardown failed.** The teardown rule above still keeps the worktree. Teardown itself runs with no prompt under this exception.
- **The branch tip moved.** Delete with `-d`, or with `-D` only when the tip equals the merged `headRefOid`, as the squash exception states.
- **A layer stacks on the branch.** An open PR whose base is this branch keeps the branch, and the worktree still goes.

When the worktree to remove is the caller's own working directory, run every command from the main checkout with `git -C "$REPO"`. After the removal, say that the session's working directory is gone, and name the main checkout as the place to continue.

Already gone? Report "already gone" and succeed. Ends when each confirmed worktree and branch is gone, or its refusal is reported.

### List

```sh
git -C "$REPO" worktree list
```

A plain inventory. When the user asks to tidy up rather than to look, that is the [`clean`](#clean) mode, which classifies every row before it offers anything.

If paths look wrong after a move or a restore, `git worktree repair <path>` rewrites the back-pointers. Git stores absolute paths in `.git/worktrees/<name>/gitdir` and in each worktree's `.git` file, so moving a worktree by hand always needs a repair.

## The base ref

Never assume `main`. The ladder, in order:

1. `git config --get "branch.$BRANCH.gh-merge-base"`, for a branch that records its own base. [`hotfix`](#hotfix) sets it, and `gh pr create` reads the same key, so the sync, the diff, and the pull request all agree.
2. `gh repo view --json defaultBranchRef --jq .defaultBranchRef.name`, authoritative when the GitHub CLI is available and authenticated.
3. `git symbolic-ref --short refs/remotes/origin/HEAD`, the local record, if it has been set.
4. `git remote set-head origin --auto` to repair an unset `origin/HEAD`, then retry the previous step.
5. Whichever of `origin/main` / `origin/master` actually exists.
6. Ask the human. Do not guess past this point.

Everything downstream uses the answer: `git diff <base>...HEAD`, ahead/behind counts, and the branch a worktree is cut from.

**A stack layer is the one exception.** A layer's base is the branch below it, so the caller names it and this ladder is not consulted for that branch. The ladder still resolves the **trunk** the stack's bottom layer sits on. Everywhere else a sibling-branch base stays banned. See [Stacked branches](#stacked-branches).

## Rebase or merge

> **Rebase onto the base to sync a feature branch, published or not. Merging the base in is an exception that needs a stated reason and the user's consent.**

Rebasing rewrites commit SHAs. On an open pull request, a force-push marks every review thread outdated, human and bot findings alike. That is a cost to **disclose**, not a bar.

- **A sync runs straight through, published branch or not.** Asking for the sync is the consent to its rebase and its `--force-with-lease` push. Stop and ask only on a problem: a dirty tree, a conflict that needs a ruling, a failed gate, or a rejected lease.
- **Report the cost after the push.** On a branch with an open PR, query the GraphQL `reviewThreads` connection for unresolved threads before the rebase, and put the exact number in the hand-off.
- **The merge exception runs only on request.** Unresolved threads are not a reason to stop and offer it. When the user asks for the merge, take [The merge exception](#the-merge-exception).
- **`--force-with-lease`, never bare `--force`.** The lease stops you overwriting a commit someone else pushed while you rebased.
- **On conflict**, resolve it by [Conflicts](#conflicts).

### Conflicts

The agent resolves every conflict and writes every resolution. The human never edits a conflicted file. The only open question per conflict is whether the resolution needs the human's ruling first, and a ruling is a pick between resolutions the agent has already written out.

**Resolve without asking** when the conflict is mechanical, meaning the intent of both sides survives in full:

- **Both sides add independent entries** (imports, exports, routes, list items, changelog lines). Keep both, in the order the file uses.
- **Both sides make the same change.** Keep one copy.
- **One side only reformats.** Keep the other side's content, then run the repo's formatter on the file.
- **A lockfile or a generated file.** Take the base's version, then regenerate it with the repo's own command (`pnpm install --lockfile-only`, the codegen script).
- **The conflict sits in context only.** The base edited or moved the surrounding lines, and the branch's change applies to the new code unaltered.

**Ask first** when the resolution is a decision rather than a merge:

- Both sides change the same behavior in ways that cannot both hold.
- A modify/delete or rename/rename conflict, or a binary file.
- The resolution drops code that either side added or kept.
- You cannot state the intent of each side in one sentence. Run this check on every conflict, mechanical ones included.

An ask names the file, the intent of each side in one sentence, the resolution you recommend, and the alternative, each shown as the code it produces. Collect every ask from one rebase stop into a single question round. Write the chosen resolution yourself.

Guards on every resolution:

- **Save the starting point** before the first rebase: `git update-ref "refs/gitkit/pre-sync/$BRANCH" HEAD`. Each sync overwrites it. `ORIG_HEAD` does not survive a second rebase; this ref makes the whole sync reversible with `git reset --hard "refs/gitkit/pre-sync/$BRANCH"`.
- **Build each resolution from both sides.** A whole-side strategy (`-X ours`, `-X theirs`, `git checkout --ours` on a source file) discards one side without a record, so it resolves lockfiles and generated files only.
- **Run `git diff --check` before each `git rebase --continue`.** It flags a leftover conflict marker.
- **Record resolutions with rerere.** Run the rebase as `git -c rerere.enabled=true rebase …`, so a conflict resolved once replays on the next sync or restack.
- **The gate judges the result.** A resolution is a code change, so the repo's test and build gate runs afterward. A gate failure in a resolved file is yours to fix: rework the resolution and rerun the gate. Ask only when the fix needs one of the decisions above.
- **An unattended caller cannot answer.** With nobody to ask, run `git rebase --abort` and return each open ask, with its recommended resolution, to the caller to escalate. When the run resumes with a ruling, re-run the sync and write that resolution.

### `sync`

The runnable form of the rule above. A sync has **two halves, in this order**: first bring the local branch level with its own counterpart on `origin`, then bring it up to date with the base. Skipping the first half makes a later `--force-with-lease` reject, or silently drop a commit pushed from another machine. Run it in the branch's worktree.

1. **Fix the ground.** Resolve the base with [the base ref ladder](#the-base-ref). Run `git -C "$WT" fetch origin --prune`. Confirm the worktree is on the feature branch and that `git status --porcelain` is empty. A dirty tree stops the sync: report the files and let the human stash or commit. Save the starting point with `git update-ref "refs/gitkit/pre-sync/$BRANCH" HEAD`. Ends when the base name, the branch name, and a clean tree are all known.
2. **Sync with `origin/$BRANCH`.** Run `git rev-list --left-right --count "origin/$BRANCH"...HEAD` when the remote branch exists; it prints `<behind>\t<ahead>`. Behind count `0` means nothing to take. Otherwise run `git pull --rebase origin "$BRANCH"` to replay your local commits on the remote ones, and resolve every conflict by [Conflicts](#conflicts). A branch with no remote counterpart skips this step. Ends when the local branch contains every commit on `origin/$BRANCH`.
3. **Measure the gap to the base.** Run `git rev-list --left-right --count "origin/$BASE"...HEAD`. Behind count `0` means the branch is already on the latest base: run the **Refresh a prepared worktree** step below when the previous step took commits, push what it took, report that, and stop. Ends with a behind count and an ahead count.
4. **Count the review threads.** When a pull request is open, count its unresolved threads from the GraphQL `reviewThreads` connection. This step asks nothing; the count goes into the hand-off. Ends with a thread count, or with no open pull request.
5. **Rebase onto the base.** Run `git -c rerere.enabled=true rebase "origin/$BASE"`. Ends when the rebase reports success or stops on a conflict.
6. **Resolve every conflict.** For each stop, list the files with `git diff --name-only --diff-filter=U`. Sort each conflict by [Conflicts](#conflicts), write the mechanical resolutions, and ask one question round for the rest. Write the ruled resolutions, run `git diff --check`, stage the files, then `git rebase --continue`. Repeat for every remaining stop. Ends when no conflict marker remains and the rebase is complete, or, for an unattended caller, on an aborted rebase with its open asks returned.
7. **Refresh a prepared worktree.** When the `gitkit-prepared` marker exists and the sync took commits, run `prepare`'s change check and the block it selects, per [prepare.md](./prepare.md#2-decide-what-runs). It runs before the gate, because a gate that runs on a stale install or a stale schema fails for the wrong reason. A failed block stops the sync before the push. Ends with the block's exit code, or with nothing watched changed, or with no marker.
8. **Prove the branch still works.** Run the repository's own test and build gate. Report a failure with its output and stop before the push. Ends with a pass, or a stop.
9. **Push with a lease.** Run `git push --force-with-lease origin "$BRANCH"`. A rejected lease means somebody pushed while you rebased: fetch, show the new commits, and ask before any retry. Ends when the remote branch matches the local one.

#### Hand off

Report the commits taken from `origin/$BRANCH`, the base, the behind and ahead counts, what the refresh ran, the gate result, the pushed branch, and the review threads the push outdated. List each resolved file with its class and a one-line reason, mark the ones the human ruled on, and name `refs/gitkit/pre-sync/$BRANCH` as the undo point. Say when the branch was already current and nothing changed. Next, review the pull request diff on the new base, and re-request review when threads went outdated.

### The merge exception

When the user takes the merge, or asks for it outright, it is still a sync, and it says so:

```sh
git merge "origin/$BASE" -m "chore(repo): sync with origin $BASE"
```

- **Use the fixed subject**, never git's default `Merge branch 'main' into …`.
- **Interpolate the base** from [the base ref](#the-base-ref); never hardcode `main`.
- **No `--no-ff`.** A sync that can fast-forward writes no commit, and `--no-ff` would make an empty merge commit.
- **Name a concrete reason with the ask**, such as "Merging instead of rebasing because this PR has 3 unresolved review threads". If you cannot name what rebasing would break, rebase.

### Never bare `git pull`

A bare `git pull` does whatever the user's `pull.rebase` and `pull.ff` config says, so it may merge, rebase, or refuse a divergent branch. Use `git pull --rebase`, or `git pull --ff-only` when you want the sync to fail loudly rather than resolve itself. The same holds for `git pull` invoked to refresh the base branch itself: configure it or pass the flag, but never let the default run.

## `prepare`

Make a worktree ready to run with the commands its repository declares in a `## Worktree setup` section of its agent-guide file: `setup:` on the first run, `update:` when a watched path changed, and `teardown:` before [Remove](#remove) deletes the worktree. A `gitkit-prepared` marker in the worktree's admin directory records the commit each run passed at. Teardown runs only where that marker exists, so gitkit never removes a resource it did not set up.

The procedure, the declaration format, the template, and the lockfile list live in **[prepare.md](./prepare.md)**. Read it when a run prepares a worktree, when a sync took commits on a prepared one, and when a removal meets one.

## `hotfix`

Start an urgent fix or a quick change with no issue: cut a `hotfix-<slug>` worktree from the branch production deploys from, move a change already written in the main checkout into it, and record that branch as the pull request base. After the merge, `backport` replays the commits onto each branch the project names. The project declares its flow in a `## Hotfix flow` section of its agent-guide file. Without one, gitkit reads CI deploy triggers, and with no evidence it uses the default branch.

The procedure, the declaration, and the template live in **[hotfix.md](./hotfix.md)**. Read it when a run starts or backports a hotfix. gitkit stops at the prepared worktree, as everywhere else: the change, the commit, the pull request, and the deploy belong to other skills and to CI.

## `clean`

Sweep away the worktrees and branches whose work has landed, on your machine and on `origin`. It classifies every worktree, local branch, and remote branch into one bucket (active, adopted, dirty, reapable, orphan) and removes only the reapable ones, one confirmation at a time. A remote delete takes its own confirmation and its own proof that the work landed. Last, it deletes qakit screenshot folders in `~/qakit/` older than 14 days whose QA plan is on no branch it kept.

The three merge detections and the per-item confirmation live in **[clean.md](./clean.md)**. Read it when a run sweeps.

The [Remove](#remove) rules govern every removal the sweep makes. It confirms each row on its own, uses `-D` only under the squash exception, never touches a worktree without gitkit's marker, and stops on a dirty one. On `origin` it never deletes the base branch and never deletes the head of an open pull request.

## `rescue`

Find work that looks lost and put it back. A bad rebase, a hard reset, a deleted branch, a stash nobody can find: the commits usually still exist, and git's own logs say where they went.

The procedure is in **[rescue.md](./rescue.md)**. It is **read-only until the restore**, and the restore **adds a branch rather than moving one**. It states the bound: an unreachable commit lives until git prunes it.

Never run `git gc`, `git prune`, or `git reflog expire` during a rescue, in any mode.

## Stacked branches

A **stack** is a chain of branches in one repository where each branch is cut from the one below it and the bottom sits on trunk, so work can build on a branch still in review. The `gh stack` extension drives it. The command surface, the preflight, and the plain-git fallback live in **[stacks.md](./stacks.md)**; read it when a run touches a stack.

### One worktree per layer

**Each layer keeps its own worktree, cut from the layer below.** The [one branch, one worktree](#the-invariant-one-branch-one-worktree) invariant is unchanged: a layer is a branch, so it gets a directory named after it, and [lookup is still by branch](#look-up-a-branchs-worktree).

gitkit runs the stack plumbing only. It never runs `gh stack submit` (pull request authoring), `gh stack merge` (merging), or the navigation commands, as [stacks.md](./stacks.md#commands-gitkit-does-not-run) lists.

**When asked how deep a stack should go, give no number.** State the mechanism and leave the depth to the human: each layer is one more pull request to review and one more branch to restack whenever anything below it changes.

## Notes

- **Creating, adopting, and syncing run with no prompt.** A removal or a branch delete previews and waits for an OK, unless [the merged-PR exception](#remove) covers it. A teardown rides on the confirmation of its removal.
- **No shell available** (e.g. a browser-based agent)? Then you cannot run git. Reason from what the user provides and **print the exact commands** as a codeblock for them to run, and never report a worktree created or removed that you could not perform.
