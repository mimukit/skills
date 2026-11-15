# dbkit: Postgres

It gives the Postgres facts behind [the schema standard](../SKILL.md#the-schema-standard); check each version limit against the detected major version.

## Locks per DDL statement

The lock decides the risk first, and table size decides it second. `ACCESS EXCLUSIVE` blocks every read and write on the table; `SHARE` blocks writes and allows reads; `SHARE UPDATE EXCLUSIVE` allows both.

| Statement | Lock | Cost | Safe path |
| --- | --- | --- | --- |
| `ADD COLUMN`, nullable, no default | `ACCESS EXCLUSIVE` | Catalog only, instant | Safe with a lock timeout |
| `ADD COLUMN … DEFAULT <constant>` | `ACCESS EXCLUSIVE` | Instant on PG 11+; rewrite before 11 | Safe with a lock timeout on 11+ |
| `ADD COLUMN … DEFAULT <volatile>` (`gen_random_uuid()`, `random()`, `clock_timestamp()`) | `ACCESS EXCLUSIVE` | Rewrites the table | Add nullable, set the default for new rows, backfill in batches |
| `ADD COLUMN … GENERATED … AS IDENTITY` | `ACCESS EXCLUSIVE` | Rewrites the table | Add a nullable `bigint`, set its sequence default for new rows, backfill in batches |
| `ADD COLUMN … GENERATED ALWAYS AS (…) STORED` | `ACCESS EXCLUSIVE` | Rewrites the table | A virtual column on PG 18 when no index needs it; else a plain column set by the application or a trigger, backfilled in batches |
| `ADD COLUMN … GENERATED ALWAYS AS (…)`, virtual (PG 18) | `ACCESS EXCLUSIVE` | Catalog only, instant; cannot be indexed | Safe with a lock timeout; index the expression instead |
| `ADD COLUMN … NOT NULL`, no default | `ACCESS EXCLUSIVE` | Fails on a table with rows | Add nullable or with a constant default |
| `ALTER COLUMN … SET NOT NULL` | `ACCESS EXCLUSIVE` | Scans the table under the lock | `ADD CONSTRAINT c CHECK (col IS NOT NULL) NOT VALID`, `VALIDATE CONSTRAINT c`, `SET NOT NULL` (PG 12+ skips the scan), drop `c` |
| `ADD CONSTRAINT … FOREIGN KEY` | `SHARE ROW EXCLUSIVE` on both tables | Scans the referencing table | Add it `NOT VALID`, then `VALIDATE CONSTRAINT` in a separate migration |
| `ADD CONSTRAINT … CHECK` | `ACCESS EXCLUSIVE` | Scans the table | Add it `NOT VALID`, then `VALIDATE CONSTRAINT` |
| `VALIDATE CONSTRAINT` | `SHARE UPDATE EXCLUSIVE` | Scans; reads and writes continue | Safe |
| `CREATE INDEX` | `SHARE` | Blocks writes for the whole build | `CREATE INDEX CONCURRENTLY` |
| `CREATE INDEX CONCURRENTLY` | `SHARE UPDATE EXCLUSIVE` | Two scans; waits for open transactions | Safe; see [Concurrent index builds](#concurrent-index-builds) |
| `DROP INDEX` | `ACCESS EXCLUSIVE` | Instant once the lock is held | `DROP INDEX CONCURRENTLY` |
| `ADD UNIQUE` or `ADD PRIMARY KEY` | `ACCESS EXCLUSIVE` | Builds an index under the lock | `CREATE UNIQUE INDEX CONCURRENTLY idx …`, then `ADD CONSTRAINT name UNIQUE USING INDEX idx` (or `PRIMARY KEY USING INDEX`) |
| `DROP COLUMN` | `ACCESS EXCLUSIVE` | Catalog only; destroys data | Ship code that no longer reads the column first (contract step) |
| `DROP TABLE` | `ACCESS EXCLUSIVE` | Catalog only; destroys data | Contract step. Optionally rename it to `_deprecated_<name>` one release first, so a straggler fails loudly and the rename can be undone |
| `RENAME COLUMN` | `ACCESS EXCLUSIVE` | Catalog only; breaks running code | Expand, migrate, contract |
| `RENAME TO` (table) | `ACCESS EXCLUSIVE` | Catalog only; breaks running code | `ALTER TABLE old RENAME TO new; CREATE VIEW old AS SELECT * FROM new;` in one transaction, and drop the view in the contract step. A simple view is auto-updatable since PG 9.3, so old code keeps reading and writing. `SELECT *` freezes the view's column list, and an ORM may reject a view with no primary key |
| `ALTER COLUMN … TYPE` | `ACCESS EXCLUSIVE` | Rewrites table and indexes, `int` to `bigint` included. No rewrite for `varchar(n)` to a larger `n` or `text`, or for more `numeric` precision at the same scale | New column, backfill, switch reads, drop the old one |
| `SET DEFAULT` or `DROP DEFAULT` | `ACCESS EXCLUSIVE` | Catalog only | Safe with a lock timeout |
| `ALTER TYPE … ADD VALUE` (enum) | `ACCESS EXCLUSIVE` on the type | Catalog only; the new value is unusable in the same transaction | Its own migration |

`DEFAULT now()` is a constant default: `now()` is stable, so the add is instant on PG 11+. Every existing row gets the migration's transaction time, so a `created_at` added to an old table dates every old row falsely.

## Timeouts and the lock queue

Locks queue in order. An `ACCESS EXCLUSIVE` request that waits behind one long query blocks every later read and write on the table, so an instant `ADD COLUMN` becomes an outage as long as the slowest open transaction.

Open each migration that touches a live table with:

```sql
SET lock_timeout = '5s';
SET statement_timeout = '15min';
```

Inside a transaction, use `SET LOCAL`. A migration that hits the lock timeout fails cleanly and holds nothing; retry it a few times with a pause, and never raise the timeout instead. A concurrent index build can run long, so give that statement a `statement_timeout` of `0` or one that fits the build.

- **Run migrations over a direct or session-mode connection**, never a transaction-mode or statement-mode pooler (PgBouncer in those modes, a Neon `-pooler` host, Supabase port 6543). That pooler can hand each statement to a different server connection, so the session `SET` may not reach the next statement and the lock timeout silently does nothing. Session-mode pooling is safe.
- **A file outside a transaction ends with `RESET lock_timeout; RESET statement_timeout;`**, so its settings do not stay on a reused connection.
- **Every file is safe to rerun.** A retry after a timeout can find part of the file applied, so use `IF NOT EXISTS` and `IF EXISTS` where the statement takes them, and check for an `INVALID` index first under [Concurrent index builds](#concurrent-index-builds).
- **Find the blockers before the deploy.** Give the user this query to run on the primary; each row is a transaction the migration would queue behind:

```sql
SELECT pid, state, xact_start, query
FROM pg_stat_activity
WHERE xact_start < now() - interval '1 min';
```

## Concurrent index builds

- `CREATE INDEX CONCURRENTLY`, `DROP INDEX CONCURRENTLY`, and `REINDEX … CONCURRENTLY` cannot run inside a transaction block. A migration tool that wraps each file in a transaction, or runs a multi-statement file as one implicit transaction, makes them fail; [orms.md](../orms.md) says how each tool runs one alone.
- A failed or cancelled concurrent build leaves an `INVALID` index. It serves no reads, still costs every write, and a rerun with `IF NOT EXISTS` skips it because the name exists. Find them with:

```sql
SELECT c.relname AS index_name, t.relname AS table_name
FROM pg_index i
JOIN pg_class c ON c.oid = i.indexrelid
JOIN pg_class t ON t.oid = i.indrelid
WHERE NOT i.indisvalid;
```

- Recover with `DROP INDEX CONCURRENTLY name;` and build it again, or with `REINDEX INDEX CONCURRENTLY name;` on PG 12+.

## Batched backfill

Backfill after the schema change ships, one short transaction per range of primary keys:

```sql
UPDATE orders
SET total_cents = round(total * 100)
WHERE id >= :start AND id < :start + 5000
  AND total_cents IS NULL;
```

The runner steps `:start` across the id range, commits each batch, and pauses so replicas keep up. Where concurrent workers claim rows, pick each batch's ids with `FOR UPDATE SKIP LOCKED`. A migrator that runs a file in one transaction defeats batching, so a large backfill runs as a script outside it.

The "not yet done" predicate (`AND total_cents IS NULL`) makes a rerun idempotent. In READ COMMITTED, a batch that waits on a row lock rechecks it, so the batch does not overwrite a concurrent app write.

After a large backfill, run `ANALYZE <table>`. A new expression index also has no statistics until `ANALYZE` runs.

## Functions and triggers

- **A `SECURITY DEFINER` function fixes its path and its callers.** Give it `SET search_path = ''` (or a fixed list) and run `REVOKE EXECUTE ON FUNCTION … FROM PUBLIC`, then grant it to the roles that need it. Otherwise a caller who can create objects in a schema on the path takes over the function's privileges.
- **`CREATE OR REPLACE FUNCTION` with a new argument list creates an overload**, and the old signature stays. Drop the old one explicitly in the same migration.

## Version limits

| Version | What it adds |
| --- | --- |
| PG 11 | Instant `ADD COLUMN` with a non-volatile default; foreign keys from a partitioned table; `COMMIT` inside a procedure |
| PG 12 | `REINDEX CONCURRENTLY`; `SET NOT NULL` skips its scan when a valid `CHECK (col IS NOT NULL)` exists; foreign keys that reference a partitioned table; `ALTER TYPE … ADD VALUE` inside a transaction block |
| PG 13 | `gen_random_uuid()` built in, with no extension |
| PG 14 | `DETACH PARTITION … CONCURRENTLY` |
| PG 15 | `UNIQUE NULLS NOT DISTINCT`, which allows one `NULL` |
| PG 18 | `uuidv7()` built in; virtual generated columns, the default kind for a generated column |

## Types to avoid

| Avoid | Use | Reason |
| --- | --- | --- |
| `timestamp` (without time zone) | `timestamptz` | Stores a wall-clock time with no zone |
| `timestamptz(0)` or any precision | `timestamptz` | Rounds; events can swap order |
| `timetz` | `timestamptz` | A zone without a date is meaningless |
| `money` | `numeric(p, s)` or integer minor units | Output follows `lc_monetary` |
| `char(n)`, `varchar(n)` | `text` with a `CHECK` on length | Same storage; shrinking `n` rewrites |
| `serial`, `bigserial` | `bigint GENERATED ALWAYS AS IDENTITY` | Standard; the column owns the sequence |
| `json` | `jsonb` | No GIN index; keeps raw text |

## Index types

Take the first row that fits the query:

| The query | Index |
| --- | --- |
| `=`, `<`, `>`, `BETWEEN`, `ORDER BY` | B-tree (the default) |
| Prefix `LIKE 'abc%'` | B-tree under the C collation; under any other collation, B-tree with `text_pattern_ops` or `varchar_pattern_ops` |
| `LIKE '%x%'`, `ILIKE`, similarity | GIN with `gin_trgm_ops` (the `pg_trgm` extension) |
| Filters one hot subset (`WHERE status = 'active'`) | Partial B-tree with that `WHERE` |
| Filters on an expression (`lower(email)`) | Expression index; the query must use the same expression |
| Reads a few extra columns after the filter | Covering B-tree, `INCLUDE (col, …)`, for an index-only scan |
| `jsonb` containment, arrays, full-text search | GIN. `jsonb_path_ops` is smaller and supports `@>`, `@?`, `@@`, but not `?`, `?\|`, `?&`. Full-text search uses the two-argument `to_tsvector('english', col)` in index and query; the one-argument form is not immutable, so an expression index cannot use it |
| Ranges, geometry, `EXCLUDE` constraints (no overlapping bookings) | GiST; the scalar `=` part of an `EXCLUDE` (`room_id WITH =`) needs the `btree_gist` extension |
| A very large table in natural insert order (time series) | BRIN |

## Partitioning

- Partition only a table past about 100 million rows whose queries filter on one key, or whose retention drops data by that key. Below that, partitions add planning cost and gain nothing.
- `RANGE` suits time, `LIST` suits a small set of discrete values, `HASH` spreads a table with no natural key. Use declarative partitioning, never table inheritance.
- A query that does not filter on the partition key scans every partition.
- A primary key or unique constraint must include the partition key; no constraint is unique across partitions.
- Drop old data with `DETACH PARTITION` (concurrently on PG 14+) and `DROP TABLE`, never with a bulk `DELETE`.
