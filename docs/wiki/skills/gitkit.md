# gitkit

The shared git layer every other skill borrows — worktree convention and lifecycle, base-ref resolution, rebase-versus-merge policy, and stacked branches.

**Reach for it when** you need a worktree, when you want to build on a branch that's still in review, or when another skill needs any git fact it shouldn't be re-deriving.

| | |
|---|---|
| Modes | `worktree` · `sync` · `clean` · `rescue` · `stack` |
| Tools | `Bash`, `Read` |
| Writes | git worktrees, branches, and stack layers |
| Visibility | public |

## What it does

gitkit is the one place the git facts live that every other skill keeps re-deriving: **where a worktree goes and what it's named, how it's created, adopted, and removed, which branch is the base, when to rebase versus merge, and how to stack a branch on one that hasn't merged yet.**

Its **core** isn't clever. All of it is native [git worktree](https://git-scm.com/docs/git-worktree) — no vendor CLI, no GUI dependency, no recorded state anywhere but git's own. That's the point: a laptop with a desktop dev tool and a headless Linux box run *identical* commands, so there's no second code path to keep in sync and no degraded mode to reason about.

**[Stacked branches](#stacked-branches) are the one part that sits outside that**, and the page says so rather than quietly weakening the claim. That branch drives GitHub's `gh stack` extension, so it needs `gh` and a GitHub remote. It degrades to plain git rather than failing, and nothing else in the skill depends on it, so a box with no `gh` runs everything else untouched.

It's a **primitives skill**. Most of its runs come from another skill calling it, not from a human saying its name. It answers *where and how*, never *what the change should be* — committing, opening a PR, and judging code all belong elsewhere.

## Modes

Five, though you rarely name one. Three of them have their own sections further down this page — [`worktree`](#operations-are-idempotent) is the worktree lifecycle, [`sync`](#sync) sits under rebase-versus-merge because that's the policy it executes, and [`stack`](#stacked-branches) is the `gh stack` half. The two below are the ones with nothing else on the page to hang them from.

`worktree` and `sync` live in `SKILL.md` itself because nearly every run and every calling kit reaches them. `clean`, `rescue`, and `stack` each load from a satellite file only when they fire — the repo's disclose-by-branch rule, applied to a skill whose common path shouldn't pay for its rare ones.

### `clean`

Sweeps away the worktrees and branches whose work has landed. Every worktree and local branch gets sorted into one bucket — active, adopted, dirty, reapable, orphan — and only the reapable ones are offered for removal.

**The reason it needs a satellite file rather than a `git branch --merged` loop is squash merges.** A squash merge writes one new commit with a new SHA and no parent link back to the branch, so ancestry says the branch never landed. On a repo that squash-merges, which is the common GitHub default, a sweep built on `--merged` finds nothing on every run and reports a tidy repo full of dead branches. So "merged" is decided by three tests, each catching a merge shape the one before it misses: ancestry for a merge commit or fast-forward, `git cherry` for a rebase-merge, and a combined patch-id comparison for a squash.

**The middle one is the trap, and it looks like the answer.** `git cherry` compares patch content rather than ancestry, so it reads like the fix for the squash problem — but it compares one commit at a time, and a squash collapses several commits into a single patch matching none of them individually. A two-commit branch that was squash-merged prints both commits as unmerged. Only the third test catches it, by reducing the whole branch to one patch-id and looking for that patch on the base, which is exactly what a squash commit is.

Two more signals corroborate without settling: a `: gone]` upstream marker is caused by a merge and equally by a human deleting a branch, and `gh pr list --state merged` is authoritative when `gh` is there, which makes the three tests the offline path. The sweep names which one fired per row, so you can disagree with a specific signal rather than with the whole list.

**It confirms per item, never in a batch**, and that's the one place gitkit's confirmation policy differs from `sync`'s. `sync` legitimately takes one confirmation because the rebase and its push are a single decision about a single branch. A sweep's rows are independent, and they're not equally safe — a `: gone]` row and a `gh`-confirmed row differ in exactly the way one prompt would hide.

`-d` and never `-D` is the last guard: git itself refuses a branch whose commits aren't in the base, so a wrong verdict fails loudly instead of deleting the work.

### `rescue`

Finds work that looks lost — a bad rebase, a hard reset, a deleted branch, a stash nobody can find — and puts it back. It reads git's own logs: the per-worktree `HEAD` reflog, a branch reflog, `ORIG_HEAD`, and `git fsck` last because it's slow and noisy.

**It restores by adding a branch, never by moving one.** That's the rule the whole mode is built around. A reset, a checkout over a dirty tree, or a force update is the same class of operation that lost the work in the first place, and it can lose a second thing on the way to recovering the first. A new branch at the found SHA touches nothing that exists, so a wrong guess costs one `git branch -d`.

**The gc window is a real bound, not a disclaimer.** An unreachable commit survives only until git prunes it — reflog entries expire, and `git gc --prune=now` ends the window immediately. The mode says so plainly rather than implying the object is safe, which is also why it never runs `git gc`, `git prune`, or `git reflog expire` itself. And when the search comes back empty it says the work is unrecoverable rather than continuing to look: changes that were never staged or stashed leave no object at all.

It closes a real dead end. `statuskit` has a rung that spots a stash and routes it to nobody, and `testkit` and `debugkit` both print a bare `git stash apply <sha>` line pointing at an unreachable object with no procedure behind it.

## The worktree convention

```
$WORKTREE_ROOT/<repo-basename>/<local-branch-name>
```

`$WORKTREE_ROOT` defaults to `~/worktrees`.

**Slashes flatten to dashes.** Branch `mimukit/6-marketing-site` gets directory `mimukit-6-marketing-site`, not a nested parent. One flat level per repo means `ls` is a complete inventory rather than a tree to walk. The directory name no longer round-trips back to the branch name — which costs nothing, because lookup is always through git.

Worktrees live **outside** the repository, never in a `.worktrees/` directory inside it. An in-repo worktree gets swept into docker build contexts, bind mounts, file watchers, and test globs, and every one of those failures shows up far from its cause.

## The invariant: one branch, one worktree

**A branch has at most one worktree, and the directory is named after it.** A worktree is keyed to a *branch*, not a workflow stage — so implementing a feature and later reviewing its PR use the same worktree, because they're the same branch.

This isn't a style preference. Git enforces it:

```
$ git worktree add ../wt-b feature-x
fatal: 'feature-x' is already used by worktree at '.../wt-a'
```

Any scheme that names worktrees by stage (`review-…`, `qa-…`) hard-fails the moment two stages touch one branch — which is the normal case, not the edge case.

Two consequences fall out: lookup is **by branch, always**, through git rather than by guessing at a path; and the "kind" of a worktree rides along for free, because the branch name already carries it.

## Branch naming

| Pattern | For |
|---|---|
| `issue-<n>-<slug>` | work starting from a tracker issue. Slug from the title — conventional `type(scope):` prefix stripped, kebab-cased, capped around 50 chars on a word boundary |
| `pr-<n>-<slug>` | **only** a fork pull request, where no local branch exists yet |
| anything else | whatever the human or the repo's convention supplies. gitkit doesn't rename it |

For a same-repo PR there's already a local branch name — using it is the rule. Inventing a `pr-*` name for a branch that exists is how you land on the two-worktrees-one-branch failure.

## Operations are idempotent

All four are native git, and running one twice is a normal thing to do that must never error or destroy work.

**Create — or adopt.** Always look first. If a worktree already exists for the branch, it's adopted: report the path and stop. Never a second one, never an error. Creation always fetches first, because branching off a stale base is silent and only surfaces as conflicts later.

**Remove.** Three rules, each guarding a real way to lose work:

- **A dirty worktree stops teardown.** It shows exactly what would be lost — uncommitted changes, untracked files, unpushed commits — and lets you decide. It never reaches for `--force` on your behalf.
- **Never remove a worktree it adopted rather than created.** If it was already there, it's someone else's context.
- **Never delete a branch it didn't create.** `-d`, not `-D`, so git itself refuses an unmerged branch.

Already gone reports "already gone" and succeeds.

**List** pairs with a staleness signal when you ask to clean up — a branch fully merged into the base is a teardown candidate. Offered, never removed on its own initiative.

## The base ref ladder

Never assume `main`. Repos default to `develop`, `trunk`, and `master` in the wild, and getting this wrong silently produces an empty or enormous diff.

1. `gh repo view --json defaultBranchRef` — authoritative when `gh` is available.
2. `git symbolic-ref --short refs/remotes/origin/HEAD` — the local record, if set.
3. `git remote set-head origin --auto` to repair an unset `origin/HEAD`, then retry. **This is the step most implementations skip, and the one that turns a failure into an answer.**
4. Whichever of `origin/main` / `origin/master` exists.
5. Ask. No guessing past this point.

A worktree's base is never a sibling feature branch — with **one stated exception**, a [stack layer](#stacked-branches), whose base *is* the branch below it. The ban is worth keeping precisely because the exception is narrow: what it catches is the accidental case, a worktree cut from whatever happened to be checked out. A layer base is legal because somebody named the branch and said why.

## Stacked branches

A **stack** is a chain of branches where each is cut from the one below and the bottom sits on trunk. It's what you reach for when the work you want to start depends on work that's built but not merged: rather than waiting for a review, you branch from the prerequisite and keep going. GitHub renders the chain, each PR reviews as its own small diff, and merging any layer merges everything below it bottom-up.

**Each layer keeps its own worktree.** The one-branch-one-worktree invariant is untouched — a layer is a branch, so it gets a directory named after it. The alternative, one worktree for the whole stack with `gh stack up`/`down` moving between layers inside it, is what the extension's own navigation assumes, and it's deliberately *not* what this collection does: every caller here keys a worktree to the issue being worked, and a stack is several issues. So the navigation commands are out of scope, because they'd move a checkout another worktree already holds.

**gitkit takes the plumbing and nothing else** — create, add a layer, restack, sync, inspect, adopt. Two commands are excluded on purpose, and the reason is the same boundary gitkit holds everywhere else: `gh stack submit` opens pull requests, and gitkit never opens anything ([`prkit`](./prkit.md) owns it); `gh stack merge` merges them, and gitkit never merges ([`mergekit`](./mergekit.md) owns it, behind a confirmation naming every PR in the cascade). `gh stack modify` is excluded for a different reason: it's a terminal UI, so no agent can drive it, and gitkit prints the command for a human instead.

**No depth limit is stated**, deliberately. Every layer is one more PR to review and one more branch to rebase whenever anything below it changes, and restacking cascades upward. How deep is too deep depends on layer size and review speed, so the skill names the mechanism and lets the human size it rather than inventing a number the tool doesn't enforce.

The command surface lives in a satellite, `stacks.md`, rather than inline — it's material only some runs reach, where the base-ref exception and the worktree rule are things every run's logic touches.

## Rebase or merge

> **Rebase onto the base to sync a feature branch — published or not. Merging the base in is an exception that needs a stated reason and consent.**

The default is rebase because that's the history worth having: a feature branch reading as a linear sequence of its own commits, with the base's work underneath rather than braided through it. A repo that merges the base in on every sync accumulates one merge commit per sync, and the branch's own story becomes unreadable long before it lands.

Rebasing's real cost is mechanical, not aesthetic: it rewrites SHAs. Once a PR is open, review threads are anchored to those commits, so a force-push marks every one outdated. That's a cost to **disclose and weigh**, not a bar — and it's the one pre-baked reason to propose the merge exception.

- **A branch with no remote counterpart rebases straight through.** Nothing points at those SHAs, so nothing can break. No confirmation needed.
- **A published branch previews once and waits.** One confirmation covers the rebase *and* the `--force-with-lease` push — they're a single decision, and asking twice asks the same question twice.
- **Count the threads before asking.** "3 review threads will be marked outdated" is a fact you can decide on; "this may outdate review comments" is not.
- **Unresolved threads are the reason to *offer* the merge exception, not to take it.** The rebase is still recommended, with merge named as the alternative alongside the count. A preference that folds in the case against it was never a preference.
- **`--force-with-lease`, never bare `--force`.**

### `sync`

The one runnable procedure in an otherwise reference-shaped skill: fetch, measure the gap against the base, preview once, rebase, resolve each conflict file by file, run the repo's gate, then `git push --force-with-lease`.

It exists because "rebase onto the base" as a stated policy still left every caller writing the seven steps itself, and the steps are exactly where the mistakes live — pushing a dirty tree, skipping the gate after a conflict resolution, reaching for bare `--force` when the lease is rejected. A conflict resolution is a code change, which is why the gate sits *before* the push rather than after it.

The lease rejection is the step worth knowing about. It means somebody pushed while you were rebasing, so the sync stops and shows their commits instead of retrying. Retrying past a rejected lease is how the flag's whole purpose gets thrown away.

A branch already level with its base pushes nothing and says so. That keeps the procedure safe to run twice.

The merge exception, when taken, never uses git's default subject — `Merge branch 'main' into issue-42-…` is what git writes when nobody chose a message, and it reads that way forever. The base is interpolated rather than hardcoded, and `--no-ff` is not used: if the sync can fast-forward, there was nothing of the branch's own to preserve.

**Never bare `git pull`**, which merges by default and writes an unasked-for merge commit. `--rebase`, or `--ff-only` to fail loudly.

## Containers and remote boxes

Worktrees store **absolute** paths, so a repo bind-mounted at a different path breaks every worktree inside it. Mount **both** `$WORKTREE_ROOT` and the main checkout — a worktree's real git directory lives under the main repo's `.git/worktrees/` — and mount both at the **same absolute path** inside and out.

**No skill may create or remove a worktree through a vendor CLI.** The moment one does, two machines diverge. A vendor's *metadata* about a worktree — the issue its card links to, a status, a comment — is a different layer and fair game, which is what [`orcakit`](./orcakit.md) reconciles. gitkit never calls in that direction; it must keep working where no such tool is installed.

`gh stack` looks like it breaks this rule and doesn't. The rule protects against a *worktree* created two different ways on two machines. A stack is a GitHub-side relationship between branches, not a worktree, and its layers are still created and removed through the same native git path everything else uses — which is why the degradation is plain git rather than a second code path.

## Hands off to

Nothing, deliberately. gitkit prepares the ground and tears it down — **creating a worktree implies nothing about what to do in it.** It's the one skill in the collection exempt from the closing hand-off requirement, by design rather than oversight.

## Restating a conclusion vs restating the derivation

Every public skill installs on its own, into repos where gitkit may not exist, so a caller that needs a git fact has to carry enough of one to keep working. That requirement outranks tidiness, and the line runs between two things that look similar on the page.

A caller may state gitkit's **answer** alongside its degradation fallback — *"gitkit owns the sync rule, and it resolves to rebase; without gitkit, rebase onto the base."* A caller may not reproduce the **reasoning that produces** the answer: the five-rung base-ref ladder, the worktree path formula, the rebase-versus-merge argument in full.

The asymmetry is about what rots. An answer is one line, and a rename here breaks it loudly wherever it's repeated. A derivation is a second implementation, and it drifts silently until two skills disagree about where a worktree lives.

Compliant by this rule today: [`prkit`](./prkit.md) and [`mergekit`](./mergekit.md) each name the rebase conclusion and its single-confirmation rule without re-deriving them, and [`wikikit`](./wikikit.md) and [`designkit`](./designkit.md) each name `gh repo view --json defaultBranchRef` as a base-ref fallback without carrying the ladder. A worktree path, a base-ref ladder, or the rebase argument turning up restated in full inside another skill is still the bug.

## Install

```sh
npx skills add mimukit/skills -s gitkit
```

Source: [`skills/gitkit/SKILL.md`](../../../skills/gitkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`1135855` on 2026-08-29._
