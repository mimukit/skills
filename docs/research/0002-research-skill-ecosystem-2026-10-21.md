# Research: the popular skill stacks, compared with the kit workflow

Sources read on 2026-10-21 by six parallel research agents, each from shallow clones of the repos and the authors' own writing. Star counts come from `gh api` on that date. pstack is out of scope here because [0001](./0001-research-pstack-skills-2026-08-19.md) already covers it, and its six backlog rows stay as they are.

Claims about this repo's kits were checked against the source before they went in: afkkit's batch is sequential on purpose (`skills/afkkit/SKILL.md`, Batch mode), only `seokit` has an `evals/` directory, no kit reads project learnings back, afkkit has no check for a weakened test gate, and skillkit's live test has no without-the-skill baseline.

## The landscape

| # | Repo | Author | Stars | Workflow in one line | Read in depth |
|---|---|---|---|---|---|
| 1 | obra/superpowers | Jesse Vincent | 302,672 | brainstorm, worktree, plan, subagent-per-task with review, finish branch | yes |
| 2 | mattpocock/skills | Matt Pocock | 298,846 | grill-with-docs, to-spec, to-tickets, implement or implement-spec, pr, retro | yes |
| 3 | affaan-m/ECC (everything-claude-code) | Affaan Mustafa | 284,991 | 311 skills, hooks that log tool calls, background "instinct" learning | yes |
| 4 | anthropics/skills | Anthropic | 182,536 | reference skills, plus skill-creator with paired evals | yes |
| 5 | DietrichGebert/ponytail | Dietrich Gebert | 170,031 | minimal-code discipline, reuse ladder, shortcut debt ledger | yes |
| 6 | github/spec-kit | GitHub | 142,184 | constitution, specify, clarify, plan, tasks, analyze, implement, converge | yes |
| 7 | garrytan/gstack | Garry Tan | 137,092 | role reviews of the plan, review, qa fix loop, ship, retro, learnings log | yes |
| 8 | addyosmani/agent-skills | Addy Osmani | 109,030 | spec, plan, build, test, review, ship; constraint and doubt skills; skill evals | yes |
| 9 | Leonxlnx/taste-skill | Leonxlnx | 99,970 | design direction, competitor test, screenshot critique | yes |
| 10 | pbakaus/impeccable | Paul Bakaus | 83,941 | design router with surface modes and a craft floor | yes |
| 11 | Fission-AI/OpenSpec | Fission-AI | 72k | living spec plus change deltas (ADDED / MODIFIED / REMOVED) | yes |
| 12 | code-yeongyu/oh-my-openagent | YeonGyu Kim | 70,234 | one keyword starts a full orchestration; todo-continuation hook | partly |
| 13 | bmad-code-org/BMAD-METHOD | Brian Madison | 54,390 | PRD, stable requirement ids, tickets that `cover` them, epic retrospective | yes |
| 14 | EveryInc/compound-engineering-plugin | Kieran Klaassen | 25,630 | ideate, brainstorm, plan, work, simplify, review, compound, PR | yes |
| 15 | humanlayer/humanlayer | Dex Horthy | 11,710 | research, plan, implement, validate (now QRSPI, not open-sourced) | yes |

Notes on reading this table. skills.sh counts are soft: the boards carry clones named `*/superpowers` with near-identical install counts that look farmed. `morluto/rea` shows 349k stars since April and was left out as suspect. Every benchmark quoted below (ponytail's −53% lines, i-have-adhd's +0.43) is self-reported by the repo's own harness.

## What the field converged on

Six patterns show up in three or more of these stacks independently. Convergence is the best signal in this survey, because each author arrived at the pattern from a different starting point.

1. **Skills get tested like code.** superpowers' `writing-skills` demands a failing baseline run without the skill ("If you didn't watch an agent fail without the skill, you don't know if the skill teaches the right thing"). Anthropic's `skill-creator` spawns with-skill and baseline runs side by side, grades assertions, and optimizes the description on a held-out set of trigger prompts. Addy Osmani's evals flag two descriptions that "near-collide". ponytail and i-have-adhd ship A/B results. skillkit today checks triggers by hand in a fresh session, once, with no control arm.
2. **Learnings flow back into the next task.** Compound Engineering's whole loop rests on it: "`/ce-compound` writes learnings that the next `/ce-brainstorm` and `/ce-plan` read as grounding." gstack logs typed learnings and prints "Prior learning applied". Matt's `retro` turns session friction into environment fixes. ECC and autoharness automate the same idea. The kits write plans, ADRs and QA docs, but nothing reads a project lesson back.
3. **Requirements carry stable ids end to end.** BMAD gives each requirement an `R` id and each ticket a `covers` list. spec-kit uses FR and SC ids and closes with `converge`, which types every gap as `missing`, `partial`, `contradicts` or `unrequested`. Kiro writes criteria in EARS form and derives property tests from them. In the kits, plankit's `Done when:`, issuekit's checkboxes, and afkkit's `checks.md` C-ids are three separate numbering schemes.
4. **Review splits into isolated axes.** Matt's `code-review` runs Standards and Spec as two parallel subagents and never merges their reports ("Reporting them separately stops one axis from masking the other"). Compound Engineering picks reviewer lenses from what the diff touches and announces each with a reason. superpowers' reviewer keeps a mandatory "declined to judge" list. reviewkit runs four passes in one subagent.
5. **A second reader checks the plan before the build.** superpowers sends a fresh "builder" subagent to read the design. claudex-loop has another model return a `verdict / findings / coverage / limitations` JSON, with approval "bound to the exact plan path and SHA256". spec-kit's `analyze` is a read-only consistency pass across spec, plan and tasks. grillkit interrogates only the user.
6. **Unattended runs get guardrails against cheating the gate.** Addy's `constraint-driven-development` forbids weakening the quality bar to make a change pass. ECC's `config-protection` hook blocks edits to linter config. gstack's QA loop stops "after two reverts or one edit to a file unrelated to the finding". oh-my-openagent's continuation hook exists to "prevent 'I'm done' lies". afkkit's acceptance check reads the diff for correctness, not for a deleted test or a new `@ts-ignore`.

## Ranked ideas to adopt

Ordered by value per unit of effort. Tier S changes how the whole loop behaves. Tier A sharpens one kit. Tier B is worth doing when the kit is next touched.

| # | Tier | Target | Change | Source |
|---|---|---|---|---|
| 1 | S | repo tooling, skillkit | `make triggers SKILL=<name>`: run `claude -p --output-format stream-json` on each line of `evals/triggers.md`, three reps, detect the `Skill` call, print a fire rate per case. skillkit's live test points at it and keeps the manual loop as the portable fallback | anthropics `skill-creator/scripts/run_eval.py` |
| 2 | S | skillkit | A **Baseline** step before Draft for any discipline skill: run 2 or 3 trigger prompts in fresh subagents without the skill, record the failures in `evals/baseline.md`, then rerun with the skill. Done when every recorded failure is gone or explicitly accepted | superpowers `writing-skills`, ponytail and i-have-adhd A/B |
| 3 | S | plankit, issuekit, afkkit, reviewkit | **Stable criterion ids.** Number each `Done when:` line `AC-<phase>.<n>`. issuekit carries the ids into checkboxes, afkkit's `checks.md` reuses them in place of fresh C-ids, reviewkit's requirement pass reports per id | BMAD `covers`, spec-kit FR/SC ids |
| 4 | S | implementkit done-gate, afkkit acceptance | **Typed gaps.** Classify each criterion and each unexplained diff hunk as `missing`, `partial`, `contradicts` or `unrequested`, and feed the gaps back as a fix round. State the rule that a checked box is not evidence | spec-kit `converge`, OpenSpec `verify` |
| 5 | S | afkkit acceptance check | **Gate-weakening blocker.** Over the diff range, flag a deleted or skipped test, a lowered coverage or lint threshold, a new `eslint-disable` or `@ts-ignore`, or an edited CI gate. Each is a blocker unless the issue asks for it | addyosmani constraint-driven, ECC config-protection |
| 6 | S | reflectkit (backlog row) | **Two routes, not one.** Keep the kit-edit route, and add a project route that writes `docs/solutions/NNNN-solution-<slug>-YYYY-MM-DD.md` with a `files:` list so a lesson goes stale when its files vanish. Gate each write on Compound Engineering's counterfactual ("would a future engineer still repeat the mistake?"), one lesson per run, a verbatim transcript quote as evidence, and a Save / Absorb / Drop verdict where Drop is a valid result. Matt's routing rule decides the form: a mechanical finding becomes a `make lint` rule or hook, only a judgement call becomes prose | CE `ce-compound`, Matt `retro`, autoharness reflector, ECC `learn-eval` |
| 7 | S | plankit, reviewkit | **Read the learnings back.** plankit's grounding step greps `docs/solutions/` and names each lesson it applies; reviewkit's convention pass does the same and prints "Prior learning applied: <path>". Without this, idea 6's project route is write-only | CE `learnings-researcher`, gstack `LEARNINGS_SEARCH` |
| 8 | A | reviewkit | **Split into isolated axes.** Conventions plus slop in one subagent, requirement-completeness in another, run in parallel, reported under separate headings with no cross-axis reranking. Add diff-triggered lenses (security, migration, performance) that each announce a one-line reason before the review starts | Matt `code-review`, CE `ce-code-review` |
| 9 | A | reviewkit | **Report rules.** A mandatory `Declined to judge` list. An "If we skip it" consequence on each finding. Findings numbered across severity groups so the user can say "fix 2 and 5". The implementer's own rationale never lowers a severity. Record the HEAD SHA reviewed, and have prkit warn when HEAD moved since | superpowers `code-reviewer.md`, ponytail-review, gstack `ship` |
| 10 | A | grillkit | **Coverage map and analyze pass.** Before round one, mark a short taxonomy Clear / Partial / Missing (failure paths, empty states, data lifecycle, scale, security, observability, migration, non-goals) and ask from the Missing rows first. Before the `Grilled:` stamp, a read-only pass checks that every phase has a `Done when:`, every decision row is used, and nothing contradicts `CONTEXT.md` or an accepted ADR. An ADR conflict blocks the stamp | spec-kit `clarify` and `analyze`, Kiro Analyze |
| 11 | A | grillkit | Word each question so "yes" accepts the recommended answer. One line | Matt `grilling` (2026-10-07) |
| 12 | A | grillkit | **Opt-in adversary round.** A fresh read-only subagent (or `codex exec -s read-only` when installed) reads the plan as its builder and returns verdict, findings, coverage and limitations; its findings join the next round. Record the plan hash beside the stamp so any later edit voids it. Add the sweep rule: when a decision replaces a behaviour, search the whole plan for the old one | superpowers builder check, claudex-loop |
| 13 | A | plankit | **Sections.** `## Behavior changes` with ADDED / MODIFIED / REMOVED for brownfield plans. A test-seams step that proposes the highest seams ("the ideal number is one") and confirms them. Split each `Done when:` into `Automated:` (with a command) and `Manual:`. A facts-only research subagent that maps the code without being told the feature | OpenSpec deltas, Matt `to-spec`, humanlayer `create_plan`, QRSPI |
| 14 | A | prkit | **Merge Danger.** Every PR body states `Door: one-way | two-way` and a one-word blast radius, plus the smallest visual (call tree or file tree) that makes the change clear | Matt `pr` |
| 15 | A | implementkit | **Escalating fix bound.** Replace "roughly three attempts" with three resumes of the same agent, then one or two rounds by a fresh agent with the failure report, then stop and report. In afkkit's fix round, write a regression test and prove it red before each repair, and stop after two reverts or one edit to an unrelated file | superpowers SDD, gstack `qa` |
| 16 | A | implementkit | **Smallest complete change.** A reuse ladder before writing (needed at all, codebase, stdlib, installed dependency, minimum), and a `shortcut: <limit>, <when to upgrade>` comment on each deliberate limit, which reviewkit then treats as a decision rather than a finding | ponytail |
| 17 | A | implementkit TDD mode | Name the tautological-test anti-pattern ("expected values must come from an independent source of truth"), and list each seam with what it catches and misses before the first red | Matt `tdd` |
| 18 | B | handoffkit | Tag each next step `(path run)`, `(path read)` or `(path assumed)`, and have the resuming session check the assumed ones first | gstack `context-save` |
| 19 | B | uikit | Add the competitor test to the signature check ("put the nearest real competitor in the sentence; if it still works, the idea belongs to the category"). Add browser surfaces to the floor: selection, caret, scrollbar, focus ring, `tabular-nums` in data | taste-skill, impeccable `craft-floor.md` |
| 20 | B | make lint | Description-collision check: TF-IDF similarity across every `description`, warning above a threshold. It targets the undertriggering AGENTS.md says no lint rule can see | addyosmani evals tier 2 |
| 21 | B | issuekit close | A plan retrospective when the last issue citing a plan closes: judge the plan against its goals, since per-issue review misses what nine small sessions did to one module | BMAD `bmad-retrospective` |

## Decisions these sources force

Four findings contradict a choice this repo already made. Each needs your call, not an edit.

- **Description what-clauses.** superpowers observed that a description summarizing the workflow ("code review between tasks") made the agent run one review and skip the body's second. Its rule is "never summarize the skill's process". AGENTS.md leads every description with a what-clause, and reviewkit's ("four ordered passes (…)") and debugkit's match the failing pattern. Idea 1's harness settles it: five reps of a review task under each wording, counting runs that execute all four passes.
- **`CONTEXT.md` versus `GLOSSARY.md`.** Matt renamed his in v1.3 because `CONTEXT.md` is ambiguous. domainkit, grillkit, issuekit and afkkit all name the file, so a rename is a coordinated change. His other domain change is cheaper and worth taking regardless: cross-check a claimed term against the code before recording it.
- **Prototypes deleted versus kept.** Matt now commits a prototype to a `prototype/<slug>` branch and links it from the issue as primary evidence. prototypekit deletes on purpose to stop a demo from becoming production. A middle path keeps the branch only for UI mocks and state models, and still deletes measurement scripts.
- **Parallel afkkit.** Matt's `implement-spec` and Kiro's dependency waves run independent tickets in parallel worktrees. afkkit's batch section records three reasons to stay sequential, and Matt himself concedes worktrees "move [collisions] to merge time". The survey does not overturn that rationale. Revisit only if the usage budget stops being the bottleneck.

## New skills worth considering

Most of what these stacks offer lands as edits on existing kits. Three ideas pass the AGENTS.md gate of a distinct moment a person would choose deliberately.

| Idea | What it does | Recommendation | Source |
|---|---|---|---|
| reflectkit, reshaped | The two-route version in idea 6 | Promote it above the other pstack rows; it is now the most-copied pattern in the field | CE, gstack, Matt, ECC, autoharness |
| wizard | When the agent hits a step only a human can do (secrets, dashboards, DNS), it writes an interactive script that walks the human through it | Worth a backlog row. Devaloy makes this case common, since nothing here opens a browser | Matt `wizard` |
| wayfinder | A map issue plus decision tickets for an effort too large for one session, worked one ticket per session | Weak as its own kit. ideakit plus issuekit `needs-planning` cover most of it; take the map-issue shape into ideakit if anything | Matt `wayfinder` |

The pstack-derived `explainkit` row should absorb humanlayer's `research_codebase` stance ("documentarians, not critics") rather than spawn a separate kit.

## What not to take

- **The SessionStart bootstrap and the "1% rule"** from superpowers. It forces a skill check on every turn, which undoes "the human is the index" and spends context load on every turn. Ideas 1, 2 and 20 attack undertriggering by measurement instead.
- **Autonomous skill creation** from autoharness and ECC's background observer. A skill is a deliberate human choice here, and a per-tool-call Haiku observer costs tokens and ships transcripts to a background model. Take their evidence and reconcile rules into reflectkit, not their autonomy.
- **Persona ceremonies.** gstack's CEO and eng-manager roles, BMAD's analyst and PM agents. Strip the roles and the useful part is a scope-mode recommendation and a checklist, already captured above.
- **A spec framework.** spec-kit itself is moving to a lighter core with extensions, and agent-os v3 dropped its spec tooling ("Spec writing: now best handled using Plan mode"). plankit plus grillkit remains the right shape; ideas 3, 10 and 13 take the parts that matter.
- **Bulk collections.** ECC's 311 skills, impeccable's 24 subcommands, taste-skill's 5k lines of direction library. This is the sprawl AGENTS.md names as the failure mode.
- **Always-on output modes.** i-have-adhd and caveman. The STE register already covers most of i-have-adhd; its one sharp rule, a pre-send check that the first and last lines alone say what happened and what to do next, belongs in your global CLAUDE.md if anywhere.

## Sources

- https://github.com/obra/superpowers (`skills/writing-skills/`, `skills/subagent-driven-development/`, `agents/code-reviewer.md`), https://github.com/prime-radiant-inc/superpowers-evals
- https://github.com/anthropics/skills (`skill-creator/`), https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices
- https://github.com/mattpocock/skills (HEAD `5beb35b`), https://www.aihero.dev/skills-changelog-v13-implement-spec-pr-retro-and-glossary-md, https://github.com/mattpocock/sandcastle
- https://github.com/garrytan/gstack (`review/`, `qa/`, `ship/`, `context-save/`, `scripts/resolvers/learnings.ts`)
- https://github.com/EveryInc/compound-engineering-plugin (`skills/ce-compound/`, `ce-code-review/`, `lfg/`), https://every.to/p/compound-engineering-gets-an-upgrade
- https://github.com/humanlayer/humanlayer/tree/main/.claude/commands, https://alexlavaee.me/blog/from-rpi-to-qrspi/
- https://github.com/github/spec-kit/tree/main/templates/commands, https://github.com/bmad-code-org/BMAD-METHOD, https://github.com/Fission-AI/OpenSpec, https://kiro.dev/docs/specs/, https://github.com/buildermethods/agent-os/blob/main/CHANGELOG.md
- https://github.com/addyosmani/agent-skills, https://github.com/DietrichGebert/ponytail, https://github.com/affaan-m/ECC, https://github.com/tigerless-labs/autoharness, https://github.com/chaseai-yt/claudex-loop, https://github.com/Leonxlnx/taste-skill, https://github.com/pbakaus/impeccable, https://github.com/ayghri/i-have-adhd, https://github.com/cloudflare/security-audit-skill
- https://skills.sh, https://skills.sh/trending
