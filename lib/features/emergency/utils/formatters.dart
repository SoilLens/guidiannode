String formatEmergencyType(String emergencyType) {
  return emergencyType
      .split('_')
      .where((segment) => segment.isNotEmpty)
      .map(
        (segment) =>
            segment[0].toUpperCase() + segment.substring(1).toLowerCase(),
      )
      .join(' ');
}

String formatDistance(double? distanceMeters) {
  if (distanceMeters == null) {
    return '--';
  }

  if (distanceMeters < 1000) {
    return '${distanceMeters.toStringAsFixed(0)}m';
  }

  return '${(distanceMeters / 1000).toStringAsFixed(1)}km';
}

String formatRelativeTime(DateTime? timestamp) {
  if (timestamp == null) {
    return 'Now';
  }

  final elapsed = DateTime.now().difference(timestamp);

  if (elapsed.inSeconds < 60) {
    return 'Just now';
  }

  if (elapsed.inMinutes < 60) {
    return '${elapsed.inMinutes}m ago';
  }

  if (elapsed.inHours < 24) {
    return '${elapsed.inHours}h ago';
  }

  return '${elapsed.inDays}d ago';
}
