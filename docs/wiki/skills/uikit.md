# uikit

Build production UI that reads as a deliberate choice for this project rather than an LLM default, and audit shipped UI for the tells that give it away.

**Reach for it when** you're building a screen, or when something you shipped looks like a template.

| | |
|---|---|
| Modes | [`build`](#build) · [`audit`](#audit) |
| Tools | `Read`, `Write`, `Edit`, `Grep`, `Glob`, `Bash`, `AskUserQuestion` |
| Writes | components and pages, left unstaged |
| Visibility | public |

## What it does

AI-generated UI has a signature. Three equal feature cards, a violet gradient, Inter on slate-900, a div-built fake dashboard in the hero, `01 / 02 / 03` eyebrows over content that isn't a sequence.

None of these are bugs and no test catches them. They're **defaults — reached for because the model had no reason to reach anywhere else.**

uikit is the reason. It supplies the constraint that makes a UI decision *this project's* decision, and names the tells so they're avoided deliberately rather than reproduced accidentally.

The whole skill hangs off one idea: **taste is spent only where nothing else constrains the choice.**

## The precedence ladder

Four rungs. The first that matches wins, and it's **named before any code is written**. A lower rung never overrides a higher one; it only fills what the higher one leaves open.

| Rung | Matches when | What it constrains |
|---|---|---|
| **1 — `DESIGN.md`** | one exists at the repo root | its tokens *are* the palette, type scale, spacing, and radii. Full stop |
| **2 — Shipped components** | a component directory, `components.json`, or a token home | the existing Button is the Button. Read three or four real ones and match them |
| **3 — The subject's own world** | neither, but the product is knowable | the product's materials, vocabulary, and artifacts |
| **4 — Stack defaults** | greenfield and the subject is genuinely opaque | the house default, declared out loud as a default rather than a choice |

**Rung 3 is where distinctiveness actually comes from.** Not from a style vocabulary — from the subject. Its instruments, its materials, its jargon, the artifacts the people who use it already handle. That's a well no other project can draw from, which is precisely why the result can't be generic. A tool for a print shop should not look like a tool for a hedge fund.

The rung also licenses **what the signature may be made of**. Rungs 1–2 get composition, interaction, and motion — the tokens are fixed and not yours to move. Rungs 3–4 get palette, type, and grid as well.

Rung 1 or 2 with a rung 3 palette is the single most damaging thing this skill could do: one rogue component matching nothing around it, in a codebase that was consistent before you arrived.

## The design read

**Five declared words, stated before any code exists.** Cheap, and it's what stops the model jumping straight to a default aesthetic — a choice you've named out loud is a choice you can be argued out of.

```
Design read — surface: product · audience: internal ops staff · rung: 2 (shipped components)
· signature: the save affordance — rows commit on change and confirm in place, no page-level Save
· density: compact
```

**surface** (`product` or `marketing`) filters the catalog, because the two have disjoint slop signatures. **audience** must be concrete — "internal ops staff who live here 6 hours a day" implies different density than "a first-time visitor deciding in 8 seconds". **rung** declares the constraint in force. **density** is the one axis that varies independently of the rung.

### The signature

**One element per surface. Exactly one.** The thing a person would describe if asked what the screen was like. Everything around it stays quiet — spend your boldness in one place.

This is deliberately *not* framed as "take a creative risk." Asked to be bold, a model retrieves what boldness looks like, and what it retrieves is the **average** of every bold thing it has seen — which today means warm cream with a high-contrast serif and terracotta accent, or near-black with a single acid-green accent, or a broadsheet layout with hairline rules and zero radius. All three are legitimate for *some* brief. None are a choice when they appear regardless of subject.

"Name the one thing this screen is remembered by" has no average to regress toward. It's also the only version that survives a pre-flight, which can check that exactly one signature exists and that its materials are legal at the declared rung — but cannot check whether a risk was taken.

Worked example, rung 2 settings page: the default output is a card with label-left/toggle-right rows and "Save changes" bottom-right. Correct and forgettable. The signature is *there is no Save button* — each row commits on change and confirms in place with inline undo. Zero new tokens, and the risk is real, because a slow network now has to be handled honestly.

**The design read never blocks.** It's a declaration, not an interview. An unclear subject gets inferred from what the repo shows, and the inference gets *stated* — wrong-but-stated beats correct-but-hung, because uikit runs inside unattended pipelines where nothing is there to answer.

## Modes

### `build`

Ground it on the ladder, detect the stack from the manifest rather than assuming, state the design read, then build.

**Compose before you invent.** Use the existing component before writing a styled `div`; extend it before forking it; fork only when the difference is real, and say why. An agent's instinct is to write fresh markup because that's faster than reading what's there — and that instinct is what produces a codebase with four Buttons.

Along the way: clear the accessibility floor without announcing it. **Motion is justified in one sentence or it doesn't ship** — `transform` and `opacity` only, never `transition: all`. **Write the strings as design material** — a control says what happens ("Save changes", not "Submit") and keeps the same verb through the flow, so a button saying "Publish" produces a toast saying "Published." Errors name the fix, not the failure.

### `audit`

**Read-only. Writes nothing, ever.**

Target resolution leads with **explicitly named paths**, because the UI most worth auditing predates the skill and appears in no diff at all — "audit our UI" is the actual ask, and a diff cannot answer it. Falling back to the working tree or branch diff, then asking. It won't sweep a whole repository by reflex.

Findings are terse and clickable, one per line, tagged 🔴 / 🟡 / 🟢, followed by a **mandatory coverage line**. An audit that reached three files reads exactly like a clean bill of health unless it says otherwise.

On the seam with a code review: [`reviewkit`](./reviewkit.md) hunts *code* signatures — dead abstractions, over-commenting, defensive noise. uikit hunts *visual* ones. Running both produces complementary findings, not duplicates, and neither defers to the other.

## The anti-slop catalog

**The discipline travels with the list.** A tell earns a line only if it's stateable as a **ban with the correct alternative beside it**, *and* an agent can check its own output for it without rendering anything.

The cap is **~30 entries, enforced by displacement: adding one means deleting one.** Lists like this rot into hundred-item checklists nobody honestly ticks, and a checklist nobody ticks is decoration. A capped list that can only improve is worth more than an exhaustive one that can only grow.

A sample of what's on it:

| Ban | Instead |
|---|---|
| Violet/purple gradient as the accent | the project's own accent |
| Three equal feature cards | the real count, sized by real weight — four features get four |
| Inter on slate-900 as the entire type decision | a display face and a body face chosen deliberately |
| A dashboard built out of `div`s | a real screenshot, an embedded live component, or nothing |
| Invented metrics — "99.99% uptime", "10,000+ users" | real numbers, or no numbers |
| A list that renders nothing at zero rows | an empty state naming the thing and offering the action |
| "Invalid input" as validation copy | name the constraint and the fix |
| Destructive actions with no confirmation and no undo | confirm, or make it undoable |

Entries are scoped **product** or **marketing**, so product entries don't fire on a landing page and vice versa. The product-UI state gaps are the product-side equivalent of a purple gradient: nobody designed that silence, it's just what got generated.

## The stack layer

The house default is Tailwind v4 + shadcn/ui, skippable whole by a project on another stack. These are **correctness rules that prevent silent wrongness**, not style preferences.

The v3→v4 renames are the reason to check the version first. Every one is a valid class name in v4 that renders *smaller* than intended — no error, no warning, just a subtly wrong result that reads as a design decision: `shadow-sm`→`shadow-xs`, `shadow`→`shadow-sm`, `rounded`→`rounded-sm`, `ring`→`ring-3`, `outline-none`→`outline-hidden`, `bg-gradient-to-r`→`bg-linear-to-r`.

On shadcn: `className` adjusts layout, not appearance — restyling internals from outside means the variant should have been extended. Semantic tokens only, no manual `dark:` overrides (a token that needs one was the wrong token), no manual `z-index` on overlays, `cn()` for conditional classes rather than string concatenation.

## Self-critique

The **written pre-flight always runs** — it's the one that fires in headless CI and locked-down VMs. It checks the catalog filtered to the surface, the full accessibility floor, the two signature checks, and a **remove-one-accessory pass**: look at what you built and take one thing away. There's nearly always one decoration that doesn't serve the brief, and it's nearly always easier to see at the end than at the start.

It's a critique, not a gate. uikit is **not a gate** at all — taste isn't pass/fail, and a build that can fail for it fails on something unfalsifiable.

The **pixel pass is opt-in**, on an explicit ask, using only what's already present. It **never installs a browser, never starts a dev server it wasn't told to start, never seeds data.**

Either way it **degrades loudly** — never claiming a visual check that didn't happen, because a UI reported as verified when nothing looked at it is worse than one reported as unverified.

## Hands off to

No `DESIGN.md` in the project? [`designkit`](./designkit.md) `init` — it derives the system from shipped UI, and there's now shipped UI to derive from. Otherwise [`commitkit`](./commitkit.md); uikit leaves changes unstaged and does not commit.

Either way the hand-off **repeats the design read verbatim**. It's the only durable record of why the UI looks the way it does, and repeating it is what carries it into a PR body when this runs inside a pipeline.

## Install

```sh
npx skills add mimukit/skills -s uikit
```

Source: [`skills/uikit/SKILL.md`](../../../skills/uikit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`fd96414` on 2026-08-07._
