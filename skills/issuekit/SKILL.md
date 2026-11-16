---
name: issuekit
description: >-
  Own the GitHub issue lifecycle in five modes: file issues from a plan, start a workable issue in its own worktree, close one once its PR merges, sync PR↔issue links and dependents after merge, and triage the tracker for label and title gaps and for done, duplicate, or obsolete issues. Use when the user says "create issues from this plan", "file an issue", "start issue #42", "close #42", "sync my issues", "triage the backlog", "set the priority on #42", "#42 is grilled, mark it ready", "fix the titles on these issues", or "clean up my issues".
license: MIT
allowed-tools: Bash, Read, Edit, Write, Skill
metadata:
  internal: false
---

# issuekit

Own the GitHub issue lifecycle through the [`gh` CLI](https://cli.github.com), in five explicit **modes**:

- **`create`.** Turn a plan document or a plain description into well-formed issues.
- **`start`.** Take a `ready` or `stacked` issue into its own worktree and flip it `in-progress`.
- **`close`.** Once its PR has merged, close the issue, unblock what it was holding up, tear the worktree down, and delete the QA screenshots its plans left in `~/qakit/`.
- **`sync`.** Reconcile and repair the PR↔issue relationship *after* the fact (issues a merged PR should have closed, a missing link on an existing PR, a dependent still marked `blocked` by an issue that landed).
- **`triage`.** Report the health of the tracker, then apply the fixes you approve, including the `needs-planning → ready` promotion once a grill settled an issue and the close of issues already done, duplicated, or obsolete.

**`close` vs `sync`.** The split is by scope. `close` lands **one named issue** whose PR merged, and is the only mode that touches the filesystem (the worktree teardown and the QA screenshot folders). `sync` sweeps the **whole tracker** for drift and never touches a worktree. `close` reuses `sync`'s reconciliation rather than restating it.

## When this fires

The user wants to act on GitHub issues. Route to a mode from what they ask. **If no mode is clear, ask first.** Present the modes as options and let the user pick before doing anything, and don't guess between creating and mutating the tracker.

**Worktrees and branches are gitkit's.** `start` and `close` get the branch name, the path, create-or-adopt, and teardown from **gitkit**. issuekit hands gitkit an issue number and title, and gitkit hands back a branch and a path.

## Preflight (every mode)

- If `gh` is missing or unauthenticated, say so and point to `https://cli.github.com` / `gh auth login`. Don't work around it.
- **Invoking issuekit means the project uses GitHub Issues.** Never decline because the repo seems to track work elsewhere.
- **No shell or `gh` at all** (e.g. a browser-based agent)? You can't call `gh`. Instead do the reasoning from what the user provides and **print the exact `gh` commands** for them to run themselves: issue bodies as codeblocks, and `gh issue create …` / `gh issue close …` lines ready to paste.

**Safety stance, for the whole skill.** Creating, closing, relabeling issues and editing PR bodies are outward-facing mutations. **Preview every mutation and get an OK before it runs, so nothing changes on GitHub unprompted.** Never merge PRs.

**Label writes are exempt in `create`, `start`, `close`, and `sync`, for every caller.** Adding or removing a label on an issue or a PR runs straight through, with no preview and no prompt, whether a person is at the keyboard or an orchestrator drives the run. This covers both namespaces, [lifecycle](#lifecycle-labels-every-mode) and [priority](#priority-labels-every-mode). A label is cheap, visible, and reversible with one command. **State every label write in the preview that accompanies it, and report what the labels became in the hand-off.** The exemption skips the prompt, never the check that the label exists.

The exemption covers labels only; every other mutation keeps the preview. **`triage` is outside the exemption**, because each of its label writes is a judgment the report proposes, so it reports first and applies every fix, labels included, only on the user's approval.

**If the repo has its own issue conventions**, whether a template in `.github/ISSUE_TEMPLATE/`, a labeling or status scheme, or a title style visible in `gh issue list`, follow those over these defaults and say you did.

## Title convention (every issue this skill creates)

Issue titles follow the same shape as commitkit's commit subjects and the [Conventional Commits specification](https://www.conventionalcommits.org). **Format:**

```
type(scope): short imperative summary
```

Pick the `type` from what the issue delivers, not the files it touches. The set is commitkit's:

| type | when |
|------|------|
| `feat` | a new capability the user can see |
| `fix` | a bug fix |
| `hotfix` | a fix on a `hotfix-<slug>` branch |
| `docs` | documentation only |
| `refactor` | behavior-preserving code change |
| `perf` | a performance improvement |
| `test` | adding or fixing tests |
| `build` / `ci` | build system, deps, or pipeline |
| `style` | formatting/whitespace, no logic |
| `chore` | routine maintenance that fits nothing above |

Rules, applied to **every** title you generate:

- **`(scope)` is mandatory**, naming the module, package, directory, or feature area the work belongs to (`feat(auth): …`). For genuinely global work (repo-wide config, tooling, cross-cutting cleanup) fall back to `repo`: `chore(repo): …`.
- **Entirely lowercase.** Never capitalize any word in the title, including the first. Proper nouns and acronyms (`OIDC`, `SSO`, `CI`) are the only exceptions.
- **Imperative mood**, stating the *effect* ("add sso login"), not the activity ("changes to auth"). **No trailing period.**
- **Title the whole issue, not its first phase.** A multi-phase issue names the capability it delivers end to end (`feat(auth): add sso login`), and its phases live in the body.

**A hotfix needs no issue before the branch.** Somebody cuts a `hotfix-<slug>` branch and opens a `hotfix(scope):` pull request without waiting for the tracker, so no mode here gates a hotfix, and `start` is not on its path. When the user files one after the fact for the record, title it `hotfix(scope): …`, label it `in-review` when its PR is already open, and never label it `ready`, because `ready` promises work nobody has begun.

---

## Lifecycle labels (every mode)

issuekit tracks where an issue sits in the workflow with a small, **flat** set of status labels. It **uses** these labels and never creates them. Provisioning labels is the job of a companion skill, **repokit**. When a label this skill needs is absent from the repo, **stop and tell the user how to add it** (run `repokit`, or the exact `gh label create` line) rather than creating it yourself or skipping silently.

Exactly one **status** label is active at a time, moving left to right through the workflow, with the three side-exits applying whenever they fit:

| label | color | means | typically set by |
|-------|-------|-------|------------------|
| `triage` | `FBCA04` | filed, not yet assessed or broken down | a human or an issue template; issuekit never sets it on its own, and `triage` mode reads it |
| `needs-planning` | `F1C40F` | not yet specified enough to work; a human plan/grill session is still owed | issuekit create / afkkit gate |
| `ready` | `0E8A16` | specified and **independent**, safe to take into its own git worktree now | issuekit create |
| `blocked` | `D93F0B` | has an unmet prerequisite that has not started | issuekit create / sync |
| `stacked` | `006B75` | its prerequisite has an open PR, so it is workable now on a branch stacked on that one | prkit / issuekit sync |
| `in-progress` | `1D76DB` | actively being worked in a worktree | issuekit start |
| `in-review` | `5319E7` | a PR is open, awaiting review or merge | a PR-authoring skill / sync |
| `needs-info` | `D4C5F9` | stalled pending more detail before it can proceed | triage |
| `wontfix` | `FFFFFF` | will not be actioned | triage |
| `duplicate` | `CFD3D7` | superseded by another issue | triage |

A **closed** issue needs no `done` label, because the closed state is the signal.

- **`ready` vs `blocked`.** `ready` is independent work the user can take into its own worktree now; `gh issue list --label ready` is the set to fan out in parallel. `blocked` waits on a prerequisite and carries a recorded dependency naming it.
- **`blocked` vs `stacked`.** `blocked` waits on a prerequisite nobody has started. `stacked` has a prerequisite in an open PR, so it is worked now on a branch cut from the prerequisite's branch, and its PR targets that branch instead of trunk.
- **`needs-planning` vs `ready`.** `ready` means specified enough to work **unattended**, so an agent (or an orchestrator like afkkit) can take it to a PR with no human. `needs-planning` means a human plan/grill session is still owed. An issue earns `ready` only once a grill settled its decisions; see [the grill gate at creation](modes/create.md#4-label-lifecycle-state-and-priority-and-record-dependencies).

`stacked` is a stored label, so it can go stale and never gates anything on its own: [`start` re-checks the prerequisite's PR live](modes/start.md#1-guard-refuse-anything-not-ready-or-stacked) before it cuts a branch.

**Type lives in the title, not a label.** Issues already carry `feat(scope):` / `fix(scope):` per the [title convention](#title-convention-every-issue-this-skill-creates), so this map has no `type:` labels.

**When a needed label is missing**, check once with `gh label list`, then report the gap instead of mutating around it:

> Label `blocked` isn't in this repo. Provision the workflow labels with **repokit**, or add just this one:
> `gh label create blocked --color D93F0B --description "has an unmet prerequisite that has not started"`

Apply a label only once it exists (`gh issue edit <n> --add-label <label>`).

### Recording a dependency

**GitHub's native issue dependencies are the source of truth.** Write the edge with `gh issue edit`, and read it back as structured data rather than by parsing prose:

```sh
gh issue edit 44 --add-blocked-by 43
gh issue list --state open --json number,title,labels,blockedBy,blocking
```

Also write a `Blocked by #N` line in the body, so a person reading the issue sees what it waits on. **The line is prose, not the store.** When the two disagree, the native edge wins and the line gets repaired.

The flags need `gh` 2.94.0 or newer. **Below that, degrade rather than refuse:** write the body line only, and say once that the native edge was skipped and why.

### Promoting a dependent

**One transition rule sets a dependent's label, and every mode that moves or checks a dependent applies it.** When a prerequisite's state changes, recompute each dependent's label from **all** of its open prerequisites, never from the one that just moved. Issue C depends on A and B: A merging leaves C `blocked` while B has not started.

Find the dependents through the native edge, the store named in [Recording a dependency](#recording-a-dependency), and read each one's full prerequisite set the same way:

```sh
gh issue view 43 --json blocking -q '[.blocking[].number]'      # who waits on #43
gh issue view 44 --json blockedBy,labels                          # everything #44 waits on
```

Below `gh` 2.94.0, read the `Blocked by #N` body lines instead and say once that the native edge was unavailable. Then take the first row that matches:

| open prerequisites | new label |
|---|---|
| none | `ready` |
| every one has an open PR, and those PRs form one chain (each PR's base is the next one's head) | `stacked`, on the top PR of that chain |
| every one has an open PR, and the PRs do not form one chain | keep the current label, and report the incompatible parents |
| at least one has no open PR | `blocked` |

- **A prerequisite's change moves only `blocked` and `stacked` dependents.** A `needs-planning` dependent keeps its label, because the grill gate holds it, not the dependency. An `in-progress` or `in-review` dependent keeps its label, because its work has started.
- **A layer has one parent branch.** When the open PRs sit on separate branches, no single base satisfies them all. Name each candidate parent PR in the report and let the user decide; never pick one.
- **Every move is a replace.** Remove the current lifecycle label in the same call that adds the new one: `gh issue edit 44 --remove-label blocked --add-label ready`.
- **A PR query that fails leaves the dependent alone.** Report it as unknown and name the failed call; an error is not evidence that no PR exists.

### Linking a PR to an issue

**GitHub honors a closing keyword (`Closes #N`) only on a PR that targets the repository's default branch.** A stack layer above the bottom one carries an inert keyword, and its `closingIssuesReferences` stays empty, until GitHub retargets the PR to the default branch when the layer below merges.

So a `gh pr list --search` hit is not a link. Keep a PR only when its `closingIssuesReferences` names the issue, or, for a PR whose base is not the default branch, its body carries `Closes #<n>`.

---

## Priority labels (every mode)

The **second** label namespace, and the one that decides what gets picked up next. Like the lifecycle set, issuekit **uses** these labels and never creates them: **repokit** provisions them, and a missing one is [reported, not worked around](#lifecycle-labels-every-mode).

| label | color | means | typically set by |
|-------|-------|-------|------------------|
| `critical` | `B60205` | drop everything; preempts work already in progress | issuekit create / triage |
| `high` | `E99695` | do this before other workable issues | issuekit create / triage |
| `medium` | `FEF2C0` | normal priority, the default once assessed | issuekit create / triage |
| `low` | `C5DEF5` | worth doing eventually; never preempts anything | issuekit create / triage |

- **One lifecycle and one priority label, independent.** Never infer one from the other: a `critical` issue is not `ready` because it is `critical`.
- **No priority label means unassessed, not `medium`.** Never default an issue to `medium` silently; `triage` hunts for the gap. Every open issue carries a priority except the side-exits (`wontfix`, `duplicate`).
- **Every write replaces the sibling present.** GitHub has no mutual exclusion between labels, so read the issue's current labels and remove whichever sibling it actually carries in the same call that adds the new one, rather than blind-removing all three:

```sh
gh issue view 42 --json labels -q '[.labels[].name]'   # → ["ready","medium"]
gh issue edit 42 --add-label high --remove-label medium
```

---

## The modes

The mode bodies live in one file each under `modes/`. Route with [When this fires](#when-this-fires), read that one file, and follow it. Everything above this line applies to every mode and is not restated in the mode files.

_Write every hand-off in this skill in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

- Mode `create` → read [modes/create.md](modes/create.md), then follow it.
- Mode `start` → read [modes/start.md](modes/start.md), then follow it.
- Mode `close` → read [modes/close.md](modes/close.md), then follow it.
- Mode `sync` → read [modes/sync.md](modes/sync.md), then follow it.
- Mode `triage` → read [modes/triage.md](modes/triage.md), then follow it.
