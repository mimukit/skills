# Plan: verifykit show mode and file split

Grilled: 2026-09-07

## Context

verifykit today has one path, and it is the expensive one. Every run costs a bundle directory, a `notes.md`, a `proof.md`, a GIF, a publish to `refs/verify-assets/<slug>`, and a `.gitignore` edit. That price is right when the output is proof a PR reader will look at. It is absurd when the question is "did the button move".

There is no cheap path, and there is no path at all for the thing a person asks for most often during a build: show me what it looks like right now. verifykit also never puts an image in front of the operator during a run. It writes a bundle and publishes a ref. Both of those serve a future PR reader, not the person in the session.

A second gap sits underneath: the capture backend precedence ranks a browser-automation MCP first and computer use second. Research on 2026-09-07 settled that the engine worth installing is a CLI browser driver that writes to disk, not an MCP server that streams an accessibility tree into context on every action. The precedence list points at the wrong thing first. That research is not filed under `docs/research/`; the grill on 2026-09-07 confirmed its conclusion (`playwright-cli`) and recorded it here.

Success means three conditions hold. A person can ask verifykit to show them a screenshot and get a path back in one cheap round. The PR-proof path still produces exactly the `proof.md` that prkit splices today. The backend precedence names the engine that is actually installed.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Mode or new skill | A mode inside verifykit. The choice between "show me" and "prove it for the PR" is one the agent routes from the verb, so it costs one description branch, not a permanent entry in the index. |
| Which skill owns it | verifykit. It already owns the backend precedence, the flow selection, the auth rule, and the driving discipline. Putting a capture loop in `uikit` or `implementkit` would be a second implementation of that material. |
| Mode names | `show`, `proof`, and `setup`. |
| File shape | Routing root plus `modes/show.md` and `modes/proof.md`, matching the shape mergekit and issuekit already use. The grill confirmed the split over an inline early exit: `proof` alone reaches the GIF, bundle, and publish steps, and the branch test in `AGENTS.md` orders a satellite on that seam. The root holds scope, flow choice, backend precedence, and auth; each satellite holds only its own drive-and-output steps. |
| Default when the invocation is ambiguous | `show`. The routing block lists the `proof` verbs explicitly (PR, proof, record, prove), so the default is the residue, not a guess. Escalating to `proof` costs one sentence. |
| Capture engine at rank one | A CLI browser driver on `PATH` that takes a URL and writes a screenshot to disk. A browser MCP drops to rank two, computer use to rank three, and the manual recipe stays the floor. |
| How the CLI is named | The category, then a probe list of one binary as the example: `playwright-cli`. The agent probes the list with `command -v`. A new driver joins the list without a rewrite. |
| Flow selection in `show` | The same rule as `proof`, stated once in the root. An explicit instruction wins, one touched flow drives without asking, several touched flows ask which to capture. |
| `show` output format | Screenshots only. No GIF. The GIF exists because a PR reader was not present; the operator is. |
| `show` output path | The system temporary directory first (`mktemp -d` on POSIX, `%TEMP%` on Windows). Fall back to `docs/verify/show-<slug>-YYYY-MM-DD/` only when no temp directory resolves; that path sits under the `docs/verify/` line `proof` already adds to `.gitignore`, so no new ignore rule. |
| `show` file naming | One directory per run, `show-<slug>-YYYY-MM-DD/`, files named `NN-<state>.png`. The slug rule is the one the root already defines. |
| `show` written record | None. The hand-off carries one caption line per path: the absolute path, then the state it shows. |
| `show` publishing | None, ever. Not optional, not behind a flag. |
| Host-specific rendering | Out of scope. `show` prints an absolute path and stops. Whether the host renders that path is the host's business. |
| Description trigger | Drop "capture proof it works" (a duplicate of "prove the UI change"). Add "show me what it looks like" and "screenshot this" for the `show` branch. The description opens as "Show a frontend change in a real browser, or prove it for a PR", so both branches lead. |
| Sibling routing | uikit `build` and implementkit each get one runner-up line after their unchanged crown, naming verifykit `show` with the plain fallback "otherwise open the app and look". implementkit's line is gated on UI work. Ships as Phase 4. |
| `setup` scope | One machine and one repo. Machine half: Node 18+, `@playwright/cli` installed globally so `playwright-cli` is on `PATH`, the workspace, a browser. Repo half: `gh auth status`, the public-repo check, the `docs/verify/` ignore line, a dry-run push probe on `refs/verify-assets/*`. No GitHub Actions file; the uploader runs locally and CI would need the bundle committed. |
| `setup` checks before it installs | Every item runs a check first and installs only on a miss. The report lists each item as present, installed, or skipped. A machine with everything present gets a report and no prompt. |
| `setup` confirmation | One `AskUserQuestion` listing every miss before any install. Global npm installs and browser downloads change the machine, and the skill is public. |
| `setup` install scope | Global (`npm install -g`), so the `show` and `proof` probe finds the binary on `PATH`. A project-local install is invisible to `command -v`. |
| Driver's bundled skills | `setup` asks once whether to run `playwright-cli install --skills -g`, default no, with the reason: a second skill on the same verbs double-triggers with verifykit. |
| `setup` completion | The checklist report plus one screenshot of `about:blank`. The screenshot is the only check that proves the browser launches. |
| No-driver floor in `show` and `proof` | Print the manual recipe, then crown verifykit `setup` as the next move. Never run `setup` inline. |
| `setup` on a private repo | Report the visibility item as skipped with the reason, state that `proof` will carry local paths, and stop. Never offer to change visibility. |
| `setup` trigger | Add "set up verifykit" and "install the browser driver" with no prune. |
| prkit contract | Unchanged. `proof` mode keeps writing `docs/verify/verify-<slug>-YYYY-MM-DD/proof.md` at the same path with the same shape. |
| `notes.md` in the `proof` bundle | Unchanged. Nothing reads it except the wiki page, and dropping it is a later cleanup, not this plan. |

## Approach

Split verifykit along the branch it already has, then add the cheap branch that is missing, then fix the precedence that points at the wrong engine, then route the two building kits to the new branch, then add a `setup` mode that readies a machine and a repo.

**What this reuses.** The mode-per-file shape comes from `skills/mergekit/` and `skills/issuekit/`, including the pointer form ``mode `close` → read [modes/close.md](modes/close.md), then follow it`` and the rule that a satellite assumes the root is loaded. The bundled `skills/verifykit/verify-assets.sh` moves with `proof` mode untouched, script and subcommands both. The scope-from-diff step, the flow-selection rule, and the auth ladder all stay as written and move up into the root.

**Rejected alternative, kept for the record.** Keep verifykit as one file and add `show` as an early-exit section. Cheaper to write and it passes lint. Rejected because an agent in `show` mode would read the whole publish machinery and be invited to build a bundle nobody asked for. The satellite is what prevents that, and preventing it is the point of the split rather than a side effect. A half split (root plus `modes/proof.md` with `show` inline) was also rejected: `AGENTS.md` fixes the mode-satellite shape at one file per mode, and lint checks that shape.

Each phase carries its own documentation edit. `AGENTS.md` requires a skill's wiki page to move in the same change as the skill, so a trailing "docs" phase would violate the rule it is trying to satisfy.

### Phase 1: rewrite the capture backend precedence (built 2026-09-07)
Independent of the split and valuable on its own. Ships alone if the later phases stall.

- Reorder the precedence in the Pick the capture backend step: CLI browser driver on `PATH`, then browser MCP, then computer use, then the manual recipe.
- Name the rank-one engine as "a CLI browser driver on `PATH` that takes a URL and writes a screenshot to disk, for example `playwright-cli`". The agent probes for each listed binary with `command -v`.
- Retire the part of the `allowed-tools` note in Notes that assumes the primary backend arrives as MCP tools with unknowable names. `Bash` covers the primary path now. Keep the caveat for the MCP fallback.
- Update `docs/wiki/skills/verifykit.md`: the How it works list, and the Tools row of the summary table.

### Phase 2: split into a routing root and `modes/proof.md` (built 2026-09-07)
Pure restructuring. No behavior change, so the diff is reviewable as a move.

- Create `skills/verifykit/modes/proof.md` holding the drive-and-capture step, the GIF, the bundle, and the publish step.
- Reduce `skills/verifykit/SKILL.md` to mode selection, When this fires, the scope-and-entry-point step, the flow-choice rule, the backend precedence from Phase 1, the auth step, and the shared Notes.
- Give `modes/proof.md` its own `Hand off` section, crowning prkit. Lint accepts a closing section in the root or in every mode file, so both mode files must carry one once Phase 3 lands.
- Keep `verify-assets.sh` at `skills/verifykit/verify-assets.sh` and fix the relative pointer to it from inside `modes/proof.md`.
- Run `make lint` and confirm the anchor, step-ref, and satellite checks pass.
- Update `docs/wiki/skills/verifykit.md`: add a `## Modes` section with a `` ### `proof` `` heading, and change the Modes row of the summary table away from "single procedure".

### Phase 3: add `show` mode (built 2026-09-07)
- Write `skills/verifykit/modes/show.md`: drive to the state, screenshot each meaningful state, print one absolute path per state, stop. No GIF, no bundle, no `notes.md`, no publish.
- Write the output path ladder into `modes/show.md`: the system temporary directory (`mktemp -d` on POSIX, `%TEMP%` on Windows), otherwise `docs/verify/show-<slug>-YYYY-MM-DD/`. Name the run directory `show-<slug>-YYYY-MM-DD/` and each file `NN-<state>.png`.
- Add the routing block and the `show` pointer to the root. Phase 5 adds the `setup` pointer later. List the `proof` verbs (PR, proof, record, prove) explicitly and make `show` the default for everything else.
- Rewrite the `description`: open with "Show a frontend change in a real browser, or prove it for a PR", drop "capture proof it works", and add "show me what it looks like" and "screenshot this".
- Add the print-the-absolute-path beat to `proof` mode's hand-off as well. Neither mode ends without telling the operator where the image is.
- Give `modes/show.md` its own `Hand off`: one caption line per path (absolute path, then the state it shows), then crown a return to the kit that was building, with escalation to `proof` as the runner-up.
- Update `docs/wiki/skills/verifykit.md`: the `` ### `show` `` heading, the opening description line, the Writes row, and the Reach for it when trigger.
- Run `make cheatsheet`, then `make lint`.
- Re-read the finished skill and re-stamp the wiki page. The stamp asserts a re-read, so it moves only after that read actually happens.

### Phase 4: route uikit and implementkit to `show` (built 2026-09-07)
Depends on Phase 3. The mode must exist before a sibling names it.

- In `skills/uikit/SKILL.md`, mode `build`, Hand off, Next: keep the crown (designkit `init` or commitkit) and add one runner-up sentence naming verifykit `show` when installed, "otherwise open the app and look".
- In `skills/implementkit/SKILL.md`, Hand off: keep the crown (commitkit or the next phase) and add the same runner-up sentence, gated on UI work. A backend build has nothing to show.
- Update `docs/wiki/skills/uikit.md` and `docs/wiki/skills/implementkit.md`: the Hands off to section of each. Re-stamp each page after a re-read.
- Run `make cheatsheet`, then `make lint`. The change touches three skills, so the single-skill page warning does not apply; each page still moves with its skill.

### Phase 5: add `setup` mode (built 2026-09-07)
Depends on Phase 1 for the engine name and on Phase 2 for the file shape. Independent of Phases 3 and 4.

- Write `skills/verifykit/modes/setup.md`. It readies one machine and one repo for `show` and `proof`. Every item runs a check first and installs only on a miss. The report lists each item as present, installed, or skipped.
- Machine half, in order: Node 18 or newer (`node --version`); `playwright-cli` on `PATH` (`command -v`), else `npm install -g @playwright/cli@latest`; the workspace (`playwright-cli install`); a browser (system Chrome, else `playwright-cli install-browser`). The unscoped `playwright-cli` npm package is deprecated, so the mode names `@playwright/cli` only.
- Before any install, list every miss in one `AskUserQuestion` and run the installs only on a yes. A machine with every item present gets the report and no prompt.
- Ask once whether to install the driver's bundled agent skills (`playwright-cli install --skills -g`). Default the answer to no and state why: a second skill on the same browser verbs double-triggers with verifykit.
- Prove the machine half with one screenshot of `about:blank` written to the temp directory, then print its absolute path.
- Repo half, in order: `gh auth status`; `verify-assets.sh check` for visibility; the `docs/verify/` line in `.gitignore`; push access to `refs/verify-assets/*` with a `git push --dry-run` that leaves no ref behind. On a private origin, mark the visibility item skipped with the reason and state that `proof` will carry local paths. Do not offer to change visibility.
- Add the `setup` pointer to the root routing block. Add the triggers "set up verifykit" and "install the browser driver" to the `description` with no prune, since this branch is new coverage.
- In the root's backend precedence, change the no-driver floor: print the manual recipe, then crown verifykit `setup` as the next move. Route, do not launch.
- Give `modes/setup.md` its own `Hand off`: the checklist report, the screenshot path, and a crowned next move of `show` on the change in hand.
- Update `docs/wiki/skills/verifykit.md` with a `` ### `setup` `` heading and the new Reach for it when trigger, then `make cheatsheet` and `make lint`. Re-stamp after a re-read.

## Resolved questions

Settled in the grill on 2026-09-07. Each row in the decisions table carries the resolution; this list records the questions the plan opened.

- Two-mode split versus one file: split. The branch test in `AGENTS.md` orders it, and the fixed mode-satellite shape rules out a half split.
- How the CLI backend is named: category plus a probe list of one, `playwright-cli`.
- Output ladder for `show`: temp first, `docs/verify/` fallback.
- Written record for `show`: none on disk, one caption line per path in the hand-off.
- Ambiguous default: `show`, with the `proof` verbs listed.
- Sibling kit edits: in scope, as Phase 4.
- `notes.md` in the `proof` bundle: unchanged, later cleanup.
- Flow selection in `show`: the root rule, no special case.
- `setup` mode, added on 2026-09-07: repo half is local readiness only, check before install on every item, one confirm for the misses, global install, ask about bundled skills, `about:blank` screenshot as the completion proof, no-driver floor routes to `setup`, private repo is a skipped item, two new triggers.

## Non-goals

- No new skill and no new directory. The index does not grow.
- No GIF, no publish, and no `refs/verify-assets` write from `show`.
- No Paseo-specific behavior, no ntfy, and no host-rendering assumption anywhere in the skill.
- No change to `prkit`, to the `proof.md` contract, to `notes.md`, or to `verify-assets.sh`.
- No MCP server dependency introduced. The MCP path stays a documented fallback.
- No change to `afkkit`, which runs its own verify probe and never calls verifykit.
- No change to the crown of any sibling hand-off. Phase 4 adds runner-up lines only.
- No GitHub Actions workflow. The uploader runs locally through `verify-assets.sh`.
- No install without a check first, and no install without a confirm.
