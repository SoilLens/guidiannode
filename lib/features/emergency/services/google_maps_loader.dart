import 'package:flutter/foundation.dart';

import '../../../core/config/app_config.dart';
import 'google_maps_loader_stub.dart'
    if (dart.library.html) 'google_maps_loader_web.dart'
    as loader;

class GoogleMapsLoader {
  static Future<void> ensureLoaded() async {
    if (!kIsWeb) {
      return;
    }

    await loader.ensureGoogleMapsLoaded(AppConfig.googleMapsApiKey);
  }
}
