# Skill collection review

Date: 2026-09-07. Source commit: `4cfb24a`.

The collection needs stronger checks between skills before it needs more skills. Several instructions disagree about mutations, lifecycle state, and completion evidence.

## Scope and evidence

This review covers the 34 repository skills, with an inventory of 68 Markdown instruction files. It includes mode procedures, selected supporting code, and the wiki summaries for all 34 skills. Detailed wiki checks focus on the rules behind the findings below. It does not certify every wiki sentence or bundled third-party skill.

This is a static review with small local command probes. It does not run all 34 skills through live agent sessions. It makes no GitHub, Orca, or Paseo mutations. The temporary probe repositories are removed after the checks.

| Check | Result |
|---|---|
| `make lint` | 0 errors, 1 portability warning for repokit |
| `make security` | Completes successfully; highest reported tier is medium |
| Skill descriptions | 2,572 words across 34 descriptions; none starts with `Use when` |
| Root instruction length | 104,923 words in total; statuskit contains 10,611 words |
| Release tag selector | Misses `1.2.3`; selects `v1.3.0-rc.1` |
| `git stash create` | Returns an empty result for a clean tree and an untracked-only tree |
| Commit staging probe | A commit includes both a newly staged file and an unrelated previously staged file |

The security result is a text scan, not proof of safe execution. The repokit warning appears to concern its intended scaffold output, including `AGENTS.md`. Treat that warning as a heuristic result, not a confirmed portability defect.

## Ranked findings

P1 means repair before depending on the affected automation. P2 means a correctness or maintenance gap. Proposed improvements appear separately from confirmed instruction conflicts.

### F1. P1. Draft requests can reach mutation steps

The instruction at `skills/prkit/SKILL.md:17` says a draft-only request does everything except `gh pr create`. Later steps rebase, commit a supplied file, push, edit an existing PR, and change labels.

An existing PR makes the defect particularly clear. Skipping creation does not skip `gh pr edit`.

Commitkit has a related wording gap. Its message-only instruction excludes the final commit, while the main procedure also stages and pushes. Its separate headless draft mode has a clearer boundary.

Give draft requests an early read-only route. End that route after the title and body, or commit message. Its completion check must confirm unchanged index, refs, and remote state.

Sources: `skills/prkit/SKILL.md:17`, `:68`, `:95`; `skills/commitkit/SKILL.md:17`.

### F2. P1. Commit grouping does not isolate the existing index

Commitkit stages each group with `git add <paths>` and then runs `git commit`. A previously staged file remains in the index. The first commit can therefore contain files assigned to a later group.

The local probe stages `b`, then stages `a`, then commits. The commit contains both files. Per-path staging alone does not enforce the intended group.

Prkit has the same exposure when it commits a supplied QA file. That command can include unrelated staged work.

Record the index before grouping. Verify the complete staged set before each commit. Preserve deliberately partial staging and unrelated staged files.

Sources: `skills/commitkit/SKILL.md:111`; `skills/prkit/SKILL.md:71`.

### F3. P1. Lifecycle transitions can advertise work as ready too early

Issuekit defines exactly one lifecycle label. Prkit explicitly adds `in-review` to a `ready` issue without removing `ready`. Its explanation also says issuekit start produces this state, although start replaces `ready` with `in-progress`.

The dependency procedures have another gap. They promote a dependent after one prerequisite opens a PR or merges. They do not require every remaining prerequisite to permit that promotion.

For example, issue C depends on A and B. Merging A must not make C ready while B remains unfinished. Statuskit already defines this complete-prerequisite rule for its ranking, but the mutation procedures do not carry it.

Use one transition rule across prkit and issuekit. Replace the existing lifecycle label. Recheck all prerequisites before each dependent promotion. Report multiple incompatible stack parents instead of choosing one silently.

Sources: `skills/issuekit/SKILL.md`, Lifecycle labels; `skills/prkit/SKILL.md:138`, `:143`; `skills/issuekit/modes/sync.md:62`; `skills/statuskit/SKILL.md`, Unblock leverage.

### F4. P1. Afkkit's completion contract conflicts with its callers

Afkkit promises an unattended run through PR creation. Prkit says PR creation and a supplied-file commit still require a preview. Afkkit says a consent requirement stops the run.

Under those skill rules alone, the normal successful path can stop at the final step. A host instruction or prior user authorization can resolve this. The portable skill contract does not state that resolution clearly.

Afkkit also excludes `.afkkit/` from git, then says the PR carries the path to `assumptions.md`. A remote reviewer cannot read that local path.

Define what the unattended request authorizes at entry. Preserve separate approval for actions outside that scope. Put reviewer-relevant assumptions directly in the PR body or a committed artifact.

Add recovery states for interruption after commit, after push, and after PR creation. Adopting an existing worktree does not prove which phases already passed.

Sources: `skills/afkkit/SKILL.md:131`, `:174`, `:209`, `:245`; `skills/prkit/SKILL.md:140`.

### F5. P1. Release selection disagrees with the supported tag formats

Releasekit promises support for tags with and without `v`. Its command matches only tags beginning with `v`. It also promises to skip prereleases, but the glob accepts them.

Local results from the documented command are reproducible:

```text
Existing tag: 1.2.3
Result: exit 128, no matching name

Existing tags: v1.2.3, then v1.3.0-rc.1
Result: v1.3.0-rc.1
```

Filter tags with a complete stable-version parser before choosing an ancestor. Test both prefix styles, prereleases, unrelated tags, and maintenance branches.

The release procedure also needs explicit resume handling. A pushed tag followed by failed GitHub release creation must resume that release, rather than derive another version. Bind the CI result to the exact commit being tagged, including the finish path after a release PR merges.

Sources: `skills/releasekit/SKILL.md:64`, `:71`, `:74`, `:91`, `:126`.

### F6. P1. Probe recovery promises a snapshot that may not exist

Debugkit and testkit require `git stash create` and a recovery SHA in every hand-off. The local probe returns an empty value for a clean tree and for untracked files alone.

The per-file patch record still provides protection. The finding concerns the unconditional snapshot claim and its incomplete coverage.

Debugkit also takes a file copy before the first edit, then asks for one patch per probe. Reusing that copy produces cumulative patches after multiple edits. Reverse-applying cumulative patches can fail or reverse an earlier probe twice.

Record whether a stash object exists. Preserve untracked files separately when probes can touch them. Take each probe's patch against its immediate pre-probe state. Verify tracked content, index state, and relevant untracked files during cleanup.

Sources: `skills/debugkit/SKILL.md:147`, `:152`; `skills/testkit/SKILL.md`, The mutation ledger.

### F7. P2. Failed queries sometimes become false facts

Namekit labels a nonzero GitHub API exit as a free handle. Local `gh help exit-codes` confirms separate failure, cancellation, and authentication outcomes. These outcomes do not establish availability.

Statuskit treats an issue-query error as evidence that the project has no tracker. A network or authentication failure cannot establish that policy.

Issuekit start uses an open-only PR search, then requires distinct reports for merged, closed, and missing PRs. That query cannot distinguish those outcomes. Searching a number also needs an explicit issue-to-PR linkage check.

Use explicit states such as present, absent, unavailable, and unknown. Interpret HTTP status separately from process exit. Query all relevant PR states before classifying a prerequisite.

Sources: `skills/namekit/SKILL.md:39`; `skills/statuskit/SKILL.md:104`; `skills/issuekit/modes/start.md:18`.

### F8. P2. Visual proof lacks a reliable link to the tested revision

Verifykit starts from plain `git diff`. That misses staged changes, untracked files, and committed feature changes. Its bundle records the environment but does not require the application commit or dirty-state identity.

Prkit chooses the newest matching proof bundle. A recent filename does not prove that its screenshots match the current branch.

Resolve the change target before capture. Record the application commit, dirty state, URL, and capture time. Validate that record before embedding the bundle. Treat stale proof as stale.

Verifykit also claims that avoiding seed commands means it cannot mutate real data. Driving a create, delete, or submit flow can mutate data through the UI. Define the permitted environment and actions before those flows run.

Sources: `skills/verifykit/SKILL.md:27`, `:65`, `:101`; `skills/prkit/SKILL.md`, Embed proof artifacts.

### F9. P2. Repokit's settings rationale contradicts the workflow

Repokit says auto-merge lets afkkit finish unattended. Afkkit ends at an open PR and explicitly excludes merging. Mergekit explicitly excludes auto-merge.

The wiki repeats the same incorrect rationale. This is an example of documentation agreement preserving a shared error.

Keep or change the setting as a deliberate repository preference. Remove the claim that afkkit needs it. Describe the actual merge owner and its endpoint.

Sources: `skills/repokit/modes/setup.md:28`; `docs/wiki/skills/repokit.md:120`; `skills/afkkit/SKILL.md`, Non-goals; `skills/mergekit/SKILL.md`, Notes.

### F10. P2. Persistent records contain conflicting identity and repair rules

Three examples affect repeated use:

- Ideakit says a dated jot file is written once and never edited. Its jot mode appends later blocks to that same file. Define append-only blocks instead of immutable files.
- Tutorkit status forbids topic reads but requires repair of router fields stored inside topic files. Permit a bounded repair read or report the missing field.
- Statuskit uses `stash-0` as a stable task key. A new stash changes which entry occupies that index. Use the stash object's identity.

Also define recovery after a partial update across a log, its current-state file, and its router. A completion criterion detects disagreement but does not explain recovery.

Sources: `skills/ideakit/SKILL.md:125`; `skills/ideakit/modes/jot.md:15`; `skills/tutorkit/modes/status.md:7`; `skills/statuskit/SKILL.md:344`.

## Collection improvements

### Add repeatable behavior checks before more rules

The CI workflow runs lint and the heuristic security scan. Skillkit describes a manual live test, but the repository has no dedicated behavior fixture suite.

Start with the reproduced failures in F1 through F6. Store an input state, the requested action, expected mutations, forbidden mutations, and expected completion evidence. Keep the command fixtures separate from agent-session checks. Command tests prove mechanics; agent checks test routing and instruction use.

A useful first acceptance set contains draft-only requests, a pre-staged unrelated file, two prerequisites, both tag prefixes, and an interrupted run. Include an expected refusal and a legitimate empty result.

### Extend lint where the rule is mechanical

The linter checks whether a description contains `Use when`, although AGENTS.md requires it at the start. Skillkit teaches the older description order. Resolve the rule at its authoring source, then enforce it.

The linter removes fragments from cross-file links before checking targets. It can therefore miss a valid file with an invalid heading fragment. Its mode check searches for a backticked word rather than a declared mode. It also checks wiki mode names in one direction only.

The security script scans each `SKILL.md`, but not its mode files or bundled scripts. After mode extraction, its scope omits instructions that can perform mutations.

Add fixtures for these blind spots. Keep text warnings separate from behavior failures. A generic shell warning should not have the same practical weight as a failed recovery test.

Sources: `scripts/lint.sh:91`, `:174`, `:354`, `:498`; `scripts/security.sh`, `scan_skill`; `.github/workflows/lint.yml`.

### Reduce context by branch and by duplicate meaning

Descriptions consume 2,572 words. Gitkit uses 149, repokit 130, and issuekit 117. None follows the required leading trigger form.

Rewrite descriptions around distinct entry cases. Preserve mode coverage and test near-miss requests. A shorter description is useful only if it still routes correctly.

Promptkit, designkit, namekit, orcakit, paseokit, and testkit still keep skipped mode bodies inline. Apply the repository's branch rule to those bodies. Avoid splitting statuskit solely because it is long.

Statuskit needs a rule consolidation first. Its empty-panel rule contradicts its earlier instruction to retain empty state panels. Its two-file write claim omits its `.gitignore` edit. One authoritative table for rendering rules would make those conflicts easier to detect.

### Make standalone installation claims accurate

All 34 skills declare public visibility. Issuekit start requires gitkit, and afkkit requires several companion skills. Those are explicit dependencies despite the collection's standalone portability rule.

Choose a declared dependency contract or a sufficient plain fallback. Do not hide required installation steps in a late execution failure. Keep companion invocation distinct from a recommendation in the closing hand-off.

### Separate test coverage from test order

Implementkit supports strict TDD or no new tests. This leaves no ordinary path for implementing first and then adding focused regression tests.

Add that path inside implementkit. Keep explicit user test preferences first. Testkit should continue to own test retrofits, rather than becoming necessary after every new feature.

The fix-round exemption also needs a correctness check. A review finding can identify a defect while leaving its remedy unresolved. Named findings should not pass the design bar automatically.

## Coverage table for every skill

These rows name a concrete improvement or a case worth testing. They are not 34 confirmed runtime defects. References point to each skill's instructions.

| Skill | Main improvement or test case |
|---|---|
| [afkkit](../../skills/afkkit/SKILL.md) | Resolve PR approval inheritance; resume by verified phase; publish reviewer-readable assumptions. See F4. |
| [commitkit](../../skills/commitkit/SKILL.md) | Isolate each staged group and make message-only requests read-only. See F1 and F2. |
| [debugkit](../../skills/debugkit/SKILL.md) | Handle absent snapshots and successive probe patches. Define evidence strength for statistical proof. See F6. |
| [designkit](../../skills/designkit/SKILL.md) | Resolve extraction-only rules against greenfield proposals and token export. Separate the mode-specific permissions. |
| [domainkit](../../skills/domainkit/SKILL.md) | Test ADR number collisions and complete supersession links within one approved record update. |
| [gitkit](../../skills/gitkit/SKILL.md) | Make the worktree command implement slash flattening. Define how later sessions establish creation ownership before cleanup. |
| [grillkit](../../skills/grillkit/SKILL.md) | Invalidate a grill stamp when later plan edits change settled decisions. Bound rounds by actual unresolved decisions. |
| [handoffkit](../../skills/handoffkit/SKILL.md) | Require the workspace, branch, known revision, and unresolved verification state when the task involves code. |
| [humankit](../../skills/humankit/SKILL.md) | Test that added opinions do not change the author's position or imply an experience the author never reports. |
| [ideakit](../../skills/ideakit/SKILL.md) | Resolve jot append semantics and recover partial log/router writes. Test repeated same-day captures. See F10. |
| [implementkit](../../skills/implementkit/SKILL.md) | Support focused tests after implementation; verify acceptance coverage beyond existing green checks. |
| [issuekit](../../skills/issuekit/SKILL.md) | Check all prerequisites, replace lifecycle labels, and distinguish all PR states. See F3 and F7. |
| [mergekit](../../skills/mergekit/SKILL.md) | Bind approval to the reviewed head and named cascade. Recheck the target immediately before merging. |
| [namekit](../../skills/namekit/SKILL.md) | Treat query failures as unknown. Search the final replacement candidate after a name conflict. See F7. |
| [orcakit](../../skills/orcakit/SKILL.md) | Test workspace ownership after align makes path prefixes overlap. Recheck activity before removal. |
| [paseokit](../../skills/paseokit/SKILL.md) | Isolate version-dependent registry rules. Test duplicate archives when a retained row changes during the run. |
| [plankit](../../skills/plankit/SKILL.md) | Require acceptance observables per phase and invalidate outdated grill provenance after material changes. |
| [prkit](../../skills/prkit/SKILL.md) | Fix draft isolation, index isolation, lifecycle replacement, and proof freshness. See F1, F2, F3, and F8. |
| [promptkit](../../skills/promptkit/SKILL.md) | Split task and system procedures. Distinguish literal brackets from unresolved placeholders in the final scan. |
| [prototypekit](../../skills/prototypekit/SKILL.md) | Record ownership of exclude entries before removing them. Isolate existing staged work during the optional park commit. |
| [qakit](../../skills/qakit/SKILL.md) | Bind reused check results to the tested revision. Clarify existing-suite execution against the ban on running test code. |
| [refactorkit](../../skills/refactorkit/SKILL.md) | Handle a result containing only weak candidates. Preserve an empty recommendation without contradicting the requirement to choose one. |
| [releasekit](../../skills/releasekit/SKILL.md) | Parse supported tags correctly and resume interrupted publication. See F5. |
| [repokit](../../skills/repokit/SKILL.md) | Correct the auto-merge rationale and its wiki copy. See F9. |
| [researchkit](../../skills/researchkit/SKILL.md) | Define source refresh conditions and explicitly separate verified evidence from an offline provisional comparison. |
| [reviewkit](../../skills/reviewkit/SKILL.md) | Test untracked-only changes against the empty-diff stop. Add a usable base-ref fallback when gitkit is absent. |
| [skillkit](../../skills/skillkit/SKILL.md) | Align the description template with AGENTS.md. Add maintenance checks and repeatable routing cases. |
| [statuskit](../../skills/statuskit/SKILL.md) | Preserve unknown query states, use stable stash identities, and consolidate rendering and write rules. See F7 and F10. |
| [testkit](../../skills/testkit/SKILL.md) | Handle absent snapshots and separate valid overlapping test failures from overly broad assertions. See F6. |
| [tutorkit](../../skills/tutorkit/SKILL.md) | Resolve router repair permissions. Derive due counts as time advances, rather than trusting an old stored count. See F10. |
| [uikit](../../skills/uikit/SKILL.md) | Constrain the required visual signature to settled behavior. An autosave example must not silently replace a specified Save action. |
| [validatekit](../../skills/validatekit/SKILL.md) | Ensure every stage supplies the demand evidence required by its verdict rule. Later-stage question sets omit Q1. |
| [verifykit](../../skills/verifykit/SKILL.md) | Resolve the full change target, record the tested revision, and bound state-changing flows. See F8. |
| [wikikit](../../skills/wikikit/SKILL.md) | Test wiki rewriting for source links outside the doc map and for non-Markdown assets. |

## Missing coverage worth adding

The first missing capability is collection maintenance with repeatable behavior evidence. Put it inside skillkit or repository tooling. It does not need another skill name.

Other gaps deserve explicit ownership before a new skill:

- Performance improvement without a regression has no clear measurement workflow. Debugkit explicitly excludes it. Start with a bounded prototype and a settled implementation task.
- Incident response, deployment execution, and rollback execution have no dedicated owner. Wikikit can document runbooks, but it does not execute them.
- Multi-package releases are an explicit releasekit refusal. Keep that refusal until actual project demand justifies the additional version model.

These are capability gaps, not evidence that the collection should grow immediately.

## Recommended order

1. Repair draft isolation and commit index handling in prkit and commitkit.
2. Repair lifecycle transitions and multi-prerequisite checks.
3. Repair release selection and probe recovery.
4. Resolve afkkit's authorization and resume contract.
5. Add behavior fixtures for those repairs.
6. Consolidate descriptions, mode files, and wiki claims against the tested contracts.

Keep the collection's existing strengths. Preserve explicit empty results, separation of diagnosis from fixes, declared coverage limits, and one recommended next action.

## Hand off

This review adds one report. It changes no skill, script, wiki page, or remote state.

The report is `docs/reviews/review-skill-collection-2026-09-07.md`.

Start with F1 and F2 in prkit and commitkit. Use `implementkit` to apply those findings, or make the focused edits directly.
