# gitkit

The shared git layer every other skill borrows — worktree convention and lifecycle, base-ref resolution, and rebase-versus-merge policy.

**Reach for it when** you need a worktree, or when another skill needs any git fact it shouldn't be re-deriving.

| | |
|---|---|
| Modes | primitives, called rather than run |
| Tools | `Bash`, `Read` |
| Writes | git worktrees and branches |
| Visibility | public |

## What it does

gitkit is the one place the git facts live that every other skill keeps re-deriving: **where a worktree goes and what it's named, how it's created, adopted, and removed, which branch is the base, and when to rebase versus merge.**

Nothing in it is clever. All of it is native [git worktree](https://git-scm.com/docs/git-worktree) — no vendor CLI, no GUI dependency, no recorded state anywhere but git's own. That's the point: a laptop with a desktop dev tool and a headless Linux box run *identical* commands, so there's no second code path to keep in sync and no degraded mode to reason about.

It's a **primitives skill**. Most of its runs come from another skill calling it, not from a human saying its name. It answers *where and how*, never *what the change should be* — committing, opening a PR, and judging code all belong elsewhere.

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

## Rebase or merge

> **Rebase onto the base to sync a feature branch — published or not. Merging the base in is an exception that needs a stated reason and consent.**

The default is rebase because that's the history worth having: a feature branch reading as a linear sequence of its own commits, with the base's work underneath rather than braided through it. A repo that merges the base in on every sync accumulates one merge commit per sync, and the branch's own story becomes unreadable long before it lands.

Rebasing's real cost is mechanical, not aesthetic: it rewrites SHAs. Once a PR is open, review threads are anchored to those commits, so a force-push marks every one outdated. That's a cost to **disclose and weigh**, not a bar — and it's the one pre-baked reason to propose the merge exception.

- **A branch with no remote counterpart rebases straight through.** Nothing points at those SHAs, so nothing can break. No confirmation needed.
- **A published branch previews once and waits.** One confirmation covers the rebase *and* the `--force-with-lease` push — they're a single decision, and asking twice asks the same question twice.
- **Count the threads before asking.** "3 review threads will be marked outdated" is a fact you can decide on; "this may outdate review comments" is not.
- **Unresolved threads are the reason to *offer* the merge exception, not to take it.** The rebase is still recommended, with merge named as the alternative alongside the count. A preference that folds in the case against it was never a preference.
- **`--force-with-lease`, never bare `--force`.**

The merge exception, when taken, never uses git's default subject — `Merge branch 'main' into issue-42-…` is what git writes when nobody chose a message, and it reads that way forever. The base is interpolated rather than hardcoded, and `--no-ff` is not used: if the sync can fast-forward, there was nothing of the branch's own to preserve.

**Never bare `git pull`**, which merges by default and writes an unasked-for merge commit. `--rebase`, or `--ff-only` to fail loudly.

## Containers and remote boxes

Worktrees store **absolute** paths, so a repo bind-mounted at a different path breaks every worktree inside it. Mount **both** `$WORKTREE_ROOT` and the main checkout — a worktree's real git directory lives under the main repo's `.git/worktrees/` — and mount both at the **same absolute path** inside and out.

**No skill may create or remove a worktree through a vendor CLI.** The moment one does, two machines diverge. A vendor's *metadata* about a worktree — the issue its card links to, a status, a comment — is a different layer and fair game, which is what [`orcakit`](./orcakit.md) reconciles. gitkit never calls in that direction; it must keep working where no such tool is installed.

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

_Verified against `main`@`d2e9d3b` on 2026-08-24._
