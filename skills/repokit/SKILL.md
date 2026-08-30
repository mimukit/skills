---
name: repokit
description: >-
  Set up a GitHub repo's metadata through the gh CLI: an inferred one-line About description + topics from the repo's own contents, and the workflow labels (issuekit's lifecycle and priority sets, plus an `ai-review` trigger label for AI PR review tools). Use when the user says "repokit", "set the repo description", "add topics/tags", "write an About blurb for this repo", "provision the workflow labels", "set up this repo's labels", "add priority labels", or "configure this repo's metadata", meaning anything about a repo's About panel or its label vocabulary.
license: MIT
disable-model-invocation: true
allowed-tools: Bash, Read
metadata:
  internal: false
---

# repokit

Configure a GitHub repository's metadata through the [`gh` CLI](https://cli.github.com), in two explicit **modes**:

- **`about`.** Infer a one-line *About* description and a focused set of topics from the repo's own contents (README, manifest, code), show them against whatever is already set, and apply what you approve.
- **`labels`.** Provision the workflow labels: the **lifecycle and priority** sets issuekit uses to track work and rank it, and the **automation** label that asks a repo's AI review tooling to look at a PR. Create what's missing, reconcile what drifted.

Two jobs, one skill, because both answer "make this repo's GitHub metadata right": the outward-facing blurb people read, and the label vocabulary the issue workflow runs on.

## When this fires

The user wants to set a repo's GitHub metadata. Route to a mode from what they ask:

- **about.** "Set the repo description", "add topics", "write an About blurb", "tag this repo", "update the repo's About".
- **labels.** "Provision the workflow labels", "set up this repo's labels", "add the issuekit labels", "add priority labels", "add an `ai-review` label", "the `blocked` label is missing".
- **both.** A vague "set up this repo" or "configure repo metadata" → offer to run `about` then `labels`.

**If no mode is clear, ask first.** Present the two modes and let the user pick before touching anything.

## Preflight (every mode)

Before any GitHub call, confirm the tooling and target:

```sh
gh --version                                          # gh installed?
gh auth status                                        # authenticated?
gh repo view --json nameWithOwner -q .nameWithOwner   # which repo? (the current dir's remote)
```

- If `gh` is missing or unauthenticated, say so and point to `https://cli.github.com` / `gh auth login`. Don't work around it.
- If there's no GitHub remote (the `repo view` call fails), stop and say so, because repokit acts on a repo that exists on GitHub.
- **No shell or `gh` at all** (e.g. a browser-based agent)? You can't call `gh`. Do the reasoning from what the user provides and **print the exact `gh` commands** for them to run, whether the description/topics lines or the `gh label create` block, as a codeblock to paste.

**Safety stance, for the whole skill.** A repo's description, topics, and labels are outward-facing state. **Preview every mutation and get an OK before it runs, so nothing changes on GitHub unprompted.** Always echo the exact command(s) you run, so the change is auditable and replayable.

**Re-run safe.** Every mode reconciles against what's already there, so running repokit a second time on an unchanged repo proposes nothing and mutates nothing. It's always safe to re-run.

## Detect (every mode)

Read the repo's current state once before proposing anything. It's the raw material every mode reconciles against, and it surfaces guardrails early. Fetch what the chosen mode needs plus the guardrail flags:

```sh
# guardrail flags + about state
gh repo view --json isArchived,isFork,isTemplate,description
gh api repos/{owner}/{repo}/topics --jq '.names'    # current topics (about mode)
gh label list --json name,color,description          # current labels (labels mode)
```

Check the guardrail flags **before** any mutation:

- **Archived** (`isArchived: true`). GitHub rejects metadata edits on an archived repo, so **stop** and tell the user to unarchive first.
- **Fork or template** (`isFork` / `isTemplate`). Its metadata is often inherited or throwaway, so **confirm the user means to edit *this* repo** before continuing.

---

## Mode: `about`

Infer the description and topics, reconcile against what's there, apply on approval.

### 1. Start from what's already set
You read the current description and topics in [Detect](#detect-every-mode), so carry them in and reconcile against curated metadata instead of clobbering it.

### 2. Gather signal from the repo
Read the cheap, high-signal sources first; only dig deeper when they're thin:

- **Primary.** The `README` and the project manifest (`package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, `composer.json`, `Gemfile`, …): name, existing description/keywords, dependencies, scripts.
- **Fallback.** Only when the above are missing or uninformative: scan the file tree and language mix (`gh repo view --json languages`, a shallow `ls`/`git ls-files`) to infer what the repo *is*.

### 3. Generate the description and topics
- **Description.** One line, plain, specific about what the repo *is/does*, no trailing period, short enough for GitHub's About panel. Say what it is, not how great it is.
- **Topics.** A focused, high-signal set (language, framework, domain, purpose), not keyword-stuffed. Enforce GitHub's format so they'll be accepted: lowercase, digits and single hyphens only, must start with a letter or number, ≤50 chars each, ≤20 topics total. Prefer widely-used topic slugs (e.g. `typescript`, `cli`, `github-actions`) so the repo surfaces under real topic pages.

### 4. Show current vs proposed, let the user decide per field
Present a side-by-side so nothing is a surprise, and let the user accept, edit, or keep-current **each field independently**:

| Field | Current | Proposed |
|-------|---------|----------|
| Description | `old blurb` | `new blurb` |
| Topics | `a, b` | `a, c, d` (+`c`,`d`; −`b`) |

Don't apply anything until the user signs off on the final values.

### 5. Apply, echoing the commands
On approval, write the approved values and print each command you run:

```sh
gh repo edit --description "the approved one-liner"
# reconcile topics to the approved set:
gh repo edit --add-topic new-one --add-topic another --remove-topic dropped-one
```

To *replace the whole topic set* in one call instead of add/remove reconciliation, the topics API is cleaner: `gh api --method PUT repos/{owner}/{repo}/topics -f 'names[]=a' -f 'names[]=b'`. Either is fine, so pick whichever expresses the change more simply.

### 6. Hand off

_Write every hand-off in this skill in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

**What changed.** Report the description and topics as they now stand, and anything the user chose to keep current rather than replace. A field you proposed and they rejected is worth one line; it's the part most likely to come up again.

**Where it landed.** Name the repo's About panel, with its URL, so they can eyeball the result.

**Next.** Name one move and stop. If `labels` hasn't run in this repo, that's it: the lifecycle and priority labels are what an issue workflow needs and the About panel isn't. If both modes are done, repokit is finished with this repo, so point at what the metadata unblocks (**issuekit** to start filing work, when installed) rather than manufacturing more configuration.

---

## Mode: `labels`

Provision the **workflow labels** so issuekit (and any workflow that reads them) has the vocabulary it expects. repokit *creates and reconciles* these labels; issuekit only *uses* them, and repokit never applies one to an issue or a PR. This mode **stands alone**, because the sets are useful for any issue workflow, so it never checks whether issuekit is installed before provisioning them.

### Three sets, three independent namespaces

The map below is really three, and keeping them apart is what makes all three usable:

- **Lifecycle** answers *can this be worked?*, meaning where the issue sits in the workflow.
- **Priority** answers *should this be worked next?*, meaning how much it matters relative to everything else workable.
- **Automation** answers *what should a machine do with this?*, meaning a label a tool subscribes to.

Lifecycle and priority are **orthogonal**: an issue carries at most one label from each, and neither implies the other. `ready` + `low` is a perfectly coherent issue (workable, not urgent), and so is `blocked` + `critical` (urgent, and that's exactly why its blocker matters). Downstream skills read them as two separate signals, so never collapse them into one ordered set.

Automation is a different kind of label again, and the difference decides how you treat it. Lifecycle and priority **describe** an issue, so a human reads them and one of each is true at a time. An automation label **acts**: a person adds it to a pull request to start a tool, and usually removes it once the tool has run. It is PR-scoped, additive, and carries no state anybody reads later, so it never competes with a lifecycle or priority label.

### The canonical lifecycle set
Provision exactly this map. The `description` column here is canonical; issuekit mirrors the same names, colors, and meanings in execution-oriented wording.

| name | color | description |
|------|-------|-------------|
| `triage` | `FBCA04` | filed, not yet assessed or broken down |
| `needs-planning` | `F1C40F` | needs a human plan/grill session before it is workable |
| `ready` | `0E8A16` | specified and independent, safe to take into its own worktree now |
| `blocked` | `D93F0B` | has an unmet prerequisite that has not started |
| `stacked` | `006B75` | its prerequisite is in flight with an open PR; workable now on a branch stacked on it |
| `in-progress` | `1D76DB` | actively being worked in a worktree |
| `in-review` | `5319E7` | a PR is open, awaiting review or merge |
| `needs-info` | `D4C5F9` | stalled pending more detail before it can proceed |
| `wontfix` | `FFFFFF` | will not be actioned |
| `duplicate` | `CFD3D7` | superseded by another issue |

### The canonical priority set
Four levels, and the colors run a deliberate hot-to-cold ramp so the family reads as one scale at a glance rather than as four unrelated labels:

| name | color | description |
|------|-------|-------------|
| `critical` | `B60205` | drop everything; preempts work already in progress |
| `high` | `E99695` | do this before other workable issues |
| `medium` | `FEF2C0` | normal priority, the default once assessed |
| `low` | `C5DEF5` | worth doing eventually; never preempts anything |

Colors are 6-hex, no leading `#`.

**No priority label means *unassessed*, not *medium*.** The absence is a real state and downstream skills read it as one; it's how `triage` finds issues nobody has ranked yet. Never provision a default, and never treat a missing label as an implied middle.

**Four levels is the ceiling, and it's already generous.** The point of a priority scale is a backlog someone can order in their head; every level past the fourth is one more place for the same issue to plausibly sit, which is how a scale turns into a coin flip. If the user asks for a fifth, say what it costs before adding it.

### The canonical automation set
One label, for the one automation this collection assumes: an AI review of a pull request.

| name | color | description |
|------|-------|-------------|
| `ai-review` | `34495E` | run the repo's AI review tooling on this PR |

The color sits outside both ramps on purpose. An automation label is not a state and not a rank, so it must not read as a step on either scale.

**The label is a switch with nothing behind it until something listens.** Creating `ai-review` does not review anything by itself: a GitHub Actions workflow or an installed review app has to subscribe to it. Check what the repo already has before you promise a result:

```sh
grep -rl 'labeled' .github/workflows/    # a workflow that fires on a label event
```

An installed review app (Copilot, CodeRabbit, Claude) is configured outside the repo, so ask the user about that half instead of guessing. Report what you find. When nothing listens yet, say so in one line and name the gap; the user still gets a real label, and the wiring is their next move.

**The listener owns the name, not this map.** A workflow fires on the exact string in its `if:` condition, so a repo that already listens for `claude-review`, `copilot-review`, `coderabbit`, or `gemini-review` keeps that name. Adopt it and skip `ai-review`, because a second trigger label that nothing reads is a switch wired to nothing. Rename ours, never theirs.

### 1. Check for an existing scheme first, in every namespace
You read the repo's labels in [Detect](#detect-every-mode). Before diffing, look for a **different-but-equivalent scheme** the repo already runs, in any namespace:

- **Lifecycle.** `status: blocked`, `S-ready`, `blocked ⛔`, or a `needs-*` family that already covers this ground.
- **Priority.** `P0`/`P1`/`P2`, `priority: high`, `pri-1`, `urgent`, or a `severity:` family being used as a de facto priority.
- **Automation.** `claude-review`, `copilot-review`, `coderabbit`, `gemini-review`, `needs-ai-review`, or any label a workflow file names as a trigger.

If one exists, **don't silently add a parallel set** (two ways to say "blocked" is worse than none, and two ways to say "urgent" is worse still, because the two will disagree). Surface it and ask which way to go:

- **Map onto theirs.** Treat the repo's labels as canonical; skip provisioning and (optionally) note the name mapping so issuekit-style workflows can be pointed at the existing names.
- **Add the canonical set.** The repo's scheme is incidental or abandoned; provision ours alongside it, and offer to retire the old labels only if the user explicitly asks.

Handle the namespaces **independently**, because a repo very often has a mature lifecycle scheme and no priority scheme at all, and the answer there is "map onto theirs for lifecycle, provision ours for priority." One question covering all three forces a wrong answer to two of them.

**Priority names collide harder than lifecycle names, so check meaning and not just spelling.** `ready` and `in-review` are workflow-shaped words that mostly mean this one thing; `critical`, `high`, and `low` are generic English and a repo may already be using them for something else entirely: bug **severity** (how badly it breaks), effort or T-shirt **size**, risk, or a customer tier. A name match is not a meaning match. When the repo already has a `critical` or `high`, read its description and a couple of the issues carrying it before assuming it's the same axis, and if it turns out to be severity, say so plainly. Severity and priority are genuinely different things (a critical crash nobody hits can be `low`), so the honest fix is to name the collision and let the user decide whether to rename theirs, rename ours, or map onto it.

Absent any existing scheme in a namespace, go straight to the diff for that one.

### 2. Diff against the canonical sets and preview
Sort each canonical label, from **all three** sets, into one of three buckets and show the plan before touching anything, grouped by namespace so the user can approve one and decline another:

- **Missing.** Not in the repo → will be **created**.
- **Drifted.** Present but wrong color or description → offer to **update** (this rewrites the label; get an explicit OK per label or for the batch).
- **Matches.** Present and correct → leave alone.

Labels **outside** the canonical sets (GitHub's defaults like `bug`/`enhancement`, or the repo's own) are **left untouched**, and you never delete a label unless the user explicitly asks.

### 3. Apply, echoing the commands
On approval:

```sh
# create a missing label
gh label create ready --color 0E8A16 --description "specified and independent, safe to take into its own worktree now"
gh label create critical --color B60205 --description "drop everything; preempts work already in progress"
gh label create ai-review --color 34495E --description "run the repo's AI review tooling on this PR"

# update a drifted label (rewrites color/description in place)
gh label edit blocked --color D93F0B --description "has an unmet prerequisite (see 'Blocked by #N' in the body)"
```

`gh label create --force` also upserts (create-or-overwrite) if you'd rather not branch on existence, but prefer the explicit create/edit split so the preview in [Diff against the canonical sets and preview](#2-diff-against-the-canonical-sets-and-preview) stays honest about what's new versus changed.

### 4. Hand off
**What changed.** Report what was created, updated, and left as-is, per namespace, and confirm which of the three sets the repo now carries in full. Provisioning one set and skipping another is a normal outcome, not a partial failure, so say which, and nobody goes looking for a missing set later.

**Where it landed.** Name the repo's label list. If you mapped onto an existing scheme instead of provisioning ours in any namespace, say which names won, because everything downstream now has to use those.

**Next.** Name one move and stop. The labels are a vocabulary, not an outcome: what they unblock is the issue workflow, so the move is to start using it, with **issuekit** `create` to file work from a plan, or `triage` to classify and rank issues that were sitting unlabeled while the vocabulary was missing.

**When you created `ai-review` and nothing listens for it, crown that gap instead.** The label starts no review until a workflow or a review app subscribes to it. Say that in one line, and name `.github/workflows/` as the place to wire it. repokit provisions the label; it does not write the workflow. When the repo already had open issues and priority is the set you just provisioned, `triage` is the stronger of the two: every one of those issues is now formally unassessed, and nothing downstream can rank them until somebody says what matters. Absent issuekit, say the labels are now available to whatever issue workflow the repo runs. If `about` hasn't run yet and the repo's About panel is empty, offer that as the smaller follow-up.

---

## Notes

- **Never** delete a repo's topics wholesale or its labels outside the canonical sets without an explicit ask; the default is additive and reconciling, not destructive.
- The lifecycle and priority maps are a **shared contract with issuekit**: the same names across both namespaces, with the same colors and meanings, and repokit's descriptions canonical. The automation set is repokit's alone, because issuekit runs the tracker and `ai-review` acts on a pull request.
- **repokit provisions the vocabulary; it never applies it.** No mode here ever puts a label on an issue or a PR. Deciding that #42 is `high` is a judgment about the work, which is issuekit `create` and `triage`'s job; asking for an AI review is a call the author makes on their own PR. repokit only guarantees the word exists to say it with. Keeping that line is what makes this mode safe to re-run on a repo with a live tracker.
- **Labels can't enforce one-per-namespace, so the writer has to.** GitHub will happily let an issue carry `critical` and `low` at once, and nothing here can prevent it. Provisioning is the only half repokit owns; the mutual exclusion is enforced at write time by whoever applies the label, which is why that rule lives in issuekit rather than in this map.
- Defer to what the repo already curates: an existing scheme in any namespace is handled in [Check for an existing scheme first, in every namespace](#1-check-for-an-existing-scheme-first-in-every-namespace), and a curated About/topics is reconciled per-field (never blind-overwritten) in `about`. Offer the canonical sets as an addition, not a replacement.
- Prefer `gh`'s structured JSON (`--json`/`--jq`, the topics API) over scraping human-readable output, because the JSON fields are a stable contract and the display text isn't.
