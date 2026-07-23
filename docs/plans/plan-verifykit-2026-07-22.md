# Plan — verifykit (+ prkit artifact attachment)

## Context

The development workflow in [IDEAS.md](../../IDEAS.md) has a gap between `reviewkit` and `prkit`: nothing actually *drives the feature* and proves it works before the PR is opened. reviewkit reads the code; qakit writes a plan for a *human* to run; neither exercises the running feature. verifykit fills that slot — it drives a just-built frontend feature via a browser-automation MCP (or computer use), captures **screenshots + a short animated GIF** of it working, and publishes those artifacts so `prkit` can embed them in the PR as proof.

Shipping verifykit is a **two-part change**: (1) author the new `verifykit` skill, and (2) upgrade `prkit` to embed the proof artifacts in a PR — `gh` can't inline media, so it needs an upload path. The two are coupled: verifykit produces the artifacts, prkit consumes them, and both agree on a single deterministic publish mechanism.

**Success:** after a coding session, `/verifykit` drives the feature end-to-end, saves a proof bundle (screenshots + a short GIF), and `prkit` opens a PR whose body embeds that proof inline — with no manual upload step.

## Design decisions (settled)

The hosting/attachment mechanism was **prototyped end-to-end against `mimukit/skills`** — every ✅ below is a verified run, not a guess.

| Decision | Resolution |
|----------|-----------|
| Placement in the flow | Between `reviewkit` and `prkit` — after code is judged, before the PR. No-ops with a message when there's no runnable frontend surface. |
| Identity vs. the generic `verify` skill | Different scope: generic `verify` drives *any* change for the agent's own confidence; `verifykit` is **frontend proof-capture for a PR**. Keep the branded name; state the distinction in the SKILL.md. |
| Identity vs. qakit | qakit = **manual** plan a *human* runs; verifykit = **automated** drive the *agent* performs and records. No overlap; verifykit never writes a human checklist. |
| Proof format | **Screenshots + one animated GIF** (stitched via `ffmpeg`). **No mp4 for now** — a hosted mp4 won't embed inline in a PR body, so it adds cost without inline proof. Deliberate later add. |
| Capture-tool precedence | **Browser-automation MCP → computer use → none.** Detect, don't assume (no browser MCP is assumed present). With neither, degrade to printing a manual capture recipe. |
| Flow selection | **Explicit instruction** in the invocation wins. Otherwise: **one flow → drive it; multiple flows → list detected candidate flows (derived from the diff as distinct user entry points) and ask the user (multi-select) which to verify.** Each chosen flow becomes a labeled bundle section. |
| Auth / seeded state | Driver + recorder, **not a provisioner**. **Reuse existing auth** (running session / stored `storageState` / env test creds) → if the flow is gated and none is available, **ask once** for the entry URL + creds (or a seed command) → else **degrade gracefully**, capturing up to the auth boundary and noting it. Runs a seed command it's *handed*; never invents or seeds state itself. |
| **Hosting mechanism** | **Hidden git ref `refs/verify-assets/<slug>`.** ✅ Repo-owned (lives in the repo, not a personal gist/account), ✅ **zero clone bloat** (a normal `git clone` fetches only `refs/heads/*`, so the ref and its blobs are never downloaded), ✅ renders inline via **SHA-pinned `raw.githubusercontent.com` URLs** (HTTP 200, `image/png`), ✅ **no working-tree disruption** (built with git plumbing + an isolated `GIT_INDEX_FILE`). Chosen over gist (ties proof to a personal account; `gh gist create` refuses binaries) and over release/orphan-branch (Releases-tab clutter / clone bloat). |
| Ref granularity | **Per-slug ref** — `refs/verify-assets/<slug>`, slug = **issue-number when a linked issue exists, else feature-slug**. Independent refs → no push race across parallel git worktrees (no rebase-retry needed). |
| Filenames | **Prefixed with the slug** (e.g. `login-throttle-flow.gif`) — the flat ref namespace has no folders, so the prefix is the grouping. |
| Deterministic ops | Live in a **bundled `verify-assets.sh`** (`publish | list | url | delete`) that the skill *calls* — the LLM never hand-runs the fragile plumbing. Self-contained: only `git` + `gh`, so it stays portable per the public-skill rule. |
| Repo visibility requirement | Inline rendering needs a **public** repo (GitHub's image proxy can't authenticate into a private one). On a private repo, degrade with a clear message rather than embedding dead links. |
| Bundle directory | `docs/verify/verify-<slug>-YYYY-MM-DD/` (screenshots, GIF, a short `notes.md`), and it is **gitignored** — assets are published to the hidden ref, not committed to the branch. |
| Visibility / portability | Public skill (`internal: false`). Degrades gracefully when no MCP, no shell, no `gh`, or a private repo — prints instructions instead of failing. |

### Asset-size reality (measured, informs the above)

`ffmpeg`-generated samples: PNG screenshots ~80–140 KB; a capped GIF (600–800px, 2–5 fps, ~8 s) ~300–800 KB (rich-media/gradient content can balloon to multiple MB). ~0.7 MB per run. Over a repo's life this is why proof is **not** committed to git — 100+ runs would be hundreds of MB of permanent, un-GC-able, every-clone-downloads-it history. The hidden ref keeps all of it out of every clone.

## Approach

### Phase 1 — Author `verifykit`
- **1.1** Scope & sourcing: derive the feature-under-test from `git diff` + the linked plan/issue; determine the launch entry point (dev server URL / command) via `run`-style detection.
- **1.2** Flow selection: detect candidate user-entry-point flows from the diff; explicit instruction wins, one flow auto-drives, multiple flows → multi-select prompt.
- **1.3** Capture-tool detection & precedence: probe browser MCP → computer use → none; record which was used.
- **1.4** Auth handling: reuse existing session/state; ask once if gated and none; else degrade and note the boundary.
- **1.5** Drive each selected flow: walk the primary happy path, capturing a screenshot at each meaningful state and a short GIF of the full flow (`ffmpeg` stitch, capped fps/scale).
- **1.6** Write the proof bundle to `docs/verify/verify-<slug>-YYYY-MM-DD/` (gitignored): screenshots, GIF, and `notes.md` (flows driven, tool used, per-step pass/fail, environment, auth boundary if any).
- **1.7** Bundle the `verify-assets.sh` helper in the skill directory (`publish | list | url | delete`).
- **1.8** Hand off: report the bundle path and offer `prkit`. Degrade gracefully (no MCP / no shell → print the manual capture recipe).
- **1.9** Repo conventions: `kit`-suffix name, front-loaded "Use when …" description, `internal: false`, no hard-wrapped prose, portable. Author via `skillkit`.

### Phase 2 — Upgrade `prkit` to embed proof

**Decoupling correction (from implementation):** prkit is a portable public skill and must not depend on verifykit's bundled `verify-assets.sh`. So publishing stays entirely in verifykit; prkit only *reads* a manifest. verifykit (Phase 1.7) publishes the assets and writes a ready-to-embed **`docs/verify/verify-<slug>-YYYY-MM-DD/proof.md`**; prkit splices that fragment in. This is the hand-off contract.

- **2.1** After building the PR body, discover a proof bundle in `docs/verify/verify-<slug>-YYYY-MM-DD/` (slug = linked issue number, else feature slug) matching this branch/issue.
- **2.2** If its `proof.md` has published SHA-pinned URLs, splice the fragment into a **Proof** section as-is — no publish, no git plumbing in prkit.
- **2.3** Only when a bundle exists; otherwise prkit behaves exactly as today.
- **2.4** Degrade: no bundle → no Proof section; bundle with local-path `proof.md` (private repo / publish skipped) → note the local artifact paths for manual attachment rather than embedding dead links.

### Phase 3 — Wire into the collection
- **3.1** Update [IDEAS.md](../../IDEAS.md): remove the `verifykit` backlog row; add both skills' behavior to the README Skills table.
- **3.2** Update `skills.sh.json`: add `verifykit` to the fitting group (**Testing & QA** or **Git & GitHub**).
- **3.3** `make lint` passes (marker + portability); update prkit's own description if its behavior surface changed.

## Open questions

Remaining spots — authoring-time details, not blockers (the load-bearing hosting/rendering unknowns are now closed by the prototype).

- **GIF encoding caps.** Exact `ffmpeg` fps/scale/duration defaults that keep GIFs proof-grade but small (2–5 fps, ~600–800px, short clips). Tune during authoring; expose an override if needed.
- **Which capture backend to wire first.** Concretely: which browser-automation MCP (e.g. Playwright MCP) to target as the primary, and the computer-use screen-capture path as fallback — including how each takes a screenshot and drives a click.
- **Private-repo degrade behavior.** Exact message/behavior when the repo is private (skip publish + link the local bundle? offer a manual path?).
- **`notes.md` shape.** The precise structure of the per-run notes file (flows, steps, pass/fail, environment, auth boundary) so it's consistent and human-scannable.
- **Ref cleanup policy.** Whether/when old `refs/verify-assets/<slug>` refs get pruned (they don't bloat clones, but they accumulate on the remote) — leave to the user, or offer a `verify-assets.sh delete` prompt after merge.
- **mp4 later.** If/when video is added, the embedding story (GitHub only renders web-composer-uploaded video) needs its own resolution — explicitly deferred.

## Non-goals

- **Not a test writer.** verifykit drives and records; it does not write unit/integration/E2E tests (a future testkit).
- **Not a manual QA plan.** That's qakit — verifykit never emits a human checklist.
- **Not a code reviewer.** It exercises the running feature, not the source (that's reviewkit).
- **Not an environment provisioner.** It reuses/asks for auth and runs a seed command it's handed; it never creates fixtures, seeds databases, or runs migrations on its own.
- **Not backend/CLI proof.** Initial scope is *frontend* features with a visual surface; headless/API verification is out until asked for.
- **Not a general PR overhaul.** Phase 2 adds a Proof section + publish path to prkit and nothing else — prkit's existing behavior is untouched when no bundle exists.
