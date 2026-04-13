# Frontend Map Flow

## Frontend Stack Reality
This project’s frontend is Flutter, so the implementation uses:

- `geolocator` for permission and live position streams
- `google_maps_flutter` for map rendering
- `supabase_flutter` for realtime subscriptions

The original `VITE_GOOGLE_MAPS_API_KEY` requirement is still supported as an alias, but Flutter consumes it through Dart defines.

## 1. Requesting Location
- Login and registration toggles call `EmergencyCoordinator.previewLocationPermission(...)`.
- The dashboard uses `EmergencyCoordinator.setLocationSharingEnabled(...)` to persist the authenticated state.
- The coordinator uses `DeviceLocationService.requestCurrentSnapshot()` to:
  - check location services
  - request permission
  - get the initial device position

## 2. Loading Google Maps
- `GoogleMapsLoader.ensureLoaded()` is called before map screens render.
- Web:
  - `google_maps_loader_web.dart` injects the Maps JavaScript API script dynamically.
- Mobile:
  - platform configuration comes from Android manifest placeholders and iOS `GMSApiKey`.

## 3. Realtime Subscriptions
- `SupabaseRealtimeService` initializes `supabase_flutter`.
- `DashboardScreen` subscribes to:
  - `notifications` filtered by `user_id`
  - the shared emergency feed on `alerts` and `live_locations`
- `ResponderFollowScreen` subscribes to `live_locations` filtered by `alert_id`

## 4. Location Watchers
- `EmergencyCoordinator` owns the main passive/active device position stream.
- Passive sharing writes to `/api/location/update`.
- Active SOS writes to `/api/alerts/:alertId/location`.
- `ResponderFollowScreen` creates its own responder-only stream so route recalculation uses the responder’s live location.

## 5. Route Updates
- `ResponderFollowScreen` requests route data through `/api/alerts/:alertId/follow`.
- The route refreshes only when needed:
  - about 20 seconds passed
  - or the victim moved about 30 meters
  - or the responder moved about 30 meters
- The frontend decodes the backend polyline with `decodeEncodedPolyline(...)` and renders it as a Google Maps `Polyline`.

## 6. Marker Updates
- Dashboard map:
  - current user marker
  - nearby active alert markers
- Active SOS map:
  - victim/current-user marker
- Responder follow map:
  - responder marker
  - victim marker
  - route polyline

## 7. Cleanup
- `DashboardScreen` unsubscribes from Supabase channels on dispose.
- `ResponderFollowScreen` unsubscribes from:
  - the alert location realtime channel
  - the responder geolocation stream
- `EmergencyCoordinator` stops the passive position stream when sharing is turned off and no active alert is running.

## 8. Key Frontend Files
- `lib/features/emergency/services/emergency_coordinator.dart`
- `lib/features/emergency/services/device_location_service.dart`
- `lib/features/emergency/services/emergency_api_service.dart`
- `lib/features/emergency/services/supabase_realtime_service.dart`
- `lib/features/emergency/services/google_maps_loader.dart`
- `lib/features/emergency/screens/dashboard_screen.dart`
- `lib/features/emergency/screens/active_sos_map_screen.dart`
- `lib/features/emergency/screens/responder_follow_screen.dart`
