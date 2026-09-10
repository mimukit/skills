# Plan — collection audit repairs

Grilled: 2026-08-11

## Context

A full read of all 27 skills against `AGENTS.md` turned up no mechanical failures — `make lint` is clean and every skill carries its visibility marker, its "Use when" trigger, and a recognized closing section. What it did turn up is drift in the places lint structurally cannot see: contracts *between* skills, tool declarations that no longer match documented behavior, and one wiki page that has fallen behind the skill it describes.

One finding breaks a workflow at runtime rather than at read time. `prkit` requires a human OK before it flips a linked issue `in-progress → in-review`, and `afkkit` dispatches `prkit` as the terminal step of a run that is unattended by definition. Nothing in either skill says what a step does when it needs an OK and nobody is there, so an `afkkit` run either blocks at the last step or silently violates prkit's own stated rule. `prkit` is the only skill in that pipeline that asks for a confirmation and the only one with no unattended-awareness at all.

The rest is slower-acting. Three skills argue explicitly that `allowed-tools` is a load-bearing backstop rather than metadata, which makes it worth holding every skill to that standard — and nothing enforces it, because lint never reads the field. `gitkit` declares that any restatement of its rules elsewhere is a bug, while the portability rule for public skills requires exactly those restatements as degradation fallbacks; four skills sit in that contradiction today and all four are behaving correctly.

Success means the unattended path completes without a human, every skill's declared tools match what it actually does, the two conventions stop contradicting each other, and a single-skill change that forgets its wiki page gets caught by lint instead of by reading.

### What the grill established as fact

Four items that entered as open questions turned out to be answerable from the repo, and answering them reshaped two phases.

- **The `Skill` entry is genuinely unused in `refactorkit`, `plankit`, and `domainkit`.** refactorkit dispatches subagents through `Task`/`Agent`, not `Skill`; plankit delegates nowhere at all; domainkit only ever *routes* to grillkit. All three can drop the tool.
- **`verifykit`'s missing `allowed-tools` is correct, not an oversight.** It needs browser-automation MCP tool names that cannot be known at authoring time, and declaring any list would lock them out. Omission is the right call and belongs in its Notes as a deliberate one. — **Reversed on the owner's instruction, 2026-08-11.** verifykit now declares the four built-ins it drives itself (`Bash`, `Read`, `Write`, `AskUserQuestion`) and names the browser-MCP requirement in its Notes, so a host that enforces the field strictly must grant the MCP alongside them or verifykit degrades to its manual capture recipe. The lint exemption list is consequently empty.
- **The repo's history is fully linear — zero merge commits.** A stamped SHA stays reachable, so SHA-based checks are viable; date comparison is simpler and equally reliable here.
- **The wiki pages are not rotting.** 16 of the last 18 skill-touching commits also touched the page. The "22 stale pages" figure is one repo-wide prose commit (`72f8c4c`, 21 skills at once) plus one genuine miss (`44c225d`, statuskit). The discipline works; only the miss needs repair, and only the miss shape needs a guard.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Where prkit's exemption lives | On the **mode**, not the caller — modeled on issuekit's `start` exemption, which already argued the case: a caller-granted bypass can drift open, and the copy inside an unattended orchestrator is the one nobody would notice drifting. A collection-wide unattended convention in `AGENTS.md` is the right move on a **third** occurrence, not this one. |
| What the exemption covers | The `in-progress → in-review` flip, **and** the add-only path when the issue is `ready`. Those are the only two states `afkkit` can hand prkit, because issuekit `start` produced them. Any other lifecycle state reaching prkit unattended is drift: escalate rather than label over it. |
| implementkit's uikit delegation | Add `Skill` to `allowed-tools` rather than reword. implementkit says uikit "runs its own visual pre-flight" — that is behavior, not a rule set, so the sentence describes an invocation. Record the context cost in Notes so it reads as a known trade. |
| gitkit's no-restatement rule | Add a carve-out rather than strip fallbacks from public skills. Restating a **conclusion plus its degradation fallback** is required by portability; restating the **derivation** stays the bug. Portability is a hard requirement for every `internal: false` skill and cannot yield here. |
| Page-staleness check scope | Warn only when the skill's last-touching commit changed **one** skill. A repo-wide prose sweep is exempt by construction, which is what keeps the check from opening at 22 warnings with 21 of them correct to ignore. Compare commit dates; the scoping removes the noise that would have justified SHA parsing. |
| Page-staleness check severity | **Warning**, never an error. A prose-only commit legitimately does not oblige a page edit, and erroring would train people to re-stamp without re-reading — defeating the check. |
| `allowed-tools` enforcement | Lint checks **presence**, with `verifykit` as a documented exemption. That is the mechanically checkable half and the half that would have surfaced verifykit. The `Skill`-vs-delegation criterion is a **one-time verification** in this pass, not a standing invariant, because a prose heuristic for "does this invoke a sibling" would misfire on every skill that routes. |
| afkkit's model routing | Named tiers — strongest, cheap, different-family — with one line mapping them to this collection's Claude aliases as an example. The observed cost reasoning is the section's value and survives the abstraction; the hardcoded aliases do not survive installation into a non-Claude harness. |
| Phase independence | **Keep the five thematic phases and accept the file overlap.** The three shared files are prose edits in different sections, and hand-resolving a small conflict costs less than re-slicing the work around file ownership. |
| New skills | Out of scope. `releasekit` earns an `IDEAS.md` row placed **third, below `testkit`** — a real gap, but not one blocking a skill that already exists, which both rows above it are. |

## Approach

Repairs first, guards second, conventions third.

**The phases are not fully independent, and that is a deliberate accepted cost.** Four files are claimed by more than one phase: `skills/afkkit/SKILL.md` and `docs/wiki/skills/afkkit.md` (Phases 1 and 4), `AGENTS.md` (Phases 3 and 4), `docs/wiki/skills/statuskit.md` (Phases 2 and 3), and `scripts/lint.sh` (Phases 2 and 3). Working them in parallel worktrees will produce conflicts on those files. The edits land in different sections, so resolution is mechanical. **When this becomes issues, do not label all five `ready` and fan them out blind** — either work them sequentially, or expect and resolve the overlap by hand.

**What this reuses.** issuekit's `start` exemption (`skills/issuekit/SKILL.md`) is the template for Phase 1 and supplies its argument almost verbatim. The lint helpers in `scripts/lint.sh` — `skill_names`, `skill_exists`, the `frontmatter` reader, and the existing `check_skill_pages` traversal — already walk exactly the pairs Phases 2 and 3 need, so both new checks are blocks inside existing functions rather than new machinery. `AGENTS.md`'s existing "Visibility: internal vs public" and "Per-skill wiki pages" sections are where Phases 3 and 4 land their rule text.

### Phase 1 — unblock the unattended pipeline

The one runtime defect. Fixes `afkkit` runs that currently stall at their last step.

- Add a preview exemption to `prkit`'s "Advance the linked issue" step, worded to belong to the step rather than to the caller, covering the `in-progress → in-review` flip and the add-only path from `ready`.
- State in the same step that any other lifecycle state escalates rather than gets labelled over, and that every other prkit mutation still previews.
- Add one line to `afkkit`'s escalation contract naming what a dispatched step does when it needs an OK and the run is unattended: it escalates rather than blocking or assuming consent.
- Update `docs/wiki/skills/prkit.md` and `docs/wiki/skills/afkkit.md` for the changed guard.

Acceptance criteria:

- [ ] `prkit` names the exemption, its two covered states, and the reason the prompt adds nothing.
- [ ] `prkit` escalates when the linked issue carries any other lifecycle state.
- [ ] `prkit` still previews the PR creation, the handed-in-path commit, and every other mutation.
- [ ] `afkkit` names the unattended-and-blocked case in its escalation contract.
- [ ] Both wiki pages describe the new guard.
- [ ] `make lint` reports zero errors and zero warnings.

### Phase 2 — make tool declarations true

Three skills already argue `allowed-tools` is a guard, not metadata. Hold the rest to it, and give lint the half it can check.

- Add `Skill` to `implementkit`'s `allowed-tools`, and record the uikit context cost in its Notes.
- Remove the unused `Skill` entry from `refactorkit`, `plankit`, and `domainkit`.
- Add one Notes line to `statuskit` and `reviewkit` recording that `Skill` is present because both call `gitkit` for the base ref. Both entries are correct and both look removable to a later audit.
- Record in `verifykit`'s Notes that `allowed-tools` is omitted deliberately, because the browser-automation MCP's tool names are unknowable at authoring time.
- Add a lint check for `allowed-tools` presence, with `verifykit` as a named exemption.
- Update every affected wiki page's summary table, which carries `allowed-tools`.

Acceptance criteria:

- [ ] `implementkit` carries `Skill` and states the context cost.
- [ ] `refactorkit`, `plankit`, and `domainkit` no longer carry `Skill`.
- [ ] `statuskit` and `reviewkit` state why they hold `Skill`.
- [ ] `verifykit` states why it declares no `allowed-tools`.
- [ ] `make lint` warns on a skill with no `allowed-tools`, and exempts `verifykit`.
- [ ] Each affected wiki page's summary table matches its skill's frontmatter.

### Phase 3 — guard against wiki-page drift

One repair plus the narrow check that catches its shape again.

- Add a lint warning to `check_skill_pages` in `scripts/lint.sh`: warn when the last commit touching `skills/<name>/` postdates the last commit touching `docs/wiki/skills/<name>.md`, **and** that commit changed only one skill.
- Repair `docs/wiki/skills/statuskit.md`. It still describes the unblocked table as "every open issue that isn't blocked"; commit `44c225d` removed `in-review` issues from that set, moved the blocked table below the Pull requests panel, and renamed it `Blocked issues`.
- Record in `AGENTS.md` that the stamp is what the check reads, so a re-stamp asserts a re-read rather than a formality.

Acceptance criteria:

- [ ] `make lint` warns when a single-skill commit leaves its page behind.
- [ ] `make lint` stays silent on a repo-wide prose commit such as `72f8c4c`.
- [ ] The warning is a warning; it never fails the run.
- [ ] `docs/wiki/skills/statuskit.md` matches the current skill.
- [ ] `AGENTS.md` states what the stamp asserts.

### Phase 4 — resolve the convention contradiction

Two rules currently disagree with each other, and four skills sit in the gap while behaving correctly.

- Add the carve-out to `gitkit`'s Notes: a calling skill may restate a gitkit conclusion together with its degradation fallback, and may not restate the derivation. Name `prkit`, `mergekit`, `wikikit`, and `designkit` as the compliant cases so the rule reads against real examples.
- Mirror one line of the carve-out into `AGENTS.md` under the visibility section, where the portability requirement lives.
- Rewrite `afkkit`'s model-routing table as named tiers — strongest, cheap, different-family — keeping the observed cost reasoning and the different-family argument for review intact, with the Claude aliases named as this collection's example rather than as the contract.
- Update `docs/wiki/skills/gitkit.md` and `docs/wiki/skills/afkkit.md`.

Acceptance criteria:

- [ ] `gitkit` states which restatements are allowed and which are the bug.
- [ ] `AGENTS.md` carries the matching line.
- [ ] `afkkit`'s routing table reads correctly for a non-Claude harness.
- [ ] `afkkit` keeps the per-step cost reasoning and the different-family argument.
- [ ] No skill loses a degradation fallback it needs to work standalone.

### Phase 5 — file the coverage gap

- Add a `releasekit` row to `IDEAS.md`, **third, directly below `testkit`**: derive a changelog and a semver tag from the Conventional Commits the collection already enforces.

Acceptance criteria:

- [ ] `IDEAS.md` carries the row in third position with a one-line scope.
- [ ] No skill is authored in this phase.

## Open questions

The grill closed every decision this plan depends on. One item was raised and deliberately not settled:

- **Are `issuekit` (553 lines) and `statuskit` (324) too long to read cheaply?** Skipped rather than answered. It stays out of scope here — see Non-goals — and it is not a prerequisite for any phase above. File it separately if it is worth pursuing; do not let it re-enter this plan as a blocker.

## Non-goals

- **No new skills.** `releasekit`, `testkit`, and `debugkit` stay in `IDEAS.md`; authoring them is skillkit's job and a separate piece of work.
- **No prose-trimming pass** on `issuekit` or `statuskit`. Trimming a skill nobody has measured is how a load-bearing rule gets deleted.
- **No collection-wide unattended convention.** Phase 1 fixes one skill. Writing the general rule into `AGENTS.md` waits for a third occurrence.
- **No 27-page wiki re-stamp sweep.** The co-commit habit is working; only the one genuine miss gets repaired.
- **No change to the shared label tables.** The issuekit/repokit contract is lint-checked and passing.
- **No change to how afkkit sequences its pipeline.** Phase 1 touches the escalation contract only.
- **No `.github` or CI changes** beyond `scripts/lint.sh` itself.
