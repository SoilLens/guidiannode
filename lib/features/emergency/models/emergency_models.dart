import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

enum GuardianLocationStatus {
  notRequested,
  fetching,
  ready,
  usingLastKnown,
  permissionDenied,
  permissionDeniedForever,
  serviceDisabled,
  failed,
}

double? _toDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

DateTime? _toDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}

class PositionSnapshot {
  const PositionSnapshot({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.heading,
    this.speed,
    this.readableAddress,
    this.locality,
    this.capturedAt,
    this.skipped = false,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? heading;
  final double? speed;
  final String? readableAddress;
  final String? locality;
  final DateTime? capturedAt;
  final bool skipped;

  LatLng get latLng => LatLng(latitude, longitude);

  String get displayAddress => readableAddress?.trim().isNotEmpty == true
      ? readableAddress!.trim()
      : locality?.trim().isNotEmpty == true
      ? locality!.trim()
      : 'Location ready';

  PositionSnapshot copyWith({
    double? latitude,
    double? longitude,
    double? accuracy,
    double? heading,
    double? speed,
    String? readableAddress,
    String? locality,
    DateTime? capturedAt,
    bool? skipped,
  }) {
    return PositionSnapshot(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracy: accuracy ?? this.accuracy,
      heading: heading ?? this.heading,
      speed: speed ?? this.speed,
      readableAddress: readableAddress ?? this.readableAddress,
      locality: locality ?? this.locality,
      capturedAt: capturedAt ?? this.capturedAt,
      skipped: skipped ?? this.skipped,
    );
  }

  factory PositionSnapshot.fromPosition(Position position) {
    return PositionSnapshot(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      heading: position.heading,
      speed: position.speed,
      capturedAt: position.timestamp,
    );
  }

  factory PositionSnapshot.fromJson(Map<String, dynamic> json) {
    return PositionSnapshot(
      latitude: _toDouble(json['latitude']) ?? 0,
      longitude: _toDouble(json['longitude']) ?? 0,
      accuracy: _toDouble(json['accuracy']),
      heading: _toDouble(json['heading']),
      speed: _toDouble(json['speed']),
      readableAddress:
          json['readable_address']?.toString() ??
          json['formatted_address']?.toString(),
      locality: json['locality']?.toString(),
      capturedAt:
          _toDateTime(json['updated_at']) ??
          _toDateTime(json['captured_at']) ??
          _toDateTime(json['created_at']),
      skipped: json['skipped'] == true,
    );
  }

  Map<String, dynamic> toUserLocationPayload({
    required bool locationPermission,
    String source = 'device',
  }) {
    return {
      'location_permission': locationPermission,
      if (locationPermission) ...{
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'heading': heading,
        'speed': speed,
        'source': source,
      },
    };
  }

  Map<String, dynamic> toAlertLocationPayload({String source = 'device'}) {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'heading': heading,
      'speed': speed,
      'source': source,
    };
  }
}

class VictimProfile {
  const VictimProfile({
    required this.id,
    this.fullName,
    this.phoneNumber,
    this.quarter,
  });

  final String id;
  final String? fullName;
  final String? phoneNumber;
  final String? quarter;

  factory VictimProfile.fromJson(Map<String, dynamic> json) {
    return VictimProfile(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      quarter: json['quarter']?.toString(),
    );
  }
}

/// Advisory-only category/urgency taxonomy shared with the backend. Never
/// treat these values as confirmation that an incident is real -- a human
/// (the reporter or a moderator) always has the final say.
class IncidentClassification {
  const IncidentClassification({
    required this.category,
    required this.urgency,
    required this.detectedLanguage,
    required this.explanation,
    required this.confidence,
    required this.recommendedAction,
    required this.requiresModeratorAttention,
    required this.possibleSpam,
    required this.assistanceNeeded,
    required this.classificationSource,
  });

  final String category;
  final String urgency;
  final String detectedLanguage;
  final String explanation;
  final double confidence;
  final String recommendedAction;
  final bool requiresModeratorAttention;
  final bool possibleSpam;
  final List<String> assistanceNeeded;
  final String classificationSource;

  bool get isAiGenerated => classificationSource == 'ai';
  bool get isRuleBased => classificationSource == 'rules';

  factory IncidentClassification.fromJson(Map<String, dynamic> json) {
    return IncidentClassification(
      category: json['category']?.toString() ?? 'other',
      urgency: json['urgency']?.toString() ?? 'medium',
      detectedLanguage: json['detected_language']?.toString() ?? 'unknown',
      explanation: json['explanation']?.toString() ?? '',
      confidence: _toDouble(json['confidence']) ?? 0,
      recommendedAction: json['recommended_action']?.toString() ?? '',
      requiresModeratorAttention: json['requires_moderator_attention'] == true,
      possibleSpam: json['possible_spam'] == true,
      assistanceNeeded: List<String>.from(
        (json['assistance_needed'] as List? ?? const <dynamic>[]).map(
          (value) => value.toString(),
        ),
      ),
      classificationSource: json['classification_source']?.toString() ?? 'rules',
    );
  }
}

class EmergencyAlert {
  const EmergencyAlert({
    required this.id,
    required this.userId,
    required this.emergencyType,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.description,
    this.readableAddress,
    this.locality,
    this.distanceMeters,
    this.createdAt,
    this.updatedAt,
    this.resolvedAt,
    this.victim,
    this.confirmedCategory,
    this.urgencyLevel,
    this.detectedLanguage = 'unknown',
    this.classificationSource,
    this.aiExplanation,
    this.verificationStatus = 'unverified',
    this.visibilityLevel = 'standard',
    this.moderationStatus = 'pending_review',
    this.peopleAffected,
    this.assistanceNeeded = const <String>[],
    this.communityConfirmations = 0,
    this.disputeCount = 0,
    this.falseReportCount = 0,
    this.myConfirmationType,
  });

  final String id;
  final String userId;
  final String emergencyType;
  final String? description;
  final double latitude;
  final double longitude;
  final String status;
  final String? readableAddress;
  final String? locality;
  final double? distanceMeters;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? resolvedAt;
  final VictimProfile? victim;
  final String? confirmedCategory;
  final String? urgencyLevel;
  final String detectedLanguage;
  final String? classificationSource;
  final String? aiExplanation;
  final String verificationStatus;
  final String visibilityLevel;
  final String moderationStatus;
  final int? peopleAffected;
  final List<String> assistanceNeeded;
  final int communityConfirmations;
  final int disputeCount;
  final int falseReportCount;
  final String? myConfirmationType;

  LatLng get latLng => LatLng(latitude, longitude);

  /// Category used for display purposes -- falls back to a mapped legacy
  /// quick-SOS type so older alerts still render a sensible marker/badge.
  String get displayCategory =>
      confirmedCategory ?? _legacyCategoryFor(emergencyType);

  bool get isVerifiedByAuthority =>
      verificationStatus == 'responder_confirmed' ||
      verificationStatus == 'officially_confirmed';
  bool get isDisputedOrFalse =>
      verificationStatus == 'disputed' || verificationStatus == 'false_report';
  bool get isSensitive => visibilityLevel == 'sensitive';

  String get displayAddress => readableAddress?.trim().isNotEmpty == true
      ? readableAddress!.trim()
      : locality?.trim().isNotEmpty == true
      ? locality!.trim()
      : 'Approximate location only';

  EmergencyAlert copyWith({
    double? latitude,
    double? longitude,
    String? status,
    String? readableAddress,
    String? locality,
    DateTime? updatedAt,
    DateTime? resolvedAt,
    String? verificationStatus,
    int? communityConfirmations,
    int? disputeCount,
    int? falseReportCount,
    String? myConfirmationType,
  }) {
    return EmergencyAlert(
      id: id,
      userId: userId,
      emergencyType: emergencyType,
      description: description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      status: status ?? this.status,
      readableAddress: readableAddress ?? this.readableAddress,
      locality: locality ?? this.locality,
      distanceMeters: distanceMeters,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
      victim: victim,
      confirmedCategory: confirmedCategory,
      urgencyLevel: urgencyLevel,
      detectedLanguage: detectedLanguage,
      classificationSource: classificationSource,
      aiExplanation: aiExplanation,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      visibilityLevel: visibilityLevel,
      moderationStatus: moderationStatus,
      peopleAffected: peopleAffected,
      assistanceNeeded: assistanceNeeded,
      communityConfirmations: communityConfirmations ?? this.communityConfirmations,
      disputeCount: disputeCount ?? this.disputeCount,
      falseReportCount: falseReportCount ?? this.falseReportCount,
      myConfirmationType: myConfirmationType ?? this.myConfirmationType,
    );
  }

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) {
    final victimJson = json['victim'];
    final confirmationCounts = json['confirmation_counts'];
    return EmergencyAlert(
      id: json['id']?.toString() ?? '',
      userId:
          json['user_id']?.toString() ?? json['victim_id']?.toString() ?? '',
      emergencyType: json['emergency_type']?.toString() ?? 'general_distress',
      description: json['description']?.toString(),
      latitude: _toDouble(json['latitude']) ?? 0,
      longitude: _toDouble(json['longitude']) ?? 0,
      status: json['status']?.toString() ?? 'active',
      readableAddress:
          json['readable_address']?.toString() ??
          json['formatted_address']?.toString(),
      locality: json['locality']?.toString(),
      distanceMeters: _toDouble(json['distance_meters']),
      createdAt: _toDateTime(json['created_at']),
      updatedAt: _toDateTime(json['updated_at']),
      resolvedAt: _toDateTime(json['resolved_at']),
      victim: victimJson is Map<String, dynamic>
          ? VictimProfile.fromJson(victimJson)
          : null,
      confirmedCategory: json['confirmed_category']?.toString(),
      urgencyLevel: json['urgency_level']?.toString(),
      detectedLanguage: json['detected_language']?.toString() ?? 'unknown',
      classificationSource: json['classification_source']?.toString(),
      aiExplanation: json['ai_explanation']?.toString(),
      verificationStatus:
          json['verification_status']?.toString() ?? 'unverified',
      visibilityLevel: json['visibility_level']?.toString() ?? 'standard',
      moderationStatus:
          json['moderation_status']?.toString() ?? 'pending_review',
      peopleAffected: json['people_affected'] == null
          ? null
          : int.tryParse(json['people_affected'].toString()),
      assistanceNeeded: List<String>.from(
        (json['assistance_needed'] as List? ?? const <dynamic>[]).map(
          (value) => value.toString(),
        ),
      ),
      communityConfirmations: confirmationCounts is Map
          ? int.tryParse(
                  confirmationCounts['community_confirm']?.toString() ?? '0',
                ) ??
                0
          : 0,
      disputeCount: confirmationCounts is Map
          ? int.tryParse(confirmationCounts['dispute']?.toString() ?? '0') ?? 0
          : 0,
      falseReportCount: confirmationCounts is Map
          ? int.tryParse(
                  confirmationCounts['false_report']?.toString() ?? '0',
                ) ??
                0
          : 0,
      myConfirmationType: json['my_confirmation_type']?.toString(),
    );
  }
}

const Map<String, String> _legacyEmergencyTypeToCategory = {
  'security': 'security_threat',
  'medical': 'medical_emergency',
  'fire': 'fire',
  'accident': 'road_accident',
  'general_distress': 'other',
};

const Set<String> _incidentTaxonomyValues = {
  'security_threat',
  'medical_emergency',
  'fire',
  'road_accident',
  'missing_person',
  'gender_based_violence',
  'natural_disaster',
  'flooding_landslide',
  'food_water_request',
  'shelter_request',
  'infrastructure_hazard',
  'public_health_concern',
  'other',
};

/// `emergency_type` may already be a full taxonomy value (quick-report
/// buttons send these directly) or one of the five original quick-SOS
/// values -- either way this always resolves to something the shared
/// category badge/marker UI understands.
String _legacyCategoryFor(String emergencyType) {
  if (_incidentTaxonomyValues.contains(emergencyType)) {
    return emergencyType;
  }

  return _legacyEmergencyTypeToCategory[emergencyType] ?? 'other';
}

class RouteSummary {
  const RouteSummary({
    required this.distanceMeters,
    required this.distanceText,
    required this.durationSeconds,
    required this.durationText,
    this.encodedPolyline,
    this.travelMode,
  });

  final double distanceMeters;
  final String distanceText;
  final int durationSeconds;
  final String durationText;
  final String? encodedPolyline;
  final String? travelMode;

  factory RouteSummary.fromJson(Map<String, dynamic> json) {
    return RouteSummary(
      distanceMeters: _toDouble(json['distance_meters']) ?? 0,
      distanceText: json['distance_text']?.toString() ?? '0 m',
      durationSeconds: (_toDouble(json['duration_seconds']) ?? 0).round(),
      durationText: json['duration_text']?.toString() ?? '0 min',
      encodedPolyline: json['encoded_polyline']?.toString(),
      travelMode: json['travel_mode']?.toString(),
    );
  }
}

class FollowDetails {
  const FollowDetails({
    required this.alert,
    required this.victimLocation,
    this.victim,
    this.route,
  });

  final EmergencyAlert alert;
  final VictimProfile? victim;
  final PositionSnapshot victimLocation;
  final RouteSummary? route;

  FollowDetails copyWith({
    EmergencyAlert? alert,
    VictimProfile? victim,
    PositionSnapshot? victimLocation,
    RouteSummary? route,
  }) {
    return FollowDetails(
      alert: alert ?? this.alert,
      victim: victim ?? this.victim,
      victimLocation: victimLocation ?? this.victimLocation,
      route: route ?? this.route,
    );
  }

  factory FollowDetails.fromJson(Map<String, dynamic> json) {
    final alertJson = json['alert'];
    final victimJson = json['victim'];
    final victimLocationJson = json['victim_location'];
    final routeJson = json['route'];

    return FollowDetails(
      alert: EmergencyAlert.fromJson(
        alertJson is Map<String, dynamic> ? alertJson : <String, dynamic>{},
      ),
      victim: victimJson is Map<String, dynamic>
          ? VictimProfile.fromJson(victimJson)
          : null,
      victimLocation: PositionSnapshot.fromJson(
        victimLocationJson is Map<String, dynamic>
            ? victimLocationJson
            : <String, dynamic>{},
      ),
      route: routeJson is Map<String, dynamic>
          ? RouteSummary.fromJson(routeJson)
          : null,
    );
  }
}

class LocationPermissionResult {
  const LocationPermissionResult({
    required this.granted,
    this.status = GuardianLocationStatus.notRequested,
    this.message,
    this.snapshot,
  });

  final bool granted;
  final GuardianLocationStatus status;
  final String? message;
  final PositionSnapshot? snapshot;
}
