import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/theme/colors.dart';
import '../../../core/theme/radii.dart';
import '../../../core/theme/spacing.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/placeholders.dart';
import '../../../core/widgets/status_widgets.dart';
import '../models/emergency_models.dart';
import 'guardian_map_view.dart';

class DashboardMapTab extends StatelessWidget {
  const DashboardMapTab({
    super.key,
    required this.mapsLoaderFuture,
    required this.position,
    required this.nearbyAlerts,
    required this.isLoadingAlerts,
    required this.onRefreshAlerts,
    required this.onShowLegend,
    required this.onOpenFollow,
    required this.onEnableLocationSharing,
  });

  final Future<void> mapsLoaderFuture;
  final PositionSnapshot? position;
  final List<EmergencyAlert> nearbyAlerts;
  final bool isLoadingAlerts;
  final Future<void> Function() onRefreshAlerts;
  final VoidCallback onShowLegend;
  final void Function(EmergencyAlert alert) onOpenFollow;
  final VoidCallback onEnableLocationSharing;

  @override
  Widget build(BuildContext context) {
    final currentPosition = position;
    if (currentPosition == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: EmptyState(
          title: 'Map unavailable',
          message:
              'Turn on location sharing to load nearby alerts, your current position, and route context.',
          icon: Icons.map_outlined,
          actionLabel: 'Enable location sharing',
          onAction: onEnableLocationSharing,
        ),
      );
    }

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('current-user'),
        position: currentPosition.latLng,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: const InfoWindow(title: 'You'),
      ),
      ...nearbyAlerts.map(
        (alert) => Marker(
          markerId: MarkerId('alert-${alert.id}'),
          position: alert.latLng,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          onTap: () => onOpenFollow(alert),
        ),
      ),
    };

    final focusPoints = <LatLng>[
      currentPosition.latLng,
      ...nearbyAlerts.map((alert) => alert.latLng),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: FutureBuilder<void>(
        future: mapsLoaderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return ErrorState(
              title: 'Map could not load',
              message: snapshot.error.toString(),
              onRetry: onRefreshAlerts,
            );
          }

          return Stack(
            children: [
              Positioned.fill(
                child: GuardianMapView(
                  markers: markers,
                  focusPoints: focusPoints,
                  initialCenter: currentPosition.latLng,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          StatusBadge(
                            label: nearbyAlerts.isEmpty
                                ? 'No live nearby alerts'
                                : '${nearbyAlerts.length} live alerts',
                            tone: nearbyAlerts.isEmpty
                                ? StatusTone.info
                                : StatusTone.error,
                          ),
                          const Spacer(),
                          IconButton.filledTonal(
                            onPressed: onShowLegend,
                            icon: const Icon(Icons.legend_toggle_rounded),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          IconButton.filledTonal(
                            onPressed: isLoadingAlerts ? null : onRefreshAlerts,
                            icon: const Icon(Icons.refresh_rounded),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.cleanWhite.withValues(alpha: 0.96),
                          borderRadius: AppRadii.card,
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              nearbyAlerts.isEmpty
                                  ? 'Your live map is ready'
                                  : nearbyAlerts.first.displayAddress,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              nearbyAlerts.isEmpty
                                  ? currentPosition.displayAddress
                                  : 'Active alert nearby. Open follow mode for route guidance.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlineActionButton(
                                    text: 'Refresh nearby',
                                    icon: Icons.refresh_rounded,
                                    onPressed: isLoadingAlerts
                                        ? null
                                        : onRefreshAlerts,
                                  ),
                                ),
                                if (nearbyAlerts.isNotEmpty) ...[
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: CommunityActionButton(
                                      onPressed: () =>
                                          onOpenFollow(nearbyAlerts.first),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
