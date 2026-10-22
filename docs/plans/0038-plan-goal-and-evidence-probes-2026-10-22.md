# Plan: goal and evidence probes in plankit and promptkit
Grilled: 2026-10-22

## Context

Felix Rieseberg's article [How to be more ambitious](https://felixrieseberg.com/how-to-be-more-ambitious-a-tutorial-for-humans-with-models/), retold in the AI LABS video "Anthropic Just Revealed How Their Engineers Use Claude Code" (2026-10-22), names two habits this repo only half follows. Altitude asks for the goal behind the request and for a specific, hard target, because specific hard goals beat "do your best". Depth says the model never grades its own work and should start from the rawest source material, not a summary of it.

plankit already asks for "the outcome that means success", but a one-line answer like "users can log in with SSO" passes its Done-when bar. Nothing asks what the work is for, and nothing asks for a number. promptkit's `task` contract already demands a concrete Done signal, but its own worked example uses a test the receiver writes after the fix, which only proves the change agrees with itself. Its Ground step resolves vague paths and commands, but not a vague reference to evidence ("the crash", "users complain").

Success: a plankit run records the goal behind the request and a target (or a reason no number fits that names what does show success), and a promptkit `task` prompt carries a Done signal the receiver cannot satisfy by writing its own check after the change, plus a ledger row for every summary of evidence it resolved to the primary artifact. Target: no number fits, because this is a change to skill prose; `make lint` passing and the grep checks in each phase are what show it worked.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Shape of the plankit change | Sharpen the existing success-outcome item in plankit's Capture step. Keep four items and one question round. No fifth item, no change to Diverge. |
| Who answers the number question (Q1) | Every plan. The escape is a reason no number fits that names what does show the work worked ("docs-only change, so the check is a lint pass"); a bare "not applicable" fails the step. |
| Proposing a target (Q2) | plankit asks for the user's number first. Only when the user has none does it propose one, from a baseline, labelled `proposed` with the baseline and its source: `Target: p95 load under 200 ms (proposed; baseline 4.8 s from <source>)`. |
| Baseline source (Q10) | A number the user gives, or a file the agent can read (a CI report, a benchmark output, a dashboard export). plankit has no shell, so it never measures one itself. |
| No baseline (Q11) | plankit proposes no number. It writes `Target: open, no baseline` and adds the line to Open questions, so grillkit settles it. |
| Where the target lands (Q3) | Always in the plan's Context. Also in the last phase's `Done when:` when the build can measure it. A metric that only shows after release stays in Context, marked `measured after release`. implementkit and afkkit need no change, because they already check every `Done when:` line. |
| Where "rawest source" lives in promptkit | The `task` Ground step: a summary of evidence resolves to its primary artifact (log path, crash report, failing command output, data file) as a ledger row, or stays named as unresolved. The contract stays five-part, so the "five-part" references and the no-rewrite gate are unchanged. |
| Independence rule for the Done signal | The Done signal row prefers a check that exists before the receiver starts (an existing test, a command, a measurement). A check the receiver writes itself must be watched to fail before the change. |
| Fail-first scope (Q5) | Every `task` prompt, not only bug fixes. A new-feature test fails before the change because the feature is absent. |
| Valid failure (Q6) | The fail-first check must fail for the stated reason, not from an import or setup error. |
| `system` mode (Q7) | Untouched. The evidence and independence rules are `task`-only, because a `system` prompt has no repo receiver and no ledger. |
| Review-only runs (Q8) | A review-only `task` run names a self-graded Done signal as weak, separate from a missing one, so the rule shows up in a review. |
| Slop catalog (Q4) | No new entry. The contract row and the review-only rule carry the meaning in one place, and the catalog stays at 30. |
| Worked example | Update `skills/promptkit/worked-example.md` so its Done line follows the independence rule. An example that breaks the rule it illustrates teaches the old rule. |
| Descriptions | Unchanged for both skills, so `make cheatsheet` output and `docs/wiki/` stay as they are. |
| Outward actions (Q9) | None. The build leaves every change uncommitted for the owner to review. No phase is attended, and no phase needs a new test runner. |

## Approach

Two local edits to two public skills, each portable as written (no repo-relative links, no dependency on this repo's machinery). Both reuse existing structure: plankit's four Capture items, its Done-when line, its Open questions section, and its plan-doc format; promptkit's resolution ledger, its five-part table, its review-only check, and its worked example.

Rejected: a fifth Capture item (adds a question to every run, and the goal probe is already part of "success"); a sixth `Evidence` contract part (three reference edits and a changed no-rewrite gate for a rule that fits inside two existing rows); a catalog entry (a second home for the same rule, and a forced deletion at the cap).

### Phase 1: plankit goal probe

- In `skills/plankit/SKILL.md`, Capture the idea: define the success outcome as the goal behind the request plus a target, or a reason no number fits that names what does show it worked.
- In the same step, state the target rules: ask the user first; propose only from a baseline the user gives or a file records, labelled `proposed` with baseline and source; with no baseline, write `Target: open, no baseline` and carry it to Open questions.
- Extend that step's Done-when line: the success outcome passes only with a target, a `Target: open, no baseline` line, or a reasoned no-number escape. A bare "not applicable" fails.
- In the plan-doc format, make the `## Context` line carry the target, and add one rule beside the `Done when:` rule: the last phase's `Done when:` carries the target when the build can measure it; a post-release metric stays in Context marked `measured after release`.

Done when: `grep -n "goal behind" skills/plankit/SKILL.md` matches the Capture step and the plan-doc format; `grep -n "no baseline" skills/plankit/SKILL.md` matches the Capture step; `grep -n "measured after release" skills/plankit/SKILL.md` matches the plan-doc format; and `make lint` reports 0 errors and 0 warnings.

### Phase 2: promptkit evidence rules

- In `skills/promptkit/modes/task.md`, Ground in the repo: add a bullet that resolves a summary of evidence to its primary artifact, recorded in the ledger like a path or a command, or named as unresolved.
- Extend that step's Done-when line to cover evidence references.
- Rewrite the Done signal row in the five-part table: prefer a check that exists before the receiver starts; a check the receiver writes must be watched to fail, for the stated reason, before the change.
- In the review-only clause of the contract step, name a self-graded Done signal as weak, separately from a missing part.
- Update `skills/promptkit/worked-example.md`: the Done line asks for the new failed-refresh case to fail before the fix, for the stale-token reason, and pass after; add an evidence row to the ledger only if the example input names evidence.

Done when: the Done signal row in `skills/promptkit/modes/task.md` names the pre-existing-check preference and the fail-first rule with its stated-reason clause; the Ground step's Done-when names evidence references; the review-only clause names a self-graded Done signal as weak; `grep -n "fail" skills/promptkit/worked-example.md` shows the new case failing before the fix; `grep -c "^| [TSB] " skills/promptkit/SKILL.md` still prints 30; and `make lint` reports 0 errors and 0 warnings.

## Open questions

None. Every question from the draft was settled in the 2026-10-22 grill.

## Non-goals

- A reviewer from a different model family (recommendation 1 from the video analysis). The owner takes it up separately.
- Multi-discipline review crews in reviewkit or uikit.
- Changes to grillkit, implementkit, afkkit, or issuekit. The target reaches the build through the existing `Done when:` line.
- Changes to promptkit's `system` mode or its slop catalog.
- Changes to either skill's `description`.
