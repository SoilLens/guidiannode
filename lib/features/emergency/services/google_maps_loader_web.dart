// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

Future<void>? _loadingFuture;

String _resolveApiKey(String apiKey) {
  if (apiKey.trim().isNotEmpty) {
    return apiKey.trim();
  }

  final metaTag = html.document.querySelector(
    'meta[name="google-maps-api-key"]',
  );
  final metaKey = metaTag?.getAttribute('content')?.trim() ?? '';

  if (metaKey.isNotEmpty) {
    return metaKey;
  }

  throw StateError(
    'Google Maps API key is missing. Set GOOGLE_MAPS_API_KEY/VITE_GOOGLE_MAPS_API_KEY or add the web meta tag.',
  );
}

bool get _isGoogleMapsReady {
  final dynamic window = html.window;
  final dynamic google = window.google;
  return google != null && google.maps != null;
}

Future<void> ensureGoogleMapsLoaded(String apiKey) {
  final resolvedApiKey = _resolveApiKey(apiKey);

  if (_isGoogleMapsReady) {
    return Future<void>.value();
  }

  if (_loadingFuture != null) {
    return _loadingFuture!;
  }

  final completer = Completer<void>();
  _loadingFuture = completer.future;

  final existingScript = html.document.querySelector(
    'script[data-guardian-node-google-maps="true"]',
  );

  if (existingScript == null) {
    final script = html.ScriptElement()
      ..async = true
      ..defer = true
      ..src =
          'https://maps.googleapis.com/maps/api/js?key=$resolvedApiKey&loading=async'
      ..setAttribute('data-guardian-node-google-maps', 'true');
    html.document.head?.children.add(script);
  }

  late Timer poller;
  poller = Timer.periodic(const Duration(milliseconds: 100), (timer) {
    if (_isGoogleMapsReady) {
      poller.cancel();
      completer.complete();
      return;
    }

    if (timer.tick >= 200) {
      poller.cancel();
      completer.completeError(
        StateError('Timed out while loading Google Maps JavaScript API.'),
      );
    }
  });

  return _loadingFuture!;
}
