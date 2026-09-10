# Plan: namekit

Grilled: 2026-08-21

## Context

Naming a project is a decision made once, badly, under time pressure. The owner already has a house convention that solves half of it: a common word plus the `aloy` suffix, as in `codealoy` (programming learning in Bangla), `growaloy` (AI growth platform for SMBs), and `saasaloy` (modular SaaS boilerplate). The convention is settled. What is missing is the part that runs every time. Mining the right root word out of a project description, judging how that root sits against the suffix, and finding out whether the name is already taken before anyone falls in love with it.

That work is mechanical enough to hand to an agent and creative enough that the agent needs a rubric, which is what makes it a skill rather than a note in `CLAUDE.md`. Left to itself a model returns ten variations of one idea and never checks whether any of them are free.

Success means one run turns "AI growth platform for SMBs" into a ranked shortlist of names that are actually available, each carrying a reason, with one crowned.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Skill name | `namekit`. Functional word leads so `name` stays searchable. `brandkit` collides with the design-tool sense of "brand kit"; `aloykit` buries the functional term. |
| Scope | A convention engine, not an `aloy` hardcoder. The skill takes a naming convention and generates against it. |
| Worked examples | `aloy` (suffix) and one generic prefix convention. **Not `kit`.** `skillkit` already teaches the `kit` rule inline, and one meaning lives in one place. |
| Convention resolution | Prompt-first ladder: stated convention → example names in the prompt → the user's own repos on request → ask. No config file, no environment variable. |
| Interview | Always runs. Adaptive from a fixed six-item pool, asking only the gaps the description leaves, capped at five questions in one round. |
| Visibility | `metadata.internal: false` (public). Conventions inlined, no repo-relative links, no dependency on `make` or `AGENTS.md`. |
| Modes | Two: `generate` (description → shortlist) and `check` (names you already have → verdict). `check` earns its description branch because it runs standalone on names namekit never produced. |
| Seam rule | Stated generally in three cases: hard join, elision on overlap, reject on vowel pileup. The cases are about the letters at the join, so a prefix convention hits the same three. |
| Availability probes | `curl` and `gh` only: RDAP for domain registration, the npm registry for the package name, the GitHub API for the org handle. Verified working. |
| Availability verdict | A **hard filter**, not a rubric criterion. A candidate that fails a probe leaves the shortlist. |
| Owner exception | A namespace owned by the user passes the filter and reads *yours*. Without it, `codealoy` fails its own filter. |
| Empty shortlist | Regenerate once with the taken roots excluded, capped at two generation passes total, then report survivors plus the two best rejects with their conflict named. |
| Web search | Runs on the crowned name only, after filtering. A hit re-crowns the runner-up and says why. |
| Non-English roots | In scope, gated on one test: a root passes only when one Latin transliteration dominates in common use. An ambiguous spelling drops rather than scoring low. |
| Output | A ranked shortlist in chat with one crowned pick. `docs/names/names-<slug>-YYYY-MM-DD.md` on request only. |
| Group | `skills.sh.json` → "Planning & Design", beside `validatekit` and `plankit`. |

## Approach

### What it reuses

- **`skillkit`'s convention-engine shape.** It resolves a naming rule, falls back to a documented default, and proposes candidates for the user to pick from. namekit is the same move aimed at projects, so the structure is proven rather than invented. The two skills stay separate: skillkit owns `kit`, namekit owns everything else.
- **`ideakit`'s hand-off posture.** A name often arrives during idea work. namekit routes to `ideakit` and `repokit` and never writes into their state.
- **The collection's `Hand off` contract, frontmatter template, and artifact-naming rule**, inlined as every public skill inlines them.
- **The probe commands verified during planning**, so the skill ships commands known to work rather than plausible ones.

### Phase 1: Scaffold and trigger surface

Create `skills/namekit/SKILL.md` with the frontmatter template: `name: namekit`, `license: MIT`, `metadata.internal: false`, and `allowed-tools: Read, Write, Bash, AskUserQuestion, WebSearch, WebFetch`. Both `Bash` and `AskUserQuestion` are load-bearing. The probes are shell calls and the interview runs every generate.

Write the `description` as a context pointer with one trigger per branch. Two branches only: generate a name, and check a name. Candidate triggers: "name this project", "what should I call this", "give me project name ideas", "come up with a name for X", "is <name> taken", "check if this name is available", "/namekit".

**Done when** the frontmatter matches the template exactly, the directory name equals `name`, and both modes carry a trigger phrase.

### Phase 2: Interview and generation

**Restate first.** Reflect the project description back in one sentence before asking anything, so a misread surfaces before generation rather than after a shortlist.

**Then interview, always, from a fixed pool of six.** Ask only the items the description leaves open, capped at five, in a single round: what it does · who it is for and what language they read · tone · words to include or avoid · where the name gets typed (domain, package, CLI command, org) · how permanent it is. The typed-surface item earns its slot because it sets the length tolerance and decides which probes run in Phase 3.

**Resolve the convention on the prompt-first ladder.** Take it from an explicit statement, else derive it from example names the user gives ("like codealoy, growaloy"), else read it from the user's own repos when they point at them, else ask. Record the resolved convention in the output so a wrong read costs one correcting line.

**Mine roots from four sources**, so the candidate set is genuinely plural rather than one idea in ten hats: the domain noun (`code`, `saas`), the outcome verb (`grow`, `ship`, `learn`), the user or the material they work on (`dev`, `shop`, `desk`), and the metaphor or non-English root when the interview named a non-English audience. A non-English root passes only the one-transliteration gate: one Latin spelling dominates in common use, or the root drops.

**Apply the seam rule, stated in three cases.** A **hard join** where the root's tail and the affix's head do not collide (`code` + `aloy` → `codealoy`). An **elision** where they overlap (`data` + `aloy` → `dataloy`, not `dataaloy`). A **reject** where the seam makes a vowel pileup or a syllable nobody says aloud. Show `aloy` under each case and one prefix convention alongside it, so the generality is demonstrated rather than asserted.

**Score against a fixed rubric** so ranking is reproducible: semantic fit, sound (three to four syllables, reads on first sight), seam quality, and spell-on-hearing. Availability is not on this rubric; it is a filter, and it runs next.

Generate wide, meaning enough raw candidates that a shortlist survives Phase 3's filter. The starting figure is 25 or more raw, cut to a ranked 12 before probing.

**Done when** the shortlist draws roots from at least three of the four sources and every surviving candidate carries a one-line rationale and a rubric verdict.

### Phase 3: The availability filter

Three probes, all verified during planning, run over the ranked 12:

- **Domain registration** — `curl -s -o /dev/null -w '%{http_code}' -L https://rdap.org/domain/<name>.com`, where `404` means not registered and `200` means registered. Check `.com` plus one TLD the interview's typed-surface answer implies.
- **npm package** — `curl -s -o /dev/null -w '%{http_code}' https://registry.npmjs.org/<name>`, where `404` means free.
- **GitHub handle** — `gh api /users/<name>`, where a 404 means the org or user name is free.

**Any hit removes the candidate**, with one exception. Resolve the user's own owner from the git remote when a repo exists, and from the convention-source repos otherwise. A namespace that resolves to that owner passes and is labelled *yours*, which is what keeps the filter from rejecting the user's own portfolio.

When the filter leaves fewer than three survivors, run Phase 2 once more with the taken roots excluded and probe again. Two generation passes is the cap. Then report what survived alongside the two best rejects, each with the probe that killed it named, because "growaloy is gone, and here is who holds it" is useful output.

Report each result as the probe's own claim. A 404 from RDAP means not registered, never buyable for twelve dollars. When the network or `gh` is unavailable, say the sweep was skipped, drop the filter, and rank on the four rubric criteria alone.

`check` mode is this phase run alone on names the user supplies, with no generation and no filtering, since there is nothing to filter down to.

**Done when** every reported candidate carries all three probe results or an explicit skipped-sweep note, no line implies a domain is purchasable, and the empty-shortlist path has been exercised at least once.

### Phase 4: Crown, search, and hand off

Crown the top survivor, then run one web search on that name alone to catch the existing product or live trademark the registries miss. A hit re-crowns the runner-up and states the conflict. This is the only search in the run.

Print the shortlist as a ranked table: name, root and its source, seam case, rubric verdict, and the three probe results. Give the crowned name a one-sentence reason. Write `docs/names/names-<slug>-YYYY-MM-DD.md` only when asked, inlining the artifact-naming rule since the skill is public. With no filesystem, print the artifact as a codeblock and give the filename.

Write the `## Hand off` section in the procedural register with the three beats. Crown one next move: `repokit` to set the new repo's description and topics when installed, otherwise `gh repo create`. Name `ideakit` as the runner-up when the name came out of an idea session.

**Done when** the closing section is titled `## Hand off`, names exactly one crowned next move with a plain fallback beside each sibling kit, and the crowned name has been searched.

### Phase 5: Repo integration

Six surfaces, all of which `make lint` checks:

1. `README.md` skills table — one row, visibility `public`.
2. `skills.sh.json` — add `namekit` to the "Planning & Design" group.
3. `docs/wiki/skills/namekit.md` — one-line description, bold "Reach for it when", the summary table (modes · tools · writes · visibility), a `### \`generate\`` and a `### \`check\`` section under `## Modes`, the source link, the install command, and the provenance stamp.
4. `docs/wiki/.wikimap.yaml` — `path: skills/namekit.md`, `mode: reference`, `documents: [skills/namekit/SKILL.md]`.
5. `docs/wiki/index.md` — link the page under "Planning & Design".
6. `make lint` — run it, fix every error, address the warnings.

Then live-test with `make link namekit` in a fresh session: three realistic phrasings that should trigger and one near-miss that should not, one full `generate` against a real project description, one `check` on a name you already own to prove the owner exception fires, and one `generate` on a saturated root to force the empty-shortlist path. Run `make unlink namekit` afterwards.

**Done when** `make lint` is clean, all six surfaces name `namekit`, and the four live-test runs above have each produced their expected path.

## Open questions

These are settled at the live test rather than by more discussion.

- **Is 25 raw candidates the right width?** It is a guess sized to survive a hard filter. Too few empties the shortlist and burns the second pass every run; too many wastes tokens before probing.
- **Is the six-item interview pool the right six?** "How permanent it is" is the weakest member and may never change a name.
- **Does `check`'s description branch earn its context load?** It fires only when the user already has a name. If a month of use never triggers it standalone, fold it into `generate`.

## Non-goals

- Logos, taglines, color, positioning, and brand identity. namekit names the thing and stops.
- Teaching the `kit` convention. `skillkit` owns that, and namekit points at no other skill to get it.
- Buying a domain, publishing an npm package, or creating the GitHub org. The skill reports what it probed and hands the purchase decision back.
- Social handle availability. Headless checks against X and the rest are rate-limited and return false negatives, which is worse than no answer.
- Renaming an existing codebase. No identifier rewriting, no migration path, no code changes.
- A config file or environment variable for the convention. The convention lives in the prompt or in the user's existing names.
