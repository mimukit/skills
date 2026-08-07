# repokit

Set up a GitHub repo's metadata through the `gh` CLI — an inferred About description and topics, and the issue lifecycle labels.

**Reach for it when** a repo's About panel is empty or its label vocabulary is missing.

| | |
|---|---|
| Modes | [`about`](#about) · [`labels`](#labels) |
| Tools | `Bash`, `Read` |
| Writes | GitHub repo metadata — description, topics, labels |
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

Provisions the issue-workflow lifecycle labels so [`issuekit`](./issuekit.md) — and any workflow reading them — has the vocabulary it expects. repokit *creates and reconciles* these; issuekit only *uses* them.

This mode **stands alone**. The labels are useful for any issue workflow, so it never checks whether issuekit is installed first.

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

**It looks for an existing scheme first.** A repo already running `status: blocked`, `S-ready`, or a `needs-*` family gets surfaced rather than silently given a parallel set — two ways to say "blocked" is worse than none. You choose: map onto theirs, or add the canonical set alongside.

Otherwise each label sorts into **missing** (create), **drifted** (offer to update, since that rewrites the label), or **matches** (leave alone). Labels *outside* the canonical set — GitHub's `bug`/`enhancement` defaults, or the repo's own — are **never touched**.

## The shared contract

The label map is duplicated in [`issuekit`](./issuekit.md) on purpose: each skill must stand alone once installed, so neither can point at a shared source. repokit's descriptions are canonical; issuekit mirrors the same names and colors in execution-oriented wording.

Nothing else keeps the copies aligned, so this repo's `make lint` diffs them on every full run and errors on drift.

## Hands off to

[`issuekit`](./issuekit.md). The labels are a vocabulary, not an outcome — what they unblock is the issue workflow, so the move is to start using it: `create` to file work from a plan, or `triage` to classify issues that sat unlabeled while the vocabulary was missing.

If only one mode has run, the other is the smaller follow-up.

## Install

```sh
npx skills add mimukit/skills -s repokit
```

Source: [`skills/repokit/SKILL.md`](../../../skills/repokit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`fd96414` on 2026-08-07._
