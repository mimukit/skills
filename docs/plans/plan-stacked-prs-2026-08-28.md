# Plan: stacked pull requests

Grilled: 2026-08-28

## Context

The collection currently treats a dependency between two issues as a **wait**. `issuekit create` ranks "independent by default" as a principle and tells the agent to design a dependency away. A dependency that survives gets the `blocked` label and a `Blocked by #N` body line. `issuekit sync` promotes `blocked → ready` only when the blocker **closes**, meaning after its PR merged. `issuekit start` refuses anything not `ready`, and `gitkit` cuts every worktree from the resolved base ref, never from a sibling feature branch.

So the workflow has no state for the case that actually happens most: the blocker is built, its PR is open, and nobody has reviewed it yet. "Nobody started the blocker" and "the blocker is sitting in review" carry the same label, and both mean stop. On a solo project where the reviewer and the author are the same person, that wait is the single largest source of idle time in the whole flow.

GitHub shipped stacked pull requests to public preview on 2026-07-30. A stack is a chain of branches in one repository where each PR targets the branch below it and the bottom targets trunk. Merging any PR merges it and every unmerged PR below it, bottom-up, and the layers above rebase automatically. That is exactly the missing state, implemented server-side, with existing reviews, checks, and merge requirements working unchanged.

Success means an issue whose prerequisite is in flight can be started **now**, on a branch cut from the prerequisite's branch, with a PR that reviews as its own small diff and lands in the right order without anyone sequencing merges by hand.

### Grounded facts

The `gh stack` CLI is a `gh` extension and is optional; stacks are also manageable from github.com, the API, and plain git. It needs `gh` 2.90.0+ and git 2.20+. Branches must live in **one repository**; cross-fork stacks are unsupported. Commits created by a server-side rebase are **not signed**, so a repo requiring signatures must rebase locally. `gh stack modify` is an interactive TUI and cannot be driven by an agent.

Separately, GitHub's native issue dependencies became readable **and writable** from `gh` 2.94.0 (2026-06-10): `--json blockedBy,blocking` to read, `--add-blocked-by` / `--remove-blocked-by` to write. One floor of 2.94.0 covers both features.

The command surface this plan builds on:

| command | does |
|---|---|
| `gh stack init [-b <base>]` | start a stack on the current branch |
| `gh stack add <branch> [-Am "msg"]` | add a layer on top |
| `gh stack submit [--auto] [--open]` | open a PR per branch with correct bases |
| `gh stack link [--base <branch>]` | adopt existing branches and PRs into a stack |
| `gh stack view [--json]` | layers, order, PR links, recent commits |
| `gh stack rebase [--upstack\|--downstack]` | cascading restack |
| `gh stack sync [--prune]` | fetch, rebase, push, reconcile PR state |
| `gh stack merge [--merge\|--squash\|--rebase] [-y]` | merge the whole stack |
| `gh stack modify` | interactive drop, fold, insert, reorder, rename |
| `gh stack unstack [--local]` | detach the stack |

Sources: [stacked PRs changelog](https://github.blog/changelog/2026-07-30-stacked-pull-requests-are-now-in-public-preview/), [CLI reference](https://docs.github.com/en/pull-requests/reference/stacked-prs-cli-commands), [managing stacked PRs](https://docs.github.com/en/pull-requests/how-tos/create-pull-requests/managing-stacked-pull-requests), [github/gh-stack](https://github.com/github/gh-stack), [issue dependencies in the CLI](https://github.blog/changelog/2026-06-10-manage-sub-issues-types-and-dependencies-from-github-cli/).

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Shape | **No new skill.** Stack support folds into `gitkit`, plus edits to five existing kits. The alternative, a separate `stackkit`, was rejected to avoid a permanent entry in the index a human has to hold. |
| What `gitkit` gives up | Its "no vendor CLI, no GitHub dependency" claim now holds for the core only. The stack section requires `gh`, and its degradation path is plain git, so the core keeps working untouched on a box with no `gh`. |
| Authority boundary | `gitkit` takes **plumbing only**: `init`, `add`, `rebase`, `sync`, `view`, `link`. `gh stack submit` goes to `prkit`; `gh stack merge` stays `mergekit`'s. `gitkit` keeps its "never opens or merges anything" line and the collection keeps one merge authority. |
| Placement | Hybrid. The base-ref exception and the layer-worktree rule sit **inline** in `SKILL.md` because every run's base-ref logic touches them; the `gh stack` command surface goes in a satellite `skills/gitkit/stacks.md` behind a pointer, because only some branches reach it. |
| `gitkit` description | Gains **one** trigger branch for the stack case, such as "stack this on #43". Not one per mode; that is synonym padding on a description already among the longest in the collection. |
| Base-ref rule | `gitkit`'s "never a sibling feature branch" rule keeps its teeth and gains one **narrow stated exception**: a stack layer's base is the branch below it. One worktree implementation survives. |
| Worktree model | **One worktree per layer.** `issuekit start` is unchanged in shape and each issue keeps its own directory where every other kit expects it. The cost is that `gh stack up`/`down` would move to a branch whose worktree is elsewhere, so those navigation commands stay out of `gitkit`'s surface. |
| `gh stack modify` | A **pointer, not a mode**. One line in the satellite naming the command and saying a human runs it, so no agent tries to drive a TUI. |
| Dependency source of truth | **Native `blockedBy`/`blocking` primary**, written with `gh issue edit --add-blocked-by`. The `Blocked by #N` body line stays as human-readable prose and as the documented fallback, not as the store. This also ends existing drift, since `statuskit` already reads the native fields and nothing writes them. |
| `gh` version floor | **Soft.** State 2.94.0 in the preflight. Below it, `issuekit` writes the body line only and says the native edge was skipped. A hard floor would break installs that work today. |
| Lifecycle vocabulary | One new **stored** label, `stacked`, written by `sync` and by `prkit`. `blocked` keeps its meaning: prerequisite not started. |
| Staleness guard | A stored label needs a guard, so **`start` verifies live**: one `gh pr view` on the blocker before cutting the branch. The label is discovery; the live check is the gate. |
| Label writer | **`prkit` writes `blocked → stacked` when it opens the blocker's PR**, so the label is fresh the instant it becomes true. `sync` stays the repair sweep. This widens `prkit` beyond its own linked issue, so the write is **preview-and-confirm**, never exempt. |
| Merge cascade | `mergekit`'s `finish` takes one confirmation that **names every PR the cascade will merge, in order**. A tightening of the existing no-batch rule, not an exception to it. |
| `statuskit` | Its blocked test gains an exception: a still-open `blockedBy` whose blocker has an **open PR** counts as unblocked and joins the pick-up-now table with a stack marker. Nearly free, since `statuskit` already does an open-PR read. |
| `afkkit` | Chain-draining deferred. One honesty edit lands now, so the batch preview names the `stacked` issues it skipped. |
| Depth cap | **None stated.** Name the mechanism instead: each layer multiplies review and restack work. A number would make a judgment call look like a constraint. |
| Fork PRs | Refuse at setup with the reason, not at failure. |

## Approach

### What it reuses

- **`gitkit`'s existing base-ref ladder and worktree lifecycle.** The stack work is one exception to a rule that already exists and one extra source for a base, not a parallel system.
- **The existing `blocked` machinery.** The `Blocked by #N` convention, the `sync` promotion, and the `create` preview table all stay. `stacked` is one more rung on a ladder that already exists.
- **`statuskit`'s open-PR read and its documented "a blocker may be a PR" rule.** The Phase 5 exception is that sentence applied one step further, against data it already fetches.
- **`issuekit`'s expand → migrate → contract section**, which already fans one un-sliceable change into a blocked chain. Those migrate batches are the clearest stack candidates in the collection.
- **`mergekit`'s confirmation rule**, which already bans a batch confirmation. The cascade is handled by making the batch visible in the prompt, not by carving an exception.

### Phase 1: `gitkit` learns stacks (built 2026-08-29)

Edit `skills/gitkit/SKILL.md` and add `skills/gitkit/stacks.md`.

**Inline in `SKILL.md`:**

- **The base-ref exception.** State it where the sibling-branch ban is stated, as the one deliberate case that is legal: a stack layer's base is the branch below it. Say the ban still holds for every accidental sibling base, which is what it was written to catch.
- **The layer-worktree rule.** One worktree per layer, each cut from the layer below, named by the layer's own branch. The one-branch-one-worktree invariant is unchanged, so nothing else in the file moves.
- **A pointer to the satellite**, phrased so it fires only on the stack branch.
- **One new trigger** in the `description`.

**In `skills/gitkit/stacks.md`:**

- Preflight: `gh` 2.94.0 floor (soft), git 2.20+, the extension install line `gh extension install github/gh-stack`, the fork refusal, and the signed-commit warning with "rebase locally" as the answer.
- The plumbing commands `gitkit` owns: `init`, `add`, `rebase`, `sync`, `view`, `link`.
- The commands it does **not** own, named with their owner: `submit` is `prkit`'s, `merge` is `mergekit`'s.
- `gh stack modify` as a one-line pointer for a human.
- The degradation path: no extension means `git switch -c <branch> <parent>` plus `gh pr create --base <parent>`, and GitHub renders no stack map.
- The cost of depth, stated as a mechanism with no number.

**Done when** `SKILL.md` states the base-ref exception and the layer-worktree rule inline, the satellite carries the whole `gh stack` surface, `gitkit` still says it never opens or merges anything, the description gains exactly one branch, and the no-`gh` core path is unchanged.

### Phase 2: the `stacked` lifecycle state (built 2026-08-29)

**`repokit`.** Add `stacked` to the canonical lifecycle table with a color and description. Pick a color distinct from `blocked`'s `D93F0B` and `ready`'s `0E8A16`. Both tables must stay aligned on names, colors, and meanings.

**`issuekit`.** Five edits:

1. **Lifecycle map.** Add the `stacked` row: prerequisite is in flight with an open PR, so this is workable now on a layer above it. State the `blocked` versus `stacked` pair the way the file already states the `ready` versus `blocked` pair.
2. **Native dependencies.** Write the edge with `gh issue edit --add-blocked-by <n>` and read it with `--json blockedBy`. Keep writing the `Blocked by #N` body line as prose. Below `gh` 2.94.0, write the line only and say the native edge was skipped.
3. **`start`.** Widen the guard to accept `stacked`. Before cutting the branch, **verify the blocker's PR is open** with one `gh pr view`, and refuse with the reason when it is closed, merged-and-deleted, or missing. Then cut from the parent layer through `gitkit`. Leave every other refusal reason unchanged.
4. **`sync`.** Add `blocked → stacked` as the repair sweep, and add the cascade case where one stack merge closes several issues at once.
5. **`create`.** Soften "design the dependency away": a surviving dependency is now a stack candidate rather than a defeat. Add a **Stack** column to the preview table. Rewrite the expand → migrate → contract section so the migrate batches read as layers.

**`close` protects the stack.** Do not tear down a worktree that a higher layer still branches from.

**Done when** `repokit` and `issuekit` carry identical `stacked` rows, `start` refuses a `stacked` issue whose blocker has no open PR, the native edge is written and read with the body line as fallback, and the `ready` guard's wording is unchanged everywhere it appears.

### Phase 3: `prkit` (built 2026-08-29)

- **Base resolution.** Get the layer base from `gitkit` when the branch is a layer. Drop the "current branch equals base, stop" refusal for layers.
- **Sync.** Use `gh stack rebase --upstack` inside a stack, in place of the plain rebase.
- **Submit.** Prefer `gh stack submit` when opening several layers at once. This is the half of the `gh stack` surface `prkit` owns.
- **Body.** Add a stack map: position in the stack, the layer below, the issue this layer closes.
- **Write `blocked → stacked` on dependents.** When the PR just opened is a blocker, flip the issues it unblocks. **Preview and confirm**, never exempt: `prkit`'s existing exemption is scoped to its own linked issue, and this reaches third-party issues, so it does not inherit that exemption.

`Closes #N` needs no change; GitHub resolves it per layer.

**Known limitation: a closing keyword is inert on a layer.** This is a property of the platform, not a defect in the kits. GitHub honours `Closes #N` only when the pull request targets the repository's **default branch**. On any other base the keyword is plain text, so every layer above the bottom one ships an issue link that resolves to nothing, and `closingIssuesReferences` comes back empty for it.

Observed in `mimukit/saasaloy`: PR #96 targets `issue-86-…` rather than `main` and carries `Closes #87` exactly as written, and its `closingIssuesReferences` is empty, while sibling PRs #89 and #95 target `main` and both link.

There is no API that registers the link early. `gh issue develop <n> --name <existing branch>` fails with `API returned empty branch name`, and the raw `createLinkedBranch` mutation returns `linkedBranch: null` for a branch that already exists. The link registers only once the base **is** the default branch, which happens by itself when the layer below merges and GitHub retargets the PR.

The consequence for this plan is documentation rather than code. `prkit` keeps writing the keyword, states the limitation in the stack map, checks `closingIssuesReferences` after opening a layer PR, and reports an empty result as expected. `prkit` never retargets a PR to force the link, because that discards the stack. `issuekit sync` treats a body carrying `Closes #N` alongside an empty `closingIssuesReferences` as the stack signature and repairs it. `statuskit` falls back to a body scrape for a PR whose base is not the default branch.

**Done when** `prkit` opens a layer PR against its parent branch, the body carries the stack map, the dependent flip previews before it writes, and a non-stacked branch takes exactly the path it takes today.

### Phase 4: `mergekit` (built 2026-08-29)

- **`finish` forks on stack membership.** A cascade merge takes one confirmation that **names every PR it will merge, in order**, with title and number. The existing rule bans a batch confirmation because the human has not reviewed each PR; the fix is to put the whole cascade in the prompt, not to carve an exception.
- **`list`** shows stack position per PR.
- **After a cascade**, hand a **set** of issues to `issuekit close`, not one.

**Done when** no cascade can run without a confirmation listing every affected PR, and a single-PR merge is unchanged.

### Phase 5: `statuskit` and `afkkit` (built 2026-08-29)

**`statuskit`.** Amend the blocked test: an issue with a still-open `blockedBy` whose blocker has an **open PR** counts as unblocked. It joins the pick-up-now table with a stack marker rather than the blocked table. Without this the dashboard files every stackable issue in the one table it tells the reader to skip, and the feature is invisible at the moment someone asks what to work on.

**`afkkit`.** One honesty edit. Batch mode drains `ready` and passes over `blocked`; it will now pass over `stacked` too. Its up-front preview promises to name what it left out, so name the skipped `stacked` issues and say chain-draining is not supported yet. No pipeline change.

**Done when** a `stacked` issue appears in `statuskit`'s pick-up-now table, and `afkkit all` lists the `stacked` issues it skipped in its preview.

### Phase 6: repo integration and live test

Surfaces, all checked by `make lint`. No new skill means no `README.md` row, no `skills.sh.json` entry, and no new wiki page:

1. `docs/wiki/skills/gitkit.md` — the stack behavior, the satellite, and the changed `description`. The summary table's tools and writes rows change.
2. `docs/wiki/skills/issuekit.md`, `prkit.md`, `mergekit.md`, `repokit.md`, `statuskit.md`, `afkkit.md` — each gains a rule, a mode behavior, or a label.
3. `make lint` — run it, fix every error, address the warnings. Expect the single-skill-page warning not to fire, since this touches many skills at once.

Then live-test with `make link gitkit` in a fresh session. Run one real two-layer stack end to end in a scratch repo: file two dependent issues, start the bottom, open its PR and watch `prkit` offer the dependent flip, start the top on a layer branch, open its PR, then merge the cascade through `mergekit` and confirm both issues close. Run `make unlink gitkit` afterwards.

**Done when** `make lint` is clean, all seven wiki pages match their skills, and the two-layer run has produced a merged stack with both issues closed.

## Open questions

These are settled at the live test rather than by more discussion.

- **Does the stored `stacked` label earn its context load?** It was chosen over a computed state for the `gh issue list --label stacked` fan-out. The cost is a label that is only as fresh as its last writer. If the live test shows `start`'s live check catching drift more than once, the computed form was the right answer after all.
- **Is `prkit`'s preview-and-confirm on dependents too chatty?** It fires on every blocker PR that unblocks something. If a normal run turns into a prompt per dependent, the write may belong back in `sync`.
- **Did the satellite split land the base-ref exception on the right side?** If a stack run keeps having to open `stacks.md` for something the inline half should have carried, the seam is wrong.
- **What does `sync` do when a layer's PR is closed unmerged?** GitHub rebases the layers above onto the layer below. The tracker consequence is a rule `sync` needs and this plan does not write. Settle it the first time it happens rather than inventing it now.

## Non-goals

- **A `stackkit` skill.** Rejected at the grill. Stack support lives in `gitkit`.
- **`afkkit` chain-draining.** Deferred to a follow-up plan, not rejected. It is the largest payoff and the largest risk: a broken bottom layer poisons every layer above it, and `gh stack modify` cannot run unattended. Ship the attended path, land one real stack, then plan it.
- **Reimplementing the stack graph.** `gitkit` wraps `gh stack` and stores no local stack state of its own.
- **Driving `gh stack modify`.** It is a TUI. `gitkit` names it and a human runs it.
- **Cross-fork stacks.** Unsupported by the feature. Refuse them with the reason.
- **Replacing `blocked`.** A prerequisite nobody has started is still a wait, and still `blocked`.
- **A second merge authority.** `mergekit` keeps the only permission to merge, and `gitkit` takes plumbing only.
- **A hard `gh` version floor.** These are public skills on other people's machines. Degrade, state it, keep working.
- **Depending on GitHub's own `gh-stack` agent skill.** It exists and targets Copilot. This collection carries its own vocabulary and hand-off contract.
- **Auto-stacking.** No kit decides on its own that two issues should become a stack. The human, or `issuekit create`'s preview table, proposes it and the human approves.
