# Getting started

By the end of this page you'll have a skill from this repo running live in your AI tools, edited, and checked against the collection's conventions.

## Before you start

You need `git`, `make`, and `bash`. The shell scripts are written to run on macOS's system bash 3.2 — no associative arrays, no `mapfile` — so nothing here needs a newer bash installed.

[`fzf`](https://github.com/junegunn/fzf) is optional. The interactive pickers use it when it's on your `PATH` and fall back to a numbered menu when it isn't.

## Clone and look around

```sh
git clone git@github.com:mimukit/skills.git
cd skills
make help
```

`make help` prints the full command surface:

```
mimukit/skills — targets:
  link [name=<skill>]    Symlink a skill into ~/.claude/skills + ~/.agents/skills (no name → picker)
  unlink [name=<skill>]  Remove a dev symlink (no name → picker of linked skills)
  list                   List all skills with their link status
  lint [name=<skill>]    Check skills against AGENTS.md conventions
  security [name=<skill>] Heuristic security scan (local stand-in for skills.sh scanners)
  help                   Show this help
```

## See what's installed

```sh
make list
```

Each skill gets a badge showing whether the repo copy is what's currently live in your AI tools:

```
  commitkit        ■ real
  gitkit           ■ real
  humankit         ■ real
  ...

24 skills · ● linked  ⇄ swapped  ◑ partial  ◆ foreign  ■ real  ○ unlinked
```

`■ real` means a non-symlink install is sitting there — typically one you installed from skills.sh. `○ unlinked` means the skill exists only in this repo and isn't active anywhere. Either way, the repo copy is *not* what your agent is reading yet. [Reference](./reference.md#link-status-badges) has the full badge table.

## Link a skill for live editing

```sh
make link name=commitkit
```

This symlinks `skills/commitkit/` into both `~/.claude/skills/` (Claude Code) and `~/.agents/skills/` (Codex, opencode, antigravity, and others). One command, every tool.

Run it with no `name=` to get a picker listing every skill with its current status.

If something is already installed under that name, `make link` doesn't delete it — it moves it aside to a `commitkit.skshbak` sibling first and reports what it did:

```
backing up existing install: /Users/you/.claude/skills/commitkit -> /Users/you/.claude/skills/commitkit.skshbak
linked /Users/you/.claude/skills/commitkit -> /Users/you/Github/skills/skills/commitkit
```

`make list` now shows `⇄ swapped` — the repo copy is live under the real name, with your published install parked safely next to it.

## Edit it

Open `skills/commitkit/SKILL.md` and change something. There's no build step and no reload — the symlink means your agent reads the file on its next invocation. Save, invoke the skill, see the change.

## Check your work

```sh
make lint
```

A clean run looks like this:

```
  ✓ commitkit
  ✓ gitkit
  ...
  ✓ shared tables (label map · type table)
  ✓ docs/wiki/workflow.md

0 error(s), 0 warning(s)
```

Lint checks each skill's frontmatter and cross-references, then — on a full run only — verifies the two tables that are deliberately duplicated across skills still agree, and that [the workflow map](./workflow.md) doesn't name a skill or mode that no longer exists. Errors fail the run; warnings don't. Scope it to one skill with `make lint name=commitkit`, which skips those cross-file checks.

Then the security scan:

```sh
make security
```

It's a local heuristic stand-in for the scanners skills.sh runs at publish time. `Med` and `Low` findings are informational — a skill that legitimately drives the shell will always report `Med`. Only `High` fails the run, and it means something to fix before pushing.

Both commands run in CI on every push to `main` and every pull request.

## Put it back when you're done

```sh
make unlink name=commitkit
```

This removes the symlink and restores anything that was backed up, so your published install comes back untouched.

## Next

Adding a skill rather than editing one? See [Add a new skill](./how-to/add-a-new-skill.md) — there are three files to update beyond the skill itself, and lint only catches one of them.

To understand why the repo is laid out this way, read [Architecture](./architecture.md).

_Verified against `main`@`fd96414` on 2026-08-07._
