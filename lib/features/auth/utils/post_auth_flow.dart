import 'package:flutter/material.dart';

import '../../../core/services/session_service.dart';
import '../../emergency/screens/dashboard_screen.dart';
import '../../profile/models/profile_models.dart';
import '../screens/profile_completion_screen.dart';

class PostAuthFlow {
  const PostAuthFlow._();

  static void routeAfterVerification(
    BuildContext context, {
    required bool bootstrapLocationSharing,
  }) {
    final user = SessionService.currentUser;
    final profile = user == null ? null : UserProfile.fromJson(user);

    final needsProfileCompletion =
        profile == null ||
        profile.fullName.trim().isEmpty ||
        profile.neighborhood.trim().isEmpty ||
        profile.emergencyContact == null ||
        profile.emergencyContact!.contactName.trim().isEmpty ||
        profile.emergencyContact!.phoneNumber.trim().isEmpty ||
        profile.emergencyContact!.relationship.trim().isEmpty;

    final destination = needsProfileCompletion
        ? ProfileCompletionScreen(
            bootstrapLocationSharing: bootstrapLocationSharing,
          )
        : DashboardScreen(bootstrapLocationSharing: bootstrapLocationSharing);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => destination),
      (route) => false,
    );
  }
}
