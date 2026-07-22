# Publishing to the skills.sh directory

How this repo gets from local to the [skills.sh](https://www.skills.sh) directory. Read this before the first push, and skim the checklist before every release.

## How listing actually works

**There is no submit form and no publish step.** skills.sh discovers a repo through install telemetry: the first time anyone runs `npx skills add <owner>/<repo>` against a public GitHub repo containing a valid `skills/<name>/SKILL.md`, the repo gets a page in the directory and starts climbing the leaderboard. Getting listed therefore reduces to three things:

1. The repo is **public** on GitHub.
2. Each skill is a folder with a valid `SKILL.md` (frontmatter + body).
3. Someone installs it with the CLI at least once.

Internal skills (`metadata.internal: true`) are hidden from discovery — they only install under `INSTALL_INTERNAL_SKILLS=1` — so they never appear on the directory page. Only the public skills (`internal: false`) are listed.

## Pre-push checklist

- [ ] `make lint` is clean — every skill carries `metadata.internal`, and public skills pass the portability checks.
- [ ] Each public skill is **self-contained**: conventions inlined, no repo-relative links, no hard dependency on `make`/`AGENTS.md`/`scripts/`, and it degrades gracefully when there's no filesystem (prints its output instead of writing files).
- [ ] Every directory name matches its frontmatter `name` exactly, is lowercase-hyphenated, 1–64 chars, no leading/trailing or consecutive hyphens.
- [ ] Each `description` front-loads an English **"Use when …"** trigger — skills.sh routes activation primarily off the description, so treat it as a routing rule, not a title.
- [ ] `make security` shows no **High Risk** skill — it's a local heuristic stand-in for the scanners skills.sh runs at publish time (Gen / Socket / Snyk), so a High here previews a public flag on the directory page. Med/Low are informational (e.g. a skill that legitimately runs the shell); High means evasion-flavored wording or a destructive command to fix first.
- [ ] Working tree is committed; `git status` is clean.
- [ ] `README.md` skills table matches what's actually in `skills/` (no advertised-but-missing entries).

## First-time push

The repo has no remote yet. Create the public GitHub repo and push `main` in one step with the `gh` CLI (authenticated as the repo owner):

```sh
gh repo create mimukit/skills --public --source=. --remote=origin --push \
  --description "Personal collection of AI agent skills, installable via skills.sh"
```

That creates `github.com/mimukit/skills`, wires up `origin`, and pushes `main`. Verify:

```sh
git remote -v
gh repo view mimukit/skills --web
```

## Subsequent releases

Once `origin` exists, publishing a change is just:

```sh
make lint          # gate on conventions
git push origin main
```

skills.sh re-reads the repo on the next install; there is nothing else to trigger.

## Sharing the install command

Listing is telemetry-driven, so the install command *is* the publish action. Put it where people will run it (README, socials, docs):

```sh
npx skills add mimukit/skills               # all public skills
npx skills add mimukit/skills -s commitkit  # just one
```

## Optional: customize the directory page

Once the repo has a page, drop a `skills.sh.json` at the repo root to group how skills display. It only affects the skills.sh page — it does not change how the CLI installs anything, and skills.sh only picks it up after the repo has been seen by telemetry (i.e. after a first install), with page caching on top.

```json
{
  "$schema": "https://skills.sh/schemas/skills.sh.schema.json",
  "notGrouped": "bottom",
  "groupings": [
    {
      "title": "Git & GitHub",
      "description": "Commits and pull requests from the real diff.",
      "skills": ["commitkit", "prkit"]
    }
  ]
}
```

Matching is case-insensitive and treats spaces/underscores like hyphens; max 50 groups and 500 skills per group. Hold off until there are enough public skills that grouping earns its keep — two skills don't need sections.

## Sources

- [skills.sh — homepage & install model](https://www.skills.sh)
- [skills.sh — customize (skills.sh.json schema)](https://www.skills.sh/docs/customize)
- [Vercel KB — Agent Skills: creating, installing, and sharing](https://vercel.com/kb/guide/agent-skills-creating-installing-and-sharing-reusable-agent-context)
