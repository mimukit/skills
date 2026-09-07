# verifykit

Show a frontend change in a real browser, or prove it for a PR with screenshots plus a short GIF, or set up the driver and publish path that both need.

**Reach for it when** a frontend change is built and you want to see it now, or want visual evidence it works before opening the PR, or a machine has no browser driver yet.

| | |
|---|---|
| Modes | `show` · `proof` · `setup` |
| Tools | `Bash`, `Read`, `Write`, `AskUserQuestion` — the CLI browser driver runs through `Bash`; a browser MCP is the host-supplied fallback |
| Writes | `show`: screenshots in the system temp directory. `proof`: `docs/verify/verify-<slug>-YYYY-MM-DD/` (gitignored), published to `refs/verify-assets/<slug>`. `setup`: one `.gitignore` line, global installs on confirm |
| Visibility | public |

## What it does

verifykit drives a just-built feature the way a user would and captures what happens. Which capture depends on who is going to look at it. When the operator is in the session, `show` writes screenshots to a temp path and prints them. When a PR reader is not present, `proof` records a GIF as well, bundles it, and publishes it so a pull request can embed it inline. `setup` installs the driver and checks the publish path so both modes have something to run on.

It sits between reviewing the code and opening the PR. A review reads the source; this **exercises the running feature**.

It is a **driver and recorder, nothing more**. It doesn't write tests (that's [`testkit`](./testkit.md)), doesn't produce a human checklist (that's [`qakit`](./qakit.md)), and doesn't provision environments beyond its own driver. If the change is backend or CLI-only with nothing to drive, it says so and stops rather than inventing a flow.

## How it works

Both capture modes share four steps before they part ways:

1. **Scope the feature** from `git diff` and the linked issue — which screens, routes, components, or flows the change touches — and find how to launch the app and reach the feature.
2. **Choose the flows.** An explicit instruction wins. One flow touched gets driven without asking. **Multiple flows touched means asking which to capture**, with several selectable — never silently guessing a "primary" flow.
3. **Pick the capture backend** by precedence: a CLI browser driver on `PATH` first (`playwright-cli`, probed with `command -v`), a browser-automation MCP second, computer use or desktop capture third. With none of them it prints a manual capture recipe, names `setup` as the next move, and stops rather than faking proof. The CLI leads because it runs from `Bash` and keeps the accessibility tree out of context on every action, which is what an MCP streams in.
4. **Handle auth** — see below.

Then the mode file takes over.

## Modes

### `show`

Screenshot the change and hand the operator a path.

The operator is present, so a GIF, a bundle, and a publish would all serve a reader who isn't there. `show` writes `NN-<state>.png` files into a `show-<slug>-YYYY-MM-DD/` directory under the system temp directory (falling back to `docs/verify/` only when no temp directory resolves), then prints one line per file: the absolute path and the state it shows. Nothing lands in the repo and no record is written; the reply is the record. It's the default when the verb is ambiguous, because it's cheap and reversible, and escalating to `proof` costs one sentence.

### `proof`

Capture screenshots and a GIF, bundle them, and publish so a PR can embed them.

This is the original verifykit path, unchanged in its outputs. The bundle and the `proof.md` contract are described below, and [`prkit`](./prkit.md) still reads the same file at the same path.

### `setup`

Ready one machine and one repo for `show` and `proof`, checking each item before installing anything.

The machine half checks Node 18+, `playwright-cli` on `PATH`, the driver workspace, and a browser, in that order. **Every item checks first and installs only on a miss**, and the misses are listed in one confirm before any install runs, because a global npm install and a browser download change a machine that may not be the author's. It then takes one screenshot of `about:blank`: the checklist proves each binary exists, and only the screenshot proves the browser launches. The repo half checks `gh auth status`, origin visibility, the `docs/verify/` ignore line, and push access via a dry run that leaves no ref behind. A private repo is one skipped item with the reason, never an offer to change visibility. It asks once about the driver's bundled agent skills and recommends no, since a second skill on the same browser verbs would double-trigger with verifykit.

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

GitHub can't inline media from `gh`, and committing proof GIFs to the branch bloats the repo's history for every clone, forever. So `proof` publishes to a **hidden git ref**, `refs/verify-assets/<slug>`.

The assets live in the repo, but a normal `git clone` never fetches that namespace — zero clone bloat — and they still render inline in a PR body via SHA-pinned `raw.githubusercontent.com` URLs. Old refs accumulate on the remote and never in anyone's clone; `verify-assets.sh delete <slug>` prunes one once its PR merges.

The fragile git plumbing lives in a bundled `verify-assets.sh` beside the skill, with `check`, `publish`, `url`, `list`, and `delete` subcommands. It's never hand-run.

**This needs a public repo.** GitHub's image proxy can't authenticate into a private one, so `check` fails there — publishing is skipped and the bundle is handed off with local paths for manual attachment, rather than embedding dead links.

## The bundle

`docs/verify/verify-<slug>-YYYY-MM-DD/` holds the screenshots, the GIF, and two fixed files:

- **`notes.md`** — flows driven, capture backend used, per-step pass/fail, environment, and any auth boundary the run stopped at.
- **`proof.md`** — the hand-off contract. A ready-to-embed Markdown fragment with the GIF and screenshots at their SHA-pinned raw URLs, captioned per flow. [`prkit`](./prkit.md) reads this and splices it straight into the pull request body, so publishing never runs twice.

The directory is **ephemeral** and belongs in `.gitignore` — the assets live on the hidden ref, not the branch.

## Hands off to

`show` hands back to whichever kit was building the change, with `proof` as the runner-up when the PR needs evidence. `proof` hands to [`prkit`](./prkit.md): the artifacts are ready for a pull request's **Proof** section, and prkit embeds `proof.md` inline. `setup` hands to `show` on the change in hand. verifykit doesn't open the PR itself, and no mode launches another.

## Install

```sh
npx skills add mimukit/skills -s verifykit
```

Source: [`skills/verifykit/SKILL.md`](../../../skills/verifykit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`327a65c` on 2026-09-07._
