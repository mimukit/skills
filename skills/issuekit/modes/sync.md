## Mode: `sync`

Reconcile and repair the PR↔issue relationship after the fact. **Sync never writes the forward `Closes #N` link onto a fresh PR**; the PR-authoring skill (a prkit-style skill) does that at open time. Sync repairs drift after merge, repairs a missing link on an existing PR, advances lifecycle labels, and unblocks dependents.

### 1. Reconcile a merged PR whose issue never closed
Find PRs merged recently whose linked issue is still open. Two causes produce the same drift, and the sweep has to catch both:

```sh
gh pr list --state merged --limit 20 --json number,title,body,baseRefName,closingIssuesReferences
gh issue list --state open --json number,title
```

- **The keyword was never written.** The body carries no `Closes #N` at all, so GitHub had nothing to resolve.
- **The keyword was written and GitHub ignored it, which is the stack signature.** The body carries `Closes #N` while `closingIssuesReferences` comes back **empty**: a stack layer merged without the retarget that [Linking a PR to an issue](../SKILL.md#linking-a-pr-to-an-issue) describes, so the issue stays open with a correct-looking body.

Read the body and `closingIssuesReferences` together rather than either alone. A body with the keyword is not evidence of a link, and an empty `closingIssuesReferences` is not evidence of a missing keyword.

For each merged PR that *should* have closed an issue (evident from `Closes #N` in the body, the branch, the title, the plan, or the user telling you), **preview it and confirm before closing**:

> PR #10 (`feat(auth): add sso login`) merged, but issue #42 is still open → close #42 with a comment linking the PR?

On approval:

```sh
gh issue close 42 --comment "Closed by #10 (merged)."
```

Strip any active status label (`in-review`, `in-progress`, …) in the same action as the close (see [Labels: advance lifecycle state](#3-labels-advance-lifecycle-state-unblock-whats-freed)). **If which issue a PR should have closed is ambiguous, ask rather than guess.**

This step is done when every merged PR in the sweep has a verdict: linked and closed, closed on approval, declined by the user, or asked about as ambiguous.

### 2. Repair a missing link on an existing open PR
If an **open** PR should reference an issue but doesn't, add `Closes #N` to its body (editing the existing PR, not opening a new one):

```sh
gh pr edit <pr> --body-file <updated-body>
```

**Sweep the open layer PRs too, so the drift is caught before the merge rather than after.** A layer PR needs a different repair from a body rewrite, so classify it before you touch it:

```sh
gh pr list --state open --json number,title,body,baseRefName,closingIssuesReferences
gh repo view --json defaultBranchRef -q .defaultBranchRef.name
```

- **Base is the default branch, body has no keyword** → the plain repair above. Add `Closes #N` and the link registers.
- **Base is not the default branch, body carries `Closes #N`, `closingIssuesReferences` empty** → **expected, not drift.** Report it and change nothing. Retargeting the PR to trunk would destroy the stack.
- **Base is not the default branch, body has no keyword** → a real gap, and the fix is the same body edit. Write `Closes #N` now so the link registers the moment the retarget lands.
- **Base is now the default branch, body carries `Closes #N`, `closingIssuesReferences` still empty** → a layer GitHub already retargeted, whose body it never re-parsed. Force the re-parse by writing the same body back, and check the link again:

```sh
gh pr view <pr> --json body -q .body > <file>
gh pr edit <pr> --body-file <file>
```

Preview each of these like any other mutation, and say which of the four cases each PR fell into. This step is done when every open PR in the sweep sits in one of the four cases, and each repair is applied or declined.

### 3. Labels: advance lifecycle state, unblock what's freed
Move issues through the [lifecycle labels](../SKILL.md#lifecycle-labels-every-mode) as PRs advance: an issue whose PR just opened → `in-review`; and when an issue that was a **blocker** closes, set each of its dependents with [the transition rule](../SKILL.md#promoting-a-dependent). The rule rechecks every open prerequisite of the dependent, so `ready` appears only when the last one has landed. Optionally comment that the prerequisite landed:

```sh
gh issue edit 44 --remove-label blocked --add-label ready     # the rule found no open prerequisite
gh issue comment 44 --body "Unblocked: #43 (the prerequisite) merged."
gh issue edit 42 --remove-label in-review   # closing → strip the active status label; the closed state is the signal
```

**`sync` is the repair sweep for `stacked`, not its primary writer**; the skill that opens the prerequisite's PR sets the label. `sync` catches what that path missed: a PR opened by hand or on GitHub, a declined flip, a stale label. Each sweep recomputes every `blocked` and `stacked` issue with [the transition rule](../SKILL.md#promoting-a-dependent), and the result is one of three moves, each run without a prompt:

```sh
# every open prerequisite has an open PR in one chain → the dependent is workable on a layer
gh issue edit 44 --remove-label blocked --add-label stacked
# every prerequisite merged → the dependent no longer needs a layer
gh issue edit 44 --remove-label stacked --add-label ready
# a prerequisite's PR closed unmerged → the dependent is a real wait again
gh issue edit 44 --remove-label stacked --add-label blocked
```

When the open prerequisites have PRs on separate branches, the rule keeps the label and the hand-off names the incompatible parents.

**A stack merge closes several issues at once**, because merging one PR in a stack merges every unmerged PR below it. So reconcile the whole cascade rather than the one PR someone named: read every merged PR in that stack, close each issue it closes, and then run the promotions above for whatever those closures freed.

This step is done when every open `blocked` and `stacked` issue carries the label the transition rule computes for it, or is named in the hand-off as unknown or as having incompatible parents.

**Relabel without asking**, per [the label exemption](../SKILL.md#preflight-every-mode). The closes and body edits around them still wait for an OK.

### 4. Hand off
**What changed.** Report issues closed, PR bodies repaired, and issues advanced or **unblocked** (`blocked` or `stacked` → `ready`, `blocked` → `stacked`). Name every label move, because those ran without a prompt. Name each dependent left alone, with its reason: an unknown PR query, or incompatible stack parents. Say plainly if nothing needed repairing.

**Where it landed.** Give the **actionable set**: a table of every open issue that is `in-progress` or `ready` *after* the sync, so the user sees at a glance what's being worked and what they can pick up next in a fresh worktree:

```sh
gh issue list --state open --label in-progress --json number,title
gh issue list --state open --label ready --json number,title
```

| # | Title | Status | Priority |
|---|-------|--------|----------|
| 43 | `feat(auth): oidc login end to end` | `in-progress` | high |
| 44 | `feat(auth): sso account linking` | `ready` | medium |

List `in-progress` rows first, then `ready`, each group ordered by priority. If both sets are empty, say so instead of printing an empty table. Drop the `Priority` column when no row carries one, and point at `triage` to rank them.

**Next.** Crown one row from that table, naming a kit only when it's installed: an `in-progress` issue is unfinished work and outranks a fresh start (resume it in its worktree with **implementkit**), while a `ready` one is the pick-up (`start <n>`). Priority orders *within* each group and doesn't jump a `ready` issue over an `in-progress` one. The exception is a `critical`, which means preempt by definition: crown it over in-progress work and say plainly what's being set down. Both sets empty means the tracker has nothing workable, so the move is `create` from a plan, or **plankit** if there isn't one yet.

