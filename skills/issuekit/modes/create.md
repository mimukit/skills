## Mode: `create`

Turn work into issues. Two inputs: a plan file (the main path) or a plain description (start fresh).

### 1. Find the input
- **Plan path:** a `NNNN-plan-<slug>-YYYY-MM-DD.md`, or an older `plan-<slug>-YYYY-MM-DD.md` without the serial. Resolve it by precedence: an explicit path in the prompt → the newest canonical plan under `docs/plans/` (the highest leading serial; for plans without one, the latest creation-date suffix) → ask which plan.
- **Ad-hoc path:** a plain description with no plan. This is the "start fresh, just file it" case → one well-formed issue.

### 2. Decompose a plan into a proposed breakdown
Read the plan's structure (phases, milestones, tasks) and decide the shape. Four principles govern the breakdown, applied **before** you present anything:

- **One issue per plan by default.** A plan becomes a single issue, and the plan's phases become [`## Phase N` sections in that issue's body](#3-create-the-issues) rather than separate issues. Split only where a piece has a genuinely different lifecycle: it ships on its own, it wants its own PR, or a real ordering constraint survives the attempt to design it away.
- **Vertical slices.** Size each issue so it completes **one testable feature end to end**, meaning something a person could verify on its own, rather than a horizontal layer (e.g. "all the DB models", "all the endpoints") that isn't demonstrable until other issues land. Where a plan does yield two issues, prefer "user can log in with SSO" over separate "add OIDC table" / "add OIDC route" / "add OIDC UI" issues. **Nothing caps a slice at what fits in one agent context.** A multi-phase issue is the normal shape here, and an unattended worker builds it phase by phase.
- **Independent by default.** Where a plan does yield more than one issue, sequence them so each can be picked up in its own git worktree and worked **in parallel**, with no issue waiting on another. When two candidate issues share state (a migration one creates and another consumes, an API contract one produces), first try to **design the dependency away**: fold them back into one issue as consecutive phases, or resequence so the shared piece ships inside the prerequisite. Only when a real ordering constraint survives do you record it: the dependent gets [`blocked`](../SKILL.md#lifecycle-labels-every-mode) and a recorded dependency, everything else gets `ready`.
- **A surviving dependency is a stack candidate.** A dependent whose prerequisite is *in flight* becomes [`stacked`](../SKILL.md#lifecycle-labels-every-mode) and is worked on a branch cut from the prerequisite's. Say so in the preview, so the user chooses between "one issue with two phases" and "two issues that stack".
- **Prefactor first.** Before slicing anything, look for a simplifying refactor that makes the real change trivial: *"make the change easy, then make the easy change."* It normally belongs as the issue's **first phase**, where the code that needs it follows in the same branch. File it as its own `ready` issue (behavior-preserving → `refactor(scope):`) only when it stands alone, meaning it ships and reviews on its own merits whether or not the feature ever lands.

**Wide mechanical refactors are the exception to the one-issue default.** When a change cannot be one vertical slice, such as renaming a shared column or retyping a symbol used everywhere, file it as **expand → migrate → contract**:

- **expand.** Add the new form alongside the old. `ready`.
- **migrate.** Update call sites in batches by area, each batch its own issue [`blocked`](../SKILL.md#lifecycle-labels-every-mode) by the expand issue, with `layer on #<expand>` in the Stack column. The batches are independent of each other, so they run in parallel once expand's PR opens.
- **contract.** Delete the old form once nothing uses it, `blocked` by all the migrate batches, with `—` in the Stack column.

**Create milestones only on request**, or in a repo that already uses them: `gh api --method POST repos/{owner}/{repo}/milestones -f title="<title>"`, then `gh issue create --milestone <title>`. Otherwise map a plan's phases onto the issue body.

Present the proposal as a **preview table** and stop for approval. Do **not** create anything yet:

| # | Title | Priority | Depends on | Stack | Phases |
|---|-------|----------|-----------|-------|--------|
| 1 | `feat(auth): add sso login` | high | none | — | oidc provider · session + token refresh · login UI · account linking |

Titles follow the [title convention](../SKILL.md#title-convention-every-issue-this-skill-creates). The **Phases** column is the plan's structure, carried into one issue. In the **Depends on** column, `#N` means that issue is `blocked` by another row, and an empty cell is an issue the user can take into a worktree now.

The **Stack** column says what happens to a dependent once its prerequisite is in flight: `layer on #N` means it is worked as a stacked branch, and `—` means it is a plain wait. Fill it for every row whose *Depends on* cell is non-empty. The column records the intent that [`sync`](./sync.md) and the PR-authoring skill act on later. Let the user add, drop, retitle, **reprioritize**, **resequence to break a dependency**, or **split** any row before you proceed. Offer the split explicitly when a phase looks like it ships on its own, and say what the split would cost: a second branch, PR, review, and close.

**Propose a [priority](../SKILL.md#priority-labels-every-mode) per row, and expect to be overruled.** Read it off what the plan calls core, defers, or flags as a risk, and mark anything the plan doesn't rank as `medium`.

**Propose `high`, never `critical`, for the most important row.** `critical` means *preempt work already in progress*, which a plan cannot know; the user escalates it if they mean it.

For an **ad-hoc** description, skip the table: draft one issue (title, body, and priority) and confirm it before creating. Its priority is the one the user's words state; with none stated, the draft says `none`, and the issue stays unassessed for `triage` unless the user sets one at the confirm.

### 3. Create the issues
**Guard against duplicates first**, so running `create` twice on one plan files no second set. Before creating, list existing issues and skip (or flag for the user) any whose title already matches:

```sh
gh issue list --state all --limit 200 --json number,title,state
```

On trackers with more than 200 issues, raise the limit or use `gh search issues --repo {owner}/{repo} --match title "<candidate title>"` so older duplicates are not silently missed.

Then write each issue with a title in the [`type(scope): summary` convention](../SKILL.md#title-convention-every-issue-this-skill-creates) and a body that carries the relevant slice of the plan: context, phases, acceptance criteria, and any decisions.

**A multi-phase issue carries its phases as `## Phase N` headings**, one per phase of the plan, in the order they build, each followed by its own acceptance criteria:

```markdown
## Phase 1: oidc provider
- [ ] the app redirects to the provider and back
- [ ] the callback rejects a mismatched `state` parameter

## Phase 2: session + token refresh
- [ ] a session survives a browser restart
- [ ] an expired access token refreshes with no re-login
```

The headings let a builder target **one phase of the issue**, and an unattended run walks them to build a large issue in one branch.

Conventions for the body:

- **Scale the body to the work.** A one-line fix is one issue with one acceptance criterion.
- **Write acceptance criteria as `- [ ]` checkboxes**, under the phase they belong to, giving a concrete verifiable definition of done for that phase. A single-phase issue drops the headings and carries one flat list.
- **Order the phases as they build.** One branch builds them in sequence, so a phase may assume every phase above it has landed and must assume nothing about the ones below.
- **Don't hard-code file paths**, because they go stale as the branch evolves; describe the change by behavior and area instead. The one exception is a **decision-rich snippet** (a schema, state machine, type, reducer) where the decision *is* the code, so include it, trimmed to just the substantive part.

```sh
gh issue create --title "feat(auth): add sso login" --body-file <bodyfile>
```

Use a temp file for each body (multi-line markdown through `--body` is flaky) and clean it up after.

### 4. Label lifecycle state and priority, and record dependencies
Apply the [lifecycle labels](../SKILL.md#lifecycle-labels-every-mode) so the fresh issues advertise their state. The **grill gate** decides which vocabulary applies:

- **Grilled source.** The input plan file carries a `Grilled: YYYY-MM-DD` stamp (grillkit writes it when it hardens a plan), *or* the user explicitly says the work is grilled/ready. The decisions are settled, so the normal pair applies: every independent issue gets `ready`, every dependent one gets `blocked` plus a [recorded dependency](../SKILL.md#recording-a-dependency) naming the prerequisite.
- **Hotfix source.** An issue filed for a `hotfix-<slug>` branch skips the gate and takes its label from [the hotfix rule](../SKILL.md#title-convention-every-issue-this-skill-creates).
- **Ungrilled source.** Any other ad-hoc description, or a plan with no grill stamp, including one whose `Grilled:` line a later material edit removed. **Every issue gets `needs-planning`.** Record the dependency anyway; it takes effect once the issue is grilled into `ready`.

**Nothing is labeled `stacked` at creation time**, because no prerequisite has a PR yet. The label arrives later, from the PR-authoring skill or from [`sync`](./sync.md).

Then apply the [priority label](../SKILL.md#priority-labels-every-mode) shown in the preview, **at most one per issue, in the same `gh issue edit` call** as the lifecycle label, so a concurrent survey never reads a half-labeled issue.

Priority is applied **regardless of the grill gate**, which governs the lifecycle namespace only.

Confirm each label exists first (`gh label list`), checking both namespaces in that one call; a repo that predates priority will have the lifecycle ten and none of the four.

```sh
# grilled plan → ready / blocked, each with its approved priority
gh issue edit 43 --add-label ready --add-label high
gh issue edit 44 --add-label blocked --add-label medium --add-blocked-by 43
# ungrilled source → needs-planning, still ranked
gh issue edit 45 --add-label needs-planning --add-label low
```

Record the dependency in the same call that labels the issue, so a dependent never exists with a `blocked` label and no recorded prerequisite. On `gh` below 2.94.0, drop `--add-blocked-by`, keep the body line, and say the native edge was skipped.

### 5. Write the issue numbers back into the plan
Once issues exist, annotate the source `NNNN-plan-<slug>-YYYY-MM-DD.md` so it stays the source of truth. Add the ref to each phase heading the issue covers, without changing the file's name, serial and creation-date suffix included:

```markdown
### Phase 1: oidc provider (#41)
### Phase 2: session + token refresh (#41)
```

**The same number repeats on every phase one issue covers**; leave the repeats. A builder writes its own `(built YYYY-MM-DD)` stamp after the number, so the two annotations sit side by side.

Use `Edit` for this. For an ad-hoc issue with no plan file, skip this step.

### 6. Hand off

**What changed.** Give a table of what you created: number, title, URL, lifecycle label, priority, and phase count. Say that the plan was annotated.

**Where it landed.** Call out the **`ready` set** (issues the user can start in parallel worktrees right now) versus the **`blocked` set**, naming what each blocked issue waits on. Order the `ready` set by priority.

**Next.** Route on which set came back non-empty, naming a sibling kit only when it's installed and otherwise describing the action plainly:

- **`ready` issues exist** → pick one up with `start <n>`, which gets it a worktree and flips it `in-progress`. Crown the **highest-priority** one rather than listing all of them, breaking a tie on whichever frees the most other work.
- **everything is `needs-planning`** (an ungrilled source) → the next move is a human grill session, meaning **grillkit** on the plan, then the `triage` promotion for each issue (`#45 is grilled, mark it ready`), which moves it to `ready`, `stacked`, or `blocked`. Say that nothing is workable unattended yet, and do not offer `start`.
- **a hotfix issue** → route on its PR. With no PR yet, open one with `Closes #<n>` (**prkit** when installed, otherwise `gh pr create`). With an open PR, run `sync`, which adds `Closes #<n>` to its body. With a merged PR there is no next step, because `create` closed the issue.
- **everything is `blocked`** → surface the root prerequisite. When the breakdown marked dependents as stack candidates, say so here: starting the root frees them as soon as its PR opens, not when it merges.

