# Plan — researchkit

## Context

[IDEAS.md](../../IDEAS.md) lists `researchkit` as the top off-flow backlog item: "Research a topic, tech, tool, architecture, or service on demand — compare the options and recommend the right one (feeds `plankit`)." It's the last skill that couples into the shipped `plankit → grillkit → issuekit → …` workflow — it front-runs `plankit` by answering the "which tool / which approach" question that plankit itself can't research well.

Two source inputs were in tension and reconciled in a grillkit session:

- **Upstream** ([mattpocock/skills research](https://github.com/mattpocock/skills/blob/main/skills/engineering/research/SKILL.md)) — a neutral, background cited-notes generator: dispatch an agent to investigate a question against primary sources, write cited Markdown, keep working in parallel. Its one strong idea is **primary sources + citations**.
- **This repo's intent** — an *opinionated* compare-and-recommend decision tool that feeds plankit.

researchkit keeps upstream's evidence rigor and rebuilds it around the **decision**: it always lands a recommendation, not neutral notes.

**Success:** on demand, `/researchkit` answers a "which should I use / which approach" question with credible options, cited tradeoffs, and a clear recommendation — grounded in primary sources — then offers to feed the result into plankit.

## Design decisions (settled)

Locked in a grillkit session ([transcript decisions](#) folded in here):

| Decision | Resolution |
|----------|-----------|
| **Core job** | **Compare & recommend.** Answer a "which tool / which approach" question with options + tradeoffs + a clear recommendation. Degrades gracefully to a **cited explainer** when there's genuinely nothing to compare (the options collapse to one). Never the neutral, no-opinion note-taker — it always lands a recommendation. |
| **Execution** | **Synchronous in-session by default.** Dispatch a background agent **only** when the host supports it *and* the user explicitly asks ("research this in the background"). Degrades cleanly to sync when background isn't available. |
| **Output** | **Print the artifact inline by default; write a file only when asked.** When saved: `docs/research/research-<slug>-YYYY-MM-DD.md`, following any existing research/notes/RFC location the repo already uses. |
| **plankit handoff** | End with the recommendation, then **offer** plankit ("turn this into a plan?") + **offer** to save — auto-start neither. The plankit nudge is phrased as **optional** (public skill; plankit may not be installed). |
| **Evidence bar** | **Primary sources** — official docs, source code, specs, first-party APIs, maintainer benchmarks — over blog-post hearsay. Each **load-bearing claim** in the comparison carries a source. **Freshness check:** note each source's version/date and flag when the landscape may have moved. **Never fabricate a citation.** |
| **Web access** | **Tool-agnostic.** Describe the goal (search the web, fetch and read primary sources) and use whatever web search/fetch tools the host exposes — don't pin tool names. **No web access → warn plainly** and fall back to cited-from-knowledge with an explicit staleness warning; never fake a source. |
| **Name** | `researchkit` — functional word leads, `kit` appended (per [AGENTS.md](../../AGENTS.md)). |
| **Visibility** | **Public** (`internal: false`) — portable, self-contained, no repo-relative links or `make`/`AGENTS.md` dependency. |
| **Provenance** | "My version of" the mattpocock upstream — authored from scratch, keeping only its primary-sources+citations idea, rebuilt around compare-and-recommend. |

## Approach

Single lean `SKILL.md` — no satellite files, no bundled scripts (nothing fragile enough to warrant one; web tools are the host's).

### Phase 1 — Frontmatter + triggers
- `name: researchkit`, `metadata.internal: false`, `license: MIT`.
- `description`: front-load "Research options and recommend one …" then a pushy **"Use when …"** clause naming the phrasings: "research X", "which should I use, A or B", "compare X and Y", "evaluate options for Z", "what's the best tool/library/service for …", "should we use X or Y", "/researchkit".
- `allowed-tools`: omit or keep permissive — do **not** pin `WebSearch`/`WebFetch` (portability). If listed, keep tool-agnostic phrasing in the body regardless.

### Phase 2 — Body: identity + when it fires
- One-paragraph statement of the job (compare & recommend, feeds plankit) and the two things it is **not**: not neutral note-taking (always recommends), not deep single-repo grounding (that's plankit's step 2).
- Distinguish from plankit explicitly so the pair reads cleanly.

### Phase 3 — Procedure
1. **Frame the question** — pin down what decision is being made and the constraints that matter (budget, stack, scale, team). Ask a couple of scoping questions only if the ask is a bare one-liner.
2. **Find the credible options** — enumerate the real contenders (don't pad with strawmen); if only one survives, say so and switch to explainer mode.
3. **Investigate against primary sources** — use the host's web tools; read official docs/source/specs; capture version/date; flag stale evidence. Degrade with a warning if no web access.
4. **Compare** — options × the constraints that matter, each load-bearing claim cited.
5. **Recommend** — one pick + a one-line why, plus the condition under which you'd pick otherwise.
6. **Hand off** — offer plankit (optional) + offer to save to `docs/research/`; leftover uncertainties become "open questions for plankit."

### Phase 4 — Artifact format
Inline-first Markdown block: `# Research — <question>` → `## Recommendation` → `## Options compared` (table) → `## Evidence (primary sources)` (claim → source, with dates) → `## Open questions for plankit`.

### Phase 5 — Notes / degradation
- Sync default; background only if host supports + user asks.
- No web access → warn + best-effort from knowledge, never fake a citation.
- No filesystem → print the artifact as a codeblock (already the default; saving is the opt-in).

### Phase 6 — Wire-up (repo housekeeping)
- Add row to README skills table (public).
- Add to `skills.sh.json` in the fitting group.
- Remove the `researchkit` row from IDEAS.md backlog on ship.
- `make lint name=researchkit` clean; live-test in a fresh session.

## Open questions

- **Background-execution mechanics** — how to detect host background-agent support portably. Lean: keep it a soft capability ("if your host can run background agents and you ask, dispatch one") rather than encoding any specific API — safest for a public skill.
- **Overlap with the host's own `deep-research`** — some environments ship a heavier research harness. researchkit is the lightweight, decision-focused, plankit-feeding tool; note the distinction rather than competing on depth.

## Non-goals

- **No implementation** — it researches and recommends; it doesn't write code or plans (that's plankit → implementkit).
- **No deep single-repo grounding** — reading *this* codebase to reuse existing patterns is plankit's step 2, not researchkit's job.
- **No neutral, opinion-free note dump** — it always lands a recommendation; if you want raw cited notes with no pick, that's a different tool.
- **No bundled scripts / satellite files** — nothing here is fragile or large enough to earn one.
