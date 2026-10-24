## Mode: `audit`

**Read-only. Writes nothing, ever.** It sweeps a codebase for motion to fix and motion that is missing, ranks both, and crowns one item for `build`. A uikit audit may flag an "extra animation" and route it here; this mode judges whether that motion stays, changes, or goes.

**Restraint is the bar.** Daily use argues for less motion, not more. Expect to reject most candidates for new motion, and treat "the motion here is already right" as a result worth stating.

### 1. Resolve the target

Take named paths first. Otherwise take the app's interactive UI: components, routes, and styles, with tests, stories, and build output excluded. Ask when the repo holds several apps and the ask names none. State the target in one line. **Done when** the target line names every directory in scope.

### 2. Recon

Map the motion surface before you judge any of it:

- **Stack and tokens.** Run [Stack detection](../SKILL.md#stack-detection).
- **Personality.** Decide whether the product reads as a crisp tool or a playful app, because [Cohesion with tokens](../SKILL.md#cohesion-with-tokens) depends on it.
- **Every animation.** Grep for `transition`, `animation`, `@keyframes`, `@starting-style`, Tailwind `transition-*`, `ease-*`, and `animate-*` classes, Motion `animate` and `exit` props, `.animate(`, `useSpring`, and `requestAnimationFrame`. Record `file:line` and the element for each.
- **Every motion-free interactive surface.** List the pressables with no `:active` state, conditional renders with no transition (`{open &&`, `hidden` toggles), accordions and `details`, popovers and menus, toasts and sheets, lists that gain or lose items, drag handlers, and empty, success, and first-run states.
- **Frequency.** Place each entry from both lists on a tier of [The frequency gate](../SKILL.md#the-frequency-gate).

**Done when** both lists are complete for the target and every entry carries `file:line` and a frequency tier.

### 3. Fixes to existing motion

Read each animation through these lenses, each a heading of the standard:

1. Purpose and frequency: [Purpose](../SKILL.md#purpose), [The frequency gate](../SKILL.md#the-frequency-gate).
2. Curve and length: [Easing](../SKILL.md#easing), [Duration](../SKILL.md#duration).
3. Origin: [Physicality and origin](../SKILL.md#physicality-and-origin).
4. Interruption and timing: [Interruptibility](../SKILL.md#interruptibility), [Asymmetric timing](../SKILL.md#asymmetric-timing), [Springs](../SKILL.md#springs), [Gestures and drag](../SKILL.md#gestures-and-drag).
5. Cost: [Property cost](../SKILL.md#property-cost), [Clip-path and transforms](../SKILL.md#clip-path-and-transforms).
6. Access: [Reduced motion and pointer gating](../SKILL.md#reduced-motion-and-pointer-gating).
7. Cohesion: [Cohesion with tokens](../SKILL.md#cohesion-with-tokens), [Stagger](../SKILL.md#stagger).

For each finding, prefer removal over a changed ingredient, and a changed ingredient over an addition. Give the exact fix values from the standard or the project's tokens. **Done when** every animation from recon has passed all seven lenses, with a finding or a pass for each.

### 4. Missing motion

Put each motion-free surface through four gates, in order. A candidate that fails one gate is rejected at that gate:

1. **Frequency.** The surface sits at the occasional or rare tier. A keyboard-initiated action fails outright.
2. **Purpose.** It names one purpose from [Purpose](../SKILL.md#purpose); delight passes only at the rare tier.
3. **Speed.** The motion works inside its band in [Duration](../SKILL.md#duration). A moment that only works slow and showy fails.
4. **Function.** Motion helps the person here. Data a person reads or acts on fails.

Give each survivor a recipe: the properties, the curve, the duration, the origin, and the reduced-motion behavior. **Done when** every motion-free surface from recon is a survivor with a recipe or a rejection with its gate.

### 5. Vet, then rank

Reread the cited lines for every finding and every survivor. Drop an item that is by design (a centered modal, a long beat on a marketing page), duplicated, misattributed, or covered by a documented project decision. Label each kept item per [Guards](../SKILL.md#guards).

Rank the kept items by leverage: the felt effect times how often people meet it, against the size of the change. A fix that touches a shared token or a primitive outranks a fix to one screen. **Done when** every kept item is confirmed at its `file:line` and holds a rank.

### 6. Report

Three parts, in this order:

1. **Ranked items.** One table: `#`, `file:line`, kind (fix or missing), finding, standard rule, fix or recipe with exact values, evidence label.
2. **Rejected candidates.** This section is required. List every surface you considered for new motion and rejected, with the gate that rejected it, plus each existing animation you judged should stay as it is. With no candidates, state why the sweep found none.
3. **Coverage.** Files read, animations judged, surfaces gated.

**Done when** all three parts are in the reply and the rejected list names a gate for each entry.

### 7. Hand off

**What changed.** Nothing. State that this audit wrote no file.

**Where it landed.** The report is in this reply.

**Next.** Crown item 1 alone, by its `file:line`. Build it with **motionkit `build`**: "fix the menu easing at `src/menu.css:12`". When no item survives, state "nothing to change" and stop.
