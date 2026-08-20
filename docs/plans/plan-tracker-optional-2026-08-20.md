# Plan: tracker-optional workflow

Grilled: 2026-08-20

## Context

The collection assumes a project manages its work in GitHub Issues. That assumption is invisible until it is wrong, and then it fails two ways at once.

`statuskit` dead-ends. Its full ladder has 8 of 12 rungs referencing issues, and when `gh` works but the project keeps no issues, every one of those rungs passes and the ladder crowns nothing. This repo hit it on 2026-08-20: zero issues have ever been opened here, and the run had to improvise a next move out of `IDEAS.md` because the ladder produced none.

`plankit` and `grillkit` route everyone to `issuekit`. plankit's Hand off says "Turn the hardened plan into GitHub issues" with no branch, and its overview frames the whole collection as "plankit drafts, grillkit hardens, issuekit files". grillkit's Hand off crowns the same move and only falls back when there is no plan file at all. A team planning in Linear gets told, every single run, to go file GitHub issues.

The collection already degrades well on two axes and has no third. **Capability** is covered: eleven skills handle `gh` missing or unauthenticated. **Installation** is covered: the route-don't-require rule appears in statuskit, testkit, refactorkit and debugkit. **Policy** is not: a repo where `gh` works, Issues are enabled, and the team tracks work somewhere else reads as a tracker in use. One line in the whole collection names that case (`statuskit` line 132, on Linear, Jira and `TODO.md`) and it gates a single panel.

Detection alone cannot close the gap. A repo with zero issues might track work in Jira or might have been created yesterday, and those want opposite advice. A repo with forty open issues might be taking user bug reports while every planned change lives in Linear.

Success means a project that files no GitHub issues gets a crowned next move from `statuskit`, gets a hand-off from `plankit` and `grillkit` that names something it can actually do, and is never told to go file issues in a tracker it does not use. A project that does file issues sees no change at all.

### What the grill established as fact

Four facts came out of reading the repo rather than reasoning about it, and two of them reshaped the plan.

- **issuekit already annotates plan phases.** Its write-back step turns `### Phase 2: auth` into `### Phase 2: auth (#41)`. The plan format has an annotation slot, and trackerless projects leave it empty. That slot became the seam this plan builds on.
- **A hand-maintained completion marker already rotted here.** `docs/plans/plan-mergekit-2026-08-01.md` line 3 still reads `Status: draft, 2026-08-01. Not yet built.` mergekit shipped weeks ago. That killed the option of asking a human to maintain a status line.
- **Phase headings are strongly conventional.** Over 100 instances of a `Phase <n>` heading across the 27 plans, though the separator varies between an em dash and a colon. Machine-findable if the match ignores the separator.
- **implementkit never writes to the plan.** It reads the plan, writes code, runs the gate, and stops. Stamping is a new responsibility, not an extension of one.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| How a skill learns whether GitHub Issues are in use | A **precedence ladder**: the prompt, then a declaration in the repo's agent-guide file, then detection from `gh`, then treat it as unknown and name both paths. Reuses implementkit's existing `prompt → CLAUDE.md → repo habit → ask` shape and the "follow the repo over these defaults" line that debugkit, refactorkit, testkit and statuskit already carry. |
| What the work list is when there is no tracker | **The plan document.** `docs/plans/plan-<slug>-YYYY-MM-DD.md` is already phase/task-shaped, because that is precisely the structure `issuekit create` decomposes into issues. It needs no new artifact and no second thing to keep honest. |
| Who states the ladder in full | **statuskit**, in a short `Resolving the tracker` section under its Preflight. AGENTS.md licenses restating a conclusion and forbids restating a derivation, so it lives in exactly one place. statuskit is the only skill that must *resolve*, because it crowns one move; the others carry a one-line conclusion. Splitting the ladder between issuekit and statuskit was rejected as the scattering failure AGENTS.md names by hand. |
| Whether issuekit resolves anything | **No.** Invoking `issuekit create` is the top rung answering itself: a user who asks for issues wants issues. issuekit gets one line saying so. |
| Whether statuskit calls issuekit to ask | **No.** statuskit's Notes defend `Skill` being reserved for gitkit, and pulling an 8,074-word tracker skill into a read-only survey costs more than the answer is worth. statuskit already makes the `gh issue list --state all` call. |
| How many ladders statuskit keeps | **Two, unchanged.** The trackerless case is the full ladder with its issue rungs gated off, which is exactly how the git-only ladder already relates to the full one. |
| What fills the gap the gated rungs leave | **Promote git-only rung 5 into the full ladder**, gated on no tracker in use. That rung already exists and already says the right thing. |
| What "no issues at all" means | **Unknown, not "no tracker".** A day-one repo and a Jira repo produce the same empty array. Unknown routes like no-tracker (never assert a plan is unfiled, never crown "go file issues") and names both paths in one line. |
| Whether to probe for lifecycle labels | **No.** A `gh label list` tiebreak on the empty case buys a sharper word rather than a different action, spends a rule on a repo state that lasts a day, and misreads a template-provisioned label set nobody uses. |
| How statuskit tells a built phase from an unbuilt one | **implementkit stamps the phase heading**, in the same slot issuekit writes `(#41)` into: `### Phase 2: auth (built 2026-08-20)`. One annotation seam in the plan format, two vocabularies, no inference from git history and no human-maintained status line. |
| Whether implementkit stamps conditionally | **Always.** A tracked phase reads `### Phase 2: auth (#41) (built 2026-08-20)`, where the number says where it is tracked and the stamp says it is done. implementkit stays tracker-ignorant, which is what keeps the resolver count at one. |
| Who documents the annotation slot | **plankit**, in its plan-doc format. plankit states outright that it owns the canonical structure, and issuekit's `(#41)` arguably belonged there already. No AGENTS.md entry: public skills cannot read it, and the collection-audit plan set the precedent that a collection-wide convention waits for a third occurrence. |
| What happens to plans predating the stamp | **Per-plan opt-in.** A plan carrying at least one stamp is authoritative, so its unstamped phases are genuinely unbuilt. A plan carrying none makes no claim, and statuskit falls back to crowning the newest plan wholesale, exactly as its git-only rung already says. No date cutoff and no backfill, so the convention migrates itself one plan at a time. |
| How implementkit is told which phase to build | **One clause, no new syntax.** Widen its input to "a plan file, optionally narrowed to one phase". "Implement phase 3 of `plan-x.md`" already parses as a named input plus a section. |
| Whether statuskit writes the declaration | **Yes, previewed.** On an unknown reading, with a user present, statuskit offers to append one sentence to the repo's existing agent-guide file. It fires once per run, ranks as a runner-up rather than the crowned move, and never fires in an unattended run. |
| statuskit's mutation stance | **Narrowed to the boundary that holds.** statuskit never mutates git or GitHub state. It writes two local files: its gitignored snapshot always, and one declaration line on approval. That was always the true property, since it already writes the snapshot. |
| Which file the declaration lands in | **The one that already exists**, preferring `CLAUDE.md`, then `AGENTS.md`, then the repo's equivalent. Never create one. With no such file, print the line for the user to place. |
| Snapshot key for a plan-phase move | `plan-<slug>-phase-<n>`. The fixed key vocabulary has `plan-<slug>`, which collides when one plan has four unbuilt phases and the one-task-per-checkbox rule splits them into four items. |
| Scope | Six skills and their six wiki pages: statuskit, plankit, implementkit, grillkit, issuekit, afkkit. prkit already skips cleanly when a PR references no issue, and mergekit already falls back to plain `gh` calls, so neither needs an edit. |

## Approach

Reuse first. Every mechanism this plan needs already exists in the collection: the precedence-ladder shape from implementkit, the agent-guide read from four skills, the conditional hand-off phrasing from plankit and grillkit, the plan-doc rung from statuskit's own git-only ladder, the tracker-in-use check from statuskit line 132, and the phase-annotation slot from issuekit's write-back step. Nothing here is a new pattern. The work is extending one fact's reach and giving one existing slot a second vocabulary.

Phases 1 and 2 are independent and can run in either order. Phase 3 depends on Phase 2 for the format line. Phase 4 depends on nothing. Phase 5 runs last because it documents the rest.

### Phase 1: statuskit resolves the tracker question (built 2026-08-20)

The load-bearing phase.

1. **Add `Resolving the tracker`** as a short section under Preflight, stating all four rungs in full: the prompt, a declaration in the agent-guide file, detection from the `gh issue list --state all` call the survey already makes, then unknown. This is the one place the derivation lives.
2. **Gate the issue rungs.** Full-ladder rungs 0, 3, 7, 8, 9 and 10 fire only when a tracker is in use. Rungs 1, 2, 4, 5 and 6 are PR and git rungs and are untouched.
3. **Promote the plan rung.** Rung 8 becomes a pair: a `ready` issue to start when a tracker is in use, or the next unbuilt phase of the newest plan when there is none, routed to `implementkit`.
4. **Read the stamps.** Find phases by a heading beginning `Phase <n>`, matching the separator loosely, since the 27 plans here use both an em dash and a colon. A phase is built when its heading carries a `(built …)` stamp. Apply the per-plan opt-in rule: a plan with no stamp anywhere makes no claim, so crown it wholesale rather than claiming its phases are unbuilt.
5. **Gate the panels.** The Issues panel already reads "(omit without gh)"; extend it to omit when no tracker is in use and say why once on the line. The Plans panel keeps its name, its suppression rule and its role as a finding; only the definition of a finding widens, so an unbuilt phase with nowhere to file it prints there.
6. **Add the declaration offer.** On an unknown reading only, with a user present, offer to append one sentence to the repo's existing agent-guide file. Preview it, rank it as a runner-up, fire it at most once per run, and skip it entirely in an unattended run or when no such file exists.
7. **Restate the mutation Note** to name the boundary that holds: no git or GitHub state ever changes, and two local files can.
8. **Add the snapshot key** `plan-<slug>-phase-<n>` to the fixed key vocabulary.

Done when a run against this repo crowns a real move without improvising, a run against a repo with open issues produces today's dashboard unchanged, and a run against a repo with zero issues says the reading is unknown and offers the declaration.

### Phase 2: plankit owns the annotation slot and branches its hand-off (built 2026-08-20)

1. **Document the slot** in the plan-doc format: a phase heading may carry a trailing annotation, `(#41)` written by issuekit and `(built YYYY-MM-DD)` written by implementkit, and both may appear together.
2. **Branch the Hand off.** The issuekit bullet gains its trackerless twin, building straight from the plan with implementkit.
3. **Soften the overview.** The "plankit drafts, grillkit hardens, issuekit files" framing gains a clause so the third step is not stated as universal.

Done when the plan-doc format names both vocabularies and the Hand off names both destinations.

### Phase 3: implementkit stamps what it builds (built 2026-08-20)

1. **Widen the input** by one clause: a plan file, optionally narrowed to one phase.
2. **Stamp after the gate passes**, on the phases actually built and no others, writing `(built YYYY-MM-DD)` into the slot Phase 2 documents. Leave the edit uncommitted so commitkit picks it up with the code.
3. **Say it in the hand-off**, so the user knows the plan file changed alongside the source.

Done when a run that builds one phase stamps that phase and leaves the rest alone.

### Phase 4: grillkit, issuekit and afkkit state the boundary (built 2026-08-20)

1. **grillkit.** The Hand off's Next beat names both destinations: the `Grilled:` stamp unlocks `ready` issues when the project files issues, and unlocks the build itself when it does not. The stamp is provenance, not a tracker artifact, so it does not change.
2. **issuekit.** One line in Preflight: an explicit invocation answers the tracker question, so `create` files issues without asking whether the project files issues.
3. **afkkit.** The hard issuekit requirement stays, for the stated reason. Its refusal gains the real cause: afkkit needs a tracker rather than just a kit, because its whole safety property is the `ready` label. A project with no GitHub tracker cannot run afkkit, and saying that plainly beats a missing-dependency message that reads as an install problem.

Done when no Hand off in the collection names issuekit as the only next step, and afkkit's refusal names the tracker.

### Phase 5: wiki pages (built 2026-08-20)

Update `docs/wiki/skills/` for all six skills, per the AGENTS.md rule that a changed rule, guard, default or hand-off target obliges a page edit. Each page explains why the branch exists rather than restating the branch. Re-stamp only the pages actually re-read.

Done when `make lint` passes and each of the six pages describes the skill as it now behaves.

### Rejected alternatives

- **Detection only.** One line per skill and no new convention, and it silently misreads a day-one repo as trackerless and a bug-report repo as tracked.
- **A `TODO.md` the kits maintain.** Gives statuskit real rows, and it is a new artifact competing with whatever the project already keeps.
- **A new `trackerkit`.** Fails the AGENTS.md gate, since nobody sits down and chooses to run it. `IDEAS.md` also records `trackerkit` as already merged into issuekit.
- **Say there is no tracker and stop.** Honest and cheap, and it leaves statuskit crowning nothing, which is the failure being fixed.
- **A hand-maintained `Status:` line per plan.** The precedent exists in this repo and already went stale.
- **Inferring built phases from git history.** No convention needed, and statuskit is read-only and cheap by design, and the inference is unreliable.

## Non-goals

- **No Linear, Jira or Asana integration.** The collection learns that GitHub Issues are not the tracker; it never learns to read the one that is.
- **No new skill.** Not `trackerkit`, and no new mode on an existing kit.
- **No change to prkit, mergekit, repokit, orcakit or paseokit.** The first two already degrade correctly. The last three are repo-metadata and worktree-linking skills that already handle `gh` being unusable and block no workflow.
- **No relaxation of afkkit's issuekit requirement.** Unattended runs keep needing the `ready` guard.
- **No config file or schema.** The declaration is one prose sentence in a file agents already read.
- **No backfill of the 27 existing plans.** The stamp convention is opt-in per plan by design.
