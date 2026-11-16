---
name: uikit
description: >-
  Build production UI that reads as a deliberate choice for this project rather than an LLM default, audit shipped UI for the tells that give it away, or mock up a screen as an image before the build. Use when the user says "build this page", "make this UI not look AI-generated", "audit our UI", "make the frontend look good", "mock up this screen", "show me a few options for this screen", or "/uikit". Reads a project's DESIGN.md when one exists.
license: MIT
allowed-tools: Read, Write, Edit, Grep, Glob, Bash, AskUserQuestion, Task, Agent
metadata:
  internal: false
---

# uikit

**Taste is spent only where nothing else constrains the choice;** see [the precedence ladder](#the-precedence-ladder). uikit reads `DESIGN.md` and never writes it, ships no palettes or font pairings, audits visual and interaction issues only, and its pre-flight never blocks a build.

## When this fires

Route by the request, read that mode's file, then follow it.

- **`build`.** Generates the UI, including UI work handed over by an implementation step. Mode `build` → read [modes/build.md](modes/build.md), then follow it.
- **`audit`.** Read-only sweep of shipped UI. **Writes nothing, ever.** Mode `audit` → read [modes/audit.md](modes/audit.md), then follow it.
- **`mockup`.** Produces an image, and code only when the user asks for code. Writes no source. Mode `mockup` → read [modes/mockup.md](modes/mockup.md), then follow it.

Ask only when a request could go either way between `audit` and `build`, such as "look at the dashboard". A mockup request that asks for code is a `build`.

_Write every hand-off in this skill in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

## The precedence ladder

Four rungs. **Take the first that matches, and say which one it was before writing any code.** A lower rung never overrides a higher one; it only fills what the higher one leaves open.

| Rung | Matches when | What it constrains |
|---|---|---|
| **1. `DESIGN.md`** | a `DESIGN.md` exists at the repo root | its tokens *are* the palette, type scale, spacing, and radii. Full stop. Its Do's and Don'ts are the voice rules for UI copy. |
| **2. The shipped components** | a component directory, a `components.json`, or a token home (`@theme`, `:root` custom properties, a theme config) | the existing Button is the Button. Read three or four real components and match their composition, naming, and spacing habits. |
| **3. The subject's own world** | neither of the above, but the product is knowable through the README, a context file, route names, domain models, or the actual thing being built | the product's materials, vocabulary, and artifacts. A tool for a print shop should not look like a tool for a hedge fund. |
| **4. Stack defaults** | greenfield and the subject is genuinely opaque | the house default below, declared out loud as a default rather than a choice. |

### Signature materials by rung

The rung licenses *what the signature may be made of*, and [the design read](#the-design-read) says what the signature is:

- **Rungs 1–2.** Composition, interaction, and motion. The tokens are fixed and are not yours to move. The room is in layout, in how the surface behaves, and in what it does at rest.
- **Rungs 3–4.** Palette, type, and grid as well. Nothing is fixed, so the signature can be structural.

## The design read

**Five declared words, stated before any code is written.**

```
Design read · surface: product · audience: internal ops staff · rung: 2 (shipped components)
· signature: the dirty state, where each changed row shows its old value struck through until Save
· density: compact
```

| Word | Values | Why it's here |
|---|---|---|
| **surface** | `product` or `marketing` | the two have disjoint slop signatures; this is what filters [the catalog](#the-anti-slop-catalog) |
| **audience** | free text, concrete | "internal ops staff who live here 6 hours a day" implies different density than "a first-time visitor deciding in 8 seconds" |
| **rung** | `1`–`4` plus what matched | declares which constraint is in force and what the signature may be made of |
| **signature** | the one element this surface is remembered by, and its material | see below |
| **density** | `compact`, `comfortable`, `spacious` | the one axis that genuinely varies independently of the rung |

### The signature

**One element per surface. Exactly one.** The thing a person would describe if asked what the screen was like. Everything around it stays quiet and disciplined, so spend your boldness in one place, and cut any decoration that doesn't serve the brief.

**The signature works inside settled behavior.** Read the plan, issue, or request first. Every behavior it specifies (a Save action, a confirm step, a field, a flow order) ships as specified, and the signature lives in what the spec leaves open: presentation, feedback, layout, motion. A signature idea that would change specified behavior goes in the hand-off as a suggestion, and the build picks a signature that fits.

Three looks are the bold default, and none is a choice when it appears regardless of subject: warm cream (near `#F4F1EA`) with a high-contrast serif and a terracotta accent; near-black with a single acid-green or vermilion accent; a broadsheet layout with hairline rules, zero radius, and dense columns.

Worked examples:

- **Rung 2, a settings page whose spec names a Save action.** Default output: card, label-left/toggle-right rows, "Save changes" bottom-right. Correct and forgettable. Signature: *the dirty state*, so each changed row shows its old value struck through beside the new one, and the Save bar counts the pending changes. Zero new tokens, and Save still works exactly as specified. Autosave would be a stronger signature only when the spec leaves the save model open; here it goes in the hand-off as a suggestion.
- **Rung 3, a booking tool for a letterpress print shop.** Default output: Inter, slate-900, three feature cards, violet CTA. Signature: *the price list is a type specimen sheet*, with sizes shown at their real sizes, ranged left on a baseline grid, and a palette drawn from paper stock and ink.

### Never block on the design read

When the subject is unclear at rung 3 or 4, infer it from whatever the repo shows and *state the inference*; never stop to ask, because uikit runs inside unattended pipelines. Ask only when the user is plainly present and the request itself is ambiguous.

## The anti-slop catalog

_Contributor note: the cap is ~30 entries, each a ban with its alternative that an agent can check without rendering, so adding one means deleting one._

Scope tags: **P** product · **M** marketing · **B** both.

### Visual and CSS

| | Ban | Instead |
|---|---|---|
| B | Violet/purple gradient as the accent, on the hero or the primary CTA | the project's own accent; at rung 3–4, a color the subject actually implies |
| B | Gradient text on headings, or one italic serif accent word inside a sans headline | solid color in one face; reach for weight or size when a heading needs emphasis |
| B | Glassmorphism by reflex: `backdrop-blur` over translucent white cards | an opaque surface with a real border |
| B | A drop shadow on every surface | shadow marks elevation; a card sitting in normal flow has none |
| B | `rounded-2xl`/`rounded-3xl` on everything, and pill-shaped (`rounded-full`) buttons by reflex | one corner language, taken from the system |
| B | Decorative status dots, like a pulsing green dot bound to nothing | bind it to real state, or delete it |

### Typography

| | Ban | Instead |
|---|---|---|
| B | Inter (or the bare system stack) on slate-900 as the entire type decision | name a display face and a body face deliberately; make the type treatment part of the design, not a delivery vehicle |
| M | An eyebrow/kicker label above every heading | delete it; if the section needs context, the heading carries it |
| M | `01 / 02 / 03` numbered markers on content that is not a sequence | use them only when order is information the reader needs |
| B | Em-dashes in **interface strings** | a period, a comma, or two sentences. This governs strings on screen, not prose in the repo |
| B | All-caps letterspaced or monospace micro-labels scattered as texture | one label style, used where a label is genuinely needed |

### Layout

| | Ban | Instead |
|---|---|---|
| B | Three equal feature cards | show the real count, sized by real weight, so four features get four |
| M | Every section centered, `max-w` + `mx-auto` + `text-center` all the way down | vary alignment; centering is for the one thing that deserves it |
| M | A `Scroll ↓` cue or bouncing chevron | delete it; content bleeding past the fold does that job |
| M | Decorative hairline grids or dot-pattern backgrounds | delete; structure should encode something true, not decorate |
| M | Rotated vertical text down the side of a section | delete |
| M | A locale / weather / local-time strip | delete, unless the product is genuinely about time or place |

### Content and copy

| | Ban | Instead |
|---|---|---|
| B | "Jane Doe" / "John Smith" placeholder people | names from the product's own domain, or the real empty state |
| M | An "Acme Inc / Company Name" logo row | real customers, or cut the section until they exist |
| M | Invented metrics ("99.99% uptime", "10,000+ users", "2M requests") | real numbers, or no numbers |
| B | Lorem ipsum | real copy; when it's unknown, the shortest true sentence |
| M | Testimonial cards with invented quotes and stock avatars | cut the section until real ones exist |

### Fake product

| | Ban | Instead |
|---|---|---|
| M | A dashboard or app screenshot built out of `div`s | a real screenshot, an embedded live component, or nothing |
| M | Fake browser chrome wrapped around a mock | the same, and a fake window frame is the most recognizable tell on the list |

### Product-UI state gaps

| | Ban | Instead |
|---|---|---|
| P | A list or table that renders nothing at zero rows | an empty state naming the thing and offering the action that creates one |
| P | No loading state | a skeleton matching the real layout, or a labeled loading region |
| P | No error state | an error naming what failed and the recovery action |
| P | Icon-only buttons with no accessible name | `aria-label`, plus a tooltip when the icon isn't obvious |
| P | "Invalid input" as validation copy | name the constraint and the fix, as in "Password needs 12+ characters" |
| P | A disabled control with no stated reason | say why it's disabled, or don't disable it |
| P | Destructive actions with no confirmation and no undo | confirm, or make it undoable; undo is usually better |

## The accessibility floor

Every build clears these without announcing it, and `audit` reports any that a shipped surface misses:

- Visible `:focus-visible` on every interactive element. Never remove a focus ring without replacing it.
- `prefers-reduced-motion` honored wherever anything moves. **motionkit**, when installed, says what the reduced version keeps.
- WCAG AA contrast on text and on meaningful non-text.
- Semantic elements before ARIA: a `button` beats a `div` with `role="button"` and a click handler, always.
- Every control labeled, every image with `alt` (empty `alt=""` when decorative, deliberately).
- Everything reachable and operable by keyboard, in a sane tab order, with focus trapped in modals and restored on close.
- Touch targets no smaller than 44px on coarse pointers.

## The stack layer

The Tailwind v4 and shadcn/ui correctness rules live in [stack.md](stack.md). Read that file when the project uses Tailwind or shadcn/ui, and skip it whole on another stack.

## The mobile layer

The fixes that make a web app on a phone behave like an installed one (sticky hover, the tap flash, `100vh`, input zoom, safe areas, overscroll, touch axes) live in [mobile.md](mobile.md). Surface ships to phones → read [mobile.md](mobile.md), then apply it; skip it whole on a desktop-only surface.

## Self-critique

### The written pre-flight, which always runs

Check the output against:

1. **The catalog**, filtered to the declared surface.
2. **The accessibility floor**, all of it.
3. **The two signature checks**: exactly one signature exists, and its materials are legal at the declared rung.
4. **The remove-one-accessory pass.** Before shipping, look at what you built and take one thing away.

Report what you fixed and what you're leaving, with a reason.

### The pixel pass, opt-in

Only on an explicit ask, such as "look at it".

Use what is **already present**, in this order: a browser-automation tool the environment provides · an installed headless browser or an existing test-automation setup already in the project. Point it at whatever renders cheapest: a static file, a component preview route, a running dev server the user started.

Read facts with an evaluate call (text, a computed style, an element count) before anything else. Take a snapshot with no image by default. Use an image only for the visual judgment itself, and save it to a file when the user must see it.

**Never install a browser. Never start a dev server you weren't told to start. Never seed data.**

## Degrade loudly

No browser, no rendering, and no filesystem are normal conditions. State the missing check beside the result.

No filesystem at all (a browser-based agent)? Print each component as a fenced block labelled with its intended path, state the design read as normal, and name the commands the user should run themselves.

## Notes

- **Never invent data**, even as a placeholder.
- **UI copy here, prose elsewhere.** uikit governs the strings inside the interface. Repo prose, docs, and READMEs belong to a general prose pass, meaning **humankit** when installed.
- **Does not commit.** Changes are left unstaged for a commit step to group.
