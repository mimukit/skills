---
name: refactorkit
description: >-
  Survey an existing codebase for the structural change worth making, then rank the candidates, crown one, and write it up as a reviewable proposal. Use when the user says "where should I refactor", "this code is hard to change", or "audit the module boundaries".
license: MIT
allowed-tools: Bash, Read, Grep, Glob, Write, Task, Agent
metadata:
  internal: false
---

# refactorkit

**Write exactly one Markdown file and touch no source code.** No moves, renames, extractions, or tidy-ups, even when one is obviously correct. The skill says *where and why*; the doing belongs to whoever picks the proposal up.

## The vocabulary

- **Module**, **interface**, and **depth** carry Ousterhout's meanings. A module is any boundary: a file, a class, a package, a service. Its interface is everything a caller must know to use it correctly, including ordering constraints, required config, side effects, the error contract, and unwritten invariants. A deep module hides much behaviour behind a small interface; a shallow one costs about as much to learn as to read.
- **Seam.** Where the system splits so one side can be replaced, faked, or tested without the other.
- **Leverage.** How much future change a fix makes cheaper. It breaks ties between otherwise equal candidates.

**Use the project's own domain terms throughout.** If the codebase says *ledger*, *tenant*, *shipment*, the proposal says those words, not a generic "component," "service," "API," or "layer."

## The four friction patterns

A closed set: look for these four and nothing else.

| Pattern | What it is | The shape to look for | Who finds it |
|---|---|---|---|
| Shallow interface | the interface costs about as much to learn as the implementation costs to read | a unit whose members each forward to exactly one member of exactly one other unit | subagent |
| Adapter prevalence | modules that exist only to reshape data between two others, where the finding is that two sides disagree on a shape, never "delete the adapters" | a cluster of translation-only units sitting on one boundary, translating in both directions | subagent |
| Untested coupling | behaviour you can only test by standing up its collaborators | tests that construct more collaborators than they make assertions, or an untested unit whose neighbours are all tested | subagent |
| Poor locality | one conceptual change fans out across many files | files that repeatedly change in the same commits while living in different parts of the tree | **main session** |

**Signals are shapes.** Match the structure in the table, whatever the code calls it. Derive the repo's own naming conventions first (the guardrails read below usually supplies them), then look for the structure under those names.

## The two gates

Every candidate clears both before it is listed at all. A candidate that fails either one is discarded silently: it does not appear as a weaker finding, and it does not appear with a caveat.

**The deletion test.** If this module vanished and its callers absorbed what it did, would complexity *concentrate* where it belongs, or merely *relocate*? Concentration passes; relocation fails. State the verdict with one sentence of evidence: which callers absorb what, and why that is or isn't a better home.

**Interface as test surface.** After the proposed change, can the behaviour be tested through the new interface alone, without reaching inside? If not, the seam is in the wrong place and the candidate fails.

Both verdicts are mandatory on every listed candidate, in the terminal output and in the file.

## The strength scale

Rate each surviving candidate against this table, not by feel.

| Strength | What it takes | How it ranks |
|---|---|---|
| `strong` | both gates pass, the files sit in the churn top slice, and the blast radius is named in actual files | crownable |
| `moderate` | both gates pass, but the code is cold or the blast radius is wide | crownable only when nothing is `strong` |
| `weak` | gates pass, but the win is stylistic, and nothing changes about what a caller must know | listed, **never crowned** |

## Procedure

### 1. Read the guardrails first

Before looking at any code, read what the repo has already decided:

- a repo-root context or glossary file (commonly `CONTEXT.md`) for the ubiquitous language, which is where the project's own domain terms come from, and where its naming conventions usually surface;
- `docs/adr/` (or wherever this repo keeps architecture decision records) for decisions already made.

A proposal that reverses an accepted decision record must **say so by its number** and route to a superseding record rather than quietly re-suggesting a design that was already rejected.

When neither file exists, continue without a warning or comment.

### 2. Rank by churn, then cluster

`git log --format= --name-only --since=<a year or so>` gives both signals in one read: how often each file changes (the churn ranking) and which files keep changing *together* (the co-change pairs that become the poor-locality finding).

Rank files by change count, then group the hot ones into **3–5 coherent areas**, by directory, by feature, by whatever seam the repo actually has. When the user names a subtree (`/refactorkit src/payments`), survey only that subtree with the same method.

**No git history**, meaning a shallow clone or not a repo at all, means no ranking. Scan by structure instead and say plainly that the prioritisation was skipped.

### 3. Fan out, one agent per cluster

Dispatch one subagent per area. Each applies the three read-the-code patterns from [The four friction patterns](#the-four-friction-patterns) to its own slice, runs both gates itself, and returns a list of candidate records or an explicit empty result.

Give every agent this fixed return shape, so the main session can rank findings it did not gather:

| Field | Content |
|---|---|
| `pattern` | one of the three read-the-code patterns |
| `files` | the paths involved |
| `shape` | the proposed structure, one line |
| `deletion_test` | verdict plus one sentence of evidence |
| `test_surface` | verdict plus one sentence of evidence |
| `blast_radius` | files touched, callers changed |
| `strength` | per [The strength scale](#the-strength-scale) |

**Poor locality stays in the main session.** It comes from the co-change pairs already in hand, and a per-area agent cannot see files that change together while living in different areas.

**No subagent tool available → scan the top churn slice inline instead**, applying the same patterns and the same gates, and say which path the run took.

### 4. Synthesize, gate, rank, crown

- **Drop** any record missing a gate verdict. Do not repair it: the main session has not read that code.
- **Dedupe** across areas; the same seam often surfaces from both sides of it.
- **Rank** on strength, then leverage, then lowest blast radius.
- **Crown exactly one when any non-`weak` candidate survives.** Never a `weak` candidate, whatever else is on the list. The rest become runners-up, in order.
- **When every survivor is `weak`, crown none.** That result is "no candidate worth doing", and it follows [When nothing clears the gates](#when-nothing-clears-the-gates), with the weak candidates listed in the terminal table.

**Done when** every record is dropped, deduped, or ranked, and the result is one crowned candidate or an explicit "no candidate worth doing".

### 5. Report, then write the artifact

Print a compact table first (candidate, pattern, strength, blast radius), then the crowned candidate with its reasoning, then the runners-up.

**Every report carries a coverage line**, in the terminal and in the file: *"ranked 1,240 files by churn, read the top 40 across 4 areas."*

**The artifact** goes to `docs/refactor/NNNN-refactor-<slug>-YYYY-MM-DD.md`, built from a four-digit serial, a lowercase type prefix, a short lowercase kebab-case subject slug, and the ISO creation date at the end. To get the serial `NNNN`, take the highest leading four-digit serial in `docs/refactor/` across this worktree, every other worktree that `git worktree list` names, and `origin/<default branch>` (`git ls-tree --name-only origin/<base> docs/refactor/` after `git fetch origin <base>`), and add one; start at `0001` when there is none. Scan all three, because parallel worktrees otherwise take the same serial. Skip a source that fails, such as no remote, and without git list the directory only. The serial is per directory and never reused. Keep the whole name stable when the file is edited; a re-run on the same subject **updates the same file in place** rather than spawning a second copy. When the repo already has an established home or naming scheme for proposal documents, that convention wins.

It contains the coverage line, the ranked table, then one section per candidate covering the problem, the proposed shape, why it is deeper, both gate verdicts, and the blast radius, with a **Mermaid before/after diagram for the crowned candidate** at minimum.

The file is durable and meant for review in a PR. refactorkit never commits it.

**No writable filesystem** (a browser-based agent) → print the artifact as a codeblock under its canonical path and skip the write.

### 6. Hand off

_Write this section in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

**What changed.** Report the file written, and explicitly that no source file was touched. **Where it landed.** Give the path. **Next.** Crown the user's next move, and do not write the plan yourself. The move is to turn the crowned candidate into a plan with phases, with **plankit** when it's installed and the proposal file as its input. Otherwise the user writes the plan by hand, one phase per safe intermediate state, each with a check that proves it. The plan then goes to **grillkit** for interrogation when it is installed, otherwise the user reviews it, and then to **implementkit** for the build when it is installed, otherwise the user builds it by hand.

When the proposal supersedes an existing decision record, name a second next move after the crowned one: route it to a decision-record skill (**domainkit** when installed), otherwise the user writes the superseding record by hand.

**On an empty or all-weak result, say there is no next move.** See [When nothing clears the gates](#when-nothing-clears-the-gates).

## When nothing clears the gates

A clean result is a real outcome, and refactorkit reports it as one: name the coverage, say nothing cleared the gates, and **write no file**. An all-`weak` result is the same outcome: list the weak candidates in the terminal table, say no candidate is worth doing, and write no file.

The terminal line has to carry the coverage, as in *"scanned 38 files across `src/`; nothing cleared the deletion test"*, or an empty result is indistinguishable from a scan that never ran.

## Notes

- **Read-only shell only.** git history, file reads, greps. Never install or run an analysis tool to generate evidence. If the repo already has such an artifact on disk, like a dependency graph or a coverage report, read it.
- **Follow the repo over these defaults.** A documented convention or a stated policy in the repo's agent-guide file (`CLAUDE.md` or an equivalent) wins, so say that you followed it.
