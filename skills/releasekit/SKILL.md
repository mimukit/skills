---
name: releasekit
description: >-
  Cut a release from the Conventional Commits a repo already writes: derive the semver bump and a changelog from the commit range, bump the manifest, tag it, and publish a GitHub release, all behind a mandatory preview. Use when the user says "cut a release", "tag a version", "release this", "what's the next version", "generate a changelog", "ship v2", or "/releasekit". It never publishes to a package registry and never moves a published tag.
license: MIT
disable-model-invocation: true
allowed-tools: Bash, Read, Write, Edit, AskUserQuestion, Skill
metadata:
  internal: false
---

# releasekit

**releasekit stops at the tag.** It never runs `npm publish`, `twine upload`, or `cargo publish`. It never moves or deletes a published tag; a bad release is fixed by cutting the next one.

## Procedure

### 1. Preflight

Every check runs before anything mutates, and each failure names itself rather than falling through to a later one. Preflight is done when every check below has passed or has stopped the run with its named refusal.

**Environment.** Confirm git, a remote, and a usable `gh`. Without `gh`, releasekit still writes the changelog and cuts the tag, so say once that the GitHub release and the CI check are both skipped, and why. Do not fail wholesale for a missing enrichment.

**Base ref.** Never assume `main`. When `gitkit` is installed, ask it. Otherwise resolve it directly:

```sh
gh repo view --json defaultBranchRef --jq .defaultBranchRef.name
```

falling back to `git symbolic-ref --short refs/remotes/origin/HEAD`, and asking the user rather than guessing past that.

**Repo state.** Refuse, and say which one failed, when:

- the working tree is dirty;
- HEAD is not the base ref;
- the branch is behind its upstream.

**Competing release tooling.** Look for `.changeset/`, `.releaserc*`, `release-please-config.json`, or a `semantic-release` dependency. **Stop before mutating anything**, name the tool, and name its command instead.

**Workspaces.** Look for `workspaces` in `package.json`, a `pnpm-workspace.yaml`, or `[workspace]` in `Cargo.toml`. **Refuse only when a marker is present and more than one manifest carries a version**, and list every versioned manifest you found. A workspace where only the root is versioned has one version and releases normally.

**Branch protection.** Probe the base branch once with both calls:

```sh
gh api "repos/{owner}/{repo}/branches/$BASE/protection"
gh api "repos/{owner}/{repo}/rules/branches/$BASE"
```

A 404 from the first call and an empty array `[]` from the second together mean unprotected and select [the direct path](#the-direct-path). A branch guarded only by a ruleset returns 404 from the first call, so a non-empty array from the second means protected. Any other answer means protected and selects [the release-PR path](#the-release-pr-path).

**Phase.** Work out which phase this run is **from the repo, never from state you keep**. Check in this order, and take the first that matches:

1. *Resume.* An earlier run stopped part way. The evidence is the newest `chore(release): vX.Y.Z` commit on HEAD's line, plus one of these: tag `vX.Y.Z` exists only locally (`git ls-remote --tags origin vX.Y.Z` is empty), the tag is on the remote but `gh release view vX.Y.Z` finds no release, or, on the direct path, the commit is not on the upstream and has no tag. **Resume that version and never derive a new one.** Pick up at the first step that did not land, and take the release body from that version's section in `CHANGELOG.md`.
2. *Finish*, release-PR path only. A merged `chore(release): vX.Y.Z` commit on the base with no tag pointing at it.
3. *Prepare* on the release-PR path, or a fresh release on the direct path. Anything else.

Resume and finish both read the version from the commit subject and skip [Derive the version](#2-derive-the-version) and [Render the changelog](#3-render-the-changelog). The check is done when the preview can name one phase and, for resume, the first step still to run.

### 2. Derive the version

**Resolve the last release.** Take the **highest stable semver tag merged into HEAD**, not the highest version in the repo:

```sh
tags=$(git tag --merged HEAD \
  | grep -E '^v?(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$' \
  | awk -F. '{ m = $1; sub(/^v/, "", m); if (m + 0 < 1000) print }')
nv=$(printf '%s\n' "$tags" | grep -c '^v')
nb=$(printf '%s\n' "$tags" | grep -c '^[0-9]')
if [ "$nb" -gt "$nv" ]; then style='^[0-9]'; else style='^v'; fi
last=$(printf '%s\n' "$tags" | grep "$style" | sort -V | tail -n 1)
```

An empty `$last` means no previous release. In the preview, list as skipped every tag of the minority prefix style and every tag the `awk` filter dropped as a calver date (major 1000 or more), so a real semver major that high stays visible. On a host whose `sort` lacks `-V`, sort on the three numeric fields instead.

Prereleases are skipped here, so the commits a `v1.3.0-rc.1` shipped still appear in the `v1.3.0` changelog.

**Read the range** `<lasttag>..HEAD`, or the whole history when no tag exists. Parse each commit's **subject and body**, because a `BREAKING CHANGE:` footer lives in the body.

**Bump from what the range contains**, taking the highest that applies:

| in the range | bump on `1.x` and above | bump on `0.x` |
|---|---|---|
| a `!` marker or a `BREAKING CHANGE:` footer | major | **minor** |
| any `feat` | minor | **patch** |
| any `fix`, `hotfix`, `perf`, or `revert` | patch | patch |
| only `docs`, `chore`, `style`, `test`, `build`, `ci`, `refactor` | none | none |

**The `0.x` column is deliberate**, the release-please and Cargo convention. State the rule and its arithmetic in words in the preview, not just the resulting number.

**A first release asks.** With no tag in the repo, prompt once with `0.1.0` prefilled. **Skip the prompt when a manifest already carries a version**, and use that version.

**The tag prefix is inherited, not chosen.** `v1.2.0` gives `v`, `1.2.0` gives none. Default to `v` on a first release.

**Two refusals come out of this step**, both with a named override:

- **Nothing user-visible.** The range holds no commit that forces a bump. Say so concretely ("nothing user-visible since v1.2.0") and name `--allow-empty` for a user who has a reason.
- **Nothing parses.** No commit in the range is a Conventional Commit, so any bump would be a guess. Refuse the same way.

**Commits that do not parse otherwise proceed.** Collect them for an **Other** section and count them in the preview.

This step is done when the preview can state the last release (or none), every tag the resolver skipped, the next version, and the rule that produced it.

### 3. Render the changelog

Group the parsed commits into Keep a Changelog sections by type:

| commit type | section |
|---|---|
| any type with `!` or a `BREAKING CHANGE:` footer | **Breaking changes** |
| `feat` | **Added** |
| `fix`, `hotfix` | **Fixed** |
| `perf`, `revert` | **Changed** |
| `docs`, `refactor`, `style`, `test`, `build`, `ci`, `chore` | none; count them by type in the preview |
| unparsed | **Other** |

On an `--allow-empty` release, list the omitted commits under **Other**. Render a section only when it has an entry.

- **Breaking changes come first, always in their own section**, carrying the migration note from the footer.
- **Keep the scope, drop the type.** Under an **Added** heading, write `auth: add token refresh retry`, not `feat(auth): add token refresh retry`.
- **Link each entry to its commit**, and to its PR when the merge commit names one.
- **Account for every commit.** The step is done when each commit in the range sits in exactly one section or in the omitted count.
- **Render exactly once.** The `CHANGELOG.md` section and the GitHub release body are the same string.

### 4. Preview and confirm

The preview is mandatory and always renders. `releasekit preview` ends here having mutated nothing; a bare `releasekit` waits for a confirmation here and mutates nothing until it gets one. The gate has no exemption: a run with nobody to answer, such as an unattended pipeline, stops here.

Lead with the path, then the facts:

- **first line.** The path (direct or release-PR) and the phase (resume, finish, prepare, or fresh).
- the computed version, and the rule that produced it stated in words;
- the rendered changelog in full;
- the manifest file and its old → new version, or that no manifest was found;
- the tag name;
- the CI check rollup result, and the SHA it belongs to;
- the count of unparsed commits;
- every command about to run.

### 5. Cut the release

**Verify CI first, on either path, and bind it to a SHA.** Read the check rollup for the exact commit the CI result has to cover, and **refuse to tag a failing one**. `--allow-red` overrides it for a known-flaky required check. When `gh` is unusable there is no rollup, so **say the check was skipped**; never let a missing signal read as green. A pending rollup is not green either, so stop and report it.

```sh
gh api --paginate "repos/{owner}/{repo}/commits/$SHA/check-runs" \
  --jq '.check_runs[] | [.name, .status, .conclusion] | @tsv'
gh api "repos/{owner}/{repo}/commits/$SHA/status" --jq .state
```

- **Finish, and a resume whose release commit is on the upstream.** `$SHA` is the release commit that gets the tag.
- **Direct path, and a resume whose release commit is not on the upstream.** CI cannot have run on the release commit, so `$SHA` is its parent: HEAD before the release commit. The release commit only adds the changelog and the manifest bump to it. Re-check that `origin/<base>` still equals `$SHA` just before the push, and stop if it moved.

#### The direct path

Unprotected base. In this order:

1. Bump the detected manifest (`package.json`, `Cargo.toml`, `pyproject.toml`, a gemspec). No manifest found is fine and is not an error.
2. Prepend the rendered section to `CHANGELOG.md`, creating the file with a header when it does not exist.
3. Commit both together as one `chore(release): v<version>` commit.
4. Create an annotated tag whose message is the release title.
5. Push the commit and the tag.
6. Create the GitHub release with `gh release create`, using the rendered body.

#### The release-PR path

Protected base. Two invocations, and the phase resolved in [Preflight](#1-preflight) decides which one runs.

**Prepare.** Do the manifest bump, the changelog, and the commit on a `release-v<version>` branch. Push it and open a PR titled `chore(release): v<version>`, whose body is the rendered changelog. Keep that exact title: a squash merge turns it into the commit subject, and the finish phase finds the release by that subject. **Stop there.** The user reviews and merges it.

**Finish.** The merged, untagged `chore(release):` commit is the trigger. Verify the rollup on that commit's SHA, tag that commit, push the tag, and create the GitHub release. The changelog is already in the repo from the merge, so nothing is committed.

This step is done when every command the preview listed has run, or when the run has stopped at a failed step. **If any step on either path fails, stop at that step** and report exactly what landed and what did not. The next run detects the gap as *resume* and continues from there. Never roll back a pushed tag.

### 6. Hand off

_Write this section in the procedural register: one instruction per sentence, active voice, present tense, no metaphor._

The hand-off differs by path, so report the one that ran.

**Direct path, release-PR finish, and resume.** This is terminal.

- *What changed.* The version, the files bumped, and the commit created.
- *Where it landed.* The tag name, the release URL, and the branch pushed.
- *Next.* There is no next kit. Say that pushing the tag may have started a publish workflow, and that releasekit does not own or watch it. Name `gh release edit` for a typo in the notes.

**Release-PR path, prepare.** This is not terminal.

- *What changed.* The release branch, the commit on it, and the PR opened. Say plainly that no tag exists yet.
- *Where it landed.* The branch name and the PR URL.
- *Next.* Review and merge the PR. Use **mergekit** when it is installed, otherwise `gh pr merge`. Then run releasekit again to tag the merged commit.

## Notes

- **Prereleases are read, never written.** releasekit passes over an existing `-rc.N` tag and never creates one.
- **Follow the repo over these defaults.** A repo with its own changelog format, a `CHANGELOG` at a different path, or a documented release procedure gets that, and say you followed it.
- No filesystem or shell (a browser-based agent, say)? Then you cannot read the log or cut anything. Instead print the derived version, the rendered changelog as a codeblock, and the exact `git tag` and `gh release create` commands for the user to run.
