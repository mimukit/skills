# dbkit: migration tool gotchas

For every command and flag, read the installed tool's `--help` or its docs for the installed version, and say in the hand-off which you read; the syntax below is a pointer, never a pinned form. The two questions for any tool are the same: does it wrap a migration in a transaction (which breaks a concurrent index build), and which of its commands touch a database.

## Drizzle

- `drizzle-kit generate` writes SQL files and needs no database. `drizzle-kit push` changes the database directly and writes no file, so it is dev-only and never produces a migration.
- A hand-written migration starts from `drizzle-kit generate --custom`, which writes an empty file the journal tracks. Statements in one file are split by `--> statement-breakpoint` lines.
- `generate` asks interactively whether a changed column is a rename or a drop-and-add. With no terminal it stalls; when the change is a rename, write the expand, migrate, contract files by hand instead.
- In drizzle-orm 0.45.4 and drizzle-kit 0.31.11, the current stable releases, the Postgres migrator runs all pending migrations inside one transaction, so `CREATE INDEX CONCURRENTLY` fails there, and it reads its order from `<out>/meta/_journal.json` (package source, checked 2026-11-16). On another version, check the installed package source. When it holds, run the concurrent build outside the migrator and record that in the hand-off.

## Prisma

- `prisma migrate dev` connects to the database and to a shadow database (Prisma 7: `datasource.shadowDatabaseUrl` in `prisma.config.ts`, checked 2026-11-16), and on drift it offers to reset the database. Run it only on [a disposable target](SKILL.md#the-disposable-target), with `--create-only` so it writes the file without applying it.
- `prisma migrate diff` can write SQL from two schema sources with no database; read its `--help` for the source flags, which changed across major versions.
- `prisma migrate deploy` applies migrations in production; `prisma migrate reset` and `prisma db push` are dev-only.
- A multi-statement `migration.sql` runs as one implicit transaction on Postgres, so a `CONCURRENTLY` statement goes alone in its own migration directory.

## Kysely

- Kysely has no generator; migrations are hand-written `up` and `down` functions.
- Type each migration's `db` as `Kysely<any>`, never the app's database interface, so an old migration still compiles after the schema moves on.
- The migrator runs pending migrations in a transaction on engines with transactional DDL, Postgres included. A concurrent build needs the migrator's option to disable transactions, where the installed version has one, or a run outside the migrator.

## TypeORM

- `migration:run` wraps all pending migrations in one transaction by default (`--transaction all`, or `migrationsTransactionMode` in the data source). `--transaction each` wraps each migration alone, and `--transaction none` wraps nothing.
- A concurrent index goes in a migration class with `transaction = false`. That property works only in `each` or `none` mode, so under the default `all` the build still fails inside the transaction.
- `synchronize: true` in the data source changes the schema on every app start, and `schema:sync` does the same from the CLI. Both are dev-only; `schema:log` prints the SQL `schema:sync` would run.
- `migrationsRun: true` applies pending migrations at app start, so every boot is a deploy.

## Sequelize

- sequelize-cli runs each migration's `up` with no transaction, so a multi-step file half-applies on failure. Wrap the steps in `queryInterface.sequelize.transaction()` and pass `{ transaction }` to each call.
- A concurrent index is `queryInterface.addIndex` with `concurrently: true`, in a migration that opens no transaction.
- `sync({ alter: true })` and `sync({ force: true })` change or drop tables to match the models, and are dev-only. Plain `sync()` creates missing tables only; the docs point production schema changes to migrations.

## Django

- `makemigrations` asks for a one-off default when a model gains a `NOT NULL` field; answer with the expand path instead (a nullable field first).
- `python manage.py sqlmigrate <app> <name>` prints the SQL a migration runs. Read it before any verdict.
- A concurrent index needs `atomic = False` on the migration and `AddIndexConcurrently` from `django.contrib.postgres.operations`.
- `SeparateDatabaseAndState` removes a field from the model without dropping the column, which is the expand half of a drop.
- A data migration (`RunPython`) goes in its own migration file.

## Rails

- `disable_ddl_transaction!` in the migration class, with `algorithm: :concurrently` on the index call, builds an index concurrently. `add_reference` adds a plain index by default.
- Before a column is dropped, add it to the model's `ignored_columns` and deploy, because Active Record caches the column list and a running process fails on a missing column.
- The `strong_migrations` gem encodes these checks; when the repo has it, follow its messages.

## golang-migrate

- A failed migration leaves the version marked dirty. Fix the database state by hand first, then run `force <version>`; forcing first records a half-applied migration as done.
- A file with several statements runs as one implicit transaction on Postgres, so a `CONCURRENTLY` statement goes alone in its own file.

## Raw SQL and other tools

- With plain SQL files, the file controls its transaction: wrap ordinary DDL in `BEGIN` and `COMMIT`, and leave a concurrent build outside any transaction.
- A serverless HTTP driver (`drizzle-orm/neon-http`, `@neondatabase/serverless` over HTTP) runs no interactive transaction. A migration or backfill script that needs `BEGIN … SET LOCAL … COMMIT` uses a TCP or WebSocket client, so check the driver the script imports.
- For any other tool (Alembic, Flyway, Liquibase, Atlas, sqlx), find its transaction behavior and its raw-SQL escape in its docs before writing the first file, and say in the hand-off what you found.
