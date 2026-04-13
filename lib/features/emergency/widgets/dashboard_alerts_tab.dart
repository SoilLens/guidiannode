import 'package:flutter/material.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/cards.dart';
import '../../../core/widgets/placeholders.dart';
import '../../../core/widgets/status_widgets.dart';
import '../models/emergency_models.dart';
import '../utils/formatters.dart';

class DashboardAlertsTab extends StatelessWidget {
  const DashboardAlertsTab({
    super.key,
    required this.nearbyAlerts,
    required this.isLoadingAlerts,
    required this.alertsError,
    required this.onRefresh,
    required this.onOpenAlert,
  });

  final List<EmergencyAlert> nearbyAlerts;
  final bool isLoadingAlerts;
  final String? alertsError;
  final Future<void> Function() onRefresh;
  final void Function(EmergencyAlert alert) onOpenAlert;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: onRefresh,
        child: ListView(
          padding: AppSpacing.screenPadding,
          children: [
            const SectionHeader(
              title: 'Nearby alerts',
              subtitle:
                  'Live incidents around you appear here as the backend and Supabase feed update.',
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Live alerts',
                    value: '${nearbyAlerts.length}',
                    helper: '3 km radius',
                    tone: nearbyAlerts.isEmpty
                        ? StatusTone.info
                        : StatusTone.error,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StatTile(
                    label: 'Feed',
                    value: alertsError == null ? 'Connected' : 'Attention',
                    helper: alertsError == null
                        ? 'Realtime ready'
                        : 'Retry soon',
                    tone: alertsError == null
                        ? StatusTone.success
                        : StatusTone.warning,
                  ),
                ),
              ],
            ),
            if (alertsError != null) ...[
              const SizedBox(height: AppSpacing.md),
              WarningBanner(
                title: 'Nearby alerts issue',
                message: alertsError!,
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            if (isLoadingAlerts)
              const LoadingCardList(count: 3)
            else if (nearbyAlerts.isEmpty)
              EmptyState(
                title: 'No nearby alerts',
                message:
                    'When new SOS activity appears in your radius, it will surface here.',
                actionLabel: 'Refresh now',
                onAction: onRefresh,
              )
            else
              ...nearbyAlerts.map(
                (alert) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: AlertCard(
                    title: formatEmergencyType(alert.emergencyType),
                    subtitle: alert.displayAddress,
                    distance: formatDistance(alert.distanceMeters),
                    time: formatRelativeTime(
                      alert.updatedAt ?? alert.createdAt,
                    ),
                    onTap: () => onOpenAlert(alert),
                    onAction: () => onOpenAlert(alert),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
