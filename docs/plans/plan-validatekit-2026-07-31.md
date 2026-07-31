# Plan — validatekit

_Created 2026-07-31._
_Grilled: 2026-07-31_

## Context

The kit collection covers everything from a rough idea forward — `plankit → grillkit → issuekit → implementkit → prkit → commitkit` — but every one of those kits assumes the thing is **worth building**. Nothing in the collection asks the prior question: *should this exist at all, and what evidence says so?* plankit is generative by design (it drafts a coherent plan from a rough idea); grillkit interrogates **decisions inside a plan**, not the commercial premise underneath it. A founder with a SaaS idea and zero demand evidence can run the entire chain and ship a beautifully-planned product nobody wants.

**validatekit** is that missing front gate. It runs an adversarial diagnostic on a business idea, grades the evidence the founder can actually produce under questioning, renders a **verdict**, names the **narrowest testable wedge**, and hands off to plankit for the *how*. It writes no code and no plan.

The design is adapted from Garry Tan's `office-hours` skill (gstack), studied in full during the grill. That skill is ~1,700 lines, of which ~870 are host-specific preamble (telemetry, brain cache, update checks, question-tuning hooks, binary setup) and a further large fraction is local-JSON state and a YC recruiting funnel. What survives here is the **diagnostic core**: the forcing questions, the anti-sycophancy discipline, the pushback patterns, the premise challenge, and the one-question-at-a-time rhythm.

**Boundary with plankit and grillkit (settled, load-bearing):**

- **validatekit** answers *"is there evidence anyone wants this, and what's the smallest thing worth testing?"* — commercial premise, upstream of everything.
- **plankit** answers *"what are we building and in what order?"* — generative, produces the plan doc.
- **grillkit** answers *"which decisions in this plan are still soft?"* — adversarial, but about **design decisions**, not market evidence.

validatekit stops at the verdict. It never generates implementation approaches and never writes a plan document — that is plankit's job, and duplicating it would make agent triggering ambiguous between two skills that both "help me think through an idea."

**Portability is a hard requirement, not a nice-to-have.** The primary target is a web chat session — Claude web, ChatGPT web, Claude Code web — where there is no repo, no `docs/` tree, often no shell, and sometimes no web search. Every phase must degrade cleanly to plain conversation. No preamble, no setup step, no persisted state, no bundled scripts.

**Success:** a founder describes a SaaS idea, answers three to four uncomfortable questions, and walks away with an honest verdict grounded in their own words, a named wedge they could test this week, one concrete real-world assignment, and — only if they ask for it — a file. It works identically in a bare chat window and in a full repo.

## Design decisions (settled)

Settled with the user across a single grillkit session on 2026-07-31.

| Decision | Resolution |
|----------|-----------|
| **Name** | `validatekit` — functional word ("validate") leads, `kit` appended, per the kit convention. Searched clean: no product, repo, or trademark found. Rejected `saaskit` (collides with saaskit.live, SaaSykit, and the entire "SaaS starter kit" genre — same collision class as shipkit, and it parses as "a kit for building SaaS," the opposite of a skill that may tell you not to build), `ideakit` (ideakit.app is an active AI startup-idea tool — direct-adjacent competitor), `pmfkit` (acronym, weak for plain-English search). |
| **Scope** | **Validation only.** office-hours' "builder mode" (hackathon, learning, open source, fun) is deliberately **not** ported — it is generative riffing, which is plankit's job. Kept from it: a **single-line off-ramp** — if the user signals this is a side project rather than a business, say so plainly and point at plankit instead of running the adversarial diagnostic on a weekend hack. |
| **Seam** | Ends at **verdict + wedge + one assignment**, then hands to plankit. Never generates implementation approaches, never writes a plan doc. |
| **Verdict basis** | The **verdict state** grades **the founder's evidence**, never the market. This stays load-bearing: it makes the state defensible (the skill cannot be wrong about a market it never claims to know), it prevents confident AI market-opinion — the failure mode that makes validation tools untrustworthy — and it means the state is identical with or without web search. The skill *does* render a market opinion, in a separate labeled section; see **Market research** below. |
| **Verdict shape** | Per-question grade (**evidenced / asserted / absent**) rendered as a table, then one of three states: **Validated**, **Unproven**, **Contradicted**. The table is what stops the verdict being a vibe — the founder can point at the empty cell. Rejected: prose-only (leaves "Unproven" contestable, no visible target to fix) and a readiness score out of 10 (fake precision; no principled weighting of demand evidence against buyer access, and founders optimize the number instead of talking to a customer). |
| **Question set** | office-hours' **six forcing questions adapted for SaaS, plus a seventh on buyer and budget** — who controls spend, and have they named a number. office-hours' Q3 asks who *feels* the pain; in B2B SaaS the person who loves the tool routinely cannot authorize the purchase, and that gap kills more deals than weak demand does. |
| **Question routing** | **Stage-routed**, so a run asks three to four questions, never seven. Stage is established up front (pre-product / has users, not paying / has paying customers). |
| **Questioning rhythm** | **One question at a time**, always. Push past the first (polished) answer. Ported directly from office-hours — batching questions is the single fastest way to get seven shallow answers. |
| **Anti-sycophancy** | **Ported as core, not optional.** The banned-phrase list ("that's an interesting approach", "that could work", "you might want to consider…") plus the five bad/good pushback exemplars. This is the only thing standing between the skill and an LLM's default encouragement, which is precisely what makes founder feedback worthless. |
| **Premise challenge** | **Kept.** Before the verdict, state the load-bearing assumptions the idea rests on as flat claims and make the user agree or disagree with each. Fully portable, no tools needed, and it is what makes a hard verdict land — the user signed off on the premises it rests on. |
| **Signal reflection** | **Kept** — the one salvageable piece of office-hours' closing. Close with "what I noticed about how you think," quoting the user's **actual words** back rather than characterizing them ("you didn't say small businesses, you said Sarah the ops manager"). Needs no state, and it is the warmth that earns a brutal verdict. |
| **Market research** | **Kept, optional, degrades silently — and widened during authoring (2026-07-31) at the owner's direction.** Originally a narrow landscape scan feeding the premises only. Now a real market pass when search is available: incumbents and their pricing, how the category is usually solved and where it fails, public customer behavior, and category momentum. It renders a **market-fit read** (`Open` / `Crowded` / `Unclear`) as its own sourced section in the output. Category terms and named competitors are fair game; the user's own product name or an unlaunched concept is never searched without asking. **The separation is retained and is load-bearing:** market findings never move a grade in the evidence table or set the verdict state — they reshape the wedge, the assignment, and the premises, and they can be why the verdict prose is harsh. This keeps the state defensible against research that is wrong or stale, and keeps the skill's core claim honest. |
| **Second opinion** | **Optional, environment-degrading.** When a subagent is available, dispatch one on a stronger model for a cold read. Otherwise emit a **copy-pasteable prompt block** the user drops into a fresh session with a different model or tool. Framed as a named fallback, never as "unavailable, skipped." |
| **Artifact** | **Verdict lands in chat. File is offered afterward, never written unprompted** — the common case is a web session with no `docs/` tree. When wanted: `docs/validation/validation-<slug>-YYYY-MM-DD.md`, carrying a `Validated: <state> — YYYY-MM-DD` stamp for downstream provenance (same pattern grillkit's `Grilled:` stamp already established). |
| **Escape hatch** | **Kept, graduated.** On "just tell me if it's good," push back once, ask the two highest-value remaining questions for the stage, then proceed. Respect a second refusal — no third ask. A verdict on a partial diagnostic must say so. |
| **Codebase research** | **Cut.** office-hours Phase 1 reads `CLAUDE.md`, runs `git log`, and greps the repo. At idea stage there is usually no repo, and the commercial premise does not live in code. |
| **Visibility** | **Public** (`internal: false`) — self-contained, no repo-relative links, no `make`/`AGENTS.md` dependency, degrades to chat output with no filesystem. |
| **Layout** | Single flat `skills/validatekit/SKILL.md`. No satellite files (office-hours used a `sections/` split; this skill is small enough not to need one) and no bundled scripts. |

### Explicitly cut from office-hours

Recorded so the omissions read as decisions rather than oversights: the ~870-line preamble in full; all local JSON state (builder profile, learnings log, decision log, telemetry, analytics); the codebase research phase; related-design discovery by filesystem grep; the mandatory 2–3 implementation approaches and the design-doc templates (plankit's job); the adversarial doc review loop; visual mockups, wireframes, and the `browse`/`design` binaries; and the whole of Phase 6 — session-count tiers, the signed Garry Tan plea, the 34-link resource pool, and the `ycombinator.com/apply` handoff.

## Approach

### Phase 1 — Frontmatter + triggers

- `name: validatekit`, `license: MIT`, `metadata.internal: false`.
- `allowed-tools: Read, Write, AskUserQuestion, WebSearch` — Write only for the optional artifact; no Edit, no Bash.
- `description`: front-load what it does, then a pushy **"Use when …"** clause naming the real phrasings: "validate my idea", "is this worth building", "should I build this", "pressure-test my startup idea", "will anyone pay for this", "/validatekit". Must also fire proactively when a user describes a new product idea and asks whether it's worth building.

### Phase 2 — Body: identity + boundary

One paragraph on the job: adversarial evidence diagnostic → verdict → wedge → assignment → hand to plankit. Then state what it is **not**, explicitly:

- **Not a planner** — it never writes a plan or generates implementation approaches (plankit).
- **Not a market oracle** — it grades the founder's evidence, never predicts whether the business works.
- **Not for side projects** — the one-line off-ramp lives here.

This paragraph is what keeps the plankit overlap from creeping back.

### Phase 3 — Frame and route

1. **Reflect the idea back** in your own words before questioning, so a misread surfaces immediately.
2. **Off-ramp check** — if this is a side project, hackathon, or learning exercise rather than a business, say so and point at plankit. One line, no ceremony.
3. **Establish stage** — pre-product (idea, no users) / has users, not paying / has paying customers. This selects the question set.

### Phase 4 — The seven forcing questions

Asked **one at a time**, pushing past the first answer. Each carries: the question, what a satisfying answer sounds like, and the red flags that mean push again.

| # | Question | Probes |
|---|----------|--------|
| Q1 | **Demand reality** — strongest evidence someone would be genuinely upset if this vanished tomorrow? Not "interested," not a waitlist | Behavior over sentiment |
| Q2 | **Status quo** — what are they doing right now to solve this, even badly, and what does the workaround cost? | Real pain, and its price |
| Q3 | **Desperate specificity** — name the actual human. Title, what gets them promoted, what gets them fired | A person, not a category |
| Q4 | **Buyer and budget** *(new)* — who controls the spend, and have they named a number? | Buyer-vs-user gap |
| Q5 | **Narrowest wedge** — smallest version someone pays real money for this week, not after the platform | Value over architecture |
| Q6 | **Observation and surprise** — have you watched someone use it without helping, and what surprised you? | Assumptions vs reality |
| Q7 | **Future-fit** — if the world looks different in three years, does this get more essential or less? | A thesis, not a tailwind |

**Stage routing** (three to four questions per run):

- **Pre-product** → Q1, Q2, Q3, Q4
- **Has users, not paying** → Q4, Q5, Q6 — "users but no revenue" is precisely the buyer-access failure
- **Has paying customers** → Q5, Q6, Q7

**Smart-skip:** if an earlier answer already covers a later question, skip it. Only ask what is genuinely unclear.

### Phase 5 — Posture: anti-sycophancy and pushback

Ported from office-hours, adapted. Two components:

- **Banned phrases during the diagnostic** — "that's an interesting approach," "there are many ways to think about this," "you might want to consider…," "that could work," "I can see why you'd think that." Replace each with a position plus the evidence that would change it.
- **Five pushback patterns** as bad/good exemplar pairs — vague market → force specificity; social proof → demand test; platform vision → wedge challenge; growth stats → vision test; undefined terms → precision demand. The exemplar contrast is the mechanism; a rule alone does not survive contact with an LLM's helpfulness prior.

Plus: **calibrated acknowledgment, not praise.** When an answer is genuinely specific, name what was good in one clause and immediately ask a harder question.

### Phase 6 — Landscape scan (optional)

Search generalized category terms for how this space is usually approached and where the conventional approach fails. Never the user's product name or stealth concept. Feeds Phase 7's premises. Skipped silently when search is unavailable — and its findings never enter the verdict, which grades evidence only.

### Phase 7 — Premise challenge

State the load-bearing assumptions the idea rests on as flat claims, and get an explicit agree/disagree on each:

```
PREMISES
1. <claim> — agree / disagree?
2. <claim> — agree / disagree?
```

On disagreement, revise and re-state. This gate is what gives the verdict its footing.

### Phase 8 — Second opinion (optional)

Offer, don't impose. Two paths, chosen by environment:

- **Subagent available** → dispatch a fresh-context cold read on a stronger model: steelman the idea, name the one answer that reveals the most, challenge one agreed premise, name the cheapest test.
- **No subagent** → emit a **self-contained, copy-pasteable prompt block** carrying the session summary, the graded evidence, and the premises, for the user to paste into a different model or tool. Present it as a first-class option, not a consolation prize.

### Phase 9 — Verdict

Render the evidence table, then the state, then the wedge and the assignment:

```markdown
## Evidence

| Dimension | Grade | What you said |
|-----------|-------|---------------|
| Demand reality | evidenced / asserted / absent | <their words, quoted> |
| …

## Verdict — <Validated | Unproven | Contradicted>

<two or three sentences, grounded in quoted answers, never in market opinion>

## Narrowest wedge
<the smallest testable thing>

## The assignment
<one concrete real-world action — not "go build it">

## What I noticed about how you think
<2–4 bullets quoting their actual words back>
```

The three states:

- **Validated** — evidence clears the bar for this stage. Build the wedge.
- **Unproven** — interest, not evidence. **Not a no; an unfinished test.** Every `absent` or `asserted` row names the cheapest experiment that would close it.
- **Contradicted** — the founder's own answers undercut the idea: nobody works around the problem today, nobody can authorize spend, the wedge requires the entire platform. The strongest thing the skill can say, and still grounded in their words rather than the model's market read.

### Phase 10 — Offer the artifact, then hand off

1. Ask whether they want this written to a file. **Only on yes**, write `docs/validation/validation-<slug>-YYYY-MM-DD.md` with the `Validated: <state> — YYYY-MM-DD` stamp near the top; create the directory if needed; keep the creation date stable on later edits and update in place.
2. No writable filesystem → say so and leave the verdict in chat.
3. Hand off by relevance, naming a sibling kit only when installed and otherwise describing the action plainly:
   - **Validated** → plankit, to turn the wedge into a plan.
   - **Unproven** → the assignment. Come back after running the test.
   - **Contradicted** → the reframe worth exploring, or plankit if they want to build it anyway with eyes open.

### Phase 11 — Wire-up (repo housekeeping)

- Add `validatekit` to the **Planning & Design** group in `skills.sh.json`, positioned **ahead of plankit** (it is upstream), and widen that group's description to cover validating an idea before planning it. Required by AGENTS.md in the same change.
- Add a `validatekit` row to the README Skills table.
- **Add the inverse drift line to plankit.** Once this skill exists and is named, `skills/plankit/SKILL.md` gains one line: if planning reveals the work is an unvalidated commercial bet rather than a scoped piece of work, stop and point at validatekit. (Deferred here from the builder-mode harvest because it was blocked on this skill shipping.)
- `make lint name=validatekit` clean.
- Live-test with `make link` in a fresh session: once against a bare idea with no repo (the primary web-chat case), once inside a repo to exercise the artifact path, and once with a deliberately evidence-free idea to confirm the skill actually returns **Contradicted** instead of softening.

## Open questions

Authoring-time refinements; the load-bearing decisions are settled above.

- **Stage-routing table for seven questions** — the mapping above is a first cut. Worth re-checking that pre-product genuinely warrants four questions while the later stages get three, and that Q4 (buyer) lands in the right stages.
- **Verdict bar** — what precisely separates Validated from Unproven. Likely "no `absent` grades on the dimensions that apply at this stage," but it needs stating concretely enough that two runs on the same answers agree.
- **Wedge quality** — whether the skill should grade the wedge itself (is it genuinely shippable this week?) or merely record the founder's answer.
- **Slug derivation** for the artifact filename when the idea has no obvious short name.
- **B2C fit** — Q4 (buyer and budget) is B2B-shaped. Whether it needs a consumer variant, or a rule to skip it when the buyer and the user are the same person.

## Non-goals

- **No plan, no approaches, no code.** validatekit stops at the verdict; plankit owns the *how*. Not even a sketch of implementation options.
- **No market prediction.** It never claims to know whether a business will succeed. It grades evidence, names gaps, and proposes tests.
- **No builder mode.** Side projects, hackathons, and learning exercises get a one-line off-ramp to plankit, not a second question set.
- **No persisted state.** No session counts, no builder profile, no learnings log, no telemetry, no analytics. Every run is cold.
- **No unprompted file writes.** The artifact is offered, never assumed.
- **No recruiting funnel, no resource pool, no relationship tiers.** The entirety of office-hours' Phase 6 is out.
- **No bundled scripts, no satellite files, no setup step.** The skill is prose and must run in a browser chat window with no shell.
