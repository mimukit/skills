# Plan: dbkit upstream adoption

Grilled: 2026-11-15

## Context

[The research report](../research/0005-research-dbkit-upstream-adoption-2026-11-15.md) compared all 116 database files in `davila7/claude-code-templates` (commit `8c9a4a2`) with dbkit as committed in `cdef528`. Most of the upstream material adds nothing, but it exposed four holes in dbkit's guards that no schema rule covers:

- A transaction-mode pooler drops the `SET lock_timeout` that every live-table migration opens with.
- The connection guard clears any loopback address, which can be a proxy or tunnel to production.
- "Read only" depends on the statement's shape, not on the session, so a stacked string or a `SELECT` with side effects gets through.
- A `DROP TABLE` can earn the verdict "safe", and its rollback line claims a forward migration can undo it.

The report also found one missing domain (multi-tenancy with row-level security), one wrong row (`engines/postgres.md:99`, prefix `LIKE` on a B-tree), and about twenty Postgres facts.

The goal is that dbkit stays safe on the databases people actually run: pooled, proxied, multi-tenant Postgres. Being complete for its own sake is not the goal. The check is mechanical, because this is a docs-only change to one skill: every report item marked adopt has a home in dbkit, `make lint` passes, and the size caps below hold.

Target (proposed; baseline from `wc -w` on 2026-11-15): the root stays at or under 3,000 words (baseline 2,794), and every Postgres run reads at most 6,500 words (baseline 5,551, the `migrate` run). A Postgres run is the root, one mode file, and the Postgres engine files that mode reads. It does not count `tenancy.md` or `orms.md`, which load only on their own branches. This per-run cap replaces the 9,000-word whole-skill cap from the dbkit plan. A whole-skill total only goes up as rules arrive, and it measures nothing an agent actually reads. The current skill already sits 19 words under the old cap. The new cap is 6,500, not 6,000, because the `tune` run comes out near 6,400 words by estimate after the split in Phase 4.

## Design decisions (settled)

These follow the report's recommendations, which the owner accepted as the defaults on 2026-11-15. The grill on the same day settled the rows marked "grill Qn". Q1 to Q4, Q13, and Q14 were asked. The others were defaulted.

| Decision | Resolution |
|----------|-----------|
| Scope | All of Tier 1, Tier 2, and Tier 3 in the report, plus decisions 1 to 6 at their recommended defaults. The report's "Rejected" list stays out. |
| Tenancy placement | A new satellite, `skills/dbkit/tenancy.md`. The root's schema standard gains a short `### Tenancy` heading that holds the four engine-neutral rules and one pointer, read when the schema has a tenant key or the ask names tenants. This passes the branch test in AGENTS.md: only tenant schemas need the RLS material, so it sits behind a pointer, while every design run needs the four rules. The Postgres RLS facts live in `tenancy.md`, not in `engines/postgres.md`, so a single-tenant Postgres run does not load them. MySQL and SQLite have no RLS, so `tenancy.md` states that in one line and keeps only the composite-FK rules for them. |
| Size caps | The root stays at 3,000 words. Tier 1 adds about 250 words to the root, so the same phase compacts existing root text to make room. Each Postgres run, as defined in Context, stays at or under 6,500 words. The per-run cap replaces the whole-skill cap. It is measured for each mode by `wc -w` on `SKILL.md`, `modes/<mode>.md`, `engines/postgres.md`, and that mode's Postgres satellite. |
| Mode structure | dbkit keeps its four modes and stays one skill. Every mode shares the connection guard, stack detection, the schema standard, and the engine files, and a split would leave the guard in two copies that drift. Tenancy is a branch of `design` and `audit`, not a moment a person chooses, so it goes in a satellite, not a new mode. `migrate` keeps write and check together, because `design` and `migrate` write both call check as their last step. |
| Postgres engine split | `engines/postgres.md` splits by the mode that reads each section. This is the branch test in AGENTS.md. `engines/postgres-tune.md` takes "Reading a plan for tune" (319 words today) and the new tune evidence queries. `engines/postgres-audit.md` takes "Catalog queries for audit" (174 words today) and the new audit queries. Locks, timeouts, concurrent builds, backfill, version limits, types, index types, partitioning, and functions stay in `engines/postgres.md`, because `design`, `migrate`, and `audit` all read them, and `tune` reads index types. `engines/mysql.md` and `engines/sqlite.md` stay whole at about 330 words each. |
| Loopback strictness (decision 1) | A process check. Clear loopback when no `cloud-sql-proxy`, `alloydb-auth-proxy`, `ssh`, or `kubectl` process listens on the port. The check uses `ss -ltnp` on Linux and `lsof -nP -iTCP:<port> -sTCP:LISTEN` on macOS. Both list the user's own processes without root (grill Q9). Ask when a proxy or tunnel is found, or when neither tool runs. |
| Compose services (grill Q1) | A compose service clears its published port only when its `image:` is a database engine (`postgres`, `mysql`, `mariadb`, `pgvector/pgvector`, and similar). A proxy or tunnel image asks, and so does an image the check cannot classify. A compose file can define a `cloud-sql-proxy` service, and clearing every service would reopen the loopback hole. |
| Pooled migrate URL | A finding with the verdict "safe with a change" (use the direct or session-mode URL). It is not a refusal. Session-mode pooling counts as safe. |
| Destructive statements | A fourth verdict, **destroys data**, for `DROP TABLE`, `DROP COLUMN`, `TRUNCATE`, and a narrowing type change. Its rollback line reads "restore from backup". The rename-to-`_deprecated_` step is optional and offered, never required. |
| Backup before a destructive step (grill Q2) | dbkit asks no question, because it never applies the migration and cannot verify a backup. The deploy-order list marks the step `destroys data, restore from backup`, and the hand-off tells the deployer to confirm a tested backup before deploying that step. |
| **destroys data** in the fix loops (grill Q5) | It is not a fixable verdict. In `design` "Check the generated migration" and `migrate` "Check the written files", it counts as "a stated reason for the user to decide", so the loop ends on an intended drop. |
| Read-only enforcement | One statement per call, a read-only session, a refusal list of side-effect functions, and a read `statement_timeout` of 30 seconds. On a timeout, the query goes to the user. |
| Read-only session mechanism (grill Q7) | `DB_CMD` carries the read-only option: Postgres `PGOPTIONS='-c default_transaction_read_only=on'` (`docker compose exec -e PGOPTIONS=…` for a compose service), MySQL `--init-command='SET SESSION TRANSACTION READ ONLY'`, SQLite `-readonly`. A runner that takes no such option gets each single statement wrapped in `BEGIN READ ONLY … ROLLBACK` by dbkit itself. |
| Side-effect functions (grill Q8) | A short list of named examples (`pg_read_file`, `lo_export`, `dblink`, `set_config`, `pg_sleep`, `LOAD_FILE`, `load_extension`). The read-only session is the real guarantee, because no deny-list is complete. |
| Read timeout scope (grill Q10) | 30 seconds on every host except a declared disposable target, where a slow count does no harm. |
| Tenancy trigger (grill Q4) | A run reads `tenancy.md` when a column such as `tenant_id`, `organization_id`, `org_id`, `workspace_id`, `account_id`, or `team_id` references one table from three or more tables, or when the ask names tenants. The rule sits on the root's `### Tenancy` pointer line, so `design` and `audit` apply the same test. |
| `audit` reads tenancy (grill Q6) | `audit` "Sweep against the standard" reads `tenancy.md` under the tenancy trigger. Without it, `audit` would rank a tenant leak by rules it never read. |
| Squawk detection (grill Q11) | "Declares" means `squawk-cli` or `squawk` in a package manifest, or a `.squawk.toml` file in the repo. |
| Facts with no web access (grill Q12) | When the build session cannot fetch the vendor docs, it drops the unverified fact and lists it in the phase's commit body. |
| Per-run cap overflow (grill Q15) | When a Phase 4 count exceeds 6,500 words, first move the next section that only some modes read into a satellite (for example, partitioning, which only `design` and `audit` use). Then trim wording. Raise the cap only with the owner's approval. |
| Outward actions (grill Q13, Q3) | The build commits each phase directly on `main` with a Conventional Commits subject, and pushes after each commit. A push is the only backup on this box. There is no branch, no worktree, and no PR. The owner approved this on 2026-11-15. |
| Phase 5 timing (grill Q14) | The owner runs Phase 5 on `main` after Phase 4 is pushed. A failure gets a fix commit on `main`. |
| Neon branch as a disposable target (decision 2) | One line under "The disposable target". A gitkit `prepare` setup command may create the branch, so dbkit still creates nothing. The host in the URL that `prepare` wrote counts as cleared. A branch that copies production data needs the user's consent in the session. dbkit gets no new verb. |
| Squawk (decision 3) | `migrate` check runs Squawk only when the project already declares it (a dependency or a config file). dbkit never installs it. |
| Per-table autovacuum (decision 4) | `tune` names it as a cause, the same as a server setting. It never proposes it as a change. |
| Privileges check (decision 5) | Part of the tenancy work. `audit` flags an app that connects as a superuser or as the table owner, and a migration that runs `GRANT ALL`. |
| Credit (decision 6) | The Credit line names the new sources with commit `8c9a4a2`: `claude-code-templates` (MIT), `supabase-postgres-best-practices` (MIT, Supabase), and `postgres-schema-design` (Apache-2.0). The wording becomes "MIT- and Apache-2.0-licensed skill sets". dbkit keeps its method: facts only, every sentence rewritten. |
| Facts to verify before writing | Four facts come from model knowledge, not from upstream text: PG 18 virtual generated columns (virtual by default, not indexable), the TypeORM and Sequelize transaction behavior, PgBouncer 1.21+ protocol-level prepared statements, and the `pg_stat_statements` column rename in PG 13. Each is checked against the vendor's own docs, and the phase records the URL it read. A fact that fails the check is dropped. |
| Description and wiki | The description does not change, so `docs/wiki/cheatsheet.md` does not change. No hand-off route changes, so `docs/wiki/workflow.md` does not change. |

## Approach

Edit dbkit in place, in four content phases ordered by risk, then do one attended check. Each phase is one commit on `main`, pushed when it lands. Every addition reuses an existing heading where one fits:

- the root's [connection guard](../../skills/dbkit/SKILL.md), "The disposable target", "Stack detection", and the schema standard headings;
- `engines/postgres.md`'s lock table, "Timeouts and the lock queue", "Batched backfill", "Version limits", "Index types", and "Reading a plan for tune";
- `modes/migrate.md`'s risk table and whole-file checks;
- `modes/audit.md`'s severity list and dev-only bullet;
- `orms.md`'s per-tool sections.

There are three new files. `tenancy.md` is new material. `engines/postgres-tune.md` and `engines/postgres-audit.md` are made from sections moved out of `engines/postgres.md`.

Rejected alternatives:

- **Tier 1 only.** It closes the guard holes, but it leaves the wrong `LIKE` row and the tenancy gap in place, and the facts batch is cheap.
- **A separate `tenantkit` skill.** It fails the gate in AGENTS.md, because nobody chooses "tenant schema design" as a separate moment from schema design.

### Phase 1: guard gaps (built 2026-11-15)

- `SKILL.md` "The connection guard":
  - Rewrite **Read only** to the read-only enforcement rule, its session mechanism, the side-effect examples, and the read timeout scope from the decisions table.
  - Rewrite **Connect only to a cleared host** to add the loopback process check and the compose image rule.
- `SKILL.md` "Stack detection": add one bullet. Name the URL the migrate script uses. A host with `-pooler`, port 6543, `?pgbouncer=true`, or a `directUrl` or `*_DIRECT` twin marks a pooled target. Proxy and connector packages (`@google-cloud/cloud-sql-connector`, `cloud-sql-python-connector`, `google-cloud-alloydb-connector`) mark a managed target.
- `engines/postgres.md` "Timeouts and the lock queue":
  - A migration runs over a direct or session-mode connection.
  - A file outside a transaction ends with `RESET lock_timeout; RESET statement_timeout;`.
  - Every file is safe to rerun.
  - Add the blocking-session query on `pg_stat_activity`, filtered on `xact_start < now() - interval '1 min'`, for the user to run before the deploy.
- `engines/postgres.md` lock table: add a `DROP TABLE` row.
- `engines/mysql.md` and `engines/sqlite.md`: add the read-only session form to each file in one line, under the existing headings.
- `modes/migrate.md`:
  - "Build the risk table" gains the **destroys data** verdict.
  - "Check the file as a whole" gains a sixth check, a pooled migrate URL, and a seventh, Squawk findings when the project declares Squawk. The check count in its **Done when** line changes to match.
  - "Check the written files" treats **destroys data** as a stated reason for the user to decide, not a verdict to fix.
  - "Write the deploy order and rollback" marks each destructive step `destroys data, restore from backup`.
  - The hand-off tells the deployer to confirm a tested backup before deploying any step that destroys data. It asks no question.
- `modes/design.md` "Check the generated migration": the same treatment of **destroys data**.
- Compact existing root prose until the root is back under its cap. Change wording only, never a rule.

Done when: `make lint` passes; `wc -w skills/dbkit/SKILL.md` prints 3,000 or fewer; `grep -c` finds `default_transaction_read_only`, `pooler`, and `destroys data` in the skill (each at least 1); and `modes/migrate.md` "Check the file as a whole" lists seven checks, with a **Done when** line that names seven.

### Phase 2: tenancy, functions, and privileges (built 2026-11-15)

- `SKILL.md` schema standard: a `### Tenancy` heading with the four engine-neutral rules (tenant key on every tenant-owned table, `UNIQUE (tenant_id, id)` with composite FKs, tenant-scoped uniqueness, tenant key leading composite indexes) and the pointer to `tenancy.md`. The pointer line states the tenancy trigger from the decisions table.
- New `skills/dbkit/tenancy.md` holds:
  - The Postgres RLS rules: `ENABLE` and `FORCE`, the `NULLIF(current_setting(…, true), '')` policy form, a scalar subquery around row-independent functions, an index on every policy column, no `SUPERUSER` or `BYPASSRLS` for the app role, `set_config(…, true)` per transaction behind a pooler, and `security_invoker` views.
  - `SET NULL (col)` for composite FKs (PG 15+).
  - The warning against the correlated `(select fn(row_col))` example.
  - The MySQL and SQLite line.
  - Its closing rule: a mode that reads it returns to its own steps.
- `modes/design.md` "Settle each table…" and `modes/audit.md` "Sweep against the standard": each reads `tenancy.md` under the tenancy trigger.
- `modes/tune.md` "Get the plan": on a table with RLS, the plan comes from the app role (`SET ROLE app`), and a plan taken as the owner shows plan shape only.
- `engines/postgres.md`: a new "Functions and triggers" section. A `SECURITY DEFINER` function sets `search_path = ''` and gets `REVOKE EXECUTE … FROM PUBLIC`. `CREATE OR REPLACE FUNCTION` with new arguments makes an overload.
- `modes/audit.md` "Rank and crown": a tenant leak (no tenant key, a plain cross-tenant FK, RLS without `FORCE`) heads High. A definer function with no fixed path is High. An app that connects as a superuser or table owner is High, and `GRANT ALL` in a migration is Medium. `ON DELETE CASCADE` on a history table is High.

Done when: `make lint` resolves the new `tenancy.md` pointer and passes; `grep -c FORCE skills/dbkit/tenancy.md` is at least 1; and `modes/audit.md` names a tenant leak as the first High item.

### Phase 3: ORM and tool coverage

- `orms.md`: add TypeORM and Sequelize sections, each with its transaction behavior and its dev-only commands, verified against the docs for the current major version.
- `modes/audit.md` "Sweep the migration history" and `modes/migrate.md` "Check the file as a whole": the dev-only check also catches app-start schema sync. That means TypeORM `synchronize: true`, Sequelize `sync({ alter: true })`, and Hibernate `ddl-auto=update`.
- `orms.md` "Raw SQL and other tools": a serverless HTTP driver (`drizzle-orm/neon-http`) runs no interactive transaction, so a migration or backfill script uses a TCP or WebSocket client.
- `SKILL.md` "The disposable target": the Neon branch line from the decisions table.

Done when: `make lint` passes; `orms.md` has `## TypeORM` and `## Sequelize` headings; `grep -c synchronize` finds the flag in `modes/audit.md` and `modes/migrate.md`; and the phase's commit body lists the doc URL for each TypeORM and Sequelize fact.

### Phase 4: Postgres split, facts, and Credit

Do the split first, as a move with no wording change, so the diff of moved text stays separate from the new facts.

- Split `engines/postgres.md`:
  - Move "Reading a plan for tune" to a new `engines/postgres-tune.md`.
  - Move "Catalog queries for audit" to a new `engines/postgres-audit.md`.
  - Give each new file a one-line opening that says which mode reads it and that `engines/postgres.md` is already loaded.
  - The "Invalid indexes" line in the audit section links to `engines/postgres.md#concurrent-index-builds` across files.
- Repoint the readers:
  - `modes/tune.md` "Diagnose" links to `../engines/postgres-tune.md`.
  - `modes/audit.md` "List what needs production stats" links to `../engines/postgres-audit.md`.
  - `SKILL.md` "Stack detection" adds one line to the Postgres bullet: `tune` and `audit` each read their own Postgres satellite, and their mode files name it.
- `engines/postgres.md` "Index types":
  - Fix the prefix `LIKE` row to require `text_pattern_ops` under a non-C collation.
  - Add a `pg_trgm` row for `LIKE '%x%'` and `ILIKE`.
  - Add the two-argument `to_tsvector` rule to the GIN row.
  - Add `btree_gist` to the GiST row.
  - Add `jsonb_path_ops` to the GIN row, keeping `@?` and `@@` in its operator list.
- `engines/postgres.md` lock table:
  - Add rows for an identity column, a stored generated column, and a virtual generated column (PG 18).
  - Change the type row to cover `int` to `bigint` (a rewrite) and `numeric` precision widening (no rewrite).
  - Add the `DEFAULT now()` note (instant, and every old row gets the migration time).
  - Split `RENAME TO` for a table from `RENAME COLUMN`, and give the table the rename-plus-view path with its two caveats.
- `engines/postgres.md` "Version limits": update the PG 18 row.
- `engines/postgres.md` "Batched backfill":
  - Give the reason for the "not yet done" predicate.
  - Add an `ANALYZE` step after a large backfill.
- `engines/postgres-tune.md`:
  - Add the `pg_stat_statements` query as needs production stats, with the PG 13 column note.
  - Add the `pg_stat_user_tables` staleness query to the estimate row.
  - Add the keyset tie-breaker to the pagination row.
  - Name per-table autovacuum as a cause only.
- `engines/postgres-audit.md`: add the `pg_stat_statements` top-queries query as needs production stats. `modes/audit.md` "List what needs production stats" names it beside unused indexes, bloat, and table sizes.
- `SKILL.md` schema standard:
  - "Constraints" gets the narrowing-change pre-check and case-insensitive uniqueness.
  - "Migrations" says that the expand step drops `NOT NULL` or adds a default before code stops writing a column.
- `modes/migrate.md` "Run the data-integrity pre-checks": add the narrowing-change count.
- `modes/tune.md` "Propose one change": name the `= ANY($1::bigint[])` form for an N+1.
- `SKILL.md` Notes: update the Credit line as in the decisions table.

Done when:

- `make lint` passes, which resolves the cross-file links into the two new satellites.
- `grep -c 'Reading a plan for tune\|Catalog queries for audit' skills/dbkit/engines/postgres.md` prints 0.
- `grep -c text_pattern_ops skills/dbkit/engines/postgres.md` is at least 1.
- The Credit line names commit `8c9a4a2`.
- The root is at 3,000 words or fewer.
- Each of these four counts prints 6,500 or fewer:
  - `cat SKILL.md modes/design.md engines/postgres.md | wc -w`
  - `cat SKILL.md modes/migrate.md engines/postgres.md | wc -w`
  - `cat SKILL.md modes/tune.md engines/postgres.md engines/postgres-tune.md | wc -w`
  - `cat SKILL.md modes/audit.md engines/postgres.md engines/postgres-audit.md | wc -w`

Run the counts from `skills/dbkit/`.

### Phase 5: owner check on real repos

Attended: the owner runs dbkit in a fresh session on `~/projects/primeshopr` or `~/projects/growaloy` after Phase 4 is pushed to `main`, and judges each result.

- Run `dbkit migrate` check on a migration whose migrate URL goes through a pooler. Expect the pooled-URL finding.
- Run `dbkit migrate` check on a migration with a `DROP COLUMN`. Expect **destroys data**, a `restore from backup` rollback line, and a backup instruction in the hand-off, with no question asked.
- Ask dbkit to read a database published by a compose service whose image is a proxy. Expect a question before it connects.
- Run `dbkit audit` on one repo. Expect the new High items where they apply, and no false tenant finding on a single-tenant schema.
- Ask dbkit to read the database with a forwarded port on loopback. Expect a question before it connects.
- Run every case in `skills/dbkit/evals/triggers.md`. The description is unchanged, so expect no change in which mode fires.

Done when: the owner records each of the six results as pass or fail in a review note under `docs/reviews/`, and every fail has a fix commit on `main`.

## Open questions

None. The grill on 2026-11-15 settled all four earlier questions: macOS loopback (Q9), the read timeout (Q10), shipping (Q3 and Q13), and the backup check (Q2).

## Non-goals

- The report's rejected list: scratch-database "prove it", down migrations as rollback, server and pool settings, app-code concurrency (deadlocks, advisory locks, batch inserts), choosing a database, NoSQL and warehouses, and vendor setup.
- Any change to the description, the trigger evals, or the wiki pages.
- `DEFERRABLE` constraints for circular FKs, hierarchical-data patterns, the cold-cache note for serverless computes, `BitmapAnd` as a composite-index hint, and range-type bound rules. Each was low value in the report.
- A dbkit verb that creates a Neon branch or any other database.
