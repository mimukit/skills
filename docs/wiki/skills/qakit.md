# qakit

Generate a step-by-step manual QA plan for a feature just implemented, grounded in the actual code changes.

**Reach for it when** a coding session wraps and you want to hand-test the result.

| | |
|---|---|
| Modes | single procedure |
| Tools | `Read`, `Bash`, `Write` |
| Writes | `docs/qa/NNNN-qa-<feature-slug>-YYYY-MM-DD.md` |
| Visibility | public |

## What it does

qakit turns a feature an agent just implemented into a **manual QA plan a human can actually run** — concrete steps, verification checkpoints inline, and pass/fail/skip boxes, grounded in what the code changed rather than a generic checklist.

The key word is manual. These are steps that genuinely need a human to perform and judge: click through a flow, read a screen, feel out the UX.

## Organized around setup, not around dimensions

Setup is what a manual QA pass actually costs — reseeding data, logging in, driving the app into a particular state. A plan that lists twenty tidy one-behavior cases, each restating the same six setup steps, has quietly charged the tester twenty setups for twenty observations. That's the plan getting the economics backwards.

So the unit of the plan is the **scenario**: one setup, every case that can run on top of it, one reset at the end. Cases are grouped by the starting state they need, and cases that share both a setup *and* a flow are merged into a single case with several checkpoints along the way.

Failure isolation doesn't suffer from the merge, which is the part worth internalizing: an unticked checkbox points at exactly one behavior just as precisely as a failed standalone case did — and it costs the tester nothing to reach, because they were already standing there.

A scenario is named for the state it starts from ("Fresh tenant, no data", "Existing user with 200 orders"), never for its topic ("Validation"). The name is what tells a tester whether they're already in the right state or need to reset first. Cases number within their scenario — `TC-2.3` is the third case of Scenario 2.

Ordering inside a scenario is deliberate too: read-only first, state-mutating next, destructive last. A case that deletes the record every other case depends on goes at the end, or earns a scenario of its own.

## Where setup actually lives

A single preconditions list at the top of a plan turns into a dumping ground — everything the plan might ever need, stacked up front and disconnected from the cases that need it. A tester reading case seven has no way to tell which of those preconditions still apply to them.

So setup is split by lifetime:

- **Environment** — true for the whole plan, done once: branch, build, base URL, credentials, how to get an auth token, feature flags, the launch command.
- **Scenario Setup** — only what *this* scenario needs, sitting directly above the cases that consume it.
- **Scenario Reset** — how to get back to clean, at the bottom of the scenario, run only when moving to the next one.

The standalone *Regression checks* list is gone for the same reason. Regression is still a dimension that generates cases; those cases now live in the scenario whose state they need, instead of floating in a section with no setup attached.

## The split that makes it useful

Anything an agent or script can confirm on its own — running a command and reading output, hitting an endpoint, asserting a return value — does **not** belong in the human's checklist.

qakit runs those itself and records the outcomes in an **Automated verification** section at the end of the plan. The human sees them confirmed without re-running them by hand.

So as cases are generated, each gets sorted: does confirming this *require a human*, or can a script do it? Only the human-only cases become numbered test cases.

The database is where that seam earns its keep, because a database check could plausibly land on either side. The sort isn't about who owns a terminal — the tester has one too — it's about **what produces the fact**. That a table exists, that an index is there, that the migration applied: all true before anyone touches the app, so qakit confirms them itself and the human never sees them. That clicking Place order wrote one row in `orders` and two in `order_items`: that fact doesn't exist until the tester acts, so the query belongs in their case, under the step that caused it.

Which is why a query inside a step isn't a violation of the manual-only rule. The rule bars a command as a *whole case* — copy this, read that, tick a box. A `$DB_CMD` block under step 3 is the same shape as the `curl` rule that's been there all along: the command doesn't replace the human's judgment, it supplies the evidence for it.

## The dimensions

Every dimension gets walked, and one that's genuinely irrelevant gets **said to be skipped** in the plan — so the tester knows it was considered, not forgotten:

Happy path · edge and boundary · negative and error handling · regression · security and permissions · data and state · concurrency and timing · compatibility · accessibility · performance · usability.

**Data and state reaches into the database**, whenever the diff touches a migration, a schema file, a model, or a query. That's the one dimension where the screen is an unreliable witness: a create that saves the parent row and silently skips the join row renders exactly like one that worked. So the plan asserts on rows, relations and constraints directly — the table exists after the migration, the create wrote its child rows, the delete cascaded and left no orphan, the unique index actually rejects a duplicate. A diff that touches no data layer skips the database half and says so under *Not covered*, like any other dimension. Those database rules sit in a separate `db.md` file that qakit reads only when the diff touches the data layer, so a frontend-only run doesn't carry them.

Each case is tagged with a tier carrying an emoji, so urgency reads at a glance:

- 🔴 **Critical** — must pass to ship; a failure blocks release.
- 🟡 **Normal** — a real bug, but not a blocker.
- 🟢 **Low** — polish or minor-impact edges.

A case carrying a data-integrity checkpoint gets **promoted** to the higher tier rather than having its checkpoint tagged separately. Two reasons: an orphaned row is frequently the most serious thing in a case whose visible behavior is trivial, and a second tier system living inside a case would make the glance table at the top of the plan lie about what it's summarizing.

It doesn't pad. One clear check per behavior beats ten redundant ones, and the count scales to the feature's surface area and risk. What the dimensions produce is a flat pile of candidates; grouping them into scenarios is what decides which of them end up as separate cases.

## What it runs, and what it won't

qakit writes no test code, but it does run the project's existing test, lint, and build commands. That is not a contradiction: those are checks a machine can confirm, and running them is exactly what keeps them off the human's list. Every command it runs is echoed in **Automated verification**.

Two command rules have the same shape: **inspect what exists, don't reproduce it.**

- **Never: anything that destroys or rebuilds state** — a `*:reset`, a teardown-and-rescaffold, a database drop, a `clean` that wipes a build. That includes the Setup and Reset blocks of the scenarios it just wrote: those are written for the human to run, and qakit describes them without ever performing them. It's writing a plan *about* an environment, not administering one, and a QA agent that resets state can wipe the very build the human was about to test.
- **Reuse, don't re-run: a gate already recorded green on this exact revision.** Re-running produces the same answer at full price, and it's the most common way this step becomes the most expensive one in a pipeline. "This exact revision" means the recorded result names the same HEAD sha and the same dirty state qakit recorded when it scoped the change. "Earlier this session" is not enough, because the tree can move inside one session. A result with no revision, or a different one, gets re-run.

The database adds one more limit, and it lives in qakit's data-layer file with the other database rules: **no write to the database, and no read from a host it hasn't named.** The write half follows from the first rule. The read half is less obvious and matters more: `DATABASE_URL` in a shell holds whatever the last person exported, and "read-only" is not a sufficient guard, because a `SELECT` against production is still an unauthorized read of customer data. So qakit resolves the host, says it out loud, and connects only to localhost, a loopback address, or a container service the compose file defines. Anything else waits for you to confirm. Decline, and the queries go into the plan for a human to run instead.

## Every case has the same four parts

**Goal · Steps · Result · Notes** — in that order, in every case, in every plan. No case drops one and none invents a fifth. The point of a fixed body is that a tester can jump into the middle of a plan they've never read and already know where to look.

- **Goal** is one line saying what the case *proves*, not what it does — "an expired token can't reach another tenant's orders", not "test the orders endpoint".
- **Steps** carry their own verification (below).
- **Result** is Pass, Fail or Skipped, one checkbox per line.
- **Notes** is where a failure's actual behavior or a skip's reason goes.

Every checkbox in the plan owns its own line, which is a rendering constraint rather than a style preference: `- [ ]` only becomes a *clickable* box when it starts a line. Three outcomes written side by side to save space come out as dead literal text, and a tester who can't tick a box in the previewer ends up editing raw markdown instead.

### Verification sits under the step that produces it

The obvious shape for a test case is a **Steps** list with an **Expected** list underneath it. It's also the wrong one: it asks the tester to walk five actions while holding five expectations in their head, then reconcile the two lists at the end — by which point they've forgotten which screen showed what.

Instead, each step is followed immediately by its own `- [ ]` checkpoints, so verification happens while the evidence is still on screen. A step with nothing to observe simply has no checkpoints.

### A checkbox is a decision, not a line of spec

Merging cases into checkpoints has an obvious failure mode: the assertions squeezed out of the case dimension pile up in the checkbox dimension instead, and a case comes out carrying twenty boxes. That's the merge relocating the cost rather than removing it.

So a checkpoint is defined as **one judgment the tester stops to make** — not one fact the feature asserts. The test is whether they'd plausibly tick one box and leave the next unticked. If both get settled in the same glance, it's one box.

The reason this matters isn't vertical space, it's honesty. Nobody makes seven independent judgments while scrolling a page once; they scroll, form one impression, then tick seven boxes. Granularity beyond the tester's attention doesn't buy precision, it fabricates it — and a rubber-stamped tick is worse than no tick, because it's read afterwards as evidence.

Two rules fall out of that:

- **Detail lives under a checkpoint as a plain unticked sub-list.** Knowing that the pricing table's featured plan is the thing most likely to disappear is worth writing down; it just isn't worth a tick of its own. The guidance survives at one-seventh the ticking cost.
- **A repeated pass gets one checkpoint plus whatever is new.** When the same sweep runs again in the other palette, the second browser or the next breakpoint, it never re-enumerates. `as above, in dark` is banned outright — a line with no observation of its own is a loop counter the human ticks by hand.

Failure isolation survives the collapse because **Notes** already exists, and a failing checkpoint needs a note regardless. That asymmetry is the point: cheap to run when it passes, expensive only where it fails.

### Skipped is a first-class outcome

A Pass/Fail box loses information. A case the tester couldn't run — dependency down, environment missing, out of time — comes back as a blank, indistinguishable from a case nobody reached.

So **Result** offers Pass, Fail *and* Skipped, and **Notes** carries the reason. A plan that returns with silent blanks tells the next reader nothing; one that says "skipped, staging Redis was down" tells them exactly what's still owed.

## The plan is written in one register

A tester reads a QA plan while doing something, usually against a clock, which is the exact case ASD-STE100 Simplified Technical English was designed for. So the whole plan is written in that register: one instruction per sentence, active voice, present tense, a named actor, and no word carrying a second meaning. "The app redirects to `/login`" beats "a redirect occurs" because the second one makes the tester work out who did it.

The clause that costs the most attention is **one term per thing, held for the whole plan**. If step 2 calls it the *cart*, step 9 does not call it the *basket* and a checkpoint does not call it the *order*. A tester who has to work out that three words mean one object stops trusting all three, and a plan they half-trust comes back rubber-stamped. The rule is deliberately scoped to a single plan rather than to the repo, because two different documents may reasonably name the same idea differently, and forcing a global vocabulary would erase distinctions that carry meaning elsewhere.

This is also why prose paragraphs lose to bullet sublists here. A wall of prose is fine when a reader is forming an opinion; it is friction when they are holding a browser in one hand.

## Other rules for a good case

- **Concrete and reproducible** — real values and exact steps. Not "test the login" but "enter `bad@example.com` / blank password, click Sign in".
- **Observable, not internal** — what the tester sees or measures, not state they have no way to inspect.
- **Every command gets its own `sh` block** — never inlined in prose or a table cell, never stacked. The tester copies each one with a single click. Commands that must run together chain with `&&` inside one block.
- **Every API endpoint gets a runnable `curl`** — method, full URL, every required header, and a concrete JSON body with real sample values. Copy-paste ready, no placeholders to guess at. This is the single biggest speedup in a QA pass: the tester runs the request instead of reconstructing it.
- **Every database assertion gets a runnable query**, through a `$DB_CMD` that **Environment** defines once. That variable is doing real work: qakit reads `package.json`, the `Gemfile`, the compose file and `DATABASE_URL` to find the client this project actually has, and folds any `docker compose exec` prefix into the same string. A plan that hard-codes `psql` is wrong on every Prisma project and every containerized one, and the tester discovers that on first paste. One variable, and every query block in the plan is identical everywhere.

  Two details decide whether the query proves anything. It **selects the columns the change should have written**, not `count(*)` — a count passes a write that saved the wrong email. And it **queries by an identifier the case itself created**, not a global total, so a row left behind by an earlier pass can't fail a later one. Cleanup still happens, in the scenario's Reset block, written for the human and never run by the agent.
- **Honest about gaps** — what the plan can't verify goes under *Not covered*, including any dimension deliberately skipped, rather than pretending coverage.

## The plan shape

```markdown
# QA Plan: <Feature name>

## Summary                   — what it does, what "working" means
## Environment               — once for the whole plan: build, base URL, creds, flags, $DB_CMD, launch
## Test cases at a glance    — table of TC-N.M, scenario, title, priority

## Scenario 1 — <starting state>
   **Setup**                 — once, for every case below
   ### TC-1.1 — <title>      — Goal · Steps (with inline checkpoints) · Result · Notes
   ### TC-1.2 — <title>
   **Reset**                 — before moving to Scenario 2

## Scenario 2 — <starting state>
   ...

## Automated verification (by AI agent)
## Not covered / needs human judgment
## Overall result            — pass / fail / partial verdict boxes
```

### The verdict sits at the foot

The tester works down the file case by case, so the run ends at the bottom. A verdict box near the top would make them scroll back over everything they just finished to tick it, which is how it ends up never ticked. Placing it last puts the box exactly where the attention already is.

### Nothing to transcribe

A signed-off QA plan that doesn't say which commit it covers can't be trusted a week later — but that's an argument for *recording* the build, not for handing the tester an empty table to copy a sha into.

qakit already runs `git log` to scope the plan, so it stamps the date, the exact commit, and whether the tree had uncommitted changes into the header line itself. Tester and date-run are dropped outright: in a solo or agent-assisted workflow the git author and timestamp of the commit that lands the filled-in plan already answer both, and a field that's redundant with git is a field that comes back blank.

What's left at the top is the one thing a machine genuinely can't supply — the human's overall verdict, as three boxes. A run against a different build than the stamp says so in a case's **Notes**.

## Hands off to

[`prkit`](./prkit.md), with the plan path: "open the PR with prkit and hand it `docs/qa/<file>`", so the PR's test plan links the QA plan instead of restating it. Without prkit, `gh pr create` with the path in the body. qakit reports how many scenarios and manual cases (and how many 🔴 critical) plus the automated result, and the human runs the plan in a fresh checkout, scenario by scenario, resetting only between scenarios.

It never marks a *manual* case as passed — those are yours to execute. The agent only fills the Automated verification section.

If what you actually want is new automated tests, qakit says so and stops rather than producing a manual plan for it. Tests for new work belong to [`implementkit`](./implementkit.md) in TDD mode; [`testkit`](./testkit.md) is for a codebase that has no tests at all.

## Install

```sh
npx skills add mimukit/skills -s qakit
```

Source: [`skills/qakit/SKILL.md`](../../../skills/qakit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`4e88ae7` on 2026-10-09._
