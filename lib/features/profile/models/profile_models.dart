double? _toDouble(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value.toString());
}

class EmergencyContactProfile {
  const EmergencyContactProfile({
    this.id,
    required this.contactName,
    required this.phoneNumber,
    required this.relationship,
  });

  final String? id;
  final String contactName;
  final String phoneNumber;
  final String relationship;

  factory EmergencyContactProfile.fromJson(Map<String, dynamic> json) {
    return EmergencyContactProfile(
      id: json['id']?.toString(),
      contactName: json['contact_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      relationship: json['relationship']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toUpdatePayload() {
    return {
      'contact_name': contactName,
      'phone_number': phoneNumber,
      'relationship': relationship,
    };
  }

  Map<String, dynamic> toSessionJson() {
    return {
      if (id != null) 'id': id,
      'contact_name': contactName,
      'phone_number': phoneNumber,
      'relationship': relationship,
    };
  }
}

class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.neighborhood,
    required this.locationPermission,
    this.latitude,
    this.longitude,
    this.emergencyContact,
    this.role = 'citizen',
    this.requestedRole,
    this.verificationStatus = 'not_requested',
    this.verificationDate,
    this.assistanceCapabilities = const <String>[],
    this.availabilityStatus = 'offline',
    this.serviceRadiusMeters,
    this.organisation,
    this.verificationNotes,
  });

  final String id;
  final String fullName;
  final String phoneNumber;
  final String neighborhood;
  final bool locationPermission;
  final double? latitude;
  final double? longitude;
  final EmergencyContactProfile? emergencyContact;
  final String role;
  final String? requestedRole;
  final String verificationStatus;
  final DateTime? verificationDate;
  final List<String> assistanceCapabilities;
  final String availabilityStatus;
  final int? serviceRadiusMeters;
  final String? organisation;
  final String? verificationNotes;

  static const List<String> selfAssignableRoles = ['citizen', 'community_helper'];
  static const List<String> requestableSensitiveRoles = [
    'verified_responder',
    'medical_responder',
    'security_responder',
    'humanitarian_responder',
  ];

  bool get isCitizenOrHelper => selfAssignableRoles.contains(role);
  bool get hasApprovedSensitiveRole =>
      requestableSensitiveRoles.contains(role) && verificationStatus == 'approved';
  bool get isModeratorOrAdmin => role == 'moderator' || role == 'administrator';
  bool get canActAsResponder =>
      role == 'community_helper' || hasApprovedSensitiveRole || isModeratorOrAdmin;
  bool get hasPendingRoleRequest => verificationStatus == 'pending';

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final emergencyContactJson = json['emergency_contact'];

    return UserProfile(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString() ?? '',
      neighborhood: json['quarter']?.toString() ?? '',
      locationPermission: json['location_permission'] == true,
      latitude: _toDouble(json['latitude']),
      longitude: _toDouble(json['longitude']),
      emergencyContact: emergencyContactJson is Map
          ? EmergencyContactProfile.fromJson(
              Map<String, dynamic>.from(emergencyContactJson),
            )
          : null,
      role: json['role']?.toString() ?? 'citizen',
      requestedRole: json['requested_role']?.toString(),
      verificationStatus: json['verification_status']?.toString() ?? 'not_requested',
      verificationDate: json['verification_date'] == null
          ? null
          : DateTime.tryParse(json['verification_date'].toString()),
      assistanceCapabilities: List<String>.from(
        (json['assistance_capabilities'] as List? ?? const <dynamic>[]).map(
          (value) => value.toString(),
        ),
      ),
      availabilityStatus: json['availability_status']?.toString() ?? 'offline',
      serviceRadiusMeters: json['service_radius_meters'] == null
          ? null
          : int.tryParse(json['service_radius_meters'].toString()),
      organisation: json['organisation']?.toString(),
      verificationNotes: json['verification_notes']?.toString(),
    );
  }

  Map<String, dynamic> toSessionUserFields() {
    return {
      'full_name': fullName,
      'phone_number': phoneNumber,
      'quarter': neighborhood,
      'location_permission': locationPermission,
      'latitude': latitude,
      'longitude': longitude,
      'emergency_contact': emergencyContact?.toSessionJson(),
    };
  }
}
