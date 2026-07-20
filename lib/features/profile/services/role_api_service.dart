import '../../../core/services/api_client.dart';
import '../models/profile_models.dart';

class RoleApiService {
  /// Citizens and community helpers switch immediately. Sensitive
  /// responder roles are stored as a pending request until an
  /// administrator approves them -- selecting one here never grants
  /// elevated access by itself.
  static Future<UserProfile> requestRole({
    required String requestedRole,
    List<String>? assistanceCapabilities,
    int? serviceRadiusMeters,
    String? organisation,
    String? verificationNotes,
  }) async {
    final response = await ApiClient.request(
      'POST',
      '/api/roles/request',
      body: {
        'requested_role': requestedRole,
        if (assistanceCapabilities != null && assistanceCapabilities.isNotEmpty)
          'assistance_capabilities': assistanceCapabilities,
        'service_radius_meters': ?serviceRadiusMeters,
        'organisation': ?organisation,
        'verification_notes': ?verificationNotes,
      },
    );
    final data = Map<String, dynamic>.from(
      response['data'] as Map? ?? const {},
    );

    return UserProfile.fromJson(
      Map<String, dynamic>.from(data['profile'] as Map? ?? const {}),
    );
  }

  static Future<UserProfile> updateAvailability({
    required String availabilityStatus,
  }) async {
    final response = await ApiClient.request(
      'POST',
      '/api/roles/availability',
      body: {'availability_status': availabilityStatus},
    );
    final data = Map<String, dynamic>.from(
      response['data'] as Map? ?? const {},
    );

    return UserProfile.fromJson(
      Map<String, dynamic>.from(data['profile'] as Map? ?? const {}),
    );
  }
}
