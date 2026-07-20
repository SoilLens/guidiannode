import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../../../core/config/app_config.dart';
import '../../../core/services/api_client.dart';
import '../../../core/services/session_service.dart';
import '../models/emergency_models.dart';

class EmergencyApiService {
  static Future<Map<String, dynamic>> updateUserLocation({
    required bool locationPermission,
    PositionSnapshot? snapshot,
  }) async {
    final response = await _request(
      'POST',
      '/api/location/update',
      body: snapshot == null
          ? {'location_permission': locationPermission}
          : snapshot.toUserLocationPayload(
              locationPermission: locationPermission,
            ),
    );

    return Map<String, dynamic>.from(response['data'] as Map? ?? const {});
  }

  static Future<EmergencyAlert> createSosAlert({
    required String emergencyType,
    required PositionSnapshot snapshot,
    String description = '',
    String? suggestedCategory,
    String? confirmedCategory,
    String? urgencyLevel,
    String? classificationSource,
    double? classificationConfidence,
    String? detectedLanguage,
    String? aiExplanation,
    String? recommendedAction,
    int? peopleAffected,
    List<String>? assistanceNeeded,
    bool immediateDanger = false,
  }) async {
    final response = await _request(
      'POST',
      '/api/alerts/sos',
      body: {
        'emergency_type': emergencyType,
        'description': description,
        ...snapshot.toAlertLocationPayload(),
        'suggested_category': ?suggestedCategory,
        'confirmed_category': ?confirmedCategory,
        'urgency_level': ?urgencyLevel,
        'classification_source': ?classificationSource,
        'classification_confidence': ?classificationConfidence,
        'detected_language': ?detectedLanguage,
        'ai_explanation': ?aiExplanation,
        'recommended_action': ?recommendedAction,
        'people_affected': ?peopleAffected,
        if (assistanceNeeded != null && assistanceNeeded.isNotEmpty)
          'assistance_needed': assistanceNeeded,
        if (immediateDanger) 'immediate_danger': true,
      },
    );

    return EmergencyAlert.fromJson(
      Map<String, dynamic>.from(response['data'] as Map? ?? const {}),
    );
  }

  /// Advisory-only preview: suggests a category/urgency for a free-text
  /// report before the user reviews and submits it. Never blocks
  /// submission if this call fails -- callers should fall back to letting
  /// the user pick a category manually.
  static Future<IncidentClassification> classifyReport({
    required String description,
  }) async {
    final response = await _request(
      'POST',
      '/api/alerts/classify',
      body: {'description': description},
    );
    final data = Map<String, dynamic>.from(
      response['data'] as Map? ?? const {},
    );

    return IncidentClassification.fromJson(
      Map<String, dynamic>.from(data['classification'] as Map? ?? const {}),
    );
  }

  static Future<Map<String, dynamic>> confirmAlert({
    required String alertId,
    required String confirmationType,
    String? note,
  }) async {
    final response = await _request(
      'POST',
      '/api/alerts/$alertId/confirmations',
      body: {
        'confirmation_type': confirmationType,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );

    return Map<String, dynamic>.from(response['data'] as Map? ?? const {});
  }

  static Future<PositionSnapshot> updateAlertLocation({
    required String alertId,
    required PositionSnapshot snapshot,
  }) async {
    final response = await _request(
      'POST',
      '/api/alerts/$alertId/location',
      body: snapshot.toAlertLocationPayload(),
    );

    return PositionSnapshot.fromJson(
      Map<String, dynamic>.from(response['data'] as Map? ?? const {}),
    );
  }

  static Future<EmergencyAlert> resolveAlert({required String alertId}) async {
    final response = await _request('POST', '/api/alerts/$alertId/resolve');

    return EmergencyAlert.fromJson(
      Map<String, dynamic>.from(response['data'] as Map? ?? const {}),
    );
  }

  static Future<List<EmergencyAlert>> fetchNearbyAlerts({
    required PositionSnapshot center,
    int radiusMeters = 3000,
  }) async {
    final response = await _request(
      'GET',
      '/api/alerts/nearby',
      query: {
        'lat': center.latitude.toString(),
        'lng': center.longitude.toString(),
        'radius_meters': radiusMeters.toString(),
      },
    );
    final data = Map<String, dynamic>.from(
      response['data'] as Map? ?? const {},
    );
    final alerts = List<Map<String, dynamic>>.from(
      data['alerts'] as List? ?? const <Map<String, dynamic>>[],
    );

    return alerts.map(EmergencyAlert.fromJson).toList();
  }

  static Future<FollowDetails> fetchFollowDetails({
    required String alertId,
    required PositionSnapshot responderLocation,
  }) async {
    final response = await _request(
      'GET',
      '/api/alerts/$alertId/follow',
      query: {
        'origin_lat': responderLocation.latitude.toString(),
        'origin_lng': responderLocation.longitude.toString(),
      },
    );

    return FollowDetails.fromJson(
      Map<String, dynamic>.from(response['data'] as Map? ?? const {}),
    );
  }

  static Future<Map<String, dynamic>> respondToAlert({
    required String alertId,
    String status = 'on_the_way',
    PositionSnapshot? responderLocation,
    String? capability,
    int? etaMinutes,
    String? note,
  }) async {
    final response = await _request(
      'POST',
      '/api/alerts/$alertId/respond',
      body: {
        'status': status,
        if (responderLocation != null) ...{
          'latitude': responderLocation.latitude,
          'longitude': responderLocation.longitude,
          'accuracy': responderLocation.accuracy,
          'heading': responderLocation.heading,
          'speed': responderLocation.speed,
          'source': 'device',
        },
        'capability': ?capability,
        'eta_minutes': ?etaMinutes,
        'note': ?note,
      },
    );

    return Map<String, dynamic>.from(response['data'] as Map? ?? const {});
  }

  /// Uploads a single evidence file (photo, short video, or audio clip) for
  /// an existing alert. Validation (mime type, size) is enforced again on
  /// the backend, which is the only thing that ever talks to Supabase
  /// Storage -- this call never touches Storage credentials directly.
  static Future<Map<String, dynamic>> uploadAlertMedia({
    required String alertId,
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}/api/alerts/$alertId/media');
    final request = http.MultipartRequest('POST', uri);
    final token = SessionService.accessToken;

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: filename,
        contentType: MediaType.parse(mimeType),
      ),
    );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
    );
    final response = await http.Response.fromStream(
      streamedResponse,
    ).timeout(const Duration(seconds: 30));
    final decoded = jsonDecode(response.body.isEmpty ? '{}' : response.body);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message: decoded is Map
            ? (decoded['message']?.toString() ??
                  'Could not upload this file. Please try again.')
            : 'Could not upload this file. Please try again.',
        code: decoded is Map ? decoded['code']?.toString() : null,
        statusCode: response.statusCode,
      );
    }

    final data = decoded is Map
        ? Map<String, dynamic>.from(decoded['data'] as Map? ?? const {})
        : <String, dynamic>{};

    return Map<String, dynamic>.from(data['media'] as Map? ?? const {});
  }

  static Future<List<Map<String, dynamic>>> fetchAlertMedia({
    required String alertId,
  }) async {
    final response = await _request('GET', '/api/alerts/$alertId/media');
    final data = Map<String, dynamic>.from(
      response['data'] as Map? ?? const {},
    );

    return List<Map<String, dynamic>>.from(
      data['media'] as List? ?? const <Map<String, dynamic>>[],
    );
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    return ApiClient.request(method, path, body: body, query: query);
  }
}
