# verifykit

Prove a frontend feature actually works by driving it in a real browser and capturing screenshots plus a short GIF as PR-ready proof.

**Reach for it when** a frontend change is built and you want visual evidence it works before opening the PR.

| | |
|---|---|
| Modes | single procedure |
| Tools | none declared — inherits the host's full set |
| Writes | `docs/verify/verify-<slug>-YYYY-MM-DD/` (gitignored), published to `refs/verify-assets/<slug>` |
| Visibility | public |

## What it does

verifykit drives a just-built feature the way a user would, captures what happens, and publishes that proof so a pull request can embed it inline.

It sits between reviewing the code and opening the PR. A review reads the source; this **exercises the running feature**.

It is a **driver and recorder, nothing more**. It doesn't write tests, doesn't produce a human checklist (that's [`qakit`](./qakit.md)), and doesn't provision environments. If the change is backend or CLI-only with nothing to drive, it says so and stops rather than inventing a flow.

## How it works

1. **Scope the feature** from `git diff` and the linked issue — which screens, routes, components, or flows the change touches — and find how to launch the app and reach the feature.
2. **Choose the flows.** An explicit instruction wins. One flow touched gets driven without asking. **Multiple flows touched means asking which to verify**, with several selectable — never silently guessing a "primary" flow.
3. **Pick the capture backend** by precedence: a browser-automation MCP first, computer use or desktop capture as fallback, and if neither exists it prints a manual capture recipe and stops rather than faking proof.
4. **Handle auth** — see below.
5. **Drive and capture** each flow along its happy path: a screenshot at every meaningful state (initial, mid-flow, the error and empty states the change introduces, success) plus one short GIF of the whole flow.
6. **Write the bundle.**
7. **Publish** so a PR can embed it.

## It reuses state, never manufactures it

For a gated flow, in order: reuse an already-authenticated session, a stored browser state file, or test credentials the project already exposes. Failing all three, it asks once for the entry URL and credentials, or a seed command to run.

If you can't or won't provide them, it **degrades** — capturing up to the auth boundary and noting where it stopped.

It will run a seed command you hand it. It will never invent one, seed a database, or run migrations. That's what keeps it safe against real data and portable across projects.

## The GIF is proof, not cinema

A few frames per second, modest width, a short clip. `ffmpeg` works well when present:

```sh
ffmpeg -y -framerate 2 -i frame-%02d.png -vf "scale=800:-1" flow.gif
```

A proof GIF is typically a few hundred KB; screenshots around 100 KB.

**No mp4.** A hosted mp4 doesn't embed inline in a PR body — GitHub only renders video uploaded through its web composer — so the format is screenshots plus GIF.

## Publishing without clone bloat

This is the design's most interesting move.

GitHub can't inline media from `gh`, and committing proof GIFs to the branch bloats the repo's history for every clone, forever. So verifykit publishes to a **hidden git ref**, `refs/verify-assets/<slug>`.

The assets live in the repo, but a normal `git clone` never fetches that namespace — zero clone bloat — and they still render inline in a PR body via SHA-pinned `raw.githubusercontent.com` URLs. Old refs accumulate on the remote and never in anyone's clone; `verify-assets.sh delete <slug>` prunes one once its PR merges.

The fragile git plumbing lives in a bundled `verify-assets.sh` beside the skill, with `check`, `publish`, `url`, `list`, and `delete` subcommands. It's never hand-run.

**This needs a public repo.** GitHub's image proxy can't authenticate into a private one, so `check` fails there — publishing is skipped and the bundle is handed off with local paths for manual attachment, rather than embedding dead links.

## The bundle

`docs/verify/verify-<slug>-YYYY-MM-DD/` holds the screenshots, the GIF, and two fixed files:

- **`notes.md`** — flows driven, capture backend used, per-step pass/fail, environment, and any auth boundary the run stopped at.
- **`proof.md`** — the hand-off contract. A ready-to-embed Markdown fragment with the GIF and screenshots at their SHA-pinned raw URLs, captioned per flow. [`prkit`](./prkit.md) reads this and splices it straight into the pull request body, so publishing never runs twice.

The directory is **ephemeral** and belongs in `.gitignore` — the assets live on the hidden ref, not the branch.

## Hands off to

[`prkit`](./prkit.md). The artifacts are ready for a pull request's **Proof** section, and prkit embeds `proof.md` inline. verifykit doesn't open the PR itself.

## Install

```sh
npx skills add mimukit/skills -s verifykit
```

Source: [`skills/verifykit/SKILL.md`](../../../skills/verifykit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`fd96414` on 2026-08-07._
