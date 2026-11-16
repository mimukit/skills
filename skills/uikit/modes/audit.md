# Mode `audit`: sweep shipped UI for the tells

**Read-only.** Fixing is a separate `build` run.

### 1. Resolve the target

In order, taking the first that applies:

1. **Explicitly named paths**, meaning a directory, a component, or a route.
2. **The UI files in the working tree or the branch diff**, untracked files included, when uncommitted or branch changes exist and no path was named.
3. **Ask**, when neither resolves. Never sweep a whole repository by reflex.

State the target in one line before reading anything. This step is done when the target line names every path in scope.

### 2. Sweep

Run [the catalog](../SKILL.md#the-anti-slop-catalog), filtered to the surface, so `product` entries don't fire on a marketing page and `marketing` entries don't fire on a settings screen. Then run [the accessibility floor](../SKILL.md#the-accessibility-floor), which fires on both, and [the mobile layer](../SKILL.md#the-mobile-layer) when the surface ships to phones. This step is done when every file in the target has been checked against every filtered catalog entry, every floor rule, and every mobile fix that applies, or is counted as skipped.

### 3. Report

Terse, clickable, no preamble. One finding per line:

```
src/components/Features.tsx:34   🔴  three equal feature cards for four features → show the real count, grouped by weight
src/components/Hero.tsx:12       🔴  fake dashboard built from divs → use a real screenshot or an embedded live component
src/app/settings/page.tsx:88     🟡  icon-only button with no accessible name → add aria-label
src/components/Card.tsx:7        🟢  rounded-3xl here, rounded-lg everywhere else → pick one corner language
```

🔴 Blocker · 🟡 Should-fix · 🟢 Nit. Then a mechanical verdict, and a **mandatory** coverage line: how many files were read and how many were skipped.

### 4. Hand off

**What changed.** Nothing. Say so.

**Where it landed.** Inline in this reply. No artifact by default; offer to save one only if asked.

**Next.** Crown the single worst finding and route it to [`build`](build.md). An extra or scattered animation finding routes to `motionkit review` when motionkit is installed, and motionkit judges whether to keep, change, or remove it. **"Nothing here reads as generated" is a valid result**; say the UI is clean and stop.
