---
name: reviewkit
description: >-
  Review AI-agent-implemented code specifically, in four ordered passes (convention-fit, agent-slop signatures, requirement-completeness, correctness) against the working tree or the branch diff, findings ranked by severity and backed by quoted evidence. Use when the user says "review this code", "review my changes", or "check the agent's work" before commit or PR.
license: MIT
allowed-tools: Read, Bash, Grep, Glob, Write, Task, Agent, Skill
metadata:
  internal: false
---

# reviewkit

Review agent-written code in four passes; report findings, and never edit source, commit, or push. A correctness-only request runs only the [Correctness](#5-pass-4-correctness) pass.

## Review with fresh eyes

**Delegate the passes to a fresh subagent** with the diff, the stated intent, and the passes below; review its findings, then present them. When no subagent tool is available, run the passes yourself and label the report a **self-review**. Either way, judge the code on disk, not the code you remember intending to write.

## Procedure

### 1. Pick the review target

Ground the review in an actual diff. Detect the target from git state, then state your pick and let the user override:

- **Uncommitted changes present** (`git status --porcelain` is non-empty) → review the working tree: `git diff HEAD` (include staged with `git diff --staged`). This is the default after a fresh coding session. **`git diff` does not show untracked files**, so a brand-new file an agent never staged is invisible to it. List them with `git status --porcelain` (the `??` entries) or `git ls-files --others --exclude-standard`, and `Read` each one in full as part of the change: **every untracked source file, no exceptions**. The only untracked files you may skip are ones nobody wrote: lockfiles, build output, vendored dependencies, compiled assets, snapshots. Note them as generated, spot-check that they're actually generated rather than hand-edited, and move on.
- **Clean tree, branch ahead of its base** → review the branch diff. **Get the base branch from gitkit**, which owns that resolution; a wrong base yields an empty diff or half the repo's history, and both look like a real review target. Without gitkit, take the remote default branch from `git symbolic-ref --short refs/remotes/origin/HEAD` (strip the `origin/` prefix), else the first of `main` or `master` that `git rev-parse --verify` resolves, and say in the target line which fallback you used. Then run `git diff <base>...HEAD` and `git log <base>..HEAD --oneline` for intent.
- **If the invocation names a target** ("review the branch", "review my staged changes") → honor it directly, skip detection.

Say which target you chose and why in one line, then proceed. If neither applies (clean tree, no branch ahead), ask what to review rather than guessing.

**Validate before reviewing.** Confirm the target resolves (`git rev-parse <ref>` for a named base) and the change is actually non-empty: the tracked diff plus the untracked files you listed. A change made only of new untracked files has an empty `git diff` and is still a full review target. If the ref doesn't resolve, or both the diff and the untracked list are empty, stop and say so.

Read the diff in full before judging anything, **once**. The four passes below are four questions asked of one reading, not four readings; don't re-run `git diff` at the top of each pass. If a pass needs a detail you didn't retain, pull that hunk (`git diff HEAD -- <path>`), not the whole diff again. The same applies to the neighboring code you compare against in [Convention-fit](#2-pass-1-convention-fit): read the sibling that establishes the pattern, not every file in the directory.

This step is done when the target line is stated, the ref resolves, every changed file and every non-generated untracked file has been read, and the stated intent is written down (or recorded as absent).

Note the change's *stated intent*, from the commit messages, the branch name, the plan or issue it references, or the user's own words. Capture it concretely: it's the spec both [Requirement-completeness](#4-pass-3-requirement-completeness) and the scope-creep check in [Agent-slop signatures](#3-pass-2-agent-slop-signatures) measure against.

**Ground rules for every pass:**

- **Skip what tooling already enforces.** Don't report formatting, import order, or lint rules a formatter/linter/CI catches on its own.
- **Every finding needs evidence.** Quote the offending hunk and name what it violates: a specific line of a repo convention doc, the stated intent, a real API signature, or the concrete failing input. A finding you can't back with a quote is a guess; drop it.
- **Hold each finding to a confidence bar before it ships.** Ask what would have to be true for this to be wrong, and report it only when the answer is *confirmed by the code, a reproduction, or a test run*, or *strongly supported with no credible innocent explanation*. "Probably a problem, but I couldn't check the runtime behavior" clears the bar only if you say which part you couldn't check. Anything weaker is not a finding. It is an **unverified area**, and it belongs in the coverage note in [Report the findings](#6-report-the-findings) rather than in the findings list.
- **Track what you could not judge.** As you go, keep a running list of areas the review didn't cover: a concurrency path you can't reason about statically, a security boundary whose auth model lives outside the diff, generated files you spot-checked rather than read, a dependency whose real API you couldn't verify offline. Silence reads as "clean," so name each unexamined area.

### 2. Pass 1: Convention-fit

Does the change look like the rest of *this* repository wrote it? For each changed file, compare against its neighbors:

- **Naming & structure.** Do new names, file layout, and module boundaries match sibling files?
- **Established patterns.** Does the repo already have a way to do this (an HTTP client, an error type, a logging helper, a test factory) that the change reinvents instead of reusing? Grep for prior art before accepting a new abstraction.
- **Idiom & style.** Error handling, async style, imports, formatting conventions the linter doesn't catch. Match what's there.
- **Dependencies.** Did it add a library for something the repo already solves, or that the project's conventions forbid? Check the manifest and existing imports.
- **Stated conventions.** If the repo documents its conventions (a `CLAUDE.md`, an agent-guide file, a `CONTRIBUTING.md`, or a style guide), read it and hold the change to it. A documented repo rule always overrides a general "best practice."

The pass is done when every changed file has been compared against at least one sibling or documented convention, and against each check above.

### 3. Pass 2: Agent-slop signatures

Hunt the tells of machine-generated code:

- **Over-engineering.** Abstraction for a single caller, config knobs nothing sets, layers of indirection a direct call would replace, "future-proofing" for requirements that don't exist. This is *Speculative Generality*, the signature agent smell: inline it until a real second caller appears.
- **Defensive fallbacks and silent catch-alls.** try/catch that swallows the error, a default or `??` fallback that hides a failure the caller should see, guards and retries around code that cannot fail, `TODO`s standing in for real handling.
- **Shims and dead paths nobody asked for.** Backward-compatibility wrappers, re-exports under old names, and flags or branches for callers that don't exist; helpers never called, exports nothing imports, variables assigned and never read.
- **Tests that test the mock.** A test that mocks the unit under test, asserts on the mock's own return value, or asserts nothing.
- **Special-casing the test input.** Code that branches on the exact value a test feeds it, or returns a hardcoded expected output, so the test passes and the general case stays broken.
- **Narrating comments.** Long docstrings and comments that restate the code or narrate intent or the change ("now uses X instead of Y"), and commented-out code left behind.
- **Scope creep.** Changes outside what was asked: unrelated refactors, reformatting untouched lines, drive-by renames, version bumps nobody requested. Flag anything the stated intent doesn't justify.
- **Hallucinated APIs.** A method, flag, or field the real dependency doesn't have. Check it against the installed version.

The pass is done when every hunk has been checked against each signature above, and every new export, helper, and dependency has a confirmed caller or a finding.

### 4. Pass 3: Requirement-completeness

Measure the change against the intent captured in [Pick the review target](#1-pick-the-review-target), meaning the plan, issue, or user's words, and report the gaps:

- **Missing requirements.** Something the ask called for that the diff doesn't do at all.
- **Partial implementation.** A requirement handled for the happy path only, one case of several, or the interface without the behavior.
- **Stubs & placeholders left in.** `TODO`/`FIXME`/`throw new Error("not implemented")`/`pass`/empty handlers presented as if the work were done.
- **Wrong interpretation.** The change does *something*, but not the thing that was asked; it solved a nearby, easier problem.

If there's no captured intent to measure against (no plan, issue, or clear request), say so and skip this pass rather than inventing a spec.

The pass is done when every requirement in the captured intent is marked met, partial, or missing, each with the hunk that shows it.

### 5. Pass 4: Correctness

- **Logic, edge cases, state, and security.** Logic errors, empty and boundary input, the error path, races and resource cleanup, injection, missing authz, and secrets in code or logs.
- **Data bounds.** For each value the changed UI renders whose render or data source the diff adds or changes, find its limit in the validation schema, the database column, the API type, or a `maxLength`, then check that the render handles it: truncation or wrapping for long text, a break rule (`overflow-wrap`, `word-break`) for an unbroken string such as an email or an ID, the plural form at 1, an empty state at 0, and a fallback for a missing optional field. Quote the limit and the render line. A frontend limit shorter than the backend one is a finding, since a valid row then fails to save or display. When no limit exists in the repo, split on the render: a render with no long-text handling is a 🟡 finding written as `unbounded: no limit in <schema>, <column>, <API type>; render at file:line has no truncation or break rule`, a render that already handles long text is no finding, and a limit that lives outside the repo (a third-party API) goes in the coverage note. qakit's worst-case checks are the runtime half, which put these values on the screen. Without qakit, render the screen by hand with long, empty, and missing values.
- **Migrations.** When the diff adds or changes a migration file, name **dbkit** `migrate` check when it is installed. Otherwise check the lock each statement takes and that the file sets a lock timeout.
- **Tests.** Do the changed tests actually exercise the change, and do they pass? Run the repo's test command if one is obvious and cheap; report what you ran and what happened.

A passing suite does not prove a tested change. Hold each new or changed test to these five questions:

- **Would it fail against a broken implementation?** Mentally invert the logic it covers, or break a boundary value. If the test still passes, it's decoration.
- **Does it assert observable behavior**, or does it re-implement the production logic in the assertion and compare the code to itself?
- **Is the scenario visible in the test**, or buried in setup/fixtures/mocks so thoroughly that the test proves the mock works and nothing else?
- **Does it cover the failure paths the change introduced**, not just the happy path the feature demo walks?
- **Does it prove the stated requirement**, or an easier neighbor of it?

The pass is done when every changed code path has been checked against the list above, and every new or changed test has answered the five questions.

### 6. Report the findings

Print the review inline, findings ranked by severity. Tag each:

- 🔴 **Blocker.** Must fix before this ships; a real bug, security hole, missing requirement, or broken convention that will bite.
- 🟡 **Should-fix.** A real problem worth addressing, not release-blocking.
- 🟢 **Nit.** Polish, style, minor slop; take it or leave it.

For each finding give, in this order: the location as `file:line` (clickable), which pass caught it (convention / slop / completeness / correctness), **a quote of the offending hunk and what it violates** (the convention doc line, the stated requirement, the real API, or the failing input, per the evidence ground rules in [Pick the review target](#1-pick-the-review-target)), what's wrong in one sentence, and the concrete fix. If a pass found nothing, say so in one line.

Structure the report as: the verdict line, the findings most severe first, then the coverage note.

**Pick the verdict mechanically from the findings:**

- **needs-work.** One or more 🔴 Blockers.
- **ready-with-fixes.** No Blockers, but at least one 🟡 Should-fix.
- **ready.** Nothing above 🟢 Nits. Nits never hold up a change.

Close with the **coverage note**: one short paragraph naming what this review did *not* verify, meaning the unverified areas collected during the passes, plus whether you ran the tests and whether this was a fresh-eyes review or a self-review (per [Review with fresh eyes](#review-with-fresh-eyes)). When a gap is serious enough that a real problem could be hiding in it (an unreviewed security boundary, a migration nobody can validate here), say the change is **blocked on outside review** rather than issuing a verdict the evidence doesn't support.

### 7. Optional: save the report

After showing the review, offer to save it (don't save unprompted). If the user wants a durable copy, e.g. to paste into a PR description, write it to `docs/reviews/NNNN-review-<branch-or-feature-slug>-YYYY-MM-DD.md`, using the next serial, a short lowercase kebab-case slug, and the review's ISO creation date (for example, `0002-review-auth-refactor-2026-07-23.md`). To get the serial `NNNN`, take the highest leading four-digit serial in `docs/reviews/` across this worktree, every other worktree that `git worktree list` names, and `origin/HEAD` (`git ls-tree --name-only origin/HEAD docs/reviews/` after `git fetch origin`), and add one; start at `0001` when there is none. Scan all three, because parallel worktrees otherwise take the same serial. Skip a source that fails, such as no remote, and without git list the directory only. The serial is per directory and never reused. Keep the whole name stable if the same report is edited. Create `docs/reviews/` if needed. Keep the saved file identical to what you printed, with a one-line header noting the date and the reviewed range. If there's no filesystem, skip this step and leave the inline report as the deliverable.

### 8. Hand off

Close with three short beats, after the report:

- **What changed.** Say that reviewkit edited no source. State whether the report was saved.
- **Where it landed.** Give the saved report path, or say the report is inline only. Name the reviewed range.
- **Next.** Crown one move from the verdict:
  - **ready** → write the manual QA plan with **qakit** when it is installed (`/qakit`). Otherwise, commit with **commitkit**, otherwise `git commit`.
  - **ready-with-fixes** or **needs-work** → apply the findings with **implementkit**'s fix round and hand it this report. Otherwise, fix the findings by hand. Then run reviewkit again.
  - **blocked on outside review** → name the area and the person or check that must clear it. Nothing else is next until that review is done.

Route to the next kit; do not invoke it.

## Notes

- **`Skill` is in the tool list for gitkit only**, to resolve the base ref.
- **Scale to the diff.** A one-line fix gets a quick pass-through and a one-line verdict; a large feature branch gets the full treatment.
- **No shell or git?** Ask the user to paste the diff *and* the original ask, then run the four passes on what they provide and print the report as a codeblock for them to save themselves.
