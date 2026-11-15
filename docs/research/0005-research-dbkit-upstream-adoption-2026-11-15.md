# What dbkit should adopt from claude-code-templates' database components

Date: 2026-11-15. Status: report only. No dbkit file has changed.

## Scope

The source is [davila7/claude-code-templates](https://github.com/davila7/claude-code-templates) at commit `8c9a4a2` (2026-11-15). I read all three database folders under `cli-tool/components/`:

| Folder | Files | Content |
| --- | --- | --- |
| `agents/database/` | 12 | Subagent prompts: architect, migration specialist, optimizer, admin, Postgres, Neon, Supabase, NoSQL |
| `skills/database/` | 95 | Skills: schema design, migration, optimizer, read-only guard, Supabase rule set, Neon, AlloyDB, Cloud SQL, BigQuery |
| `commands/database/` | 9 | Slash commands, mostly Supabase, one Snowflake |

Every candidate below was checked against the dbkit text as committed in `cdef528` (`SKILL.md`, the four mode files, the three engine files, `orms.md`). When I say "dbkit has none", a search of those files found zero hits.

Licenses: the repo is MIT. `skills/database/supabase-postgres-best-practices` is MIT, author Supabase. `skills/database/postgres-schema-design` is Apache-2.0 (its LICENSE.txt still has the unfilled copyright placeholder). `skills/database/postgresql` is a near copy of that Apache file with no license of its own. The other files state no license and fall under the repo's MIT. dbkit's method of taking facts and rewriting every sentence keeps all of this clean, but the Credit line in `SKILL.md` names "three MIT-licensed skill sets" and has to change if we adopt anything.

## Verdict

About 110 of the 116 files add nothing. Most are keyword lists, vendor setup guides, or examples that break dbkit's own standard (`serial`, `timestamp` without a zone, a nullable `created_at`, an unbatched `UPDATE` inside a DDL migration). dbkit is already more exact than any of them on locks, `NOT VALID`, concurrent indexes, expand/contract, and plan reading.

The value sits in about six files, and it falls into three groups. The first group matters most: four holes in dbkit's safety guards, which no amount of schema knowledge covers. The second is one missing domain, multi-tenancy with row-level security. The third is a set of Postgres facts, one of which fixes a wrong row in dbkit today.

Three of the four analysis slices found the pooler gap independently, from three different files. That is the strongest single signal in this report.

## Tier 1: gaps in the guards

These change what dbkit does on a real database, so they come first.

### 1. Migrations through a transaction-mode pooler lose their lock timeout

dbkit opens every live-table migration with `SET lock_timeout = '5s'` (`engines/postgres.md`, "Timeouts and the lock queue"). Through PgBouncer in transaction or statement mode, a Neon `-pooler` host, Supabase port 6543, or AlloyDB's built-in PgBouncer, that `SET` runs as its own transaction. The next `ALTER` can land on a different server connection that has no timeout. The guard then does nothing, and nothing reports it. The `CONCURRENTLY` file is hit hardest, because it runs outside a transaction, where `SET LOCAL` is not available. A migrator's session advisory lock leaks the same way.

Sources: `agents/database/neon-expert.md:74-75`, `skills/database/neon-instagres/SKILL.md:19-20`, `skills/database/using-neon/references/features.md:101-102`, `supabase-postgres-best-practices/rules/conn-pooling.md:36-39`. Upstream states the "use the direct URL for migrations" rule. The link to dbkit's lock timeout is our own derivation.

Proposed change:

- `engines/postgres.md` "Timeouts and the lock queue": one bullet. A migration runs over a direct or session-mode connection, never a transaction or statement pooler.
- `SKILL.md` "Stack detection": name the URL the migrate script uses. A host that holds `-pooler`, port 6543, `?pgbouncer=true`, or a `directUrl`/`*_DIRECT` twin marks a pooled target.
- `modes/migrate.md` "Check the file as a whole": a sixth check, "the migrate command's URL is pooled". I prefer the verdict "safe with a change" over a refusal.

Keep the wording exact. Session-mode pooling is safe. PgBouncer 1.21+ tracks protocol-level prepared statements, so do not claim that prepared statements always break.

### 2. A loopback address can be production

The connection guard clears "`localhost`, a loopback address" with no question. With a Cloud SQL or AlloyDB Auth Proxy, an SSH tunnel, or `kubectl port-forward` running, `127.0.0.1:5432` is the production primary. dbkit would then run read queries against customer data with no confirmation. `EXPLAIN ANALYZE` stays protected, because it needs a declared disposable target. The read-only `SELECT`s do not.

Sources: `skills/database/cloud-sql-basics/SKILL.md:66-77`, `skills/database/alloydb-basics/references/core-concepts.md:20-25`. Upstream only shows the proxy on loopback. The guard gap is our finding.

Proposed change: in `SKILL.md` "The connection guard", clear loopback only when a compose service publishes the port, or when no proxy or tunnel process serves it (`ss -ltnp` or `lsof -i :5432`, looking for `cloud-sql-proxy`, `alloydb-auth-proxy`, `ssh`, `kubectl`). How strict to make this is a decision, listed below.

### 3. "Read only" is enforced by statement shape, not by the session

dbkit's rule says "Run `SELECT`, `EXPLAIN`, and catalog queries." Two failures get past that. A valid `SELECT` can have side effects (`pg_read_file`, `lo_export`, `dblink`, `set_config`, `pg_sleep`, MySQL `LOAD_FILE`, SQLite `load_extension`). A stacked string such as `COMMIT; DROP …` escapes a `BEGIN READ ONLY` wrapper, which was a real bug in the archived Postgres MCP server. dbkit runs SQL that comes from the user and from repo code, for example in `tune` and the pre-checks, so both cases are live.

Source: `skills/database/readonly-sql-guard/SKILL.md:13-36`. Its library pitch at lines 40-52 is not worth taking.

Proposed change to the **Read only** bullet:

- Send one statement per call, never a stacked string.
- Open the session read-only: Postgres `PGOPTIONS='-c default_transaction_read_only=on'`, MySQL `SET SESSION TRANSACTION READ ONLY`, SQLite `sqlite3 -readonly`.
- Refuse a statement that calls a function with side effects.
- Give the read session a `statement_timeout` (MySQL `max_execution_time`), so a full-scan pre-check count on a cleared production host stops in 30 seconds and goes to the user instead. This last point is our own inference; `sql-pro` only says "avoid heavy queries on production".

The one-statement rule must go with the session default, because a stacked `SET default_transaction_read_only = off` undoes it.

### 4. A destructive statement can pass as "safe", and its rollback is a restore

`modes/migrate.md` judges by lock class, so `DROP TABLE` with a lock timeout gets "safe". The deploy-order step then says "A rollback is a new forward migration". For `DROP TABLE`, `DROP COLUMN`, `TRUNCATE`, or a narrowing type change, no forward migration brings the data back.

Sources: `agents/database/schema-migration-specialist.md:44-45, 447, 493`, `agents/database/database-admin.md:20` ("untested backups don't exist").

Proposed change:

- `modes/migrate.md` "Build the risk table": a fourth verdict, "destroys data". Its rollback line reads "restore from backup", and the hand-off asks the user to confirm a tested backup.
- `engines/postgres.md` lock table: a `DROP TABLE` row (catalog only, contract step). Optionally rename to `_deprecated_<name>` one release first, so a straggler fails loudly and can be renamed back.

## Tier 2: missing coverage

### 5. Multi-tenancy and row-level security

dbkit has no tenant rules, and a cross-tenant leak is the worst schema defect there is. This was the main finding of the first pass on `agents/database/database-architect.md`. The Supabase rules add the performance half.

Engine-neutral, for a new `### Tenancy` heading in the schema standard:

- Every tenant-owned table carries the tenant key, not only the top table.
- Parents get `UNIQUE (tenant_id, id)`, and children reference them with a composite FK `(tenant_id, project_id)`. A plain `project_id` FK lets a row in tenant A point at a parent in tenant B.
- Uniqueness is scoped to the tenant, `UNIQUE (tenant_id, lower(email))`, unless the value is global.
- The tenant key leads the composite indexes.

Postgres, for a new `## Row-level security` section in `engines/postgres.md`:

- `ENABLE` and `FORCE ROW LEVEL SECURITY`. The owner skips RLS without `FORCE`, and many apps connect as the owner.
- Policy form `USING (tenant_id = (SELECT NULLIF(current_setting('app.current_tenant_id', true), '')::bigint))`. It fails closed when the setting is unset or left as `''` by a pooled connection.
- Wrap a row-independent function in a scalar subquery, as above or `(select auth.uid())`. The planner runs it once as an InitPlan instead of once per row. Do not copy upstream's `(select is_team_member(team_id))`: it passes a row column, so it stays correlated and still runs per row (`security-rls-performance.md:46-48`).
- Index every column a policy filters on.
- The app role has no `SUPERUSER` or `BYPASSRLS`.
- With a transaction pooler, set the tenant per transaction with `set_config(..., true)`.
- A view skips RLS unless created `WITH (security_invoker = true)`.
- A composite FK with `ON DELETE SET NULL` names the column, `SET NULL (project_id)` (PG 15+), or it nulls the tenant key too.
- `tune` asks for the plan under the app role (`SET ROLE app`). A plan run as the owner or a superuser skips the policies and shows a query that production never runs.

`modes/audit.md` severity: a tenant leak (no tenant key, a plain cross-tenant FK, RLS without `FORCE`) goes to the top of High.

### 6. SECURITY DEFINER functions without a fixed search_path

Without `SET search_path = ''`, a caller who can create objects in a schema on the path can take over the function's privileges. dbkit writes `updated_at` triggers, so it writes functions. Add a short "Functions and triggers" note to `engines/postgres.md`, with the companion `REVOKE EXECUTE ON FUNCTION … FROM PUBLIC` that upstream omits. In `audit`, a definer function with no fixed path is High. Source: `supabase-postgres-best-practices/rules/security-rls-performance.md:33-39`.

The same note can hold one more fact: `CREATE OR REPLACE FUNCTION` with a new argument list creates an overload and leaves the old signature in place (`skills/database/postgres-schema-design/SKILL.md:126`).

### 7. ORM schema sync at app start

dbkit's dev-only check looks for commands (`drizzle-kit push`, `prisma migrate reset`). A config flag gets past it: TypeORM `synchronize: true`, Sequelize `sync({ alter: true })`, Hibernate `ddl-auto=update`. Each changes the schema at boot with no migration and no lock timeout, and can drop columns. Add the flags to the dev-only bullet in `modes/audit.md` and `modes/migrate.md`. Source: `schema-migration-specialist.md:255` names TypeORM only.

`orms.md` also lacks TypeORM and Sequelize. TypeORM `migration:run` wraps all pending migrations in one transaction by default, with `--transaction each|none` and a per-migration `transaction = false`. sequelize-cli wraps nothing, so a multi-step file half-applies on failure. Verify both against current versions before adding them.

## Tier 3: Postgres facts

### Fix a wrong row

`engines/postgres.md:99` says a plain B-tree serves prefix `LIKE 'abc%'`. That holds only under the C collation. Under a typical `en_US.UTF-8` database the index needs `text_pattern_ops` (or `varchar_pattern_ops`). Found by the slice agent while it checked the upstream `LIKE` advice.

### Add to the lock table and version table

- Adding an identity column or a stored generated column rewrites the table.
- `int` to `bigint` rewrites the table. More `numeric` precision at the same scale does not, which is a second safe widening beside `varchar`.
- PG 18: a generated column without `STORED` is virtual by default. Adding one changes only the catalog, but PG 18 cannot index it. Confirm against the PG 18 release notes before shipping.
- `ADD COLUMN … DEFAULT now()` is instant on PG 11+, because `now()` is stable, not volatile. Every existing row gets the migration's transaction time, so a `created_at` added to an old table puts a false date on every old row. Upstream `postgres-schema-design:124` says `now()` forces a rewrite, which is wrong.
- `RENAME TO` for a table can ship in one transaction: `ALTER TABLE old RENAME TO new; CREATE VIEW old AS SELECT * FROM new;`. A simple view is auto-updatable since PG 9.3, so old code keeps reading and writing until the contract step drops the view. Caveat: `SELECT *` freezes the column list, and some ORMs object to a view without a primary key. Source: `schema-migration-specialist.md:40`.

### Add to the index types table

- `LIKE '%abc%'`, `ILIKE`, similarity → GIN with `gin_trgm_ops` (`pg_trgm`). dbkit names the leading `%` as a cause in its plan table but gives no fix.
- Full-text search uses the two-argument `to_tsvector('english', col)` in both index and query. The one-argument form is not IMMUTABLE, so an expression index cannot use it.
- An `EXCLUDE USING gist (room_id WITH =, period WITH &&)` constraint needs the `btree_gist` extension for the scalar `=` part.
- `jsonb_path_ops` gives a smaller GIN index but drops the key-existence operators `?`, `?|`, `?&`. Upstream says it supports only `@>`; it also supports `@?` and `@@`.

### Add to tune and audit evidence

- `pg_stat_statements` as the Postgres twin of the MySQL digest query dbkit already has: `SELECT queryid, calls, total_exec_time, mean_exec_time, rows, query FROM pg_stat_statements ORDER BY total_exec_time DESC LIMIT 20`. Mark it "needs production stats". The columns are `total_time`/`mean_time` before PG 13.
- `ANALYZE` the table after a large backfill, and after a new expression index, which has no statistics until then. The read-only proof for the "estimated rows off by 10×" row is `last_analyze`, `last_autoanalyze`, `n_mod_since_analyze` from `pg_stat_user_tables`.
- Before a migration, find the sessions that will block it: `SELECT pid, state, xact_start, query FROM pg_stat_activity WHERE xact_start < now() - interval '1 min'`. These are the "slowest open transaction" that dbkit's lock-queue section warns about.

### Add to the migration rules

- Pre-check a narrowing type change: count the values that do not fit (`length(col) > N`) before shrinking. dbkit counts NULLs, duplicates, and orphans, but not this.
- In the expand step, a column that code is about to stop writing must lose its `NOT NULL` or gain a default first. Otherwise inserts fail during the deploy.
- `RESET` the timeouts at the end of a file that runs outside a transaction, and make every file safe to rerun.
- State the reason for the "not yet done" predicate in the batched backfill (`AND total_cents IS NULL`). It makes a rerun idempotent, and in READ COMMITTED it is rechecked after a row-lock wait, so the batch does not overwrite a concurrent app write.

### Smaller rules

- Case-insensitive uniqueness for emails and handles: a unique index on `lower(email)`, or `citext`.
- `ON DELETE CASCADE` on a table with history (orders, invoices, audit log) is High in `audit`.
- Keyset pagination carries every sort column plus a unique tie-breaker, `WHERE (created_at, id) > ($1, $2)`, with an index on `(created_at, id)`.
- Name the N+1 fix form: `WHERE user_id = ANY($1::bigint[])`, one statement shape, or the ORM's eager load.
- A deferrable unique constraint cannot be an `ON CONFLICT` arbiter. Relevant only if dbkit adds `DEFERRABLE` for circular FKs.

## Decisions for the owner

1. **Loopback strictness** (Tier 1, item 2). Option A: run the process check, and ask when a proxy or tunnel is found. Option B: ask on every loopback host that is not a compose service. I prefer A. B adds a question to almost every local run.
2. **A Neon branch as a disposable target.** dbkit already admits it with no guard change. gitkit `prepare` can declare a `setup:` command that runs `neonctl branches create` and a `teardown:` that deletes it, so the repo creates the database, not dbkit. I recommend one line that documents this route, and no new dbkit verb. Two sub-questions follow. Should a host that matches the URL `prepare` wrote count as cleared, so every run does not ask? I say yes. A branch copies production data by default, so should a disposable branch of production need explicit consent or be schema-only? Schema-only gives empty tables, and `tune` then rejects its plans for the row-count rule.
3. **Squawk lint** in `migrate` check, used only when the project already has it. It is static and needs no database. I recommend it.
4. **Per-table autovacuum settings.** `ALTER TABLE … SET (autovacuum_vacuum_scale_factor = 0.05)` is table DDL, not a server setting, so dbkit's "name settings, never propose them" rule does not clearly cover it. I would keep it as a named cause.
5. **A privileges check in `audit`**: the app connects as a superuser or as the table owner, or a migration runs `GRANT ALL`. It overlaps with the RLS work. I would add it as part of Tier 2, item 5.
6. **Credit line.** Adopting from the Supabase rules (MIT) and `postgres-schema-design` (Apache-2.0) means the Credit in `SKILL.md` must name them with a commit and stop saying "three MIT-licensed skill sets".

## Rejected

- **Scratch database "prove it"** (`database-architect.md`, Snowflake command). It breaks "dbkit never creates a database" and "no mode applies a migration".
- **Down migrations as the rollback** (`schema-migration-specialist.md:443-446`, `database-migration`). It conflicts with forward-only. Tier 1, item 4 covers the true exception.
- **Server and pool settings** (`conn-limits`, `conn-idle-timeout`, `postgresql-optimization`, the optimizer and admin agents). They conflict with dbkit's settings rule, and `conn-limits.md` gets its own `work_mem` arithmetic wrong.
- **App-code concurrency** (`lock-deadlock-prevention`, `lock-advisory`, `lock-short-transactions`, `data-batch-inserts`). These are application design, outside a schema and migration skill.
- **Choosing a database, NoSQL, warehouses** (`nosql-specialist.md`, `bigquery-basics`, Snowflake). Out of scope. `nosql-specialist.md` also unpickles Redis data and uses removed MongoDB options.
- **Vendor setup** (Neon, AlloyDB, Cloud SQL, Neon Auth, the Supabase commands). Provisioning, IAM, and SDK reference. `neon-instagres` also carries a referral code and recommends `prisma db push` and TypeORM `synchronize: true`.
- **Upstream errors**, kept here so nobody adopts them later:
  - The three-step NOT NULL that ends in `SET DEFAULT, SET NOT NULL` (`schema-migration-specialist.md:116-127`) scans under `ACCESS EXCLUSIVE` and leaves a window for new NULL rows.
  - "Wrap all migrations in transactions" (`supabase-schema-architect.md:70`) breaks `CONCURRENTLY`.
  - "Composite index, most selective first" (`postgres-schema-design:76`) loses to dbkit's equality, range, sort order.
  - "FKs from partitioned tables are not supported" (`postgres-schema-design:93`) is outdated since PG 11.
  - "Plain VACUUM locks the table" (`schema-partitioning.md:23`) is wrong.
  - The FK-index catalog query in `schema-foreign-key-indexes.md:55` misses non-leading covers; dbkit's query is better.

## Per-file verdict

| File or group | Verdict | Feeds |
| --- | --- | --- |
| `agents/database/database-architect.md` | Useful | Tier 2 item 5, several Tier 3 facts |
| `agents/database/schema-migration-specialist.md` | Useful, with an outdated flagship example | Tier 1 item 4, items 7, rename via view, narrowing pre-check |
| `agents/database/neon-expert.md` | One fact | Tier 1 item 1 |
| `agents/database/postgres-pro.md` | Keyword list | Leads for `pg_stat_statements`, `pg_trgm` |
| Other 8 agents | Filler, ops, or out of scope | None |
| `skills/database/postgres-schema-design` (Apache-2.0) | Useful | Most index and version facts |
| `skills/database/postgresql` | Copy of the above | Cite the original |
| `skills/database/readonly-sql-guard` | One point | Tier 1 item 3 |
| `skills/database/supabase-postgres-best-practices` (MIT) | Partly useful; `AGENTS.md` is a generated copy of `rules/` | Tier 2 items 5 and 6, tune evidence |
| `skills/database/database-architect`, `database-migration`, `database-optimizer`, `postgresql-optimization`, `sql-pro` | Low quality; `database-migration` examples are unsafe | Reminder that `orms.md` lacks TypeORM and Sequelize |
| `skills/database/using-neon` | Partly useful | Tier 1 item 1, decision 2, serverless HTTP driver note |
| `skills/database/cloud-sql-basics`, `alloydb-basics` | One fact each | Tier 1 item 2 |
| `skills/database/neon-instagres` | Negative example | Direct URL for migrations |
| `skills/database/bigquery-basics` | Out of scope | None |
| `commands/database/*` (9) | Filler; several apply or push migrations | None |

Two low-value notes did not make the tiers. Serverless HTTP drivers (`drizzle-orm/neon-http`) cannot run an interactive `BEGIN … SET LOCAL … COMMIT`, which matters only for a custom backfill script. A plan from a just-resumed serverless compute reads a cold cache, so read the second run.

## Next

Take Tier 1 first, as its own change, because it closes guard holes and touches few lines: `SKILL.md` "The connection guard" and "Stack detection", `engines/postgres.md` "Timeouts and the lock queue", and `modes/migrate.md`. Settle decision 1 before that edit. Tier 2 item 5 is large enough for a short plan. Tier 3 can go in as one batch edit to `engines/postgres.md`, including the `text_pattern_ops` fix.
