## Mode `start <n>`: prepare the review workspace

`start` creates or adopts the worktree, gets the project running, prints the review pack, and stops. It syncs only under [Sync consent](../SKILL.md#sync-consent).

### 1. Resolve the head

```sh
gh pr view <n> --json headRefName,headRefOid,headRepositoryOwner,isCrossRepository,author,title,body,url
```

A **cross-repository (fork) PR** is read-only from here. Say so at setup time. A fork PR also refuses the "and sync" ask: say so here, and carry on with a plain `start`.

Record `headRefOid`. It is the **reviewed head**, the commit the review pack is built on and the reviewer is about to judge, and [`close`](./close.md#merge-path) merges that commit and no other. A sync in [Measure the base-branch gap](#3-measure-the-base-branch-gap-and-report-it) replaces it. Ends when the head branch, the reviewed head SHA, and the fork status are known.

### 2. Get a worktree, adopting first and creating only if needed

Ask gitkit for the head branch's worktree; reuse it, and create one only when none exists.

- **Same-repo PR.** Fetch the head branch (`git fetch origin <head>:<head>` or `git fetch origin` plus a local checkout), then ask gitkit for that branch's worktree. Pushes from it go back to the PR.
- **Fork PR.** There is no local branch yet, so make one: `git fetch origin "pull/<n>/head:pr-<n>-<slug>"`, where `<slug>` is the head branch name kebab-cased and capped at roughly 40 characters. Then the worktree is created on *that* branch, and takes its name.
- **Already have one.** Adopt it and say so. Re-running `start` must never error or discard work in progress. If the adopted worktree is dirty, **report what's uncommitted before doing anything else** and let the reviewer decide whether to continue.

Ends when the worktree path is known, it sits at the reviewed head, and its dirty state is reported.

### 3. Measure the base-branch gap and report it

```sh
git fetch origin
git rev-list --left-right --count origin/<base>...HEAD    # "<behind>\t<ahead>"; left > 0 means behind
```

**Report the two numbers.** Without a sync request, stop there: no rebase, no merge of the base, no push.

On a sync request, hand the sync to **gitkit** in the worktree. It resolves to a rebase, stops on a dirty tree or a conflict that needs a ruling, and reports the review threads the push outdated. Run it here, before [Set the project up](#4-set-the-project-up), so the install matches the synced lockfile. Without gitkit, rebase onto the base and push with `--force-with-lease`. A behind count of `0` needs no sync; say so. After the sync pushes, read `headRefOid` again and record it as the reviewed head, and measure the two numbers again. A stopped sync leaves the branch where it was: report why, and carry on unsynced.

This step ends when both numbers are reported, and, on a sync request, when the sync has pushed and the synced head is recorded, or the sync has stopped with its reason.

### 4. Set the project up

**Hand the setup to gitkit `prepare`** in the worktree. It runs the repo's declared worktree setup (install, untracked files, the worktree's own database, seed), or only the lockfile install when the repo declares none, and it skips an adopted worktree whose watched files have not changed. A failed setup stops this step: report the command, the exit code, and the output tail gitkit returns. Without gitkit, run the `setup:` block of the repo's `## Worktree setup` section from the worktree root, otherwise the install the lockfile implies.

Then start the app. The scripts tell you the dev command; prefer a project-local run or dev skill when one exists. Copy `.env.example` to `.env` only if that is the repo's documented setup, the file is absent, and the declared setup did not already write it.

Ends on an observed result. For a server, that is the app answering on its port. For anything else, it is the project's own observable: a CLI that prints its `--help`, a library whose build passes. Otherwise it ends on a reported reason the project cannot start, with the command and its output.

### 5. Print the review pack

- PR title, number, author, URL, and the body's summary.
- The linked issue and its acceptance criteria, when the PR references one.
- The commits (`git log origin/<base>..HEAD --oneline`) and the file-level shape of the diff (`--stat`).
- The QA plan, if the repo has one for this change, and any proof artifacts.
- **Unresolved review threads with `file:line` and the comment text**, bot or human.
- Any follow-up nits the PR body itself records.
- CI status per check, and the behind/ahead counts against `origin/<base>`.

**Name each missing item**, for example "No QA plan in this repo's conventional location". Ends when every item above is printed or named as missing, and the pack shows the reviewed head SHA.

### 6. Hand off

_Write every hand-off in this skill in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

**What changed.** Report whether the worktree was adopted or created. Report what gitkit `prepare` ran: the declared setup, an update and the paths that triggered it, the lockfile install only, or nothing. Report the sync: not asked, or asked and its result, with the commits rebased and the review threads the push outdated. When no sync ran, state that nothing was pushed.

**Where it landed.** Give the single command that starts the app. Then print gitkit's workspace block as the last lines of the reply, after **Next**, with `for: PR #<n>` and the PR's base branch. Without gitkit, print the same block:

```
Workspace ready
- repo: <absolute path of the main checkout>
- worktree: <absolute worktree path>
- branch: <PR head branch>
- base: <PR base branch>
- state: created | adopted
- for: PR #<n>
```

The block starts nothing.

**Next.** The reviewer reads, runs, and forms an opinion. When the branch is still behind, name **gitkit `sync`** inside the worktree as the first move, and give the behind count. Then `close <n>` executes whichever verdict they reach, whether a merge or a fix round. Say both halves.

Then stop. mergekit does not judge the code, and does not proceed to `close` on its own.
