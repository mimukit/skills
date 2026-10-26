# Plan: uikit mockup mode

Grilled: 2026-10-26

## Context

A request for a mockup today gets an HTML page. `skills/uikit/SKILL.md:265` defines a mockup as "an HTML page built for a person to compare or approve", and the popular mockup skills ([Magdoub wireframe](https://github.com/Magdoub/claude-wireframe-skill/), [baoyu-design](https://github.com/jimliu/baoyu-design), [kgoedecke ui-mockup-skill](https://github.com/kgoedecke/ui-mockup-skill)) do the same. The owner wants an image by default and HTML only when the owner asks for code.

The `Mockups` section is a footnote to `build`, so a mockup request has no mode, no steps, and no done condition of its own. "Show me a few options for this screen" and "mock up three versions" also fire `prototypekit`, which builds throwaway code in the app. Two skills claim one phrase.

Goal behind the request: a person who asks for a mockup sees an image and reads no code.

Target: none as a number. The owner tests the result manually with two prompts, "mock up the settings screen" (expect an image, no HTML) and "give me the settings screen mockup as code" (expect HTML).

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Where the behavior lives | A `mockup` mode in `uikit`, not a new skill. A new skill would cost a permanent index entry for a choice the agent makes from context. |
| Ideation | A variant of `mockup`, not a mode. A request for options produces N images side by side, each from a different design read. The steps match a single mockup. |
| Option cap | 4 side-by-side options (defaulted). More images shrink until a reader cannot compare them. |
| Default output | An image. HTML or other code only when the user asks for code ("as code", "the HTML", "the component"). |
| Skill layout | Full split (asked). `build`, `audit` and `mockup` each live in `skills/uikit/modes/<mode>.md`. The root keeps mode routing, the design read, the precedence ladder, the catalog, and the shared floors. Every other split skill uses this shape. The split of `build` and `audit` is a behavior-neutral move with no wording change. |
| Image path | By what the box has, generator first (asked). Use an image-generation tool when the session lists one. Otherwise render a throwaway HTML file to PNG with a CLI browser driver. The user sees only the image. A user word such as "exact" or "match the real layout" moves the choice to the render. |
| Naming the tools | The public skill says "an image-generation tool in the current tool list" and "a CLI browser driver on `PATH`, for example `playwright-cli`" (defaulted, same wording as `skills/verifykit/SKILL.md:57`). With two generators, the mode asks once. |
| No image path available | Say so, name what is missing, and offer the HTML file path as the fallback. Never show raw HTML as if it were the mockup. |
| Owner of "show me a few options", "mock up three versions" | `uikit mockup`. `prototypekit` keeps interactive throwaway code that answers a question. |
| Design source | The mockup reads `DESIGN.md` and walks the precedence ladder, then applies the catalog. It skips the stack layer, the mobile layer, and the accessibility floor, because no code ships. |
| Global rule | One line in `~/.claude/CLAUDE.md` (asked): "A mockup request gets an image. Write HTML or other code only when I ask for code." |
| Test approach | Manual, by the owner. No runner. |
| Outward actions | None. The plan commits and pushes nothing by itself. |

## Approach

Split `uikit` into a routing root plus `modes/`, write `mockup` as the third mode, then route to it from the description, from `When this fires`, and from `prototypekit`. The mode reuses the precedence ladder, the design read, and the anti-slop catalog already in `skills/uikit/SKILL.md`. It reuses the probe in `skills/verifykit/SKILL.md:57` for the render path, stated as an answer with a fallback because `uikit` is public and must install alone.

Rejected: a separate `mockupkit` skill (index cost, see Design decisions), an `ideation` mode (a count of options, not a different process), and a mixed layout with only `mockup` as a file (no skill mixes the two shapes).

### Phase 1: Add the global rule
Attended: the owner approves the one-line wording before it lands in `~/.claude/CLAUDE.md`.

Add the line from Design decisions to `~/.claude/CLAUDE.md`, in the owner's chosen wording.
Done when `grep -n "mockup" ~/.claude/CLAUDE.md` shows the line.

### Phase 2: Split uikit into modes

Move `## Mode: build` and `## Mode: audit` into `skills/uikit/modes/build.md` and `skills/uikit/modes/audit.md` with no wording change. Leave one pointer per mode in the root in the trigger-carrying form. Move each mode's `Hand off` with its body. Fix every anchor that crosses the move.
Done when `make lint` exits 0 and `git diff -M --stat` shows the two mode bodies as moves, not rewrites.

### Phase 3: Write the mockup mode

Write `skills/uikit/modes/mockup.md` with steps that each end on a done condition: ground it (ladder rung, design read, screen list, option count up to 4), produce it by the image path rule, check it against the catalog, hand off. Delete the old `## Mockups` section from the root and the `A mockup follows Mockups` bullet from `build`. Keep the file-based edit economy from the old section (write once, edit the file, show once, a subagent for large sets). State the no-image-path fallback.
Done when `grep -rn "HTML page built for a person" skills/uikit` prints nothing, and the mode states the image default, the code-on-request exception, the option cap, the generator-first rule, and the fallback.

### Phase 4: Route to the mode

Add a `mockup` branch to the `uikit` description inside the first 300 characters of the trigger, pruning a synonym to make room. Add a `mockup` line to `When this fires`. In `skills/prototypekit/SKILL.md`, remove "competing UI mocks" from the description and the "show me a few options for this screen" and "mock up three versions" triggers at line 19. Add one pointer there to `uikit mockup`. Run `make cheatsheet`.
Done when `make lint` exits 0 and `git diff docs/wiki/cheatsheet.md` shows only the two changed what-clauses.

### Phase 5: Update the wiki

Update `docs/wiki/workflow.md`: the `uikit` section at line 231 gains the `mockup` mode, and the `ui` line at 156 says image options go to `uikit mockup`.
Done when `make lint` exits 0 and `grep -n "uikit mockup" docs/wiki/workflow.md` prints at least one line.

### Phase 6: Owner test
Attended: the owner runs the two test prompts after Phases 1 to 5 land. It cannot move earlier, because it needs the build.

Run both prompts from Context in a fresh session on a project with a UI.
Done when the first prompt returns an image with no HTML shown, and the second returns HTML.

## Open questions

- None deferred. The generator-first rule can produce an image that ignores `DESIGN.md` tokens. The owner test shows whether that matters. The tuning of the "exact" override word belongs to a later pass.

## Non-goals

- A new skill, or an `ideation` mode.
- Changes to `uikit build` or `audit` behavior. Phase 2 moves them and changes no wording.
- A mockup that ships as production code. `build` owns that.
- Interactive prototypes. `prototypekit` owns those.
- A bundled library of palettes or layouts. The `uikit` rule against a taste library stays.
