# commitkit

Create git commits with Conventional Commits messages derived from the actual diff.

**Reach for it when** a coding session wraps and you want the work committed — grouped properly, with messages written from what changed rather than guessed.

| | |
|---|---|
| Modes | main procedure (commit this session's changes, or everything with `all`) · message-only route (read-only) · draft mode (headless, message only) |
| Tools | `Bash`, `Read` |
| Writes | git commits, pushed to `origin` unless the user or a caller says `no-push`; nothing on the message-only route |
| Visibility | public |

## What it does

commitkit turns the current changes into one or more clean commits with [Conventional Commits](https://www.conventionalcommits.org) messages inferred from the diff itself.

**Multiple commits is the default**, not the exception. A session that touched three concerns produces three commits, each with its own scope — not one catch-all.

It's built for AI coding sessions where you hand off with a bare "commit". In that mode it works autonomously: staging the session's files, grouping the work into as many commits as it deserves, committing them, pushing them, and reporting a table — without stopping to ask at each step.

## It commits this session's work, unless you say `all`

A bare "commit" takes only the changes made in the current session: every file the agent created, edited, deleted, or renamed, plus whatever a command it ran changed as part of the work, like a lockfile. `/commitkit all` takes every change in the tree, and naming a scope ("commit the auth fix") takes just that.

The reason is how the work actually happens. One fix branch, or `main` itself, often carries several small fixes at once, each driven by a different agent in a different session. A commit that swept the whole tree would bundle someone else's half-done fix into this one, under this one's message. So everything outside the scope is left exactly as it was: not staged, not committed, not restored. A path another session staged stays staged, parked aside and put back around each commit. The report names the paths it left alone, so you can see the run noticed them.

Two edges. When another session edited the same file, the agent commits only the hunks it wrote, and asks when they overlap too closely to split. And a fresh session has no session set at all, so instead of guessing it lists the changed paths and asks which to commit, with `all` as the one-word answer for everything.

## It reads the stat, not the diff — when it can

The most interesting decision in the skill is how much diff to read, and it turns on **who wrote the changes**.

| Who wrote it | What it reads |
|---|---|
| **You did, in this same context** | The file-level stat. You already know what the change does and *why* — the approach rejected, the test that caught a bug, the file deliberately left alone. A diff can't tell you any of that, and re-reading code written minutes ago buys nothing. |
| **You didn't** — a subagent, a fresh session, the user's own edits, or work far enough back to be out of context | The diff, group by group — never wholesale. It sketches groups from the stat, then reads `git diff HEAD -- <paths>` per group and stops once that group's type, scope, and effect are clear. A pathless `git diff HEAD` would pull the whole session's changes into context at once. |

When in doubt, it reads. A vague commit message costs more than the tokens it saved.

The same economics drive the git calls themselves. commitkit fires at the end of a session, when the context window is at its largest, and every extra Bash call re-pays that whole window as input. So the state read is one chained call, and the entire commit sequence — every `git add`/`git commit` pair plus the closing push and `git status -sb` — is another.

**Generated files are never read** in either mode — lockfiles, build output, vendored directories, snapshots, compiled assets. Their stat line carries every bit of signal a commit message can use, and their diffs are the largest in most repos.

## Type and scope

Type comes from what the diff *does*, not what files it touches:

| type | when |
|------|------|
| `feat` | a new capability the user can see |
| `fix` | a bug fix |
| `hotfix` | an urgent fix patched straight onto the base branch |
| `docs` | documentation only |
| `refactor` | behavior-preserving code change |
| `perf` | a performance improvement |
| `test` | adding or fixing tests |
| `build` / `ci` | build system, deps, or pipeline |
| `style` | formatting/whitespace, no logic |
| `chore` | routine maintenance that fits nothing above |

**`hotfix` is the one addition to the Conventional Commits set, and the branch decides it.** A commit sitting on a `hotfix-<slug>` branch, cut from the base branch to patch it directly, takes `hotfix`; everything else stays `fix` however urgent it felt. Tying the type to the branch keeps it checkable, where tying it to severity makes every author re-argue the same call. A repo whose tooling validates types against the standard list gets `fix` instead, stated once.

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
- **Body lines stay at 72 characters or fewer.** Hooks like commitlint's `body-max-line-length` reject longer lines, and 72 clears the common 72/80/100 limits, so a compliant message commits on the first try instead of costing a retry.
- **A body is required.** One line of *why*, then bullets. Trivial commits don't get padded, but they always get the summary line and at least one bullet.
- No `Co-authored-by` or tool advertising unless you ask for it.

## Grouping

Changes get mapped to logical groups before anything is committed. Each feature group or related unit of work — a feature and its tests, a bugfix, a docs update, a config bump — becomes its own commit.

Grouping is by **what the change accomplishes**, not by file type or directory. A feature stays with the tests and docs that belong to it. But it doesn't over-fragment either: a single cohesive change is one commit even across several files.

Groups are ordered so dependencies land first. A file with hunks from multiple groups gets staged interactively rather than assigned wholesale.

### The index is not trusted

`git add` only adds to the index; it never removes. So a file you staged before the run would ride into whichever commit came first, whatever group it belonged to. commitkit records the staged set before it groups anything, places every pre-staged path in a group or in a keep-staged set, and checks before each commit that the index holds exactly that group's paths.

When other staged paths are in the way, it parks them: it saves their staged hunks as a patch, unstages them, commits the group, and applies the patch back to the index. A patch keeps hunk-level staging, so a file you staged half of comes back half staged. The shorter `git commit -- <paths>` was rejected because it commits the working-tree copy of each path and would pull your unstaged hunks into the commit.

## The push

commitkit **pushes by default** once the commits exist, as the last link in the same chained call. The reasoning is an asymmetry: a commit that lives only on one disk is one lost machine away from gone, while a fast-forward push publishes work that a revert can undo. The old default protected against the cheap failure and left the expensive one open.

The gate is the shape of the push, not the name of the branch. It pushes when the repo has an `origin` remote and the branch either tracks `origin` or has no upstream yet. A topic branch and the base branch are treated the same, because plenty of solo repos commit straight to `main` and asking there would fire on every run.

It holds and asks when the remote rejects the push, when there is no `origin`, or when the branch tracks some other remote. A rejected push means the branch moved on the remote, and commitkit will not reach for `--force-with-lease` to get past it — rewriting a published branch belongs to [`gitkit`](./gitkit.md) and [`prkit`](./prkit.md), which take a confirmation for it.

Opt out per run by saying `no-push`: "commit only, do not push", "commit, don't push", "don't publish yet". The report then says the commits are local and names the push command. A calling skill uses the same switch: [`afkkit`](./afkkit.md) commits each phase with `no-push` and publishes the branch once, when [`prkit`](./prkit.md) opens the PR, so an unattended run never leaves half-finished work on `origin`. When a caller passed `no-push`, the hand-off returns to that caller instead of crowning the push.

## When it pauses

Delegated committing means it stages files itself without asking. It only stops when intent is genuinely ambiguous: half-finished work in the tree, secrets, changes you probably didn't mean to commit, or a partially staged file where staging the whole path would sweep in deliberately unstaged hunks.

It never runs `git add -A` blindly across unrelated concerns. If nothing in scope has changed, it stops and says so.

If a commit fails — a pre-commit hook rejects it — the `&&` chain stops at that group, later groups stay uncommitted, and the hook output gets surfaced. It never retries blindly or reaches for `--no-verify` unless told to.

## The message-only route

Asking for a message in a live session ("draft a commit message") takes a separate read-only route. It reads the staged diff, or the session's changes when nothing is staged (the whole tree under `all`), writes the message, prints it, and stops. It runs only read commands, and it proves that: it hashes the commit, the staged diff, and the refs before and after, and the two records must match. The route exists because the older wording said "do everything except the final commit", which still staged files and pushed.

## Draft mode

The other way to run commitkit is from a git tool that has no agent session behind it — a lazygit custom command, a git hook, anything that shells out. That caller inlines `SKILL.md`, appends the staged diff, captures stdout, and drops the result into its commit panel. Draft mode exists for that path.

Two things change, and both follow from who is driving.

**One commit, not many.** Multiple commits is the whole point of the main procedure, and it depends on commitkit being able to stage files itself. A commit panel has already staged the set and won't let anything restage it, so the default inverts: one message for whatever is staged.

**Output is the message, nothing around it.** No preamble, no code fence, no summary table, no hand-off. The runner doesn't read the output, it *pastes* it, so a friendly opening line lands in the commit as a friendly opening line. This is also why draft mode overrides the codeblock fallback the skill uses elsewhere when it has no shell: a fence helps a human who copies by hand and breaks a pipe.

Type, mandatory scope, and the required body carry over unchanged. The payload can also carry `git log --oneline`, which is what lets a toolless run still match the repo's existing style, and a `[diff truncated]` marker, which the message works around silently rather than confessing. An empty payload produces no output at all.

## Hands off to

It depends on where the branch already is, which is why the push chain ends with a `gh pr view` and the hand-off reads the answer instead of assuming one.

On a branch with no pull request, [`prkit`](./prkit.md) opens one from exactly these commits. On a branch that already has an open pull request, the commits landed on it the moment they pushed, so a second PR is the wrong move and the report crowns the review step instead — [`mergekit`](./mergekit.md) to reply and re-request review. A merged or closed PR means the branch is spent, and the report crowns a fresh branch with [`gitkit`](./gitkit.md). When the push was held or skipped, the push outranks all of it, because commits that exist nowhere but your machine are the most useful line in the report.

It never amends or rewrites history without an explicit ask.

## Install

```sh
npx skills add mimukit/skills -s commitkit
```

Source: [`skills/commitkit/SKILL.md`](../../../skills/commitkit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`634d5d7` on 2026-09-19._
