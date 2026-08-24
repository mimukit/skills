# issuekit

Own the GitHub issue lifecycle in five modes — file the work, pick it up, land it, keep it in sync as PRs merge, and keep the tracker honest and ranked.

**Reach for it when** a plan needs turning into issues, or an issue needs starting, closing, or reconciling.

| | |
|---|---|
| Modes | [`create`](#create) · [`start`](#start) · [`close`](#close) · [`sync`](#sync) · [`triage`](#triage) |
| Tools | `Bash`, `Read`, `Edit`, `Write`, `Skill` |
| Writes | GitHub issues, labels, PR bodies; annotates the source plan |
| Visibility | public |

## What it does

Five jobs in one skill, because they're the same job at five points in a dev workflow.

**`close` vs `sync`** is the split worth understanding: it's by *scope*, not mechanism. `close` lands **one named issue** whose PR you know merged, and is the only mode that touches the filesystem. `sync` sweeps the **whole tracker** for drift after the fact and never touches a worktree. `close` reuses `sync`'s reconciliation rather than restating it.

**If no mode is clear, it asks first.** It won't guess between creating and mutating the tracker.

## Safety stance

Creating, closing, and relabeling issues are outward-facing mutations. **Every one is previewed and gets an OK before it runs.** It never merges PRs.

**One exemption exists, and it belongs to the mode rather than the caller.** `start`'s `ready → in-progress` flip runs unprompted, whether you typed the command yourself or an unattended orchestrator like [`afkkit`](./afkkit.md) did.

It's the only mutation whose approval is already implied twice: the `ready` guard has refused everything a human hasn't grilled, and asking for the issue to be started is asking for it to be marked started. The cost of prompting is real, too — an issue that sits in a worktree while the tracker still shows it `ready` is an issue another worker can pick up. Nothing else widens, and **no caller of any kind gets to skip the guard itself.**

## The lifecycle labels

issuekit **uses** these labels and never creates them. Provisioning is [`repokit`](./repokit.md)'s job — a missing label means it stops and tells you how to add it rather than creating it silently.

| label | means |
|-------|-------|
| `triage` | filed, not yet assessed |
| `needs-planning` | a human plan/grill session is still owed |
| `ready` | specified and **independent** — safe to take into its own worktree now |
| `blocked` | has an unmet prerequisite, named in the body as `Blocked by #N` |
| `in-progress` | actively being worked |
| `in-review` | a PR is open |
| `needs-info` · `wontfix` · `duplicate` | side exits |

Two pairs carry the design:

**`ready` vs `blocked` is the parallel-work pair.** issuekit sizes and sequences issues so each can be picked up in its own worktree with no ordering constraint. `gh issue list --label ready` is then the exact set you can fan out right now.

**`needs-planning` vs `ready` is the human-gate pair.** `ready` means specified enough to work **unattended**. An issue earns it only once a grill settled its decisions.

**Type lives in the title, not a label** — issues carry `feat(scope):` per the Conventional-Commits title convention shared with [`commitkit`](./commitkit.md), whose type set it now matches exactly, so the map holds only lifecycle status. A **closed** issue needs no `done` label; the closed state is the signal.

## The priority labels

The second label namespace, and the one that decides what gets picked up next. Like the lifecycle set, issuekit **uses** these and [`repokit`](./repokit.md) provisions them.

| label | means |
|-------|-------|
| `critical` | drop everything — preempts work already in progress |
| `high` | do this before other workable issues |
| `medium` | normal priority — the default once assessed |
| `low` | worth doing eventually — never preempts anything |

**Lifecycle and priority are orthogonal — one label from each, and neither implies the other.** Lifecycle answers *can this be worked?*; priority answers *should this be worked next?* An issue is `ready` **and** `high`, or `blocked` **and** `critical`, and both are coherent. Never inferring one from the other is load-bearing rather than tidy: promoting an issue to `ready` because somebody marked it `critical` is exactly how ungrilled work reaches an unattended worker, and the `ready` guard exists to stop that. Urgency is a reason to work something sooner, never a reason to work it with fewer checks.

**No priority label means *unassessed*, not `medium`.** The absence is a real state and it's what `triage` hunts for. An unranked issue everyone assumes is normal-priority is indistinguishable from one somebody actually thought about — and that distinction is the whole value of the scale. The side exits (`wontfix`, `duplicate`) are going nowhere and need no rank.

**Exactly one priority at a time, enforced at write time because GitHub won't.** Labels are a flat namespace with no mutual exclusion, so nothing stops an issue carrying `critical` and `low` at once, and a double-ranked issue sorts unpredictably everywhere downstream. Every write is therefore a *replace*: issuekit reads the issue's current labels and removes whichever sibling is actually there in the same call that adds the new one. Computing the removal from what's really on the issue — rather than blind-removing all three siblings — is what keeps the preview honest, since `medium → high` reads differently from `set high`.

**Why labels rather than a GitHub Projects priority field** is [explained on repokit's page](./repokit.md#labels), which owns the provisioning decision. The short version: Projects v2 needs an OAuth scope `gh auth login` doesn't grant, and priority would only exist for issues added to a board.

## Modes

### `create`

Turn a plan document or a plain description into well-formed issues.

**The default shape is one issue per plan**, carrying the plan's phases as `## Phase N` headings in its body. That is a deliberate reversal of the epic-and-children breakdown this skill used to propose. Every split costs a worktree, a branch, a PR, a review, and a close, and it buys sequencing that phases in one body already carry for free — while an agent can now build a large issue phase by phase in a single unattended run. So the split has to earn itself: a piece gets its own issue when it ships on its own, wants its own PR, or has a real ordering constraint that survived the attempt to design it away.

Four principles govern the breakdown, applied **before** anything is presented:

- **One issue per plan by default.** Phases go in the body, not in separate issues. Starting consolidated beats starting fragmented, because splitting later is one request and merging later is not.
- **Vertical slices.** Size each issue to complete **one testable feature end to end** — "user can log in with SSO" rather than separate "add OIDC table" / "add OIDC route" / "add OIDC UI" issues. **Nothing caps a slice at what fits in one agent context**; a multi-phase issue is the normal shape.
- **Independent by default.** Where a plan does yield more than one issue and two of them share state, first try to **design the dependency away** — fold them back into one issue as consecutive phases, or resequence so the shared piece ships inside the prerequisite. Only a surviving real constraint gets recorded.
- **Prefactor first.** Look for a simplifying refactor that makes the real change trivial. It normally belongs as the issue's **first phase**, where the code that needs it follows in the same branch; it earns its own issue only when it ships and reviews on its own merits whether or not the feature lands.

A wide mechanical refactor is the standing exception. Renaming a shared column or retyping a symbol used everywhere gets sequenced **expand → migrate → contract**, because the migrate batches are independent *of each other* and want parallel branches — the one thing phases in a single issue cannot do. It reuses the existing `blocked` machinery with no new labels.

The proposal comes as a **preview table** and stops for approval. Its **Phases** column is the plan's structure carried into one issue, and its **Depends on** column is empty by construction on a one-issue breakdown. When a phase looks like it ships on its own, the split is offered explicitly, with its cost named: a second branch, PR, review, and close. **This guard is the point: never spray a repo with auto-generated issues.**

The table also carries a **Priority** column. issuekit proposes a priority per row read off the plan — what it calls core versus polish, what it defers, what it flags as a risk — and expects to be overruled, because a plan can say what's central without saying why the work is being done at all, which is the thing priority actually encodes. It never proposes `critical` from a plan: that label means *preempt work already in progress*, a claim about right now that a document written last week can't make, so the most important row gets `high` and you escalate it if you mean it. Approved priorities land in the same `gh issue edit` call as the lifecycle label, so a fresh issue never sits half-labeled where a concurrent survey could read it. And they land **regardless of the grill gate**, which governs only the lifecycle namespace — an ungrilled issue is `needs-planning` because nobody has settled its decisions, but "this matters more than that" is a judgment you just made in the preview. Dropping it would leave the ungrilled backlog, the exact pile that most needs ordering, as the one part of the tracker nothing can rank.

It also **guards against duplicates** before creating, because `create` is the workflow's entry point and gets re-invoked. And **milestones are opt-in** — never introduced by default, because you'd then have to maintain them.

The **grill gate** decides which label vocabulary applies. A plan carrying grillkit's `Grilled: YYYY-MM-DD` stamp gets the normal `ready`/`blocked` pair. An ungrilled source gets **`needs-planning` on everything** — which is what keeps afkkit from picking up work a human hasn't grilled.

### `start`

Pick an issue up. Deliberately thin: the tracker half is issuekit's, the worktree half is [`gitkit`](./gitkit.md)'s, and there's nothing in between.

**Never start an issue that isn't labeled `ready`.** This one guard carries more weight than its size suggests, and it's the reason `start` lives here rather than in a worktree skill.

An issue reaches `ready` only two ways: a human grilled its decisions settled, or `sync` promoted it when its prerequisite landed. So refusing everything else enforces **both the dependency graph and the human-grill gate for free.**

The gate does not depend on who types the command. It's the *label* that carries the human's judgment, earned upstream at the grill, and nothing calling `start` can award it. So it refuses on the label alone — **never softened because the caller sounds confident, names a plan, or says it's fine.**

Refusals name the reason. An issue already `in-progress` isn't a failure — it takes the adopt path, where gitkit hands back the existing worktree and the label is left alone. That's what makes `start` safe to re-run.

### `close`

The other bookend. The issue's PR merged, so close it out and reclaim its workspace.

**A merged PR is required, not assumed.** No PR, or one still open, means `close` does **nothing** — no close, no label change, no worktree removal.

That precondition is the whole reason `close` is safe to run on a name you half-remember. Its two irreversible acts — closing the issue and deleting a worktree — are both gated behind evidence the work actually landed. Forced teardown of unlanded work stays something you do deliberately, through gitkit directly.

The preview names **every** effect, including routine ones: unblocking a dependent changes what someone else picks up next, and removing a worktree deletes a directory they may have a terminal sitting in.

Teardown goes to gitkit, whose rules aren't overridden: **a dirty worktree stops the removal**, because a merged PR does not guarantee an empty worktree — scratch files, a stashed experiment, an unpushed follow-up all live there and none are in the PR.

### `sync`

Reconcile the PR↔issue relationship after the fact.

It **deliberately does not write the forward `Closes #N` link onto a fresh PR** — that's [`prkit`](./prkit.md)'s job at open time. sync earns its place only where the automatic chain *broke*: a merged PR whose issue never closed, a missing link on an existing PR, and the dependency payoff — when a blocker closes, finding what it was holding up and swapping `blocked` → `ready`.

**If which issue a PR should have closed is ambiguous, it asks rather than guesses.** Closing the wrong issue is worse than leaving one open.

Its hand-off prints the **actionable set** — every open issue that's `in-progress` or `ready` after the sync — so you see at a glance what's being worked and what you can pick up. `in-progress` rows come first, each group is ordered by priority, and the Priority column is dropped when no row carries one: an all-blank column reads as "nothing matters" when the truth is "nobody has ranked these", and the fix for that is `triage`, not a wider table. The crowned row follows one rule — priority orders *within* each group and never jumps a `ready` issue over an `in-progress` one, because a half-built `medium` still costs less to land than a fresh `high`. The exception is a `critical`, which means preempt by definition: it gets crowned over in-progress work, with a plain note about what's being set down.

### `triage`

Report first, act on approval. **It never mutates the tracker just to tidy up.**

It fetches `--state all`, because a `Blocked by #N` pointing at an already-closed issue is drift the open-issue list alone cannot see.

The drift it flags: stale · orphaned · **zombie label** (a closed issue still carrying a status) · **stale block** (a `blocked` whose target already closed) · dangling or circular dependencies · unmarked · **ungrilled `ready`** — an issue promoted too early, offered a move back to `needs-planning` so unattended workers skip it until a human grills it.

Three more come from the priority namespace: **unassessed** (no priority label — counted separately from *unmarked*, since a tracker with tidy lifecycle labels and no priorities anywhere is both common and invisible if the report prints one number), **double-ranked** (more than one priority label, which the GitHub UI will happily produce since it applies labels additively — the repair keeps the highest, because over-ranking an issue you're about to look at beats burying one somebody explicitly escalated), and **stale `critical`** (untouched for weeks, which is self-refuting: nobody dropped anything for it, so the tracker is saying out loud that it isn't critical, and left alone it outranks everything downstream forever and trains you to ignore the one level that's supposed to be unignorable).

**Ranking a backlog is proposed as one table, not one question per issue.** Priority is comparative by nature — you're deciding what beats what — and a table is the only shape that shows the comparison you're actually making. Asked one at a time, twenty issues become twenty context-free judgments and every one comes back `medium`, which is the same as not ranking at all. The proposal aims for a *distribution* (`critical` empty or nearly so, `high` a handful, a long `medium`/`low` tail), because a backlog where most things are `high` carries no priority information: the label stops discriminating and every consumer silently falls back to the tiebreak underneath.

**And it never applies a priority you didn't approve.** Every other triage fix repairs a state that's provably wrong — a zombie label on a closed issue, a block whose blocker landed. Priority is a claim about what matters, and only you can make it.

triage only classifies. The fixes it can't make itself route to a sibling mode.

## Where the boundaries sit

**Worktrees and branches are gitkit's.** `start` and `close` bookend a worktree's life and both get it from [`gitkit`](./gitkit.md) — branch name, path convention, create-or-adopt, teardown. issuekit answers *"is this issue workable, and what does the tracker say now?"*; gitkit answers *"where does the code for this branch live?"*

**Labels are repokit's to create.** The label maps here are a shared contract with [`repokit`](./repokit.md), duplicated on purpose because each skill must stand alone once installed. This repo's `make lint` diffs them on every full run and errors on drift — one check covers both namespaces, since the rows share a format.

**Whether a project uses GitHub Issues at all is [`statuskit`](./statuskit.md)'s question, not issuekit's.** It sounds like it should live here, and the charter argument for that is real. It doesn't, because invoking issuekit already answers it: someone asking to file, start, or close an issue has said where their work lives. So `create` files issues without first checking whether the project files issues, and no mode ever declines on the grounds that the repo looks like it tracks work in Linear. statuskit needs the answer because it surveys a repo nobody has told it anything about and has to crown exactly one move; issuekit is always invoked deliberately.

## Hands off to

By mode and by what came back. `create` with `ready` issues → `start` on the highest-priority one, breaking a tie on whichever frees the most other work. `create` with everything `needs-planning` → [`grillkit`](./grillkit.md), because nothing is workable unattended yet. `start` → the worktree and [`implementkit`](./implementkit.md), or [`afkkit`](./afkkit.md) for an unattended run. `close` → whatever this close unblocked, unless **the worktree survived dirty**, which outranks everything, because unlanded work in a stale worktree is what gets lost.

## Install

```sh
npx skills add mimukit/skills -s issuekit
```

Source: [`skills/issuekit/SKILL.md`](../../../skills/issuekit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`8cfe301` on 2026-08-24._
