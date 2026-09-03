# Reference

Declared surface: every command, variable, badge, and check the repo defines.

## Make targets

Run `make help` to print this list from the `Makefile` itself.

| Target | Arguments | Does |
|--------|-----------|------|
| `make link` | `name=<skill>` (optional) | Symlinks `skills/<name>/` into every AI tool's skills directory. No `name=` opens a picker. |
| `make unlink` | `name=<skill>` (optional) | Removes a dev symlink and restores any backup. No `name=` opens a picker restricted to linked skills. |
| `make list` | — | Prints every skill with its aggregated link status. |
| `make cheatsheet` | — | Regenerates `docs/wiki/cheatsheet.md` from the pages under `docs/wiki/skills/`. Prints a nudge for any row that runs long. |
| `make lint` | `name=<skill> …` (optional) | Checks skills against the conventions. Named skills skip the cross-file checks. |
| `make security` | `name=<skill> …` (optional) | Heuristic security scan. |
| `make help` | — | Prints the target list. Default goal. |

`make lint` and `make security` accept multiple skill names. `make link` and `make unlink` take one.

Exit status: `lint` is non-zero when there are errors (warnings alone pass). `security` is non-zero when the worst tier reaches `SECURITY_FAIL_TIER`.

## Environment variables

All four are read by `scripts/`, and all four have defaults — none needs setting for normal use.

| Variable | Default | Read by | Effect |
|----------|---------|---------|--------|
| `CLAUDE_SKILLS_DIR` | `$HOME/.claude/skills` | `lib.sh` | Where the Claude Code half of a dev link goes. |
| `AGENTS_SKILLS_DIR` | `$HOME/.agents/skills` | `lib.sh` | Where the Codex/opencode/antigravity half of a dev link goes. |
| `SKILL_BACKUP_SUFFIX` | `.skshbak` | `lib.sh` | Suffix for the sibling an existing install is moved aside to. |
| `SECURITY_FAIL_TIER` | `high` | `security.sh` | Tier at or above which the scan exits non-zero. One of `safe`, `low`, `med`, `high`. |

One more variable matters but is **not** read by anything in this repo:

| Variable | Read by | Effect |
|----------|---------|--------|
| `INSTALL_INTERNAL_SKILLS=1` | the skills.sh CLI | Installs skills marked `metadata.internal: true`, which are otherwise hidden from discovery. |

## Link status badges

`make list` and the interactive pickers report an aggregate status across **both** destination directories.

| Badge | Status | Meaning |
|-------|--------|---------|
| `●` | linked | Your dev symlink is in every destination, pointing at the repo copy. |
| `⇄` | swapped | Linked, over a backed-up real install. `make unlink` restores it. |
| `◑` | partial | Present in some destinations but not cleanly linked in all — usually an interrupted link or unlink. Re-run `make link`. |
| `◆` | foreign | A symlink exists but points somewhere other than this repo's copy. `make link` replaces it. |
| `■` | real | A non-symlink install lives there, typically from skills.sh. Plain operations won't touch it; `make link` turns it into `swapped`. |
| `○` | unlinked | Not present in any destination. |

Quick model: `●` and `⇄` mean the repo copy is live; `○`, `■`, and `◆` mean it isn't; `◑` means the destinations disagree.

`foreign` and `real` also exist as *per-directory* states internally, alongside `linked` and `unlinked`. Only the aggregate reaches the badge.

## Frontmatter fields

```yaml
---
name: <matches directory>
description: >-
  <what it does>. Use when <explicit English trigger>.
license: MIT
allowed-tools: <only if the skill needs a restricted set>
metadata:
  internal: true   # true = repo-only meta skill; false = public/publishable
---
```

## Lint checks

Per skill:

| Check | Severity |
|-------|----------|
| `SKILL.md` exists | error |
| Frontmatter block present and non-empty | error |
| `name:` field present | error |
| `name:` matches the directory name exactly | error |
| `name` is one lowercase word ending in `kit` | warning |
| `description:` field present | error |
| `description` contains a "Use when" trigger | warning |
| `license:` present | warning |
| `metadata.internal` declared | error |
| `metadata.internal` is exactly `true` or `false` | error |
| `allowed-tools:` declared | warning |
| Public skill has no repo-relative link (`](../…`) | warning |
| Public skill doesn't reference repo machinery (`make lint`, `AGENTS.md`, `scripts/`) | warning |
| Closing hand-off section exists, in the root or in every `modes/*.md` | warning |
| Every intra-doc `](#anchor)` resolves to a real heading, in `SKILL.md` and every satellite | error |
| No number-based `step N`, `step-N`, or `§N` reference, in `SKILL.md` and every satellite | warning |
| Every relative pointer resolves inside the skill directory, from the root and from every satellite | error |

Full runs only (skipped when skill names are passed):

| Check | Severity |
|-------|----------|
| `issuekit` and `repokit` label maps agree on names and colors | error |
| `commitkit` and `issuekit` commit-type tables agree | error |
| Every skill named in the workflow map exists | error |
| Every `<kit> <mode>` in the workflow map names a real mode | error |
| Every lifecycle label in the workflow map's vocabulary section still exists in `issuekit` | error |
| Every skill has a page at `docs/wiki/skills/<name>.md` | error |
| Every page in `docs/wiki/skills/` documents a real skill | error |
| Every `` ### `mode` `` heading on a skill page names a mode that `SKILL.md` defines | error |
| Every skill has a page entry in `docs/wiki/.wikimap.yaml` | error |
| Every skill page `.wikimap.yaml` registers exists | error |
| Every skill is linked from `docs/wiki/index.md` | error |
| Every skill page `index.md` links exists | error |
| A commit touching exactly one skill also touched that skill's page | warning |
| `docs/wiki/cheatsheet.md` matches what `scripts/cheatsheet.sh` generates | error |

The portability checks apply only to skills marked `internal: false`. The hand-off check exempts `gitkit`, and accepts the grandfathered headings `Report`, `Output`, `Finish`, and `After creating` alongside the canonical `Hand off`. The `allowed-tools` check has its own exemption list, `TOOLS_EXEMPT`, which is currently empty — joining it requires stating the reason in the skill's own Notes.

A **satellite** is any `.md` in a skill's directory other than `SKILL.md`, most often a `modes/<mode>.md`. It ships with the skill on install, so it carries the same reference-integrity checks as the root rather than rotting where nothing looks. A relative pointer is checked from the file that writes it, so `](modes/close.md)` in a root and `](../SKILL.md#remove)` in a satellite both resolve against their own directory. The portability check reads `](../…)` in a root as an escape from the skill directory and flags it; the same pointer in a satellite is how a satellite reaches its own root.

The hand-off check takes a split skill on either terms. A skill with a `modes/` directory passes when the root carries a closing section, or when every one of its `modes/*.md` does, because a per-mode hand-off belongs with the mode body it closes.

The four page-registration checks ask one question of three files — can this page be found on disk, by a docs audit, and by a reader. They enforce **presence only**. Nothing checks *placement*: `index.md` groups skills by theme, and a skill filed under the wrong heading links just as correctly as one filed right.

The cheatsheet check regenerates the page into a temp file and diffs it. Nothing on that page is authored, so a difference always means the same thing: a skill page changed and nobody ran `make cheatsheet`. The error prints the first lines of the diff and names the fix.

The page-lag warning compares commit dates rather than stamped SHAs, and is scoped to commits that changed exactly one skill. A repo-wide prose sweep touches many skills at once and genuinely owes no page edit, so the scoping is what keeps the check from opening at one warning per skill touched, nearly all of them correct to ignore.

## Security finding classes

| Class | Mirrors | Severity | Triggered by |
|-------|---------|----------|--------------|
| Autonomous shell execution | Gen | med | Imperative "run/execute" near a shell command or a `sh`/`bash` fence |
| Broad tool grant, uses shell | Gen | med | No `allowed-tools` declared, yet the skill uses the shell |
| Broad tool grant | Gen | low | No `allowed-tools` declared |
| Bash alongside Write/Edit | Gen | low | `allowed-tools` grants both |
| Detection-evasion language | Snyk | high | "evade/bypass/defeat … detector/classifier/scanner", "undetectable" |
| Network exfiltration | Socket | med | `curl`/`wget`/URL near "post/upload/send/exfil", or "send … to" |
| Secret handling | Snyk | med | "read/print/log … secret/token/API key/password/`.env`" |
| Destructive or injection command | Gen | high | `rm -rf`, `sudo`, `chmod 777`, fork bomb, `eval $`, pipe-to-shell |

Severity ranks `safe` < `low` < `med` < `high`. A skill's tier is the maximum across its findings. The frontmatter is excluded from body scanning so an `allowed-tools` declaration isn't matched as prose.

## Documentation artifact naming

`<type>-<slug>-YYYY-MM-DD.md`, using the artifact's **creation** date — the filename stays stable when the file is edited.

| Type | Path | Written by |
|------|------|------------|
| Plan | `docs/plans/plan-<slug>-YYYY-MM-DD.md` | `plankit` |
| Research | `docs/research/research-<slug>-YYYY-MM-DD.md` | `researchkit` |
| Validation | `docs/validation/validation-<slug>-YYYY-MM-DD.md` | `validatekit` |
| Refactor proposal | `docs/refactor/refactor-<slug>-YYYY-MM-DD.md` | `refactorkit` |
| Debug postmortem | `docs/debug/debug-<slug>-YYYY-MM-DD.md` | `debugkit` |
| QA | `docs/qa/qa-<slug>-YYYY-MM-DD.md` | `qakit` |
| Review | `docs/reviews/review-<slug>-YYYY-MM-DD.md` | `reviewkit` |
| Handoff | `docs/handoffs/handoff-<slug>-YYYY-MM-DD.md` | `handoffkit` |
| Prompt | `docs/prompts/prompt-<slug>-YYYY-MM-DD.md` | `promptkit` `system` |
| ADR | `docs/adr/adr-NNNN-<slug>-YYYY-MM-DD.md` — zero-padded, monotonic | `domainkit` |
| Verification bundle | `docs/verify/verify-<slug>-YYYY-MM-DD/` — a directory | `verifykit` |

Same subject means update in place, never a second file. On a genuine collision of type, slug, and date, make the slug more specific; only as a last resort insert a sequence immediately before the date.

## Gitignored paths

| Path | Why |
|------|-----|
| `docs/tests/` | scratch QA and test plans, disposable |
| `docs/verify/` | verifykit proof bundles, published to `refs/verify-assets/*` instead |
| `docs/status/` | statuskit snapshots, point-in-time scratch dashboards |
| `.DS_Store`, `*.swp` | OS and editor cruft |

## CI

`.github/workflows/lint.yml` runs on pushes to `main` and on every pull request. One job on `ubuntu-latest`: `actions/checkout@v4`, then `make lint`, then `make security`.

_Verified against `main`@`17c5881` on 2026-09-01._
