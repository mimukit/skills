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

## The tells

They matter in **clusters**, not isolation. One em dash or one "however" proves nothing. Em dashes plus rule-of-three plus "vibrant tapestry" plus a "Conclusion" section is a confession.

| Tell | Looks like |
|------|-----------|
| **Inflated significance** | *stands as a testament to, marks a pivotal moment, plays a crucial role, evolving landscape* |
| **Promotional tone** | *nestled, in the heart of, vibrant, breathtaking, boasts a, must-visit, renowned* |
| **Superficial -ing tails** | *…, highlighting its importance,* *…, ensuring seamless integration* |
| **AI vocabulary** | *delve, crucial, pivotal, underscore, showcase, tapestry, intricate, foster, leverage, seamless, robust, realm* |
| **Copula avoidance** | *serves as, functions as, represents, features* — prefer "X is Y" |
| **Rule of three** | *innovation, inspiration, and industry insights* |
| **Negative parallelism** | *Not only… but also…*, *It's not just X, it's Y*, clipped tails like *…, no guessing* |
| **Filler and hedging** | *in order to* → *to*; *due to the fact that* → *because*; *could potentially possibly* → *may* |
| **Signposting and chatbot residue** | *Let's dive in*, *I hope this helps*, *Certainly!*, *You're absolutely right!* |
| **Persuasive-authority formulas** | *the real question is, at its core, what really matters*; *X is the language of Y* |
| **Vague attribution** | *experts argue, observers have noted* with no source named |
| **Formatting tells** | mechanical boldface, inline-header bullets, Title Case Headings, decorative emojis |

## The em-dash rule

The finished rewrite contains **no em dashes** and uses **no en dashes as sentence punctuation**. Replacements, in rough order of preference: a period, comma, colon, parentheses, or a restructured sentence.

Legitimate numeric and date ranges survive as hyphens or "to" (`1914-1918`, `pp. 10 to 12`). Spaced em dashes and double hyphens used the same way get caught too. Before delivering, the draft is searched for both marks — any remaining em dash means the rewrite isn't done.

**One exception overrides it:** a user-supplied writing sample that uses em dashes. Then the mark is matched to the sample's frequency rather than banned. Matching the author beats scrubbing the tell, and a sample outranks every style rule here.

## What not to flag

Clean human writing trips several of these on its own, and gutting legitimate prose is the opposite of the job:

- Polish, formal vocabulary, or consistent style. Professionals and edited writers exist.
- A single em dash, one *however*, one clipped emphatic sentence, curly quotes alone.
- Bland or dry prose without the *specific* tells. Dry is not the same as AI.
- Quoted text, titles, proper names, or a phrase being discussed rather than used.

Hard-to-fake specifics, mixed or unresolved feelings, era-bound slang, genuine asides and self-corrections, real variety in sentence length — those are a person's fingerprints. Lean toward leaving them alone.

## How you reach it changes what you get

| Called with | Delivers |
|---|---|
| Text in the conversation | the full loop: final rewrite, a "what still read as AI" note, and a one-line change summary |
| A file path | rewrite written back; code blocks, frontmatter, tables, and link targets untouched. Reports a summary and the path, not the prose |
| Another skill or agent | the final text alone. No draft, no audit bullets, no ceremony — the caller wants prose |

Asked only for a review, it reports the located tells with line references and skips the rewrite entirely.

## How it works

1. Mark every instance of the tells.
2. Write a **draft rewrite** — vary sentence length, prefer concrete detail and plain constructions, hold the register and coverage.
3. Ask two blunt questions: *what still reads as AI-generated?* and *does this state any fact not in the source?*
4. Revise into a **final rewrite** fixing both, carrying no em or en dashes.

## Hands off to

Nothing, usually. A rewritten file in a repo is uncommitted prose, so [`commitkit`](./commitkit.md) is the move. A review rather than a rewrite hands back to you — apply the tells you want, then re-run. Text from the chat routes nowhere: the draft is yours to paste back.

## Reference

The pattern catalog derives from [Wikipedia: Signs of AI writing](https://en.wikipedia.org/wiki/Wikipedia:Signs_of_AI_writing), maintained by WikiProject AI Cleanup.

## Install

```sh
npx skills add mimukit/skills -s humankit
```

Source: [`skills/humankit/SKILL.md`](../../../skills/humankit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`1f85177` on 2026-08-16._
