# Plan: Remove the owner as the review bottleneck

Review: pending

## Context

The kits open agent PRs faster than one person can review, QA and merge them. In saasaloy on 2026-11-07, 18 PRs wait, 17 of them pass CI, and the oldest is from 2026-10-25. CI is not the blocker. The owner is. The owner wants to keep control of architecture and code quality. The owner also wants every machine-checkable rule in CI, and line review replaced by recaps, tours and decision lists where the risk is low. The guiding quote, from Anthropic: "We want to preserve human time and attention for issues only humans can solve and make sure automated checks catch the rest."

The research brief is `/home/dev/research-context/review-bottleneck-2026-11-07/brief.md`. This plan covers every brief item marked **K**, and the kit side of every item marked **S+K**. A separate plan in the saasaloy repo covers the saasaloy-only work (items 1, 5, 14, 15, 18) and the saasaloy side of the S+K items. Saasaloy is the worked example here. Every change below must work in any of the owner's repos.

Facts checked for this plan:

- afkkit's intro says "a PR-level review bot covers the diff once the PR opens", and its Non-goals defer deeper review to that bot. No kit sets the bot up. repokit `labels` provisions `ai-review` and says "repokit provisions the label; it does not write the workflow". Saasaloy has no review workflow.
- afkkit runs one dispatch of its own (the acceptance check), on the session's model, and the browser opens in qakit only. Its `assumptions.md` holds only choices between two options.
- issuekit `start` counts open feature PRs, warns at 3, and never refuses. afkkit only reports the count.
- mergekit `list` prints a table and does not crown a PR. mergekit's Notes say "No polling, no queue, no auto-merge". mergekit `close` already binds the confirmation to a head SHA with `--match-head-commit`. It checks CI, but not unresolved review threads.
- reviewkit is read-only and never posts. Its confidence bar accepts a finding that is "strongly supported with no credible innocent explanation". It has no pre-existing tag and no round logic.
- refactorkit has no modes and never edits source.
- verifykit is a "driver and recorder" that does not judge. qakit judges results against acceptance criteria.
- `IDEAS.md` lists `trailkit`, `impactkit` and `explainkit`, each modeled on a pstack skill. This plan resolves the first two.
- pstack is MIT licensed, copyright Lauren Tan, version 0.15.36 in the copy read on 2026-11-07.

Target: open PRs that wait on the owner stay at 3 or fewer in each repo that uses the kits (proposed; baseline 18 in saasaloy on 2026-11-07, from the brief). The guardrail is that reverts on main and `fix(...)` commits within 7 days of a merge do not rise. Both numbers are measured after release, by gatekit `recap` in Phase 7. No build phase can check them.

## Brief items mapped to kits

| # | Brief item | Kit | Change type | Why this owner |
|---|---|---|---|---|
| 2 | Smaller PRs | afkkit, plankit | update, update | afkkit owns the stop policy for an unattended run. plankit owns the phase shape that becomes one PR. |
| 3 | Risk tiers by path, as a `risk:*` label | gatekit `setup`, repokit `labels` | new skill, update | The labeler is a CI workflow, and no kit writes workflows today. repokit owns the label vocabulary. |
| 4 | Review bot as a required check | gatekit `setup`, reviewkit `pr` | new skill, new mode | gatekit writes the workflow. reviewkit owns the review the bot runs, so the rubric has one source. |
| 6 | Review pack for medium-tier PRs | mergekit `start` | update | `start` already prints a review pack. |
| 7 | WIP cap | afkkit | update | afkkit owns the decision to start or stop. issuekit keeps the count. |
| 8 | Weekly recap and sampled post-merge read | gatekit `recap` | new skill mode | The recap feeds the tier decisions that gatekit owns. |
| 9 | Metrics and guardrails | gatekit `recap` | new skill mode | Same reason as item 8. |
| 10 | `REVIEW.md` per repo | gatekit `setup`, reviewkit, rulekit | new skill, update, new skill | gatekit scaffolds the file, reviewkit reads it, and rulekit turns a repeated finding into a rule. |
| 11 | Blocking findings, tags, security review, resolved threads | reviewkit, gatekit `setup`, mergekit `close` | update, new skill, update | reviewkit tags findings. gatekit wires security review and branch protection. mergekit refuses a merge with an open blocking thread. |
| 12 | Review round cap | reviewkit `pr`, mergekit `fix`, rulekit `garden` | new mode, update, new skill mode | The bot side caps re-review. The author side caps fix rounds. The old-code scan is a sweep. |
| 13 | Approval pinned to a commit | mergekit `close`, gatekit `setup`, gitkit | update, new skill, update | mergekit already pins its confirmation. It must also check that the bot review and the verdict cover the head. gitkit owns the patch-equivalence rule. |
| 16 | Risk and How to revert in the PR body | prkit | update | prkit owns the body. |
| 17 | Eval set from past escapes | gatekit `eval`, rulekit | new skill mode, new skill | The eval scores the review pipeline that gatekit sets up. rulekit finds the escapes. |
| 19 | Rule-and-enforcer table and the `/correct` method | rulekit `correct` | new skill | No kit mines history for mistake classes and writes enforcers. refactorkit never edits. |
| 20 | Verification skill and feature map | verifykit `map` | new mode | verifykit owns driving the app. The map makes the drive reusable. |
| 21 | Proof-only findings | reviewkit | update | The rule changes reviewkit's correctness pass, which both the bot and afkkit use. |
| 22 | Independent verifier with a live check | qakit `accept`, afkkit, gitkit | new mode, update, update | qakit judges results against criteria. verifykit does not judge. |
| 23 | "Calls waiting on you" over the PR queue | mergekit `queue`, statuskit | new mode (replaces `list`), update | A merge decision is mergekit's domain. statuskit crowns one move and routes to it. |
| 24 | Decision log with a cross-model reviewer | afkkit | update | afkkit is the only unattended runner. |
| 25 | Shorter PR body | prkit | update | prkit owns the body. |
| 26 | Gardener and ratchet | rulekit `garden` | new skill mode | The ratchet is an enforcer, so it sits with the rule table. |
| 27 | Trust test before a lighter tier | gatekit `loosen` | new skill mode | Only gatekit changes tiers. |

Kits checked and left unchanged: grillkit, testkit, issuekit, commitkit. Reasons are in [Non-goals](#non-goals).

## Design decisions (proposed, not yet settled)

The owner has not settled these. Each row is a recommendation for the grill.

| Decision | Resolution |
|----------|-----------|
| New skills | Two. **gatekit** owns the merge gates in a repo: the risk-tier labeler, the review bot workflow, security review, `REVIEW.md`, branch protection, the weekly recap, tier changes and the review eval. **rulekit** owns the rule-and-enforcer table, the `/correct` method and the gardener sweep. Everything else is an update or a mode. |
| Why gatekit is a skill, not repokit modes | repokit modes are one-shot metadata jobs with no project judgment. gatekit carries a loop the owner returns to every week (recap, loosen, eval). Its material (tier rules, workflow templates, the `REVIEW.md` format, the metrics) loads only at those moments. Four more modes would double repokit's description. A split, with setup in repokit and the loop in gatekit, would cut one concept in two. |
| gatekit invocation | `disable-model-invocation: true`, like repokit. Only the owner starts it. This puts pstack's rule "anything that loosens a gate needs a separate countersign" into the frontmatter: no agent can loosen a tier on its own. A sibling kit routes the owner to it by name. |
| Why rulekit is a skill, not a refactorkit mode | refactorkit reads the tree's structure, has no modes, and never edits. `/correct` reads history and review comments for mistake classes, then writes lint rules and tests and proves each one fails on a past mistake. When the right fix level is architecture, rulekit routes the class to refactorkit as a proposal. refactorkit stays edit-free. |
| Where the review rubric lives | In reviewkit. A new `pr` mode is the review the bot runs. The gatekit workflow installs reviewkit into the repo at a pinned commit and tells the action to use it. No second copy of the rubric exists. |
| Proof-only findings (item 21) | reviewkit's correctness pass keeps a finding only when a run proves it: a failing test, a repro script, or command output. reviewkit reruns each command and drops what does not reproduce. The report gives a Dropped count. Convention and slop findings keep the quote rule, because a quoted doc line is their proof. A finding that cannot be run goes to the coverage note as an unverified area. |
| Finding tags (item 11) | Keep 🔴 🟡 🟢. Add a `pre-existing` tag for code that existed before the change. A pre-existing finding never blocks and never repeats across rounds. Only 🔴 on new code fails the bot check. |
| Round cap (item 12) | The bot side, in reviewkit `pr`: round 1 reviews the whole diff, and later rounds review only the diff since the last reviewed SHA. A finding never repeats. A repeated class is named once. After round 3 the bot posts a "rethink" summary and runs again only when the owner adds `ai-review`. The author side, in mergekit `fix`: after 3 fix rounds on bot findings, `fix` stops and hands the owner the bug class. |
| Risk tiers (item 3) | Path rules live in one repo file, `.github/risk-tiers.yml`, which gatekit writes. A deterministic workflow sets `risk:low`, `risk:medium` or `risk:high`. An unmatched path gets `medium`. Raise-only rules move a PR up a tier: a deleted test, an added lint suppression, a changed CI file, an outside author. The bot may raise the tier and never lowers it. Size never lowers a tier, so a split cannot game it (the Zalando finding). |
| Low-tier auto-merge versus mergekit's rule | mergekit stays the only skill that merges, always on a per-PR human confirmation. A low-tier auto-merge is a GitHub-side repo policy, off at setup. Only gatekit `loosen` turns it on, per tier, after the trust test. mergekit never enables it, and its Notes say so. |
| Human slots on a solo repo | GitHub refuses a self-approval, and agent PRs open under the owner's account. So gatekit never sets "required approvals" on a solo repo. The human slot is mergekit's per-PR confirmation. On a team repo, gatekit sets required approvals and "dismiss stale approvals on push" (item 13). |
| Verdict pinned to the patch (items 13 and 22) | A verdict records the head SHA and its `git patch-id`. gitkit owns the equivalence rule, ported from pstack's shipping playbook: a verdict still covers a head when the patches match, or differ only in tests, docs or lint config. A code change needs a new verdict. |
| Where a verdict lives | afkkit puts it in the PR body's Verification section, through prkit, so no extra outward action is needed. qakit `accept` on an open PR posts it as a PR comment with one machine-readable first line (`qakit-accept sha=<sha> patch-id=<id> verdict=<PASS|PASS+NOTES|FAIL> model=<alias>`), after a preview. Readers check both. |
| Verifier name | qakit mode `accept`, so it shares afkkit's term "acceptance check". The name `verify` would collide with verifykit. |
| Decision list (item 23) | mergekit `list` becomes `queue`. "List my PRs" still triggers it. It prints one call per PR, riskiest first, each with link, user impact, the agent's pick, evidence and risk, in pstack ketchup's shape. The picks come from evidence that other tools produced (tier, bot review, verdict, CI, conflicts). mergekit still forms no opinion of its own about the code. |
| Per-PR confirmation from a decision list | A reply that names each PR number ("merge 330, 325") confirms each named PR, bound to the head SHA the list printed for it. "Merge them all" still confirms nothing. mergekit then merges the named PRs one at a time, each with its own recheck. |
| WIP cap (item 7) | afkkit does not start an issue while the owner's open, non-draft PRs that wait on review number 3 or more. The number comes from issuekit's count. The cap is 3 by default. An inline override ("afkkit all, cap 5") or one line in the repo's agent-guide file can change it. A batch checks the cap before each issue. issuekit keeps its warning for attended starts. |
| Size stop (item 2) | After each phase-group commit, afkkit measures the branch diff outside tests, lockfiles and generated files. Above 1,500 added lines it escalates as a planning gap, keeps the commits, and asks for a split. |
| Decision log (item 24) | `assumptions.md` becomes `decisions.tsv` with pstack's columns (`ts`, `step`, `decision`, `why`, `evidence`, `result`) plus `alternative`. A row with an alternative is an assumption, and the PR body's Assumptions section is built from those rows. `progress.md` stays as it is, because the resume table keys on it. This folds `IDEAS.md`'s `trailkit` into afkkit. |
| Trail reviewer (item 24) | A second afkkit dispatch, after the fix step and before the PR. It reads `decisions.tsv` and the run's commits, not the code, and writes an Attention list. It uses a different model family when the host offers one (a Codex delegate on T3 Code, for example). Otherwise it uses a new agent on the same family, and the PR body says so. Its first line names the model. |
| PR body (items 16 and 25) | Without a repo template, prkit writes, in this order: Attention (afkkit runs only), Assumptions, Why, What changed, Scope, Tradeoffs, Blast radius with a How to revert line, Verification. The target is under about 40 lines. File-by-file detail goes to a linked artifact, such as the QA plan or a saved review. A repo template still wins. |
| Sign-off by the person who started the agent (item 16) | No checkbox. The per-PR merge confirmation is the sign-off. mergekit prints Blast radius and How to revert next to the confirm line. |
| Blast radius | reviewkit gains one output, from pstack's blast-radius skill: the one fact the change is safe because of, with its proof level on pstack's five-step ladder, marked proven or unproven. afkkit's acceptance check passes it to prkit. This folds the method of `IDEAS.md`'s `impactkit` into reviewkit. |
| Verification skill (item 20) | verifykit `map` writes a project-local skill, `verify-<app>`, into the project's skill directory: Launch, Doctor, Drive, Evidence, Cleanup, and a `features/` map with one file per feature. A second run of `map` maintains it (pstack's maintain pass). qakit, verifykit `show` and `proof`, and afkkit read it when it exists. A project with a machine-readable feature registry generates the map from that registry and adds a CI freshness check. Saasaloy's `registry-item.json` is the worked example. |
| Live check in afkkit (item 22) | The acceptance checker drives the agent-confirmable criteria live through the verification skill, on the run's one dev server. The rule "the browser opens in qakit only" becomes "the browser opens in qakit and in the acceptance check". |
| Credit | Each kit that borrows from pstack gains one Notes line that names pstack by Lauren Tan (MIT, cursor/plugins, version 0.15.36, read 2026-11-07). The text is written from scratch, so no license notice is owed. gatekit also credits the Anthropic code-review article and PostHog's StampHog. |
| Test approach | No new test framework. Every phase checks with `make lint`, and with `make cheatsheet` where a description changes. The phases that change run-time behavior also run once on a real saasaloy PR or issue, as each `Done when:` line says. |

## Conflicts with how the kits work today

Each conflict below has a proposed fix, and the fix lands in the phase that touches the kit.

1. **afkkit names a review bot that nobody sets up.** gatekit `setup` writes it (Phase 5). afkkit's Preflight detects whether the repo has a review workflow, and the PR body states when no bot review will run. Until then, afkkit's intro and Non-goals must not claim a bot exists.
2. **afkkit's one-review rule.** afkkit says it runs "exactly one acceptance check in-span" and makes one dispatch. Item 22 adds a live lane, and item 24 adds a trail reviewer. Fix: the one-code-review rule stays. The live lane joins the same acceptance check. The trail reviewer reads the decision log, not the code, so it is a second dispatch with a different role. The dispatch rules section names both.
3. **afkkit's single-model rule.** "Every model is the session's model" conflicts with a cross-model trail reviewer. Fix: one named exception for the trail reviewer, used only when the host offers another family.
4. **afkkit's browser rule.** See the live-check row above.
5. **afkkit says style belongs to the bot.** The acceptance check skips style because "the PR review bot and the human reviewer own them". Item 4's bot reports blockers, not style. Fix: style moves to lint through rulekit and to `REVIEW.md`'s nit cap. Neither the checker nor the bot owns it.
6. **mergekit "no queue, no auto-merge".** Fix: `queue` is a read-and-decide listing, not a poller. Auto-merge is a GitHub policy that gatekit `loosen` controls. mergekit's Notes change to say both.
7. **mergekit "never a batch".** Fix: the per-PR rule above. A reply must name each PR number.
8. **mergekit `list` "do not crown".** `queue` gives a pick per PR, but it ranks only by risk, for reading order. It still crowns no "next PR". statuskit crowns.
9. **reviewkit "never posts".** `pr` mode posts one GitHub review with inline threads. That is its output, and it edits no code. An attended local run previews the review before it posts.
10. **reviewkit's confidence bar.** The "strongly supported" route goes away in the correctness pass. Proof-only replaces it.
11. **repokit "does not write the workflow".** That stays true. repokit's `labels` hand-off and `setup` hand-off route the owner to gatekit `setup` when nothing listens for `ai-review`.
12. **issuekit's "warn, never refuse".** That stays true for attended starts. afkkit applies the cap to the count issuekit returns. The count has one source, and the cap policy has one owner.
13. **statuskit rung 2.** It crowns `mergekit start` on one unreviewed PR. With 3 or more waiting, it crowns `mergekit queue` instead.

## Approach

The work reuses the kits' existing seams. afkkit's run directory, dispatch rules and escalation contract take the new stops and the trail. mergekit's review pack, head binding and thread query take the tier, verdict and blocking-thread checks. reviewkit's passes, evidence rules and coverage note take proof-only findings and the `pr` mode. verifykit's driver precedence takes the project verification skill. repokit's label map takes the `risk:*` namespace. issuekit's open-PR count feeds the WIP cap.

The phases follow the brief's recommended order: clear the queue first, then make work verifiable, then move rules out of review, then automate review, then loosen with evidence. One change moves earlier. The inflow stops (WIP cap, size stop, short PR body) are cheap text changes that keep the queue from growing again, so they come second. Each phase is one PR in this repo, small enough to review in about ten minutes.

Rejected, one line each. Install pstack: it overlaps the kits, defaults code roles to Grok models, and depends on Cursor-only features (Bugbot, automations, cloud agents). A voting panel on each bot finding, as Anthropic runs: proof-only gives the same noise cut for one reviewer's cost. A separate `trailkit` shared layer: afkkit is its only consumer. An `impactkit` skill: the safety-fact method is one output of a review, not a moment the owner chooses.

### Phase 1: Queue catch-up and the review pack (items 23, 6, 11, 13)

- mergekit: replace `modes/list.md` with `modes/queue.md`. For each open PR, read tier label, CI, unresolved threads (bot and human), the latest verdict and whether it covers the head, conflicts with the base, behind count, stack position and linked issue. Print one opening sentence, then one call per PR, riskiest first, about 30 words each: link, what it changes for users, pick, evidence, risk. PRs that share a call share one call line. Credit pstack ketchup.
- mergekit `queue` offers one call to verify the PRs with no verdict or a stale one. On yes, it runs qakit `accept` on each, one at a time. Before Phase 3 ships, the call reads "verify by hand" and names the gap.
- mergekit: write the per-PR confirmation rule for a decision-list reply into "Never merge automatically".
- mergekit `start`: add to the review pack the Assumptions or decisions section from the PR body, a short tour (files in reading order, entry points first), shared surfaces (files that other open PRs also edit), changed and deleted test files with an assertion-count change, the QA screenshots next to the approved mockup path from the plan, the verdict line with its head check, and a "what the checks do not cover" line from the bot summary or the review coverage note. Scale the pack by tier: a low-tier pack is short, and a high-tier pack ends with "line review required".
- mergekit `close`: stop when an unresolved 🔴 or security thread is open on the PR, unless the owner names the thread and overrides it. Stop when the bot's last review or the verdict does not cover the bound head. Print Blast radius and How to revert above the confirm line.
- mergekit Notes: replace "No polling, no queue, no auto-merge" with the two points from conflict 6.
- statuskit: rung 2 crowns `mergekit queue` when 3 or more PRs wait on the owner. Add a tier column to the PR table when `risk:*` labels exist.
- afkkit Hand off: route **opened** to `mergekit queue` when the open-PR count is 3 or more.
- docs/wiki/workflow.md: rename `list` to `queue` in the LAND row and the mergekit section.

Done when: `make lint` passes; `grep -rn "mergekit list" skills docs/wiki` prints nothing; `mergekit queue` on saasaloy prints one call for each of its open PRs, riskiest first, and each call names a pick and a risk; `mergekit start` on one saasaloy PR prints the shared-surfaces and changed-tests lines.

### Phase 2: Stop the inflow (items 7, 2, 16, 25)

- afkkit: add the WIP cap as a preflight stop, per the design row. A stop is not an escalation, because nothing was mutated. The batch summary names the issues the cap held back.
- afkkit: add the size stop after each phase-group commit, per the design row. The escalation comment gives the measured line count and proposes split points from the issue's phases.
- plankit: in the plan-doc format, each phase is one PR. A phase that edits shared surfaces (files that other in-flight work also edits, such as a catalog or an index) is its own phase, ordered first. The plan file and its mockup assets land on the base branch in their own docs-only PR before the first build phase.
- implementkit: generalize the reproduction-test rule. Never delete, skip or weaken an existing test to reach green. When the spec changes a behavior and an old test must change, list it in the hand-off under "changed tests", and afkkit writes it as a decision.
- prkit: the new default body order and the 40-line target, per the design row. The hotfix Rollback line becomes the general How to revert line.
- Credit pstack's opening-a-pr playbook in prkit.

Done when: `make lint` passes; prkit's default body template lists the seven sections in order; afkkit's Preflight names the cap, its default and both override paths; an `afkkit all` dry read on saasaloy with 18 open PRs stops before the first issue and names the cap.

### Phase 3: The verification skill and the independent verifier (items 20, 22, 13)

Attended: the owner picks the saasaloy features for the first map and approves the generated skill's Launch command, because it starts real services.

- verifykit: add `modes/map.md`. On a first run, interview the repo (surface, run, drive, observe, isolate), write `verify-<app>` with Launch, Doctor, Drive, Evidence and Cleanup, and seed `features/` with the top 3 to 5 features. Prove the skill once end to end: launch, doctor, drive one feature, capture evidence, clean up, and confirm the evidence survives. On a later run, maintain it: index hygiene, a read-only source pass per feature, a live pass over every feature, then fix the map or report a product regression. Credit pstack create- and maintain-verification-skill.
- verifykit `map`: when the project has a machine-readable feature registry, generate the map from it and propose a CI freshness check. The cadence (a scheduled job) belongs to the project.
- verifykit shared procedure, qakit Scope step, afkkit "Work that runs once": read `verify-<app>` for launch and drive when it exists, before they derive their own.
- gitkit: add a short "patch equivalence" reference with the rule from the design row.
- qakit: add `modes/accept.md`, so qakit becomes a routing root plus its default plan mode and `accept`. `accept <pr|range>` runs in a new agent that did not write the change. It reruns the repo's gates once each, drives the feature-map journeys that the change touches, compares each result with the acceptance criteria, and returns PASS, PASS+NOTES or FAIL with the head SHA and patch-id. A rebase or a minor fix gets one `accept` run at the new head. New behavior gets the full run again. Credit pstack autopilot-full and shipping.
- afkkit acceptance check: add the live lane through qakit `accept`, and apply the browser-rule change. The verdict line goes to prkit for the Verification section.
- Add "Green CI alone never authorizes a merge" to qakit `accept`'s Notes. mergekit already holds this rule, so only the pointer changes.

Done when: `make lint` passes; qakit and verifykit each have a mode file per mode, and their roots keep only routing and shared material; `verifykit map` on saasaloy writes `verify-saasaloy` whose own proof run ends with evidence on disk; `qakit accept` on one saasaloy PR prints a verdict line with a SHA and a patch-id.

### Phase 4: rulekit, the rules out of review (items 19, 26, 12, 10, 17)

Attended: the owner approves the skill name.

- Write `skills/rulekit/SKILL.md` with two modes. Add it to `skills.sh.json`, `docs/wiki/index.md` and `docs/wiki/workflow.md`, and run `make cheatsheet`.
- `correct`: read recent commits, reverts, review threads (bot and human), the agent-guide file and workaround comments. Group the mistakes into classes, and a class counts after two occurrences. Fix each class at the highest level that works: architecture (routed to refactorkit as a proposal), types, a lint or CI check whose error names the fix, a test, then a written rule last. Prove each new check fails on the real past mistake. Keep the rule table (rule, enforcer, past mistake caught) in the agent-guide file. A broken rule with no enforcer is a repeat and moves up a level. Leave the changes uncommitted, one group per class, for commitkit.
- `correct` also writes each confirmed escape (a past PR whose bug shipped) as an eval case in the project's review eval file, for gatekit `eval`.
- `garden`: a sweep the owner runs or schedules weekly. It finds new workaround comments, new lint suppressions and a second way to do a thing the rule table names as one paved path. It installs or updates a ratchet: a baseline count per pattern and a CI check that fails when a change adds more. The comment sweep skips paths the repo marks as commented on purpose, such as CI and config files. It also scans old code for the bug classes the review bot keeps flagging as pre-existing (item 12) and offers each cluster as an issue through issuekit, with `gh issue create` as the fallback.
- The `REVIEW.md` loop (item 10): a finding flagged twice becomes a rulekit class. rulekit reads repeated bot findings as one input.
- Credit pstack correct and principle-encode-lessons-in-structure.

Done when: `make lint` passes; `make cheatsheet` shows rulekit; `rulekit correct` on saasaloy prints each class with its evidence, the level picked and why a higher level did not work, and every new check it wrote fails on the named past commit.

### Phase 5: Review automation (items 4, 3, 10, 11, 12, 13, 21)

Attended: the owner approves the gatekit name, adds the model secret to saasaloy, and approves branch protection on saasaloy.

- reviewkit: proof-only correctness findings with rerun and a Dropped count. The `pre-existing` tag. The blast-radius output. `REVIEW.md` joins the stated-conventions source in the convention pass. Credit pstack interrogate and blast-radius.
- reviewkit: split into a routing root plus `modes/local.md` (today's behavior) and `modes/pr.md`. `pr <n>` reviews a PR, in CI or locally. It reads `REVIEW.md` (failure statements per area, nit cap, skip paths), opens its summary with a finding count, posts one review with inline threads, applies the round logic, and sets the check to fail only on a 🔴 finding on new code. It may raise the `risk:*` label and never lowers it.
- repokit `labels`: add a fourth namespace, risk, with `risk:low`, `risk:medium` and `risk:high`. Route the `ai-review` gap and the `setup` hand-off to gatekit `setup`.
- Write `skills/gatekit/SKILL.md` as a routing root with `modes/setup.md` in this phase. Add it to `skills.sh.json`, `docs/wiki/index.md` and `docs/wiki/workflow.md`, and run `make cheatsheet`.
- gatekit `setup` writes, and leaves uncommitted: `.github/risk-tiers.yml` from the repo's real paths; the labeler workflow; the review workflow (Claude Code GitHub Action, triggered on open, push and `ai-review`, with reviewkit installed at a pinned commit); a security review workflow; and a `REVIEW.md` draft whose failure statements the owner fills in. It previews branch protection (required checks, resolved threads, and on a team repo required approvals with stale-approval dismissal) and applies it on the owner's OK. It checks that the `risk:*` labels exist and routes to repokit when they do not, with the `gh label create` lines as the fallback. CI workflow files and owner-listed paths always map to `risk:high`.
- mergekit `fix`: count fix rounds on bot findings, stop after 3, and hand the owner the bug class.
- afkkit: Preflight records whether a review workflow exists. The intro and Non-goals say "when the repo has one, which gatekit sets up".

Done when: `make lint` passes; on a saasaloy test PR, the labeler sets a `risk:*` label, the review workflow posts one review whose summary opens with a count and a Dropped line, and a second push gets a diff-only review that repeats no finding.

### Phase 6: The unattended decision trail (item 24)

- afkkit: replace `assumptions.md` with `decisions.tsv`, per the design row. Update the run-directory table, the spec gate, Implement, QA, Fix, Open the PR, the resume table, and the Hand off.
- afkkit: before Open the PR, audit the log against the run's commits and add any missing decision as a new row. Then dispatch the trail reviewer. It flags decisions with weak evidence, verification claimed without proof, choices that look risky in hindsight, and gaps a quick read would miss. Its Attention list goes first in the PR body, with "reviewed by <model>" as the first line. "No flags" is a valid result.
- afkkit dispatch rules: name the trail reviewer as the second dispatch and the one model exception.
- prkit: read the Attention list and build Assumptions from rows with an alternative.
- `IDEAS.md`: remove `trailkit` and `impactkit` with a pointer to this plan.
- Credit pstack show-me-your-work.

Done when: `make lint` passes; `grep -rn "assumptions.md" skills` prints nothing; one `afkkit <n>` on a saasaloy issue opens a PR whose body starts with an Attention section that names its reviewer model.

### Phase 7: Loosen only with evidence (items 8, 9, 27, 17)

- gatekit `recap`: a weekly read of what merged, grouped by tier. It gives the numbers: PR wait time, reverts on main, `fix(...)` commits that touch a merged PR's paths within 7 days, and release smoke failures when the repo has them. It samples 1 in 5 merged medium PRs for a post-merge read by the owner. Drift becomes an issue, through issuekit, and a rulekit class where it can. It writes a dated snapshot under `docs/gates/` by this repo's artifact naming rule.
- gatekit `loosen <path|tier>`: the trust test. The owner did the task once by hand, the agent has the owner's tools, every stage proves its work and can stop the line, repeated failures are now checks, and the recap numbers for that tier stayed flat for the chosen window. It moves a path to a lighter tier, or turns on low-tier auto-merge, as an uncommitted change to `.github/risk-tiers.yml` and the workflows, with the evidence in the hand-off. It never loosens a CI-file rule.
- gatekit `eval`: run reviewkit `pr` locally on each case in the project's review eval file (the bad commit's diff and the finding that should appear), and print caught or missed per case. The owner runs it after a change to `REVIEW.md` or to reviewkit.

Done when: `make lint` passes; `gatekit recap` on saasaloy prints the four numbers with their sources and names one sampled PR; `gatekit eval` on saasaloy prints caught or missed for each of the escapes #251, #269 and #274.

## Open questions

Each question has a recommended answer for the grill.

1. **gatekit's name.** "gate" already means the test-and-build gate in implementkit and afkkit. Recommended: keep `gatekit`, because a merge gate is the same idea one level up. The alternative is `tierkit`, which names only part of the scope.
2. **rulekit's name.** Recommended: `rulekit`, because "rule" is the word people search ("lint rule", "agent rules"). Check skills.sh and npm for a collision before Phase 4.
3. **How the review workflow gets reviewkit.** Recommended: install it at run time at a pinned commit of mimukit/skills, so no vendored copy can drift. The alternative is a committed copy under `.claude/skills/`. The exact install command comes from the skills.sh CLI help at build time.
4. **Which model the review bot uses, and which secret.** Recommended: the action's default alias and a `CLAUDE_CODE_OAUTH_TOKEN` secret, because the owner already pays for a subscription. Confirm that this is allowed for CI use.
5. **The WIP cap number.** Recommended: 3, the number issuekit already warns at. CircleCI's rule is "what you can merge in about a day". Revisit after two `recap` runs.
6. **The size limit.** Recommended: 1,500 added lines outside tests, lockfiles and generated files. Saasaloy's feature PRs run 4,000 to 11,600, so the limit would have split all of them. Is a new module confined to its own directory exempt?
7. **The unmatched-path tier.** Recommended: `medium`. `high` is safer but sends most PRs to line review, and that keeps the bottleneck.
8. **Low-tier auto-merge at setup.** Recommended: off, in every repo. Turn it on per tier with `loosen` after two recaps with flat numbers. "Start strict and loosen with evidence."
9. **Attention or Assumptions first in the PR body.** Recommended: Attention first, then Assumptions. Attention flags the risks in the run, and Assumptions lists the choices. Item 25 says assumptions first. This answer changes that.
10. **A verify-all call in `mergekit queue`.** It can cost 18 live verifier runs on saasaloy. Recommended: offer it as one call with the count and the estimated time, and run it only on a yes.
11. **Where gatekit's snapshot lives.** Recommended: `docs/gates/NNNN-gates-<repo>-YYYY-MM-DD.md`, per this repo's artifact naming rule. An alternative is no file and a printed recap only.
12. **The trail reviewer on a host with one model family.** Recommended: run it on a new agent of the same family and print "same-family review" in the Attention header. Skipping the reviewer drops the one read of the trail before the owner sees it.
13. **A `risk:*` label on an issue.** The labels are PR-scoped. Should issuekit `create` predict a tier for each phase, so a grill sees the expected review cost? Recommended: no, until the labeler has run on real PRs for a month.
14. **The saasaloy plan's order.** This plan needs saasaloy for live runs in Phases 1, 3, 4, 5 and 7. Recommended: the saasaloy plan merges #283 (the seeded playground) before Phase 3 starts here.

## Non-goals

- Installing pstack, its hooks or its plugin anywhere.
- Saasaloy-only work: generated catalog files (item 1), dependency-cruiser rules (item 5), the merge queue (item 14), experimental module status (item 15), and closing stale PRs (item 18). The saasaloy plan owns them.
- grillkit changes. The PR slicing rule lives in plankit's format, and grillkit already grills what plankit writes. A grill question that repeated the rule would be a second copy.
- testkit changes. rulekit writes the one test that enforces a class. A suite that passes when behavior breaks routes to testkit `audit`, which already has a mutation ledger.
- issuekit changes. Its open-PR count stays a warning. The cap is afkkit's policy.
- commitkit changes.
- An explainer skill for "explain this module before I change it" (item 8's last sentence). It stays in `IDEAS.md` as `explainkit`. mergekit's tour covers the PR-scoped case.
- A comment ban. CI and config files keep explanatory comments on purpose.
- A voting panel per bot finding.
