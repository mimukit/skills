---
name: prototypekit
description: >-
  Build throwaway code that answers a question, whether an interactive state model you can drive, a script that measures one thing, or competing live UI variants to switch between in the app, then fold the answer into the decision and delete the code. Use when the user says "prototype this", "spike this", "does this state model hold up", "is this library fast enough", or "try three live versions in the app". Not a demo generator and never production code.
license: MIT
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, AskUserQuestion
metadata:
  internal: false
---

# prototypekit

Write code that answers one question; keep the answer, delete the code.

An image of a screen, or image options of one, is **uikit** `mockup` when installed; otherwise draw the image with whatever image tool is present. A question that documentation can settle is a research job, not a prototype. A demo request gets the bounce in [No question, no prototype](#no-question-no-prototype).

## No question, no prototype

Before writing a line, state **the question** and **the decision it unblocks**, one sentence each. If you can't write both, there is nothing to prototype yet.

An ask that resolves to "build me a demo", "make a proof of concept for the client", or "just try something" is production work under a softer name. **Bounce it once**, naming the reason and the route: it wants a plan and a real build, not a throwaway.

**If the user reaffirms, the ask converts, not the skill.** Say plainly that this is production work, then do it *as* production work: no marker, no exclude entry, no disposal, and it stays on disk. prototypekit stops driving at that point. Never build a demo *as a marked, disposed prototype*: that hands someone a thing to show a client and then deletes it.

## The six rules

Both modes obey these.

1. **Throwaway from day one, and marked.** Live next to what you're prototyping so the project's imports, aliases, and config just work. Name every file `*.prototype.*` and every directory `*.prototype/`. The exclude entry matches the marker, so an unmarked prototype is one `git add -A` away from `main`.
2. **Trivial to run.** One command from the project's own task runner, or a file you double-click. Discover the runner from the repo (`package.json`, `Makefile`, `justfile`, `pyproject.toml`, `go.mod`, `Cargo.toml`) rather than assuming one, and **name the command for the user to run; never start a dev server yourself.**
3. **No persistence.** State lives in memory. When the question involves a database, use a scratch one named so nobody mistakes it, such as `PROTOTYPE_wipe_me`.
4. **Skip the polish.** No tests, no abstractions, no error handling beyond what makes it run. prototypekit **never runs a done-gate**; there is nothing to gate.
5. **Surface the state.** Every action (logic) or variant switch (ui) shows the full relevant state.
6. **Stop when the question is answered**, not when the prototype feels finished. The scope box is the check.

## Procedure

### 1. State the question and draw the scope box

Write the question and the decision it unblocks, per [No question, no prototype](#no-question-no-prototype).

Then draw the **scope box**: the cases that are **in**, and the cases explicitly **out**. A case outside the box is a new decision: say so and get agreement before you build it.

Put the box in the prototype file's own header comment, with every assumption you had to make beside it.

### 2. Route the branch

- A state model, a reducer, a flow, a backend module, a feasibility question → [the logic mode](#4-the-logic-mode).
- A page, a screen, a component → [the UI mode](#5-the-ui-mode).

Ambiguous and the user isn't reachable? Default by what surrounds the code and state the assumption in the header.

### 3. Mark it, exclude it, then write it

**Before the first file exists**, register the marker patterns in the repo's **private exclude**, not the tracked `.gitignore`. A tracked ignore edit is itself an uncommitted change; the private exclude is local-only.

```sh
git rev-parse --git-path info/exclude    # resolve the real path; never hardcode .git/info/exclude
```

In a linked worktree `.git` is a *file*, not a directory, so the literal path doesn't exist. Append `*.prototype.*` and `*.prototype/` only if they aren't already listed. Both patterns ship, because the file glob won't match a directory on its own. **Record which lines you appended.** A pattern that was already listed belongs to whoever put it there, and disposal leaves it alone.

**Say you did it in the same line** you say where the prototype is going, so the user knows the guard is in place before any code lands.

### 4. The logic mode

**First axis: does the code already exist?**

- **It exists.** Import the real module and run it through the project's own runner, rendering however the project can: a throwaway dev route, a CLI harness, a script. **Never re-type logic you already have; import it.**
- **You're inventing it.** One self-contained file. For a web project that's HTML with no build step and no server, so you double-click to open it. For anything else, that language's simplest runnable single file.

**Second axis: who reads the output?**

- **A human clicking.** Build the interactive shape: **free-play controls** that can fire every transition, plus **guided walkthroughs** that push the model through the specific hard cases the question is about, the ones nobody can reason about on paper. Render the full state after every action. A non-developer must be able to drive it.
- **A number or a log**, as in is this fast enough, do these two interop, does this API do what its docs imply. Write a script that prints the measurement *and the conditions it was taken under*.

Same gate, same scope box, same disposal across all four combinations; only the render target changes.

### 5. The UI mode

**Three structurally different variations on a single route**, switched by a URL search param with a small floating switcher.

**Divergence is the deliverable.** Every variant must differ on a **structural axis (layout, information hierarchy, or interaction model) and must name the axis it takes.** Differing on color, spacing, or corner radius is a recolor, not a variant. Ship fewer than three only when three distinct axes can't be named, and then say so.

Follow whatever routing and naming the project already uses, and **never invent a new top-level structure to hold a mock.**

When a UI skill is installed, borrow its anti-slop catalog and accessibility floor, but **override its design-system precedence for this job only, and say so.**

A winning variant is **evidence, not a starting point.** Building it for real is a fresh job against the real files, at full conformity, from scratch.

### 6. Write the verdict

Four lines, wherever it lands:

```
Question: <what we needed to know>
Built:    <what was made, and which cases it was driven through>
Showed:   <what actually happened>
Answer:   <the decision this unblocks, now settled>
```

Write **Built** straight from the scope box, so it names the cases driven and transitions covered.

Land it in whatever asked the question:

- **A plan document.** **Strike the open question and add a row to its settled-decisions section**, citing the prototype. This is prototypekit's **one edit to a tracked file**, and it only ever touches a file the user named. A new settled decision is a material edit, so when the plan carries a `Grilled:` line, delete that line in the same edit and say so; the plan needs a re-grill.
- **An issue.** Leave a comment.
- **Neither.** Report in the chat.

**When the prototype answered a *different* question than the one asked, report and stop.** The verdict says the asked question is still open and reports the finding beside it. One carve-out: when the finding *invalidates the premise* of the asked question (the state model can't exist, so "does it hold up" is moot), that **is** the answer, and it's reported as one.

### 7. Park, then dispose

**Offer the park first**, as one ask, with the literal command. It is off by default:

```sh
git diff --cached --name-only    # record the staged set first
git checkout -b prototype-<slug> && git add -f <files> && git commit -m "prototype: <question>" -- <files> && git checkout -
```

The path list after `--` limits the commit to the prototype files, so work the user had already staged stays staged and stays out of the park. After the park, run `git diff --cached --name-only` again and confirm it matches the recorded set. The checkout back removes the parked files from the working tree, so the delete below finds them gone.

**Then delete, confirmed per file.** List every file you created this session and confirm each one individually. An excluded file is untracked, so git cannot recover it. **Never touch a file you didn't create in this session.**

Remove the exclude entry **only when every prototype file is gone**, and remove only the lines you recorded as appended. Any file the user keeps gets reported by absolute path with its exclude line left in place.

### 8. Hand off

_Write this section in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

**What changed.** Report the files created, which were deleted and which the user chose to keep, which exclude lines you removed and which you left, whether the park happened, and whether you removed a `Grilled:` line.

**Where it landed.** Give the verdict's destination by path (the plan file and the row it added, the issue, or the chat), and the absolute path of anything still on disk.

**Next.** Crown one move:

- The answer settles a plan decision → fold it forward with a planning or grilling skill, otherwise edit the plan directly.
- A UI variant won → build it for real with a UI skill, otherwise implement it from scratch at full conformity.
- The answer settled a hard-to-reverse trade-off → record it as an ADR with a domain/decision skill, otherwise write the ADR by hand.

Name a sibling skill only when it's actually installed, and always give the plain fallback.

## Notes

- **Never unattended.** The deliverable is a human judgment; keep prototypekit out of autonomous pipelines.
- **Does not commit** (except the explicitly offered park), does not push, does not open a PR, does not file an issue.
- **No filesystem or shell** (e.g. a browser-based agent)? Print the prototype as fenced blocks with the paths they'd go to, skip the exclude and disposal steps entirely, and give the verdict inline.
