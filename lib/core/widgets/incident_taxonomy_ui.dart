import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Presentation mapping shared by alert cards, map markers, and the
/// free-text report review step, so the same category/urgency/verification
/// value always looks the same everywhere in the app.
class IncidentCategoryUi {
  const IncidentCategoryUi._();

  static const Map<String, String> _labels = {
    'security_threat': 'Security threat',
    'medical_emergency': 'Medical emergency',
    'fire': 'Fire',
    'road_accident': 'Road accident',
    'missing_person': 'Missing person',
    'gender_based_violence': 'Sensitive report',
    'natural_disaster': 'Natural disaster',
    'flooding_landslide': 'Flooding / landslide',
    'food_water_request': 'Food or water needed',
    'shelter_request': 'Shelter needed',
    'infrastructure_hazard': 'Infrastructure hazard',
    'public_health_concern': 'Public health concern',
    'other': 'Other emergency',
  };

  static const Map<String, IconData> _icons = {
    'security_threat': Icons.shield_outlined,
    'medical_emergency': Icons.medical_services_outlined,
    'fire': Icons.local_fire_department_outlined,
    'road_accident': Icons.car_crash_outlined,
    'missing_person': Icons.person_search_outlined,
    'gender_based_violence': Icons.privacy_tip_outlined,
    'natural_disaster': Icons.storm_outlined,
    'flooding_landslide': Icons.water_outlined,
    'food_water_request': Icons.restaurant_outlined,
    'shelter_request': Icons.home_outlined,
    'infrastructure_hazard': Icons.warning_amber_outlined,
    'public_health_concern': Icons.coronavirus_outlined,
    'other': Icons.info_outline,
  };

  static const Map<String, Color> _colors = {
    'security_threat': AppColors.error,
    'medical_emergency': AppColors.trustBlue,
    'fire': AppColors.error,
    'road_accident': AppColors.engagementOrange,
    'missing_person': AppColors.engagementOrange,
    'gender_based_violence': AppColors.textSecondary,
    'natural_disaster': AppColors.engagementOrange,
    'flooding_landslide': AppColors.trustBlue,
    'food_water_request': AppColors.safetyGreen,
    'shelter_request': AppColors.safetyGreen,
    'infrastructure_hazard': AppColors.communityYellow,
    'public_health_concern': AppColors.trustBlue,
    'other': AppColors.textTertiary,
  };

  static String label(String category) => _labels[category] ?? 'Other emergency';

  static IconData icon(String category) => _icons[category] ?? Icons.info_outline;

  static Color color(String category) => _colors[category] ?? AppColors.textTertiary;
}

class UrgencyUi {
  const UrgencyUi._();

  static String label(String urgency) => switch (urgency) {
    'critical' => 'Critical',
    'high' => 'High',
    'medium' => 'Medium',
    'low' => 'Low',
    _ => 'Unrated',
  };

  static Color color(String urgency) => switch (urgency) {
    'critical' => AppColors.error,
    'high' => AppColors.engagementOrange,
    'medium' => AppColors.communityYellow,
    'low' => AppColors.textTertiary,
    _ => AppColors.textTertiary,
  };

  static IconData icon(String urgency) => switch (urgency) {
    'critical' => Icons.priority_high_rounded,
    'high' => Icons.arrow_upward_rounded,
    'medium' => Icons.remove_rounded,
    'low' => Icons.arrow_downward_rounded,
    _ => Icons.help_outline_rounded,
  };
}

class VerificationUi {
  const VerificationUi._();

  static String label(String status) => switch (status) {
    'community_confirmed' => 'Community confirmed',
    'responder_confirmed' => 'Responder confirmed',
    'officially_confirmed' => 'Officially confirmed',
    'disputed' => 'Disputed',
    'false_report' => 'False report',
    'resolved' => 'Resolved',
    _ => 'Unverified',
  };

  static Color color(String status) => switch (status) {
    'community_confirmed' => AppColors.trustBlue,
    'responder_confirmed' => AppColors.safetyGreen,
    'officially_confirmed' => AppColors.safetyGreen,
    'disputed' => AppColors.communityYellow,
    'false_report' => AppColors.error,
    'resolved' => AppColors.safetyGreen,
    _ => AppColors.textTertiary,
  };

  static IconData icon(String status) => switch (status) {
    'community_confirmed' => Icons.groups_rounded,
    'responder_confirmed' => Icons.verified_rounded,
    'officially_confirmed' => Icons.verified_rounded,
    'disputed' => Icons.help_rounded,
    'false_report' => Icons.block_rounded,
    'resolved' => Icons.check_circle_rounded,
    _ => Icons.radio_button_unchecked_rounded,
  };

  /// Whether this state should read as clearly, visibly more trustworthy
  /// than a plain unverified report -- used so an official/responder pin
  /// never looks identical to an unconfirmed one.
  static bool isElevated(String status) =>
      status == 'responder_confirmed' ||
      status == 'officially_confirmed' ||
      status == 'community_confirmed';
}
