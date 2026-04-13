# OTP Enum Sync

## Why enum mismatch errors happen

GuardianNode stores OTP session purposes in `public.otp_sessions.purpose`.
That column is expected to use the Postgres enum `public.otp_purpose_enum`.

Enum mismatch errors happen when backend code sends a value that the database
enum does not support. A common example is sending `registration` while the
database only supports `register`.

Typical Postgres error:

```text
invalid input value for enum otp_purpose_enum: "registration"
```

## Backend source of truth

Backend code should never hardcode OTP purpose strings inline.

Use [server/constants/otpPurpose.js](../server/constants/otpPurpose.js) as the
shared source of truth:

- `register`
- `login`
- `reset_password`
- `verify_phone`

The constants module also normalizes the legacy alias `registration` to
`register` so older data paths can be handled safely during migration.

## Supabase schema expectation

`otp_sessions.purpose` should be:

```sql
purpose public.otp_purpose_enum not null
```

`otp_purpose_enum` should contain:

- `register`
- `login`
- `reset_password`
- `verify_phone`

## Safe migration strategy

For fresh environments:

- Run [server/sql/create_otp_sessions.sql](../server/sql/create_otp_sessions.sql)

For existing environments with schema drift:

- Run [server/sql/add_enum_value.sql](../server/sql/add_enum_value.sql)

If Supabase still reports `PGRST204` or says a column is missing from the
schema cache after the column exists:

- Run [server/sql/reload_schema_cache.sql](../server/sql/reload_schema_cache.sql)

That migration safely:

- creates `otp_purpose_enum` if it does not exist
- adds any missing enum values
- converts `otp_sessions.purpose` to the enum type when the column is still text
- adds missing OTP workflow columns such as `attempts`, `max_attempts`,
  `registration_payload`, `metadata`, `verified_at`, `created_at`, and
  `updated_at`
- maps legacy `registration` values to `register` during the column conversion
- recreates the expected `otp_sessions` indexes if they are missing
- requests a PostgREST schema cache reload when the migration completes

## Operational guidance

- Treat [server/constants/otpPurpose.js](../server/constants/otpPurpose.js) as
  the only allowed place to define OTP purpose values.
- When adding new OTP flows, update both the constants file and the SQL
  migration/bootstrap files in the same change.
- If production throws `database_enum_mismatch`, check the backend constants
  first, then verify the enum values in Supabase.
- If production throws `database_column_missing`, the live `otp_sessions`
  table is older than the backend and needs the schema sync migration.
- If production throws `PGRST204` after a migration already ran successfully,
  reload the PostgREST schema cache before changing application code.
