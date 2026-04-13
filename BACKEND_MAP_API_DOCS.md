# Backend Map API Docs

## POST `/api/location/update`

### Purpose
Persists the authenticated user’s location-sharing preference and latest known coordinates.

### Auth
- Required
- Uses the custom JWT session issued by GuardianNode auth

### Request Body
```json
{
  "location_permission": true,
  "latitude": 5.9597,
  "longitude": 10.1453,
  "accuracy": 12.4,
  "heading": 180,
  "speed": 0.8,
  "source": "device"
}
```

### Validation Rules
- `location_permission` is required.
- If `location_permission` is `true`, both `latitude` and `longitude` must be present.
- `latitude` must be between `-90` and `90`.
- `longitude` must be between `-180` and `180`.

### Response Shape
```json
{
  "success": true,
  "message": "Location sharing preferences updated successfully.",
  "data": {
    "user": {
      "...": "updated users row"
    }
  },
  "meta": null
}
```

### Side Effects
- Updates `users.location_permission`
- Updates `users.latitude`
- Updates `users.longitude`
- Updates `users.updated_at`

## POST `/api/alerts/sos`

### Purpose
Creates a new active emergency alert using the authenticated user’s current location.

### Auth
- Required

### Request Body
```json
{
  "emergency_type": "general_distress",
  "description": "Emergency raised from GuardianNode",
  "latitude": 5.9597,
  "longitude": 10.1453,
  "accuracy": 8.1,
  "heading": 90,
  "speed": 0.2,
  "source": "device"
}
```

### Validation Rules
- `emergency_type` is required.
- `latitude` and `longitude` are required.
- Coordinates must be valid geographic values.

### Response Shape
```json
{
  "success": true,
  "message": "SOS alert created successfully.",
  "data": {
    "id": "alert-uuid",
    "user_id": "victim-uuid",
    "victim_id": "victim-uuid",
    "emergency_type": "general_distress",
    "status": "active",
    "latitude": 5.9597,
    "longitude": 10.1453,
    "readable_address": "Commercial Avenue, Bamenda, Cameroon",
    "locality": "Bamenda",
    "created_at": "2026-03-17T10:00:00.000Z",
    "updated_at": "2026-03-17T10:00:00.000Z",
    "notified_user_count": 4
  },
  "meta": null
}
```

### Side Effects
- Inserts into `alerts`
- Upserts into `live_locations`
- Updates the victim row in `users`
- Inserts `incident_logs`
- Inserts nearby `notifications`
- Triggers Supabase Realtime through table changes

## POST `/api/alerts/:alertId/location`

### Purpose
Updates the live SOS location for the alert owner.

### Auth
- Required
- The authenticated user must own the alert

### Request Body
```json
{
  "latitude": 5.9601,
  "longitude": 10.1462,
  "accuracy": 7.5,
  "heading": 110,
  "speed": 1.3,
  "source": "device"
}
```

### Validation Rules
- `alertId` must be a UUID.
- Coordinates are required and must be valid.
- Alert must exist and remain `active`.

### Response Shape
```json
{
  "success": true,
  "message": "Live alert location updated successfully.",
  "data": {
    "id": "live-location-uuid",
    "alert_id": "alert-uuid",
    "user_id": "victim-uuid",
    "latitude": 5.9601,
    "longitude": 10.1462,
    "formatted_address": "Food Market Road, Bamenda, Cameroon",
    "locality": "Bamenda",
    "updated_at": "2026-03-17T10:00:12.000Z",
    "skipped": false
  },
  "meta": null
}
```

### Side Effects
- Upserts the latest row in `live_locations`
- Updates `alerts.latitude`, `alerts.longitude`, and `alerts.updated_at`
- Emits Supabase Realtime `INSERT` or `UPDATE` events on `live_locations`

## GET `/api/alerts/nearby`

### Purpose
Returns active alerts near the requester’s supplied coordinates.

### Auth
- Required

### Query Params
- `lat`
- `lng`
- `radius_meters` optional, default `3000`

### Validation Rules
- Coordinates are required.
- `radius_meters` must be between `1` and `20000`.

### Response Shape
```json
{
  "success": true,
  "message": "Nearby active alerts fetched successfully.",
  "data": {
    "center": {
      "latitude": 5.9597,
      "longitude": 10.1453
    },
    "radius_meters": 3000,
    "alerts": [
      {
        "id": "alert-uuid",
        "emergency_type": "medical",
        "status": "active",
        "latitude": 5.9611,
        "longitude": 10.1478,
        "readable_address": "Up Station, Bamenda, Cameroon",
        "distance_meters": 420
      }
    ]
  },
  "meta": null
}
```

### Side Effects
- Reads `alerts`, `live_locations`, and `users`
- No writes

## GET `/api/alerts/:alertId/follow`

### Purpose
Returns route-ready victim details for responder follow mode.

### Auth
- Required

### Query Params
- `origin_lat` optional
- `origin_lng` optional
- `travel_mode` optional, default `DRIVE`

### Validation Rules
- `alertId` must be a UUID.
- If `origin_lat` is provided, `origin_lng` must also be provided.
- `travel_mode` currently accepts:
  - `DRIVE`
  - `TWO_WHEELER`
  - `WALK`

### Response Shape
```json
{
  "success": true,
  "message": "Responder follow details fetched successfully.",
  "data": {
    "alert": {
      "...": "normalized alert payload"
    },
    "victim": {
      "id": "victim-uuid",
      "full_name": "Jane Doe",
      "phone_number": "+237..."
    },
    "victim_location": {
      "latitude": 5.9601,
      "longitude": 10.1462,
      "readable_address": "Food Market Road, Bamenda, Cameroon",
      "locality": "Bamenda",
      "updated_at": "2026-03-17T10:00:12.000Z"
    },
    "route": {
      "distance_meters": 1200,
      "distance_text": "1.2 km",
      "duration_seconds": 360,
      "duration_text": "6 min",
      "encoded_polyline": "..."
    }
  },
  "meta": null
}
```

### Side Effects
- Reads `alerts`, `live_locations`, and `users`
- Calls Google Routes API when origin coordinates are supplied
- Calls Google Geocoding API only if the stored live location lacks an address
