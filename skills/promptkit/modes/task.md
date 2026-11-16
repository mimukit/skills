## Mode: `task`

A `task` prompt targets **an agent with filesystem access in this repo**: a fresh session, a subagent, an unattended run, an issue body. Every rule below is only correct for that receiver.

### 1. Ground in the repo

Before writing anything:

- **Resolve every vague reference to a real path or symbol.** *"the auth file"* becomes `src/lib/session.ts`. *"the old flow"* becomes the function that actually implements it, or it stays named as unresolved.
- **Discover commands rather than guessing them.** *"make sure tests pass"* becomes the repo's real test command, found in `package.json`, a `Makefile`, `pyproject.toml`, a `justfile`, or the CI config.
- **Resolve every summary of evidence to its primary artifact.** *"the crash"* becomes the crash report or the log path; *"users say it's slow"* becomes the trace, the benchmark output, or the support export behind it. An artifact the tree doesn't hold stays named as unresolved.
- **Read the repo's agent instruction file** (`CLAUDE.md`, an `AGENTS`-style guide, `.cursorrules`, whatever it uses) to learn what the prompt can **leave out**, not what to copy in.

**Omit with a pointer, never silently.** One line, *"follow the conventions in the repo's agent instruction file"*, phrased generically because each tool auto-loads a different file. Where the prompt must **override** an instruction file, say so explicitly rather than restating the rule and hoping the later text wins.

**Keep the resolution ledger as you go.** Pair every vague reference with what it became, and name every one that didn't resolve as unresolved.

Done when every vague reference, every summary of evidence, and every unnamed command in the input has a ledger row, resolved or named as unresolved.

### 2. Ask at most three, and never block

Three scoping questions, maximum, and only for decisions the repo can't answer. Where an answer doesn't arrive, **bake the assumption into the prompt visibly and name it in the ledger**. An unresolved reference is not a blocker; it stays in the prompt as a visible stated assumption.

**Ask them answerable.** Every question is a short closed list of labeled options, so the reply is `1b, 2a` rather than a paragraph, and every list carries an option that hands the call back (*"you pick"*). `AskUserQuestion` renders this natively; without it, write the options out as a numbered list.

A prompt that can't be sharpened because the *work* is unsettled routes upstream through [the routing note](../SKILL.md#the-routing-note), not by blocking.

Done when every question is answered or its assumption is in the ledger.

### 3. Write to the five-part contract

Every `task` prompt carries all five:

| Part | What it is |
|---|---|
| **Goal** | the outcome, stated once, in the receiver's terms |
| **File scope** | the paths in, and the paths deliberately out |
| **Constraints** | what must hold: conventions to follow, things not to touch, decisions already made |
| **Done signal** | a concrete check, meaning a command, a test, or an observable state. Never "when it works". Prefer a check that exists before the receiver starts (an existing test, a command, a measurement). A check the receiver writes itself must be watched to fail before the change, for the stated reason and not from a setup error |
| **Stop condition** | where to stop, so the agent doesn't keep going past the ask |

Bake real content in. Long context on top, the ask at the bottom. `task` **assumes the receiver runs with thinking on**, as current coding agents do, so spending a question on it buys nothing.

On a review-only run, skip this step and check the input against the five parts instead. A Done signal the receiver writes and grades itself, with no fail-first step, is present but **weak**; name it as weak, separately from a missing part. Done when each of the five parts is present in the prompt, or, on a review-only run, named as present or missing, with a self-graded Done signal named as weak.

### 4. Strip the slop, then scan for brackets

Run [the catalog](../SKILL.md#the-prompt-slop-catalog) filtered to `task`. Then scan the output literally for `[`, `<`, `{{`, and `TODO`, and sort every hit into one of two kinds:

- **Literal.** Text the receiver uses exactly as written: code, a type such as `Array<T>`, a Markdown link, a glob, an HTML tag, a command or path. It stays.
- **Placeholder.** Text standing in for a value nobody has filled in: `[FILE]`, `<your goal here>`, `{{name}}`, a `TODO`. **A surviving placeholder means the prompt isn't finished.**

The test for a doubtful hit: would the receiver act on these exact characters, or would it have to guess what goes there? Done when every hit is classed and no placeholder remains.

### 5. Dry-run

Read the prompt back **as the receiving agent** and state the first thing you would actually do. Fix what that exposes. Done when the first action you state matches the goal and stays inside the file scope.

### 6. Deliver

**The prompt in a fenced block first.** Then a compact **What changed**, meaning the ledger, two to four lines:

```
resolved "the auth file" → src/lib/session.ts
resolved "make sure tests pass" → pnpm test && pnpm typecheck
assumed the change is server-side only; stated in the prompt
could not resolve "the old flow"; left named as unresolved
```

**The no-rewrite verdict.** promptkit may return *"this is fine, send it"* with the input unchanged, rather than change something to justify the run. Return it when the three checks the run already performed pass: **every contract part present · no placeholder surviving the scan · no catalog entry firing.** Then the ledger prints what the prompt already had instead of what changed.

On a review-only run, deliver the diagnosis alone: the ledger, the missing contract parts and a weak Done signal, the catalog entries that fired, and the placeholders the scan found.

### 7. Hand off

**What changed.** Nothing on disk; `task` writes no files. Say the mode you ran and whether it was a rewrite, a review, or a no-rewrite verdict.

**Where it landed.** The fenced block above, ready to paste. On a review-only run, the diagnosis above.

**Next.** Send it. If [the routing note](../SKILL.md#the-routing-note) fired, the crowned move is the upstream one it named instead. If the prompt is meant to drive a build, the receiver is an implementation pass, meaning **implementkit** when installed, otherwise paste it into a fresh agent session. promptkit does not launch it. After a review-only run, fix the listed gaps yourself, or re-run promptkit without "just tell me" for a rewrite.

## A worked `task` run

The example lives in [worked-example.md](../worked-example.md). Read that file before writing a `task` prompt when the five-part contract needs an example.
