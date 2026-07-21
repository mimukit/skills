---
name: issuekit
description: >-
  Own the GitHub issue lifecycle with three modes — create issues from a plan-*.md or a description, sync PR↔issue links after merge, and triage the tracker. Use when the user says "create issues from this plan", "file an issue", "sync my issues", "close the issue this PR fixed", "triage the backlog", "issuekit", or wants issues opened, reconciled, or reviewed with the gh CLI.
license: MIT
allowed-tools: Bash, Read, Edit
metadata:
  internal: false
---

# issuekit

Own the GitHub issue lifecycle through the [`gh` CLI](https://cli.github.com), in three explicit **modes**:

- **`create`** — turn a plan document or a plain description into well-formed issues, with parent→child links.
- **`sync`** — reconcile and repair the PR↔issue relationship *after* the fact (issues a merged PR should have closed, a missing link on an existing PR, an un-ticked parent checklist).
- **`triage`** — report the health of the tracker, then offer fixes you approve.

One skill, three jobs, because they're the same job at three points in a dev workflow: file the work, keep it in sync as PRs land, and keep the tracker honest.

## When this fires

The user wants to act on GitHub issues. Route to a mode from what they ask:

- **create** — "create issues from this plan", "open issues for `plan-auth.md`", "file an issue for X", "start fresh with an issue".
- **sync** — "sync my issues", "this PR merged but the issue is still open", "link this PR to #42", "tick the parent checklist".
- **triage** — "triage the backlog", "what's the state of my issues", "review open issues", "any stale issues".

**If no mode is clear, ask first.** Present the three modes as options and let the user pick before doing anything — don't guess between creating and mutating the tracker.

## Preflight (every mode)

Before any GitHub call, confirm the tooling is ready:

```sh
gh --version        # gh installed?
gh auth status      # authenticated?
gh repo view --json nameWithOwner -q .nameWithOwner   # inside a repo?
```

- If `gh` is missing or unauthenticated, say so and point to `https://cli.github.com` / `gh auth login` — don't work around it.
- **No shell or `gh` at all** (e.g. a browser-based agent)? You can't call `gh`. Instead do the reasoning from what the user provides and **print the exact `gh` commands** for them to run themselves — issue bodies as codeblocks, `gh issue create …` / `gh issue close …` lines ready to paste.

**Safety stance — the whole skill.** Creating, closing, relabeling issues and editing PR bodies are outward-facing mutations. **Preview every mutation and get an OK before it runs — nothing changes on GitHub unprompted.** Never merge PRs.

---

## Mode: `create`

Turn work into issues. Two inputs — a plan file (the main path) or a plain description (start fresh).

### 1. Find the input
- **Plan path:** a `plan-*.md`. Resolve it by precedence: an explicit path in the prompt → the newest `docs/plans/plan-*.md` → ask which plan.
- **Ad-hoc path:** a plain description with no plan. This is the "start fresh, just file it" case → one well-formed issue.

### 2. Decompose a plan into a proposed breakdown
Read the plan's structure — phases, milestones, tasks — and decide the shape:
- a **parent epic + N child issues** when the plan has distinct sub-tasks worth tracking separately, or
- a **flat list** (or single issue) when it doesn't.

Two principles govern the breakdown — apply them **before** you present anything:

- **Fewest issues by default.** Actively look for scopes where several related tasks can collapse into **one issue with a checklist** instead of separate issues. Merge aggressively; only split into its own issue/sub-issue when a task is genuinely independent — different lifecycle, owner, or PR. Default to the *smallest* number of issues and sub-issues that still tracks the work honestly. The user can always ask to split one further; starting consolidated and splitting on request beats starting fragmented.
- **Vertical slices.** Size each issue/sub-issue so it completes **one testable feature end to end** whenever possible — a slice a person could verify on its own — rather than a horizontal layer (e.g. "all the DB models", "all the endpoints") that isn't demonstrable until other issues land. Prefer "user can log in with SSO" over separate "add OIDC table" / "add OIDC route" / "add OIDC UI" issues; fold those layers into the one vertical slice as checklist items.

**Milestones are opt-in.** Do **not** create GitHub milestones by default — map a plan's phases onto issues and checklists instead. Only when the user **explicitly asks** for milestones (or points at a repo that already uses them) should you create one (`gh api repos/{owner}/{repo}/milestones`, then `gh issue create --milestone <title>`) and attach issues to it. Absent that ask, never introduce a milestone the user would then have to maintain.

Present the proposal as a **preview table** and stop for approval — do **not** create anything yet:

| # | Type | Title | Parent | Checklist |
|---|------|-------|--------|-----------|
| 1 | epic | `auth: add SSO login` | — | — |
| 2 | child | `auth: OIDC login end to end` | #1 | provider · session · token refresh · UI |
| 3 | child | `auth: SSO account linking` | #1 | link existing · unlink · conflict handling |

Each child is a vertical slice with its layers folded into a checklist, not one issue per layer. Let the user add, drop, retitle, reparent, or **split** any row before you proceed — offer splitting explicitly when a slice is large. This guard is the point — never spray a repo with auto-generated issues.

For an **ad-hoc** description, skip the table: draft one issue (title + body) and confirm it before creating.

### 3. Create the issues
**Guard against duplicates first.** create is the workflow's entry point and gets re-invoked — running it twice on one plan must not file a second set. Before creating, list existing issues and skip (or flag for the user) any whose title already matches:

```sh
gh issue list --state all --limit 200 --json number,title,state
```

Then write each issue with a clear title (imperative, matching the repo's issue/commit style) and a body that carries the relevant slice of the plan — context, acceptance criteria, and any decisions. Create parents before children so child bodies can reference them.

```sh
gh issue create --title "auth: add SSO login" --body-file <bodyfile>
```

Use a temp file for each body (multi-line markdown through `--body` is flaky) and clean it up after.

### 4. Link parents → children
Try GitHub's **native sub-issues** first, then fall back:

```sh
# Native (preferred): attach a child to its parent via the sub-issues API.
# sub_issue_id is the child's DATABASE id (an integer) — NOT the GraphQL node id
# that `gh issue view --json id` returns. Resolve it from the REST endpoint:
child_id=$(gh api repos/{owner}/{repo}/issues/{child_number} --jq .id)
# Attach it — use -F (typed integer), not -f (which would send a string and be rejected):
gh api --method POST repos/{owner}/{repo}/issues/{parent_number}/sub_issues \
  -F sub_issue_id="$child_id"
```

If that call fails — sub-issues disabled, older GitHub Enterprise, or insufficient permissions — **fall back** to a task-list checklist in the parent body and **tell the user which path was used**:

```markdown
### Sub-issues
- [ ] #43 wire OIDC provider
- [ ] #44 session + token refresh
```

### 5. Write the issue numbers back into the plan
Once issues exist, annotate the source `plan-*.md` so it stays the source of truth — add the ref next to each task it maps to:

```markdown
### Phase 2 — auth (#41)
- OIDC provider (#43)
- session + token refresh (#44)
```

Use `Edit` for this. For an ad-hoc issue with no plan file, skip this step.

### 6. Report
Print a table of what you created — number, title, parent, URL — and note whether links used native sub-issues or the task-list fallback, and that the plan was annotated.

---

## Mode: `sync`

Reconcile and repair the PR↔issue relationship. **Sync deliberately does not write the forward `Closes #N` link onto a fresh PR** — that belongs to the PR-authoring step (a prkit-style skill) at open time. Sync only earns its place where the automatic chain *broke*:

| Who | Owns |
|-----|------|
| PR-authoring skill | write `Closes #N` into a **new** PR at open time (forward, happy path) |
| **issuekit sync** | reconcile drift after merge, repair a missing link on an **existing** PR, tick parent checklists, labels only if the repo uses them |

### 1. Reconcile — merged PR whose issue never closed
Find PRs merged recently whose linked issue is still open because the `Closes #` keyword was missing:

```sh
gh pr list --state merged --limit 20 --json number,title,body,closingIssuesReferences
gh issue list --state open --json number,title
```

For each merged PR that *should* have closed an issue (evident from the branch, title, plan, or the user telling you), **preview it and confirm before closing**:

> PR #10 (`auth: add SSO login`) merged, but issue #42 is still open → close #42 with a comment linking the PR?

On approval:

```sh
gh issue close 42 --comment "Closed by #10 (merged)."
```

Never auto-close — always show the pairing and wait for the OK. **If which issue a PR should have closed is ambiguous, ask rather than guess** — closing the wrong issue is worse than leaving one open.

### 2. Repair — missing link on an existing open PR
If an **open** PR should reference an issue but doesn't, add `Closes #N` to its body (editing the existing PR, not opening a new one):

```sh
gh pr edit <pr> --body-file <updated-body>
```

### 3. Checklist — tick the parent when a child closes
The task-list fallback (`- [ ] #child`) does **not** auto-tick when the child closes; native sub-issues do. When a child issue is closed, update the parent body to check its box:

```sh
gh issue view <parent> --json body -q .body   # read
gh issue edit <parent> --body-file <updated>  # write back with - [x] #child
```

### 4. Labels — only if a scheme already exists
If — and only if — the repo already uses status labels (`in-progress`, `in-review`, `done`, or similar, discoverable via `gh label list`), move issues through them as PRs advance. If there's no such scheme, **skip silently** — don't invent one.

### 5. Report
Summarize what changed: issues closed, PR bodies repaired, checklists ticked, labels moved — each an action the user approved.

---

## Mode: `triage`

Report first, act on approval. Never mutate the tracker just to "tidy up."

### 1. Read the tracker
Fetch `--state all` (not just open) — detecting a **closed** parent with open children, or the inverse, needs the closed issues too. Filter to open for the drift that only concerns open work.

```sh
gh issue list --state all --limit 200 --json number,title,state,labels,assignees,updatedAt,createdAt
```

Parent→child hierarchy has two representations: a task-list (`- [ ] #child`) lives in the parent's body, but **native sub-issue links live in the API, not the body** — enumerate them with `gh api repos/{owner}/{repo}/issues/{n}/sub_issues` rather than assuming the body tells the whole story.

### 2. Flag drift
Produce a **status report** — a table — surfacing:
- **Stale** — no update in a long while (e.g. 30–60 days; scale to the repo's pace).
- **Orphaned** — no labels, no assignee, no parent.
- **Closed-parent / open-children** (and its inverse) — broken hierarchy.
- **Missing labels** — relative to the repo's own scheme, if it has one.
- **Status cross-checks** — issues whose linked PR merged but that are still open (hand off to `sync` for the actual close).

### 3. Offer fixes
For each flagged item, propose a concrete fix — relabel, reprioritize, close as stale, post a decision comment — and apply **only what the user approves**:

```sh
gh issue edit <n> --add-label <label>
gh issue comment <n> --body-file <decision>
gh issue close <n> --comment "Closing as stale; reopen if still relevant."
```

### 4. Report
Recap what the report found and what was changed vs. left alone.

---

## Shared action: comment a plan or decision

Across `create` and `triage` you may post a plan excerpt or a decision onto an issue as an audit trail. It's a shared action, not a mode:

```sh
gh issue comment <n> --body-file <file>
```

Use a temp file for multi-line markdown and remove it after.

## Notes

- **Never** merge PRs, and never mutate GitHub state without showing the change and getting an OK first.
- If the repo has its own issue conventions — a template in `.github/ISSUE_TEMPLATE/`, a labeling scheme, a title style visible in `gh issue list` — follow those over these defaults and say you did.
- Prefer `--body-file` over `--body` for anything multi-line; clean up temp files afterward.
- Keep issues proportional to the work: a one-line fix is one issue, not an epic with three children. Scale the breakdown to the plan's real surface area.
