# guidiannode

A new Flutter project.

## Local auth backend

The Node backend lives in `server/` and serves auth endpoints at `http://localhost:3000/api/auth`.

Start it with:

```bash
cd server
npm start
```

Health check:

```bash
http://127.0.0.1:3000/health
```

## Running the Flutter app against local auth

Android emulator can use the built-in default:

```bash
flutter run
```

That default is `http://10.0.2.2:3000/api/auth`, which only works inside the Android emulator.

For a physical Android phone, use one of these:

```bash
adb reverse tcp:3000 tcp:3000
flutter run --dart-define=API_AUTH_BASE_URL=http://127.0.0.1:3000/api/auth
```

```bash
flutter run --dart-define=API_AUTH_BASE_URL=http://<your-computer-ip>:3000/api/auth
```

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
