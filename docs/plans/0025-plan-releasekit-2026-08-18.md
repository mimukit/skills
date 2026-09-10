# Plan — releasekit

Grilled: 2026-08-18

## Context

Every commit in a repo this collection touches is a Conventional Commit with a mandatory scope, because `commitkit` enforces it on the way in. That vocabulary is exactly what a semver bump and a changelog are computed from — `feat` is a minor, `fix` is a patch, `!` is a major — and today nothing in the collection reads it back out. The convention is paid for on every commit and cashed in nowhere.

The workflow also stops short of the end. `mergekit finish <n>` merges the PR and hands the ball back to the reviewer; `issuekit close` reconciles the tracker. After that the chain ends, and the release — the thing that makes merged work reachable by a user — is done by hand or not at all.

releasekit closes both gaps. It reads the commit range since the last tag, derives the next version and a changelog from it, and cuts the release: a `CHANGELOG.md` section, a version bump in the ecosystem's manifest, an annotated tag, and a GitHub release.

**Success** is that a user with merged work on the base branch runs one command, reads a preview, confirms, and ends up with a tag and a published release whose notes they would have written themselves.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Changelog artifact | **Both.** Prepend a Keep-a-Changelog section to `CHANGELOG.md`, and reuse the same rendered text as the GitHub release body. One render, two destinations — never two texts that can disagree. |
| Manifest version | **Bump the detected manifest.** A tag saying `v1.3.0` while `package.json` says `1.2.0` is a real bug in most ecosystems. |
| Registry publish | **Hard non-goal.** The tag releasekit creates is precisely the trigger a publish workflow already listens for. |
| Existing release tooling | **Detect and refuse.** changesets, semantic-release, and release-please own versioning end to end; a second writer corrupts their state. Name the tool and its command, mutate nothing. |
| Invocation shape | **One procedure, two exits** — not modes. The preview gate is mandatory and always renders; `releasekit preview` stops there, a bare `releasekit` continues past it on confirmation. |
| Where it may run | **Base branch, clean tree, in sync with the remote.** Refuse otherwise, loudly. |
| **Protected base branch** | **Detect in preflight, then branch on it.** Probe `gh api repos/{owner}/{repo}/branches/{base}/protection` once; any non-404 means protected. Unprotected takes the **direct path**; protected takes the **release-PR path**. The preview names the path it picked. Refusing on a protected base would make releasekit useless on exactly its audience. |
| **Two-phase inference** | On the release-PR path, releasekit works out which half it is in **from the repo, not from state it keeps**: a merged `chore(release): vX.Y.Z` commit on the base with no tag pointing at it means *finish*; anything else means *prepare*. The mode is the first line of the preview, so a misdetection is visible before anything mutates. |
| **CI gate** | **Require a green check rollup on the base's head commit before tagging**, with an explicit override flag for a known-flaky required check. A red base ships a broken release under a version that can never be reused. When `gh` is unusable, say the check was skipped rather than implying green. |
| **Resolving the last tag** | **Nearest semver ancestor of HEAD** — `git describe --tags --abbrev=0`, filtered to the semver pattern so a `nightly-2026-08-01` tag cannot be mistaken for a release. Not the highest semver in the repo, which reads the wrong lineage on a repo running `v1.x` alongside `v2.x`. |
| **Prerelease tags** | **Skipped at the resolver.** The range runs from the last *stable* tag, so commits that shipped in `v1.3.0-rc.1` still appear in the `v1.3.0` changelog. The rest of the skill never learns prereleases exist. |
| **First release** | **Ask, prefilled `0.1.0`** — it happens once per repo and is unfixable afterwards, and `1.0.0` is a public declaration of API stability that must not be guessed. Skip the prompt when a manifest already carries a version; that version is the answer. |
| **Pre-1.0 ladder** | On `0.x`, **a breaking change bumps the minor and a `feat` bumps the patch** — the release-please and Cargo convention. Bumping major would take `0.3.0` to `1.0.0` and declare stability from a single commit footer. The preview states the rule and the arithmetic in words, not just the resulting number. |
| **Range with no user-visible change** | **Refuse and explain** — "nothing user-visible since v1.2.0" — with an explicit override flag the user passes deliberately. A patch bump for every CI tweak makes releases meaningless; a prompt every time trains people to dismiss it. |
| **Commits that aren't Conventional Commits** | **Proceed, with a floor.** Unparsed commits land under an **Other** changelog section and are counted in the preview, so nothing is silently dropped. A range where *nothing* parses refuses, because the bump would be a guess. Squash-merge repos would be unusable under a stricter rule. |
| **Monorepos** | **Detect, then decide on the evidence.** A workspace marker (`workspaces` in `package.json`, `pnpm-workspace.yaml`, `[workspace]` in `Cargo.toml`) *plus more than one versioned package* refuses and names every versioned manifest it found. A workspace where only the root carries a version proceeds normally — that repo has one artifact and one version. |
| **Commit grouping** | **One commit**, `chore(release): v<version>`, carrying the manifest bump and the changelog together. On the release-PR path that commit is the entire PR. |
| Tag immutability | **Never move or delete a published tag.** A bad release is fixed by cutting the next one. |
| **Fixing a released typo** | **Out of scope.** The hand-off names `gh release edit` as the one-liner. Adding a notes-edit path would make a third entry point out of a two-exit skill. |
| Tag prefix | Inferred from the last tag — `v1.2.0` gives `v`, `1.2.0` gives none — defaulting to `v` on a first release. |
| Unattended runs | **Interactive only.** afkkit's pipeline ends at the open PR, so releasekit is outside it; its confirm gate is a consent gate with no mode-owned exemption, and afkkit's own rule is that such a gate escalates rather than assumes a yes. |
| Base ref | From `gitkit`, which owns it. Public skills install alone, so inline the answer with a fallback: without `gitkit`, use the remote's default branch. |
| Visibility | `internal: false` — public. This repo has no tags and no releases, so releasekit ships for other repos and cannot dogfood here. |
| Tools | `Bash, Read, Write, Edit, AskUserQuestion, Skill`. `Skill` is for the `gitkit` base-ref call only, matching `mergekit` and `statuskit`. No web tools. |

## Approach

**What it reuses.** The Conventional Commits vocabulary and its nine types come from `commitkit` — releasekit parses what commitkit writes and must not restate the type table as its own invention. The base ref and the never-bare-`git pull` rule come from `gitkit`. The `gh`-degradation shape (name the gap once, carry on git-only) comes from `statuskit`'s preflight. The preview-then-confirm-before-mutation stance comes from `mergekit`, which is also where the release-PR path hands off. The hand-off's three beats and the procedural register come from the repo conventions every skill already follows.

**Rejected approaches**, one line each: *wrap release-please* — inherits its config surface and its opinions, and dies when it changes. *Changelog only, no tag* — leaves the version question unanswered, which is the hard half. *A GitHub Action instead of a skill* — CI can't ask the question that matters, which is whether this range is a release at all.

### Phase 1 — Preflight and guards

Every check here runs before anything mutates, and each failure names itself rather than falling through.

- **Environment** — git present, remote present, `gh` usable. Degrade per source: without `gh`, cut the tag and write the changelog, and say the GitHub release and the CI check were both skipped and why.
- **Base ref** — resolve through `gitkit`; fall back to the remote's default branch.
- **Repo state** — refuse when the tree is dirty, HEAD is not the base ref, or the branch is behind its upstream.
- **Competing tooling** — `.changeset/`, `.releaserc*`, `release-please-config.json`, a `semantic-release` dependency. Stop before any mutation; name the tool and its command.
- **Monorepo** — workspace markers plus a second versioned manifest refuses, listing every versioned manifest found.
- **Protection** — probe the base branch's protection once. The answer selects the direct path or the release-PR path for the whole run.
- **Phase** — on the release-PR path, look for a merged untagged `chore(release):` commit to decide *prepare* or *finish*.

### Phase 2 — Derive the version

- Resolve the last release tag as the **nearest semver ancestor of HEAD**, skipping prereleases and non-semver tags.
- Read the range `<lasttag>..HEAD`, or the whole history when no tag exists.
- Parse each commit's subject **and body** — `BREAKING CHANGE:` footers live in the body and cannot be skipped.
- Bump rules on `1.x` and above: `!` or a `BREAKING CHANGE:` footer → major; any `feat` → minor; any `fix` or `perf` → patch. On `0.x`: breaking → minor, `feat` → patch.
- A first release asks, prefilled `0.1.0`, unless a manifest already carries a version.
- Collect unparsed commits for the **Other** section. Refuse if the range holds no parseable commit at all, or no commit that forces a bump, unless the override flag is set.

### Phase 3 — Render the changelog

- Group parsed commits by type into Keep-a-Changelog sections, breaking changes first and always in their own section with the migration note from the footer.
- Keep the scope, drop the type prefix: `auth: add token refresh retry` reads better than `feat(auth): add token refresh retry` under an **Added** heading.
- Link each entry to its commit, and to its PR when the merge commit names one.
- Render exactly once. The `CHANGELOG.md` section and the GitHub release body are the same string.

### Phase 4 — The preview gate

- First line: which path (direct or release-PR) and, on the PR path, which phase.
- Then the computed version and the rule in words, the rendered changelog, the manifest and its old → new version, the tag name, the CI rollup result, the count of unparsed commits, and every command about to run.
- `releasekit preview` ends here having mutated nothing.
- A bare `releasekit` asks for confirmation here and mutates nothing until it gets one.

### Phase 5a — Cut it, direct path

Unprotected base. In this order, because each step depends on the last landing:

1. Bump the detected manifest. No manifest found is fine and is not an error.
2. Prepend the section to `CHANGELOG.md`, creating the file with a header when it does not exist.
3. Commit both as `chore(release): v<version>`.
4. Verify the CI rollup is green on the base's head, unless overridden.
5. Create an annotated tag whose message is the release title.
6. Push the commit and the tag.
7. Create the GitHub release with `gh release create` using the rendered body.

If any step fails, stop there and report exactly what landed and what did not. Never roll back a pushed tag.

### Phase 5b — Cut it, release-PR path

Protected base. Two invocations.

**Prepare** — do steps 1–3 above on a `release-v<version>` branch, push it, and open a PR whose body is the rendered changelog. Stop. The user reviews and merges it, with `mergekit` when installed.

**Finish** — detected on the next invocation by the merged untagged `chore(release):` commit. Verify the CI rollup on the base, tag that commit, push the tag, create the GitHub release. The changelog is already in the repo from the merge, so nothing is rewritten.

### Phase 6 — Hand off

The hand-off differs by path, and the plan should say so rather than claim one shape.

- **Direct path** — terminal. Name the version, the tag, the release URL, and the fact that pushing the tag may have started a publish workflow releasekit does not own or watch. There is no next kit.
- **Release-PR path, prepare** — not terminal. Name the PR, and route to `mergekit` to review and merge it, with `gh pr merge` as the plain fallback. Say that releasekit must be re-run afterwards to tag.
- **Release-PR path, finish** — terminal, same as the direct path.

Both terminal shapes name `gh release edit` for a typo in the notes, since fixing one is out of scope.

### Phase 7 — Land it in this repo

- `skills/releasekit/SKILL.md`, `internal: false`.
- `docs/wiki/skills/releasekit.md` — the reader-facing page, with the provenance stamp.
- Add `releasekit` to the right group in `skills.sh.json`.
- Add it to the README Skills table and **delete its row from `IDEAS.md`**, per that file's own graduate step.
- `make lint` clean.

## Open questions

The design frontier emptied in the 2026-08-18 grill. Two residual risks are implementation concerns rather than open decisions, recorded so they are not rediscovered later:

- **The phase inference keys on a commit subject.** A repo that squash-merges the release PR under a rewritten title produces no `chore(release):` commit, so *finish* never fires and the next run re-prepares a release that already merged. The preview naming the detected phase is the mitigation; whether that is enough is a thing to watch in testing.
- **A long range is a large read.** Subjects are cheap, bodies are not, and bodies cannot be skipped because `BREAKING CHANGE:` lives there. A year of commits since the last tag may need a cap and a stated truncation rather than an unbounded read.

## Non-goals

- **Publishing to any package registry.** The tag is the trigger; CI does the publish.
- **Moving or deleting a published tag**, and rewriting released history in any form.
- **Editing a published release's notes.** Fix forward, or run `gh release edit` by hand.
- **Monorepo / per-package versioning** — one version per repo, and a workspace with several versioned packages is refused rather than guessed at.
- **Cutting prereleases.** releasekit reads past an existing prerelease tag but never creates one.
- **Replacing or driving changesets, semantic-release, or release-please.** releasekit detects them and stands down.
- **Writing the commits it releases.** That is commitkit's job, and releasekit only ever reads them.
- **Watching for the release PR to merge, or watching CI after the tag lands.** Both are the user's move; releasekit is re-run rather than left waiting.
- **Running unattended.** The confirm gate is a real gate, and there is no mode-owned exemption for it.
