# plan: gitkit — one worktree convention for local Orca and the remote devbox

**Status:** in progress — gitkit shipped and tested; callers refactored 2026-08-02. Remaining: migrate the existing worktrees, then run both machines through a full cycle.
**Date:** 2026-08-02

## The problem

Two worktree conventions coexist in this repo with no arbiter between them:

- **orcakit** creates worktrees through `orca worktree create`, named `issue-<n>-<slug>`, path unstated (Orca owns placement).
- **mergekit** creates worktrees through native `git worktree`, at `.worktrees/pr-<n>-<slug>/` inside the repo. Its plan doc says *"No orcakit, no Orca… no 'prefer orcakit when installed' fallback."*

The workflow is moving to two machines: a local MacBook where Orca runs, and a cloud VPS (Linux, docker compose) where it does not. Both must behave identically. Today they cannot: orcakit is Orca-only and mergekit is deliberately Orca-blind, and both tear down after a merge, so on an Orca-created worktree `git worktree remove` and `orca worktree rm` can both fire.

## The findings that reframe it

**1. Orca workspaces already are native git worktrees.** Verified locally:

```
~/orca/workspaces/saasaloy/issue-12-auth-capability-module/.git
  → gitdir: /Users/mukit/Github/mimukit/saasaloy/.git/worktrees/issue-12-auth-capability-module
```

`git worktree list` from the main checkout enumerates every Orca workspace as an ordinary worktree. Orca is not a parallel system — it is metadata (issue link, terminals, lineage, per-repo base ref) layered on top of `git worktree`.

**2. Orca can observe git-created worktrees rather than owning them.** Every repo currently carries `externalWorktreeVisibility: "hide"` (from `orca repo list --json`). Per the docs: *"Worktrees you create yourself with `git worktree add` stay external until you import them. If the repo hides external worktrees, Orca surfaces newly detected ones in the New externally-created worktrees inbox so you can import them or leave them hidden."* And removals propagate: *"If you `git worktree remove` from the CLI, Orca will notice and clean up its own state the next time it refreshes that repo."*

**3. Git refuses one branch in two worktrees.** Verified:

```
$ git worktree add ../wt-b feature-x
fatal: 'feature-x' is already used by worktree at '.../wt-a'   (exit 128)
```

This is a **live bug in mergekit**. It creates `pr-<n>-<slug>` tracking the PR's head branch — which hard-fails whenever that branch is already checked out in the worktree the feature was implemented in. On a machine where an agent implements in `issue-42-*` and opens the PR from it, that is the normal case, not an edge case.

## Decisions

| Decision | Choice |
|---|---|
| Shared root | `~/worktrees` on both machines, overridable via `$WORKTREE_ROOT` |
| Owner skill | **`gitkit`** — worktrees plus shared git primitives |
| Worktree engine | **Native `git worktree` only, on both machines.** No `orca` CLI calls. |
| Orca's role | **Observer.** Configured to surface git-created worktrees in its UI. |
| Worktree identity | **One branch, one worktree.** Directory name always equals the local branch name. |
| mergekit | Adopts the existing worktree for the PR's branch; creates one only when absent |
| orcakit | On a deprecation path once this proves out |

## The convention

### Path

```
$WORKTREE_ROOT/<repo-basename>/<local-branch-name>
```

`$WORKTREE_ROOT` defaults to `~/worktrees`. `<repo-basename>` is the main checkout's directory name. Identical shape on both machines.

**Slashes in a branch name flatten to dashes** (decided 2026-08-02, prompted by the live `mimukit/6-marketing-site` branch this plan had not accounted for). `mimukit/6-marketing-site` → `mimukit-6-marketing-site`, keeping one flat level per repo so `ls` is a complete inventory. The directory name therefore no longer round-trips to the branch name — which costs nothing, since lookup is always through git. Rejected the alternative of letting it nest: a `mimukit/` directory holding branch-shaped children turns the inventory into a tree walk for no gain. On the rare `a/b` vs `a-b` collision, `git worktree add` fails on the existing path — report it rather than silently appending a suffix.

### The invariant: one branch, one worktree

**A branch has at most one worktree, and the directory is named after it** (slashes flattened, per above). A worktree is keyed to a *branch*, not to a workflow stage — so implementing a feature and later reviewing its PR use the same worktree, because they are the same branch. This is not a style preference; git enforces it (finding 3).

Consequences:

- **Lookup is by branch, always.** `git worktree list --porcelain` reports `branch refs/heads/<name>` per worktree; that is the lookup key for adopt, reuse, and teardown. Never look up by workflow stage or by a `pr-*` / `issue-*` prefix.
- **Names are branch names, so the kind prefix comes along for free.** `issue-42-auth-capability-module` because gitkit named the *branch* that when the work started. Nothing separately encodes "kind."
- **`pr-<n>-<slug>` is only a local branch name mergekit invents.** For a fork PR there is no local branch yet, so mergekit fetches `pull/<n>/head` into a branch it names `pr-<n>-<slug>` — and the worktree directory takes that same name. The invariant holds.

```
~/worktrees/saasaloy/
  issue-42-auth-capability-module   # branch issue-42-…, created at implement time,
                                    #   reused when reviewing its PR
  pr-34-fix-token-refresh           # branch pr-34-…, invented by mergekit for a fork PR
```

### Branch naming

- **`issue-<n>-<slug>`** — slug from the conventional issue title `type(scope): summary`, prefix stripped, kebab-cased, capped ~50 chars at a word boundary. Empty slug → bare `issue-<n>`.
- **`pr-<n>-<slug>`** — fork PRs only. Slug from the head branch name, kebab-cased, capped ~40 chars.

### Engine: native git only

Both machines run the same commands. No `orca` invocation anywhere in any skill.

```sh
# create
git -C "$REPO" fetch origin --prune
git -C "$REPO" worktree add -b "$BRANCH" "$WORKTREE_ROOT/$(basename "$REPO")/$BRANCH" "$BASE"

# adopt / look up by branch
git -C "$REPO" worktree list --porcelain      # parse: worktree <path> … branch refs/heads/<name>

# teardown
git -C "$REPO" worktree remove "$PATH" && git -C "$REPO" branch -d "$BRANCH"
```

This is what makes the two machines identical: there is no second code path to keep in sync, and nothing to detect. The VPS is not a degraded mode — it runs the same thing.

### Orca's role: observer

Orca is configured once per repo to surface externally-created worktrees, then stays out of the way. It contributes the UI, terminals, and embedded browser; it contributes nothing to worktree lifecycle.

**Setup, per repo, one time:** flip `externalWorktreeVisibility` off `hide` in Orca's repo settings. There is no CLI setter — `orca repo` exposes only `list`, `add`, `show`, `set-base-ref`, `search-refs` — so this is a UI toggle.

**Verify before committing to it:** the docs describe an inbox (*"New externally-created worktrees"*) for the `hide` case, but do not state whether the non-hide value adopts automatically or still requires a per-worktree import click. Flip it on one repo, run `git worktree add`, and see whether the worktree appears unprompted. If it is still inbox-gated, that is a one-click-per-worktree tax on the local machine only — acceptable, but worth knowing before the migration.

### Base ref — resolved, not hard-coded

```sh
git symbolic-ref --short refs/remotes/origin/HEAD    # → origin/main, origin/master, …
```

Falls back to whichever of `origin/main` / `origin/master` exists. reviewkit and mergekit already do this; orcakit hard-codes `origin/main` and must stop.

### Sync policy — the one place the rule is stated

prkit currently says *"always rebase… never merge the base into the branch"*; mergekit says *"merge, never rebase. Never force-push."* Both are right in context, but nothing reconciles them. The unified rule:

> **Rebase a branch you exclusively own and have not published for review. Merge the base into a branch that is under review or shared.**

Rebasing rewrites SHAs, which detaches review comments and breaks anyone who pulled the branch. Before a PR exists there is no one to break, so rebase for a clean history; once a PR is open and being reviewed, merge.

## gitkit's surface

A public skill (`internal: false`) owning:

1. **Path and branch-naming convention** — the forms above.
2. **The one-branch-one-worktree invariant**, and branch-keyed lookup.
3. **Worktree lifecycle** — `create`, `adopt`, `list`, `remove`, all native git. Idempotent both ways: creating for a branch that already has a worktree adopts and reports it; removing an absent one reports "already gone". A dirty worktree stops teardown and shows what would be lost.
4. **Base-ref resolution.**
5. **Sync policy.**

Note how much smaller this is than the original draft: no backend detection, no dual teardown, no `orca` dependency, no recorded state.

**Known weakness, accepted.** gitkit is a primitives skill: nobody says "gitkit this," so its `description` trigger is weak and it runs mostly because other skills call it. The trigger should still front-load real English phrases people do say — "spin up a worktree", "tear down this worktree", "should I rebase or merge here".

## Adoption: every skill delegates to gitkit

**The rule.** No skill may implement, restate, or vary anything gitkit owns. If a skill needs a worktree, a base ref, a branch name, or a sync decision, it calls gitkit and uses what comes back. A skill may still hold *policy about when* to ask — mergekit decides a PR is worth pulling down, prkit decides a branch is ready to publish — but never *how* the git operation is done.

This matters because the audit found the same concern implemented four different ways. Base-ref resolution alone:

| Skill | Mechanism today |
|---|---|
| reviewkit | `git symbolic-ref --short refs/remotes/origin/HEAD` → `git remote show origin` → `main`/`master` |
| prkit | `gh repo view --json defaultBranchRef` → `symbolic-ref` → repair via `git remote set-head origin --auto` |
| mergekit | `gh repo view --json defaultBranchRef` only |
| orcakit | hard-coded `origin/main` |

Four skills, four answers, and only prkit's recovers from an unset `origin/HEAD`. **gitkit adopts prkit's ladder as canonical** — it is the only complete one — and the other three drop their own.

### Skills that change

| Skill | What it delegates | Change |
|---|---|---|
| **mergekit** | worktree lifecycle, base ref, sync policy | **Adopt-first.** Resolve the PR's head branch, look it up in `git worktree list --porcelain`, reuse that worktree if present. Create only when the branch has no worktree — same-repo PRs check out the fetched head branch; fork PRs fetch `pull/<n>/head` into a `pr-<n>-<slug>` branch first. Path moves to the shared root; drop the `.git/info/exclude` step. Drop its own base-ref call. **Teardown narrows:** never remove a worktree it adopted rather than created, never delete a branch it did not create. |
| **prkit** | base ref, sync policy, branch creation | Keeps its base-ref *ladder* — as gitkit's, not its own. Drops the standalone "always rebase" rule in favor of gitkit's owned-vs-under-review rule (which yields rebase here anyway, so behavior is unchanged — only the source of truth moves). Its default-branch guard (*"a PR needs a feature branch… offer `git switch -c <name>`"*) calls gitkit for the branch name. |
| **reviewkit** | base ref | Drops its three-step base detection; calls gitkit. Everything downstream (`git diff <base>...HEAD`) is unchanged. |
| **orcakit** | worktree lifecycle, base ref, branch naming | Drops `orca worktree create` / `orca worktree rm`; stops hard-coding `origin/main`. Residue is the `ready` guard plus label flips. **Slated for deletion** — see [plan-orcakit-deletion-2026-08-02.md](plan-orcakit-deletion-2026-08-02.md). |
| **afkkit** | worktree lookup | Worktree discovery goes through gitkit `list` (branch-keyed) instead of `orca worktree list` / `git worktree list`. Its three verification commands stay — they check the *session's* location, which is afkkit's own concern. The manual prerequisite becomes **issuekit `start`** rather than `orcakit start` (see the correction below). |
| **statuskit** | branch naming, base ref | Its branch→issue heuristic parses `issue-N` / slug patterns — that parser belongs with the producer, so it sources the pattern from gitkit. "Is this a feature branch?" needs gitkit's base ref rather than assuming `main`/`master`. Routes worktree work to gitkit. |

### Skills that do not change — and why

Confirmed by audit, not assumed:

| Skill | Finding |
|---|---|
| **commitkit** | No branch, base-ref, worktree, or sync surface. Operates on the index and working tree only. |
| **implementkit** | Entirely cwd-relative, no worktree or branch awareness. This is *why* afkkit can dispatch it into a worktree unchanged — keep it that way. |
| **issuekit** | ~~No behavior change; grows a `start` mode later, under the orcakit deletion plan.~~ **Corrected 2026-08-02: the `start` mode was pulled forward into this change** — see below. |
| **repokit** | Worktree wording appears only inside label descriptions it provisions. Text, not behavior. |
| **verifykit** | Uses its own `refs/verify-assets/<slug>` namespace and an isolated index; explicitly *"never touches the working tree or current branch."* Worktree-safe by construction — leave alone. |
| **qakit** | "branch to test on" is a form field in generated output, not an operation. |
| **domainkit** | Its ADR-renumbering note concerns parallel *branches* colliding on a number — a merge-time editorial concern, not git plumbing. |
| **plankit**, **researchkit**, **grillkit**, **humankit**, **validatekit**, **skillkit**, **handoffkit** | No git surface at all. |

That is all 20 skills accounted for: 6 change, 14 do not.

### Correction, 2026-08-02: issuekit gains `start` in this change, not later

Executing the refactor surfaced a gap in the table above. It says afkkit's manual prerequisite *"becomes a gitkit call rather than `orcakit start`"* — but gitkit only makes a worktree. It does not read the `ready` label and does not flip `ready → in-progress`, and that guard is afkkit's entire safety property: the reason an unattended run can never get ahead of human judgment. Routing afkkit's front door straight at gitkit would have deleted the gate and left nothing in its place.

The orcakit deletion plan already had the answer — a new issuekit `start` mode owning the guard, the label flip, and a gitkit call for the worktree — but scheduled it *after* this change. So the sequencing was wrong, not the design. **`start` was pulled forward and shipped here**, and afkkit's prerequisite now reads issuekit `start <n>`.

The knock-on: that satisfies precondition 4 of the deletion plan, and it makes orcakit a pure wrapper over issuekit + gitkit with nothing of its own left. orcakit is refactored onto both (no `orca` CLI, no hard-coded `origin/main`) and now carries a deprecation notice pointing at them, but is **not** deleted — the deletion plan's other preconditions, chiefly a full cycle on the VPS, are still unmet.

### Registry

`skills.sh.json` gains `gitkit` in the "Git & GitHub" group.

### Sequencing

Ship gitkit → refactor the 6 callers → **then** migrate the existing worktrees → run both machines through a full cycle → then execute the orcakit deletion plan.

**Decided 2026-08-02: refactor before migrating**, reversing this plan's original order. The original rationale — *"so there is never a moment where skills look in a root the worktrees have left"* — was wrong on the facts. No skill ever looks in a root. gitkit's lookup is `git worktree list --porcelain`, which asks git, and git tracks worktrees by recorded absolute path regardless of where they sit. Adopt, list, and remove keep working on worktrees in the old root without modification; only **create** consults the path convention.

So the real cost of deferring the migration is split-brain — newly created worktrees under `~/worktrees`, the legacy six under `~/orca/workspaces` — not breakage. That is a tolerable state to sit in, and it buys the option to adjust the convention after real use rather than committing the filesystem to it first.

Do not fold the orcakit deletion into this change either: while the convention is still settling, orcakit remaining in place is a working fallback.

## Migration

Runs **after** gitkit ships and the callers are refactored — see [Sequencing](#sequencing). Until then the legacy worktrees keep working where they are.

### Actual state, surveyed 2026-08-02

Six real worktrees, **all clean** (no uncommitted changes). One carries unpushed commits, which a move does not touch.

| Worktree | Branch | Note |
|---|---|---|
| `saasaloy/issue-12-auth-capability-module` | same | 2 unpushed commits |
| `saasaloy/issue-27-…-via-manifest` | same | |
| `saasaloy/issue-29-…-via-iac` | same | |
| `saasaloy/issue-41-…-astro-7-…` | same | |
| `growaloy/3-phase-1-first-testable-paid-loop` | same | |
| `growaloy/6-marketing-site` | **`mimukit/6-marketing-site`** | branch ≠ directory; flattens to `mimukit-6-marketing-site` |

Two directories under `~/orca/workspaces` are **not worktrees** and are not migration targets — delete them instead:

- `saasaloy/issue-10-waitlist-feature-end-to-end-proof` — no `.git` file, absent from `git worktree list`, 4 KB holding only an empty `.dev/playground`.
- `llm-web-refactoring-test-mimukit/` — entirely empty.

### Steps

1. Point Orca's `settings.workspaceDir` at `~/worktrees` — keeps any worktree you create by hand in the Orca UI landing in the same place.
2. Flip `externalWorktreeVisibility` off `hide` on each repo, and **verify the auto-adopt behavior** (see above) before going further.
3. Move each worktree and repair its back-pointers. Note `6-marketing-site` takes its **flattened branch name** as the destination, so this move also fixes the one worktree that violates the convention:

   ```sh
   mkdir -p ~/worktrees/saasaloy
   mv ~/orca/workspaces/saasaloy/<name> ~/worktrees/saasaloy/<name>
   git -C /Users/mukit/Github/mimukit/saasaloy worktree repair ~/worktrees/saasaloy/<name>

   # the slash case:
   mv ~/orca/workspaces/growaloy/6-marketing-site ~/worktrees/growaloy/mimukit-6-marketing-site
   git -C /Users/mukit/Github/mimukit/growaloy worktree repair ~/worktrees/growaloy/mimukit-6-marketing-site
   ```

4. Verify with `git -C <repo> worktree list` that no path still points at `~/orca/workspaces`.
5. Confirm Orca re-discovers the moved worktrees; re-import any it drops.
6. Delete the two non-worktree directories above, then remove the empty `~/orca/workspaces` tree once every repo verifies clean.

## The docker-compose constraint

Git stores **absolute** paths in `.git/worktrees/<name>/gitdir` and in each worktree's `.git` file. If compose bind-mounts the repo at a different path than the host uses, every worktree breaks inside the container.

Requirements for the VPS:

- Mount `$WORKTREE_ROOT` **and** the main checkout — the worktree's real git directory lives under the main repo's `.git/worktrees/`. Mounting only the worktree yields a broken checkout.
- Mount both at the **same absolute path** inside and outside the container.

Mitigation worth evaluating: git 2.48+ supports relative worktree pointers (`git config worktree.useRelativePaths true`, and `git worktree repair --relative-paths`). Local git is 2.55, so this is available. Relative pointers survive remapping *as long as the repo and the worktree root keep their relative positions* — which argues for siding them, e.g. `~/code/<repo>` and `~/worktrees/<repo>`. Same-absolute-path remains the robust answer; treat relative paths as a second belt.

This constraint is also why mergekit's worktrees leave the repo: an in-repo `.worktrees/` gets swept into docker build contexts, bind mounts, and file watchers.

## Rejected: headless Orca on the VPS

Orca does run headless on Linux (`orca serve`, AppImage, state under `~/.config/`). Rejected because Remote Orca Servers are beta and [stablyai/orca#9047](https://github.com/stablyai/orca/issues/9047) breaks agent launch for server-local workspaces from a browser client. Moot under this design anyway: with no skill calling the `orca` CLI, the VPS needs nothing from Orca.

## Open questions

- Does flipping `externalWorktreeVisibility` auto-adopt, or still gate through the inbox? **Blocks the migration, not the refactors** — test before moving anything, but it no longer sits in front of shipping gitkit.
- ~~Does `gitkit` also own branch **creation** for prkit's default-branch guard?~~ **Resolved 2026-08-02: yes** — gitkit owns branch naming, so prkit's guard calls it for the name.
- ~~How does the path convention handle a branch name containing `/`?~~ **Resolved 2026-08-02: flatten to dashes** — see [Path](#path).
- When mergekit adopts an existing worktree that has uncommitted work in it, does it refuse, stash, or proceed? Adopt-first makes this reachable in a way the old create-always design never was.
- Naming: `gitkit` collides with Google's GitKit and npm packages, and "git" is a poor search term for a worktree skill. Accepted deliberately in favor of the broader primitives scope; revisit if discovery suffers.

## Sources

- [Orca — Worktrees](https://www.onorca.dev/docs/model/worktrees)
- [Orca — Remote Servers](https://www.onorca.dev/docs/remote-servers)
- [Orca — Settings reference](https://www.onorca.dev/docs/settings)
- [Orca — CLI reference](https://www.onorca.dev/docs/cli/reference)
- [stablyai/orca#9047 — headless serve / web client host resolution](https://github.com/stablyai/orca/issues/9047)
- Local verification: `orca --help`, `orca repo list --json`, `git worktree list`, `~/Library/Application Support/Orca/orca-data.json`, and a scratch-repo test of the two-worktrees-one-branch restriction
