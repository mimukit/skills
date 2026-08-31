# repokit

Set up a GitHub repo through the `gh` CLI — an inferred About description and topics, the workflow labels (issue lifecycle, priority, and an `ai-review` trigger for AI PR review tools), and a full new-repo setup that applies the house settings and scaffolds the baseline files.

**Reach for it when** a repo's About panel is empty, its label vocabulary is missing, or a freshly created repo needs bringing up to convention in one pass.

| | |
|---|---|
| Modes | [`about`](#about) · [`labels`](#labels) · [`setup`](#setup) |
| Tools | `Bash`, `Read`, `Write` |
| Writes | GitHub repo metadata and settings — description, topics, labels, merge config — plus scaffold files on disk (unstaged) |
| Triggering | **explicit only** — model invocation is disabled |
| Visibility | public |

## What it does

Three jobs, one skill, because all three answer "make this repo's GitHub configuration right" — the outward-facing blurb people read, the label vocabulary the issue workflow runs on, and the settings-and-files baseline a new repo starts from.

**If no mode is clear, it asks first**, presenting the three modes before touching anything. A vague "set up this repo" routes to `setup`, which subsumes the old "offer `about` then `labels`" answer.

## Safety stance

A repo's description, topics, and labels are outward-facing state. **Every mutation is previewed and gets an OK before it runs — nothing changes on GitHub unprompted.** Every command is echoed, so the change is auditable and replayable.

It's **re-run safe**. Every mode reconciles against what's already there, so a second run on an unchanged repo proposes nothing and mutates nothing.

Two guardrail flags get checked before any mutation:

- **Archived** — GitHub rejects metadata edits outright, so it stops and tells you to unarchive first.
- **Fork or template** — metadata is often inherited or throwaway, so it confirms you mean *this* repo.

## Modes

### `about`

Infers a description and topics from the repo's own contents, reconciles against what's set, and applies on approval.

It starts from what's **already there**, so curated metadata gets reconciled rather than clobbered. Signal comes from the cheap, high-signal sources first — the README and the project manifest — and only digs into the file tree and language mix when those are thin.

- **Description** — one line, plain, specific about what the repo *is or does*, no trailing period. Say what it is, not how great it is.
- **Topics** — focused and high-signal, not keyword-stuffed. GitHub's format is enforced so they'll actually be accepted: lowercase, digits and single hyphens, starting with a letter or number, ≤50 chars each, ≤20 total. Widely-used slugs are preferred so the repo surfaces under real topic pages.

The proposal comes as a side-by-side table, and **each field is decided independently** — accept, edit, or keep current:

| Field | Current | Proposed |
|-------|---------|----------|
| Description | `old blurb` | `new blurb` |
| Topics | `a, b` | `a, c, d` (+`c`,`d`; −`b`) |
| Homepage | `none` | `https://example.com` |

**Homepage is optional and only ever proposed from a URL the repo already names** — a deployed site, a docs site, a package page. There is no inference to fall back on, so a repo that names none keeps an empty homepage. The repo's own GitHub URL is not a candidate; the About panel shows it already.

### `labels`

Provisions the workflow labels so [`issuekit`](./issuekit.md) — and any workflow reading them — has the vocabulary it expects. repokit *creates and reconciles* these; issuekit only *uses* them.

This mode **stands alone**. The labels are useful for any issue workflow, so it never checks whether issuekit is installed first.

**There are three sets, and they're three independent namespaces.** Lifecycle answers *can this be worked?*; priority answers *should this be worked next?*; automation answers *what should a machine do with this?* An issue carries at most one lifecycle and one priority label, and neither implies the other — `ready` + `low` is coherent (workable, not urgent), and so is `blocked` + `critical` (urgent, which is exactly why its blocker matters). Collapsing them into one ordered set is the mistake this split exists to prevent: it would force a repo to choose between saying *where* work is and saying *how much it matters*.

**Lifecycle:**

| name | color | description |
|------|-------|-------------|
| `triage` | `FBCA04` | filed, not yet assessed or broken down |
| `needs-planning` | `F1C40F` | needs a human plan/grill session before it is workable |
| `ready` | `0E8A16` | specified and independent — safe to take into its own worktree now |
| `blocked` | `D93F0B` | has an unmet prerequisite that hasn't started |
| `stacked` | `006B75` | its prerequisite is in flight with an open PR; workable now on a branch stacked on it |
| `in-progress` | `1D76DB` | actively being worked in a worktree |
| `in-review` | `5319E7` | a PR is open, awaiting review or merge |
| `needs-info` | `D4C5F9` | stalled pending more detail before it can proceed |
| `wontfix` | `FFFFFF` | will not be actioned |
| `duplicate` | `CFD3D7` | superseded by another issue |

**Priority** — four levels on a hot-to-cold color ramp, so the family reads as one scale rather than four unrelated labels:

| name | color | description |
|------|-------|-------------|
| `critical` | `B60205` | drop everything — preempts work already in progress |
| `high` | `E99695` | do this before other workable issues |
| `medium` | `FEF2C0` | normal priority — the default once assessed |
| `low` | `C5DEF5` | worth doing eventually — never preempts anything |

**Why labels and not a GitHub Projects field.** Projects v2 ships a real Priority field that sorts and groups natively, and it was the obvious candidate. It needs an OAuth scope `gh auth login` doesn't grant by default, and asking for `projectItems` without it fails the *entire* JSON query rather than just that field — so every downstream skill would break with an unhelpful GraphQL error on a fresh install. Worse, priority would only exist for issues somebody added to a board, and each skill would need configuring for *which* board. Labels are repo-local, need no extra scope, work on user-owned repos, and every consumer already fetches the `labels` array for lifecycle — priority rides along at no extra API call. Milestones mean release scope and issue types are org-only, so neither was a candidate.

**No priority label means *unassessed*, not `medium`.** The absence is a real state, and it's what lets `issuekit triage` find the issues nobody has ranked. A default would erase exactly the distinction the scale exists to draw — between an issue somebody thought about and called normal, and one nobody has looked at.

**Four levels is the ceiling.** A priority scale is only useful if someone can order a backlog in their head; every level past the fourth is one more place the same issue could plausibly sit, which turns the scale into a coin flip.

**Automation** — one label, for the one automation this collection assumes:

| name | color | description |
|------|-------|-------------|
| `ai-review` | `34495E` | run the repo's AI review tooling on this PR |

**Why it's a third namespace and not a lifecycle label.** Lifecycle and priority *describe* an issue — a human reads them, and one of each is true at a time. `ai-review` *acts*: somebody puts it on a pull request to start a tool, and takes it off once the tool has run. It is PR-scoped, additive, and nothing downstream reads it as state, so filing it beside `ready` and `blocked` would break the one-label-at-a-time rule that makes those readable. Its graphite color sits outside both ramps for the same reason — it must not look like a step on either scale.

**The label is a switch with nothing behind it until something listens.** Creating `ai-review` reviews nothing by itself; a workflow in `.github/workflows/` or an installed review app has to subscribe to the label event. So the skill greps the workflow files, reports what it finds, and crowns *wiring the listener* as the next move when nothing does. It never writes the workflow — provisioning the vocabulary is the whole job.

**And the listener owns the name.** A workflow fires on the exact string in its condition, so a repo already listening for `claude-review` or `coderabbit` keeps that name and gets no `ai-review`. A second trigger label nothing reads is worse than none, because it looks like it works.

**It looks for an existing scheme first — in every namespace, independently.** A repo already running `status: blocked` or `S-ready`, or `P0`/`P1` or `priority: high`, gets surfaced rather than silently given a parallel set. The namespaces are asked about separately because the common case is a mature lifecycle scheme and no priority scheme at all — one question covering both forces a wrong answer to half of it.

**Priority names collide harder, so it checks meaning and not just spelling.** `ready` and `in-review` are workflow words that mostly mean this one thing. `critical` and `high` are generic English, and a repo may already use them for bug **severity**, effort size, or risk. Those are genuinely different axes — a critical crash nobody hits is `low` priority — so a name match isn't a meaning match, and the skill reads the existing label's description before assuming it's the same thing.

Otherwise each label sorts into **missing** (create), **drifted** (offer to update, since that rewrites the label), or **matches** (leave alone). Labels *outside* the canonical sets — GitHub's `bug`/`enhancement` defaults, or the repo's own — are **never touched**.

**repokit provisions the vocabulary; it never applies it.** No mode here puts a label on an issue or a PR. Deciding #42 is `high` is a judgment about the work, which belongs to issuekit; repokit only guarantees the word exists to say it with. That line is what makes this mode safe to re-run against a live tracker.

### `setup`

Brings an already-created repo up to convention in one span: repo settings, baseline files, then `about` and `labels` delegated on top with one closing hand-off for the whole run. It **configures, never creates** — `gh repo create` stays with you, and the root preflight stops when there's no GitHub remote. It also never commits: scaffold files land unstaged for [`commitkit`](./commitkit.md) to group.

**Why merge-commit-only.** [`mergekit`](./mergekit.md) closes every PR with `gh pr merge --merge`, and a squash breaks the branch ancestry that [`gitkit`](./gitkit.md)'s `clean` needs three separate detections to see through. So `setup` proposes enabling merge commits and disabling squash and rebase — one merge method, one shape of history — plus delete-branch-on-merge so the remote branch dies with its PR. The wiki toggle is proposed off (wikikit `publish` is opt-in). The settings come as their own question, one option per row of the map — matching rows included, marked as such — so you enable or disable each setting individually instead of approving the map whole — a repo that keeps squash merges on purpose should not have to fight the scaffold question to say so. The default branch is report-only: renaming one breaks open PRs and clones, so `setup` states a mismatch and changes nothing.

**The rest of the map serves the skills downstream of it.** Update-branch puts the button mergekit's sync step reaches for, and auto-merge is what lets [`afkkit`](./afkkit.md) land a PR after checks pass without a human at the keyboard. Both secret-scanning rows are free on a public repo and need Advanced Security on a private one, so on a private repo `setup` says the plan may reject them and offers them anyway — a refused flag costs one error message, and a leaked credential costs a rotation. Neither `gh repo view` field set covers update-branch or secret scanning, so `setup` reads those two from the REST API.

**Why branch protection is out.** Rulesets need admin rights and, on private repos, a paid plan — a mode that fails on half its target repos isn't a convention, it's a coin flip.

**The scaffold set** is grounded in what the mimukit repos actually share: `LICENSE`, `README.md`, `.gitignore` (stack-matched, skipped when the stack is unknown), `AGENTS.md`, and a `.claude/CLAUDE.md` pointer to it. An existing file is never overwritten. A repo with history runs the identical flow — the diffs just shrink.

**The license is a question, never an assumption, in both visibilities.** A public repo gets MIT recommended (text fetched from the GitHub licenses API, never written from memory); a private repo gets a proprietary all-rights-reserved file recommended, because the point is to say the code is proprietary where a reader will find it — with an open license offered as runner-up since private repos often go public later. "No license" stays available, with one line on what it means. The holder name comes from `gh api user`, falling back to `git config user.name`, always visible in the preview.

## The shared contract

The label maps are duplicated in [`issuekit`](./issuekit.md) on purpose: each skill must stand alone once installed, so neither can point at a shared source. repokit's descriptions are canonical; issuekit mirrors the same names and colors in execution-oriented wording.

Nothing else keeps the copies aligned, so this repo's `make lint` diffs them on every full run and errors on drift. One diff covers both namespaces — the rows share a format, so the check picks up every row without caring which table it sits in. The automation set is the exception, listed in lint's `UNSHARED_LABELS`: `ai-review` acts on a pull request, issuekit runs the tracker, so there is no second copy to drift from.

**Labels can't enforce one-per-namespace, so the writer has to.** GitHub will happily let an issue carry `critical` and `low` at once, and nothing repokit provisions can prevent it. The mutual exclusion is enforced at write time by whoever applies the label, which is why that rule lives in issuekit rather than in this map.

## Hands off to

[`issuekit`](./issuekit.md). The labels are a vocabulary, not an outcome — what they unblock is the issue workflow, so the move is to start using it: `create` to file work from a plan, or `triage` to classify and rank issues that sat unlabeled while the vocabulary was missing. On a repo that already had open issues when priority was provisioned, `triage` is the stronger of the two — every one of those issues is now formally unassessed, and nothing downstream can rank them until somebody says what matters.

The exception is a fresh `ai-review` label with no listener. Then the next move is a workflow in `.github/workflows/` that subscribes to it, because until one exists the label is inert and nobody downstream can tell.

If only one metadata mode has run, the other is the smaller follow-up. After a `setup` run the first move is [`commitkit`](./commitkit.md), because the scaffold files are sitting unstaged.

## Install

```sh
npx skills add mimukit/skills -s repokit
```

Source: [`skills/repokit/SKILL.md`](../../../skills/repokit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`6d09df4` on 2026-08-31._
