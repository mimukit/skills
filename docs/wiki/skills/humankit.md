# humankit

Strip the tells of AI-generated writing from prose so it reads like a person wrote it.

**Reach for it when** a draft sounds like ChatGPT — or when you want a diagnosis of *why* it does, without a rewrite.

| | |
|---|---|
| Modes | single procedure; rewrite or review-only |
| Tools | `Read`, `Edit`, `Write` |
| Writes | back to the source file, or inline |
| Visibility | public |

## What it does

The job is not to delete flagged words. It's to rewrite prose into something a specific human would actually write: concrete, uneven in rhythm, plain in construction, and true to the author's register.

Every claim in the original survives. Its *shape* doesn't — dull stretches get compressed, interesting ones get room, paragraphs merge and split freely. Uniform structure is itself a tell, so mirroring the original's paragraph count preserves the exact thing you came to remove. When coverage and structure pull against each other, coverage wins: a five-paragraph source may land in four, but it never becomes a summary.

## The rule that governs the rest

**Never invent facts.** The rewrite carries no fact, name, number, date, quote, or citation that isn't in the source or supplied by the user.

This is the failure mode the rest of the skill invites. Told to replace *nestled in the heart of a vibrant region* with something concrete, the tempting move is to supply the concrete detail yourself. Concreteness comes from the source or it doesn't come at all — where the source offers nothing specific, cut to the plain version and leave it plain.

Opinions, reactions, and mixed feelings are voice rather than fact, so those can be added where the register allows. A factual claim added to make prose feel human is a defect, even when it reads better than the vague original it replaced.

Fiction is the exception, where inventing detail is the job.

## What it is not

Copy-editing to make writing read well — not a way to disguise machine-written work as human where honesty is required. Academic submissions, disclosure-bound writing, attributed work: edit for the reader, not to game an automated check.

## Who reads it, and what that rules out

humankit fires on prose a person reads. An agent instruction file is not that, and running the catalog over one does real damage, because there the tells *are* the machinery.

Take a `SKILL.md`, an agent instruction file such as `CLAUDE.md` or an `AGENTS`-style guide, a system prompt, a rules file. A metaphor noun the document defines and reuses anchors a region of behavior in one token. Mechanical boldface is what marks the load-bearing rule among twenty that aren't. A formula repeated verbatim is the thing that makes the behavior repeat. All three are humankit tells, and the last one is the exact opposite of what "vary the rhythm" asks for. Strip them and the file reads better to a person while steering the model worse.

So those files get named as out of scope and routed instead — a prompt to [`promptkit`](./promptkit.md), a skill to [`skillkit`](./skillkit.md). promptkit has carried the mirror of this rule since it shipped: never run an em-dash rule or an AI-vocabulary list against a prompt, where scaffolding and repetition are features. The guard now sits on both sides, which matters because only one of the two skills can actually cause the damage.

Procedural text gets the softer version. A runbook, a QA checklist, a handoff: those take the subtraction and skip the voice half. Uniform short sentences are the correct register there, so [Removing tells is half the job](#removing-tells-is-half-the-job) would rewrite them into something worse than it found.

Documentation, a README, release notes, PR bodies, UI copy: all in scope as normal. The gate is who reads it, not where it lives.

## The tells

They matter in **clusters**, not isolation. One em dash or one "however" proves nothing. Em dashes plus rule-of-three plus "vibrant tapestry" plus a "Conclusion" section is a confession.

| Tell | Looks like |
|------|-----------|
| **Inflated significance** | *stands as a testament to, marks a pivotal moment, plays a crucial role, evolving landscape* |
| **Promotional tone** | *nestled, in the heart of, vibrant, breathtaking, boasts a, must-visit, renowned* |
| **Superficial -ing tails** | *…, highlighting its importance,* *…, ensuring seamless integration* |
| **AI vocabulary** | *delve, crucial, pivotal, underscore, showcase, tapestry, intricate, foster, leverage, seamless, robust, realm* |
| **Abstract metaphor nouns** | *substrate, wedge, vector, nexus, scaffolding, flywheel, north star, ratchet, gold-plating* |
| **Elevated synonyms** | *utilize* → *use*; *facilitate* → *help*; *prior to* → *before* |
| **Copula avoidance** | *serves as, functions as, represents, features* — prefer "X is Y" |
| **Passive voice and propped-up verbs** | *queries are validated* → *the compiler validates queries*; *runs quickly* → *is fast* |
| **Rule of three** | *innovation, inspiration, and industry insights* |
| **Synonym cycling** | *protagonist, main character, central figure, hero* in one passage |
| **False ranges** | *from onboarding to enterprise security* — no shared scale |
| **Negative parallelism** | *Not only… but also…*, *It's not just X, it's Y*, clipped tails like *…, no guessing* |
| **Filler and hedging** | *in order to* → *to*; *due to the fact that* → *because*; *could potentially possibly* → *may* |
| **Signposting and chatbot residue** | *Let's dive in*, *I hope this helps*, *Certainly!*, *You're absolutely right!* |
| **Persuasive-authority formulas** | *the real question is, at its core, what really matters*; *X is the language of Y* |
| **Vague attribution** | *experts argue, observers have noted* with no source named |
| **Colon as a connector** | a colon welded mid-sentence to imply a relationship the clause never earns |
| **Formatting tells** | mechanical boldface, inline-header bullets, Title Case Headings, decorative emojis |

The metaphor-noun entry is scoped deliberately: the test is *use*, not the word. A term the text defines and then reuses for one thing is doing work and stays. The same word dropped in once for texture is decoration. A flat ban would condemn vocabulary that plenty of good technical writing depends on, which is why the rule reads as a use test rather than a blocklist.

## Two cut tests

The catalog names patterns. These judge the sentence that trips none of them and still reads as machine-written, and both end in a deletion:

- **Does it name a mechanism, or a feeling?** *SQL you can read* describes a sensation the reader is supposed to have. *A column rename fails the build* names what happens. If a sentence can't be restated as a concrete instruction, fact, or number, it goes.
- **Could it appear unchanged in another project's docs?** Then it says nothing about this one.

The first test is where the never-invent-facts rule bites hardest. Asked to replace a feeling with a mechanism, inventing the mechanism is the obvious move and the wrong one. When the source supplies none, cutting is the only option on the table.

## The em-dash rule

The finished rewrite contains **no em dashes** and uses **no en dashes as sentence punctuation**. Replacements, in rough order of preference: a period, comma, parentheses, or a restructured sentence. A colon qualifies only where it introduces a list or an example — swapping an em dash for a mid-sentence colon trades one tell for another.

Legitimate numeric and date ranges survive as hyphens or "to" (`1914-1918`, `pp. 10 to 12`). Spaced em dashes and double hyphens used the same way get caught too. Before delivering, the draft is searched for both marks — any remaining em dash means the rewrite isn't done.

**One exception overrides it:** a user-supplied writing sample that uses em dashes. Then the mark is matched to the sample's frequency rather than banned. Matching the author beats scrubbing the tell, and a sample outranks every style rule here.

## What not to flag

Clean human writing trips several of these on its own, and gutting legitimate prose is the opposite of the job:

- Polish, formal vocabulary, or consistent style. Professionals and edited writers exist.
- A single em dash, one *however*, one clipped emphatic sentence, curly quotes alone.
- Bland or dry prose without the *specific* tells. Dry is not the same as AI.
- Quoted text, titles, proper names, or a phrase being discussed rather than used.

Hard-to-fake specifics, mixed or unresolved feelings, era-bound slang, genuine asides and self-corrections, real variety in sentence length — those are a person's fingerprints. Lean toward leaving them alone.

## Removing tells is half the job

Strip every tell and put nothing back and the result is sterile, which is its own signature. That failure mode is why the skill carries a positive half: take a position instead of weighing pros and cons at equal length, vary the rhythm, let structure be uneven, use *I* where the register allows, and permit mixed feelings.

This is the part that looks like it contradicts the never-invent-facts rule, and doesn't. Opinion, reaction, and unresolved feeling are voice, so they can be added. A name, number, date, or claim is fact, so it can't. Encyclopedic, technical, legal, and reference writing are the exception in the other direction: there, plain and neutral already *is* the human voice, and adding personality would be the error.

## How you reach it changes what you get

| Called with | Delivers |
|---|---|
| Text in the conversation | the full loop: final rewrite, a "what still read as AI" note, and a one-line change summary |
| A file path | rewrite written back; code blocks, frontmatter, tables, and link targets untouched. Reports a summary and the path, not the prose |
| Another skill or agent | the final text alone. No draft, no audit bullets, no ceremony — the caller wants prose |

Asked only for a review, it reports the located tells with line references and skips the rewrite entirely.

## How it works

1. Mark every instance of the tells, then run the two cut tests over what survives.
2. Write a **draft rewrite** — vary sentence length, prefer concrete detail and plain constructions, hold the register and coverage, give it voice.
3. Ask three blunt questions: *what still reads as AI-generated?*, *does this state any fact not in the source?*, and *has the de-slopping left it sterile?*
4. Revise into a **final rewrite** fixing all three, carrying no em or en dashes.

## Hands off to

Nothing, usually. A rewritten file in a repo is uncommitted prose, so [`commitkit`](./commitkit.md) is the move. A review rather than a rewrite hands back to you — apply the tells you want, then re-run. Text from the chat routes nowhere: the draft is yours to paste back.

## Reference

The pattern catalog derives from [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), maintained by WikiProject AI Cleanup. The metaphor nouns, the colon tell, the two cut tests, and the voice section come from [pstack's `unslop` skill](https://github.com/cursor/plugins/blob/main/pstack/skills/unslop/SKILL.md).

## Install

```sh
npx skills add mimukit/skills -s humankit
```

Source: [`skills/humankit/SKILL.md`](../../../skills/humankit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`e14d201` on 2026-08-19._
