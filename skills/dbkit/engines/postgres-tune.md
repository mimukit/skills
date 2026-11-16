# dbkit: Postgres plan reading

## Reading a plan for tune

Compare each node's estimated `rows` with its actual `rows` and `loops` first; most bad plans start with a bad estimate.

| Symptom in the plan | Likely cause | Change to propose |
| --- | --- | --- |
| `Seq Scan` on a large table with a high `Rows Removed by Filter` | No index the filter can use: none exists, the column is wrapped in a function, the types differ, or a `LIKE` starts with `%` | An index that matches the filter as written, or a query that matches the index |
| Estimated rows off from actual by 10× or more | Stale statistics (check with the query below), or correlated columns | `ANALYZE` the table; `CREATE STATISTICS` for the correlated columns |
| `Nested Loop` with a large `loops` count on the inner side | The inner join key has no index, or the outer estimate is low | An index on the inner join key; fix the estimate first |
| `Index Scan` followed by a large `Rows Removed by Filter` | The index covers only part of the filter | A composite index with the remaining equality column |
| `Sort Method: external merge`, or `Hash` with `Batches` above 1 | The operation spills to disk | An index in the `ORDER BY` order; else name `work_mem` as the cause for the operator |
| `Buffers: shared read` far above `shared hit` | The query touches more pages than the cache holds | A covering or narrower index; fewer columns selected |
| `Index Only Scan` with a high `Heap Fetches` | The visibility map lags | A vacuum on the table, named for the operator |
| A large `OFFSET` with most rows discarded | Offset pagination | Keyset pagination with a unique tie-breaker, `WHERE (created_at, id) > ($1, $2) ORDER BY created_at, id`, with an index on `(created_at, id)` |

Statistics staleness, read-only:

```sql
SELECT relname, last_analyze, last_autoanalyze, n_mod_since_analyze
FROM pg_stat_user_tables
WHERE relname = '<table>';
```

Server settings (`work_mem`, `shared_buffers`) and per-table autovacuum settings (`ALTER TABLE … SET (autovacuum_…)`) are a cause to name for the operator, never a change dbkit proposes.

## Top queries

The queries that take the most total time are **needs production stats**. Give this query for the user to run on the primary; on PG 12 and older, the columns are `total_time` and `mean_time`:

```sql
SELECT queryid, calls, total_exec_time, mean_exec_time, rows, query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;
```

Reading it needs the `pg_stat_statements` extension already installed. dbkit never creates it.
