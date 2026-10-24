## Mode: `review`

**Read-only. Writes nothing, ever.** It judges the motion in a change and returns a findings table and a verdict. A fix is a separate `build` run, so the person who reads the verdict decides what to change.

**Flag by default; approval is earned.** Motion that runs is not motion that passes. A transition that lands late, grows from the wrong point, fires on a high-frequency action, or restarts on a second trigger is a finding even when nothing breaks.

### 1. Resolve the target

Take the first source that applies:

1. **Named paths**, such as a component, a stylesheet, or a route.
2. **The working tree**, when it holds uncommitted changes: `git diff` plus `git diff --cached`, and the untracked files from `git status --porcelain`, which a plain diff never shows.
3. **The branch against its base**, when the tree is clean: `git diff <base>...HEAD`, with the base from `gitkit` when installed, otherwise `origin/HEAD`.
4. **Ask**, when none resolves.

State the target in one line, then run [Stack detection](../SKILL.md#stack-detection). **Done when** the target line names every file in scope and the stack line names the drivers and token homes.

### 2. Find every animation

Read each file in scope in full, not only the changed hunks, because a hunk that changes a duration can hide the `transition: all` three lines above it. Collect every motion source: `transition` and `animation` declarations, `@keyframes`, `@starting-style`, Tailwind `transition-*`, `duration-*`, `ease-*`, and `animate-*` classes, Motion `animate`, `initial`, `exit`, and `transition` props, `.animate(` calls, and `requestAnimationFrame` loops. Record each as `file:line`, the element it moves, and the trigger that starts it. **Done when** every file in scope is read and every motion source in it has a row in your working list, or the list states "no motion in scope".

### 3. Judge each animation against the standard

Walk every animation through [the motion standard](../SKILL.md#the-motion-standard), top heading to bottom, starting with [The frequency gate](../SKILL.md#the-frequency-gate). A rule that the project's own token or documented convention overrides is not a finding; note the override once.

Escalate these on sight, at the highest severity:

- `ease-in` on an entrance, an exit, or any response to input ([Easing](../SKILL.md#easing)).
- An entrance from `scale(0)`, or a pure fade with no starting transform ([Physicality and origin](../SKILL.md#physicality-and-origin)).
- A trigger-anchored popover, menu, or tooltip that scales from its own center.
- `transition: all`, or a layout property animated where a transform tier exists ([Property cost](../SKILL.md#property-cost)).
- Keyframes on UI a user can trigger again mid-motion, such as toasts, toggles, and tabs ([Interruptibility](../SKILL.md#interruptibility)).
- Any animation on a keyboard shortcut, the command palette, or another action at the top frequency tier.
- UI motion over 300 ms with no stated reason ([Duration](../SKILL.md#duration)).
- Movement with no reduced-motion path, or hover motion with no fine-pointer gate ([Reduced motion and pointer gating](../SKILL.md#reduced-motion-and-pointer-gating)).
- A parent CSS variable that drives a child's `transform`.

Label each finding per [Guards](../SKILL.md#guards). A claim about feel or smoothness from code alone is "needs a recording". When a browser driver is present, record the doubtful ones and relabel them "recorded". **Done when** every animation in the working list has a finding or an explicit pass, and every finding has a heading and a label.

### 4. Choose the fix by the remedy order

For each finding, take the earliest remedy that resolves it:

1. **Remove the motion.** This applies when the animation fails the frequency gate or names no [Purpose](../SKILL.md#purpose).
2. **Fix the ingredient.** Change the curve, the duration, the origin, the starting transform, the property, the driver (keyframes to a transition or spring), or the timing asymmetry.
3. **Add what is missing.** Add the reduced-motion path, the hover gate, a stagger, or a blur mask on a crossfade.

Give the exact values: the curve as a token or a `cubic-bezier()`, the duration in milliseconds, the property list. Reuse the project's tokens. **Done when** every finding has one fix with exact values and no fix uses a later remedy where an earlier one works.

### 5. Report

One table, one row per finding, worst first:

```
| file:line | Finding | Standard rule | Fix | Evidence |
| --- | --- | --- | --- | --- |
| src/Toast.tsx:41 | Toast enters on @keyframes; a second toast restarts the first | Interruptibility | Transition transform and opacity, 200ms var(--ease-out), start in @starting-style | from code |
| src/menu.css:12 | Menu enters with ease-in 320ms from scale(0) | Easing | ease-out var(--ease-out), 180ms, from scale(0.96) opacity 0, origin var(--transform-origin) | from code |
```

Then the verdict, one of two:

- **Block**: any escalation trigger fired, or a finding needs the first remedy.
- **Pass**: no escalation trigger fired, durations and curves sit inside the standard, interruptible UI uses transitions or springs, and every movement has a reduced-motion path.

Close with a coverage line: files read, animations judged, findings by label. **Done when** the table, the verdict, and the coverage line are in the reply.

### 6. Hand off

**What changed.** Nothing. State that this review wrote no file.

**Where it landed.** The table and the verdict are in this reply.

**Next.** Crown the worst finding by its `file:line`. Fix it with **motionkit `build`**: "fix the toast entrance at `src/Toast.tsx:41`". When the verdict is pass, say that the motion passes the standard and stop.
