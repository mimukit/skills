# Skill collection review: follow-up

Date: 2026-10-02. Source commit: `3cd7fde`. Previous review: [0001-review-skill-collection-2026-09-07.md](./0001-review-skill-collection-2026-09-07.md) at `4cfb24a`.

The collection does not need more skills yet. It needs three things first. The P1 defects from review 0001 are still open, the hand-offs between skills have breaks, and lint does not check the rules that would have caught most of the new findings.

## Scope and method

This review covers all 34 skills, their satellite files, their wiki pages, `scripts/lint.sh`, README, IDEAS.md and `skills.sh.json`. Four read-only agents did the audit in parallel. One rechecked every finding in review 0001, and three audited groups of skills for new issues. I checked a sample of the agent claims against the files. I removed one claim because it was false: the sentence at `issuekit/modes/create.md:38` is complete.

| Check | Result |
|---|---|
| `make lint` | 0 errors, 1 warning (the old repokit portability heuristic) |
| `make security` | worst tier Med, the same as before |
| Descriptions | 2,638 words for 34 skills. 0 of 34 start with "Use when". repokit has 1,088 characters. |
| Skills with `disable-model-invocation: true` | 11. Their descriptions do not load in Claude Code, so the always-on budget there is about 1,722 words. |
| Behavior tests (trigger cases, fixture runs) | none exist |
| Commits since review 0001 | 20, of which 4 fix review findings |

## Status of review 0001

One finding is fixed, two are partly fixed, and seven are still open. Three probes were run again, and they give these results:

- **commitkit index isolation (F2):** the defect still reproduces. If `b` is staged first and then `a` is committed as a group, the commit contains both files.
- **`git stash create` (F6):** the command still returns an empty result on a clean tree and on a tree with only untracked files.
- **releasekit tag resolver (F5):** the two reported cases are fixed. The resolver still picks `2026.08.01` and `v1.4.0.bak` as releases.

| Id | Status | What remains |
|---|---|---|
| F1 draft requests reach mutations | open | `prkit:17`, `commitkit:17`. A draft still rebases, pushes, and edits labels. |
| F2 commit grouping uses the whole index | open | `commitkit:114`, `prkit:71` |
| F3 lifecycle transitions | partial | Label replacement is fixed (`prkit:140`). The all-prerequisites check is still missing in `issuekit/modes/sync.md:62`, `close.md:31` and `prkit:146-153`. |
| F4 afkkit completion contract | open | `afkkit:209` stops at the prkit consent gate. `afkkit:131` points the PR body at the git-excluded `.afkkit/`. There is no per-phase resume. |
| F5 release tag selection | partial | There is no stable-semver parser, no resume after a tag is pushed and the release step fails, and CI is checked on the base head (`:129`), not on the tagged commit. |
| F6 probe recovery snapshot | open | `debugkit:147`, `testkit:202` |
| F7 a failed query is read as a fact | open | `namekit:39`, `statuskit:104`, `issuekit/modes/start.md:18` |
| F8 visual proof and the tested revision | open | The verifykit mode split did not change this. |
| F9 repokit auto-merge rationale | fixed | |
| F10 write-once and append conflicts | open | ideakit, tutorkit, statuskit |

Of the per-skill rows in review 0001, only repokit is fixed. Releasekit, paseokit, issuekit and prkit are partly fixed. All other rows are still open.

## New findings

P1 means repair before you depend on the affected flow. P2 means a correctness or maintenance gap. P3 means polish.

### P1

**N1. No attended route leads from implement to review or QA.** `implementkit:104` crowns commitkit, and `commitkit:161` crowns prkit. reviewkit has no `Hand off` section, and its close at `:120-132` routes only fixes. `qakit:276` names no next kit, but `prkit:68` expects a QA plan path from a caller. Only afkkit runs review and QA in sequence. In attended work, the two skills that check agent output are reached only from memory. Fix: make reviewkit the implementkit runner-up, route a reviewkit `ready` verdict to qakit or commitkit, and pass the qakit plan path to prkit.

**N2. afkkit's commit step breaks its own success path.** afkkit commits through commitkit (`afkkit:144,172`), and commitkit pushes by default (`commitkit:127`). If the base moved, prkit then needs a preview to rebase a published branch (`prkit:61`), and afkkit escalates every consent gate (`:209`). So every such run escalates at the PR step, and the branch is already on origin. This contradicts `afkkit:21`, "never publishes half-broken work". This cause is separate from F4. Fix: give commitkit a no-push flag for callers.

**N3. Three skills remove merged worktrees under different rules.** `gitkit/clean.md:91` says "Never a batch yes" and `:105` allows only `-d`. `paseokit:303` takes one confirmation for the set and calls it "the mergekit rule", but `mergekit:36` says "Never a batch". `paseokit:321` allows `-D` after a squash merge, and `orcakit:187` says "One OK covers the batch". The candidate tests differ too: `orcakit:167` rejects an open issue, and `paseokit:293` accepts it. gitkit is the git layer, so the other two skills should cite its rule and not restate their own.

**N4. Nothing moves `needs-planning` back to `ready`.** `afkkit:193` says to re-run once the issue is `ready` again, and `issuekit/modes/create.md:132` says to re-run `create`. The duplicate guard at `create.md:47` skips existing titles, so the re-run changes nothing. grillkit stamps only the plan file, and issuekit `triage` only demotes. An escalated issue stays stuck until someone changes the label by hand.

**N5. releasekit does not know the `hotfix` type.** commitkit, prkit and issuekit write `hotfix(scope):` (`commitkit:67`, `prkit:86`). The bump table at `releasekit:83-88` and the changelog sections at `:105` do not list it. A patch that holds only hotfix commits hits the "nothing user-visible" refusal at `:98`. The mapping for `perf`, `docs` and `refactor` is not defined either.

### P2

**N6. ideakit hands off to a skill the model cannot invoke.** `ideakit/modes/validate.md:3` dispatches to validatekit, but `validatekit:6` sets `disable-model-invocation: true`. In Claude Code the call fails, or the mode silently uses its short fallback. validatekit's description also says "proactively whenever someone describes a new product", and that can never happen.

**N7. wikikit `update` stamps pages it did not verify.** `wikikit/modes/update.md:25` says "Re-stamp every page touched" after a fix to one claim. The stamp asserts a full re-read, and AGENTS.md says a stamp bumped as a formality launders an unverified page. `wikikit:122` gives the correct rule for adopted pages, and `update` contradicts it.

**N8. `wikikit:155` says "No unmixed modes."** The rule means "no mixed modes", so as written it bans what it wants.

**N9. skillkit produces skills that fail this repo's lint.** `skillkit:57` updates the README table and `skills.sh.json` only. It does not add the wiki page, the `.wikimap.yaml` entry, the `index.md` link, or run `make cheatsheet`. Its layout advice says "prefer one file" and does not mention the `modes/<mode>.md` shape. Its description template (`:73`) follows AGENTS.md's template, which contradicts AGENTS.md's own "front-load" rule.

**N10. handoffkit cannot compute its file serial.** `allowed-tools: Read, Write` (`handoffkit:7`) gives no tool that lists a directory. `:72` requires the agent to list `docs/handoffs/` for the next `NNNN`. A host that enforces the field gives every handoff `0001`.

**N11. designkit `audit` writes files.** The shared extraction engine writes a swatch HTML file and edits `.gitignore` (`designkit:179-181`), but `audit` says "Writes nothing, ever" (`:241`). The "Token sync" section (`:269-279`) has no mode and no trigger, so it fires only from one hand-off line.

**N12. promptkit review-only still writes a file.** `promptkit:52` offers review-only in both modes, but the `system` steps at `:185` and `:201` always write `docs/prompts/...`.

**N13. issuekit `close` ignores `stacked` dependents.** `close.md:307` finds dependents by body text and moves only `blocked → ready`. prkit already moved them to `stacked` when the PR opened (`prkit:152`). Only `sync.md:76` handles `stacked → ready`.

**N14. statuskit never crowns a `stacked` or `needs-planning` issue.** Rung 8 (`statuskit:195`) crowns only `ready`, and rung 9 sends all other issues to triage. A `stacked` issue can be started, and a `needs-planning` issue belongs to grillkit.

**N15. debugkit's hand-off to implementkit does not match implementkit's contract.** `debugkit:228` says implementkit "starts from your red test". implementkit's fix round takes review findings (`:30`) and gates on the existing suite only. Nothing keeps the red test or checks that it turns green.

**N16. The `blocked` label text is not the same in its three copies.** The source is `repokit/modes/labels.md:25`. The example at `labels.md:105` and the copy at `issuekit:142` add "(see 'Blocked by #N' in the body)". A run that copies the example creates drift that the next run reports.

**N17. The repokit update-branch rationale is false.** `repokit/modes/setup.md:114` says the setting serves "the sync mergekit runs". mergekit `start` never syncs, and GitHub's button merges the base in, which gitkit forbids (`gitkit:163`). The wiki page repeats this claim. This row is separate from F9.

**N18. Completion criteria are absent from most procedures.** No step in commitkit, mergekit's four modes, issuekit `start`, `close`, `sync` and `triage`, afkkit, handoffkit, plankit or researchkit ends on a "done when" bound. Examples: `handoffkit:66` "Keep it tight", `plankit:24` "Enough to draft, no more", `commitkit:104` "map the changes to logical groups". namekit (`:68`, `:81`, `:96`) shows the form to copy. A bound such as "every changed path sits in exactly one group" would also have caught F2.

**N19. qakit carries its database rules on every run.** About 35 lines apply only when the diff touches the data layer (`qakit:36`, `:105-107`, `:247-263`). By the branch test, they belong in a `db.md` satellite.

### P3

- `repokit:32` says "Present the three modes", but repokit has four.
- `gitkit/clean.md:121` hands off to `orcakit clean` and `paseokit sync`, but both tools prune by themselves. `orcakit:257` and the orcakit wiki say Paseo prunes nothing, and `paseokit:18` says it has pruned since 0.7.
- `issuekit/modes/close.md:337` crowns the most recently updated `ready` issue. The other modes crown by priority.
- `issuekit/modes/triage.md:3` says "act on approval", but `:29` and `:44` apply fixes without a gate.
- `releasekit:146` gives the release PR no title. Use the `chore(release): vX.Y.Z` subject that the finish phase looks for.
- `afkkit:144` falls back to `git add -A`, and `commitkit:56` forbids it.
- `prkit:51` uses `fix/login-123`, but gitkit defines no slash form. `statuskit:189` routes to `mergekit <N>`, which is not a mode.
- The ideakit hand-off rule "a jot run → no next step" (`:211`) takes precedence over the promote signal at the exact moment the third entry lands. Cross-idea `status` has states where no crown rule fires.
- tutorkit declares `Task, Agent` and never dispatches a subagent. The `explain` mode has no hand-off rule.
- domainkit: `Status` is optional (`:100`), but supersession flips it (`:41`, `:56`). The wiki shows the title as `# NNNN — <Title>`, and the skill shows `# NNNN: <Title>`.
- verifykit `proof` uses ffmpeg, but `setup` does not check for it. On a backend-only change, verifykit stops and does not route to qakit.
- refactorkit routes to grillkit and implementkit and skips plankit, so the proposal never becomes a plan with phases.
- Prohibition text that lists the forbidden thing: `refactorkit:59` lists `*Mapper`, `*Service`. `validatekit:28` quotes its five banned phrases. researchkit states "never build" five times.

### Wiki and README drift

- `docs/wiki/skills/gitkit.md:175` says gitkit has no hand-off, but SKILL.md, `clean.md` and `rescue.md` each have one.
- `docs/wiki/skills/issuekit.md:118` and the cheatsheet say `start` accepts only `ready`, but it accepts `stacked` too.
- `docs/wiki/skills/skillkit.md:107` shows artifact names without the serial. The commit `3cd7fde` touched many skills, so the single-skill lint warning did not fire.
- The prkit wiki page omits the issuekit `start` hand-off. The qakit wiki page says "three commands it will never run", and the skill says two.
- The README gitkit row omits sync, cleanup, recovery and stacks. The repokit row omits `docs`. The afkkit row says "grilled", and the description says "groomed".
- `index.md` groups differ from the `skills.sh.json` groups.

## Descriptions

The descriptions disagree with AGENTS.md, and AGENTS.md disagrees with itself. The rule says "front-load an English Use when trigger", and the template says `<what it does>. Use when …`. Every skill follows the template. I recommend that you change the rule to match the template, add a position cap and a length cap to lint, and leave the 34 descriptions as they are.

Two descriptions need work regardless:

- **repokit** has 1,088 characters, which is over the 1,024 limit that I recall from the Agent Skills spec. Check the spec to confirm. Its trigger starts at character 562.
- **ideakit** has no trigger for its `close`, `research` and `validate` modes. This is the coverage failure that AGENTS.md calls the expensive one.

Synonym padding is heaviest in repokit, gitkit, tutorkit, issuekit and ideakit. Eight descriptions also repeat scope disclaimers that their bodies state ("never edits code", "not a demo generator"). For the 11 skills that the model cannot invoke, the trigger lists cost nothing in Claude Code but still cost on other hosts.

Trigger words that collide across skills are "test" (six skills), "review", "plan", "audit", "status" and "pressure-test". The sharpest collision is grillkit "pressure-test an idea" against validatekit "pressure-test my startup idea". validatekit is invocation-only, so a model-routed request always goes to grillkit.

## Tooling gaps

Lint checks structure well. It does not check the rules behind most findings in this review. These checks can be added, and each one would have caught a real finding:

1. "Use when" position and a description length cap (repokit).
2. A skill with `disable-model-invocation: true` must not be a dispatch target and must not say "proactively" (N6).
3. Wiki stamp date against the last commit to the skill, on every run (the skillkit page drift). Four pages are stale today: domainkit, skillkit, ideakit and promptkit.
4. The three beats inside `Hand off`, with a `Next` line at minimum (reviewkit has no hand-off and lint accepts its section names).
5. Declared tools that the skill never uses (tutorkit), and tools that a step needs but the skill does not declare (handoffkit). This check is a heuristic warning.
6. README table, `skills.sh.json` groups and `index.md` groups in parity. IDEAS.md rows that name a shipped skill.

The larger gap is still behavior testing. No trigger cases or fixture runs exist. Review 0001 named this as the top missing capability, and none of the 20 commits since then started it. Without it, a fix to F1 or F2 cannot be shown to hold. Start with fixture scripts for the four probes that reproduce today (commitkit index, stash snapshot, release tags, lint drift), and put them under `scripts/` or behind a `make test` target. Add trigger cases for the collision words after that.

## Capability gaps

Lifecycle coverage from idea to release is complete for the happy path. The gaps are in the paths around it.

| Gap | Owner I recommend | Reason |
|---|---|---|
| Revert a merged PR | a `revert` mode in prkit, with issuekit reopening the issue | prkit writes a Rollback line, but nothing executes it |
| PR closed without merge | issuekit `sync` | the issue stays `in-review`, and only dependents are handled |
| Hotfix flow | releasekit, after N5 | gitkit names the branch, but nothing cuts the patch release |
| Dependency upgrades and codemods | a new skill, for example `upgradekit` | a distinct, deliberate moment. It reads changelogs for breaking changes and applies edits behind a gate. No current skill does both. |
| Security review | a `security` mode in reviewkit | the agent can pick it from the request wording, so it does not need a new name |
| Performance work | a profiling branch in debugkit | it keeps diagnosis separate from the fix, and implementkit does the fix round |
| Data migration and rollback | a conditional section in the plankit format, plus a check in reviewkit | no new skill |
| CI workflow and required checks | a mode in repokit | repokit already owns the repository settings |
| Deploy, rollback, incident | no owner yet | wait for real demand, as review 0001 says |

For the IDEAS.md backlog, apply the two-loads gate:

- **evalkit earns a skill.** It is a distinct moment, and promptkit refuses this job by design. Keep it apart from this repo's own skill tests, which belong in `scripts/`.
- **jobkit earns a skill.** It sits outside development work, so consider `internal: true` or another collection.
- **seokit is not ready.** It needs a defined scope and output first.
- **banglakit is a humankit mode.** The language follows from context, so a person does not need to choose it. Add a disclosed Bangla tells catalog to humankit.

## Recommended order

1. Fix F1 and F2 in commitkit and prkit, and add the commitkit no-push flag (N2) in the same change.
2. Add the review and QA hand-offs (N1).
3. Put the worktree removal rule in gitkit only, and make paseokit and orcakit cite it (N3).
4. Fix the lifecycle set together: F3 prerequisites, N4, N13 and N14.
5. Fix releasekit: F5 remainder and N5.
6. Add the fixture scripts and lint checks 1 to 3 from Tooling gaps.
7. Fix the P2 rows that are local edits: N6 to N12, N16, N17, N19.
8. Fix the wiki and README drift. Re-stamp only the pages that someone re-reads.
9. Add completion criteria (N18), one skill at a time, starting with plankit and commitkit.

Leave the new capabilities until steps 1 to 6 are done. The collection is strong where it states empty results and keeps diagnosis apart from fixes. Its weak point is the hand-off between skills, and new skills add more of those.

## Resolution

Updated 2026-10-03. Every finding in this report and every open row of review 0001 has an edit in the working tree. The edits are not committed. `make lint` reports 0 errors and 0 warnings, and lint now enforces the six checks under Tooling gaps.

These items stay open:

- The capability gaps are proposals, not defects. No new skill or mode was added for them.
- There are still no behavior fixtures. skillkit now writes trigger cases for a new skill, but no runner executes them.
- The wiki stamps did not move. Re-stamp each page after the commit lands on `main`.

## Hand off

This review adds one report. It changes no skill, script, wiki page or remote state.

The report is `docs/reviews/0002-review-skill-collection-2026-10-02.md`.

Next, fix F1, F2 and N2 in commitkit and prkit. Use implementkit with this report as input, or make the edits directly.
