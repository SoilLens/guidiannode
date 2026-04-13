import 'package:geolocator/geolocator.dart';

import '../models/emergency_models.dart';

class DeviceLocationService {
  static Future<LocationPermissionResult> requestCurrentSnapshot() async {
    final isLocationServiceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!isLocationServiceEnabled) {
      return const LocationPermissionResult(
        granted: false,
        message:
            'Location services are turned off. Please enable GPS or browser location and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return const LocationPermissionResult(
        granted: false,
        message:
            'Location access was denied. GuardianNode needs your location to coordinate emergency response.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return const LocationPermissionResult(
        granted: false,
        message:
            'Location access is permanently denied. Please re-enable it in your device or browser settings.',
      );
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    );

    return LocationPermissionResult(
      granted: true,
      snapshot: PositionSnapshot.fromPosition(position),
    );
  }

  static Stream<PositionSnapshot> getPositionStream({
    LocationAccuracy accuracy = LocationAccuracy.high,
    int distanceFilter = 10,
  }) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: accuracy,
        distanceFilter: distanceFilter,
      ),
    ).map(PositionSnapshot.fromPosition);
  }
}
