---
name: retrokit
description: >-
  Run a retrospective on a finished agent session: find the friction moments in its log, trace each one to a gap in the repo's environment or in a skill, and save a ranked report that routes every fix to the kit that owns it. Use when the user says "retro this session", "run a retro on the last afkkit run", or "retro all sessions on this box" for a session from any repo.
license: MIT
disable-model-invocation: true
allowed-tools: Bash, Read, Grep, Glob, Write, Agent, Task
metadata:
  internal: false
---

# retrokit

**Write exactly one report and change nothing else.** A retro finds why the environment let a session struggle, and proposes the change that stops a repeat: a check, a pointer, a skill fix, or a deletion. The kit that owns each fix makes it later. retrokit never writes a lint rule, a standards line, or a skill edit itself.

## Invocation

- `retrokit` → the current session.
- `retrokit <log path | session id | "the last afkkit run">` → that session of the current repo.
- `retrokit all [<log path | session id>]` → any session on the box, from any repo. The report still lands in the repo you run it in.

## The evidence gate

**Every candidate points at a moment in the log.** The moment is a quoted tool call, error, retry, user correction, or interruption, with its `<log path>:<line>`, and a cost: the tool calls, turns, or wall time it burned, or the correction the user had to make. A candidate with no moment is dropped, however sound the advice. A report with zero candidates is a valid result.

**Redact before you write.** A quote is 200 characters at most. Replace every secret, token, key, password, and credential URL with `<redacted>`. When the repo you run in is public and the session's repo is private or unknown, write a one-line paraphrase and the `<log path>:<line>` in place of the quote. Read visibility with `gh repo view --json visibility` in each repo; without `gh`, treat the visibility as unknown.

## Where a fix belongs

The agent that builds has the most context pressure: it explores, writes, and debugs. The agent that reviews gets a diff and has room. So:

- **The always-loaded agent guide (`CLAUDE.md` or an equivalent) holds navigation pointers.** A new rule there is usually the wrong fix, and moving one out is a valid candidate.
- **A mechanical violation gets a deterministic check.** A fixed pattern, a banned API, an import shape, or a file-location rule becomes a rule in the repo's own linter, a pre-commit hook, or a CI job, whichever the repo already runs. A check that exists but is unwired or broken is the finding, not a new check.
- **A judgement call gets a line in `CODING_STANDARDS.md`**, the reviewer-side standards file. Propose creating it with the first accepted judgement rule when the repo has none.

## The categories

Sort each friction moment into exactly one row.

| Category | The moment in the log | The fix | Owner |
|---|---|---|---|
| Navigation | a long search for a file or a fact | a pointer from a file the agent already reads; a term the agent misread goes to the glossary | implementkit, or domainkit for a term |
| Automated check | a mistake a tool could have caught, or a repo with no guardrail at all (no hook and no CI running lint, typecheck, and tests) | a lint rule, a hook, a CI job, or wiring for an existing one | implementkit |
| Coding standard | the reviewer missed a judgement-call mistake | a `CODING_STANDARDS.md` line | implementkit |
| Steering bloat | an agent-guide instruction that belongs in a check or the standards file | move it there, then delete it from the guide | implementkit |
| No-op | an instruction the agent obeyed by default, or one it ignored with no effect | delete it | implementkit |
| Tool economy | an expensive tool call for little output (a whole-file read, a full suite where one file would do, a chatty CLI) | a cheaper command, script, or flag | implementkit |
| Information access | a fact the agent needed and could not reach (server logs, a service's state, a stale doc) | wider read access, such as a dev server that writes its log to a file; a stale doc goes to its docs kit | implementkit, or wikikit for a stale doc |
| Skill defect | a skill step that ended early, a vague completion criterion, a trigger that did not fire, a skill that asked where it should decide | an edit to that skill, then a re-run of its trigger cases | skillkit |

Name an owner kit only when it is installed. Otherwise describe the fix as a plain edit the user makes.

## Procedure

### 1. Pick the session

Resolve the log to read:

- **Claude Code** writes `~/.claude/projects/<slug>/<session id>.jsonl`, where `<slug>` is the session's start directory with `/` and `.` turned into `-`. Subagent logs sit in `<slug>/<session id>/subagents/`.
- **Codex** writes `~/.codex/sessions/YYYY/MM/DD/rollout-*.jsonl`.
- Both carry a `cwd` field on their entries.

**A session belongs to the current repo** when its `cwd` sits inside the repo root, inside a worktree that `git worktree list` names, or inside this repo's worktree root. gitkit owns that root, and it resolves to `${WORKTREE_ROOT:-~/worktrees}/<repo basename>/`; it catches the sessions of removed worktrees. Without gitkit, the user names a removed worktree's session by its log path. In `all` mode, any log on the box qualifies.

**An afkkit run** is found by its evidence. The PR body ends with `afkkit run: <host> session <id>` when the host exposed the id, and the log file carries that id in its name. Without that line, search the logs for the PR URL or the issue's `afkkit <n>`, and take the newest match. "The last afkkit run" is the newest session of this repo whose user turns name afkkit. A host deletes old logs after its retention period (Claude Code's `cleanupPeriodDays`); when the log is gone, retro the PR body alone and say so. When the user names nothing, take the current session. When the host keeps no log you can read, retro the current session from context, and say so in the report.

**Done when** each session to read has a log path, or the run has declared that it reads the current session from context.

### 2. Dispatch the digest

**Never read a raw log into this context.** Logs run to several megabytes. Dispatch one subagent per session with the host's subagent tool. Its brief names the log path and the subagent log directory when it exists. For an afkkit run, it also names the PR body (`gh pr view <n> --json body`), which holds the run's open problems and decisions, and the `.afkkit/` run directory in the worktree while the worktree still exists (`progress.md` and `orientation.md` live only there). The subagent reads them all and returns a digest file:

- every user turn, as one line each;
- every tool error, failed command, and non-zero exit;
- every retry of the same call, and every search that took more than three calls to find one thing;
- every user correction, interruption, and rejected tool call;
- every afkkit `decision` line and open problem;
- each entry with its `<log path>:<line>` and the count of tool calls between the user turns around it.

Pull a full excerpt only for a line the digest points at. With no subagent tool, extract the same lines inline with `grep` or `jq`, never a full read, and say so.

**Done when** each session has a digest file, or a stated reason why its log could not be read.

### 3. Find the friction moments

Read each digest. A friction moment is a stretch where the agent spent effort it should not have needed, or where the user had to step in.

**Done when** every error, retry, correction, interruption, and long search in the digest is either a friction moment with its quote and cost, or dismissed in one line with the reason (expected exploration, a transient network error, the user changing their mind).

### 4. Classify and route

For each moment, ask what in the environment allowed it. Sort it into one row of [The categories](#the-categories), then name the concrete fix: the file and the line to add, move, or delete, the check to write or wire, or the skill and its step. Follow [Where a fix belongs](#where-a-fix-belongs). Name the repo that owns the fix as its target; in `all` mode it can differ from the session's repo, and a skill defect targets the repo that holds the skill.

Two moments with one cause become one candidate that lists both moments.

**Done when** every friction moment belongs to one candidate, and every candidate has a category, a concrete fix, a target repo, and an owner.

### 5. Rank

Read the earlier reports in `docs/retros/`. A candidate with the same category and the same fix target as an earlier report's candidate is a **repeat**: it moves up one severity level and cites that report's path.

| Severity | What it takes |
|---|---|
| 🔴 High | the user had to correct the agent, wrong work shipped or reached a commit, or the candidate is a repeat of a 🟡 |
| 🟡 Medium | the agent recovered alone, but at a cost of ten or more tool calls or a full re-run of a gate |
| 🟢 Low | a small, one-off cost |

Order the candidates by severity, then by cost. Crown the first one. A deletion ranks by the same rule as an addition.

**Done when** every candidate has a severity, every repeat cites its earlier report, and exactly one candidate is crowned, or the report has no candidates.

### 6. Write the report

Write `docs/retros/NNNN-retro-<slug>-YYYY-MM-DD.md`: a four-digit serial, a short lowercase kebab-case slug naming the session's work, and today's ISO date. To get the serial, take the highest leading serial in `docs/retros/` across this worktree, every other worktree that `git worktree list --porcelain` names, and `origin/<default branch>` (`git ls-tree --name-only origin/<base> docs/retros/` after `git fetch origin <base>`), and add one. Skip a source that fails, and start at `0001` when there is none. A re-run on the same session updates its report in place.

The report holds:

- a header: the date, each session's log path, its repo, and its start directory;
- a coverage line, such as *"digest of 1,412 log lines, 23 user turns, 9 errors; 4 friction moments, 3 candidates"*;
- a table: rank, severity, category, fix, target repo, owner;
- one section per candidate: its moments with their quotes or paraphrases, the cause, the fix, and the repeat citation when it has one;
- the dismissed lines from [Find the friction moments](#3-find-the-friction-moments).

Check every quote against [The evidence gate](#the-evidence-gate) as you write it. With no writable filesystem, print the report as a code block under its canonical path.

**Done when** the file exists at its path, and every quote in it is 200 characters or fewer, carries no secret, and obeys the visibility rule.

### 7. Hand off

_Write this section in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

**What changed.** Name the report you wrote. Say that retrokit changed no other file. Give the count of candidates by severity.

**Where it landed.** Give the report path, and the target repo of each candidate outside the current repo.

**Next.** Crown one move: the crowned candidate, routed to its owner kit with a one-line invocation, such as "fix afkkit's spec gate with **skillkit**" or "add the lint rule with **implementkit**". When the owner kit is not installed, describe the edit the user makes. Name up to two runners-up. Commit the report with **commitkit** when installed, otherwise with `git add` and `git commit`. Do not start any of these yourself.

When the report has no candidates, say the session needs no change, and that there is no next move.

**Done when** the hand-off names the report path and exactly one next move, or states that there is none.
