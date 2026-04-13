# Debug Auth Mode

## What It Is

Debug auth mode lets GuardianNode complete the registration and OTP flow without sending a real SMS. The OTP screen stays visible, the backend still creates an OTP session, and verification still happens through `/api/auth/verify-otp`.

## Why It Exists

This mode makes it possible to test the full registration and login journey before an SMS provider is purchased or configured.

## How It Works

When `DEBUG_AUTH_MODE=true`:

- `POST /api/auth/register` validates the registration payload and stores it inside an `otp_sessions` record.
- No SMS provider is called.
- The new `otp_sessions.metadata` payload is marked with `mode: "debug"`.
- Accepted codes come from environment variables, not controller hardcoding.
- `POST /api/auth/verify-otp` accepts `DEBUG_DEFAULT_OTP` and `DEBUG_BACKUP_OTP`.
- On successful verification, the backend creates or updates the user profile, creates or updates the initial emergency contact, signs a JWT app session, and returns the same kind of success payload the frontend needs to enter the app.

When `AUTO_VERIFY_DEBUG_OTP=true`:

- The debug OTP session is created in a verification-ready state for rapid testing.
- The app still routes to the OTP screen.
- Entering the configured debug code still completes the flow normally.

## Environment Variables

Required backend variables:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `JWT_SECRET`
- `DEBUG_AUTH_MODE`
- `DEBUG_DEFAULT_OTP`
- `DEBUG_BACKUP_OTP`
- `AUTO_VERIFY_DEBUG_OTP`
- `OTP_EXPIRES_MINUTES`

Recommended local defaults:

```env
DEBUG_AUTH_MODE=true
DEBUG_DEFAULT_OTP=1234567
DEBUG_BACKUP_OTP=0000000
AUTO_VERIFY_DEBUG_OTP=false
OTP_EXPIRES_MINUTES=10
```

## Default OTP Values

- Primary debug OTP: `1234567`
- Backup debug OTP: `0000000`

These values are read from env and can be changed without editing controller code.

## Switching To Real OTP Later

To move out of debug mode:

1. Set `DEBUG_AUTH_MODE=false`.
2. Keep the same registration, verify, and resend endpoints.
3. Wire `server/services/smsService.js` to the real SMS provider.
4. Keep `otp_sessions` and the JWT session flow unchanged.

## Risks And Precautions

- Never leave `DEBUG_AUTH_MODE=true` enabled silently in production.
- The server logs a startup warning whenever debug auth mode is enabled.
- Debug helper text should stay developer-only on the frontend.
- The accepted debug OTP values are referenced from env and not written to logs in plain text.
- `otp_sessions` must exist in Supabase before the flow is used. Apply [`server/sql/create_otp_sessions.sql`](./server/sql/create_otp_sessions.sql).
- If Supabase reports an OTP enum or column mismatch, run [`server/sql/add_enum_value.sql`](./server/sql/add_enum_value.sql) to sync the enum values, missing columns, and indexes.
- If Supabase reports `PGRST204` after columns were added, run [`server/sql/reload_schema_cache.sql`](./server/sql/reload_schema_cache.sql) to refresh the PostgREST schema cache.
