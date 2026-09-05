# Cheatsheet

Every skill and every mode, one line each. This is the recall page — what exists, and what each mode does — not the explanation. For how the skills compose into one loop, read [the workflow](./workflow.md); for a skill in full, follow its name to its page.

| Skill | What it does |
|---|---|
| [`afkkit`](#afkkit) | Run a groomed `ready` GitHub issue through the whole build span unattended: worktree, implement, commit, verify-and-review, fix, QA plan, and open PR. |
| [`commitkit`](#commitkit) | Create git commits with Conventional Commits messages derived from the actual diff. |
| [`debugkit`](#debugkit) | Chase a symptom to its true cause — reproduce it, shrink it, write falsifiable hypotheses, and prove the cause by toggling the symptom on and off — then hand over a failing reproduction instead of a fix. |
| [`designkit`](#designkit) | Derive a project's design system from the UI it already ships and keep it true as the code moves — a spec-compliant `DESIGN.md`, validated by the official linter. |
| [`domainkit`](#domainkit) | Maintain a project's domain model as a consented byproduct of design work — a `CONTEXT.md` glossary and `docs/adr/` decision records. |
| [`gitkit`](#gitkit) | The shared git layer every other skill borrows — worktree convention and lifecycle, base-ref resolution, rebase-versus-merge policy, and stacked branches. |
| [`grillkit`](#grillkit) | Interrogate any idea, plan, or design — a round of unblocked decisions at a time, each with a recommended answer, until you both share the same picture. |
| [`handoffkit`](#handoffkit) | Compact the current conversation into a handoff document another agent or session can pick up cold. |
| [`humankit`](#humankit) | Strip the tells of AI-generated writing from prose so it reads like a person wrote it. |
| [`ideakit`](#ideakit) | Think an idea through across many sessions: one ideas repo with a folder per idea, a jotpad for the thoughts that have none, one idea open at a time, and nothing written to disk until you ask for it. |
| [`implementkit`](#implementkit) | Implement a plan, spec, or issue into working code — then stop, gated on the repo's own tests and build. |
| [`issuekit`](#issuekit) | Own the GitHub issue lifecycle in five modes — file the work, pick it up, land it, keep it in sync as PRs merge, and keep the tracker honest and ranked. |
| [`mergekit`](#mergekit) | Take an open GitHub PR and set it up for review on your machine — worktree, project running, review pack — then merge it once you say so. |
| [`namekit`](#namekit) | Name a project to a naming convention you already use, then prove the name is free before you commit to it. |
| [`orcakit`](#orcakit) | Keep the [Orca](https://www.onorca.dev/) desktop app's workspace list honest about the git worktrees your workflow actually creates. |
| [`paseokit`](#paseokit) | Push the git worktrees your workflow actually creates into [Paseo](https://paseo.sh)'s workspace registry, and reap the finished work — the dead rows, and the worktrees whose PRs merged. |
| [`plankit`](#plankit) | Turn a rough feature or change into a structured plan document, before any code. |
| [`prkit`](#prkit) | Draft and open a GitHub pull request from your branch — title, summary, and test plan written from the actual commits and diff. |
| [`promptkit`](#promptkit) | Sharpen the prompt before you send it — the one-shot instruction you're about to hand a coding agent, or the system prompt your application ships. |
| [`prototypekit`](#prototypekit) | Build throwaway code that answers a question, fold the answer into the decision, then delete the code. |
| [`qakit`](#qakit) | Generate a step-by-step manual QA plan for a feature just implemented, grounded in the actual code changes. |
| [`refactorkit`](#refactorkit) | Survey an existing codebase for the structural change worth making — shallow interfaces, adapter sprawl, poor locality, untested coupling — rank the candidates, crown one, and write it up as a reviewable proposal. |
| [`releasekit`](#releasekit) | Cut a release from the Conventional Commits a repo already writes — derive the semver bump and a changelog from the commit range, bump the manifest, tag it, and publish a GitHub release, all behind a mandatory preview. |
| [`repokit`](#repokit) | Set up a GitHub repo through the `gh` CLI — About description and topics, the workflow labels, and a full new-repo setup. |
| [`researchkit`](#researchkit) | Research the credible options for a technical decision and recommend one, grounded in primary sources with cited, dated evidence. |
| [`reviewkit`](#reviewkit) | Review AI-agent-implemented code specifically — four ordered passes, findings ranked by severity and backed by quoted evidence. |
| [`skillkit`](#skillkit) | Create a new AI agent skill from scratch — naming, drafting, live testing, and publishing included. |
| [`statuskit`](#statuskit) | Survey a project read-only into a one-screen dashboard, then crown one finish-first next move — ranked on declared priority — routed to the kit that does it. |
| [`testkit`](#testkit) | Retrofit an automated test suite onto a working codebase that has none — rank the untested surface, crown a slice, stand up a runner, and write tests that were each watched to fail before they were kept. |
| [`tutorkit`](#tutorkit) | Teach a topic across many sessions — one learning repo with a folder per topic, lessons pitched at what you already know, and spaced retrieval that makes it stick. |
| [`uikit`](#uikit) | Build production UI that reads as a deliberate choice for this project rather than an LLM default, and audit shipped UI for the tells that give it away. |
| [`validatekit`](#validatekit) | Pressure-test a SaaS or startup idea before you build it — forcing questions, an honest verdict graded on evidence you can actually produce, the narrowest wedge, and one real-world assignment. |
| [`verifykit`](#verifykit) | Prove a frontend feature actually works by driving it in a real browser and capturing screenshots plus a short GIF as PR-ready proof. |
| [`wikikit`](#wikikit) | Generate and maintain a project's reader-facing documentation in-repo — getting-started, how-to guides, architecture, runbooks — with every command verified against the code. |

## [`afkkit`](./skills/afkkit.md)

Run a groomed `ready` GitHub issue through the whole build span unattended: worktree, implement, commit, verify-and-review, fix, QA plan, and open PR.

_No modes — one path._

## [`commitkit`](./skills/commitkit.md)

Create git commits with Conventional Commits messages derived from the actual diff.

_No modes — one path._

## [`debugkit`](./skills/debugkit.md)

Chase a symptom to its true cause — reproduce it, shrink it, write falsifiable hypotheses, and prove the cause by toggling the symptom on and off — then hand over a failing reproduction instead of a fix.

_No modes — one path._

## [`designkit`](./skills/designkit.md)

Derive a project's design system from the UI it already ships and keep it true as the code moves — a spec-compliant `DESIGN.md`, validated by the official linter.

| Mode | What it does |
|---|---|
| `init` | ground it with the engine, naming the rung that matched and the counts found, before proposing anything |
| `update` | resolve the target — uncommitted changes first, otherwise the branch diff against a base from [`gitkit`](./skills/gitkit.md), never an assumed `main` |
| `audit` | read-only. Writes nothing, ever |

## [`domainkit`](./skills/domainkit.md)

Maintain a project's domain model as a consented byproduct of design work — a `CONTEXT.md` glossary and `docs/adr/` decision records.

_No modes — one path._

## [`gitkit`](./skills/gitkit.md)

The shared git layer every other skill borrows — worktree convention and lifecycle, base-ref resolution, rebase-versus-merge policy, and stacked branches.

| Mode | What it does |
|---|---|
| `clean` | sweeps away the worktrees and branches whose work has landed, on your machine and on `origin` |
| `rescue` | finds work that looks lost — a bad rebase, a hard reset, a deleted branch, a stash nobody can find — and puts it back |
| `sync` | fetches, rebases onto the base, resolves each conflict, then force-pushes with lease |

## [`grillkit`](./skills/grillkit.md)

Interrogate any idea, plan, or design — a round of unblocked decisions at a time, each with a recommended answer, until you both share the same picture.

_No modes — one path._

## [`handoffkit`](./skills/handoffkit.md)

Compact the current conversation into a handoff document another agent or session can pick up cold.

_No modes — one path._

## [`humankit`](./skills/humankit.md)

Strip the tells of AI-generated writing from prose so it reads like a person wrote it.

_No modes — one path._

## [`ideakit`](./skills/ideakit.md)

Think an idea through across many sessions: one ideas repo with a folder per idea, a jotpad for the thoughts that have none, one idea open at a time, and nothing written to disk until you ask for it.

| Mode | What it does |
|---|---|
| `jot` | records a loose thought and stops |
| `promote` | turns a jot into an idea |
| `capture` | writes the idea down and stops |
| `session` | the mode that thinks, and the only one that discusses |
| `status` | reports and writes nothing at all |
| `research` | classifies before it acts, because "research" covers three different asks with three different owners |
| `validate` | hands a startup or SaaS idea to [`validatekit`](./skills/validatekit.md), takes the verdict inline, and offers the verdict, the wedge, and the assignment as one log entry |
| `close` | records a verdict: `building`, `parked`, or `closed` |

## [`implementkit`](./skills/implementkit.md)

Implement a plan, spec, or issue into working code — then stop, gated on the repo's own tests and build.

_No modes — one path._

## [`issuekit`](./skills/issuekit.md)

Own the GitHub issue lifecycle in five modes — file the work, pick it up, land it, keep it in sync as PRs merge, and keep the tracker honest and ranked.

| Mode | What it does |
|---|---|
| `create` | turn a plan document or a plain description into well-formed issues |
| `start` | picks a `ready` issue up, and hands the worktree half to gitkit |
| `close` | closes an issue whose PR merged, and reclaims its workspace |
| `sync` | reconcile the PR↔issue relationship after the fact |
| `triage` | report first, then act — on approval for a close or a comment, straight through for a relabel |

## [`mergekit`](./skills/mergekit.md)

Take an open GitHub PR and set it up for review on your machine — worktree, project running, review pack — then merge it once you say so.

| Mode | What it does |
|---|---|
| `list` | the morning dashboard: what's actually waiting on you, in one table |
| `start` | prepare the review workspace for a PR: worktree, project running, review pack. |
| `close` | merge or fix, depending on which verdict you reached |
| `fix` | the mirror of `start`, for a PR you authored that came back with review comments, a change request, or red CI |

## [`namekit`](./skills/namekit.md)

Name a project to a naming convention you already use, then prove the name is free before you commit to it.

| Mode | What it does |
|---|---|
| `generate` | A description in, a ranked shortlist out, then a probe loop you drive |
| `check` | names in, verdicts out. Same three probes, same owner exception, no generation and no ranking |

## [`orcakit`](./skills/orcakit.md)

Keep the [Orca](https://www.onorca.dev/) desktop app's workspace list honest about the git worktrees your workflow actually creates.

| Mode | What it does |
|---|---|
| `list` | reports every workspace with a verdict, and changes nothing |
| `link` | attaches the issue number and a real-state `workspaceStatus` to a workspace card |
| `clean` | reclaim workspaces whose work already landed |
| `align` | stop Orca creating worktrees somewhere gitkit will never look |

## [`paseokit`](./skills/paseokit.md)

Push the git worktrees your workflow actually creates into [Paseo](https://paseo.sh)'s workspace registry, and reap the finished work — the dead rows, and the worktrees whose PRs merged.

| Mode | What it does |
|---|---|
| `list` | reports every workspace with a verdict, and changes nothing |
| `sync` | the adding mode, safe to run repeatedly by construction |
| `clean` | the removing mode, and the only one — every archive and every delete in the skill lives here, in two halves |
| `align` | one-time configuration, per machine. It touches no workspace at all |

## [`plankit`](./skills/plankit.md)

Turn a rough feature or change into a structured plan document, before any code.

_No modes — one path._

## [`prkit`](./skills/prkit.md)

Draft and open a GitHub pull request from your branch — title, summary, and test plan written from the actual commits and diff.

_No modes — one path._

## [`promptkit`](./skills/promptkit.md)

Sharpen the prompt before you send it — the one-shot instruction you're about to hand a coding agent, or the system prompt your application ships.

| Mode | What it does |
|---|---|
| `task` | sharpens the one-shot instruction you are about to hand a coding agent — the default |
| `system` | sharpens a durable system prompt an application ships |

## [`prototypekit`](./skills/prototypekit.md)

Build throwaway code that answers a question, fold the answer into the decision, then delete the code.

_No modes — one path._

## [`qakit`](./skills/qakit.md)

Generate a step-by-step manual QA plan for a feature just implemented, grounded in the actual code changes.

_No modes — one path._

## [`refactorkit`](./skills/refactorkit.md)

Survey an existing codebase for the structural change worth making — shallow interfaces, adapter sprawl, poor locality, untested coupling — rank the candidates, crown one, and write it up as a reviewable proposal.

_No modes — one path._

## [`releasekit`](./skills/releasekit.md)

Cut a release from the Conventional Commits a repo already writes — derive the semver bump and a changelog from the commit range, bump the manifest, tag it, and publish a GitHub release, all behind a mandatory preview.

_No modes — one path._

## [`repokit`](./skills/repokit.md)

Set up a GitHub repo through the `gh` CLI — About description and topics, the workflow labels, and a full new-repo setup.

| Mode | What it does |
|---|---|
| `about` | infers a description and topics from the repo's own contents, reconciles against what's set, and applies on approval |
| `labels` | provisions the workflow labels the issue lifecycle expects |
| `setup` | brings an existing repo up to convention — settings, baseline files, `about`, `labels` |

## [`researchkit`](./skills/researchkit.md)

Research the credible options for a technical decision and recommend one, grounded in primary sources with cited, dated evidence.

_No modes — one path._

## [`reviewkit`](./skills/reviewkit.md)

Review AI-agent-implemented code specifically — four ordered passes, findings ranked by severity and backed by quoted evidence.

_No modes — one path._

## [`skillkit`](./skills/skillkit.md)

Create a new AI agent skill from scratch — naming, drafting, live testing, and publishing included.

_No modes — one path._

## [`statuskit`](./skills/statuskit.md)

Survey a project read-only into a one-screen dashboard, then crown one finish-first next move — ranked on declared priority — routed to the kit that does it.

| Mode | What it does |
|---|---|
| `critical` | the one label that outranks the finish-first ranking |

## [`testkit`](./skills/testkit.md)

Retrofit an automated test suite onto a working codebase that has none — rank the untested surface, crown a slice, stand up a runner, and write tests that were each watched to fail before they were kept.

| Mode | What it does |
|---|---|
| `audit` | read-only. It ranks the untested surface and writes nothing but the ledger — no test file, no source edit |
| `cover` | writes the tests, standing up a runner first when the project has none |

## [`tutorkit`](./skills/tutorkit.md)

Teach a topic across many sessions — one learning repo with a folder per topic, lessons pitched at what you already know, and spaced retrieval that makes it stick.

| Mode | What it does |
|---|---|
| `status` | the front door — where you are with every track you have open |
| `explain` | the fast path, and the reason tutorkit isn't a commitment. "How does Postgres MVCC work" should not open a track |
| `lesson` | the core loop, and the only mode that opens a track |
| `drill` | retrieval practice, interleaved across topics, capped at 12 cues per run |
| `exam` | measures and refuses to teach. Two entry points, one posture — ask, grade, record, explain nothing |

## [`uikit`](./skills/uikit.md)

Build production UI that reads as a deliberate choice for this project rather than an LLM default, and audit shipped UI for the tells that give it away.

| Mode | What it does |
|---|---|
| `build` | ground it on the ladder, detect the stack from the manifest rather than assuming, state the design read, then build |
| `audit` | read-only. Writes nothing, ever |

## [`validatekit`](./skills/validatekit.md)

Pressure-test a SaaS or startup idea before you build it — forcing questions, an honest verdict graded on evidence you can actually produce, the narrowest wedge, and one real-world assignment.

_No modes — one path._

## [`verifykit`](./skills/verifykit.md)

Prove a frontend feature actually works by driving it in a real browser and capturing screenshots plus a short GIF as PR-ready proof.

_No modes — one path._

## [`wikikit`](./skills/wikikit.md)

Generate and maintain a project's reader-facing documentation in-repo — getting-started, how-to guides, architecture, runbooks — with every command verified against the code.

| Mode | What it does |
|---|---|
| `init` | for a repo with no doc set |
| `update` | for a change that just landed |
| `audit` | read-only. Writes nothing, ever |
| `publish` | opt-in, explicit-ask-only. Nothing routes into it, and a request has to name the GitHub wiki to reach it |

---

_Generated by `make cheatsheet` from the pages under [`docs/wiki/skills/`](./skills/). Edit a skill's page, not this file — `make lint` diffs the two._
