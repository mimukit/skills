# validatekit

Pressure-test a SaaS or startup idea before you build it — forcing questions, an honest verdict graded on evidence you can actually produce, the narrowest wedge, and one real-world assignment.

**Reach for it when** someone describes a new product idea and wants to know whether to build it.

| | |
|---|---|
| Modes | single procedure, staged by evidence level |
| Tools | `Read`, `Write`, `WebSearch`, `AskUserQuestion`, `Task`, `Agent` |
| Writes | `docs/validation/validation-<slug>-YYYY-MM-DD.md` on request only |
| Visibility | public |

## What it does

validatekit runs an adversarial evidence diagnostic on a business idea: a few uncomfortable questions asked one at a time, a grade on the evidence the founder can produce under pressure, a **verdict**, the **narrowest testable wedge**, and **one concrete assignment** in the real world.

It's the gate in front of the build. Every planning and shipping tool assumes the thing is worth building; this one asks whether anyone wants it.

## The posture

**The default failure mode of an AI asked about someone's idea is encouragement, and encouraging feedback is worthless feedback.** So the skill bans its own hedges outright:

> "That's an interesting approach." · "There are many ways to think about this." · "You might want to consider…" · "That could work."

Each dodges a position. Every one gets replaced with a stance plus the evidence that would change it.

**Push past the first answer.** The first answer is the pitch — rehearsed, smooth, optimized for the listener. The second is where reality lives.

**Calibrated acknowledgment, not praise.** A genuinely specific answer gets named in a single clause, then something harder immediately: *"That's the first real number you've given me — who else has paid it?"*

Five worked pushback patterns carry this, because a rule alone doesn't survive contact with an LLM's helpfulness prior:

| They say | Don't | Do |
|---|---|---|
| "It's for small businesses that struggle with reporting." | "That's a big market — which segment first?" | "Small businesses isn't a person. Who did you last talk to — name, title, company size?" |
| "I showed twenty people and they all said they'd use it." | "That's encouraging validation." | "Saying yes to a demo costs nothing. How many did something that cost them?" |
| "Eventually it becomes the whole workspace for X." | "That's an ambitious vision." | "Skip eventually. What's the one screen someone pays for on Monday?" |
| "The market is growing 30% a year." | "Strong tailwind." | "Markets don't buy software, people do. Why does that growth reach *you*?" |
| "It uses AI to streamline their workflow." | "Makes sense." | "Streamline what, from how long to how long? Walk me through the clicks." |

## The separation that holds it together

validatekit researches the market when it can — incumbents, pricing, what customers publicly complain about. But it **never launders that research into the evidence grade.**

The verdict grades what *the founder* can produce under questioning. The market read sits beside it as a separate, sourced, fallible section. Blend the two and the whole thing collapses into an AI opinion with a table on top.

So a market finding never moves a grade. It can reshape the wedge, redirect the assignment, sharpen a premise, and be the reason the verdict prose is harsh — but the founder can dispute the research without touching the grade, and fix the grade without arguing about the research.

## The forcing questions

Seven, selected by stage, asked **one at a time** — batching is the fastest way to get four shallow answers.

| Q | Asks | Ask again on |
|---|---|---|
| **Q1 Demand reality** | strongest evidence someone would be upset if this vanished | waitlists, surveys, "everyone loves it". Interest is not demand |
| **Q2 Status quo** | what they do about it now, and what the workaround costs | "nothing, that's the opportunity" — a problem nobody works around is usually a problem nobody has |
| **Q3 Desperate specificity** | the actual person: title, what gets them promoted, what gets them fired | a segment rather than a person; a persona invented rather than met |
| **Q4 Buyer and budget** | who controls the money, and whether they said a number out loud | only ever talking to the user when the buyer is someone else |
| **Q5 Narrowest wedge** | the smallest version someone pays for *this week* | anything needing the platform first |
| **Q6 Observation and surprise** | have they watched someone use it without helping | "nothing surprised me" — no surprise means no observation |
| **Q7 Future-fit** | does this get more essential in three years, and why doesn't the incumbent just add it | a tailwind named without a mechanism |

Stage selects the set: pre-product gets Q1–Q4; users-but-no-revenue gets Q4–Q6, because that's a buyer-access failure until proven otherwise; paying customers get Q5–Q7.

On "just tell me if it's good", it pushes back **once**, asks the two highest-value remaining questions, then proceeds — and a verdict from a partial diagnostic says it was partial.

## The verdict bar

Each dimension grades as **evidenced** (something that actually happened — a name, a number, money that moved), **asserted** (confident and plausible, but a belief rather than an observation), or **absent**.

Then the state, in precedence order:

| State | Means |
|---|---|
| **Contradicted** | at least one answer supplies evidence *against* — nobody works around it, nobody can authorize the spend, the wedge is worthless alone. The strongest thing validatekit can say |
| **Validated** | demand reality is `evidenced` and nothing asked is `absent`. Build the wedge |
| **Unproven** | everything else, and the common result. **Not a no — an unfinished test**, with the cheapest experiment named for every gap |

A Crowded market alongside `evidenced` demand is still Validated; the prose just says the wedge has to survive a specific incumbent at a specific price. An Open market never rescues an idea whose founder can't produce a single piece of evidence — **a gap in the market is not a customer.**

## Two things it won't do

- **It's not a planner.** No plan document, no implementation approaches — that's [`plankit`](./plankit.md). Crossing that line makes two skills compete for the same trigger.
- **It's not for side projects.** A hackathon build, a learning exercise, a portfolio piece gets one line — "this doesn't need validating, it needs building" — and it stops. It does not run the diagnostic on a weekend hack.

It also won't put your unlaunched product name into a search engine without asking. Category terms and named competitors are public companies; your concept isn't.

## The assignment is never a build task

Always a real-world action, doable this week: talk to this named person, ask this exact question, charge someone this number, watch one user finish the task without help.

And every run closes on **what it noticed about how you think**, quoted back in your own words — *"you didn't say small businesses, you said Sarah the ops manager who gets audited in March."* That's the warmth that makes a brutal verdict land as respect rather than dismissal.

## Hands off to

By verdict: **Validated** → [`plankit`](./plankit.md), to turn the wedge into a plan. **Unproven** → the assignment, and come back after running it. **Contradicted** → the reframe worth exploring, or plankit anyway if you want to build it with eyes open. That's a legitimate choice; it just has to be a choice.

## Install

```sh
npx skills add mimukit/skills -s validatekit
```

Source: [`skills/validatekit/SKILL.md`](../../../skills/validatekit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`1f85177` on 2026-08-16._
