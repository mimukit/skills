# dbkit: tenancy

Read this file when the root's [Tenancy](SKILL.md#tenancy) trigger fires; the root and the engine file are already loaded, and their composite-key and scoping rules hold here.

## Postgres row-level security

- **Turn it on and force it.** Run `ALTER TABLE … ENABLE ROW LEVEL SECURITY` and `ALTER TABLE … FORCE ROW LEVEL SECURITY` on every tenant-owned table. The table owner skips RLS without `FORCE`, and many apps connect as the owner.
- **Write the policy to fail closed.** Use `USING (tenant_id = (SELECT NULLIF(current_setting('app.current_tenant_id', true), '')::bigint))`. An unset setting, or a `''` left on a pooled connection, matches no row.
- **A policy with only `USING` applies to writes too.** Add `WITH CHECK` when the write rule differs from the read rule.
- **Wrap a row-independent function in a scalar subquery**, as above or `(select auth.uid())`, so the planner runs it once as an InitPlan. Never pass a row column into it: `(select is_member(team_id))` stays correlated and runs once per row.
- **Index every column a policy filters on.** The policy adds its filter to every query on the table.
- **The app role has no `SUPERUSER` or `BYPASSRLS`.** Either one skips every policy.
- **Behind a transaction pooler, set the tenant per transaction** with `SELECT set_config('app.current_tenant_id', $1, true)`, never per session. A session setting stays on the server connection for the next client.
- **A view skips RLS** unless it is created `WITH (security_invoker = true)` (PG 15+). Without it, the view runs as its owner.
- **A composite foreign key with `ON DELETE SET NULL` names its column**, `SET NULL (project_id)` (PG 15+). The plain form nulls the tenant key too.

## Tenant leaks

Each of these is a tenant leak:

- A tenant-owned table with no tenant key.
- A plain foreign key between tenant-owned tables, with no tenant key in it.
- A unique constraint on a tenant value that leaves out the tenant key.
- A tenant-owned table with RLS enabled but no `FORCE`.
- A view over a tenant-owned table with no `security_invoker`.
- An app role with `SUPERUSER` or `BYPASSRLS`, or one that owns the tables without `FORCE`.
- A session-level `SET app.current_tenant_id` behind a transaction pooler.

## MySQL and SQLite

MySQL and SQLite have no row-level security, so only the root's composite-key and scoping rules apply there.

The mode that read this file returns to its own steps.
