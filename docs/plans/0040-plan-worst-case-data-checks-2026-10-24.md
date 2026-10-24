# Plan: worst-case data checks

Grilled: 2026-10-24

## Context

A UI built against demo data looks finished until real data arrives: a 60-character company name, an email with no break point, a one-letter name, a count of 1 that reads "1 items", an empty list with no empty state, a role that is missing. No check in the collection feeds a screen that data on purpose. `qakit` lists "Edge & boundary" as a dimension (`skills/qakit/SKILL.md:50`), but it names categories, not values, and it has no way to put a value on the screen. `reviewkit` checks "Edge cases" in its correctness pass (`skills/reviewkit/SKILL.md:105`), but it does not ask what limit each rendered field has or whether the UI handles that limit. `uikit` covers empty, loading, and error states as a design rule, not as a test.

Emil Kowalski's `break-ui` skill ([emilkowalski/skills](https://github.com/emilkowalski/skills), MIT, read at commit `2d22863`) does this as one skill: map every rendered value and its limit, build a worst-case dataset from a catalog, render it behind a dev-only toggle, and report each break with a fix. This collection splits that work on the seam between reading code and running it, because the loop already has an owner for each half: `reviewkit` reads code and never runs the app, `qakit` is the one skill that opens a browser (`skills/afkkit/SKILL.md:76`), and `afkkit`'s acceptance check and Fix step already turn qakit's ❌ results into fixes (`skills/afkkit/SKILL.md:208`). The goal the owner stated is that an agent tests the UI, tries to break it, and fixes what breaks. The split meets it with no new skill and no new fix logic.

Success: a qakit run on a screen that renders data feeds it worst-case values with no file written to the repo, and reports each break as a ❌ with what the page showed; a reviewkit run flags a rendered field whose limit the UI does not handle; afkkit picks both up with no change of its own.

Target: on `~/projects/primeshopr/apps/admin` (a Vite SPA that fetches its lists in the browser with `@tanstack/react-query`), one qakit run reports at least one worst-case ❌ with its observed value and the mocked route it used, and `git status` in that repo shows no new file; one reviewkit run over a commit that touched a list screen reports at least one data-bounds finding with the limit quoted; `make lint` in this repo reports 0 errors.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Where the work lives | Split. `reviewkit` gets the static half, `qakit` the runtime half. No new skill and no `reviewkit` browser pass, because reviewkit is read-only by contract and the browser opens in qakit only. |
| reviewkit's static check | One "Data bounds" item in Pass 4: Correctness, beside "Edge cases". For each value the changed UI renders, find its limit (validation schema, database column, API type, `maxLength`) and check that the UI handles it: truncation or wrapping for long text, a break rule for unbroken strings, plural forms at 1, an empty state at 0, a fallback for a missing optional field. A frontend limit shorter than the backend one is a finding. A field with no limit found is handled by the unbounded rule below. |
| qakit's runtime check | A worst-case check family under the existing "Edge & boundary" dimension, held in a new satellite `skills/qakit/worst.md`, read only when the change renders data in a UI and a browser driver is present. Same disclosure shape as `db.md`. |
| Injection | Network route mocking. qakit captures the real response shape of each list or detail request the screen makes, then serves a worst-case body of the same shape through the browser driver's request mocking (`playwright-cli route <pattern> --body …` on this box; the satellite states the goal and tells the agent to read the driver's `--help`, not a pinned syntax). Nothing is written to the repo. |
| Server-fetched data | A route mock in the browser cannot reach data the server fetches and renders (Next.js server components, SSR loaders). Fallback order: seed worst-case rows on a declared disposable target, using qakit's existing disposable-target rules; otherwise a manual case naming the values to enter. |
| Value source | Schema-backed or plausible, never random. The limit from the schema or the column comes first; with none, a long but believable value, and the field goes in the report as "unbounded". One dataset spreads its failures across the first rows, because those are on screen. |
| Catalog | Rewritten from upstream `CATALOG.md` into `worst.md`: names, emails and identifiers, labels from data, numbers and money, collections (0, 1, many), time, images and media, missing optional fields. Facts and values carried, prose rewritten, credit line at the end. |
| When it runs | Automatically, on every qakit run whose change renders data in a UI and has a browser driver, which includes every afkkit run. qakit's description also gains a "try to break this component" trigger, so a person can ask for it directly. |
| Viewports | qakit's existing widths: `DESIGN.md` breakpoints, else 1440 px and 375 px. Overflow at 375 px is the most common break. |
| Fix | Report, then route. qakit records each break as a ❌ (observed value, mocked route, viewport, the proposed fix) and fixes nothing; reviewkit reports its finding and edits nothing. afkkit's acceptance check and Fix step fix them in an unattended run; attended, the next move is an implementkit fix round. |
| afkkit | No change. It already runs qakit's browser checks and reviewkit's passes 3 and 4, and it already reads qakit's ❌ results as evidence. |
| Test approach | No new runner. Lint, then one live run of each skill on the target fixture. |
| Unbounded fields in reviewkit | Split on the render, to keep reviewkit's confidence bar. An unbounded field with no long-text handling at its render line is a 🟡 finding that quotes the render line and names where the review looked for a limit: `unbounded: no limit in <schema>, <column>, <API type>; render at file:line has no truncation or break rule`. An unbounded field that already has handling is no finding. A limit that lives outside the repo (a third-party API) goes in the coverage note. |
| reviewkit scope | Only the fields whose render or data source the diff adds or changes, not every field on a touched screen. |
| Direct break ask | "Try to break this component" writes a normal `docs/qa/` plan scoped to one worst-case scenario. The slug ends in `-worst-case`, and the Summary says the run covered the worst-case checks only. One artifact shape, so prkit links it and a re-run updates it in place. |
| Response shape | Capture a live response first. When the dev server returns no rows, build the shape from the API types in the repo. |
| Pagination and auth | Mock the first page only, and set the total-count fields to the worst-case count. Leave auth and session requests unmocked, and start the mocks after login. |
| Mocked requests | Reads only: `GET`, and a GraphQL `POST` whose operation is a query. A write is never mocked, because a mock would hide a real save. |
| Severity | 🔴 a hidden or unreachable control, a crash or blank screen, `undefined`, `null`, or `NaN` on screen, or a wrong count. 🟡 clipped text with no ellipsis or title, a wrong plural, or a missing empty state. 🟢 a wrap that reads badly. |
| ❌ line shape | `❌ <page> · <field> = <worst-case value> @ <viewport> via route <pattern> → <what the page showed>; expected <what it should show>; fix: <proposed fix>`, under Browser checks. |
| Outward actions | Phases 1–3 may commit on `main` in this repo, one Conventional Commit per phase. No push, no issues, no PR. Phase 4 commits and writes nothing in `~/projects/primeshopr`. |

## Approach

Add one item to reviewkit, one satellite and three pointers to qakit, and the doc surfaces that name them. The runtime half reuses qakit's driver list, its local-state and disposable-target rules, its viewport widths, and its screenshot directory; the static half reuses reviewkit's evidence and confidence bar. Each skill states only its own half, and each names the other as its answer plus a fallback, which the portability rule allows.

Rejected alternatives, one line each:

- **A reviewkit browser pass** (the owner's first idea). It breaks reviewkit's read-only contract and starts a dev server on every code review.
- **A committed fixture and a dev-only toggle**, the upstream shape. It is durable, but it writes code per component and makes the check a build task, not a QA check.
- **DOM text substitution** with `eval`. It works on any data source, but it tests layout only: no plurals, counts, or empty states.
- **A new `breakkit` skill.** "Try to break this" is one trigger on qakit, not a moment that needs its own entry in the index.

### Phase 1: reviewkit data bounds
Add the "Data bounds" item to Pass 4: Correctness in `skills/reviewkit/SKILL.md`, with its evidence rule (quote the limit and the render line) and its unverified fallback (a limit the review could not find is "unbounded", not a guess). Add the unbounded rule and the diff-only scope from the design decisions. Name qakit's worst-case checks as the runtime half, with the plain fallback "render the screen with long, empty, and missing values by hand".
Done when: `make lint` passes, the item names every handling case listed in the reviewkit design decision and the frontend-shorter-than-backend rule, and it states all three branches of the unbounded rule.

### Phase 2: qakit worst-case satellite
Write `skills/qakit/worst.md`: when it applies, the field map (every rendered value, its source, its limit or "unbounded"), the catalog, the route-mock procedure (capture the real response or fall back to the API types, build a same-shape worst-case body, mock reads only and the first page only, start after login, serve it, reload, assert), the server-fetched fallback, the assertions (horizontal overflow per viewport, text clipped with no ellipsis or title, plural at 1, empty state at 0, a missing optional field rendered as `undefined`, `null`, or `NaN`, console errors), the severity rule, and the ❌ line shape. Add the pointer in qakit's Scope step (``change renders data in a UI and a driver is present → read [worst.md](worst.md), then follow it in every step it names``), the dimension line under "Edge & boundary", the run under Browser checks, the "try to break this component" trigger in the description, and the direct-ask rule (one worst-case scenario, `-worst-case` slug).
Done when: `make lint` passes, the description stays under 1,024 characters with "Use when" inside the first 300, `worst.md` is at or under 1,200 words, and every catalog group from the design decision has a section.

### Phase 3: Doc surfaces
Run `make cheatsheet`. Add a sentence to the qakit and reviewkit paragraphs of `docs/wiki/workflow.md` naming the two halves and that afkkit's Fix step fixes what they find.
Done when: `make lint` reports 0 errors and 0 warnings, and `git diff docs/wiki/cheatsheet.md` shows the changed qakit line.

### Phase 4: Live test
Attended: the owner starts the fixture app and judges the reports.
Dev-link with `make link` if the installed copies are not the repo copies. Run qakit against a list screen in `~/projects/primeshopr/apps/admin` (for example the users or members route) on the local dev server. Run reviewkit over a commit in that repo that touched a list screen, for example `41376d1` (members page). Unlink when done.
Done when: the qakit report has at least one worst-case ❌ with its observed value, viewport, and mocked route; `git status --porcelain` in `~/projects/primeshopr` lists no new file from the run; the reviewkit report has at least one data-bounds finding with the limit quoted, or an unbounded finding that quotes the render line; every mismatch led to an agreed edit.

## Non-goals

- Fixing breaks inside qakit or reviewkit.
- A committed fixture, a dev-only toggle, or any file written to the target repo.
- Load and performance testing with large volumes; that stays in qakit's Performance dimension.
- Visual design critique of the broken state; that stays with `uikit`.
- Any change to `afkkit`, `implementkit`, or `testkit`.
