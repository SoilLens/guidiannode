import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../core/services/session_service.dart';
import '../models/profile_models.dart';

class ProfileApiService {
  static Future<UserProfile> fetchCurrentProfile() async {
    final response = await _request('GET', '/api/profile/me');
    final data = Map<String, dynamic>.from(
      response['data'] as Map? ?? const {},
    );

    return UserProfile.fromJson(
      Map<String, dynamic>.from(data['profile'] as Map? ?? const {}),
    );
  }

  static Future<UserProfile> updateCurrentProfile({
    required String fullName,
    required String neighborhood,
    required EmergencyContactProfile emergencyContact,
  }) async {
    final response = await _request(
      'PUT',
      '/api/profile/me',
      body: {
        'full_name': fullName,
        'quarter': neighborhood,
        'emergency_contact': emergencyContact.toUpdatePayload(),
      },
    );
    final data = Map<String, dynamic>.from(
      response['data'] as Map? ?? const {},
    );

    return UserProfile.fromJson(
      Map<String, dynamic>.from(data['profile'] as Map? ?? const {}),
    );
  }

  static Future<Map<String, dynamic>> _request(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${AppConfig.apiBaseUrl}$path');
    final request = http.Request(method, uri)
      ..headers.addAll(_headers)
      ..body = body == null ? '' : jsonEncode(body);
    final streamedResponse = await request.send();
    final rawResponse = await http.Response.fromStream(streamedResponse);
    final decodedBody = rawResponse.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(rawResponse.body) as Map<String, dynamic>;

    if (rawResponse.statusCode < 200 || rawResponse.statusCode >= 300) {
      throw Exception(
        decodedBody['message']?.toString() ??
            'The GuardianNode profile request failed.',
      );
    }

    return decodedBody;
  }

  static Map<String, String> get _headers {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final token = SessionService.accessToken;

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }
}
