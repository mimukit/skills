# commitkit

Create git commits with Conventional Commits messages derived from the actual diff.

**Reach for it when** a coding session wraps and you want the work committed — grouped properly, with messages written from what changed rather than guessed.

| | |
|---|---|
| Modes | main procedure (commit or draft-only) · draft mode (headless, message only) |
| Tools | `Bash`, `Read` |
| Writes | git commits. Never pushes |
| Visibility | public |

## What it does

commitkit turns the current changes into one or more clean commits with [Conventional Commits](https://www.conventionalcommits.org) messages inferred from the diff itself.

**Multiple commits is the default**, not the exception. A session that touched three concerns produces three commits, each with its own scope — not one catch-all.

It's built for AI coding sessions where you hand off with a bare "commit". In that mode it works autonomously: staging the right files, grouping the work into as many commits as it deserves, committing them, and reporting a table — without stopping to ask at each step.

## It reads the stat, not the diff — when it can

The most interesting decision in the skill is how much diff to read, and it turns on **who wrote the changes**.

| Who wrote it | What it reads |
|---|---|
| **You did, in this same context** | The file-level stat. You already know what the change does and *why* — the approach rejected, the test that caught a bug, the file deliberately left alone. A diff can't tell you any of that, and re-reading code written minutes ago buys nothing. |
| **You didn't** — a subagent, a fresh session, the user's own edits, or work far enough back to be out of context | The diff, group by group — never wholesale. It sketches groups from the stat, then reads `git diff HEAD -- <paths>` per group and stops once that group's type, scope, and effect are clear. A pathless `git diff HEAD` would pull the whole session's changes into context at once. |

When in doubt, it reads. A vague commit message costs more than the tokens it saved.

The same economics drive the git calls themselves. commitkit fires at the end of a session, when the context window is at its largest, and every extra Bash call re-pays that whole window as input. So the state read is one chained call, and the entire commit sequence — every `git add`/`git commit` pair plus the closing `git status -sb` — is another.

**Generated files are never read** in either mode — lockfiles, build output, vendored directories, snapshots, compiled assets. Their stat line carries every bit of signal a commit message can use, and their diffs are the largest in most repos.

## Type and scope

Type comes from what the diff *does*, not what files it touches:

| type | when |
|------|------|
| `feat` | a new capability the user can see |
| `fix` | a bug fix |
| `docs` | documentation only |
| `refactor` | behavior-preserving code change |
| `perf` | a performance improvement |
| `test` | adding or fixing tests |
| `build` / `ci` | build system, deps, or pipeline |
| `style` | formatting/whitespace, no logic |
| `chore` | routine maintenance that fits nothing above |

**Scope is mandatory here** — unlike vanilla Conventional Commits, it's never omitted. The module or feature group the diff belongs to becomes the scope: `feat(auth): …`. Genuinely global work falls back to `repo`: `chore(repo): …`.

## The message

```
type(scope): short imperative summary

one-line summary of why the change was made

- reason/change bullet
- reason/change bullet
```

- **Imperative mood, all lowercase subject.** No capitalized first word, no trailing period, aim for ≤ 50 characters.
- The summary states the **effect** ("add retry to fetch client"), not the activity ("changes to fetch client").
- **A body is required.** One line of *why*, then bullets. Trivial commits don't get padded, but they always get the summary line and at least one bullet.
- No `Co-authored-by` or tool advertising unless you ask for it.

## Grouping

Changes get mapped to logical groups before anything is committed. Each feature group or related unit of work — a feature and its tests, a bugfix, a docs update, a config bump — becomes its own commit.

Grouping is by **what the change accomplishes**, not by file type or directory. A feature stays with the tests and docs that belong to it. But it doesn't over-fragment either: a single cohesive change is one commit even across several files.

Groups are ordered so dependencies land first. A file with hunks from multiple groups gets staged interactively rather than assigned wholesale.

## When it pauses

Delegated committing means it stages files itself without asking. It only stops when intent is genuinely ambiguous: half-finished work in the tree, secrets, changes you probably didn't mean to commit, or a partially staged file where staging the whole path would sweep in deliberately unstaged hunks.

It never runs `git add -A` blindly across unrelated concerns. If nothing has changed at all, it stops and says so.

If a commit fails — a pre-commit hook rejects it — the `&&` chain stops at that group, later groups stay uncommitted, and the hook output gets surfaced. It never retries blindly or reaches for `--no-verify` unless told to.

## Draft mode

The other way to run commitkit is from a git tool that has no agent session behind it — a lazygit custom command, a git hook, anything that shells out. That caller inlines `SKILL.md`, appends the staged diff, captures stdout, and drops the result into its commit panel. Draft mode exists for that path.

Two things change, and both follow from who is driving.

**One commit, not many.** Multiple commits is the whole point of the main procedure, and it depends on commitkit being able to stage files itself. A commit panel has already staged the set and won't let anything restage it, so the default inverts: one message for whatever is staged.

**Output is the message, nothing around it.** No preamble, no code fence, no summary table, no hand-off. The runner doesn't read the output, it *pastes* it, so a friendly opening line lands in the commit as a friendly opening line. This is also why draft mode overrides the codeblock fallback the skill uses elsewhere when it has no shell: a fence helps a human who copies by hand and breaks a pipe.

Type, mandatory scope, and the required body carry over unchanged. The payload can also carry `git log --oneline`, which is what lets a toolless run still match the repo's existing style, and a `[diff truncated]` marker, which the message works around silently rather than confessing. An empty payload produces no output at all.

## Hands off to

[`prkit`](./prkit.md), to open a pull request from exactly these commits. The work is committed but unpublished, and the report says whether the branch has an upstream — commits on a local-only branch exist nowhere but your machine, which is usually the most useful line in the report.

It never pushes, amends, or rewrites history without an explicit ask.

## Install

```sh
npx skills add mimukit/skills -s commitkit
```

Source: [`skills/commitkit/SKILL.md`](../../../skills/commitkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`5723c6a` on 2026-08-22._
