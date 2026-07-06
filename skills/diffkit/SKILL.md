---
name: diffkit
description: Compare one of your own skills against the upstream "base" skill it was inspired by, to surface what you could adopt or update. Use when the user runs "/diffkit <name>", asks to check a skill against its upstream/baseline, or wants to see what changed upstream since they last reviewed a skill. Reads baselines.json, fetches the upstream SKILL.md, does a semantic gap analysis plus a change-feed diff, then optionally drafts the accepted improvements into the local skill.
license: MIT
allowed-tools: Read, Edit, Write, Bash, WebFetch
---

# diffkit

Maintenance skill for this collection. Every skill here is authored from scratch — never forked — but some are "my version of" a popular upstream skill. `baselines.json` records that upstream link purely as a **reference for improvement**. This skill turns that reference into two concrete comparisons and, optionally, edits.

## Invocation

`/diffkit <skill-name>` — e.g. `/diffkit commitkit`.

If no name is given, list the skills that have a `baselines.json` entry and ask which one.

## Inputs & locations

- Repo root is the directory containing `baselines.json` (this file lives at `skills/diffkit/SKILL.md` under it).
- Your version:     `skills/<name>/SKILL.md`
- Provenance:       `baselines.json` → `<name>.sources[]` (may be more than one source)
- Snapshot cache:   `.baselines/<name>__<i>.md` (gitignored) — the upstream file as it looked at your last review, for source index `i`.

Each source has: `repo`, `path`, `branch`, `last_reviewed_sha`, `last_reviewed_at`.

The mechanical half — fetching upstream (with a `master` fallback), the change-feed diff, and stamping the review watermark — lives in `scripts/baseline.sh`, surfaced as `make diff` and `make save`. Prefer those over hand-rolling `curl`/`diff`: they are the single source of truth and use the very snapshot paths this skill reads. Fall back to a manual fetch only if the script is unavailable — the raw URL is `https://raw.githubusercontent.com/<repo>/<branch>/<path>`.

## Procedure

The mechanical steps (2, 4, 7) run once for **all** sources via `baseline.sh`, which loops them for you. The judgement steps (3, 5) you do per source, since your one local `SKILL.md` is compared against each upstream in turn.

### 1. Load
- Read `baselines.json`; find `<name>`. If absent, tell the user this skill has no baseline (it's an original) and stop.
- Read your `skills/<name>/SKILL.md`.

### 2. Fetch upstream + change feed
- Run `make diff name=<name>` (or `scripts/baseline.sh diff <name>` from any directory). For every source it fetches current upstream, falls back to `master` on a 404, and line-diffs against the snapshot — printing either the diff, "up to date", or "no prior snapshot — first review". This covers both the fetch and step 4's change feed in one call, and writes nothing (pure look).
- Read the upstream text it fetched so you have it in hand for the semantic gap analysis below. (Commit-SHA capture is not needed here — `make save` records it when you mark the skill reviewed.)

### 3. Gap analysis (mine vs. upstream — semantic)
Your version is rewritten from scratch, so a raw text diff is noise here. Instead, read both and reason about **capabilities**, not wording:
- Sections / steps / options the upstream covers that yours doesn't.
- Edge cases, guardrails, or examples upstream handles that yours misses.
- Things yours does *better* or deliberately differently (note these — they are not gaps).
Produce a short list of **concrete, adoptable suggestions**, each phrased as an action ("add a step that …", "handle the case where …").

### 4. Change feed (upstream-now vs. upstream-at-last-review — line diff)
- Interpret the diff already printed in step 2: summarize what upstream *changed* since your last review (a precise, cheap signal on top of the semantic gap analysis).
- If step 2 reported "no prior snapshot — first review", there's no watermark yet — treat all of upstream as new context for the gap analysis.

### 5. Report (inline)
Print a compact report:
- **Gaps / suggestions** (from step 3), numbered.
- **What changed upstream** since last review (from step 4), or "first review".
- **Where you differ on purpose** (so you don't accidentally "fix" a deliberate choice).

### 6. Apply (optional)
Ask which suggestions to adopt. For each accepted one, draft the edit into `skills/<name>/SKILL.md` via Edit and show the diff for review. Never apply silently.

### 7. Mark as reviewed (explicit — never automatic)
After the report/edits, ask: **"Mark `<name>` as reviewed?"**
- Only if the user says yes, run `make save name=<name>` (or `scripts/baseline.sh save <name>`). For every source it refreshes the snapshot **and** stamps `last_reviewed_sha` (best-effort from the GitHub API, else `null`) and `last_reviewed_at` (today) in `baselines.json`. No hand-editing of the snapshot or the JSON.
- If the user only looked and isn't caught up, run nothing here — `diff` wrote nothing, so the next run still surfaces the same pending changes. Looking and acknowledging are decoupled: `diff` looks, `save` acknowledges.

## Notes
- Multiple sources: `baseline.sh` handles all of them per call; do the semantic gap analysis (step 3) and report (step 5) per source, grouped by source.
- Never edit the snapshot cache or the `last_reviewed_*` fields by hand; `make save` owns the watermark.
- This skill is a "meta" skill — it maintains the collection and is not meant for the public directory listing.
