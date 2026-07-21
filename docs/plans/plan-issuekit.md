# Plan — `issuekit`

Own the GitHub issue lifecycle across the dev workflow as a single public skill with three explicit modes. Hardened via grillkit on 2026-07-21.

## What it is

A public (`internal: false`) skill following this repo's `kit` conventions. One `SKILL.md`, one skill, **three modes** — `create`, `sync`, `triage`. When invoked without a mode, issuekit asks the user which of the three they want (menu with options). This keeps the single `issuekit` node in the [IDEAS.md](../../IDEAS.md) workflow diagram honest — it appears at three points (entry triage, create-from-plan, PR→issue sync) because it *is* three modes of one skill.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Structure | One skill, explicit modes; no-mode → ask user which mode |
| Mode set | `create`, `sync`, `triage` (3). "Comment" is a shared action, not a mode |
| Create input | A `plan-*.md` (main path) **or** a plain description (ad-hoc single issue) |
| Create decomposition | Parse plan → **preview table** of proposed breakdown → user edits/approves before any issue is created |
| Parent→child links | Try native GitHub sub-issues via `gh api`; fall back to `- [ ] #123` task-list in parent body; report which path was used |
| Plan write-back | After creation, annotate the `plan-*.md` with new issue numbers next to each task |
| Sync scope | Reconcile drift + repair missing link + tick parent checklist; labels only if a scheme already exists |
| Sync closing an issue | **Preview + confirm** before closing — never auto-close |
| Triage behavior | Report-first (read-only pass), then offer fixes the user approves before mutation |
| Safety stance | Every GitHub-mutating action is outward-facing → preview/confirm first; nothing mutates unprompted; never merges PRs |
| `allowed-tools` | `Bash, Read, Edit` (Edit for plan write-back) |

## Modes

### Mode 1 — `create` (workflow entry: plan → issues, or start fresh)

- **Inputs:** two paths.
  - **Plan path:** a `plan-*.md`. Discovery precedence: explicit path in the prompt → newest `docs/plans/plan-*.md` → ask.
  - **Ad-hoc path:** a plain description → one well-formed issue (the "start fresh" entry point in the workflow diagram).
- **Decompose (plan path):** parse the plan's structure (phases/milestones/tasks) and present a **preview table** of the proposed breakdown — parent epic + N children, or a flat list, chosen per plan. User edits/approves **before anything is created**. Guards against spamming a repo with noisy auto-generated issues.
- **Parent→child links:** attempt native GitHub sub-issues through `gh api` (REST `/issues/{n}/sub_issues` or GraphQL). If the call fails (feature disabled, old GHES, insufficient perms), degrade to a `- [ ] #123` task-list checklist in the parent body and tell the user which path was taken.
- **Plan write-back:** after creation, edit the `plan-*.md` to add issue refs next to each task (e.g. `Phase 2 — auth (#43)`), keeping the plan the source of truth. This is why `Edit` is in `allowed-tools`.
- **Comment action:** may post the plan/decision as a comment on the created issue(s).

### Mode 2 — `sync` (reconcile / repair — NOT forward-linking)

Deliberately does **not** establish the forward `Closes #N` link on a fresh PR — that is `prkit`'s job at PR-open time. Sync earns its place only where the automatic chain breaks:

- **Reconcile:** find merged PRs whose linked issue didn't auto-close (keyword was missing) and close the issue with a comment linking the PR. **Preview + confirm before closing.**
- **Repair:** add a missing `Closes #N` to an *existing* open PR body.
- **Checklist:** tick a parent's `- [ ] #child` box when a child issue closes (the task-list fallback doesn't auto-tick; native sub-issues do).
- **Labels:** move issues through status labels only if the repo already uses such a scheme; otherwise skip silently.

**Handoff with prkit (no overlap):**

| Who | Owns |
|-----|------|
| `prkit` | write `Closes #N` into a *new* PR at open time (forward, happy path) |
| `issuekit` sync | reconcile drift after merge, repair a missing link on an *existing* PR, tick parent checklists, labels only if the repo uses them |

### Mode 3 — `triage` (report-first)

- **Read-only pass by default:** list open issues and flag drift as a status report — stale issues, orphaned issues, closed-parent/open-children, missing labels, status cross-checks.
- **Then offer fixes:** relabel, reprioritize, close stale, post a decision comment — each approved by the user before anything mutates.

## Cross-cutting conventions (baked in, not per-mode)

- **Comment** ("post a plan/decision as a comment") is a shared action available where it fits (create, triage), not a standalone mode.
- **Preflight** like prkit: verify `gh` is installed, authenticated (`gh auth status`), and a repo is detected before mutating.
- **Portability / graceful degradation:** with no shell or `gh` available (e.g. browser-based agent), print the `gh` commands for the user to run instead of failing. Self-contained, no repo-relative links, machine/OS-agnostic — required for a public skill per AGENTS.md.
- **Never** merge PRs. Never mutate GitHub state unprompted.

## Non-goals

- Not a PR authoring tool (that's `prkit`) — sync does not open PRs or write forward links on fresh PRs.
- No auto-triage that mutates the tracker without approval.
- No first-class status-label workflow when the repo has no label scheme.

## Build checklist (for `/skillkit`)

- [ ] Author `skills/issuekit/SKILL.md` with `metadata.internal: false`, `allowed-tools: Bash, Read, Edit`.
- [ ] Description front-loads an English "Use when …" trigger (create issues, sync PR↔issue, triage the tracker).
- [ ] Document the three modes + no-mode menu, the create preview/write-back, the native→task-list fallback, and the prkit handoff.
- [ ] Add `issuekit` to the appropriate group in `skills.sh.json` (public skill).
- [ ] On ship: delete the `issuekit` row from `IDEAS.md` and add it to the README Skills table.
- [ ] `make lint` passes.
