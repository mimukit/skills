# Plan — Prose register

_Created 2026-08-09._
_Grilled: 2026-08-09._

## Context

The owner's global instructions say: "Write every reply to me in ASD-STE100 Simplified Technical English." That rule covers chat. It does not reach the documents the skills write, which is where most of the owner's reading actually happens: QA plans, runbooks, handoffs, status snapshots, and the `Hand off` section at the end of every skill.

Extending the rule is not a copy-paste job, because the repo already carries two prose rules that contradict it:

| Rule | Source | Asks for |
|---|---|---|
| ASD-STE100 | global `CLAUDE.md`, "Talking to me" | one term per concept, ≤20-word procedural sentences, uniform, no metaphor |
| No AI tells | global `CLAUDE.md`, "Writing prose" | plain verbs, concrete detail, uneven sentence length |
| humankit | `skills/humankit/SKILL.md:13` | "uneven in rhythm", "lightly opinionated", match the author's voice |

STE and humankit give opposite instructions. STE treats uniform text as correct. humankit treats uniform text as a defect to remove. A skill told to obey both produces nothing coherent. So the work is not "add STE." The work is **decide which register each artifact is written in, and say so once.**

A scope survey over all 27 skills produced a three-tier answer. Tier 1 artifacts are procedures a person follows under time pressure, which is the exact case ASD-STE100 was written for. Tier 2 artifacts mix procedure with argument. Tier 3 artifacts are machine-read or format-bound, and STE would break them.

The grill added a gate that sits above those tiers (D21). **The register applies only to what a skill writes back to its own operator.** Content a skill produces for a third-party reader is production writing and keeps its own standards, however procedural it looks. That gate is what removes `humankit` and `wikikit` from the plan.

Success means: a person reading a QA plan or a hand-off gets shorter, flatter, less ambiguous text; a person reading a research recommendation or a verdict still gets prose with a position in it; and no skill has to guess which of the two it is writing.

## Settled decisions

D1–D9 were settled at draft time. D10–D20 were settled in the grill of 2026-08-09.

| # | Decision | Answer | Why |
|---|---|---|---|
| D1 | Framing | **Register**, not "STE mode" | The rule that has to be stated is the *split*. Naming only STE would leave the humankit contradiction unresolved and invite someone to apply STE to a verdict. |
| D2 | Register names | `procedural`, `explanatory`, `exempt` | Three words a drafting agent can classify against in one read. The third is load-bearing: without it, a commit subject is a candidate for rewriting. |
| D3 | Split criterion | Who reads it and **why** | Not document type. A `docs/` file can be either. "Reads it while doing something" versus "reads it to form an opinion" classifies every artifact in the survey without a tiebreak. |
| D4 | Approach | Inline the rule per skill, stated once in `AGENTS.md` | Rejected: a new `stekit` skill (a 28th skill in trigger competition with `humankit`, plus a routing hop on every artifact). Rejected: a declared register field (nothing reads a field at runtime, so it is prose either way). |
| D5 | Scope of this plan | **Tier 1 only** | Tier 2 needs a per-section split inside single documents, which is a harder rule and a worse first test of whether the register idea holds. |
| D6 | Tier 3 handling | An explicit **exempt** list, written down | Cheaper to state the exemption now than to reverse a bad rewrite of a commit convention later. |
| D7 | humankit's status | Fully exempt, and untouched | humankit's rules are correct for its job. Superseded in part by D21: humankit is not merely exempt, it is out of scope, so no boundary line is added to it either. |
| D8 | Lint | **No check in this plan** | `scripts/lint.sh` checks structure. A sentence-length or vocabulary check fires on tables, code spans, and quoted text, and a noisy lint gets ignored. |
| D9 | Precedence | user instruction → target repo convention → register | Matches how every other rule in this repo degrades. A public skill must never override a host repo's documented style. |
| D10 | Inline policy | Full rule **once** in `AGENTS.md`, **one compressed line** per skill | Pays the duplication cost at its smallest. Every skill is `internal: false`, so a bare `AGENTS.md` reference would leave every public install without the rule. One sentence is cheap to keep true; a full paragraph in 24 files drifts. |
| D11 | Rule home | Global `CLAUDE.md` **and** `AGENTS.md` | The conflict originates in the global file, which already claims docs by name and asks for "uneven sentence length". Leaving it untouched means an inlined register line loses to a standing global instruction on every run. |
| D12 | "One term per concept" | Scoped to **one document**, never repo-wide | `crown`/`rank`, `preview`/`confirm`, and `adopt`/`reuse` appear about 190 times across the skills, and each pair carries a real distinction. A QA plan must not call the same thing a "step" and a "case"; `qakit` and `handoffkit` may still differ from each other. |
| D13 | Diátaxis mapping | ~~Per page, opening frame excepted~~ — **superseded by D21** | `wikikit` writes documentation for a project's readers, not for the operator. D21 removes it from scope, so the mapping question no longer arises. |
| D14 | Optional Tier 1 tasks | **All three ship** — T2, T4, T6 | T2 is what makes the rule apply to skills that do not exist yet, which is the reason to state it in `skillkit` at all. |
| D15 | Global amendment size | **One clause in each existing section**, no new section | "Talking to me" already carries the full STE rule list. Extending its coverage line costs one clause and duplicates nothing. A full register in the global file would be dead weight in every project without an `AGENTS.md`. |
| D16 | Skills without a `Hand off` | **`statuskit` only** | `gitkit` reports per operation and has no closing section to apply a register to. `reviewkit` closes at `### 6. Report the findings`, which mixes verdict with next action — Tier 2 by D5, so it is deferred rather than half-done. |
| D17 | humankit at runtime | ~~Detect, say so, ask~~ — **superseded by D21** | D21 puts humankit out of scope entirely, so nothing is added to it. The guard moves to the procedural side instead: see Deferred. |
| D18 | Proof | **Pilot on `qakit`**, then sweep | The judgment is subjective and the plan does not pretend otherwise. Generate one QA plan before and after; keep the register only if the second is faster to follow. |
| D19 | Per-skill line placement | Directly under the `## Hand off` heading | The agent reads it at the moment it writes the section. A `## Notes` block is one tidy home per skill and 200 lines from the text it governs. |
| D20 | Wiki page sync | The **four** skills whose rules change | `AGENTS.md` obliges a page edit for a materially changed rule, guard, or default. A one-line style note in a hand-off is not one, and the register is a repo convention that `AGENTS.md` already carries. |
| D21 | **Audience gate** | The register covers **agent-to-operator** text only | A skill's report to its own operator is 1-to-1 communication under time pressure, which is what ASD-STE100 was written for. Content a skill produces for a third-party audience is production writing: it needs room to explain a concept and a sentence length that fits the idea. Removes `humankit` and `wikikit` from scope entirely. |

## Approach

Reuses what already exists rather than inventing machinery:

- **`AGENTS.md`** already holds the repo's cross-skill conventions in exactly this shape (see its "Prose formatting" and "Closing a skill: the hand-off" sections). The register rule is one more section there.
- **`skillkit`** already carries a **Quality bar** and a **Conventions** block that new skills inherit. The register rule joins them, so it applies to skills that do not exist yet.
- **The one-line cross-skill note** is a shape the repo already uses: the `humankit` routing line appears verbatim in `wikikit:416`, `designkit:296`, and `uikit:321`. T7's register line is the same move, so no new convention is invented. Those three routing lines themselves do not change.
- **Portability** (`AGENTS.md`, "Visibility") forces a compressed form of the rule into each skill. All 27 skills are `internal: false`, so there is no internal exception to carve out.

Each task below is numbered so it can be allowed or disallowed on its own. Phase 2 is a gate: nothing after it runs until the pilot passes.

### Phase 1 — State the rule

**T1. Add a `## Prose register` section to `AGENTS.md`.** Place it directly after "Prose formatting", which it extends. Add a one-line cross-reference from "Closing a skill: the hand-off" so the two sections do not look like rival authorities. Proposed content:

> **This register governs what a skill writes back to its own operator.** It does not govern content a skill produces for a third-party audience — project documentation, published prose, UI copy, PR and issue bodies. That is production writing for readers who are not in the session, and it needs the freedom to explain a concept and to use the sentence length the idea requires. A content-generating skill keeps its own standards.
>
> Within agent-to-operator text, every artifact has one of three registers. Classify it before writing it.
>
> - **Procedural** — text a person reads *while doing something*: QA steps, handoff documents, status snapshots, `Hand off` sections, next-move lines, acceptance criteria, preview-and-confirm lines. Write it in ASD-STE100 Simplified Technical English. One instruction per sentence. Procedural sentences 20 words or fewer, descriptive sentences 25 or fewer. Active voice, present tense, name the actor. Keep the articles, and use a plain verb in place of a gerund. No metaphor, idiom, or second meaning. Six sentences per paragraph at most. Within a single document, pick one term per concept and keep it — this rule is scoped to the document, never to the repository.
> - **Explanatory** — text a person reads *to form an opinion*: plan context, research recommendations, ADR rationale, review verdicts. The repo's AI-tells rules govern this, and `humankit` owns the catalog. Do not apply STE here; it strips the register that makes a position readable.
> - **Exempt** — machine-read or format-bound text: Conventional Commits subjects, issue titles, prompts, design tokens, code, paths, commands, and anything quoted from another source.
>
> Precedence: an explicit user instruction, then the target repository's own documented convention, then the register.
>
> A skill's closing hand-off is procedural, whatever the skill produces for its reader. See "Closing a skill: the hand-off" for its structure.

**T11. Amend the owner's global `CLAUDE.md` by one clause in each of two sections** (D11, D15). No new section.

- **"Talking to me"** — extend its coverage line so STE reaches procedural documents, not chat alone: after "chat replies, summaries, and explanations", add the procedural documents the skills write for me (QA steps, handoff documents, status snapshots, and a skill's closing hand-off). The same clause states where it stops, per D21: content written for a third-party reader is not covered.
- **"Writing prose"** — scope its closing preference. The tells list still applies everywhere; only "uneven sentence length" narrows to explanatory and public-facing prose, because that single clause is what contradicts STE.

**T2. Add one line to `skillkit`'s Quality bar** (`skills/skillkit/SKILL.md:86-100`), and a matching short subsection under its `## Conventions`, so a newly authored skill classifies its own output.

**~~T3. Add a boundary line to `humankit`.~~ Dropped by D21.** `humankit` produces published prose for readers outside the session. Nothing is added to it, including the boundary line. The guard it would have provided moves to the procedural side instead: see Deferred.

### Phase 2 — Pilot and gate

**T4. `qakit`** — add the register to the "Rules for good cases" list at `skills/qakit/SKILL.md:195-228`. It is the least disruptive of the three remaining owners, because line 225 already says "Short lines, not walls of prose" and line 223 already says "Concrete and reproducible". The register names the standard those two are reaching for. Applies to Goal, Steps, checkpoints, Setup, Reset, and Not covered.

**T12. The pilot gate.** Generate one QA plan with `qakit` after T4. Compare it against a QA plan written before the change. Keep the register only if the second is faster to follow. This test is subjective by design (D18) — no metric is invented. If the pilot fails, stop here and revert T4; everything after this point is unstarted.

### Phase 3 — The remaining artifact owners

**~~T5. `wikikit`.~~ Dropped by D21.** `wikikit` writes a project's documentation for that project's readers. A runbook or a how-to it produces is public-facing production content, and it keeps `wikikit`'s own writing standards and its Diátaxis rules unchanged. `wikikit`'s closing `## Hand off` is still in scope under T7, because that text is the skill reporting to its operator.

**T6. `handoffkit`** — add the register to `## Document shape` (`skills/handoffkit/SKILL.md:28-58`). Applies to Next steps, How to run / verify, and Current state. Goal and Decisions & constraints stay explanatory, because they carry reasoning a cold reader has to weigh.

**T8. `statuskit`** — apply the register to the crowned move, the runner-up lines, and the snapshot checkbox list (`skills/statuskit/SKILL.md:212-219`, `264-269`). Line 221 already constrains a panel to one line, so the register is an extension of a rule the skill holds. Per D16, `statuskit` is the only skill without a `## Hand off` heading that is in scope.

### Phase 4 — The hand-off sweep

**T7. Add one register line to every skill's closing hand-off.** 24 of 27 skills carry a `## Hand off` section; `statuskit`, `reviewkit`, and `gitkit` close differently and are handled by D16. This is the single highest-leverage scope in the survey: one rule, one surface, and it is the text the owner reads when attention is lowest.

Per D10 and D19, the form is one italic line directly under the `## Hand off` heading, before the three beats:

> _Write this section in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

The full rule stays in `AGENTS.md` alone.

D21 does not shrink this task. `humankit` and `wikikit` keep their register line, because a `## Hand off` is the skill telling its operator what changed and where it landed. That is 1-to-1 session text, not the article or the doc page the skill just produced. The same split holds for `prkit`, `designkit`, and `uikit`: their output is public-facing and untouched, their hand-off is not.

### Phase 5 — Keep the repo honest

**T9. Update the wiki page for the four skills whose rules change** — `qakit`, `handoffkit`, `statuskit`, `skillkit`. Re-date each page's provenance stamp. Per D20, the other 23 pages are not touched: a one-line style note in a hand-off is not a materially changed rule, and re-dating 23 stamps that say nothing new makes the stamp meaningless as an audit signal. `humankit` and `wikikit` are among the untouched, because D21 leaves both skills unchanged.

**T10. Run `make lint`** and confirm no anchor, hand-off, or portability warning was introduced. No new lint rule is added (D8).

## Verification

1. `make lint` passes with no new warnings (T10).
2. The pilot gate passes: one QA plan generated after T4 is faster to follow than one generated before (T12).
3. Every skill with a `## Hand off` heading carries the register line directly beneath it — 24 skills, checked by grep.
4. `AGENTS.md` has exactly one `## Prose register` section, it opens with the D21 audience gate, and "Closing a skill: the hand-off" cross-references it.
5. The four wiki pages in T9 carry a `2026-08-09` provenance stamp; the other 23 are unchanged.
6. `skills/humankit/SKILL.md` and `skills/wikikit/SKILL.md` differ from `main` only in their `## Hand off` line. Nothing else in either file changes.

## Deferred

- **The humankit guard.** D21 drops T3, so nothing stops a user from running `humankit` over a QA plan or a handoff document and getting uneven rhythm back. The fix belongs on the procedural side rather than in `humankit`: `qakit`, `handoffkit`, and `statuskit` can each carry a line saying their artifact is written in the procedural register and is not humanized. That is a small addition to tasks already in scope, and it is deliberately left out of this pass until the pilot proves the register is worth protecting.
- **`reviewkit`'s findings report** — raised in the grill and deliberately not settled. Its closing section mixes a verdict (explanatory) with a next action (procedural), which makes it a Tier 2 problem. It becomes a candidate for the next pass rather than a half-measure in this one.
- **The Tier 1/2/3 vocabulary.** D21 supplies a sharper criterion than the tier split — *who consumes the artifact* — and the two disagree in places. The survey's tiers stay in this document as the record of how the scope was found. A later pass should retire them in favor of the audience gate.
- **Tier 2 generally** — see Non-goals.

## Non-goals

- **No rewrite of the `SKILL.md` prose itself.** An agent reads those files, not a person. 5,530 lines is a large change with an unproven benefit.
- **No Tier 2 work.** `plankit`, `refactorkit`, `researchkit`, `prkit`, `domainkit`, `uikit`, and now `reviewkit` are deliberately out. They need a per-section split, which this plan is testing the groundwork for.
- **No Tier 3 work, ever.** `commitkit` and `issuekit` title conventions, `promptkit` output, `designkit` tokens, `verifykit` proof files, and `gitkit` commands are exempt by D6.
- **No new skill.** Rejected in D4.
- **No new lint rule.** Rejected in D8.
- **No change to any public-facing content generator.** D21 puts `humankit` and `wikikit` out of scope. Their published output — humanized prose, project docs, runbooks, how-tos — needs room to explain a concept and a sentence length that fits the idea. Neither file changes except for its own `## Hand off` line, which is session text.
- **No change to `humankit`'s rules at all.** T3 is dropped, so not even a boundary line is added.
- **No repo-wide vocabulary purge.** D12 scopes "one term per concept" to a single document. `crown`/`rank`, `preview`/`confirm`, and `adopt`/`reuse` all survive.
- **No rewrite of existing `docs/wiki/skills/` prose** beyond the sync T9 requires, and only for the six skills named there.
