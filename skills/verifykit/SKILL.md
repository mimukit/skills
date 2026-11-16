---
name: verifykit
description: >-
  Show a frontend change in a real browser, or prove it for a PR: drive the feature, capture screenshots (plus a short GIF for proof), and publish proof so a pull request can embed it inline; or set up the browser driver and the publish path on a machine. Use when a frontend change is built and you want to see it or want visual evidence it works before opening the PR: "show me what it looks like", "screenshot this", "verify this feature", "record the flow working", "prove the UI change", "/verifykit", when a PR needs proof artifacts to attach, "set up verifykit", or "install the browser driver".
license: MIT
allowed-tools: Bash, Read, Write, AskUserQuestion
metadata:
  internal: false
---

# verifykit

Drive a just-built frontend feature the way a user would and capture what happens. `show` hands the operator screenshots in the session. `proof` captures screenshots plus one short GIF and publishes them so a pull request can embed them inline. `setup` readies a machine and a repo for both.

## When this fires

After a frontend feature is built and you want to look at it or prove it works. If the change is backend/CLI-only with nothing to drive, say so without inventing a flow, and route to **qakit** for a manual test plan (`/qakit`); without qakit, name the commands and endpoints a person should exercise by hand. For tests, a hand-test checklist, or a source review, route to **testkit**, a manual-QA skill, or a code-review skill instead of capturing.

- **`show`.** Screenshots to a local path, nothing published.
- **`proof`.** A request that names a PR, proof, a record, or proving, or a PR step that needs proof artifacts. Screenshots plus a GIF, bundled and published for the PR body.
- **`setup`.** A request to set up verifykit or install the driver. Installs what is missing and reports what is present.

**When the verb is ambiguous, run `show`.**

## Shared procedure

Every capture mode (`show` and `proof`) runs these steps first. `setup` skips them and starts in its own file.

### 1. Scope the feature and find the entry point

Resolve the **full change target**: `git diff HEAD`, untracked files (`git ls-files --others --exclude-standard`, read each one), and `git diff <base>...HEAD`. Take the base from **gitkit** when it is installed; otherwise use `git symbolic-ref --short refs/remotes/origin/HEAD` with the `origin/` prefix removed, else the first of `main` or `master` that resolves. Read the linked issue or plan when there is one. From these, learn which screens, routes, components, or flows the change touches.

Record the **tested revision** before you drive: the application commit (`git rev-parse HEAD`) and the dirty state (`yes` when `git status --porcelain` prints anything, else `no`). Find the dev-server command and the entry URL, and confirm the URL before driving.

Pick a **slug** for this run: the linked **issue number** when there is one, else a short lowercase kebab-case **feature slug** from the branch/diff (e.g. `login-throttle`). Each mode forms its run directory from the slug and the run's ISO creation date. A run directory under `docs/verify/` takes the next serial: take the highest leading four-digit serial in `docs/verify/` across this worktree, every other worktree that `git worktree list` names, and `origin/<default branch>` (`git ls-tree --name-only origin/<base> docs/verify/` after `git fetch origin <base>`), and add one; start at `0001` when there is none. Scan all three, because parallel worktrees otherwise take the same serial. Skip a source that fails, such as no remote, and without git list the directory only. The serial is per directory and never reused.

This step is done when every changed, staged, untracked, and committed path is classified as visual or not, the entry URL is confirmed, and the commit and dirty state are recorded.

### 2. Choose the flows to drive

Derive candidate flows from the diff as distinct **user entry points**: a changed route/page, a form or dialog, a component tied to a user action. Then:

- **Explicit instruction wins.** If the invocation names a flow ("verify the checkout flow", "show me the settings page"), drive that.
- **One flow** touched → drive it, no question.
- **Multiple flows** touched → list the candidates with short labels and **ask the user which to capture** (allow selecting several). Drive each chosen flow and label its captures as a separate section. Never silently guess a "primary" flow.

This step is done when every flow to drive is named, by the invocation, by the single candidate, or by the user's choice.

### 3. Pick the capture backend (by precedence)

Detect what's available and use the best, in order:

1. a **CLI browser driver on `PATH`** that takes a URL and writes a screenshot to disk, for example `playwright-cli`. Probe each listed binary with `command -v`;
2. a **browser-automation MCP** (drives a real browser, takes screenshots);
3. **computer use** / desktop screen capture;
4. **none of them** → degrade: don't fake it. Print a short manual capture recipe (what to click, what to screenshot), name verifykit `setup` as the next move to install the driver, and stop. Never run `setup` from inside a capture.

Record which backend was used in the hand-off. This step is done when one backend is chosen, or the manual recipe is printed and the run has stopped.

### 4. Handle auth and required state

verifykit reuses state; it never manufactures it. In order: **reuse** an already-authenticated session, a stored browser state file, or test credentials the project already exposes. If the flow is gated and none is available, **ask once** for the entry URL and credentials (or a seed command to run). If the user can't or won't provide them, **degrade gracefully**: capture up to the auth boundary and note where it stopped. Run a seed command you're *handed*, but never invent one, seed a database, or run migrations yourself.

**Bound state-changing flows before you drive them.** When any selected flow takes a create, delete, submit, payment, invite, or email-sending action:

- Name the environment from the entry URL and the app's config: local, a dev or preview deploy, or a shared or production host.
- List each state-changing action the flows will take, and the record or account it touches.
- Drive those actions without a question only on a local or throwaway environment with test data. For any other host, ask once with the list; drive only the actions the user permits.
- When the user declines, capture up to the action, not through it, and note the boundary.

This step is done when the auth state is reused, given, or recorded as a boundary, and every state-changing action is permitted or recorded as a boundary.

## Modes

_Write every hand-off in this skill in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

The mode bodies live in one file each under `modes/`. Route with [When this fires](#when-this-fires), read that one file, and follow it. Everything above this line applies to every mode and is not restated in the mode files.

- Mode `show` → read [modes/show.md](modes/show.md), then follow it.
- Mode `proof` → read [modes/proof.md](modes/proof.md), then follow it.
- Mode `setup` → read [modes/setup.md](modes/setup.md), then follow it.

## Notes

- **`allowed-tools` covers the primary path.** The browser MCP fallback arrives as server-named tools (commonly `mcp__<server>__*`) that the list cannot name. A host that enforces `allowed-tools` strictly must grant the browser MCP; else the capture step degrades to the manual recipe.
- **No mp4.** A hosted mp4 does not embed inline in a PR body, because GitHub only renders video uploaded through its web composer, so the proof format is screenshots + GIF. A `raw.githubusercontent.com` mp4 renders as a bare link, and a `<video>` tag is stripped (GitHub Markdown API, checked 2026-11-16).
