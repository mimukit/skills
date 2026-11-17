---
name: grillkit
description: >-
  Grill the user relentlessly about any idea, plan, or design, a round of unblocked decisions at a time, each with a recommended answer, until you both share the same picture. Use when the user wants to stress-test or pressure-test an idea, says "grill me", "grill this plan", "poke holes in this", "interrogate my design", or otherwise asks to interrogate a concept before committing to it, whether a rough idea, a plan file, an architecture, or a PR.
license: MIT
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, AskUserQuestion, Task, Agent, Skill
metadata:
  internal: false
---

# grillkit

Map the subject as a **design tree**, where every decision branches into the decisions that hang off it.

## How to grill

- **Open by reflecting the idea back.** Before the first question, restate the subject in your own words: the goal you understand, the shape you're about to grill.
- **Work the tree in rounds.** The **frontier** is every decision whose prerequisites are already settled, meaning the questions you can ask *now* without guessing at answers you haven't heard yet. Ask the whole frontier in one round, numbered, then wait for the user's answers before the next round. A question whose answer depends on another question still open in this round belongs to a *later* round, not this one. [Asking the round](#asking-the-round) is the format.
- **Each round reshapes the tree.** Recompute the frontier and ask the next round.
- **Always recommend an answer.** For every question, state the option you'd pick and why.
- **Ask what needs the user; default the rest.** A round asks only the decisions that need the user's judgment and lists every other one as a default the user can override by number. [Ask or default](#ask-or-default) is the sort.
- **Probe the soft spots.** Push hardest on unstated assumptions, hand-waved edge cases, error and failure paths, scope boundaries, and anything described vaguely. If an answer is thin, follow up in the next round rather than letting it stand. A decision gets one follow-up; a second thin answer records it as **deferred**, and it leaves the frontier.
- **Ask only what is still open.** A round carries only unresolved decisions. A settled decision returns to the frontier only when a later answer contradicts it, and the round says which answer reopened it.

## Asking the round

### Ask or default

Sort every frontier decision before you write the round. The sort decides where it sits in the round, not whether it gets a recommendation: both kinds carry one.

**Ask** the decision when any of these holds:

- **Domain or product.** What the product does and for whom, a business rule, pricing, a domain term's name or meaning, what is in or out of scope.
- **Taste.** Visual design, copy, tone, naming the user sees.
- **Hard to reverse.** A data model, a public API or CLI surface, a migration, an external contract, a cost commitment, a security or privacy trade-off.
- **Weak recommendation.** Two options are close, your evidence is thin, or your pick contradicts something the user said.
- **Outward action.** Permission for anything beyond the plan's own branch. The build-stop round in [When to stop](#when-to-stop) always asks these.

**Default** everything else: the mechanics a competent implementer picks without controversy, choices a later commit reverses cheaply, and choices the repo's conventions already settle. When the sort is unclear, ask.

A default is settled when the user replies to its round without overriding it. An override settles the decision with the user's answer, and it follows the same follow-up and deferred rules as an asked decision. A default never returns in a later round unless a later answer contradicts it.

Every default appears in the round's table with its one-line reason, and the recap in [Hand off](#hand-off) marks each settled decision as asked or defaulted.

This sort is done when every frontier decision is either in the defaults table or written as an asked question.

### The shape of a round

```
### Round 2: 5 open decisions, 2 asked, 2 defaulted
Blocked behind this round: storage format, migration path.

**Defaults.** Taken unless you change one by number.

| # | Decision | Default | Why |
|---|---|---|---|
| Q4 | Page file names | (a) kebab-case from the page title | matches the repo's existing docs |
| Q5 | Link style between pages | (a) relative Markdown links | renders in GitHub and in every engine |

---

❓ **Q6. Where does the doc map live?**
Stakes: `update` needs a code-path → page lookup without reading every page, and `audit`'s recency prefilter needs to know which paths a page describes.

- **(a) Per-page colocated metadata.** Can't drift from the page, one grep pass, invisible in every renderer
- **(b) YAML frontmatter.** GitHub renders it as a visible table, and it may collide with an engine's own schema
- **(c) Central manifest.** One more file to keep in sync
- **(d) Re-derive each run.** No drift, but throws away the cheapness `audit` depends on

➡️ **(a)** as an HTML comment under the visible stamp: `<!-- wikikit: documents: src/cli/**, package.json -->`

---

❓ **Q7. Contributor docs: in or out?**
Stakes: dev-env setup and release steps are *derivable from the repo*; a CONTRIBUTING.md is a social contract that isn't in the repo at all.

- **(a) Split on that seam.** Mechanical half becomes how-tos, the social half stays out
- **(b) All in.** Pulls PR etiquette and CoC into scope, which can only be invented
- **(c) All out.** Loses two how-tos that verify cleanly

➡️ **(a)** with `how-to/set-up-a-dev-environment.md` and `how-to/cut-a-release.md` joining the doc set; root `CONTRIBUTING.md` is never written, only linked.

---

⏳ **Q8. How do readers move between pages?** Waiting on a sub-agent checking the repo for a docs generator, because the generator decides whether a sidebar exists. It lands next round.

Reply `6a 7b`, change a default with its number (`5b`), or say "go with your picks" to take everything.
```

### The rules that produce it

- **Options are a list, never prose.** One option per line, even for a binary.
- **Each option carries its own trade-off** on its own line.
- **Stakes first, two sentences max.** Label it `Stakes:` and say what breaks or stays undecided downstream.
- **The recommendation is one line.** `➡️ **(a)** <the concrete form it takes>`: the letter, then only the exact syntax, path, or shape. Never restate the option's description.
- **Rule off between questions** with `---`.
- **Number continuously across rounds.** Q1–Q3 in round one, Q4 onward in round two. A `⏳` question keeps its number when it returns in a later round with the fact it waited for, and new questions continue from the highest number used so far.
- **Code spans are for literals only.** Paths, filenames, flags, commands, identifiers. Use *italics* for conceptual emphasis.
- **Show what's pending.** When a sub-agent is still fetching a fact a question depends on, list that question with `⏳` and name what it waits for.
- **Defaults come first, as one table.** One row per default: the number, the decision, the pick with its letter, and a one-cell reason. A default needs no stakes line and no option list; a user who wants to override one asks for the options. A round with no defaults drops the table.
- **Head the round and close it.** The header counts the open, asked, and defaulted decisions and names what they unblock. The closing line names the reply format.

### Offer the picker when you have one

With `AskUserQuestion` available, run the round **hybrid**: print the full text round first, with stakes, trade-offs, evidence, and recommendation, then call the tool for the picks alone.

- **The picker carries the asked questions only.** Defaults stay in the table.
- **The picker mirrors the text round exactly.** Same questions in the same order, same options in the same order.
- **Write the recommended option as `(a)` while you write the options**, unless the options carry an order of their own (a spectrum, escalating scope, a chronology). Never reorder between the two views.
- **Prefix every label with its letter**, as in `(a) Per-page metadata`, and mark the recommended option `(Recommended)` at the end of its label.
- Keep the labels short; the rationale lives in the text round.
- The tool caps at 4 questions per call and 4 options per question, and it always appends an "Other" escape for the user's own answer (checked 2026-11-16). A wider frontier means batching calls in round order or falling back to the text round alone; never trim the frontier to fit the widget. A question with a fifth option can't be mirrored at all: either fold two options together in *both* views, or leave that one question to the text round rather than showing the picker a truncated list.

## Facts are your job, decisions are theirs

If a fact is discoverable in the codebase, docs, or config, find it yourself. Ask the user only for *decisions*.

When a frontier question needs a fact from the environment (filesystem, tools, config) and you have a sub-agent tool, **dispatch a sub-agent to find it, and don't block on it.** Only the questions downstream of it wait; ask the rest of the frontier now and list the blocked one with `⏳`. With no sub-agent tool available, look the fact up inline before you put the dependent question to the user.

## When to stop

**Before the frontier counts as empty, ask the build-stop round** when the subject is something that gets built. These are the questions a build would otherwise stop for:

- **Outward actions.** Permission for each one the plan calls for beyond its own branch, such as filing follow-up issues, pushing, or a deploy.
- **Test infrastructure.** The runner and approach for each phase that asks for a kind of test the repo does not have yet.
- **Attended phases.** Each phase that needs a person, such as a design pick or a mockup approval. Settle it now when the grill can. Otherwise confirm that it stays attended, and that it comes before the phases that can run unattended.

Skip a question the plan already answers.

The grill is done when the frontier is empty: every decision in the design tree is settled, or deferred and named as deferred. The user can also stop the grill at any round; the decisions still open become deferred. Then hand off, and do not begin implementing until the user explicitly says to proceed.

## What to do with the result

Where the result lands depends on how the session started:

- **Started from a plan file.** When the input was an existing plan document (e.g. a `NNNN-plan-<slug>-YYYY-MM-DD.md`, or an older one without the serial), **fold the settled decisions back into that same file by default**, without asking. Keep its name, serial and creation-date suffix included, and tell the user you updated it. Only skip or redirect the write if the user explicitly asked for something else (a standalone note, no file, a different location). **Stamp the hardened plan** with a `Grilled: YYYY-MM-DD` line directly under the title (today's date; update it on a re-grill). issuekit labels a plan's issues `ready` only when the plan carries this stamp. Write it the same way on a project that files no issues. **The stamp covers the plan as grilled, not later edits.** A material edit removes it: one that adds, removes, or changes a settled design decision; adds, removes, or re-scopes a phase; changes a phase's `Done when:` observable; or changes the non-goals or the migration section. Whoever makes that edit deletes the line, and a re-grill writes it again. Wording fixes, phase-heading annotations such as `(#41)` or `(built YYYY-MM-DD)`, and new open questions leave it in place. **Record the build-stop answers in the plan too**: each approved outward action and each test runner as a row in the settled design decisions, and each phase that stays attended as an `Attended:` line under its heading naming what it waits on. An unattended runner reads only the plan, never this conversation. No filesystem? Print the stamp line with the recap for the user to add themselves.
- **Started from anything else.** With a rough idea, a design in someone's head, an architecture, or a PR, **ask** where the decisions should go: update some existing file in place, write a standalone note in the current directory, or nothing at all. Don't write a file unprompted and don't assume a location.

If grilling settled a domain term or a hard-to-reverse trade-off decision worth keeping, **domainkit** is the scribe when installed; otherwise note the settled decision for the user to record as a glossary entry or ADR.

## Publish the result

Offer the closing chores (commit, push, issue body, label) as one action with one confirmation. Skip this section when the grill wrote no file and settled no issue, or when there is no git repository.

**Build one preview.** List each action that applies, and leave out a line that has nothing to do:

- **Commit.** The paths: the plan file you rewrote, plus any glossary or decision record written during the grill. The Conventional Commits subject, for example `docs(plan): grill the <slug> plan`.
- **Push.** The current branch and its `origin` target, as a plain fast-forward.
- **Issue body.** The issue the grill hardened, either the one it started from or the one the plan names. Say what changes: the settled decisions, the link to the plan, and the open questions the grill closed.
- **Label.** `needs-planning → ready`, only when the plan carries the `Grilled:` stamp and no decision is deferred. With a deferred decision, the label stays and the preview says why. issuekit owns the promotion rule, and it can resolve to `blocked` when the issue names an open dependency; without issuekit, promote to `ready` only when the issue names no open dependency.

**Ask once.** Offer three answers: publish everything, commit only, or skip. With `AskUserQuestion`, use it.

**Run the approved actions in this order:** commit, push, issue body, label.

- Commit and push with **commitkit**, handing it the exact paths. Without commitkit, run `git add -- <paths> && git commit -m "<subject>" && git push`.
- Edit the issue body with **issuekit**. Without it, run `gh issue edit <n> --body-file <file>`.
- Promote the label with **issuekit** `triage` as a targeted request (`#<n> is grilled, mark it ready`). Without it, run `gh issue edit <n> --remove-label needs-planning --add-label ready`.

The label goes last, because unattended work on a `ready` issue needs the plan on the remote.

**Stop at the first failure.** A refused push (a protected branch, a non-fast-forward, no permission) stops the sequence: report the error, leave the issue body and the label unchanged, and name the plain fix. Never force-push, and never open a pull request the user did not ask for.

This step is done when every approved action has run, or the first failure is reported and nothing after it ran.

## Hand off

_Write this section in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

**What changed.** Give a brief recap of the decisions you settled together, each in a line. Name each question you raised and didn't resolve as deferred. Mark each decision as asked or defaulted. Name each phase that stays attended, and each outward action the user approved.

**Where it landed.** Name the plan file you rewrote in place and its `Grilled:` stamp, or the file you were asked to write instead, or nothing at all when the user declined a file. Give the commit SHA, the pushed branch, the issue URL, and its label after [Publish the result](#publish-the-result), or say which of those the user skipped or which failed.

**Next.** Pick the first route that applies. Do not start it.

- The publish step moved an existing issue to `ready`: run **afkkit** on it (`run issue #<n> unattended`), otherwise **issuekit** `start <n>`, otherwise create a branch and build it by hand.
- No plan file: name what the decisions feed, the build (**implementkit**, otherwise by hand) or a decision record (**domainkit**, otherwise a glossary entry or ADR the user writes).
- The project tracks work in GitHub Issues and no issue exists yet: file the plan with **issuekit**, which reads the stamp to file the issues as `ready`, otherwise run `gh issue create` once per phase with the plan path in each body.
- The project tracks work elsewhere or nowhere: build the first phase with **implementkit**, otherwise build it by hand on a new branch. The prompt or the repo's agent-guide file says which tracker applies; a GitHub project may still run its backlog in Linear, Jira, or a file.
