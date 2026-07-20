#!/usr/bin/env node
// Applies server/sql/*.sql to the Supabase Postgres database directly, in
// dependency order, so a deploy can run `npm run migrate` instead of someone
// pasting each file into the Supabase SQL Editor by hand.
//
// Requires DATABASE_URL -- the direct Postgres connection string from
// Supabase (Project Settings -> Database -> Connection string -> URI), NOT
// the SUPABASE_URL/SUPABASE_SERVICE_ROLE_KEY pair used elsewhere in this
// app. Those are PostgREST credentials and cannot execute arbitrary DDL;
// this script needs a real `postgres://` connection.
//
// Every file in server/sql/ is written to be idempotent (IF NOT EXISTS /
// DROP ... IF EXISTS), so re-running an already-applied file is a safe
// no-op. This script also tracks what it has personally applied in a
// schema_migrations table so repeat deploys skip work quickly, but that
// table is a convenience, not a correctness requirement.

const fs = require('fs');
const path = require('path');
const { Client } = require('pg');

// Explicit, dependency-respecting order. New files must be added here --
// this script does not infer order from the filesystem.
const MIGRATION_ORDER = [
  'create_otp_sessions.sql',
  'add_enum_value.sql',
  'add_whatsapp_verification_columns.sql',
  'add_whatsapp_verification_index.sql',
  'create_live_locations.sql',
  'create_alert_responses.sql',
  'reload_schema_cache.sql',
  'add_role_and_verification_columns.sql',
  'add_alert_intelligence_fields.sql',
  'extend_response_state_machine.sql',
  'create_alert_confirmations.sql',
  'create_moderation_actions.sql',
  'create_alert_media.sql',
  'enable_row_level_security.sql',
  'add_password_authentication.sql',
];

const SQL_DIR = path.join(__dirname, '..', 'sql');

const ensureMigrationsTableSql = `
  create table if not exists public.schema_migrations (
    filename text primary key,
    applied_at timestamptz not null default timezone('utc'::text, now())
  );
`;

async function main() {
  const connectionString = process.env.DATABASE_URL;

  if (!connectionString) {
    console.error(
      '[migrate] DATABASE_URL is not set. This must be the direct Postgres ' +
        'connection string from Supabase (Project Settings -> Database -> ' +
        'Connection string -> URI), not SUPABASE_URL. Nothing was run.'
    );
    process.exitCode = 1;
    return;
  }

  const filesOnDisk = new Set(fs.readdirSync(SQL_DIR).filter((f) => f.endsWith('.sql')));
  const missingFromOrder = [...filesOnDisk].filter((f) => !MIGRATION_ORDER.includes(f));
  if (missingFromOrder.length > 0) {
    console.warn(
      `[migrate] WARNING: these .sql files exist but are not in MIGRATION_ORDER and will be skipped: ${missingFromOrder.join(', ')}`
    );
  }

  const client = new Client({
    connectionString,
    ssl: { rejectUnauthorized: false },
  });

  await client.connect();

  try {
    await client.query(ensureMigrationsTableSql);

    const { rows } = await client.query('select filename from public.schema_migrations');
    const alreadyApplied = new Set(rows.map((row) => row.filename));

    for (const filename of MIGRATION_ORDER) {
      const filePath = path.join(SQL_DIR, filename);

      if (!fs.existsSync(filePath)) {
        console.warn(`[migrate] Skipping ${filename}: file not found on disk.`);
        continue;
      }

      if (alreadyApplied.has(filename)) {
        console.log(`[migrate] Skipping ${filename}: already applied.`);
        continue;
      }

      const sql = fs.readFileSync(filePath, 'utf8');
      console.log(`[migrate] Applying ${filename} ...`);

      try {
        await client.query(sql);
        await client.query(
          'insert into public.schema_migrations (filename) values ($1) on conflict do nothing',
          [filename]
        );
        console.log(`[migrate] Applied ${filename}`);
      } catch (error) {
        console.error(`[migrate] FAILED applying ${filename}: ${error.message}`);
        throw error;
      }
    }

    console.log('[migrate] All migrations up to date.');
  } finally {
    await client.end();
  }
}

main().catch((error) => {
  console.error('[migrate] Migration run aborted:', error.message);
  process.exitCode = 1;
});
