# Backend Auth Flow

## Register Flow In Debug Mode

1. `POST /api/auth/register` validates:
   - `full_name`
   - `phone_number`
   - `quarter`
   - optional coordinates
   - one emergency contact
2. The backend stores the full registration payload in `otp_sessions.registration_payload`.
3. The OTP session is marked with debug metadata:
   - `mode: "debug"`
   - `auto_verify_ready`
   - env references for accepted debug codes
4. No SMS provider is called.
5. The response returns:
   - `otp_session_id`
   - `phone_number`
   - `expires_at`
   - `next_step: "verify_otp"`

## Verify OTP Flow In Debug Mode

1. `POST /api/auth/verify-otp` loads the pending OTP session.
2. The backend checks expiry and attempt limits.
3. Debug verification accepts env-configured codes only.
4. When the code is valid:
   - the OTP session becomes `verified`
   - the user profile is created or updated without duplicates
   - the initial emergency contact is created or updated
   - a JWT app session is signed and returned

## Resend OTP Flow In Debug Mode

1. `POST /api/auth/resend-otp` loads the latest registration or login session.
2. Existing pending OTP sessions for the same phone and purpose are cancelled.
3. A fresh debug OTP session is created.
4. No SMS is sent.

## Real Mode Vs Debug Mode

Debug mode:

- Uses env OTP values.
- Skips SMS delivery.
- Logs debug-session creation clearly.

Real mode:

- Generates a unique OTP.
- Stores only the OTP hash in `otp_sessions`.
- Delegates delivery to `server/services/smsService.js`.
- Reuses the same verify and resend flow.

## Session Creation Flow

After successful OTP verification:

1. The backend finalizes the login or registration purpose.
2. A JWT is signed with:
   - `sub`
   - `phone_number`
   - token type metadata
3. The response includes:
   - `access_token`
   - `token_type`
   - `expires_in`
   - `issued_at`
   - `expires_at`
   - user payload
