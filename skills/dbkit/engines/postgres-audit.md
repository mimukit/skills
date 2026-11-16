# dbkit: Postgres audit queries

## Catalog queries for audit

Foreign keys with no index whose leading columns cover them:

```sql
SELECT c.conrelid::regclass AS table_name, c.conname AS foreign_key
FROM pg_constraint c
WHERE c.contype = 'f'
  AND NOT EXISTS (
    SELECT 1 FROM pg_index i
    WHERE i.indrelid = c.conrelid
      AND (string_to_array(i.indkey::text, ' ')::int2[])[1:cardinality(c.conkey)] @> c.conkey
  );
```

Indexes with the same definition on one table:

```sql
SELECT indrelid::regclass AS table_name, array_agg(indexrelid::regclass) AS indexes
FROM pg_index
GROUP BY indrelid, indkey::text, indclass::text,
         coalesce(indexprs::text, ''), coalesce(indpred::text, '')
HAVING count(*) > 1;
```

Invalid indexes: the query in [Concurrent index builds](postgres.md#concurrent-index-builds).

Unused indexes are **needs production stats**: dev counters say nothing about production, and each replica keeps its own. Give this query for the user to run on the primary and each replica:

```sql
SELECT s.relname AS table_name, s.indexrelname AS index_name, s.idx_scan,
       pg_size_pretty(pg_relation_size(s.indexrelid)) AS size
FROM pg_stat_user_indexes s
JOIN pg_index i ON i.indexrelid = s.indexrelid
WHERE s.idx_scan = 0 AND NOT i.indisunique
ORDER BY pg_relation_size(s.indexrelid) DESC;
```

Table sizes and bloat are **needs production stats** the same way.

Top queries are **needs production stats** too. Give this query for the user to run on the primary; on PG 12 and older, the columns are `total_time` and `mean_time`. It needs the `pg_stat_statements` extension already installed, and dbkit never creates it:

```sql
SELECT queryid, calls, total_exec_time, mean_exec_time, rows, query
FROM pg_stat_statements
ORDER BY total_exec_time DESC
LIMIT 20;
```
