# repokit

Set up a GitHub repo's metadata through the `gh` CLI — an inferred About description and topics, and the issue lifecycle and priority labels.

**Reach for it when** a repo's About panel is empty or its label vocabulary is missing.

| | |
|---|---|
| Modes | [`about`](#about) · [`labels`](#labels) |
| Tools | `Bash`, `Read` |
| Writes | GitHub repo metadata — description, topics, labels |
| Triggering | **explicit only** — model invocation is disabled |
| Visibility | public |

## What it does

Two jobs, one skill, because both answer "make this repo's GitHub metadata right" — the outward-facing blurb people read, and the label vocabulary the issue workflow runs on.

**If no mode is clear, it asks first**, presenting both before touching anything. A vague "set up this repo" gets an offer to run `about` then `labels`.

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

### `labels`

Provisions the issue-workflow labels so [`issuekit`](./issuekit.md) — and any workflow reading them — has the vocabulary it expects. repokit *creates and reconciles* these; issuekit only *uses* them.

This mode **stands alone**. The labels are useful for any issue workflow, so it never checks whether issuekit is installed first.

**There are two sets, and they're two independent namespaces.** Lifecycle answers *can this be worked?*; priority answers *should this be worked next?* An issue carries at most one from each, and neither implies the other — `ready` + `low` is coherent (workable, not urgent), and so is `blocked` + `critical` (urgent, which is exactly why its blocker matters). Collapsing them into one ordered set is the mistake this split exists to prevent: it would force a repo to choose between saying *where* work is and saying *how much it matters*.

**Lifecycle:**

| name | color | description |
|------|-------|-------------|
| `triage` | `FBCA04` | filed, not yet assessed or broken down |
| `needs-planning` | `F1C40F` | needs a human plan/grill session before it is workable |
| `ready` | `0E8A16` | specified and independent — safe to take into its own worktree now |
| `blocked` | `D93F0B` | has an unmet prerequisite (see 'Blocked by #N' in the body) |
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

**It looks for an existing scheme first — in both namespaces, independently.** A repo already running `status: blocked` or `S-ready`, or `P0`/`P1` or `priority: high`, gets surfaced rather than silently given a parallel set. The namespaces are asked about separately because the common case is a mature lifecycle scheme and no priority scheme at all — one question covering both forces a wrong answer to half of it.

**Priority names collide harder, so it checks meaning and not just spelling.** `ready` and `in-review` are workflow words that mostly mean this one thing. `critical` and `high` are generic English, and a repo may already use them for bug **severity**, effort size, or risk. Those are genuinely different axes — a critical crash nobody hits is `low` priority — so a name match isn't a meaning match, and the skill reads the existing label's description before assuming it's the same thing.

Otherwise each label sorts into **missing** (create), **drifted** (offer to update, since that rewrites the label), or **matches** (leave alone). Labels *outside* the canonical sets — GitHub's `bug`/`enhancement` defaults, or the repo's own — are **never touched**.

**repokit provisions the vocabulary; it never applies it.** No mode here puts a label on an issue. Deciding #42 is `high` is a judgment about the work, which belongs to issuekit; repokit only guarantees the word exists to say it with. That line is what makes this mode safe to re-run against a live tracker.

## The shared contract

The label maps are duplicated in [`issuekit`](./issuekit.md) on purpose: each skill must stand alone once installed, so neither can point at a shared source. repokit's descriptions are canonical; issuekit mirrors the same names and colors in execution-oriented wording.

Nothing else keeps the copies aligned, so this repo's `make lint` diffs them on every full run and errors on drift. One diff covers both namespaces — the rows share a format, so the check picks up all thirteen without caring which table they sit in.

**Labels can't enforce one-per-namespace, so the writer has to.** GitHub will happily let an issue carry `critical` and `low` at once, and nothing repokit provisions can prevent it. The mutual exclusion is enforced at write time by whoever applies the label, which is why that rule lives in issuekit rather than in this map.

## Hands off to

[`issuekit`](./issuekit.md). The labels are a vocabulary, not an outcome — what they unblock is the issue workflow, so the move is to start using it: `create` to file work from a plan, or `triage` to classify and rank issues that sat unlabeled while the vocabulary was missing. On a repo that already had open issues when priority was provisioned, `triage` is the stronger of the two — every one of those issues is now formally unassessed, and nothing downstream can rank them until somebody says what matters.

If only one mode has run, the other is the smaller follow-up.

## Install

```sh
npx skills add mimukit/skills -s repokit
```

Source: [`skills/repokit/SKILL.md`](../../../skills/repokit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`e14d201` on 2026-08-19._
