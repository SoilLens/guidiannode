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
  });

  final String id;
  final String fullName;
  final String phoneNumber;
  final String neighborhood;
  final bool locationPermission;
  final double? latitude;
  final double? longitude;
  final EmergencyContactProfile? emergencyContact;

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
