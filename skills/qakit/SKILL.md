---
name: qakit
description: >-
  Generate a QA plan for a feature just implemented, grounded in the actual code changes: the agent runs every check with an observable result, in a headless browser when one is available, and leaves a short manual list of what needs human judgment, saved to docs/qa. Use when a coding session wraps and you want to hand-test the result, or the user says "write a QA plan", "make a manual test plan", "how do I test this", "generate a testing plan for this feature", "try to break this component", or runs /qakit.
license: MIT
allowed-tools: Read, Bash, Write
metadata:
  internal: false
---

# qakit

The agent runs every check with an **observable pass condition** and records the result in the plan's **Automated verification** section. The plan's manual cases keep only human **judgment** (the screen looks right, matches the mockup, feels good, reads well), grouped by **setup**, with a screenshot gallery for the screens to judge. The plan is written to `docs/qa/`.

## When this fires

qakit writes no test code. When the user wants *new automated* tests (unit, integration, E2E), say so and stop without a manual plan. Route tests for new work to **implementkit** in TDD mode, and a codebase with no tests to **testkit**. Without those kits, name the plain step: write the tests beside the change.

## Procedure

### 1. Scope the feature
Ground the plan in what was built. Gather, in order of preference:

- **The session context**: what the user asked for and what you implemented this session.
- **The change**: `git diff --stat HEAD` and `git log --oneline -10`. Read a full diff only for a file that carries behavior the session has not already told you about.
- **The user**, only if intent is still unclear. Ask, in one question, what the feature is *supposed* to do and how they exercise it (URL, command, screen, credentials).

Write down, for yourself: the feature's intended behavior, its entry points, and its dependencies (services, data, auth, config).

Record the revision under test, too: `git rev-parse HEAD` and whether `git status --porcelain` is empty. The plan's header stamp and every reused check result bind to this pair.

Diff touches the data layer (a migration, a schema file, a model, or a query) → read [db.md](db.md), then follow it in every step it names.

Change renders data in a UI and a driver is present, or the user asks to try to break a component → read [worst.md](worst.md), then follow it in every step it names.

When the change has a UI, list the **browser drivers** in order of preference: a CLI driver on `PATH` that opens a URL, clicks, reads the page, and writes a screenshot (probe `command -v playwright-cli`), then each browser-automation MCP tool set in this session (a host's own preview browser counts). [Run the automated checks yourself](#5-run-the-automated-checks-yourself) starts the first one and moves down the list when it fails. No driver means the page checks stay with the human, as [Derive the test dimensions](#2-derive-the-test-dimensions) describes. Do not install one; verifykit `setup` does that when it is installed. Read the viewport widths from the project's `DESIGN.md` breakpoints when it has them; otherwise use 1440 px and 375 px.

Find the **disposable target**, if the project declares one: an environment that a documented command destroys and rebuilds, such as a playground app or a local database container, named as throwaway in the project's agent instruction file or README, together with its reset command. A declared target makes state-changing commands agent-verifiable on that target only. Never infer one: a local database that nobody declared throwaway may hold someone's work.

This step is done when intended behavior, every entry point, every dependency, and the revision pair are written down, and you know whether db.md and worst.md apply, which browser drivers you have, and which disposable target the project declares, if any.

### 2. Derive the test dimensions
Generate candidate cases for each dimension that applies: happy path, edge and boundary, negative and error handling, regression, security and permissions, data and state, concurrency and timing, compatibility, accessibility, performance, and usability. When worst.md applies, it adds worst-case values for every rendered field under edge and boundary. When db.md applies, it adds the database assertions under data and state. Name a skipped dimension under *Not covered* only when a reader would expect it.

Tag each case with one of three tiers:

- 🔴 **Critical.** Must pass to ship; a failure blocks release.
- 🟡 **Normal.** Should pass; a failure is a real bug but not a blocker.
- 🟢 **Low.** Nice-to-have, polish, or edge cases with minor impact.

**Split human-only from agent-verifiable.** As you generate cases, sort each checkpoint with one test: *can you write its pass condition as an assertion a script evaluates?* If yes, it is agent-verifiable. That covers command output, HTTP responses, return values, and, with a browser driver, everything a page exposes: text and figures, the URL after a click, an element present or absent, a link's `href` and `target`, a class or attribute such as the theme, keyboard focus order, an accessible name, console errors, and horizontal overflow at a given width. If no, it is human-only: the screen looks right, matches the mockup, reads well in dark mode, feels smooth, or the copy says the right thing. External effects the app cannot observe (a WhatsApp message arrives, a payment settles, an email lands) and anything that needs real credentials or a physical device also stay human-only. Without a browser driver, page checks are human-only too. A command that changes state (a setup, a migration, a drop, a reset) is agent-verifiable only on a declared disposable target; on anything else it stays with the human.

Only the human-only checkpoints reach the plan's test cases. Run the agent-verifiable ones yourself and record their outcomes in the **Automated verification** section. A case often splits: its figures and links go to the agent, and "the layout matches the mockup" stays with the human. Expect a UI plan to keep roughly ten human checkpoints or fewer. When it keeps many more, apply the assertion test to each one again.

This step is done when every dimension has candidate cases or was skipped, every skipped dimension a reader would expect has a *Not covered* line, and every candidate carries a tier and a human-only or agent-verifiable tag.

### 3. Group the cases into scenarios
A **scenario** is one setup, every case that can run on top of it, and one reset at the end. Sort the candidate cases by the starting state each one needs, then:

- **One scenario per distinct starting state.** Two cases that need the same state belong in the same scenario, always.
- **Merge cases that share a setup *and* a flow.** If confirming three behaviors means walking one flow and looking at three things along the way, that's *one* case with three checkpoints, not three cases that each restate the same six steps. **This is a merge, not a relocation**: the merged case gets three checkpoints, not every assertion the three cases spelled out, stacked into a column of boxes.
- **Split only when the flows diverge**: a different entry point, or a case that leaves state the following case can't tolerate.
- **Order within a scenario: read-only first, state-mutating next, destructive last.** A case that deletes the record every other case needs goes at the end, or gets its own scenario.
- **Fewest scenarios that still cover the dimensions.**

Name a scenario for the state it starts from ("Fresh tenant, no data", "Existing user with 200 orders", "Feature flag off") rather than for its topic ("Validation", "Error handling").

Number cases within their scenario: `TC-<scenario>.<case>`, so `TC-2.3` is the third case of Scenario 2.

This step is done when every human-only candidate sits in exactly one scenario, and every scenario has a distinct starting state.

### 4. Write the plan file
Write to `docs/qa/NNNN-qa-<feature-slug>-YYYY-MM-DD.md`, using the next serial, a short lowercase kebab-case feature slug, and the plan's ISO creation date (for example, `0012-qa-login-throttle-2026-07-23.md`). To get the serial `NNNN`, take the highest leading four-digit serial in `docs/qa/` across this worktree, every other worktree that `git worktree list` names, and `origin/<default branch>` (`git ls-tree --name-only origin/<base> docs/qa/` after `git fetch origin <base>`), and add one; start at `0001` when there is none. Scan all three, because parallel worktrees otherwise take the same serial. Skip a source that fails, such as no remote, and without git list the directory only. The serial is per directory and never reused. Keep the whole name stable on later edits; record an updated date inside the document when useful. Create `docs/qa/` if it doesn't exist. Update an existing QA plan for the same artifact in place, and keep its name even when it has no serial.

Structure the file like this:

````markdown
# QA Plan: <Feature name>

_Generated <date> · against `<commit sha>` (<clean or uncommitted changes>) · covers <brief scope>_

## Summary
- What the feature does, in one short sentence.
- What "working" means, in one short sentence.

## Environment
True for the whole plan. Do this once, before Scenario 1.

- Branch / build under test
- Base URL, credentials, and how to obtain any auth token the calls need
- Feature flags / config
- Screenshots: local to this run at `<commit sha>` and not committed. The names under each case match the labels in the gallery.

Launch with:

```sh
<launch command>
```

- [ ] Environment ready

## Test cases at a glance

Priority legend: 🔴 Critical · 🟡 Normal · 🟢 Low

| # | Scenario | Test case | Priority |
|------|----------|-----------|----------|
| TC-1.1 | 1: <starting state> | <short title> | 🔴 Critical |
| TC-1.2 | 1: <starting state> | <short title> | 🟡 Normal |
| TC-2.1 | 2: <starting state> | <short title> | 🟢 Low |

## Scenario 1: <starting state>

**Setup.** Run once, for every case in this scenario.

1. <setup action>

```sh
<setup command>
```

- [ ] Setup complete

### TC-1.1: <short title>  ·  🔴 Critical

**Goal.** <one line: what this case proves>

**Steps**

1. <concrete action a human takes>
   - [ ] <one judgment the tester stops to make right here>
     - <what to look at, when the judgment needs a guide; a plain bullet, not a checkbox>
     - <another thing taken in at the same glance>
     - screenshots: `<screen>-light-1440` · `<screen>-dark-1440` · `<screen>-light-375`
   - [ ] <a second judgment, only when it's a genuinely separate look>
2. <next action; a command goes in its own block>

   ```sh
   <command to run>
   ```

   - [ ] <what the output or screen must show>

**Result**

- [ ] Pass
- [ ] Fail
- [ ] Skipped

**Notes.** _what actually happened on a fail; why it was skipped_

### TC-1.2: <short title>  ·  🟡 Normal
...

**Reset.** Run after every case above, before moving to Scenario 2.

```sh
<reset command>
```

## Scenario 2: <starting state>
...

## Automated verification (by AI agent)
_Checks the agent ran itself. No action needed from the tester; listed here for context and sign-off._

Commands run (one per block; chain with `&&` when they must run together):

```sh
<command 1>
```

```sh
<command 2>
```

- ✅ <command 1> → <what the output confirmed>
- ✅ <endpoint / assertion checked> → <result>
- ❌ <anything that failed, with the actual output> _(if any)_

### Browser checks
_Driven with `<driver>` against `<base URL>` at `<revision>`. <n> screenshots, local to this run and not committed._

- ✅ <page> · <what was asserted> → <the observed value>
- ❌ <page> · <what was asserted> → <the observed value, and what was expected>

## Not covered / needs human judgment
- <anything that can't be scripted: visual polish, UX feel, external integrations, timing>
- <dimension deliberately skipped, and why>

## Overall result
_Tick one when you finish the run, or skip the ticks. Report each failure in the agent session or as a PR comment, and the agent records it here._

- [ ] Pass: every case passed
- [ ] Fail: at least one case failed
- [ ] Partial: cases were skipped or not reached
````

Rules for good cases:
- **Pre-fill the date and the sha** in the header stamp yourself.
- **Overall result goes last**, at the foot of the file.
- **Fixed case body, always these four parts in this order:** **Goal**, **Steps**, **Result**, **Notes**. No case drops one, no case invents a fifth.
- **Goal is one line and says what the case *proves***, not what it does: "an expired token can't reach another tenant's orders", not "test the orders endpoint".
- **Verification lives under the step that produces it.** Never a separate expected-results list at the bottom of the case: a step is followed immediately by its own `- [ ]` checkpoints. A step with nothing to observe has no checkpoints.
- **One checkpoint per *judgment*, not per assertion.** A checkpoint is one thing the tester stops to decide, not one fact the feature asserts. The test to apply: *would they plausibly tick one box and leave the next one unticked?* If they'd settle both in the same glance, it is one checkpoint.
- **Split different judgments; join one judgment applied across a set.** "The footer's headings, links, separator rule and copyright are all legible" is a single look at a single region, so one box. "The icon changed to the moon" and "storage now holds `dark`" are two places to look, so two boxes. The word "and" is not the test; whether the tester's eye has to move is.
- **Detail belongs *under* a checkpoint, as a plain unticked sub-list** that says what to look at:

  ```markdown
  1. Set the state to `light`. Scroll the whole page top to bottom at ≥1280px.
     - [ ] Every block reads correctly, with nothing illegible and nothing invisible on its own background
       - navbar: sticky background opaque; logo, links and control legible
       - hero: heading, sub-copy, both buttons; primary label against the primary fill
       - pricing-table: the toggle in both positions; the featured plan distinguishable; check marks
       - footer: headings, links, separator rule, copyright
  ```
- **A repeated pass gets one checkpoint plus whatever is new.** When a second variant re-runs a sweep the tester already performed (the other palette, the second browser, the next breakpoint, the swapped preset) never enumerate the same items again. **Never write "as above, in `<variant>`".**

  ```markdown
  2. Set the state to `dark`. Scroll the page again.
     - [ ] The same sweep is clean in dark
     - [ ] Nothing is pure-black-on-dark where a muted token was intended
  ```
- **Every checkbox owns its own line**, because a `- [ ]` renders as a clickable checkbox only when it starts a line. This includes Result's three outcomes.
- **Point each visual judgment at its screenshots by name, never by path**, because a path breaks in every other clone. A checkpoint about how a screen looks carries a plain `screenshots:` sub-bullet that names each capture [Run the automated checks yourself](#5-run-the-automated-checks-yourself) took for it, one name per variant, each in backticks and written in full. A name is `<screen>-<light|dark>-<width>`, the file name without `.png`, and it is the label the gallery shows. Leave the sub-bullet out when no driver ran.
- **A screenshot that must last goes through verifykit, not the plan.** The capture folder is local and temporary. When a reviewer needs an image after the run, **verifykit** `proof` publishes the chosen images to a hidden ref and **prkit** embeds them in the PR body. Without verifykit, attach the image to the PR by hand.
- **A Skipped result needs a reason in Notes.**
- **Write the whole plan in ASD-STE100 Simplified Technical English**: Goal, Setup, Reset, Steps, checkpoints, and Not covered. One instruction per sentence, procedural sentences 20 words or fewer, descriptive ones 25 or fewer, active voice, present tense. **Keep one term per thing for the whole plan**: if the setup calls it the *cart*, no later step calls it the *basket*.
- **Every command gets its own ```sh code block**, so the tester copies each one with one click. Never inline a terminal command in prose or a table cell, and never stack commands in one block. When commands must run together, chain them with `&&` on one line in a single block.
- **Every API endpoint gets a runnable `curl`** in its own ```sh block: the full URL (the local base URL or a `$BASE_URL` that **Environment** defines), every required header, and real sample values, with no `<placeholders>`.

This step is done when the file exists at its serial path, every case has all four body parts, and every command and `curl` sits in its own block.

### 5. Run the automated checks yourself
Before handing off, actually run the agent-verifiable checks you split out in [Derive the test dimensions](#2-derive-the-test-dimensions), meaning terminal commands, endpoint hits, and return-value assertions, and record each outcome in the plan's **Automated verification** section (✅ passed with what the output confirmed, ❌ failed with the actual output). For anything you hit over HTTP, paste the **exact `curl` you ran** in its own ```sh block so the human can re-run or adapt it. If there's no shell/filesystem, say so and leave the section for the human to fill.

**What you run.** You run the project's own test, lint, and build commands as they already exist, the read-only checks db.md defines when it applies, the browser checks below, and the bundled `gallery.py`. You write no new test and edit no test file. Fetch no remote code and touch no credentials. A check that would need elevated access goes to the human as a described step.

**One command class you never run, and one you reuse instead of re-running:**

- **Never: anything that destroys or rebuilds state**, such as `*:destroy`, `*:reset`, a teardown-and-rescaffold, a database write or drop, or a `clean` that wipes a build. This includes every scenario's own **Setup** and **Reset** block: those are written *for the human to run*, and the agent never executes them. The one exception is a declared disposable target, below.
- **Reuse: a gate already recorded green on this exact revision**, meaning a test, build, lint, or verify result that names the same HEAD sha and the same dirty state you recorded in [Scope the feature](#1-scope-the-feature). Record what it was, the revision it ran on, and that it passed. A result that names no revision, or a different sha or dirty state, is not reusable: run the gate. Run it also when the change under test **is** that gate.

**Scenarios on a disposable target.** When [Scope the feature](#1-scope-the-feature) found a declared disposable target, run each scenario whose Setup, steps, and Reset touch only that target yourself:

- **Say the target first.** State the target and its reset command in one line before the first command, so the operator can stop you.
- **Run the scenario as written.** Run Setup, then each case's commands in order, then Reset. Run nothing outside the target, and stop the scenario at the first command that would reach another host, another database, or a shared service.
- **Record the evidence in the case.** Tick each checkpoint you confirmed, tick the case's Result, and put the real output, trimmed to the lines that prove the checkpoint, in its **Notes**. Mark the scenario heading `· run by the agent on <target> at <revision>`.
- **Leave the target clean.** End with the declared reset command when the last scenario changed it, and record that run too.

These scenarios stay in the plan as cases, not in **Automated verification**. A command case whose target is not declared disposable stays manual.

**Browser checks.** With a browser driver from [Scope the feature](#1-scope-the-feature), drive the running app and record each page assertion under **Browser checks**. When worst.md applies, run its mock, reload, and assert loop on each screen in scope as well:

- **Reach the app.** Reuse a dev server that already serves the base URL. Otherwise start it once with the plan's launch command, and stop it when the checks end. Run no Setup, Reset, seed, or migration to reach a state, except on a declared disposable target. A check that needs one anywhere else stays a manual checkpoint.
- **Drive local state only.** A click that creates, deletes, submits, pays, or sends writes through the app. Drive it only against a local server with sample or demo data, or a declared disposable target. On any other host, the check stays manual.
- **Assert, then record the observed value.** "✅ `/account/` · Active orders card → `7`" proves more than "✅ figures correct". A ❌ records what the page showed and what the plan expected.
- **Capture the human's screens.** Take one screenshot of each screen a human-only checkpoint judges, in each variant the change supports: light and dark, and each viewport width from [Scope the feature](#1-scope-the-feature) for a responsive page. Save each one as `~/qakit/<plan file name without .md>/<screen>-<light|dark>-<width>.png`, never inside the repo, and write its name into its checkpoint. The folder is the run's own, and nothing in it is committed. When installed, **issuekit** `close` deletes it after the merge and **gitkit** `clean` sweeps old ones; otherwise delete it by hand once the PR merges.
- **Close the browser** when the checks end, because a CLI driver keeps a background browser alive between commands.

When a driver fails to start, record its error once under **Browser checks** and try the next driver on the list. When every driver fails, move the page checks back into the manual cases and name each error in the hand-off. Do not change the driver's sandbox or security settings to make it start; that is the operator's decision.

Do not fix a ❌; qakit writes no code.

This step is done when every agent-verifiable check from [Derive the test dimensions](#2-derive-the-test-dimensions) has a ✅ or ❌ line, or a line that names the revision of the reused result, every scenario on a disposable target has its ticks and output and the target is reset, every human-only visual checkpoint has its screenshots or the plan says why not, and no browser or server you started is still running.

### 6. Build the gallery

Skip this step when no screenshot was captured, and say why in the hand-off.

The bundled [`gallery.py`](gallery.py) builds one page from the plan file. It reads each case, the checkpoints under its steps as the judge questions, and the `screenshots:` names, then groups the images in `~/qakit/<plan file name without .md>/` by case and writes the page there. Resolve the installed skill directory and run the script there; the working directory is the target project. Run plain `python3`, because `python3 -I` hides a Pillow installed for the user.

```sh
python3 "<path-to-this-skill>/gallery.py" docs/qa/<file> --dry-run
```

```sh
python3 "<path-to-this-skill>/gallery.py" docs/qa/<file>
```

```sh
python3 "<path-to-this-skill>/gallery.py" docs/qa/<file> --inline
```

- **Dry run first.** It prints each case with its judge questions and screenshot names, then the missing names and the "Other captures". A missing name is a typo in the plan or a capture that did not happen: fix the plan or take the capture, then run it again. An image in "Other captures" is one no checkpoint names: name it under its checkpoint, or leave it there as context.
- **`index.html` is the page to keep.** It is one self-contained file with every image embedded.
- **`--inline` is for a host that renders HTML in the session.** It writes `inline.html` plus a `web/` folder of smaller copies that the page references by absolute path, styled with the host's theme variables. It warns when the page passes 512 KB. Build it only on such a host.
- **Pillow is optional.** With it, the script converts the images to WebP. Without it, `index.html` embeds the original PNGs, a larger file, and the script says so. Report that line in the hand-off.
- **The page names the capture commit** from the Environment line, and it shows a stale warning when `HEAD` has moved past that commit. A qakit refresh on the same plan builds the page again.

Without Python 3, skip the page and say so in the hand-off.

This step is done when the dry run shows no missing name and `index.html` exists, plus `inline.html` on a host that renders HTML, or the hand-off says why there is no gallery.

### 7. Hand off

_Write this section in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

Close with three short beats:

- **Failures first.** When a browser or automated check failed, list each ❌ with its observed value before anything else.
- **What changed.** Give a one-line summary: how many scenarios and manual checkpoints (and how many 🔴 critical), plus the automated and browser results (e.g. "2 scenarios, 7 manual checkpoints, 2 critical · 6 commands and 41 browser checks ran, 1 failed · Scenario 3 run by the agent on the playground, reset after"). Say that no manual case is marked. Tell the human to report failures in the session or as a PR comment; ticking the file is optional.
- **Where it landed.** Give the plan path, `docs/qa/<file>`, and the revision it was written against. Then show the gallery. When the host can render HTML in the session, render `inline.html` there. Always give the path to `index.html` as well. Never hand off a bare screenshot folder.
- **Next.** With a ❌, fix it first with **implementkit** (otherwise fix it by hand), then run qakit again. With none, open the PR with **prkit** and hand it `docs/qa/<file>`, so the PR's test plan links the QA plan. Without prkit, run `gh pr create` and put the plan path in the body.

Don't mark any *manual* case as passed yourself. The agent fills the Automated verification section and the scenarios it ran on a disposable target, nothing else. Route to prkit; do not invoke it.

## Notes
- **Browser MCP and HTML render tools are outside `allowed-tools`.** `Bash` covers a CLI driver such as `playwright-cli` and `gallery.py`. On a host that enforces `allowed-tools` strictly and grants no browser tools, the page checks stay manual.
- **No filesystem or shell?** You can't write the file or read a diff. Instead ask the user to paste the change or describe the feature, then print the finished plan as a codeblock with the canonical `docs/qa/NNNN-qa-<feature-slug>-YYYY-MM-DD.md` path, with `0001` when you can't list their QA plans, for them to save themselves.
