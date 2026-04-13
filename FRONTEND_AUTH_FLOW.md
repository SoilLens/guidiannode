# Frontend Auth Flow

## Registration To OTP Navigation

1. The registration form still looks the same.
2. Submitting the form now sends the full payload to `POST /api/auth/register`.
3. On success, the app still opens the OTP verification screen.
4. The frontend carries forward:
   - `phoneNumber`
   - `otpSessionId`
   - optional debug helper text

## Debug OTP Entry

- The OTP screen is unchanged visually.
- When backend debug data is returned and `SHOW_DEBUG_OTP_HELPER=true`, the screen shows a subtle helper message.
- Entering the configured debug code completes verification like a real OTP.

## Dashboard Redirect

After `POST /api/auth/verify-otp` succeeds:

1. The frontend stores the returned JWT session in `SessionService`.
2. The app routes to `DashboardScreen`.

## Handling Debug Helper Text

- Helper text is controlled in Flutter through `lib/core/config/app_config.dart`.
- Set `SHOW_DEBUG_OTP_HELPER=true` with `--dart-define` to display it.
- Set `SHOW_DEBUG_OTP_HELPER=false` to hide it without touching UI code.

## Future Compatibility With Real OTP

- The frontend already uses the same register, verify, and resend endpoints real mode will use.
- Switching to real OTP later does not require new screens.
- The OTP screen, loading states, and redirect flow remain the same.
