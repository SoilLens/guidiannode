import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/placeholders.dart';
import '../../../core/widgets/status_widgets.dart';
import '../models/emergency_models.dart';
import '../utils/formatters.dart';

class DashboardCommunityTab extends StatelessWidget {
  const DashboardCommunityTab({
    super.key,
    required this.nearbyAlerts,
    required this.onOpenAlert,
    required this.onOpenProfile,
    required this.onOpenMap,
  });

  final List<EmergencyAlert> nearbyAlerts;
  final void Function(EmergencyAlert alert) onOpenAlert;
  final VoidCallback onOpenProfile;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context) {
    final primaryAlert = nearbyAlerts.isNotEmpty ? nearbyAlerts.first : null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          const SectionHeader(
            title: 'Community support',
            subtitle:
                'Nearby people, support points, and response guidance come together here.',
          ),
          const SizedBox(height: AppSpacing.md),
          const InfoBanner(
            title: 'How community response works',
            message:
                'GuardianNode nearby users can open active alerts, follow route guidance, and move toward victims with better context.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (primaryAlert != null)
            AlertCard(
              title: formatEmergencyType(primaryAlert.emergencyType),
              subtitle: primaryAlert.displayAddress,
              distance: formatDistance(primaryAlert.distanceMeters),
              time: formatRelativeTime(
                primaryAlert.updatedAt ?? primaryAlert.createdAt,
              ),
              onTap: () => onOpenAlert(primaryAlert),
              onAction: () => onOpenAlert(primaryAlert),
            )
          else
            const EmptyState(
              title: 'No response requests yet',
              message:
                  'Keep location ready and GuardianNode will surface nearby incidents as they happen.',
              icon: Icons.people_outline_rounded,
            ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
            title: 'Support points',
            subtitle:
                'Trusted places that can matter during urgent movement and handoff.',
          ),
          const SizedBox(height: AppSpacing.md),
          const SafeZoneCard(
            locationName: 'Mile 4 Police Station',
            distance: '1.2 km',
          ),
          const SizedBox(height: AppSpacing.sm),
          const SafeZoneCard(
            locationName: 'Regional Hospital Bamenda',
            distance: '2.4 km',
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
            title: 'Quick actions',
            subtitle: 'Keep your profile and routing readiness in shape.',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ActionTile(
                  title: 'Profile',
                  subtitle: 'Emergency contact and neighborhood',
                  icon: Icons.account_circle_outlined,
                  onTap: onOpenProfile,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ActionTile(
                  title: 'Map',
                  subtitle: 'Nearby incidents and your location',
                  icon: Icons.map_outlined,
                  accentColor: AppColors.engagementOrange,
                  onTap: onOpenMap,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
