# skillkit

Create a new AI agent skill from scratch — naming, drafting, live testing, and publishing included.

**Reach for it when** you want to author a skill and don't want to re-derive the conventions each time.

| | |
|---|---|
| Modes | single procedure, driven one step at a time |
| Tools | `Read`, `Edit`, `Write`, `Bash`, `AskUserQuestion`, `WebSearch`, `WebFetch` |
| Writes | `skills/<name>/SKILL.md` in the host collection's layout |
| Visibility | public |

## What it does

skillkit turns "I want a skill that does X" into a lean, conventions-compliant `SKILL.md`, then hands you a live-test loop to try it for real.

Every skill is **authored from scratch, never forked**. A skill may be "my version of" an upstream one, rewritten to fit the collection's conventions — but it's written, not copied.

## How it works

It drives one step at a time and won't jump ahead to drafting before intent, visibility, provenance, and name are settled.

1. **Gather intent** — what the skill does and *when it should trigger*, in real user phrasings. Plus hard constraints: tools it needs, things it must not do.
2. **Visibility** — internal or public. This changes the rules for everything downstream.
3. **Provenance** — original, or your version of an upstream skill. Either way it's authored here; the answer just informs how much to lean on the upstream for structure.
4. **Propose names** — 3–5 candidates with one recommended.
5. **Draft** from the frontmatter template, applying the quality bar.
6. **Review loop** — iterate until you explicitly approve. It won't proceed to testing on an unsigned-off draft.
7. **Live test.**
8. **Hand off** after running the collection's lint and updating its listing surfaces.

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

- **Front-load the leading word.** The first words of `name` and `description` do the invocation work.
- **"Use when" trigger** — phrased slightly pushy to fight undertriggering, naming the phrasings that should fire it.
- **Skills are for what the model can't already do.** If the guidance is obvious, it won't trigger no matter how you word it.
- **Stay lean.** Prefer one `SKILL.md`. A satellite file only when content is *large* **and** needed *only sometimes*; guidance needed every run belongs inline.
- **Intent over incantation** — the most nuanced rule here. A skill says *what to accomplish and why* and lets the agent work out the invocation. An exact command gets pinned **only** when it's a stable public contract (`git commit`, `gh pr create`, `jq`), and even then made self-correcting. Never hardcode volatile syntax, and never encode a tool's *internal* behavior — output-format parsing, help-text scraping — as if it were contract. The failure mode runs both ways: brittle syntax that breaks loudly, or over-abstraction that taxes every run quietly.
- **One meaning, one place.** Internal skills point at the repo's conventions doc; public skills inline what they need.
- **Prune no-ops.** Delete weak sentences rather than trimming them.
- **Classify the output's register** — see below. Getting it wrong flattens a verdict or bloats a runbook.
- **Close with a hand-off** — what changed, where it landed, one crowned next move, written in the procedural register.

## The register rule, and why it has an audience gate

A skill writes for two readers who need opposite prose, so skillkit makes a new skill classify its own output before drafting it.

Text a skill writes back to **its own operator** — QA steps, handoff documents, status snapshots, the closing hand-off — is *procedural*, and follows ASD-STE100 Simplified Technical English: one instruction per sentence, active voice, present tense, a named actor, no metaphor. Text a person reads **to form an opinion** — plan context, research recommendations, ADR rationale, review verdicts — is *explanatory*, keeps uneven rhythm, and must not be flattened, because clipped uniform sentences strip the register that makes a position readable. Commit subjects, issue titles, prompts, design tokens, and quoted source are *exempt*, since nothing about them is prose.

The gate that matters most is the one above all three: **the register only reaches what a skill writes back into the session.** Content a skill produces for a third-party audience — project documentation, published prose, UI copy — is out of scope entirely and keeps its own standards. That reader is not in the room, cannot ask a follow-up question, and needs the writing to have room to explain a concept and to use whatever sentence length the idea requires. This is why [`humankit`](./humankit.md) and [`wikikit`](./wikikit.md) carry no register rule at all, while every skill's closing hand-off carries one, including theirs.

The clause about holding one term per concept is scoped to a **single document**, never to the repo. Two skills may reasonably use different words for a similar idea, and forcing a global vocabulary erases distinctions that are doing real work.

## Conventions it carries

Because a public skill can't link back to a conventions file, skillkit inlines the rules it needs: the frontmatter template, **no hard wrapping** (one continuous line per paragraph; only code fences, tables, and frontmatter keep their line structure), the prose register described above, documentation artifact naming (`<type>-<slug>-YYYY-MM-DD.md`, creation date, stable on edit), **never cross-referencing a step by number** (a bare number binds to position, so reordering silently misdirects it — link the heading anchor instead), and the closing hand-off shape.

## Live testing

skillkit **doesn't install the skill itself** — it hands you the commands.

If the collection provides dev-link tooling, it points you at that; otherwise, symlink or copy the directory into your agent's skills dir. Then test in a **fresh session**, because the skill list loads at startup and a running session won't see it.

The suggested trial: fire it with several varied, realistic phrasings that *should* trigger it, plus a near-miss or two that should *not* — which guards against overtriggering — then confirm the run follows the drafted procedure end to end and produces what the skill promises.

## Hands off to

A commit. skillkit suggests a conventional message (`feat(<name>): add <name> skill`) for you to run and **never commits automatically** — that's your call.

Before closing it finishes the mechanical tail: runs the collection's lint, and updates whatever lists its skills (a README table, and `skills.sh.json` when the repo has one).

## Install

```sh
npx skills add mimukit/skills -s skillkit
```

Source: [`skills/skillkit/SKILL.md`](../../../skills/skillkit/SKILL.md) · [Add a new skill by hand](../how-to/add-a-new-skill.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`c11dbaf` on 2026-08-09._
