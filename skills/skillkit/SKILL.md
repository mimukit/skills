---
name: skillkit
description: >-
  Create a new skill from scratch for this collection, conventions and testing included. Use when the user wants to author, scaffold, or draft a new skill, runs "/skillkit", or says something like "help me make a skill for X". Interviews for intent, proposes on-brand kit names, drafts a conventions-compliant SKILL.md.
license: MIT
allowed-tools: Read, Edit, Write, Bash
metadata:
  internal: true
---

# skillkit

Authoring skill for this collection. It turns a rough idea ("I want a skill that does X") into a lean, conventions-compliant `skills/<name>/SKILL.md`, then a test plan you can actually run. Every skill here is authored from scratch — never forked — and obeys [`AGENTS.md`](../../AGENTS.md); skillkit exists so you don't re-derive those rules each time.

## Invocation

`/skillkit` — or any natural "create/author/scaffold a skill" request. If the user hasn't said what the skill should *do*, ask before anything else. Drive the procedure below one step at a time; don't jump ahead to drafting before intent, visibility, provenance, and name are settled.

## Procedure

### 1. Gather intent
Ask what the skill should do and *when it should trigger* (the real user phrasings). Optionally ask for example skill links; if given, skim them for structure ideas — non-blocking, and only if fetching is available. Capture: the job, the trigger conditions, and any hard constraints (tools it needs, things it must not do).

### 2. Visibility (internal or public?)
Ask whether this is an **internal** repo-only skill or a **public** publishable one — it changes the rules for everything downstream (see `AGENTS.md` → *Visibility*).
- **internal** (like diffkit, skillkit): a maintenance/meta skill for this repo. Repo coupling is fine — it may reference `AGENTS.md`, `make`, `baselines.json`, and use repo-relative links. Stamp `metadata.internal: true`. skills.sh hides it from discovery.
- **public** (like commitkit, humankit): a shareable skill. It **must** follow the Portability rules below and stamp `metadata.internal: false`. It gets discovered and listed on skills.sh automatically once pushed.

### 3. Provenance (original vs. "my version of")
Ask: is this **original**, or **your version of an upstream skill**?
- **Original** (like diffkit): no `baselines.json` entry.
- **Upstream-inspired**: collect `repo` (e.g. `owner/name`), `path` (to the upstream `SKILL.md`), and `branch`. You'll wire this in step 5 so [`diffkit`](../diffkit/SKILL.md) can track it later.

### 4. Propose names
Suggest **3–5 `kit` names** and recommend one. Rules (from `AGENTS.md`): one lowercase word, the **functional term leads** so it stays searchable (people search `commit`, not `kit`), `kit` appended, shorten an awkward root rather than force a clumsy join (`humanize` → `humankit`), and avoid collisions with well-known tools. Let the user pick. The chosen name **must** equal the directory name.

### 5. Draft
Create `skills/<name>/SKILL.md` from the frontmatter template in `AGENTS.md`, applying the **Quality bar** below, and stamp `metadata.internal` from step 2. Keep it lean — prefer one file.
- If **public**, apply the **Portability** checklist below as a hard gate — the skill must stand alone once installed.
- If **upstream** (step 3), add the entry to `baselines.json` with both watermarks `null`:

```json
"<name>": {
  "sources": [
    { "repo": "<owner/name>", "path": "<path/to/SKILL.md>", "branch": "main", "last_reviewed_sha": null, "last_reviewed_at": null }
  ]
}
```

### 6. Review loop
Show the draft. Take edits and iterate until the user explicitly approves. Don't proceed to testing on a draft the user hasn't signed off.

### 7. Test plan + live test
Write a **disposable test-plan file** at the repo root, `<name>-testplan.md`, so the user can follow it in a fresh session. It contains:
- **Setup / cleanup** — `make link name=<name>` and, when done, `make unlink name=<name>`; a note to test in a **fresh session** (the skill list loads at startup).
- **3–5 trigger prompts** that *should* fire the skill (varied, realistic phrasings), each with expected behavior and a pass box.
- **2–3 near-miss prompts** that should *not* fire it (guards against overtriggering), each with why it should stay silent.
- **Behavioral assertions** — a checklist for a real run (asks intent before drafting, applies visibility rules, proposes 3–5 kit names, passes `make lint`, stops at the commit hand-off).

The file is scratch: tell the user it's untracked and to delete it (or gitignore it) when finished — it isn't meant to ship. Then inject the skill for the live trial with `make link name=<name>`.

### 8. Finish
- Run `make lint name=<name>`; fix any `E:` and address `W:` before handing off. For public skills, lint also flags likely portability breaks.
- Update the **README skills table** (`README.md`): a row with the name, a one-line description, its visibility (internal/public), and the baseline column (`— (original)` or the upstream `repo`).
- Hand off: surface a suggested conventional commit message (e.g. `feat(<name>): add <name> skill`) for the user to run. **Do not commit automatically** — committing is the user's call.

## Quality bar

Apply these while drafting; they are the difference between a skill that triggers and reads well and one that doesn't:

- **Front-load the leading word** — the first words of `name` and `description` do the invocation work; put the functional term there.
- **"Use when" trigger** — `description` starts with what it does, then a plain-English "Use when …" clause, phrased slightly pushy to fight undertriggering (name the phrasings/commands that should fire it).
- **Skills are for what the model can't already do** — a skill only fires for tasks the base model can't handle directly. If the guidance is obvious, it won't trigger no matter how you word it.
- **Stay lean; progressive disclosure** — prefer one `SKILL.md`. Add a satellite file (`references/…`) only when content is *large* **and** needed *only sometimes*; guidance needed on every run belongs inline.
- **One meaning, one place** — no duplication. For internal skills, point to `AGENTS.md` for conventions instead of restating them; for public skills, inline what they need (see Portability).
- **Prune no-ops** — test every line for relevance; delete weak sentences rather than trimming them. Explain the *why* behind a rule when it isn't obvious.
- **No hard-wrapping** — write each paragraph and list item as one continuous line (see `AGENTS.md`). Keep line structure only in code fences, tables, and YAML frontmatter.
- **kit naming + frontmatter** — obey the `kit` rules and the `AGENTS.md` template exactly; `name` must match the directory; declare `metadata.internal`.

## Portability (public skills only)

A public skill is installed on its own into arbitrary environments — only its own directory travels, so it must stand alone:

- **Self-contained** — inline the conventions it relies on. No repo-relative links (`../…`), and no hard dependency on `make`, `baselines.json`, `AGENTS.md`, or repo `scripts/`. If it needs a helper script, bundle it inside the skill's own directory.
- **Machine/OS-agnostic** — no absolute paths, no platform-specific assumptions; prefer instructions that work on any shell or none.
- **Environment-degrading output** — when a filesystem and shell are available, write/edit files directly; when they aren't (e.g. a browser-based agent), print the finished artifact as a codeblock for the user to save, and skip repo-only steps like `make link`/`make lint`.

Internal skills are exempt — they live and die in this repo and may use its machinery freely.

## Notes

- skillkit is **internal** (`metadata.internal: true`) and **original** (no `baselines.json` entry). Like diffkit, it's a meta/maintenance skill for this collection, not a published skill.
- Add scripts or satellite files to a *new* skill only when it genuinely needs one — never speculatively. Per-skill scripts live in the skill's own directory; the repo-root `scripts/` is for repo management only.
