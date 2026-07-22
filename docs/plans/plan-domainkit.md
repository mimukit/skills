# Plan — domainkit

## Context

The owner wants to track two living project-memory artifacts, sourced from [mattpocock/skills `domain-modeling`](https://github.com/mattpocock/skills/tree/main/skills/engineering/domain-modeling):

- **`CONTEXT.md`** — a Domain-Driven-Design **domain glossary**: project-specific terms, tight 1–2 sentence definitions of *what a term is*, and an `_Avoid_` list of rejected synonyms. Not a status file, not general programming concepts.
- **`docs/adr/NNNN-slug.md`** — Architecture Decision Records: why a hard-to-reverse, trade-off decision was made.

A researchkit pass over the upstream repo (fetched 2026-07-22) surfaced the load-bearing correction: upstream's `CONTEXT.md` is a **glossary**, not the capped "project status snapshot" the owner first described. The owner then confirmed they want the **glossary** interpretation (no token cap) plus **ADR** tracking — and explicitly *not* a status file.

A follow-up grillkit session settled the shape below.

**Success:** during normal design/build flow, when a domain term crystallizes or a hard-to-reverse trade-off decision is settled, `domainkit` auto-fires, offers to record it, and — on consent — writes the glossary entry or ADR in the right place and format. The owner never runs it by hand; the domain model stays current as a consented byproduct of existing work.

## Design decisions (settled)

Locked in a grillkit session:

| Decision | Resolution |
|----------|-----------|
| **Core job** | **Scribe of the domain model.** Detect the moment (a term needs pinning down / a decision meets the ADR bar) → **offer** → write on consent. Maintains both artifacts; one skill, two artifacts. |
| **Two artifacts, one skill** | Glossary = *what terms mean*; ADR = *why a decision was made*. Same moment (design/decision time), same `docs/`-adjacent memory space — bundled, not split into two skills. |
| **`CONTEXT.md` = glossary** | DDD domain glossary, upstream's format: header (context name + 1–2 sentence description) → terms grouped by optional subheading, each with a tight *what-it-is* definition and an `_Avoid_` synonym list. **No token/char cap** (a glossary grows with the domain; you never evict terms). Forbids general programming concepts. Be opinionated — pick one canonical term. Multi-context projects get a `CONTEXT-MAP.md` at root pointing to per-context files. |
| **ADR = `docs/adr/NNNN-slug.md`** | Upstream's format verbatim: sequential zero-padded numbering (scan `docs/adr/` for the highest, increment); minimal by default (title + 1–3 sentence *context/decision/why*); optional `Status` (`proposed \| accepted \| deprecated \| superseded by ADR-NNNN`), `Considered Options`, `Consequences`. ADRs are **immutable** — reverse by writing a new one that supersedes. Directory created only when the first ADR is needed. |
| **ADR trigger (three-part bar)** | Write an ADR only when **all three** hold: hard-to-reverse, surprising-without-context, and a genuine trade-off among real alternatives. |
| **Invocation** | **Model-invoked** — the `description` triggers on "a domain term crystallized" / "a hard-to-reverse trade-off decision was settled," so it auto-fires *inside* grillkit / plankit / implementkit flow. **Never run by hand.** |
| **Consent gate** | Both writes are consent-gated: detect → offer ("record this term / write an ADR?") → write only on yes. Never writes unprompted. |
| **Lean scribe, not interrogator** | domainkit stays lean: detect, offer, write, keep the format right. The hard questioning — challenge terms, stress-test with edge cases, reconcile code with stated behavior — is **grillkit's** job. domainkit leans on grillkit; it does not duplicate the interrogation. |
| **Wiring** | A one-line **soft nudge** in grillkit / plankit prose ("new terms or a settled trade-off decision → domainkit records them"). The glossary/ADR **format lives only in domainkit** — never copied into host skills (DRY + portability). |
| **No `statuskit` / `status.md`** | Deliberately not built. Project status stays **ambient**: issuekit / GitHub issues (forward-looking), git + session history (backward-looking), handoffkit (on-demand compaction). A hand-maintained status file rots; glossary + ADR are worth persisting precisely because they capture reasoning/vocabulary *not* recoverable from issues or git. |
| **Name** | `domainkit` — functional word leads, `kit` appended (per AGENTS.md). Chosen over `contextkit` because the skill owns more than the file (glossary **and** ADRs **and** the modeling role). |
| **Visibility** | **Public** (`internal: false`) — portable, self-contained: format inlined, no repo-relative links, no `make`/`AGENTS.md` dependency. |
| **Provenance** | "My version of" the mattpocock `domain-modeling` upstream — authored from scratch to these conventions, keeping the glossary + ADR formats and the scribe role, dropping any token-cap idea and deferring interrogation to grillkit. |

## Approach

Single lean `SKILL.md`. Upstream ships satellite `CONTEXT-FORMAT.md` / `ADR-FORMAT.md` files; here the formats are compact enough to **inline** into the skill body (keeps it self-contained and portable — no repo-relative satellite dependency).

### Phase 1 — Frontmatter + triggers
- `name: domainkit`, `metadata.internal: false`, `license: MIT`.
- **Do not** set `disable-model-invocation` — model-invocation is the whole point; the skill must be free to auto-fire.
- `description`: front-load "Maintain a project's domain model — a `CONTEXT.md` glossary and `docs/adr/` decision records — as a consented byproduct of design work." Then a pushy **"Use when …"** clause naming the triggers: "a domain term needs pinning down / crystallizes," "a term is used inconsistently," "a hard-to-reverse trade-off decision is settled," "record an architectural decision / write an ADR," "update the glossary / ubiquitous language," "another skill needs to maintain the domain model," "/domainkit."
- `allowed-tools`: `Read, Write, Edit, Glob` (read existing artifacts, scan `docs/adr/` for the next number, write/append). Keep minimal.

### Phase 2 — Body: identity + when it fires
- One-paragraph statement of the job: **scribe of the domain model** — detect → offer → write; maintains glossary + ADRs; auto-fires in-flow.
- The two things it is **not**: not the interrogator (that's grillkit — domainkit defers the hard questioning), and not a status tracker (status is ambient via issues/git/handoffkit; there is deliberately no `status.md`).

### Phase 3 — Procedure
1. **Detect the moment** — a term is vague/overloaded/conflicting, or a settled decision meets the three-part ADR bar. In-flow, this fires while grilling/planning/implementing.
2. **Locate existing artifacts** — read `CONTEXT.md` (or `CONTEXT-MAP.md` → the right context file); `Glob docs/adr/` for the highest number.
3. **Offer** — surface the proposed glossary entry or ADR and ask before writing (consent gate).
4. **Write on consent** — glossary: add/adjust the term in place, keep it a pure glossary (no specs/implementation), be opinionated about the canonical term. ADR: create `docs/adr/NNNN-slug.md` (next number, zero-padded), minimal by default, optional sections only when they add value.
5. **Defer interrogation** — if the term/decision is genuinely unsettled, hand back to grillkit rather than guessing; domainkit records settled understanding, it doesn't manufacture it.

### Phase 4 — Inlined formats
- **CONTEXT.md (glossary)** — header + terms (definition + `_Avoid_`), single-vs-multi context (`CONTEXT-MAP.md`), allowed/forbidden content, definition style, opinionated tone. No cap.
- **ADR** — `docs/adr/NNNN-slug.md`, numbering rule, minimal structure, optional `Status`/`Considered Options`/`Consequences`, immutability + supersession, the three-part write bar.

### Phase 5 — Degradation
- **No filesystem** → print the proposed glossary entry / ADR as a codeblock instead of writing (portable, environment-degrading per AGENTS.md).
- **Never write unprompted** — the consent gate holds even when auto-fired.

### Phase 6 — Wire-up (repo housekeeping)
- Add a one-line soft nudge to grillkit and plankit prose pointing at domainkit (no format duplication).
- Add row to README skills table (public).
- Add to `skills.sh.json` in the fitting group (create one if none fits — likely alongside the plan/decision workflow skills).
- Remove nothing from IDEAS.md — `domainkit` was not a backlogged row (it originated here); if a row is later added, drop it on ship per the backlog rules.
- `make lint name=domainkit` clean; live-test in a fresh session (confirm it auto-fires on a term/decision moment and stays silent otherwise).

## Open questions

- **Auto-fire tuning** — the risk with a model-invoked scribe is over-firing (nagging on every noun) or under-firing (never noticing). Lean: bias the `description` and procedure toward *high-bar* moments (a term is genuinely conflicting/overloaded; a decision genuinely meets all three ADR criteria), and always keep the consent gate so a mis-fire costs one dismissible offer, not a spurious write.
- **Multi-context threshold** — when does a project graduate from a single root `CONTEXT.md` to `CONTEXT-MAP.md` + per-context files? Lean: follow upstream — stay single-file until bounded contexts clearly diverge, then split lazily.

## Non-goals

- **No interrogation** — challenging terms and stress-testing decisions is grillkit's job; domainkit records the settled result.
- **No status tracking** — no `status.md`, no `statuskit`; status stays ambient via issuekit + git/session history + handoffkit.
- **No token/char cap on `CONTEXT.md`** — a glossary grows with the domain; capping would evict real terms.
- **No implementation or planning** — it scribes the domain model; it doesn't write app code (implementkit) or plans (plankit).
- **No separate ADR skill** — glossary and ADR live in the one `domainkit`; they are not split.
- **No satellite files** — the formats are inlined to keep the public skill self-contained and portable.
