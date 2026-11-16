---
name: repokit
description: >-
  Configure a GitHub repo through gh in four modes: an inferred About description and topics, the workflow labels (issuekit's lifecycle and priority sets plus `ai-review`), a new-repo setup (house settings, baseline files, About, labels), and a docs/ renumbering into creation order. Use when the user says "set the repo description", "add topics", "provision the workflow labels", "set up this new repo", or "renumber the docs".
license: MIT
disable-model-invocation: true
allowed-tools: Bash, Read, Write
metadata:
  internal: false
---

# repokit

Configure a GitHub repository through the [`gh` CLI](https://cli.github.com) in four modes. Route to a mode from what the user asks. A vague "set up this repo" or "configure this repo" is `setup`, the umbrella that runs `about` and `labels` on top of the house settings and baseline files. `setup` does not run `docs`, because a fresh repo has no artifacts to renumber.

**If no mode is clear, ask first.** Present the four modes and let the user pick before touching anything.

_Write every hand-off in this skill in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

Read the one mode file and follow it. Everything in this root applies to every mode and is not restated in the mode files.

- Mode `about` → read [modes/about.md](modes/about.md), then follow it.
- Mode `labels` → read [modes/labels.md](modes/labels.md), then follow it.
- Mode `setup` → read [modes/setup.md](modes/setup.md), then follow it.
- Mode `docs` → read [modes/docs.md](modes/docs.md), then follow it.

## Preflight (every mode)

**`docs` is the exception to this section and the next one.** It renames files in the working tree and calls GitHub not at all, so it runs on a local-only repo. Its own file states the checks it does need. Everything below applies to `about`, `labels`, and `setup`.

- If `gh` is missing or unauthenticated, say so and point to `https://cli.github.com` / `gh auth login`. Don't work around it.
- If there's no GitHub remote (`gh repo view` fails), stop and say so. That covers `setup` too: creating the repo is the user's move (`gh repo create`), and repokit begins after it exists.
- **No shell or `gh` at all** (e.g. a browser-based agent)? Do the reasoning from what the user provides and **print the exact `gh` commands** for them to run, whether the description/topics lines, the `gh label create` block, or the `gh repo edit` settings line, as a codeblock to paste. `setup`'s scaffold files degrade the same way: print each file as a fenced block with its path.

**Safety stance, for the whole skill.** **Preview every mutation and get an OK before it runs.** `setup` is the one exception: the user asked for it to run on defaults, so it applies them and reports every change in its hand-off. `about` and `labels` run on their own keep their approval questions. Always echo the exact command(s) you run.

**Re-run safe.** Every mode reconciles against what's already there, so a second run on an unchanged repo proposes nothing and mutates nothing.

## Detect (every mode)

Read the repo's current state once before proposing anything. Fetch what the chosen mode needs plus the guardrail flags:

```sh
# guardrail flags + about state
gh repo view --json isArchived,isFork,isTemplate,description,homepageUrl
gh api repos/{owner}/{repo}/topics --jq '.names'    # current topics (about mode)
gh label list --json name,color,description          # current labels (labels mode)
```

`setup` additionally fetches the settings it diffs; its mode file names the exact fields.

Check the guardrail flags **before** any mutation:

- **Archived** (`isArchived: true`). GitHub rejects metadata edits on an archived repo, so **stop** and tell the user to unarchive first.
- **Fork or template** (`isFork` / `isTemplate`). Its metadata is often inherited or throwaway, so **confirm the user means to edit *this* repo** before continuing.

## Notes

- **Never** delete a repo's topics wholesale or its labels outside the canonical sets without an explicit ask.
- The lifecycle and priority maps are a **shared contract with issuekit**: the same names across both namespaces, with the same colors and meanings, and repokit's descriptions canonical. The automation set is repokit's alone, because issuekit runs the tracker and `ai-review` acts on a pull request.
- **repokit never commits.** `setup` writes scaffold files and leaves them unstaged and `docs` leaves its renames staged; grouping and committing either is a commit skill's job, or the user's.
- Prefer `gh`'s structured JSON (`--json`/`--jq`, the topics API) over scraping human-readable output.
