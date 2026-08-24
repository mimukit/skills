# releasekit

Cut a release from the Conventional Commits a repo already writes — derive the semver bump and a changelog from the commit range, bump the manifest, tag it, and publish a GitHub release, all behind a mandatory preview.

**Reach for it when** work has merged and somebody has to decide what version it is and what the notes say — and you would rather that decision came from the commit log than from memory.

| | |
|---|---|
| Modes | none — one procedure with two exits (`preview`, or cut it) |
| Tools | `Bash`, `Read`, `Write`, `Edit`, `AskUserQuestion`, `Skill` |
| Writes | `CHANGELOG.md`, the ecosystem's version manifest, one `chore(release)` commit, an annotated tag, a GitHub release |
| Triggering | **explicit only** — model invocation is disabled |
| Visibility | public |

## The gap it fills

[`commitkit`](./commitkit.md) enforces Conventional Commits with a mandatory scope on every commit in the repo. That is a real tax, paid on every change, and until now the collection collected it and spent it on nothing — the type, the scope, and the `!` marker are exactly the inputs a semver bump and a changelog are computed from.

The workflow also stopped one step short of the user. [`mergekit`](./mergekit.md) merges the PR and hands the ball back; [`issuekit`](./issuekit.md) `close` reconciles the tracker. After that the chain ended, and the release — the thing that makes merged work reachable — was done by hand or not at all.

releasekit is the step that reads the tax back out.

## Why it stops at the tag

No `npm publish`, no `twine upload`, no `cargo publish`. Two reasons, and the second is the real one.

Credentials are the obvious argument: a skill that publishes needs registry tokens, and every registry handles them differently. The stronger argument is that **the tag releasekit creates is already the trigger**. Nearly every publish pipeline in existence fires on a pushed tag, so releasekit's output is the input CI was waiting for. Doing the publish as well would duplicate a mechanism that already works, and would do it in the one place where a mistake is public and permanent — `npm unpublish` is heavily restricted, and PyPI does not allow re-uploading a version at all.

## Why a protected base branch gets its own path

This is the decision that shaped the skill most, and the original plan missed it entirely.

The straightforward design commits the changelog and version bump to the base branch and pushes. Any repo mature enough to be cutting releases almost certainly forbids exactly that. Refusing on a protected base would have left releasekit working only on repos too small to need it.

So it probes protection in preflight and picks a path. Unprotected gets the direct push. Protected gets a **release PR**: the bump and changelog land on a `release-v<version>` branch, a PR opens with the changelog as its body, and releasekit stops. The user merges it — with [`mergekit`](./mergekit.md), or by hand — and runs releasekit again to tag the merged commit.

The cost is honest and worth naming: **on that path releasekit is not terminal**, and it takes two invocations. That is the price of working on the repos that most need it.

## Why the phase is inferred, never stored

The release-PR path splits a release in two, so any given invocation has to know which half it is in. releasekit is not a bot watching for a merge.

A state file would answer it and was rejected: it drifts, it needs gitignoring, and a cancelled release leaves it lying. Explicit `prepare` / `tag` subcommands would also answer it, and push the question onto the user — who is the person least likely to remember which half they are in.

Instead it reads the repo. **A merged `chore(release): vX.Y.Z` commit on the base with no tag pointing at it means finish; anything else means prepare.** The repo is the state, so there is nothing to keep in sync.

The detection has a known weakness: a repo that squash-merges the release PR under a rewritten title produces no `chore(release):` commit, so *finish* never fires. The mitigation is that the preview names the detected phase on its first line, before anything mutates.

## Why the last tag is the nearest ancestor

`git describe --tags --abbrev=0`, filtered to the semver shape — not the highest version in the repo.

The two agree on most repos, which is what makes the difference easy to get wrong. They diverge exactly where it matters: a project maintaining `v1.x` alongside a released `v2.x`. Cutting a `v1.3.1` patch there, "highest semver" would diff against `v2` and produce a changelog full of commits that shipped months ago in a different major line.

Prereleases are skipped at the same resolver, so a `v1.3.0-rc.1` tag is passed over and the commits it shipped still appear in the `v1.3.0` changelog — where a user reading the stable release actually expects them.

## Why a breaking change on `0.x` bumps the minor

This contradicts the plain reading of `!`, and it is deliberate.

Bumping major on a pre-1.0 repo takes `0.3.0` to `1.0.0`. Under semver, `1.0.0` is a public declaration that the API is stable — and deriving that declaration from a single commit footer is the loudest thing this skill could do by accident. The convention here follows release-please and Cargo: on `0.x`, breaking bumps the minor and a `feat` bumps the patch.

Because the rule surprises people, the preview states it and its arithmetic in words rather than only showing the resulting number.

## Why CI is a gate rather than a warning

The original guards checked the working tree, the branch, and the sync — everything about whether the release *describes* the right code, and nothing about whether that code works.

A tag on a red base is the most expensive mistake in the whole procedure, because the version number is spent permanently. It cannot be reused, only superseded, and anyone who resolved it in between gets the broken build. So the check rollup on the base's head is a refusal, with `--allow-red` available for a genuinely flaky required check.

When `gh` is unusable there is no rollup, and releasekit **says the check was skipped**. A missing signal is never allowed to read as green.

## Why unparsed commits proceed, but a range of them refuses

Squash-merge repos build commit subjects from PR titles, which frequently are not Conventional Commits. Any repo with history predating the convention has a mixed log. Refusing until every commit parses would make releasekit unusable on both, which is most real repos.

So unparsed commits land under an **Other** changelog section and are counted in the preview — nothing is dropped silently. The floor is that a range where *nothing* parses refuses, because at that point the bump is not derived from anything.

The same shape governs a range holding only `docs` and `chore`: nothing forces a bump, so releasekit refuses with `--allow-empty` named in the refusal. A patch bump for every CI tweak makes the version meaningless, and a prompt on every no-op range trains people to dismiss it.

## The refusals

Four, each a refusal rather than a caution, because each has a failure that a warning does not prevent.

- **Another release tool owns the repo.** changesets, semantic-release, and release-please manage versioning end to end; a second writer corrupts their state. releasekit names the tool and its command and mutates nothing.
- **A workspace with several versioned packages.** A workspace marker alone is not disqualifying — plenty of repos have a `packages/` directory and one published artifact — so the refusal keys on a marker *plus* more than one versioned manifest, and lists them.
- **A red base**, as above.
- **Moving or deleting a published tag.** Re-tagging breaks every consumer that already resolved it. A bad release is fixed by cutting the next one, and a typo in the notes is fixed with `gh release edit` outside the skill.

## Why it never runs unattended

[`afkkit`](./afkkit.md)'s pipeline ends at an open PR, so releasekit sits outside it by construction. The reason it stays outside is the preview: that confirmation is a consent gate with no mode-owned exemption, and afkkit's own rule is that such a gate escalates rather than assuming a yes.

Nothing about a release is urgent enough to justify inventing an exemption for the one mutation in this collection that cannot be undone.

## Hands off to

**Usually nowhere.** On the direct path, and on the second half of the release-PR path, releasekit is terminal — the hand-off names the tag and the release URL, says that pushing the tag may have started a publish workflow it does not own or watch, and stops. A terminal skill that invents a follow-up to look useful is worse than one that ends.

The exception is the release-PR **prepare** run, which hands to [`mergekit`](./mergekit.md) to review and merge the release PR, degrading to `gh pr merge` when mergekit is not installed — and then back to releasekit to tag.

It borrows the base ref from [`gitkit`](./gitkit.md), which owns it, and resolves it directly when gitkit is absent.

## Install

```sh
npx skills add mimukit/skills -s releasekit
```

Source: [`skills/releasekit/SKILL.md`](../../../skills/releasekit/SKILL.md) · [How it fits the loop](../workflow.md)

_Verified against `main`@`d2e9d3b` on 2026-08-24._
