# Plan: qakit database-level checks

Grilled: 2026-09-19

## Context

`skills/qakit/SKILL.md` generates a manual QA plan from the diff. Its **Data & state** dimension (SKILL.md:44) names persistence, idempotency, create/update/delete and orphaned state, but every one of those is phrased at the surface: reload the page, hit the endpoint again, look at the screen. Nothing tells the agent to look at the database itself.

That gap matters for the failure class the UI hides. A create that writes the parent row and silently skips the join row, a delete that leaves an orphan, a migration that ships a table the code never reaches, a unique index that was declared but never created: each of those passes a screen-level QA pass and breaks in production. The tester has the shell open already, so the cost of one query in the middle of a case is one copy-paste.

Success: a QA plan for a feature that touches the data layer carries database assertions, the assertions sit where the tester can act on them, and a feature with no database work produces exactly the plan it produces today.

## Design decisions (settled)

| Decision | Resolution |
|----------|-----------|
| Separate database section, or inline checkboxes? | Both, split by what produces the fact. A **static** fact (a table exists, a column has the right type, a migration applied, an index is present) does not depend on a tester action, so it goes in **Automated verification** and the agent runs it. A **mutation** fact (this click added one row here and one row there) only exists after the human acts, so it is a checkpoint under that step. This is qakit's existing human-only / agent-verifiable seam (SKILL.md:59), applied to SQL. |
| Does an inline query break the "no command-and-check-output as a manual case" rule? | No. The rule bars a command *as a whole case*. A command inside a step with its own checkpoint is already the documented shape (SKILL.md:138-144). The database query is the same shape as the `curl` rule (SKILL.md:229). |
| New dimension, or extend **Data & state**? | Extend. A separate "Database" dimension would split one concept across two rungs, and the dimension list is already 11 long. Co-locate. |
| Which database client does the plan name? | The agent discovers the project's own client and writes it literally. It reads `package.json`, `Gemfile`, the compose file, and `DATABASE_URL`, then defines `DB_CMD` once in **Environment**. Every later block reads `$DB_CMD -c "…"`, so no plan carries a placeholder the tester must guess at. |
| A database reachable only inside a container? | `DB_CMD` absorbs the prefix, so **Environment** holds `DB_CMD="docker compose exec -T db psql -U app appdb"` and every case block stays identical. One variable carries the whole difference between a host client and a container client, and the agent reads the service name from the compose file. |
| What does a mutation assertion query? | The columns the change is supposed to have written, plus the join or child rows. A bare count passes a write that saved the wrong value. The expected values go in the checkpoint text, not in the query. |
| Priority of a database checkpoint | The case takes the higher tier. A case whose checkpoint proves data integrity is promoted rather than tagged, so one tier per case still holds and the glance table stays true. |
| Who cleans up the rows a case writes? | The scenario's existing **Reset** block gains the truncate or seed re-run, and the human runs it; the agent never does. Alongside it, the rule tells the agent to query by the identifier the case itself created rather than by a global count wherever it can, so a leftover row does not break the next pass. |
| When does the dimension fire? | When the diff touches the data layer: a migration, a schema file, a model, or a query. Otherwise the dimension is skipped and named under *Not covered*, exactly like every other dimension. |
| What stops the agent querying production? | A target-host confirmation before the first connection. The agent resolves the host, states it, and connects only to `localhost`, a container service, or a host the user confirms. Read-only is not a sufficient guard on its own, because a production `SELECT` is still an unauthorized connection to customer data. |
| Does the agent run the mutation queries itself? | No. It runs read-only introspection for **Automated verification** and writes nothing. The existing destructive-command ban (SKILL.md:236) already covers a drop or a reset; this adds `SELECT`-only as the explicit positive. |
| Does the `description` change? | No. The existing triggers already cover a QA pass on a migration, and a database check is a dimension inside the same job rather than a new branch. The wiki page and the cheatsheet carry the news to the human. |
| What when there is no database? | The dimension is skipped like any other, and named under *Not covered*. No new machinery. |

## Approach

Edit `skills/qakit/SKILL.md` in place, then its wiki page, then regenerate the cheatsheet. Reuse what is there: the dimension list, the agent-verifiable split, the `curl` rule as the template for the query rule, the scenario **Reset** block, and the `docs/qa/` artifact convention. No new file inside `skills/qakit/`, because every branch of the skill walks the whole body — the branch test in `AGENTS.md` keeps this in one file.

### Phase 1: extend the Data & state dimension and its trigger (built 2026-09-19)

Rewrite the **Data & state** bullet (SKILL.md:44) to name the database layer explicitly: schema presence after a migration, the rows a create is supposed to write, the join or child rows beside them, cascade behavior on delete, absence of orphans, and a unique or foreign-key constraint that must reject a duplicate. Keep it one bullet.

State the firing condition in the same bullet: the database half applies when the diff touches a migration, a schema file, a model, or a query, and is otherwise skipped and named under *Not covered*.

Add one sentence to the **Split human-only from agent-verifiable** paragraph (SKILL.md:59) stating the static/mutation seam from the decisions table, so the agent sorts a database candidate the same way it sorts any other.

Add one sentence to the prioritize block (SKILL.md:51-57): a case whose checkpoint proves data integrity takes the higher tier.

Done when: the dimension bullet names schema, rows, relations, and constraints; it states its own firing condition; the split paragraph names which facts the agent runs and which reach the human's checklist; the prioritize block carries the promotion rule.

### Phase 2: add the `DB_CMD` discovery and the query rule (built 2026-09-19)

Extend [Scope the feature](#1-scope-the-feature) with the client discovery: read `package.json`, `Gemfile`, the compose file, and `DATABASE_URL` to find the project's own client, and build a single `DB_CMD` that already carries any container prefix.

Add the connection line to the **Environment** section of the plan template (SKILL.md:90-104), beside base URL and credentials, with the `DB_CMD` assignment in its own `sh` block.

Add a rule to the *Rules for good cases* list (SKILL.md:195-229), directly after the `curl` rule and in the same form:

- Every database assertion gets a runnable query in its own `sh` block, invoked through `$DB_CMD`, never described in prose.
- The query selects the columns the change is supposed to have written, plus the join or child rows. The expected values go in the checkpoint text.
- Query by the identifier the case itself created, rather than by a global count, so a leftover row from an earlier pass does not fail the check.
- One checkpoint per judgment still applies: "the order row and its two line-item rows all exist with the right totals" is one look at one result, so one box.

Extend the scenario **Reset** guidance (SKILL.md:157-161) so a scenario with mutation cases carries its truncate or seed re-run in Reset, written for the human.

Done when: the rule sits beside the `curl` rule, the template's Environment block defines `DB_CMD`, the rule's example is a real copy-paste command, and the Reset guidance names the database statement.

### Phase 3: add schema introspection and the target-host guard (built 2026-09-19)

Extend [Run the automated checks yourself](#5-run-the-automated-checks-yourself) (SKILL.md:231) with the read-only database checks: table and column existence, index and constraint presence, and the applied-migration list. State the positive bound explicitly — the agent runs `SELECT` and introspection only, and writes nothing. Paste the exact query it ran, the same way the `curl` rule already requires.

Add the target-host guard beside the two existing hard exclusions (SKILL.md:234-239): resolve the host before the first connection, state it, and connect only to `localhost`, a container service, or a host the user confirms.

Add a line to the **Notes → Scope of shell use** paragraph (SKILL.md:248) so the declared shell surface stays true.

Done when: the step names the four introspection checks, states the read-only bound as a positive, carries the host guard, and the scope note matches.

### Phase 4: update the wiki page and the cheatsheet (built 2026-09-19)

Update `docs/wiki/skills/qakit.md`: the dimension list at `## The dimensions`, the split explanation at `## The split that makes it useful`, the exclusion list at `## Two commands it will never run` (now three), and `## The plan shape` where Environment changed. Write the *why*, not the procedure — the reason the static/mutation seam falls where it does, and why a read-only query still needs a host confirmation, are the page's job.

Re-stamp the provenance line only after re-reading the edited `SKILL.md`. Run `make cheatsheet`, then `make lint`.

Done when: `make lint` passes clean and the page describes the seam a reader could not infer from the rules.

## Open questions

None. Every question this plan raised is settled in the table above.

## Non-goals

- Writing or running automated database tests. That stays with **testkit**.
- Any write, migration, seed, or reset executed by the agent. The existing ban holds and widens.
- A database mode, flag, or satellite file inside `skills/qakit/`. This is one dimension and two rules, not a branch.
- Teaching the agent a schema-diff tool or a migration linter.
- A change to qakit's `description`.
