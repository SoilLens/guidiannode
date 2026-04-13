import 'dart:math' as math;

import '../models/emergency_models.dart';

double distanceInMeters(PositionSnapshot origin, PositionSnapshot destination) {
  const earthRadiusMeters = 6371000.0;
  final latitudeDelta = _toRadians(destination.latitude - origin.latitude);
  final longitudeDelta = _toRadians(destination.longitude - origin.longitude);
  final originLatitude = _toRadians(origin.latitude);
  final destinationLatitude = _toRadians(destination.latitude);

  final haversineComponent =
      math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(originLatitude) *
          math.cos(destinationLatitude) *
          math.pow(math.sin(longitudeDelta / 2), 2);
  final angularDistance =
      2 *
      math.atan2(
        math.sqrt(haversineComponent.toDouble()),
        math.sqrt(1 - haversineComponent.toDouble()),
      );

  return earthRadiusMeters * angularDistance;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
