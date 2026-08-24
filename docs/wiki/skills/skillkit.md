# skillkit

Create a new AI agent skill from scratch — naming, drafting, live testing, and publishing included.

**Reach for it when** you want to author a skill and don't want to re-derive the conventions each time.

| | |
|---|---|
| Modes | single procedure, driven one step at a time |
| Tools | `Read`, `Edit`, `Write`, `Bash`, `AskUserQuestion`, `WebSearch`, `WebFetch` |
| Writes | `skills/<name>/SKILL.md` in the host collection's layout |
| Triggering | **explicit only** — model invocation is disabled |
| Visibility | public |

## What it does

skillkit turns "I want a skill that does X" into a lean, conventions-compliant `SKILL.md`, then hands you a live-test loop to try it for real.

Every skill is **authored from scratch, never forked**. A skill may be "my version of" an upstream one, rewritten to fit the collection's conventions — but it's written, not copied.

## How it works

It drives one step at a time and won't jump ahead to drafting before intent, visibility, provenance, and name are settled.

1. **Gather intent** — what the skill does and *when it should trigger*, in real user phrasings. Plus hard constraints: tools it needs, things it must not do. Then the gate below: does this earn a skill, or is it a mode?
2. **Visibility** — internal or public. This changes the rules for everything downstream.
3. **Provenance** — original, or your version of an upstream skill. Either way it's authored here; the answer just informs how much to lean on the upstream for structure.
4. **Propose names** — 3–5 candidates with one recommended.
5. **Draft** from the frontmatter template, applying the quality bar.
6. **Review loop** — iterate until you explicitly approve. It won't proceed to testing on an unsigned-off draft.
7. **Live test.**
8. **Hand off** after running the collection's lint and updating its listing surfaces.

## Does it earn a skill, or is it a mode?

The first thing skillkit checks after intent, and the one it's most tempting to skip, because the answer is almost always "yes, build it" and asking feels like friction.

Two budgets get spent here, and they behave differently. **Context load** is what always-loaded material costs the agent: every skill's `description` sits in the window on every turn whether or not the skill fires, so the collection's descriptions share one bill. **Cognitive load** is what the collection costs *you* — knowing which skills exist and which one owns the next move. You are the index, and there is no paging you out.

The second one is the reason the gate exists, and the reason it isn't simply "minimize the number of skills". Cognitive load is the price of human agency: you pay it precisely where you want to make the call yourself. So the test isn't size or scope, it's **whether a human genuinely wants to choose this** — a distinct moment, a decision you'd make deliberately. When the choice is one the agent should be making from context anyway, it belongs as a **mode inside an existing skill**, where it costs one branch in that skill's description instead of a permanent entry you have to remember forever.

skillkit names the existing skill and hands the call back. It doesn't refuse the request.

## The naming rule

One lowercase word, the **functional term leading** so it stays searchable — people search `commit`, not `kit` — with `kit` appended. An awkward root gets shortened rather than forced into a clumsy join: `humanize` → `humankit`, not `humanizekit`.

Collisions with well-known tools get avoided (`speckit`, `shipkit`, anything already popular). With network access it searches the candidate on the web and in the skills.sh directory; offline, it says the popularity check was skipped rather than pretending.

The chosen name **must** equal the directory name.

## Visibility decides the rules

| | Internal | Public |
|---|---|---|
| Marker | `metadata.internal: true` | `metadata.internal: false` |
| Repo coupling | fine — may reference the repo's conventions doc, build tooling, repo-relative links | forbidden |
| Discovery | hidden by skills.sh | listed automatically once pushed |
| Portability gate | exempt | hard requirement |

A public skill is installed on its own into arbitrary environments — only its own directory travels. So it must be **self-contained** (conventions inlined, no `../` links, no dependency on the host repo's Makefile or conventions doc, helper scripts bundled inside its own directory), **machine and OS-agnostic**, and **environment-degrading** — writing files when a filesystem exists and printing its output as a code block when one doesn't.

## The quality bar

The difference between a skill that triggers and reads well and one that doesn't:

- **Front-load the leading word.** The first words of `name` and `description` do the invocation work. It pays twice when the word is one the model already knows — `commit`, `review`, `slop`, `ledger` — because a pretrained word anchors a region of behavior for free, where a coined one charges definition tokens for the same anchor.
- **"Use when" trigger** — phrased slightly pushy to fight undertriggering, naming the phrasings that should fire it. Then **one trigger per branch, not per synonym**: cover every mode and collapse the phrasings that rename a single one. See below for why the two halves don't contradict each other.
- **Skills are for what the model can't already do.** If the guidance is obvious, it won't trigger no matter how you word it.
- **Stay lean; disclose by branch.** Prefer one `SKILL.md`. Inline what every branch needs, push into a satellite file what only some branches reach, and keep a concept's definition, rules, and caveats under one heading rather than scattered.
- **Every step ends on a completion criterion** — see below.
- **Prompt the positive.** A prohibition drags the forbidden behavior into context and makes it *more* available, not less, so state the target behavior instead. A ban earns its place only as a hard guardrail you can't phrase positively, and even then it gets a positive target beside it.
- **Intent over incantation** — the most nuanced rule here. A skill says *what to accomplish and why* and lets the agent work out the invocation. An exact command gets pinned **only** when it's a stable public contract (`git commit`, `gh pr create`, `jq`), and even then made self-correcting. Never hardcode volatile syntax, and never encode a tool's *internal* behavior — output-format parsing, help-text scraping — as if it were contract. The failure mode runs both ways: brittle syntax that breaks loudly, or over-abstraction that taxes every run quietly.
- **One meaning, one place.** Internal skills point at the repo's conventions doc; public skills inline what they need. The environment counts as a source of truth too — a skill that restates `package.json`, a `Makefile`, or `--help` output is a cache, and a cache earns its load only when the lookup is expensive.
- **Prune no-ops.** Delete weak sentences rather than trimming them. The test is model-relative, so a disputed line gets settled by running the skill rather than by arguing about it.
- **Classify the output's register** — see below. Getting it wrong flattens a verdict or bloats a runbook.
- **Close with a hand-off** — what changed, where it landed, one crowned next move, written in the procedural register.

## Why a step needs an end condition

The rule that changes the most drafts: **every step ends on a completion criterion**, the condition that tells the agent the work is done. A step without one ends when the agent feels finished, and that is where most run-to-run variance in a skill actually comes from — not from the instructions being wrong, but from nothing saying when they're satisfied.

Two properties do the work. **Clarity** decides whether the agent can tell done from not-done. A vague bound ("understanding reached", "keep it lean") invites *premature completion*, where the step ends early because attention has already slipped forward to the steps still visible ahead of it. **Demand** decides how much the wording requires: "every modified model accounted for" forces real digging where "produce a change list" lets the agent stop at three. The exhaustive form beats the productive one, and it isn't limited to procedures — "every rule applied" binds a flat body of reference the same way, which is how a skill made entirely of rules still carries a bar.

The repair order matters, because the obvious fix is the expensive one. **Sharpen the bound first** — it's a local edit to one sentence. Split the sequence only when the bound is genuinely fuzzy *and* you have watched the rush happen, and know that splitting only works across a real context boundary: a hand-off document or a subagent dispatch. An inline call leaves the later steps sitting in the same context and hides nothing.

## Why a description prunes synonyms but never coverage

The two trigger rules look like they pull against each other. Push hard to fight undertriggering, then cut phrasings — pick one.

They're aimed at different things. A `description` is a **context pointer**: it names material the agent isn't holding and encodes the condition for reaching it, and it loads on every turn whether or not the skill fires. What that budget buys is *branch coverage* — one trigger per distinct case the skill handles, usually per mode. What it wastes is synonyms. "teach me X" and "I want to learn X" are one branch written twice; "teach me X" and "quiz me" are two branches, and dropping either one silently kills a mode.

So the pruning target is duplicate phrasings and identity the body already carries, never a case that would otherwise go untriggered. The asymmetry is deliberate: an over-long description costs tokens on every turn, which is visible and cheap to fix later, while a missing branch costs a skill that simply never fires, and nothing in lint can see that happening.

## The register rule, and why it has an audience gate

A skill writes for two readers who need opposite prose, so skillkit makes a new skill classify its own output before drafting it.

Text a skill writes back to **its own operator** — QA steps, handoff documents, status snapshots, the closing hand-off — is *procedural*, and follows ASD-STE100 Simplified Technical English: one instruction per sentence, active voice, present tense, a named actor, no metaphor. Text a person reads **to form an opinion** — plan context, research recommendations, ADR rationale, review verdicts — is *explanatory*, keeps uneven rhythm, and must not be flattened, because clipped uniform sentences strip the register that makes a position readable. Commit subjects, issue titles, prompts, design tokens, and quoted source are *exempt*, since nothing about them is prose.

The gate that matters most is the one above all three: **the register only reaches what a skill writes back into the session.** Content a skill produces for a third-party audience — project documentation, published prose, UI copy — is out of scope entirely and keeps its own standards. That reader is not in the room, cannot ask a follow-up question, and needs the writing to have room to explain a concept and to use whatever sentence length the idea requires. This is why [`humankit`](./humankit.md) and [`wikikit`](./wikikit.md) carry no register rule at all, while every skill's closing hand-off carries one, including theirs.

The clause about holding one term per concept is scoped to a **single document**, never to the repo. Two skills may reasonably use different words for a similar idea, and forcing a global vocabulary erases distinctions that are doing real work.

## Conventions it carries

Because a public skill can't link back to a conventions file, skillkit inlines the rules it needs: the frontmatter template, the **information hierarchy** (steps, in-file reference, disclosed reference, and the branch test that decides which rung a piece sits on), **completion criteria** as described above, **no hard wrapping** (one continuous line per paragraph; only code fences, tables, and frontmatter keep their line structure), the prose register described above, documentation artifact naming (`<type>-<slug>-YYYY-MM-DD.md`, creation date, stable on edit), **never cross-referencing a step by number** (a bare number binds to position, so reordering silently misdirects it — link the heading anchor instead), and the closing hand-off shape.

## Live testing

skillkit **doesn't install the skill itself** — it hands you the commands.

If the collection provides dev-link tooling, it points you at that; otherwise, symlink or copy the directory into your agent's skills dir. Then test in a **fresh session**, because the skill list loads at startup and a running session won't see it.

The suggested trial: fire it with several varied, realistic phrasings that *should* trigger it, plus a near-miss or two that should *not* — which guards against overtriggering — then confirm the run follows the drafted procedure end to end and produces what the skill promises.

The trial is also where a **no-op** gets settled. A no-op is a line the model already obeys by default, so it pays context to say nothing — and whether a given line qualifies is a fact about the model, not about how the sentence reads. Two people who disagree about a no-op are disagreeing about the default. Delete the suspect line, run the same phrasing again, and keep it only if the behavior changed.

## Hands off to

A commit. skillkit suggests a conventional message (`feat(<name>): add <name> skill`) for you to run and **never commits automatically** — that's your call.

Before closing it finishes the mechanical tail: runs the collection's lint, and updates whatever lists its skills (a README table, and `skills.sh.json` when the repo has one).

## Install

```sh
npx skills add mimukit/skills -s skillkit
```

Source: [`skills/skillkit/SKILL.md`](../../../skills/skillkit/SKILL.md) · [Add a new skill by hand](../how-to/add-a-new-skill.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`e14d201` on 2026-08-19._
