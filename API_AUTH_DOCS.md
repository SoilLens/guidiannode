# API Auth Docs

## `POST /api/auth/register`

### Request Body

```json
{
  "full_name": "Jane Doe",
  "phone_number": "+237612345678",
  "quarter": "Up Station",
  "location_permission": false,
  "latitude": null,
  "longitude": null,
  "emergency_contact": {
    "contact_name": "John Doe",
    "phone_number": "+237699999999",
    "relationship": "Family Member"
  }
}
```

### Validation

- `full_name`: required string
- `phone_number`: required normalized phone number
- `quarter`: required string
- `latitude` and `longitude`: optional, but must be supplied together when present
- `emergency_contact.contact_name`: required
- `emergency_contact.phone_number`: required
- `emergency_contact.relationship`: required

### Success Response Shape

```json
{
  "success": true,
  "message": "Registration details accepted. Continue to OTP verification.",
  "otp_session_id": "uuid",
  "phone_number": "+237612345678",
  "expires_at": "2026-03-15T12:00:00.000Z",
  "next_step": "verify_otp",
  "auto_verify_ready": false,
  "debug": {
    "mode": "debug",
    "helper_message": "Debug OTP mode enabled. Use code 123456."
  }
}
```

### Debug Mode Behavior

- Stores registration payload in `otp_sessions`.
- Skips SMS delivery.
- Returns a debug helper payload when enabled.

### Real Mode Behavior

- Generates a real OTP session.
- Stores the OTP hash.
- Calls `smsService` for delivery.

## `POST /api/auth/verify-otp`

### Request Body

```json
{
  "phone_number": "+237612345678",
  "otp_code": "123456",
  "otp_session_id": "uuid"
}
```

### Validation

- `phone_number`: required normalized phone number
- `otp_code`: required 6-digit string
- `otp_session_id`: optional UUID

### Success Response Shape

```json
{
  "success": true,
  "message": "OTP verified. Registration completed successfully.",
  "session": {
    "access_token": "jwt",
    "token_type": "Bearer",
    "expires_in": 604800,
    "issued_at": "2026-03-15T12:00:00.000Z",
    "expires_at": "2026-03-22T12:00:00.000Z",
    "user": {
      "id": "uuid",
      "phone_number": "+237612345678"
    }
  },
  "user": {
    "id": "uuid",
    "phone_number": "+237612345678"
  },
  "redirect": "/dashboard"
}
```

### Debug Mode Behavior

- Accepts `DEBUG_DEFAULT_OTP` and `DEBUG_BACKUP_OTP`.
- Finalizes registration or login without SMS delivery.

### Real Mode Behavior

- Verifies the hashed OTP stored in `otp_sessions`.
- Finalizes registration or login the same way after a valid code.

## `POST /api/auth/resend-otp`

### Request Body

```json
{
  "phone_number": "+237612345678",
  "otp_session_id": "uuid"
}
```

### Validation

- `phone_number`: required normalized phone number
- `otp_session_id`: optional UUID

### Success Response Shape

```json
{
  "success": true,
  "message": "OTP resent successfully",
  "otp_session_id": "uuid",
  "phone_number": "+237612345678",
  "expires_at": "2026-03-15T12:05:00.000Z",
  "next_step": "verify_otp",
  "auto_verify_ready": false
}
```

### Debug Mode Behavior

- Creates a fresh debug OTP session.
- Does not send SMS.

### Real Mode Behavior

- Cancels the old pending session.
- Creates a new OTP session.
- Sends a new OTP through `smsService`.
