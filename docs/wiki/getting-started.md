# Getting started

Two very different people land here, and they need opposite things.

| You want to | Start at |
|-------------|----------|
| Install these skills and use them in your own projects | [Install and use the skills](#install-and-use-the-skills) |
| Change a skill, add one, or fork the collection | [Work on the collection](#work-on-the-collection) |

Using them takes one command and no clone. Working on them needs the repo. The two paths below are independent — you don't need the first to do the second, or the second to do the first.

---

## Install and use the skills

By the end of this section you'll have skills from this collection installed in your agent, know how to invoke one, and know how to update or remove them.

### What you need

Node (for `npx`) and an agent that reads skills — Claude Code, Codex, Cursor, Amp, Antigravity, opencode, and a dozen others are supported by the installer. That's it. Don't clone this repo; the installer fetches what it needs.

### Look before you install

```sh
npx skills add mimukit/skills -l
```

`-l` lists every skill in the repo with its full description and installs nothing. Each description front-loads an English **"Use when …"** trigger, which is the same text your agent routes on, so reading the list tells you both what a skill does and what makes it fire.

### Install

```sh
npx skills add mimukit/skills               # the whole collection
npx skills add mimukit/skills -s commitkit  # just one
```

Repeat `-s` to pick a handful — `-s commitkit -s prkit`. A comma-separated list is *not* accepted; the CLI treats `commitkit,prkit` as one unknown name and reprints the available skills instead of installing. Either way it runs its security scanners (Gen, Socket, Snyk) and prints a verdict per skill before writing anything.

### Where they land

By default the install is **project-level** — scoped to the directory you ran it in:

```
./.agents/skills/commitkit/SKILL.md    the real files, read by most agents
./.claude/skills/commitkit             symlink, for Claude Code
./skills-lock.json                     what's installed, and at what content hash
```

Commit `skills-lock.json` and your team gets the same skills at the same versions.

Add `-g` to install at the user level instead (`~/.claude/skills` and `~/.agents/skills`), which makes the skills available in every project on the machine. Project-level is the better default when a skill's conventions belong to one codebase; global is better for the ones you want everywhere, like `commitkit` or `humankit`.

### Invoke one

Two ways, and the first is the one to reach for:

- **Describe the task.** "Commit this", "review my changes", "write a QA plan for this feature". The agent matches your wording against the skill's `description` and loads it. Every description here is written as a routing rule for exactly this reason, so plain English works better than you'd expect.
- **Name it explicitly.** `/commitkit` in Claude Code, or just "use commitkit". Do this when you want a specific skill and don't want to negotiate with the router.

Skills run with your agent's full permissions. Read one before you trust it with your repo — `SKILL.md` is plain Markdown, and every skill here is [documented page by page](./index.md#the-skills).

### Try one without installing

```sh
npx skills use mimukit/skills@commitkit
```

This prints the skill as a ready-to-paste prompt and writes nothing to disk. Useful for a one-off, or for reading a skill in full before you commit to installing it.

### Which skill to reach for

Install `statuskit` and ask it. It surveys the project read-only — working tree, issues, open PRs, unfiled plans — and crowns a single next move, routed to the kit that does it. It's the intended entry point when you sit down and aren't sure.

Otherwise: [the workflow guide](./workflow.md) maps how the skills compose into one loop (**decide → plan → file → build → ship → land**), and [the skill pages](./index.md#the-skills) cover each one on its own — what it does, when it fires, how its modes work, what it hands off to.

### Update, list, remove

```sh
npx skills update            # pull the latest version of everything installed
npx skills ls                # what's installed, and where
npx skills remove -s commitkit
```

`update` takes `-g` / `-p` to scope to global or project skills. `remove` takes the same `-s` and `-g` flags as `add`.

### Where to go next

Read [the workflow guide](./workflow.md) — the skills are individually useful, but the loop is the point, and the guide is what turns a shelf of separate tools into one routine.

---

## Work on the collection

By the end of this section you'll have a skill from this repo running live in your AI tools, edited, and checked against the collection's conventions.

### Before you start

You need `git`, `make`, and `bash`. The shell scripts are written to run on macOS's system bash 3.2 — no associative arrays, no `mapfile` — so nothing here needs a newer bash installed.

[`fzf`](https://github.com/junegunn/fzf) is optional. The interactive pickers use it when it's on your `PATH` and fall back to a numbered menu when it isn't.

### Clone and look around

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

### See what's installed

```sh
make list
```

Each skill gets a badge showing whether the repo copy is what's currently live in your AI tools:

```
  commitkit        ■ real
  gitkit           ■ real
  humankit         ■ real
  ...

29 skills · ● linked  ⇄ swapped  ◑ partial  ◆ foreign  ■ real  ○ unlinked
```

`■ real` means a non-symlink install is sitting there — typically one you installed from skills.sh. `○ unlinked` means the skill exists only in this repo and isn't active anywhere. Either way, the repo copy is *not* what your agent is reading yet. [Reference](./reference.md#link-status-badges) has the full badge table.

### Link a skill for live editing

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

### Edit it

Open `skills/commitkit/SKILL.md` and change something. There's no build step and no reload — the symlink means your agent reads the file on its next invocation. Save, invoke the skill, see the change.

### Check your work

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
  ✓ docs/wiki/skills/

0 error(s), 0 warning(s)
```

Lint checks each skill's frontmatter and cross-references, then — on a full run only — verifies the two tables that are deliberately duplicated across skills still agree, that [the workflow map](./workflow.md) doesn't name a skill or mode that no longer exists, and that [the per-skill pages](./index.md#the-skills) still line up one-to-one with the skills they document. Errors fail the run; warnings don't. Scope it to one skill with `make lint name=commitkit`, which skips those cross-file checks.

Then the security scan:

```sh
make security
```

It's a local heuristic stand-in for the scanners skills.sh runs at publish time. `Med` and `Low` findings are informational — a skill that legitimately drives the shell will always report `Med`. Only `High` fails the run, and it means something to fix before pushing.

Both commands run in CI on every push to `main` and every pull request.

### Put it back when you're done

```sh
make unlink name=commitkit
```

This removes the symlink and restores anything that was backed up, so your published install comes back untouched.

### Next

Adding a skill rather than editing one? See [Add a new skill](./how-to/add-a-new-skill.md) — there's a reader-facing page to write and five more files to update beyond the skill itself, and lint only catches two of them.

To understand why the repo is laid out this way, read [Architecture](./architecture.md).

_Verified against `main`@`c772308` on 2026-08-18._
