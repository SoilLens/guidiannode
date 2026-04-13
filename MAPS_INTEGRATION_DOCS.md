# Maps Integration

## Overview
GuardianNode now uses Google Maps for three separate jobs:

1. Map rendering in the Flutter client through `google_maps_flutter`.
2. Reverse geocoding on the backend through the Google Geocoding API.
3. Route generation on the backend through the Google Routes API.

Because this frontend is Flutter, not Vite, the app reads the Google Maps client key from Dart defines. For compatibility with the original requirement, the Flutter config accepts either `GOOGLE_MAPS_API_KEY` or `VITE_GOOGLE_MAPS_API_KEY`.

## Frontend Key Usage

### Primary client key
- `GOOGLE_MAPS_API_KEY`

### Supported alias
- `VITE_GOOGLE_MAPS_API_KEY`

### How it is used
- Web: `lib/features/emergency/services/google_maps_loader_web.dart` injects the Google Maps JavaScript API script at runtime before map widgets render.
- Android: `android/app/build.gradle.kts` reads the key from environment variables or `local.properties` and passes it into the manifest placeholder `GOOGLE_MAPS_API_KEY`.
- iOS: `ios/Runner/Info.plist` reads `$(GOOGLE_MAPS_API_KEY)`, and `ios/Runner/AppDelegate.swift` passes it into `GMSServices.provideAPIKey(...)`.

### Example Flutter launch
```bash
flutter run -d chrome ^
  --dart-define=API_BASE_URL=http://127.0.0.1:3000 ^
  --dart-define=GOOGLE_MAPS_API_KEY=your_client_key ^
  --dart-define=SUPABASE_URL=https://your-project.supabase.co ^
  --dart-define=SUPABASE_ANON_KEY=your_publishable_key
```

## Backend Key Usage

### Required server key
- `GOOGLE_MAPS_SERVER_API_KEY`

### Where it is used
- `server/services/mapService.js`

### What it powers
- `reverseGeocode(lat, lng)`
- `getRoute(origin, destination)`

This key stays on the backend only and is never exposed to the Flutter client.

## Maps JavaScript API Role
- Renders the live responder/victim map.
- Shows the user marker, victim marker, and active nearby alert markers.
- Supports camera centering and fit-bounds behavior on map screens.

## Geocoding API Role
- Converts raw `latitude` and `longitude` values into a readable address.
- Stores the latest readable address on `live_locations.formatted_address`.
- Feeds alert cards, victim tracking, and follow mode route context.

## Routes API Role
- Computes the responder-to-victim route.
- Returns normalized fields:
  - `distance_meters`
  - `distance_text`
  - `duration_seconds`
  - `duration_text`
  - `encoded_polyline`

## Supabase Realtime Requirements
The Flutter app also needs:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

The backend already uses `SUPABASE_SERVICE_ROLE_KEY`, but the client must use the public publishable/anon key for subscriptions. The service-role key must never be shipped to the frontend.

## Platform Notes
- Web geolocation requires HTTPS or localhost.
- Android requires `ACCESS_COARSE_LOCATION` and `ACCESS_FINE_LOCATION`.
- iOS requires `NSLocationWhenInUseUsageDescription`.
- If you build for iOS, set `GOOGLE_MAPS_API_KEY` in `ios/Flutter/Debug.xcconfig` and `ios/Flutter/Release.xcconfig` or through your CI/Xcode build settings.
