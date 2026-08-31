# Plan: repokit `setup` mode

Grilled: 2026-08-31

## Context

repokit today configures a repo that already runs: it writes the About panel (`about`) and provisions the workflow labels (`labels`). Neither answers the question a brand new repo poses, which is "make this thing match how I work". A fresh `gh repo create` lands on GitHub's defaults, and those defaults contradict the collection: all three merge methods stay on where mergekit merges with `--merge`, head branches survive the merge where gitkit's `clean` then has to sweep them, and the repo carries no LICENSE, no README, and no agent guide.

Today every mimukit repo shows the same untouched defaults (`sq:true mc:true rb:true del:false` across all eight sampled). There is no house convention encoded anywhere, only one repeated by hand and inconsistently. `setup` is where it gets written down once.

Success: on a new empty repo, one `setup` run leaves the merge settings, the About panel, the label vocabulary, and the baseline files all correct, with every mutation previewed first.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Scope of `setup` | GitHub repo settings, local scaffold files, and an orchestrated `about` + `labels` span. |
| Branch protection and rulesets | Out of scope. It needs admin rights and a paid plan on private repos, so it would fail on half the target repos. |
| Merge convention | Merge commit only. Enable `mergeCommitAllowed`, disable squash and rebase, so the setting matches mergekit's `gh pr merge --merge`. |
| Repo creation | Configure only. The user runs `gh repo create`; repokit keeps its existing preflight, which stops when there is no GitHub remote. |
| File layout | Split `SKILL.md` into a routing root plus `modes/about.md`, `modes/labels.md`, `modes/setup.md`. |
| License | `setup` asks which license the project takes, in both visibilities. It recommends MIT for a public repo and a proprietary all-rights-reserved file for a private one. |
| Commit and push | `setup` writes scaffold files and stages nothing beyond them. It never commits and never pushes; commitkit owns that. |
| Tool surface | Widen frontmatter to `allowed-tools: Bash, Read, Write`. The widening is `setup`'s doing; `about` and `labels` gain nothing they'd misuse. |
| Wiki toggle | One more row in the settings preview, proposed **off**. The user flips it in the same approval pass; no dedicated prompt. |
| Repos with history | Same flow, smaller diffs. Scaffold proposes only missing files; settings, `about`, and `labels` already reconcile. No second code path. |
| Open PRs vs merge-method change | No check. The settings preview already shows the change; mimukit repos run solo. |
| License holder name | `gh api user --jq .name`, falling back to `git config user.name`, always visible in the file preview before write. |

## Approach

Reuse everything repokit already carries. The preflight, the `Detect` block, the archived/fork guardrails, the preview-before-mutate stance, and the re-run-safe reconcile rule all stay in the root and serve all three modes unchanged. `setup` adds one new mutation surface (`gh repo edit` flags for settings) and one new artifact surface (scaffold files); the About and label halves are delegated, not rewritten.

### Phase 1: split repokit into a routing root plus mode satellites (built 2026-08-31)

repokit is 244 lines with three mode bodies once `setup` lands, and a run only ever walks one of them. That is the branch test in AGENTS.md, so the file splits.

- Keep in the root: frontmatter, the two-line mode summary, `When this fires` with routing, `Preflight`, `Detect`, the safety stance, `Re-run safe`, and `Notes`.
- Move `about` to `modes/about.md` and `labels` to `modes/labels.md` verbatim, dropping nothing and repeating no root material.
- Add one pointer per mode in the required form: `` mode `setup` → read [modes/setup.md](modes/setup.md), then follow it ``.
- Each satellite keeps its own `Hand off` section, which is what lint accepts for a split skill.

Done when `make lint` passes and every anchor link in the root resolves into a satellite.

### Phase 2: write `modes/setup.md` (built 2026-08-31)

The mode body, in run order.

1. **Report the repo's shape.** Read the state the root's `Detect` already fetched, plus commit count and file list, and say what you found. A repo with history runs the identical flow; the diffs just shrink, because scaffold proposes only missing files and everything else already reconciles.
2. **Settings diff.** Fetch and diff against the canonical settings map below. Show current vs proposed per field, grouped, and apply only what the user approves.
3. **Scaffold diff.** List which baseline files are missing and which already exist. Never overwrite an existing file; propose a patch only when the user asks.
4. **Delegate `about`.** Run the `about` mode body against the now-scaffolded repo, so the README it reads is the one `setup` just wrote.
5. **Delegate `labels`.** Run the `labels` mode body unchanged.
6. **Hand off.** Report settings changed, files written, About applied, labels provisioned, and crown one next move.

The canonical settings map, each entry with the reason it is not the GitHub default:

| Setting | Value | Why |
|---------|-------|-----|
| `--enable-merge-commit` | true | mergekit closes a PR with `gh pr merge --merge`. |
| `--enable-squash-merge` | false | A squash breaks branch ancestry, which is the case gitkit `clean` needs three tests to detect. |
| `--enable-rebase-merge` | false | One merge method means one shape of history. |
| `--delete-branch-on-merge` | true | The remote branch dies with the PR, so gitkit `clean` sweeps only what it must. |
| `--enable-wiki` | false (flippable) | Proposed off in the preview; wikikit `publish` is opt-in and enabling later is one click. The user flips the row in the same approval pass. |
| `--enable-projects` | false | Nothing in the collection reads a project board. |
| `--enable-issues` | true | issuekit is the tracker. |

Default branch stays `main` and `setup` only reports a mismatch; renaming a default branch breaks open PRs and clones, so it is never automatic.

Done when the mode file states every step, every step ends on a checkable condition, and the settings map carries a reason per row.

### Phase 3: the scaffold set (built 2026-08-31)

Grounded in what the mimukit repos actually share, not in a generic starter template. Sampling `saasaloy`, `devaloy`, and `skills-tracker` gives a common core of README, LICENSE, `.gitignore`, an agent guide, and `docs/`.

| File | Content | Skipped when |
|------|---------|--------------|
| `LICENSE` | The license the user picks, with their name and the current year. | Present, or the user declines a license. |
| `README.md` | Title, the one-line About text, an install or run section. | Present. |
| `.gitignore` | Matched to the detected stack; no file when the stack is unknown. | Present, or stack undetected. |
| `AGENTS.md` | Repo conventions skeleton. | Present. |
| `.claude/CLAUDE.md` | A pointer to `AGENTS.md`, matching this repo's own one-line form. | Present. |

**The license is a question, never an assumption, and a private repo gets the question too.** `setup` asks which license the project takes before it writes `LICENSE`. The recommendation follows the repo's visibility, and the option list changes with it.

- **Public repo → recommend MIT.** Every public mimukit repo uses MIT, and the collection ships `license: MIT` in skill frontmatter. Offer MIT, Apache-2.0, and GPL-3.0, and accept any SPDX identifier the user names instead. Fetch the text from `gh api /licenses/<key> --jq .body` rather than writing a license from memory, then substitute the year and the holder name.
- **Private repo → recommend a proprietary all-rights-reserved file.** A private repo holds proprietary code, and the point of the file is to say so where a reader will find it. `setup` writes a short `LICENSE` naming the holder, the year, and the reservation of all rights, with no grant to use, copy, modify, or distribute. There is no SPDX text to fetch for this, so the mode carries the wording itself.
- **Offer an open license to a private repo as the runner-up**, because a private repo often goes public later and picking the license now is cheaper than relicensing after contributors arrive.
- **"No license" stays available in both.** Say what it means when the user picks it: default copyright already reserves all rights, so the code is not open, but nobody reading the repo can tell that from the repo.

`setup` recommends, and the user decides. This is not legal advice, and the mode says so in one line rather than arguing the point.

`setup` writes files and stops. It stages nothing and it commits nothing, which keeps repokit consistent with the rest of the collection.

Done when every row names its content and its skip condition, and the mode never overwrites an existing file.

### Phase 4: routing, description, and docs (built 2026-08-31)

- Widen frontmatter to `allowed-tools: Bash, Read, Write` so a host that honors the field permits the scaffold step.
- Add `setup` to the frontmatter `description` as one new branch, with triggers like "set up a new repo", "configure this new repo", "make this repo match my conventions". Add no synonym that renames an existing branch.
- Add `setup` to `When this fires` routing, and change the vague "set up this repo" line, which currently offers `about` then `labels`, to route to `setup` instead.
- Update `docs/wiki/skills/repokit.md`: the summary table's mode count and tools, a new `` ### `setup` `` section explaining why branch protection is out and why merge-commit-only is the choice, and a re-read provenance stamp.
- `skills.sh.json` and `.wikimap.yaml` need no change; repokit is already registered in both.

Done when `make lint` passes clean, including the mode-parity check between `SKILL.md` and the wiki page.

### Rejected alternatives

- **Add `setup` as a fourth section inside the single `SKILL.md`.** Smallest diff, but it pushes the file past 350 lines where every run reads three mode bodies it will not use.
- **Make `setup` a separate skill.** It fails the AGENTS.md gate: nobody chooses between "configure repo metadata" and "set up a new repo" as distinct deliberate moves, so it is a mode.

## Open questions

None. All questions from the draft were settled in the grill session of 2026-08-31 and moved into the design-decisions table.

## Non-goals

- Creating the repository. `gh repo create` stays with the user.
- Branch protection, rulesets, and required status checks.
- Committing or pushing anything.
- Writing CI workflows, and writing the `ai-review` listener that `labels` already flags as a gap.
- Applying any label to an issue or a PR, which stays issuekit's job.
