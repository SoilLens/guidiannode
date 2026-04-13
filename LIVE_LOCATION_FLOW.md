# Live Location Flow

## 1. Enable Location Sharing
- The login and registration location toggles now request device/browser location permission immediately.
- After authentication, `DashboardScreen` can bootstrap that preference into the authenticated flow.
- The Flutter coordinator captures the current position and posts it to `POST /api/location/update`.
- The backend persists:
  - `users.location_permission`
  - `users.latitude`
  - `users.longitude`
  - `users.updated_at`

## 2. Passive Location Sync
- Once location sharing is enabled, `EmergencyCoordinator` starts a geolocation stream.
- Passive user location writes are throttled to avoid excessive writes.
- Current thresholds:
  - at least 30 seconds
  - or about 50 meters moved

This keeps the `users` table reasonably fresh so nearby-user selection has useful coordinates.

## 3. SOS Creation
- The user presses the SOS button from the dashboard.
- The frontend ensures a location exists.
- The frontend calls `POST /api/alerts/sos`.
- The backend:
  - validates coordinates
  - creates the `alerts` row
  - reverse geocodes the coordinates
  - upserts the first `live_locations` row
  - writes an `incident_logs` row
  - finds nearby users
  - inserts `notifications` rows for them

## 4. Live Tracking
- After SOS activation, the same device location stream continues running.
- The frontend now starts sending alert-specific location updates to `POST /api/alerts/:alertId/location`.
- Active SOS writes are throttled more aggressively for tracking.
- Current thresholds:
  - at least 6 seconds
  - or about 20 meters moved

The backend updates:
- `live_locations`
- `alerts.latitude`
- `alerts.longitude`
- `alerts.updated_at`

## 5. Nearby Broadcast
- Nearby users subscribe to Supabase Realtime on:
  - `notifications`
  - `alerts`
  - `live_locations`
- New SOS incidents arrive through `notifications`.
- List/map refreshes are triggered from the shared emergency feed subscription.

## 6. Victim Live Map
- The victim opens `ActiveSosMapScreen`.
- The map centers on the victim location.
- The screen shows:
  - emergency type
  - readable address
  - live marker
  - sync status

## 7. Responder Follow Flow
- A nearby user opens an alert from the list or map.
- `ResponderFollowScreen` requests the responder’s current position.
- The frontend calls `GET /api/alerts/:alertId/follow?origin_lat=...&origin_lng=...`.
- The backend returns:
  - alert metadata
  - victim profile data
  - victim latest location
  - readable address
  - route payload

The responder screen then:
- subscribes to `live_locations` for that alert
- updates the victim marker in realtime
- refreshes the route only when needed

## 8. Route Refresh Rules
- Route recomputation is not continuous.
- The responder screen refreshes when:
  - about 20 seconds have elapsed
  - or the victim moved about 30 meters
  - or the responder moved about 30 meters

## 9. Cleanup
- Geolocation streams are owned by the coordinator or follow screen and cleaned up on dispose.
- Supabase Realtime channels are unsubscribed when screens close.
- The passive stream stops when sharing is disabled and no active SOS exists.
