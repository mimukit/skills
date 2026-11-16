# Plan: Trim outdated instructions from the skills

Grilled: 2026-11-16

## Context

The skills were written to steer older, weaker models. A frontier model (Opus 5.5, Fable 5.2) follows a stated rule without a paragraph that argues for it, knows standard git and domain facts, and over-works rather than under-works. An audit on 2026-11-16 found that the old markers (ALL-CAPS, role prompts, "think step by step") are already gone. What remains costs context on every skill run and dilutes the rules that matter: persuasion tails after rules, Notes sections that repeat the body, body trigger lists, self-pitch intros, maintainer notes in runtime text, restated defaults, and textbook reference. The audit also found five confirmed bugs, ten reported bugs, and about 25 facts that may be stale.

The full findings, per skill and per line, are in `docs/research/0006-research-skill-trim-audit-2026-11-16.md`. That file is the work list for every phase below. Its paseokit and orcakit findings no longer apply, because this plan retires both skills.

The goal is skills that carry only what the model cannot do or know by itself, so each rule gets full attention and new skills do not regrow the excess.

Target: `skills/**/*.md` at 163,000 words or fewer, with no rule, guardrail, gotcha, or verified fact lost (proposed; baseline 203,736 words from `find skills -name '*.md' | xargs cat | wc -w` at `f2c5296` on 2026-11-16, which is 194,076 without paseokit and orcakit; the audit estimates about 31,700 removable words in the remaining 35 skills).

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Order | Fix the rules that teach the patterns first (skillkit and AGENTS.md), then retire the two skills, then bugs, then stale facts, then trims. A trim done before the authoring rule changes is regrown by the next skill edit. |
| The "why" rule | A rule carries one clause of why, and only when the reason is a non-obvious fact. A rule that needs no reason carries none. |
| AGENTS.md scope | Add one bullet under "Pruning" only. AGENTS.md stays the owner's reasoning record, so its own argument tails stay. |
| Body trigger lists | Delete the quoted trigger phrases from "When this fires" sections. Keep each routing or boundary rule that changes behavior ("no mode is clear → ask", "backend-only goes to qakit"). |
| Notes sections | Keep a Notes bullet only when it is the no-filesystem fallback, a reason `TOOLS_EXEMPT` in `scripts/lint.sh` requires, or a fact stated nowhere else in the skill. |
| Maintainer notes | Keep a note, cut to one clause, only when it stops a specific future edit from breaking something (uikit's catalog cap). Delete the rest, and put the reason in the commit body. |
| Duplicates | Keep the most precise statement of a rule, in the section where the agent needs it. Replace the other copies with a link only when the reader must jump there. |
| Kept on purpose | Gotchas, hard guardrails, the procedural-register lines, the inlined serial rules (portability), the afkkit resume state machine, owner-curated numbers (motionkit curves, qakit worst values). |
| No-behavior-change proof | After each skill's trim, a fresh subagent reads the diff with the rubric from research 0006 and puts every removed sentence in a class: argument, duplicate, default, or textbook. Each sentence it cannot place gets a live trial: a second fresh subagent gets the trimmed skill and one prompt that tests that sentence. A sentence whose trial shows a behavior change goes back in. The commit body records "N sentences removed: A argument, D duplicate, F default, T textbook, U unplaced, R restored". |
| paseokit and orcakit | Retired. Move both to `archive/<name>/` at the repo root and set `internal: true` in each frontmatter. skills CLI 1.8.1 walks the repo root one level deep, so `skmi` no longer finds them; the internal flag covers a `--full-depth` scan. Nothing lints, installs, trims, or fact-checks `archive/`. |
| Local installs | Remove paseokit and orcakit from `~/.claude/skills` and `~/.agents/skills` on this box with the skills CLI. Approved. |
| Stacked branches | Keep stack support. Install `github/gh-stack` on this box with `gh extension install` to verify the version floors. Approved. |
| Matching | Line numbers in the research file drift as edits land. Match each finding on its quoted text. |
| Commit shape | Commit straight to local `main`. One commit per skill for trims, `refactor(<skill>): trim …`. Bug fixes and fact updates are separate `fix(<skill>)` commits, so a revert of a trim never reverts a fix. Approved. |
| Push | After each phase, push `main:skill-trim-wip` as a backup. Push `main` only after the owner review, then delete `skill-trim-wip` on the remote. Approved. Nothing reaches `origin/main` before the review, so no box installs unreviewed trims. |
| Review cadence | Phases 1–7 run straight through with no stop. The owner reviews once, after Phase 7. |
| Descriptions | Out of scope. No `description:` field changes in the 35 remaining skills, so `make cheatsheet` shows no diff after Phase 2. |
| Lint guard | Add a `make lint` warning for a "When this fires" section that quotes three or more phrases. No idiom warnings, because words like "tempting" give false positives. |
| motionkit `vocabulary.md` | Cut to about 8 non-obvious terms (rubber-banding, hold to confirm, origin-aware, perceptual duration). The lookup branch keeps its file. |
| gitkit container section | Move to `skills/gitkit/container.md` behind a one-line pointer, because only container runs reach it. |
| Fact sources | `--help` on this box first, else the vendor's docs by web fetch. Name the source in the commit body. |

## Approach

The work reuses the repo's own tools: `make lint` checks anchors, step references, hand-off sections and portability after every edit; `make cheatsheet` proves no description changed; `wc -w` measures the target. The rubric and the per-skill findings come from the research file, so no phase re-audits from scratch.

Rejected: a single collection-wide rewrite pass. It mixes bug fixes into trims, makes review impossible, and loses the per-skill revert.

### Phase 1: Fix the authoring rules (built 2026-11-16)
- In `skills/skillkit/SKILL.md`, apply the five Propagators items in the research file: the "why" rule, "slightly pushy", the base-model claim, the Quality bar pointer list, and the live-test reason.
- In `AGENTS.md` "Pruning", add one bullet: "A skill body carries no argument after a rule, no trigger list, no Notes that repeat the body, and no note to a future maintainer."
- In `scripts/lint.sh`, add the trigger-list warning.
- Trim the rest of skillkit per its findings, with the no-behavior-change proof, because children copy this file.

Done when: `grep -n 'slightly pushy\|base model can.t handle\|Explain the \*why\*' skills/skillkit/SKILL.md` prints nothing, the new AGENTS.md bullet exists, `make lint` passes, and `make lint` prints the new warning for at least one skill that still has a trigger list.

### Phase 2: Retire paseokit and orcakit (built 2026-11-16)
- `git mv` both directories to `archive/`, and set `internal: true` in each frontmatter.
- Remove both from `skills.sh.json`, `README.md`, `docs/wiki/index.md`, `docs/wiki/workflow.md`, and `docs/wiki/architecture.md`. Run `make cheatsheet`.
- Delete the skill names from `skills/gitkit/SKILL.md` and `skills/gitkit/clean.md`. Keep the generic vendor-tool rule.
- Add one line under Layout in `AGENTS.md`: "`archive/` holds retired skills; nothing lints, installs, or trims them."
- Remove the local installs with the skills CLI.
- Commit as `chore(repo): retire paseokit and orcakit`, with the reason in the body.

Done when: `make lint` passes, `skills add /home/dev/projects/skills --list` names neither skill, `grep -rn 'paseokit\|orcakit' skills/ skills.sh.json README.md docs/wiki/` prints nothing, and neither name exists in `~/.claude/skills` or `~/.agents/skills`.

### Phase 3: Fix the bugs (built 2026-11-16)
- Fix every item under "Confirmed bugs" in the research file.
- Check every item under "Reported bugs, not yet checked", except the paseokit item. Fix it, or record in the commit body why it is not a bug.

Done when: every bug item is fixed or recorded as not a bug, the repaired `gh api` read in repokit setup runs on this repo without error, the issuekit triage regex matches `hotfix(auth): fix crash`, and `make lint` passes.

### Phase 4: Update stale facts (built 2026-11-16)
- Install `github/gh-stack` with `gh extension install`.
- Check each row in "Stale facts to verify" against a primary source, except the paseokit and orcakit rows.
- Rewrite promptkit's model-generation entries to key on the call's thinking or effort setting, not the model family.
- Update reviewkit's slop signatures to current-model tells.
- Pin a version and a check date beside each vendor fact that changes.

Done when: every remaining row is updated, or confirmed with its source named in the commit body, or listed in the commit body as unverifiable with the reason.

### Phase 5: Trim the high-yield skills (built 2026-11-16)
Apply the per-skill findings, with the no-behavior-change proof, to statuskit, testkit, researchkit, refactorkit, prkit, reviewkit, designkit, releasekit, debugkit, and prototypekit (19–35% each, about 12,400 words).

Done when: every finding for these ten skills is applied or skipped with a reason in the commit body, each commit body carries the reviewer's class counts and the skill's word count before and after, `make lint` passes, and `make cheatsheet` shows no diff.

### Phase 6: Trim the middle band (built 2026-11-16)
Apply the per-skill findings, with the no-behavior-change proof, to promptkit, verifykit, grillkit, implementkit, motionkit, qakit, commitkit, humankit, issuekit, gitkit, plankit, repokit, tutorkit, uikit, mergekit, seokit, wikikit, afkkit, ideakit, and validatekit (12–18% each). skillkit was trimmed in Phase 1.

Done when: the same checks as Phase 5 hold for these 20 skills.

### Phase 7: Trim the lean skills and measure (built 2026-11-16)
Apply the per-skill findings, with the no-behavior-change proof, to domainkit, handoffkit, namekit, and dbkit. Then measure the whole collection and push the backup ref.

Done when: the same checks as Phase 5 hold for these four skills, `find skills -name '*.md' | xargs cat | wc -w` prints 163,000 or fewer, and `origin/skill-trim-wip` points at local `main`.

## Open questions

None. Every decision was settled in the grill on 2026-11-16.

## Non-goals

- No change to any `description:` field or to the trigger wording that loads every turn, beyond removing the two retired skills.
- No new skills, no merged skills, and no mode splits. The only file moves are the two archived skills and the gitkit container satellite.
- No removal of stacked-branch support. If that is wanted later, it needs its own plan, because it touches six skills and the `stacked` label.
- No trim, fact check, or lint of anything under `archive/`.
- No change to AGENTS.md beyond the two named lines.
- No change to the procedural-register rule or the hand-off structure.
- No re-audit. New findings that turn up during a trim go to a new research file, not into this plan.
