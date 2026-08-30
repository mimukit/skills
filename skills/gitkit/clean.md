# The clean sweep: `gitkit clean`

Reference for gitkit's [`clean`](./SKILL.md#clean) mode. Read this only when a run actually sweeps; nothing else in gitkit depends on it.

The sweep finds the worktrees and local branches whose work has landed, and removes them one at a time. It is the counterpart to [create, or adopt](./SKILL.md#create-or-adopt): the same three teardown rules in [Remove](./SKILL.md#remove) govern every removal here, and this file adds only the classification that decides which rows reach them.

## 1. Enumerate

```sh
git -C "$REPO" fetch origin --prune
git -C "$REPO" worktree list --porcelain
git -C "$REPO" branch -vv
```

Fetch with `--prune` first. It is what deletes the stale remote-tracking refs the classification below reads, so a sweep on an unfetched repo misreads every row.

Ends with one row per worktree and one row per local branch. A branch with no worktree is a legal row; so is a worktree whose branch is gone.

## 2. Classify

Every row lands in exactly one bucket. Work down the list and stop at the first match:

- **active** — the branch checked out in the repo you are sweeping from, or a branch with an open pull request. Leave it and say nothing.
- **adopted** — the worktree was already there when gitkit arrived. Never touch it. You do not know what is open in it.
- **dirty** — uncommitted changes, untracked files, or commits the remote does not have. Report exactly what is there and leave it. This is the bucket that protects work, so check it before calling anything reapable.
- **reapable** — the branch's work is in the base, the tree is clean, and gitkit created the worktree.
- **orphan** — a worktree whose directory is gone, or whose branch was deleted elsewhere. `git worktree prune` handles these and needs no confirmation, because there is nothing left to lose.

A row that matches nothing is **active** by default. Silence is the safe answer.

## 3. Decide "merged", the part that is not obvious

**`git branch --merged` misses a squash-merged branch entirely.** A squash merge writes one new commit with a new SHA and no parent link back to the branch, so ancestry says the branch never landed. On a repo that squash-merges — the common GitHub default — a sweep built on `--merged` alone finds nothing reapable on every run and reports a tidy repo that is full of dead branches.

Three tests, each catching a merge shape the one before it misses. Run them in order and stop at the first that answers:

```sh
BASE_REF="origin/$BASE"
MB=$(git -C "$REPO" merge-base "$BASE_REF" "$BRANCH")

# 1. ancestry — a merge commit or a fast-forward
git -C "$REPO" merge-base --is-ancestor "$BRANCH" "$BASE_REF"

# 2. per-commit patch equality — a rebase-merge or individual cherry-picks
git -C "$REPO" cherry "$BASE_REF" "$BRANCH" | grep -q '^+' || echo merged

# 3. combined patch equality — a squash merge
BRANCH_PID=$(git -C "$REPO" diff-tree -p "$MB" "$BRANCH" | git patch-id --stable | cut -d' ' -f1)
for c in $(git -C "$REPO" rev-list "$MB".."$BASE_REF"); do
  [ "$(git -C "$REPO" show -p --format= "$c" | git patch-id --stable | cut -d' ' -f1)" = "$BRANCH_PID" ] && echo merged
done
```

- **Test 2 does not catch a squash**, which is the trap worth stating because it looks like it should. `git cherry` compares one commit's patch at a time, and a squash collapses several commits into one patch that matches none of them individually. A two-commit branch that was squash-merged prints both commits as `+`, meaning unmerged. Test 2 earns its rung on the *rebase-merge* shape, where each commit did land separately.
- **Test 3 is the squash detection.** It reduces the whole branch to a single patch-id and looks for that patch on the base. That is exactly what a squash commit is, so the ids match, and they keep matching after the base moves on with unrelated work.
- **`--stable` is required.** Without it, `git patch-id` output depends on hunk ordering and the comparison silently stops matching.

Two corroborating signals, neither sufficient alone:

```sh
git -C "$REPO" branch -vv | grep ': gone]'                          # upstream deleted, after the --prune above
gh pr list --head "$BRANCH" --state merged --json number,mergedAt   # authoritative, when gh is there
```

- **`: gone]` is a signal and not a proof.** The remote branch went away, which a merge causes and so does somebody deleting a branch by hand.
- **`gh` settles it** when available. A merged pull request for the head branch is the fact the three tests approximate, so prefer it and treat the tests as the offline path.

`$BASE` comes from [the base ref ladder](./SKILL.md#the-base-ref). Report which test fired for each reapable row, so the human can disagree with a specific signal rather than with the whole list.

Ends when every reapable row carries a named reason.

## 4. Preview, and confirm per item

Print one table: the branch, its worktree path, the bucket, and the reason. Then confirm **each removal on its own**.

**Never a batch yes.** A sweep is the one place where a single confirmation covers many independent deletions, and the rows are not equally safe — a `: gone]` row and a `gh`-confirmed row differ in exactly the way one prompt hides. Sync is different, and legitimately takes one confirmation, because there the rebase and the push are one decision about one branch.

A run where the human declines everything is a successful run. Report the table and stop.

## 5. Remove

For each confirmed row, in this order:

```sh
git -C "$REPO" worktree remove "$WT"
git -C "$REPO" branch -d "$BRANCH"
git -C "$REPO" worktree prune
```

`-d`, never `-D`. It is the last guard: git itself refuses a branch whose commits are not in the base, so a wrong reapable verdict fails loudly here rather than deleting the work. When `-d` refuses, keep the worktree removal and report the refusal — the branch stays, and that is the correct outcome.

## Hand off

Report the buckets by count, then each removed worktree by path and each deleted branch by name. Name the dirty rows you left and what is in them. Say when nothing was reapable.

**A removed worktree leaves a stale row in any workspace tool that tracked it.** Clean that next: run `orcakit clean` for Orca, or `paseokit sync` for Paseo, when either is installed. With neither installed there is nothing further to do.
