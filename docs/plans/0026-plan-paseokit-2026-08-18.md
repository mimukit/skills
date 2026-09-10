# Plan — paseokit

Grilled: 2026-08-18
Researched: 2026-08-18

## Context

The owner has moved from [Orca](https://www.onorca.dev/) to [Paseo](https://paseo.sh) as the agent orchestration tool for coding sessions. The worktrees themselves have not changed: `gitkit` owns the convention, `issuekit start` and `mergekit` create them, and every one is plain `git worktree` under `$WORKTREE_ROOT/<repo>/<branch>`. What changed is the tool that has to show them.

`orcakit` exists because Orca **discovers** worktrees on its own and then knows nothing about them — so its job is enrichment and cleanup. Paseo inverts that. It discovers nothing at all. A worktree that `git worktree add` created is invisible to Paseo until something explicitly registers it, and a workspace whose directory has been deleted stays in `paseo workspace ls` forever.

So the original ask — worktrees "dynamically discovered and shown by Paseo similar to Orca" — cannot be satisfied by configuring Paseo. There is no setting to turn on. Something has to push worktrees into Paseo's registry and reap dead rows back out. **paseokit is that something**, and it sits exactly where `orcakit` sits: it never creates or destroys a worktree, only Paseo's row for one.

**The grill changed the delivery model.** The plan originally paired the skill with a `post-checkout` git hook so registration happened the moment a worktree was born. The owner rejected the hook and chose to run the skill by hand. paseokit is therefore **on-demand only**: worktrees appear in Paseo when you run `paseokit sync`, not when they are created. That is a deliberate trade of immediacy for a smaller footprint and no writes into any repo's `.git/hooks`.

**Success** is that one command brings Paseo's sidebar into agreement with the worktrees that actually exist on the machine, across every project, and that running it twice in a row changes nothing the second time.

## Verified findings

Everything below was confirmed against the live daemon on `devaloy`, CLI and daemon both `0.4.0`, by creating throwaway worktrees and reading back `~/.paseo/projects/*.json`. This is the evidence base for the decisions that follow; re-verify before implementing against a newer Paseo.

| Question | Answer | How it was verified |
|---|---|---|
| Does Paseo discover worktrees git created? | **No.** The registry is explicit-only. | A worktree added with `git worktree add` never appeared in `paseo workspace ls`. |
| Can Paseo adopt an existing worktree? | **Yes, cleanly.** `paseo workspace create --isolation local --path <wt>` introspects git and records `kind: "worktree"`, the correct `branch`, and `mainRepoRoot` pointing at the main checkout. | Registered a git-made worktree; read back the full record. |
| Is registration idempotent? | **No.** Running it twice on one path silently creates a second workspace row. | Two consecutive identical `workspace create` calls produced `wks_a21b…` and `wks_30cf…` with the same `cwd`. |
| Does Paseo prune a workspace whose directory is gone? | **No.** The row persists indefinitely. | Removed the worktree with `git worktree remove`; both rows were still listed afterwards. |
| Does `workspace archive` delete the worktree? | **No.** It is registry-only — directory, branch, and git registration all survive. | Archived a workspace, then confirmed all three were intact. |
| Does `--project <id>` matter? | **Critically.** Without it Paseo creates a *duplicate project* whose `rootPath` is the worktree path, even though `projectKey` is identical to the real project's. | Registering without `--project` produced `prj_fcc61f66…` named after the branch, alongside the real `prj_bfd40f65…`. |
| Does running from inside the main checkout infer the project? | **No.** Same duplicate-project result. | Registered with `cwd` = main checkout and no `--project`. |
| Will `--project` accept a name or a path? | **No.** Both are rejected with `Unknown project: …`. It requires the literal `prj_…` id. | Tried `--project skills` and `--project /home/dev/projects/skills`. |
| Is the id derivable from `projectKey`? | **No.** Not an md5, sha1, sha256, or sha512 prefix or substring. | Hashed all three known `projectKey` values against their ids. |
| Is there a `paseo project ls` to resolve it? | **No, not in 0.4.0**, despite the published docs describing one. | `paseo project --help` falls through to root usage. |
| What metadata can a workspace carry? | **Title and pin, nothing else.** No issue link, no status field. | Full record: `workspaceId`, `projectId`, `cwd`, `kind`, `displayName`, `title`, `branch`, `worktreeRoot`, `baseBranch`, `isPaseoOwnedWorktree`, `mainRepoRoot`, timestamps, `archivedAt`, `autoArchivedChangeRequestUrl`, `pinnedAt`. |
| Is `isPaseoOwnedWorktree` trustworthy? | **No.** Set to `true` for worktrees git created and Paseo merely adopted. | Every adopted worktree came back `true`. |
| Is cron available on the target box? | **No.** No `crontab` binary, no cron daemon, no systemd. | `command -v crontab` empty; `/run/systemd/system` absent. |
| Does `post-checkout` fire on `git worktree add`? | **Yes**, with `$1` set to the null SHA and `pwd` inside the new worktree; an ordinary `git checkout` fires with a real SHA. `--no-checkout` does not fire. | Installed a logging hook and observed all three cases. |
| Does any kit use `--no-checkout`? | **No.** `gitkit` always checks out. | Grepped every `SKILL.md`. |
| Does any kit make branchless worktrees? | **Yes** — `debugkit` uses `git worktree add --detach` for bisect scratch. | Grepped every `SKILL.md`. |

The hook findings are recorded even though the hook was cut, so that reviving automation later does not need the research repeated.

Two facts about the owner's current config carry forward: `worktrees.root` is already `~/worktrees/`, matching `gitkit`'s default, and `daemon.autoArchiveAfterMerge` exists and is `false`.

## Design decisions (settled)

Questions Q1–Q14 refer to the grill of 2026-08-18.

| Decision | Resolution |
|----------|-----------|
| Name | **`paseokit`** — functional word leads, one word, lowercase, no collision with a known tool. |
| Visibility | `internal: false` — public and portable. It no-ops cleanly on a machine with no Paseo, as `orcakit` does without Orca. |
| Tools | `Bash, Read, Skill`. Matching `orcakit` exactly; `Write` is no longer needed now that no hook script is installed. `Skill` is for the `gitkit` base-ref and teardown calls. |
| Relationship to `orcakit` | **Independent siblings, both kept.** No shared adapter, no deprecation. Each is machine-local and optional, and neither is ever called by another skill. |
| The line it does not cross | **Git owns the worktree; Paseo owns the row.** paseokit never runs `paseo workspace create --isolation worktree` to do real work, never invents a path, never lets Paseo create a branch. It registers and archives, nothing else. |
| Archiving is the removal primitive | **Proven non-destructive**, so `sync` may archive without a confirm gate. This is the sharpest divergence from `orcakit`, whose `clean` deletes directories and therefore needs a preview and an explicit OK. |
| **Delivery model (Q12 follow-up)** | **On-demand only. No git hook, no scheduler, no background process.** The owner runs `paseokit sync` when they want the sidebar reconciled. `autoArchiveAfterMerge` is consequently the only automatic mechanism in the design. |
| **Run scope (Q1)** | **Machine-wide.** Iterate every live project in `projects.json` and run `git worktree list --porcelain` against each `rootPath`. The sidebar being fixed is machine-wide, and the file must be read for ids anyway. |
| Resolving `projectId` | **Read `~/.paseo/projects/projects.json`**, matching `rootPath` == main checkout and `archivedAt` == null. Confirmed to have no CLI equivalent and to be underivable. A documented seam with a stated fallback, not a stable API. |
| Fallback when the id cannot be resolved | **Skip registration and report.** Never register without `--project` — a duplicate project is worse than a missing row, because it is invisible in `workspace ls` and no CLI deletes it. |
| **Bootstrapping a missing project (Q2)** | **Auto-create** by registering the main checkout with `paseo workspace create --isolation local --path "$REPO"`, then re-read `projects.json` for the new id. That is how a project comes into being, and it mutates nothing on disk. |
| **Reach beyond registered projects (Q6)** | **Scan, report, register on confirmation.** Walk `$WORKTREE_ROOT/*`, resolve each candidate to its main checkout with `git rev-parse --git-common-dir`, and list repos Paseo has never seen. Register them only on an explicit OK. |
| Paseo's own worktrees | **Skipped by construction.** They live under `worktrees.root/<hash>/<slug>` and already carry a workspace row, so `sync` never sees them as unregistered. The `$WORKTREE_ROOT` scan must skip those hash directories rather than reporting them as unknown repos. |
| **Detached worktrees (Q7)** | **Filtered on identity, not location.** A worktree with no symbolic HEAD never registers, which keeps `debugkit`'s bisect scratch out of the sidebar. Same predicate everywhere: `git symbolic-ref -q HEAD`. |
| **Title (Q5)** | **`#<n> · <issue title>`**, read from `gh`, degrading to the branch slug when `gh` is unusable. Never overwrite a title a human set, matching `orcakit`'s rule on hand-written metadata. |
| Enrichment surface | **The title, and only the title.** Paseo has no issue-link or status field, so `orcakit`'s `link` mode has no equivalent here. |
| **Tombstones (Q9, Q13)** | **An archived row suppresses re-registration.** `list` gives it a `tombstoned` verdict so it reads as deliberate rather than missing, and `sync` names them and offers to restore on one OK. Without this, archiving to declutter is undone by the next run. |
| **Sync gates (Q14)** | **Straight through, with two exceptions**: registering a repo Paseo has never seen, and restoring a tombstone. Both mutate scope the user did not ask for; everything else is non-destructive and proven so. |
| **Duplicate rows (Q11)** | **Keep the row a live agent is attached to, otherwise the oldest**, and archive the rest. `paseo ls --json` reports each agent's `cwd`, so it is the same pass already run for the `busy` verdict. |
| Agent safety | **Never archive a workspace with a live agent in it.** A workspace whose `cwd` matches a non-idle agent is skipped with a reason. |
| **Modes (Q10)** | **Three: `list`, `sync`, `align`.** `auto` existed only to install the hook and dies with it. `align` is per machine; the other two are machine-wide reconciliation. |
| **`autoArchiveAfterMerge` (Q8)** | **Surfaced by `align`, recommended as an experiment, explicitly flagged unverified.** It only reaches workspaces where Paseo detected a PR, so `sync` still owns the general case. |
| `isPaseoOwnedWorktree` | **Documented as a known lie, not worked around.** The skill states that Paseo claims ownership of adopted worktrees, so the desktop app may offer to delete a worktree git owns. No CLI corrects the flag. |
| Directory page | Joins the existing **Git & GitHub** group in `skills.sh.json`, beside `orcakit`. No new group. |

## Approach

**What it reuses.** The worktree path convention, the branch grammar, the base-ref answer, and the teardown rules belong to `gitkit`; paseokit states its conclusions and never re-derives them. The mode shape — a read-only `list`, a writing mode, a one-time `align` — comes from `orcakit`, as does the "no tool on this box means no-op and stop" preflight stance. The hand-off's three beats and the procedural register come from the repo conventions.

**Rejected approaches**, one line each: *a `post-checkout` hook* — verified working, and cut anyway because the owner prefers no writes into `.git/hooks` and is content to sync by hand. *A cron job* — no cron on the target box, and polling is the wrong shape for a job that has an exact trigger. *`paseo schedule`* — runs a full agent on a cadence, spending tokens forever on one existence check and one create. *A long-running watcher* — nothing supervises it, and it dies on the next redeploy. *Teaching `gitkit` to call Paseo* — `gitkit` must keep working where no such tool exists, and its own notes forbid calling in that direction. *Merging with `orcakit` behind an adapter* — the two tools have opposite models, so the adapter would be most of the skill.

### Phase 1 — Preflight (every mode)

- `paseo status` — CLI installed, daemon reachable? **Not installed means stop**, in one sentence. Worktrees are fine without Paseo and nothing else depends on this skill.
- Daemon unreachable → name `paseo start` and stop. Do not start a daemon on someone's machine unasked.
- Read `~/.paseo/projects/projects.json` and build the map of live projects. An unreadable or unexpectedly shaped file degrades every writing mode to read-only; say which and why rather than guessing at ids.
- `gh` missing or unauthenticated → titles fall back to the branch slug and the tracker column reads "unknown". Nothing else degrades, because unlike `orcakit clean` no operation here is gated on proving a merge.

### Phase 2 — Mode `list`

Read-only. Changes nothing, asks nothing, and is the right first move whenever the state is unclear.

Join three sources: `git worktree list --porcelain` per project, `paseo workspace ls --json`, and `gh` for the tracker. Match on **absolute path**, the only key both git and Paseo record. Skip anything with no symbolic HEAD. Give every row a verdict:

| verdict | means | fix |
|---|---|---|
| `registered` | worktree exists, exactly one active workspace points at it | nothing |
| `unregistered` | worktree exists, no workspace points at it | `sync` |
| `orphaned` | workspace points at a path that no longer exists | `sync` |
| `duplicate` | two or more active workspaces share one `cwd` | `sync` |
| `tombstoned` | worktree exists, and its only row is archived | `sync`, which offers to restore |
| `unknown repo` | worktree under `$WORKTREE_ROOT` whose repo Paseo has never seen | `sync`, on confirmation |
| `stray project` | workspace under a project whose `rootPath` is a worktree, not a repo | reported only; no CLI can delete a project |
| `busy` | a non-idle agent's `cwd` is inside this workspace | leave it |
| `reapable` | PR merged, issue closed, tree clean | `gitkit` teardown, then `sync` |

Put `busy` rows first when any exist, since those are where an action would interrupt live work.

### Phase 3 — Mode `sync`

The writing mode, and safe to run repeatedly by construction.

Straight through, no confirmation:

- **Register** every `unregistered` worktree with `paseo workspace create --isolation local --path "$WT" --project "$PROJECT_ID" --title "$TITLE"`.
- **Archive** every `orphaned` row. Proven non-destructive.
- **Collapse** duplicates to the agent's row, or the oldest when no agent is attached.
- **Retitle** rows whose title is still a bare branch name and whose issue `gh` can resolve, never touching a human-set title.
- **Skip** anything `busy`, naming the agent id in the report.

Gated on one confirmation each:

- **Unknown repos** — list them, then register the main checkout (which creates the project) and its worktrees on an OK.
- **Tombstones** — name them, restore on an OK, leave them alone otherwise.

Because `workspace create` is not idempotent, the existence check before each registration is load-bearing rather than an optimization. It must consider archived rows too, or the tombstone rule silently fails.

### Phase 4 — Mode `align`

One-time configuration, per machine.

- Check `worktrees.root` in `~/.paseo/config.json` against `$WORKTREE_ROOT` (`~/worktrees` unless the environment says otherwise). It already matches on the owner's box; it will not on a fresh machine. Aligning it only affects worktrees Paseo creates itself, so say that plainly rather than implying a migration.
- Surface `daemon.autoArchiveAfterMerge`. Setting it `true` would let Paseo archive a workspace when its change request merges, covering part of the reaping job natively. Recommend it as an experiment to observe, flag that it is undocumented, and note it only reaches workspaces where Paseo detected a PR.

### Phase 5 — Hand off

Report registrations, archives, retitles, and skips with reasons; name the paths; crown one next move. `busy` and `stray project` rows outrank everything else, because neither is fixable by running the skill again.

### Phase 6 — Land it in this repo

- `skills/paseokit/SKILL.md`, authored from scratch per `skillkit`.
- `docs/wiki/skills/paseokit.md`, with three mode sections and the provenance stamp.
- `paseokit` appended to the **Git & GitHub** group in `skills.sh.json`.
- A line in `orcakit`'s notes pointing at its sibling, and the reciprocal line in `paseokit`. Neither may call the other.
- `make lint` clean.

## Open questions

- **Does `autoArchiveAfterMerge` actually work?** Undocumented and untested. Worth flipping to `true` on the owner's box and watching one PR merge before the skill's recommendation hardens into a default.
- **How stable is the `projects.json` shape across Paseo versions?** The skill depends on it for every write. Decide whether preflight should validate the shape strictly and degrade, or fail loudly on a surprise.
- **Does on-demand prove tolerable?** If syncing by hand becomes friction, the hook research above is complete and the mode can be added back as `auto` without redoing it.
- **Should `sync` grow a `--dry-run`?** `list` covers most of that need, but the two would drift as `sync` gains gates.

## Non-goals

- **Creating or removing worktrees.** That is `gitkit`, always, and routing to it is the right answer whenever a worktree itself must change.
- **Installing git hooks.** Cut in the grill. paseokit writes nothing into any repo.
- **Touching the tracker.** paseokit reads issues and PRs to build a title and a verdict; it never closes, labels, or edits. Tracker drift routes to `issuekit close`.
- **Driving agents.** `paseo run`, `attach`, `send`, and the terminal and schedule surfaces belong to the `paseo` CLI.
- **Deleting stray projects.** No CLI exists in 0.4.0. Report them and name the manual fix — edit `~/.paseo/projects/projects.json`, restart the daemon — without performing it.
- **Replacing `orcakit`.** Both stay.
