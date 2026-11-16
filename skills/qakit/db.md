# qakit: data-layer rules

Each section names the qakit step it extends.

## Scope the feature: build one `DB_CMD`

Find the project's own database client and build one `DB_CMD`. Read `package.json`, `Gemfile`, the compose file, and `DATABASE_URL` to learn what this project runs. Write the real invocation, so `psql "$DATABASE_URL"`, `pnpm prisma db execute --stdin`, or `bin/rails runner`. Where the database answers only inside a container, fold the prefix into the same variable (`docker compose exec -T db psql -U app appdb`), and read the service name from the compose file. Every query block in the plan reads `$DB_CMD`.

This is done when `DB_CMD` holds one invocation that matches a client the project declares.

## Derive the test dimensions: data and state goes down to the database

Under **Data & state**, assert on the database as well as the screen: the new table and columns exist after the migration runs, a create writes the row the change promises *and* its join or child rows, an update changes the columns it claims and no others, a delete cascades as designed and leaves no orphan, and a unique or foreign-key constraint rejects a duplicate.

**A case that proves data integrity takes the higher tier.** When a case carries a checkpoint on a row, a relation, or a constraint, promote the whole case rather than tagging the checkpoint.

**A database check sorts on the human-or-agent seam by what produces the fact.** A **static** fact holds before anyone touches the app, so the agent confirms it: the table and its columns exist, the index and the constraint are present, the migration applied. A **mutation** fact only exists after the tester acts, so it belongs in that tester's case as a checkpoint under the step that caused it.

## Write the plan file: queries, Environment, and Reset

Add the client to **Environment**, once, above the launch command:

````markdown
Set the database client once. Every query below runs through it.

```sh
export DB_CMD='docker compose exec -T db psql -U app appdb'
```
````

**Every database assertion gets a runnable query, in its own ```sh block, through `$DB_CMD`.** Write the query itself, and use only the client **Environment** defines:

```sh
$DB_CMD -c "select o.id, o.total_cents, o.status, count(i.id) as items from orders o join order_items i on i.order_id = o.id where o.reference = 'QA-1001' group by o.id;"
```

Three rules for the query:

- **Select the columns the change is supposed to have written**, plus the join or child rows beside them, never a bare `count(*)`.
- **Query by the identifier the case itself created** (`reference = 'QA-1001'`), rather than by a global count, so the case survives a re-run.
- **Put the expected values in the checkpoint text, not in the query**: `- [ ] One order row exists, total 4500, status "paid", with 2 item rows`.

**A scenario whose cases write rows carries the cleanup in its Reset.** Put the truncate or the seed re-run in the **Reset** block, in its own ```sh block, so the tester restores the starting state once at the end of the scenario. Keep the cleanup out of the case bodies. The agent writes this block and never runs it, except on the disposable target that qakit's root names, where it runs the whole scenario and this Reset with it.

## Run the automated checks yourself: static facts, read only

**Name the database you are about to open, before you open it.** `DATABASE_URL` in a shell holds whatever the last person exported, and read-only is not a sufficient guard: a `SELECT` against production is still an unauthorized read of customer data. So resolve the host first, state it to the user, and connect when it is `localhost`, a loopback address, or a container service the compose file defines. For any other host, ask the user before the first connection. When they decline, write the queries into the plan for the human and leave that part of **Automated verification** unrun.

**A declared disposable target's database is the one write exception.** When the scenario runs on that target, the agent runs its write queries and its Reset there, under the same host check, and records the output in the case. Every other database stays read-only.

**Confirm the static facts by reading only.** Run four introspection checks: the new tables and columns exist with the declared types, the indexes are present, the constraints (unique, foreign key, not-null) are present, and the migration list shows the change applied. Run `SELECT` and catalog queries only. Paste each query you ran in its own ```sh block.

This is done when each of the four checks has a ✅ or ❌ line in **Automated verification**, or the plan says the host was not confirmed.
