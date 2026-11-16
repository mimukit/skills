# Mode: `labels`

Provision the **workflow labels**. repokit *creates and reconciles* these labels and never applies one to an issue or a PR. Provision them whether or not issuekit is installed.

## Three sets, three independent namespaces

- **Lifecycle** (*can this be worked?*) and **priority** (*should this be worked next?*) describe an issue. An issue carries at most one label from each, and neither implies the other, so never collapse them into one ordered set.
- **Automation** is a PR trigger: a person adds it to a pull request to start a tool. It carries no state and never competes with a lifecycle or priority label.

## The canonical lifecycle set
Provision exactly this map. The `description` column here is canonical; issuekit mirrors the same names, colors, and meanings in execution-oriented wording.

| name | color | description |
|------|-------|-------------|
| `triage` | `FBCA04` | filed, not yet assessed or broken down |
| `needs-planning` | `F1C40F` | needs a human plan/grill session before it is workable |
| `ready` | `0E8A16` | specified and independent, safe to take into its own worktree now |
| `blocked` | `D93F0B` | has an unmet prerequisite that has not started |
| `stacked` | `006B75` | its prerequisite is in flight with an open PR; workable now on a branch stacked on it |
| `in-progress` | `1D76DB` | actively being worked in a worktree |
| `in-review` | `5319E7` | a PR is open, awaiting review or merge |
| `needs-info` | `D4C5F9` | stalled pending more detail before it can proceed |
| `wontfix` | `FFFFFF` | will not be actioned |
| `duplicate` | `CFD3D7` | superseded by another issue |

## The canonical priority set
Four levels. If the user asks for a fifth, say what it costs before adding it.

| name | color | description |
|------|-------|-------------|
| `critical` | `B60205` | drop everything; preempts work already in progress |
| `high` | `E99695` | do this before other workable issues |
| `medium` | `FEF2C0` | normal priority, the default once assessed |
| `low` | `C5DEF5` | worth doing eventually; never preempts anything |

Colors are 6-hex, no leading `#`.

**No priority label means *unassessed*, not *medium*.** `triage` reads the absence as a state. Never provision a default, and never treat a missing label as an implied middle.

**Priority is a label, not a GitHub Projects field.** Reading `projectItems` needs an OAuth scope that `gh auth login` does not grant by default, and without it the whole JSON query fails.

## The canonical automation set
One label, for the one automation this collection assumes: an AI review of a pull request.

| name | color | description |
|------|-------|-------------|
| `ai-review` | `34495E` | run the repo's AI review tooling on this PR |

**Creating `ai-review` reviews nothing until something listens.** A GitHub Actions workflow or an installed review app has to subscribe to it. Check what the repo already has before you promise a result:

```sh
grep -rl 'labeled' .github/workflows/    # a workflow that fires on a label event
```

An installed review app (Copilot, CodeRabbit, Claude) is configured outside the repo, so ask the user about it. When nothing listens yet, say so in one line and name the gap.

**The listener owns the name, not this map.** A workflow fires on the exact string in its `if:` condition, so a repo that already listens for `claude-review`, `copilot-review`, `coderabbit`, or `gemini-review` keeps that name. Adopt it and skip `ai-review`.

## 1. Check for an existing scheme first, in every namespace
You read the repo's labels in Detect. Before diffing, look for a **different-but-equivalent scheme** the repo already runs, in any namespace:

- **Lifecycle.** `status: blocked`, `S-ready`, `blocked ⛔`, or a `needs-*` family that already covers this ground.
- **Priority.** `P0`/`P1`/`P2`, `priority: high`, `pri-1`, `urgent`, or a `severity:` family being used as a de facto priority.
- **Automation.** `claude-review`, `copilot-review`, `coderabbit`, `gemini-review`, `needs-ai-review`, or any label a workflow file names as a trigger.

If one exists, **don't silently add a parallel set**. Surface it and ask which way to go:

- **Map onto theirs.** Treat the repo's labels as canonical; skip provisioning and (optionally) note the name mapping so issuekit-style workflows can be pointed at the existing names.
- **Add the canonical set.** The repo's scheme is incidental or abandoned; provision ours alongside it, and offer to retire the old labels only if the user explicitly asks.

Ask **per namespace**: a repo often has a mature lifecycle scheme and no priority scheme at all.

**A priority name match is not a meaning match.** A repo may use `critical`, `high`, or `low` for **severity**, effort **size**, risk, or a customer tier. When the repo already has one, read its description and two of the issues carrying it. If it is a different axis, name the collision and let the user decide whether to rename theirs, rename ours, or map onto it.

Absent any existing scheme in a namespace, go straight to the diff for that one.

**Under `setup`, ask nothing here.** A namespace with an existing scheme is skipped, neither mapped nor provisioned, and the hand-off names it with `repokit labels` as the place to decide. A namespace with no scheme is provisioned. Skip the question about an installed review app; report only what the workflow grep finds. This step is done when each of the three namespaces has an answer: no existing scheme, map onto theirs, or add the canonical set.

## 2. Diff against the canonical sets and preview
Sort each canonical label, from **all three** sets, into one of three buckets and show the plan before touching anything, grouped by namespace so the user can approve one and decline another:

- **Missing.** Not in the repo → will be **created**.
- **Drifted.** Present but wrong color or description → offer to **update** (this rewrites the label; get an explicit OK per label or for the batch).
- **Matches.** Present and correct → leave alone.

Labels **outside** the canonical sets (GitHub's defaults like `bug`/`enhancement`, or the repo's own) are **left untouched**, and you never delete a label unless the user explicitly asks.

This step is done when every canonical label in a namespace being provisioned sits in exactly one bucket, and the user has approved or declined each namespace's plan. Under `setup`, the plan is approved as shown: create every missing label and update every drifted one.

## 3. Apply, echoing the commands
On approval:

```sh
# create a missing label
gh label create ready --color 0E8A16 --description "specified and independent, safe to take into its own worktree now"
gh label create critical --color B60205 --description "drop everything; preempts work already in progress"
gh label create ai-review --color 34495E --description "run the repo's AI review tooling on this PR"

# update a drifted label (rewrites color/description in place)
gh label edit blocked --color D93F0B --description "has an unmet prerequisite that has not started"
```

Prefer `gh label create` for a missing label and `gh label edit` for a drifted one over `gh label create --force`, so the commands match the preview's buckets. This step is done when every approved create and update has run with its command echoed, and each command GitHub refused is reported with its error.

## 4. Hand off
**What changed.** Report what was created, updated, and left as-is, per namespace, and confirm which of the three sets the repo now carries in full. Provisioning one set and skipping another is a normal outcome, not a partial failure.

**Where it landed.** Name the repo's label list. If you mapped onto an existing scheme in any namespace, say which names won.

**Next.** Name one move and stop: start the issue workflow, with **issuekit** `create` to file work from a plan, or `triage` to classify and rank issues that were sitting unlabeled while the vocabulary was missing.

**When you created `ai-review` and nothing listens for it, crown that gap instead.** The label starts no review until a workflow or a review app subscribes to it. Say that in one line, and name `.github/workflows/` as the place to wire it. repokit does not write the workflow. When the repo already had open issues and priority is the set you just provisioned, crown `triage`: every one of those issues is now unassessed. Absent issuekit, say the labels are now available to whatever issue workflow the repo runs. If `about` hasn't run yet and the repo's About panel is empty, offer that as the smaller follow-up. When this run was delegated from `setup`, skip this hand-off; `setup` closes for the whole span.
