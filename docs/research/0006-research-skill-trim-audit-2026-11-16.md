# Research: outdated instructions in the skills collection

## Context

On 2026-11-16 six parallel reviewers read every `.md` file under `skills/` (37 skills, 203,736 words by `wc -w`). Each reviewer tested every passage against one rubric: what a frontier model (Opus 5.5 / Fable 5.2 class) does correctly without the instruction, or what now costs more than it buys. The edits were read-only. Line numbers refer to `main` at `f2c5296` and will drift as edits land, so match on the quoted text, not the number.

The plan that acts on this file is `docs/plans/0050-plan-skill-trim-2026-11-16.md`.

## Rubric

| # | Pattern | Test |
|---|---------|------|
| 1 | Persuasion tail | A rule followed by sentences that argue for it or against an imagined shortcut ("the tempting move", "X wearing a Y", "that is the point"). Keep the rule, cut the argument, unless the reason is a non-obvious fact. |
| 2 | Default restated | Behavior the model does unprompted: bounded retries, "ask rather than invent", "never fabricate a command", read-before-edit. |
| 3 | Tutorial or textbook | Standard tool usage or domain knowledge the model holds. Keep gotchas, version-specific facts, and owner choices. |
| 4 | Trigger duplicate | A body "When this fires" list that repeats the description's phrases. The body loads only after the skill fires. Keep routing and boundary rules. |
| 5 | Self-pitch | An intro that markets the skill or restates the description. |
| 6 | Over-specification | Micro-rules for easy judgment calls, worked examples of the obvious. |
| 7 | Over-demand | Wording that pushes a model that already over-works into more work. |
| 8 | Stale fact | A fact that is wrong or unverified as of 2026-11. |
| dup | Duplicate | One rule stated two or more times in the same skill, most often in a closing Notes section. |
| maint | Maintainer note | Text that speaks to a future editor of the skill, not to the running agent. |

## Estimated removable words per skill

Total about 32,800 words (16.1%).

| Skill | Words | Removable |
|-------|------:|----------:|
| statuskit | 10,714 | 30–35% |
| testkit | 4,202 | 30% |
| researchkit | 1,734 | 28% |
| refactorkit | 2,767 | 23% |
| prkit | 4,625 | 22% |
| reviewkit | 3,558 | 21% |
| designkit | 4,027 | 20% |
| releasekit | 3,099 | 20% |
| debugkit | 3,934 | 19% |
| prototypekit | 2,630 | 19% |
| promptkit | 6,178 | 18% |
| verifykit | 3,836 | 18% |
| grillkit | 3,598 | 17% |
| implementkit | 3,437 | 17% |
| motionkit | 8,668 | 17% |
| qakit | 8,627 | 17% |
| commitkit | 5,014 | 16% |
| humankit | 2,892 | 16% |
| issuekit | 13,728 | 16% |
| gitkit | 13,140 | 15% (root alone 24%) |
| plankit | 2,702 | 15% |
| repokit | 6,981 | 15% |
| skillkit | 3,938 | 15% |
| tutorkit | 5,367 | 15% |
| uikit | 6,649 | 15% |
| mergekit | 7,232 | 14% |
| seokit | 8,939 | 14% |
| wikikit | 5,979 | 13% |
| afkkit | 7,596 | 12% |
| ideakit | 6,242 | 12% |
| paseokit | 6,475 | 12% |
| validatekit | 3,030 | 12% |
| orcakit | 3,185 | 11% |
| domainkit | 3,745 | 8% |
| handoffkit | 1,324 | 8% |
| namekit | 2,521 | 7% |
| dbkit | 11,422 | 5% |

## Propagators in skillkit

These lines teach the patterns to every new skill.

- `skillkit/SKILL.md` "Prune no-ops" bullet, last sentence: "Explain the *why* behind a rule when it isn't obvious." It has no length cap. Replace with "Give one clause of why, and only when the reason is a non-obvious fact."
- `skillkit/SKILL.md:139` "phrased slightly pushy to fight undertriggering". Older skill-authoring advice. Current models over-trigger on forceful wording, and the phrase conflicts with "one trigger per branch". Replace with "name each branch's real phrasing plainly".
- `skillkit/SKILL.md:140` "A skill only fires for tasks the base model can't handle directly." An unverified host claim, moot for `disable-model-invocation` skills. Replace with "Write only what the model cannot already do."
- `skillkit/SKILL.md:142-152` The Quality bar restates the Conventions sections in the same file. Replace the pointer bullets with "Apply every Conventions section."
- `skillkit/SKILL.md:53` "the skill list loads at startup, so a running session won't see the new skill". Verify: current Claude Code hot-reloads `~/.claude/skills`. Keep "fresh session", with a clean trigger test as the reason.

## Confirmed bugs

- `repokit/modes/setup.md:12` `gh repo view --json …autoMergeAllowed…` fails on gh 2.104 with `Unknown JSON field`, so the whole settings read fails. Drop the field. Read `allow_auto_merge` from `gh api repos/{owner}/{repo}`.
- `gitkit/SKILL.md:309` "git pull on a branch behind its remote merges by default". Git 2.33+ refuses a divergent pull when `pull.rebase` is unset. Keep the rule (always `--rebase` or `--ff-only`) and drop the false reason.
- `issuekit/modes/triage.md:31` The title regex has no `hotfix`, so triage flags valid hotfix titles.
- `qakit/SKILL.md:332` Names T3 Code tools (`html_preview`, `html_render`). This breaks the no-T3-in-skills rule. Use host-neutral text.
- `wikikit/modes/init.md:41` and `repokit/modes/about.md:50` hold the only "write every hand-off in this skill in the procedural register" line, so the other modes never load it. Move each to the root. verifykit has the opposite fault: `modes/proof.md:61`, `show.md:20` and `setup.md:48` each carry a copy, and the root can hold one.

## Reported bugs, not yet checked

- `gitkit/SKILL.md:167` "Four rules" but five bullets follow.
- `gitkit/clean.md:46` "squash-merges, the common GitHub default". GitHub's default is a merge commit.
- `issuekit/modes/create.md:95` "the lifecycle nine". The set has ten labels since `stacked`.
- `testkit/SKILL.md:264` "Do not draft a commit message" against `:271` "Suggest a message such as test(<area>)".
- `designkit/SKILL.md:169` "three states" but the table lists four (`supplied`). `:208` also omits `supplied`.
- `releasekit/SKILL.md:56-62` "A 404 means unprotected". A branch guarded only by a ruleset also returns 404 from the classic protection API, so the direct push fails after the changelog is written. Also probe `gh api repos/{owner}/{repo}/rules/branches/$BASE`.
- `releasekit/SKILL.md:163` The check-runs call has no `--paginate`, so a commit with more than 30 checks is read in part.
- `repokit/modes/setup.md:87` Typo "empty, This step".
- `paseokit/SKILL.md:30-34` "Two consequences" introduces three bullets.
- Serial-rule drift: `qakit:95`, `verifykit modes/proof.md:3` and `show.md:12`, `testkit:64`, `repokit setup.md:81` say `origin/HEAD` with `git fetch origin`. AGENTS.md says `origin/<default branch>` with `git fetch origin <base>`.

## Stale facts to verify

| Location | Claim | Check |
|----------|-------|-------|
| promptkit SKILL.md:86, 139-150; task.md:44; system.md:11 | reasoning-native vs non-reasoning models | Current models are hybrid. Key the shape to the call's thinking or effort setting, not the model ID. |
| promptkit SKILL.md:79 | caps are "volume, not precision" | Make the why "forceful wording makes current models over-trigger". |
| promptkit SKILL.md:86, 88 | "GPT-4", "one 2023 paper" | Remove dated references. |
| promptkit SKILL.md:94 | "some tokenizers split them badly" | Verify or drop the clause. |
| reviewkit SKILL.md:76-81 | slop signatures (`// increment i`, hallucinated APIs) | Current tells: defensive fallbacks, compat shims, tests that mock the unit under test, long docstrings. |
| afkkit SKILL.md:311, 72 | "a subagent cannot start a subagent" on Claude hosts | If false, the conductor relay and the batch rule simplify. |
| afkkit SKILL.md:228, 312 | `send_input` on Codex | Verify the tool name or say "the host's message-to-agent tool". |
| implementkit SKILL.md:59 | "`Task` or `Agent`" | Claude Code renamed Task to Agent. |
| grillkit SKILL.md:116 | AskUserQuestion caps at 4 questions and 4 options | Verify current limits and the automatic "Other". |
| namekit SKILL.md:34, 45 | rdap.org 404 = not registered | A TLD with no RDAP server may also return 404 and report a taken domain as free. |
| orcakit SKILL.md:43-66, 122-136, 238-250 | Orca CLI selectors and flags | Run `orca --help` on a current install. |
| paseokit SKILL.md:66-74, 16 | Paseo 0.8.0 facts; "registers nothing on its own" | Run `paseo status`, `paseo workspace --help`, `paseo project --help`. |
| gitkit stacks.md:10-16 | gh-stack version floors 2.90/2.94 | Check the extension release notes. |
| mergekit modes/close.md:72 | `gh stack merge` | Not installed on this box. |
| dbkit engines/mysql.md:21, 31 | 8.0.16 and 8.0.18 branches | MySQL 8.0 reached end of life in April 2026. |
| dbkit engines/postgres.md:99-106 | version table ends at PG 18 | Add PG 19 if it is GA. |
| dbkit SKILL.md:69, orms.md:14-17 | Prisma `directUrl` | Prisma 7 moved URLs to `prisma.config.ts`. |
| dbkit orms.md:8, 10 | Drizzle journal; "in the versions we know" | Pin a version. |
| seokit SKILL.md:136, 160; structured-data.md:11; SKILL.md:90 | FAQ rich results end date; crawler table; privacy.anthropic.com link; `--headless=new` | Plain `--headless` is new mode since Chrome 132. |
| motionkit SKILL.md:140, 154, 170; modes/perf.md:15 | Firefox compositor for clip-path and background-color; Motion v12 transforms | `@starting-style` is Baseline, so the `data-mounted` fallback may go. |
| designkit SKILL.md:51, 104, 128-135 | DESIGN.md alpha schema of 2026-08-06; eleven lint rules | `npx @google/design.md spec --rules --format json`. |
| humankit SKILL.md:47, 138 | "Words that spiked after 2023" | Diff against the current Wikipedia "Signs of AI writing" revision; consider "genuinely", "load-bearing", "quiet". |
| uikit mobile.md:54 | `interactive-widget=resizes-content` on iOS | iOS Safari does not support it. |
| wikikit publish.md:82, 133 | `actions/checkout@v5`, `github-wiki-action@v5` | Check current majors and input names. |
| wikikit publish.md:11, 13, 15 | no API creates a wiki; force-push behavior | Check current GitHub docs. |
| verifykit SKILL.md:90 | raw.githubusercontent mp4 does not embed | Verify; drop "deliberate later add". |

## Cross-skill patterns

1. **Notes sections that repeat the body.** The largest single pool. debugkit:255-260, refactorkit:166-172, prototypekit:154-161, reviewkit:163-168, orcakit:265-271, plankit:145-149, testkit:273-281, paseokit:256-262, uikit:221-226, verifykit:87-92, qakit:338-340, designkit:326-331, ideakit:236-244, tutorkit:194-197, wikikit:165-171, promptkit:170-172, implementkit:163-168, releasekit:212-218, afkkit:334-338, statuskit:384-394. Keep only the no-filesystem fallback, a reason `TOOLS_EXEMPT` in `scripts/lint.sh` requires, and true one-offs.
2. **"When this fires" trigger lists.** 32 skills. Keep routing rules ("no mode is clear → ask", "backend-only goes to qakit"). mergekit:19-26 routes modes, so trim it, do not delete it.
3. **Persuasion tails.** Densest in testkit, refactorkit, statuskit, debugkit, promptkit system.md, tutorkit, issuekit triage.md and create.md. The idioms "X wearing a Y", "worse than no X", "that is the point", "load-bearing" (9 uses) and "genuinely" (21 uses in six skills) mark them.
4. **Self-pitch intros and "What X is not" lists.** Keep a "not" item only when it routes to a sibling or blocks an observed drift.
5. **Maintainer notes in runtime text.** gitkit:380-381, statuskit:120, 386, 393, issuekit SKILL.md:99, 184, start.md:68, uikit:99, paseokit:258, mergekit SKILL:62 and close.md:75, implementkit:165, releasekit:213, 218, verifykit:90, testkit:191.
6. **One fact stated 3–5 times.** humankit no-invent (:15, :43, :81, :113, :121); default-branch closing keywords (prkit:111, 155, 206; issuekit sync.md:19, 52; start.md:21; close.md:12); label-exemption rationale (issuekit SKILL.md:55, start.md:87, close.md:3, 45, sync.md:89; prkit:168, 216); statuskit layer fallback (76, 141, 152) and reviewer rule (92, 155, 225); mergekit sync consent (SKILL:62, start.md:5, 44-48); designkit grounding (:17, :178, :184, :326); seokit stop-processes (:31, :84, both mode stop steps); validatekit market read (:21, :138, :214); the "it proposes, never fixes" essay (debugkit:21, refactorkit:19, reviewkit:13).
7. **Defaults restated.** implementkit:106 and testkit:239 retry caps; the hash-object before/after ritual in commitkit:64, 71 and prkit:27, 33; gh preflight blocks in prkit:40-46, repokit:47-50, issuekit:43-49.
8. **Text written against an older version of the skill.** "exactly as before", "works exactly as it always has", "before this rule existed": prkit:63, 122, 215, 216; issuekit create.md:122; gitkit:134.
9. **Satellite preambles** that say the root applies: gitkit clean.md:3, rescue.md:3, stacks.md:3; seokit audit.md:3, crawl.md:3; dbkit design.md:3, migrate.md:3, audit.md:3, tenancy.md:33; motionkit build.md:3.

## Findings per skill

Format: location · pattern · action. "Cut tails" means keep each rule sentence and delete the argument after it.

### statuskit
- 13-23 · 5, 4 · Delete intro and When this fires; keep "Read and advise; writes only the Write-rules files."
- 56-66 · 1 · Compress to "A workable critical preempts every rung. Name the displaced move. Several workable → route to issuekit triage."
- 92-94, 155, 225 · dup · Keep the three-outcome rule at 155 once.
- 98, 120 · maint · Delete.
- 141, 152 · dup · Link to the layer fallback at 76.
- 149-150 · 1 · Keep definitions; cut rationale clauses.
- 209-225 · 1 · Compress the rung commentary to its three rules (10b lowest serial; stacked is startable when prerequisite PRs form one open chain; 8b lowest unbuilt phase).
- 281 · 2 · "Write move lines in ASD-STE100; one term per thing."
- 287-303 · 6 · Drop the render rules' Why column; keep the `Closes none` and `Blocked issues` reasons.
- 343, 358, 360 · 1 · Delete 360; cut 343 and 358 to rules.
- 362-366 · 1 · "One issue or PR per checkbox. Every move needs an observable retire signal; else route to plankit or issuekit."
- 384-394 · dup · Delete 386, 387, 390, 391, 394. 392-393 to "Skill: gitkit only. Edit: the two appends only."

### testkit
- 17-28 · 1, 5 · "Every kept test is observed red under a mutation, and takes its expectation from outside the implementation."
- 30-39 · 4 · Keep 36 (new work goes to implementkit); delete the rest.
- 43-47, 58, 66 · 1 · Delete "will feel wrong", the "bureaucracy" line, the "run N+1 cheap" paragraph.
- 99-102, 112-118, 128, 245 · 1, 6 · Delete glosses on obvious signals and tails.
- 136-142 · 1 · Cut tails.
- 150-152, 165 · 1 · Keep "declare N/M, stop on excess" and "provenance comment on every test".
- 179-183 · 1 · Keep the guardrail; delete the meta sentence.
- 189-191, 210, 214 · 1 · Cut tails.
- 239 · 2 · "If the gate fails, report it red; never weaken an assertion."
- 264 vs 271 · bug · Make them agree.
- 273-281 · dup · Delete 275-280; keep 281.
- Keep: the mutation ledger (stash create, `patch -R`, never `git checkout -- <file>`).

### researchkit
- 13-15 · 5 · Delete.
- 17-24 · 4 · Delete; the single-survivor explainer sits in step 2.
- 28-32 · 1 · "Never write or run code to settle a claim; log it in Open questions and route a spike to prototypekit." allowed-tools enforces it.
- 42, 63 · 2 · Delete "Don't pad the field with strawmen".
- 110 · 2 · Delete the Execution note.
- 112-113 · dup · Delete.

### refactorkit
- 13-21 · 5, 1 · "Write one Markdown file; touch no source."
- 23-32 · 4, 6 · Delete; 90 covers superseding an ADR.
- 36-46 · 3 · One line naming Ousterhout depth and the seam terms; keep Leverage and the domain-terms rule. Medium confidence.
- 46, 50, 65, 69, 73 · 1 · Cut tails.
- 106, 118, 120, 132, 138, 162 · 1 · Cut tails.
- 166-172 · dup · Delete Zero-mutation, Route-don't-launch, Route-don't-require bullets.

### prkit
- 13, 15-17 · 5, 4 · Delete; keep the draft-only routing sentence.
- 27, 33 · 7 · "Run read commands only: no fetch, push, commit, rebase, or gh writes."
- 40-46 · 3 · "Stop and say so if `gh auth status` fails."
- 59, 65, 80 · 1, 2 · 59 to "Read the full diff only when commits are thin or the stat shows unexplained files."; delete 65; 80 to one sentence.
- 67, 214 · 2 · Delete.
- 84, 94 · 1 · Delete rationale; keep one of 94 and Notes 213.
- 111, 155 · 1 · State the default-branch closing-keyword fact once.
- 122, 215 · 2 · Delete Notes 215; cut publish narration and "exactly as before".
- 132, 139 · 3 · "Use --body-file with a temp file."
- 168-172, 216 · 1, 2 · Keep the rules (replace, two allowed start states, stop on any other); delete rationale, 172, Notes 216.
- 177, 141 · 1 · Delete rationale sentences.

### reviewkit
- 13-15 · 5 · "Review agent-written code in four passes; report findings, never edit."
- 19-21 · 1 · "Delegate the passes to a fresh subagent with diff and intent; otherwise label the report a self-review."
- 25-29 · 4 · Delete; keep "a correctness-only request runs only that pass".
- 68, 83 · 3 · Delete Fowler paragraphs; keep Speculative Generality as one slop bullet.
- 70, 85, 120 · 7 · Per-pass "every changed test answers the five questions"; the per-check clean-result ledger conflicts with "Scale to the diff" at 167.
- 76-81 · 8 · Update slop signatures (see Stale facts).
- 104-110 · 3 · Compress logic, edge cases, concurrency, security to one line; keep data bounds, migrations, tests.
- 163-168, 130, 140 · dup · Delete Read-only and Not-a-substitute Notes, the 130 tail, and 140.
- Keep: the untracked-files rule (37) and "read the diff once" (45).

### designkit
- 13-17 · 5 · "DESIGN.md (Google Labs format) at repo root. Every token is a value in the code, or user-supplied."
- 19-25 · 5 · "Writes no UI, ships no palettes, does no contrast math; glossary and ADRs belong elsewhere."
- 29-32 · 4 · Mode names plus cue phrases the description lacks.
- 47, 91, 124, 139, 302 · 1 · Cut tails.
- 118 · 1 · "audit uses the SHA through git show, else the date; keep the stamp visible."
- 169, 208 · bug · Four states, include `supplied`.
- 178, 182 · 1 · "Put anything not derivable in `omitted`."
- 192-194 · 1 · "Write a gitignored swatch sheet (token, state, absorbed values); delete it after consent."
- 222, 250, 236-238 · 1 · Delete rationale.
- 278, 320 · 2 · Delete.
- 326-331 · dup · Delete the Notes section.

### releasekit
- 14-18 · 5 · "Stops at the tag; never publishes to a registry or moves a tag."
- 20-28 · 4 · Delete; the skill is user-invoked only.
- 56-62 · 8 · Add the rulesets probe.
- 88-92 · 3 · "List calver-dropped and minority-prefix tags in the preview."
- 107, 109, 115, 118 · 1 · Rule plus "state it in the preview".
- 135, 137, 141 · 1 · Delete rationale clauses.
- 163 · bug · Add `--paginate`.
- 212-218 · dup · Delete 212, 213, 215, 216, 218; keep 214 and 219.

### debugkit
- 13-15 · 5 · Delete.
- 21, 182 · 1 · Delete the rationale passages; keep the ban.
- 25-35 · 4, 6 · "Out of scope: features nobody built (see intake bar) and 'make this faster' with no prior fast state."
- 47-49 · 1 · "Without expected vs actual, you debug an invented expectation."
- 104-108 · 1, 3 · Delete 104, 106, the 108 tail; keep the bold rules.
- 122-128 · 1 · Keep never-toggle-production as one line.
- 210-212 · 1 · "In an instrumentation plan, drop any entry with no discriminating experiment."
- 255-260 · dup · Delete Never-apply, Never-green-wash, Route-don't-launch, Route-don't-require bullets.
- Keep: `patch -R` vs `git apply -R`, and the `git checkout --` ban.

### prototypekit
- 13-15 · 5 · "Write code that answers one question; keep the answer, delete the code."
- 17-26 · 4 · Keep the uikit-mockup route and the demo pointer.
- 53-55 · 1 · Keep the box and the header-comment rule.
- 80, 94, 113, 121 · 1 · Cut tails.
- 154-161 · dup · Keep "Never unattended" and the no-shell fallback.

### promptkit
- 14, 23 · 5 · Delete both paragraphs.
- 34-42 · 4, 1 · Delete the 36 phrase list and 42 rationale; keep the `task` default and the `system` signal rules.
- 65-67 · 1 · "Each entry carries its why; cap ~30, add one by deleting one."
- 79, 86, 88, 94, 139-150 · 8 · See Stale facts.
- 137 · 1 · "Stand the entry down and name it in the diagnosis."
- 146-148 · 1 · "Deliver one prompt for the identified receiver; apply vendor conventions inside it."
- 154-156 · 1 · "Fire when the goal can't be stated without a choice the user hasn't made."
- 168-174 · dup · Delete 170 and 172.
- modes/system.md:17, 19, 34, 51, 81, 85 · 1 · Cut tails; keep 87.
- modes/task.md:7, 18, 26, 72, 80 · 1, 5 · Cut to rules; delete 7 and 72.
- worked-example.md:42 · 1 · Keep its first sentence.
- Keep: SKILL.md:27 "the model will drift toward doing the task".

### verifykit
- 13-15 · 5 · Cut to the mode summary.
- 17-27 · 4 · Keep "backend-only goes to qakit" and "ambiguous runs show".
- 35, 37 · 3 · "Diff HEAD, untracked files, and base...HEAD." Keep the base fallback.
- 87 · 6 · "A host that enforces allowed-tools strictly must grant the browser MCP; else the capture step degrades."
- 88, 92 · 2 · Delete.
- 90 · 8 · Verify; drop "deliberate later add".
- modes/show.md:12, proof.md:3 · dup · State the serial rule once in the root.
- modes/proof.md:7, 13, 34 · 6, 1 · Delete duplicate size advice; cut publish rationale.
- Register line · dup · One copy in the root.

### grillkit
- 13 · 5 · Delete.
- 17, 20 · 1 · Cut tails on reflect-back and always-recommend.
- 27 · 1 · Delete.
- 92-103 · 1, 6 · Cut each bullet to its imperative; the example round at 51-90 shows the shape.
- 110-115 · 6, 1 · "Picker mirrors the text round in order; label '(a) …'; put the pick first unless options have natural order."
- 116 · 8 · Verify AskUserQuestion limits.
- 140 · 1 · Keep the rules and the material-edit list.
- 180 · 1 · Compress Next to the route list.

### implementkit
- 13-24 · 5, 4 · "Builds from a named input; never commits or designs; retrofits go to testkit."
- 59 · 8 · Name Agent, drop Task.
- 72-75 · 3 · "TDD: per slice, see the test fail, write minimal code, refactor while green."
- 83 · 2 · "Typecheck and run the affected test file per slice."
- 86, 97, 99 · 2 · Delete; keep run-once-into-log.
- 106 · 2 · "After three failed fixes, stop and report red."
- 123, 127 · 1 · Delete.
- 163-168 · dup · Delete 163, 164, 166, 167, 168; 165 to "Invoke uikit for UI files only; no other skill."

### motionkit
- 13 · 5 · Delete.
- 21-24 · 4 · Keep the 26 tie-breakers.
- 72-81 · 3 · "One purpose: feedback, spatial, state, bridging, explanation (marketing only), delight (rare tier only)."
- 93, 115, 117, 121, 132 · 1 · Rule clauses, e.g. "`ease-in` on UI is a finding."
- 150-165 · 3 · Keep the tier table and box-shadow → drop-shadow.
- 178-180 · 3 · Delete.
- 203, 217 · 3, dup · Delete the Notes bullet; cut the personality sentence.
- vocabulary.md · 3 · Delete, or cut to about 8 non-obvious terms (rubber-banding, hold to confirm, origin-aware, perceptual duration). About 750 words.
- modes/perf.md:20-36 vs 38-52 · dup · Merge the symptom table into the cause list.
- modes/build.md:3, review.md:5 · 1, 5 · Delete the build intro; keep "expect to reject most candidates".
- recipes.md:29, 52, 65, 71 · dup · Delete rationale sentences.
- Keep: curves, duration bands, the 0.11 velocity, the 30-80 ms stagger.

### qakit
- 13-19 · 5 · "The agent runs every check with an observable pass condition; the plan keeps only human judgment, grouped by setup."
- 23 · 4 · "New automated tests: say so and stop; route to implementkit TDD or testkit, else write them beside the change."
- 30-31, 69, 92, 97 · 2 · Delete.
- 51-61 · 6, 7 · One line of dimension names, keep db/worst hooks; ask "Not covered" only for dimensions a reader would expect.
- 81, 227, 240 · 1 · Keep the rule and its test; delete defences.
- 222-223, 249, 252-253, 255 · 1, 2 · Delete 249, 252, 255; "Pre-fill date and sha; Overall result goes last; Skipped needs a Notes reason."
- 254 · 1, 6 · "Write the plan in ASD-STE100. Keep one term per thing for the whole plan."
- 256-257 · 3 · Delete the sales line and the curl tutorial.
- 268, 271 · 1 · Keep the guardrail.
- 332 · bug · Host-neutral text.
- 338-340 · dup · Delete 338, 339; 340 to "Browser MCP and render tools are outside allowed-tools; without them, page checks stay manual."
- Keep: worst.md value catalog, db.md host check, the production-read guardrail.

### commitkit
- 13, 15-17 · 5, 4 · Delete; keep the 17 routing clauses.
- 19, 119-121, 236 · 2 · Keep one line at 19: "Stage, group, commit, push without per-step confirmation; the only planned question is the branch."
- 64, 71 · 7 · Delete the record-and-compare ritual; 69's command list holds.
- 95 · 2 · Delete.
- 108 · 1 · "Chain git calls with && unless a decision sits between them."
- 112-115 · 1 · "Wrote it this session: group from the stat, body from memory. Otherwise read each group's diff separately."
- 142 · 1 · "hotfix only for a fix on a hotfix-<slug> branch; other changes there keep their own type."
- 162, 273 · 2 · Delete 162; cut 273 after "explicitly asks".
- 174-178 · 2, 6 · "One commit per logical change, tests and docs included; dependencies first; split mixed files by hunk."
- 223 · 1 · "An empty or failed gh pr view means no PR."
- 225 · 1 · "Push when origin exists and the branch tracks it or has no upstream; branch name does not gate it."
- 253 · 3 · "Build the table from the paths you staged; key files plus '+N more' when long."
- Keep: 203 zsh word-split, 209-221 park patch and the `git commit -- <paths>` warning, 169 no Co-authored-by.

### humankit
- 15, 43, 81, 113 · 1, dup · Keep "Never invent facts… Fiction excepted." once plus the step-3 audit question.
- 21 · 4 · "A review-only ask gets the detection pass, no rewrite."
- 23 · 1 · "Agent instruction files and prompts are out of scope; name promptkit or skillkit."
- 41-75 · 3 · Cut Inflated, Promotional, AI vocab, Elevated, Filler, Signposting to a name plus 3 examples. Keep full entries for metaphor nouns, colon, -ing tails, negative parallelism, false ranges, copula.
- 47, 138 · 8 · Refresh the vocabulary list.
- 89 · dup · Delete the last sentence.
- 120 · 2 · Delete "read it aloud in your head".
- 128-132 · dup · Delete.
- Keep: "What not to flag" (91-100) and the 17 honesty boundary.

### issuekit
- SKILL.md:25-35 · 4 · Delete the phrase lists; keep "If no mode is clear, ask".
- SKILL.md:50, 55, 116-118 · 1 · 50 to "Never decline because the repo seems to track work elsewhere."; one-line label-pair definitions.
- SKILL.md:99, 184, 213-228 · 2, maint · Delete maintainer notes, the gh issue comment tutorial, the third "never merge PRs", duplicated Notes 227-228.
- SKILL.md:186-197 · 1, 3 · "One lifecycle and one priority label, independent. None = unassessed. Every write replaces the sibling present."
- create.md:12-16, 69, 93, 117 · 1 · Cut defences.
- create.md:18-28 · 3, 6 · "Wide refactor: expand (ready) → migrate batches (blocked, layer on expand) → contract." Milestones only on request.
- create.md:36-42 · 1 · Keep the column definitions and "propose high, never critical".
- create.md:95 · bug · Ten lifecycle labels.
- start.md:13, 32, 41, 43, 58-60 · 1 · Keep the rule plus "refuse on the label alone, whatever the caller claims"; delete the anecdote and the warn-vs-gate essay.
- close.md:16, 24, 55-60 · 1, 2 · Reduce restated gitkit rules to conclusion plus fallback; keep the GitHub retarget fact.
- sync.md:3-8, 33, 72, 106 · 1, 2, 6 · Delete the ownership table, duplicated "never auto-close", rationale.
- triage.md:24-26, 59-65 · 1 · Keep each check's test and fix; delete 65.
- triage.md:31 · bug · Add `hotfix` to the regex.

### gitkit
- SKILL.md:13-19 · 5 · "Core is native git; stack needs gh; prepare runs only repo-declared commands."
- SKILL.md:21-33 · 4 · Delete phrase lists; keep "Not this skill".
- SKILL.md:61, 86, 219 · 1 · Cut tails.
- SKILL.md:67-81 · 3, 1 · "One branch, one worktree (git enforces it). Look up by branch through git, never by path."
- SKILL.md:167 · bug · Count.
- SKILL.md:223-244 · 1, 2 · Keep the blockquote rule and the thread-outdating fact.
- SKILL.md:302-305 · 1 · "Fixed subject with base interpolated; no --no-ff; name a concrete reason."
- SKILL.md:307-309 · 8 · See Confirmed bugs.
- SKILL.md:341-364 · 2, 1 · Delete "The cost of depth"; cut 349-358 to one line.
- SKILL.md:366-376 · 6 · Move the container section to a satellite behind a pointer.
- SKILL.md:380-381 · maint · Delete.
- clean.md:3, 67, 89-91, 107; rescue.md:3, 13, 51; stacks.md:3 · 1, 2 · Cut rationale, the sync digression, satellite preambles.
- clean.md:46 · bug · Default merge method.
- prepare.md:75-84 · 3 · Lockfile names plus "run that manager's locked install".

### plankit
- 13 · 5 · Flow sentence plus "plans only".
- 15-19 · 4 · Delete.
- 33 · 2 · Delete.
- 45-49 · 6 · Delete the variants example.
- 139-143 · 1 · Keep the vocabulary and "match loosely".
- 145-149 · dup · Delete Plan-only, Fewest-sections, Defer bullets.

### repokit
- SKILL.md:14-21 · 5 · Delete.
- SKILL.md:27-30 · 4 · Keep mode pointers and "setup does not run docs".
- SKILL.md:47-50 · 3 · Keep the failure rules only.
- SKILL.md:83, 85, 87 · 1, 2 · Delete 85, 87; cut 83.
- modes/labels.md:5-15 · 1, 6 · "Three namespaces: lifecycle and priority describe an issue (one of each at a time); automation is a PR trigger."
- modes/labels.md:34, 47, 49 · 1 · "Four levels; name the cost if asked for a fifth." Delete the projectItems paragraph.
- modes/labels.md:58-68 · 1 · Keep the grep and "adopt the listener's name".
- modes/labels.md:77, 84 · 1 · "A name match is not a meaning match: read the label description and two issues; name a severity collision."
- modes/labels.md:117-123 · 1 · Keep the crown rules.
- modes/about.md:46, labels.md:114 · 3 · Keep "create for missing, edit for drifted".
- modes/setup.md:12 · bug · autoMergeAllowed.

### skillkit
- See Propagators.
- 14 · 5 · Cut to its first sentence.
- 18, 25 · 2, 6 · Delete the ask-first and link-skim sentences.
- 111, 113, 121, 133 · 1 · Delete rationale; children copy this file.
- 144 · 1, 6 · "Pin only stable public commands, self-correcting via --help; otherwise state the goal."
- 166 · dup · Delete.

### tutorkit
- SKILL.md:14 · 5 · Delete.
- SKILL.md:20-27 · 2, 5 · Delete 22, 24, 26, 27; keep 23, 25.
- SKILL.md:31-35 · 4 · Keep intent resolution and the no-topic and ambiguous rules.
- SKILL.md:59, 63, 83, 85, 93 · 1 · "Derive the due count at read time; never store one."; cut tails.
- SKILL.md:97, 123, 133, 139, 153, 155 · 1, 3 · Delete pedagogy rationale; keep the cwd-path fact in 97.
- SKILL.md:161 · 2 · Delete.
- SKILL.md:194-197 · dup · Delete 194, 196, 197.
- lesson.md, exam.md, drill.md, status.md · 1 · Cut rationale trailers; keep rules, caps, ranking table.

### uikit
- 13-17 · 5 · "Taste is spent only where nothing else constrains the choice; see the precedence ladder."
- 19-24 · 1, 5 · "Reads DESIGN.md, never writes it; ships no palettes; audit is visual only; pre-flight never blocks."
- 30-32 · 4 · Keep pointers and the ambiguity rule.
- 49, 62, 201 · 1 · Delete.
- 84-86 · 1 · Keep the three "bold average" looks as a ban line.
- 99 · maint · Move to a contributor note.
- 211-215 · 2 · "State the missing check beside the result."
- 221-226 · dup · Delete 221, 222, 224; 223 to "Never invent data."
- modes/build.md:15, 20-21 · 6, 1 · Delete 21 and generic copy advice; keep "follow DESIGN.md voice".
- modes/audit.md:9, 10, 32 · 1, 2 · Delete.
- mobile.md:54 · 8 · iOS support.
- Keep: stack.md Tailwind v4 rename table.

### mergekit
- SKILL.md:13-17 · 5 · One line plus the merge-exception sentence.
- SKILL.md:23-26 · 4 · One phrase per mode.
- SKILL.md:37 · 1 · "A cascade takes one confirmation that names every PR, in merge order."
- SKILL.md:77-83 · dup · Delete 79-81.
- modes/start.md:5, 44-48 · dup · State sync policy once at SKILL:62.
- modes/start.md:19-25 · 3, 1 · "Ask gitkit for the head branch's worktree; reuse it, create only when none exists."
- modes/start.md:31 · dup · Delete.
- modes/start.md:56, list.md:11 · 2 · Delete.
- modes/close.md:75, 78-79 · maint, 1 · Keep "issuekit close per merged layer, bottom-up, then sync".
- modes/fix.md:5, 19 · 5, 1 · Delete 5; 19 to "Give each item a verdict before any edit; feedback can be wrong for this repo."
- Keep: `--match-head-commit`, `gh pr checks --watch --fail-fast`, GraphQL-only thread resolution.

### seokit
- SKILL.md:13 · 5 · Delete; keep 15.
- SKILL.md:31, 84; audit.md:71-75; crawl.md:58-62 · dup · Mode steps become "Run the Server lifecycle stop."
- SKILL.md:69 · 6 · "Warn that dev-server performance is meaningless and metadata routes may differ from the build."
- SKILL.md:105 · dup · Delete.
- SKILL.md:115-153 · 3 · Delete textbook Gotcha cells (NOINDEX, HTTPS, HOST, MOBILE history, ANCHOR, SOURCE, TRUST, SITE-DUP-*, SITEMAP-GAP).
- SKILL.md:196-201 · 3 · Keep the AI-visibility sampling method.
- references/site-types.md · 3 · Keep the non-obvious entries (self-ranked listicles, docs llms.txt, don't block *-User agents, scaled-content policy). About 500 words.
- references/structured-data.md:7, 31-112 · 3, 6 · Delete the three JSON-LD templates; "Fetch the search gallery before recommending a type"; keep the Gone list.
- references/international.md · 3 · Keep Next.js alternates, Bing and lang, US crawl IPs, en-UK.
- modes/audit.md:3, crawl.md:3 · 2 · Delete.

### wikikit
- SKILL.md:13-15 · 5 · Cut 13 to its first sentence; delete 15.
- SKILL.md:24-29 · 4 · One line per mode; keep the 31-33 guards.
- SKILL.md:53, 59, 121, 125, 129, 111 · 1 · Cut tails; keep the SHA → date fallback.
- SKILL.md:152-163, 105 · 3, dup · Keep "one Diátaxis mode per page" and "verified commands".
- SKILL.md:165-171 · dup · Delete 167, 168, 170, 171.
- modes/init.md:23, 37, 41 · 1, bug · Delete 23 and 37 sentences; move 41 to the root.
- modes/update.md:7, 11, 17, 35 · 1 · Cut tails.
- modes/publish.md:9, 15 · 1 · Delete.
- Keep: the probe allowlist (133-141) and publish.md's four choices.

### afkkit
- 13-15 · 5 · "Sequences issuekit → implementkit → commitkit → qakit → prkit; owns only the escalation policy."
- 24-29 · 4 · Keep "no number or all → ask".
- 44, 76 · 1 · Delete the sentence and the anecdote.
- 52, 189, 226, 306 · 1 · Cut to rules.
- 157 · dup · Step 1 becomes "invoke issuekit start; say unattended."
- 173-175 · 6 · Delete.
- 287, 292 · 1, dup · Link to The contract's authorization list.
- 311, 228, 312 · 8 · See Stale facts.
- 324-332 · dup · "No plan or grill, merge, feedback loop, or parallel batch."
- 334-338 · 1, 2 · Delete the three Notes.
- Keep: the resume table, the progress.md grammar, `rev-parse --git-path info/exclude`, the glob and PID rules.

### ideakit
- SKILL.md:14 · 5 · Delete.
- SKILL.md:24-35 · 4 · One intent line per mode; keep the 37-41 tie-breaks.
- SKILL.md:81, 87, 125, 131-133, 153, 159, 163-181, 202 tail · 1 · Cut tails; keep the 3-step gate and the cwd fact at 202.
- SKILL.md:236-244 · dup · Keep 245.
- jot.md:9, capture.md:9, status.md:11, 23, validate.md:10 · 1 · Cut rationale.

### paseokit
- SKILL.md:18-22 · 5 · Delete 22; cut 18.
- SKILL.md:30-34 · 2 · Point to "The archive call deletes directories".
- SKILL.md:38-47 · 4 · Delete phrases and 47.
- SKILL.md:66-74 · 8 · Verify Paseo facts.
- SKILL.md:256-262 · dup, maint · Keep 256's first sentence.
- modes/clean.md:3-8, 27, 67 · 5, 1 · One line; delete the metaphor and "Silence is not consent."

### validatekit
- 16 · 5 · Delete.
- 21, 138, 214 · dup · Keep 214.
- 34 · 1 · Delete the meta sentence; keep the pushback table.
- 103, 136, 140, 146 · 1 · Delete tails.
- 212 · dup · Delete.

### orcakit
- 14-16 · 5 · One sentence.
- 25 vs 215 · dup · Keep 215.
- 29-34 · 4 · Keep "If no mode is clear, ask."
- 186 · 1 · Delete.
- 265-271 · dup · Delete four Notes bullets.
- Vendor flags · 8 · Verify with `orca --help`.

### domainkit
- SKILL.md:13-15 · 5 · "Keeps CONTEXT.md and docs/adr/ current: detect, offer, write on consent."
- SKILL.md:21-23 · 4 · Keep the mode definitions and the 25 rule.
- SKILL.md:30, 46 tail · dup · Delete; 92 excludes status.
- SKILL.md:98 · dup · record.md:9 owns numbering.
- SKILL.md:123 · 3 · Delete the qualifier list.
- SKILL.md:127, 29 · dup · Delete.
- record.md:26 · 1 · "Keep this to three lines."

### handoffkit
- 16-18 · 4 · Keep the focus-argument sentence.
- 26, 80 · dup · Keep one.
- 78 · 6, 7 · Delete step 3.

### namekit
- 19 · 5 · Delete.
- 21-24 · 4 · Keep the routing rule at 26.
- 34, 45 · 8 · Verify RDAP behavior.
- 122, 144 · 1 · Delete tails.

### dbkit
- SKILL.md:13 · 5 · Delete.
- SKILL.md:17-24 · 4 · Keep each mode's write scope, the both-asks rule, Not this skill.
- SKILL.md:148-153, 98, 102, 120 · 3 · "Start in 3NF; denormalize only on a tune plan; JSON only for sparse, unfiltered attributes." Keep headings; findings cite them.
- modes/design.md:3, migrate.md:3, audit.md:3, tenancy.md:33 · 5, 2 · Delete.
- engines/postgres.md:7, 122-134, 139-140 · 3 · Keep pattern_ops, jsonb_path_ops, to_tsvector, btree_gist, the 100M threshold, PK-includes-key, DETACH.
- Keep: the connection guard (36-52), "never from memory / read --help", the lock table, the per-ORM transaction gotchas.

## Keep across the collection

- Real gotchas and hard guardrails, even when short.
- The "_Write this section in the procedural register_" lines. STE is not a model default.
- The inlined NNNN serial rules. AGENTS.md licenses them for portability.
- Notes text that `TOOLS_EXEMPT` in `scripts/lint.sh` requires.
