import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/elevation.dart';
import '../theme/radii.dart';
import '../theme/spacing.dart';
import 'buttons.dart';
import 'status_widgets.dart';

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  subtitle!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class ActionTile extends StatelessWidget {
  const ActionTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.accentColor = AppColors.trustBlue,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: AppRadii.card,
      child: InkWell(
        borderRadius: AppRadii.card,
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.card,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: AppRadii.card,
                ),
                child: Icon(icon, color: accentColor),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.helper,
    this.icon,
    this.tone = StatusTone.info,
  });

  final String label;
  final String value;
  final String? helper;
  final IconData? icon;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    final palette = switch (tone) {
      StatusTone.success => AppColors.safetyGreenSurface,
      StatusTone.warning => AppColors.communityYellowSurface,
      StatusTone.error => AppColors.errorSurface,
      StatusTone.info => AppColors.trustBlueSurface,
      StatusTone.action => AppColors.engagementOrangeSurface,
    };
    final foreground = switch (tone) {
      StatusTone.success => AppColors.safetyGreen,
      StatusTone.warning => AppColors.textPrimary,
      StatusTone.error => AppColors.error,
      StatusTone.info => AppColors.trustBlueDark,
      StatusTone.action => AppColors.engagementOrange,
    };

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette,
        borderRadius: AppRadii.card,
        border: Border.all(color: foreground.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: foreground),
            const SizedBox(height: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: foreground),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(color: foreground),
          ),
          if (helper != null) ...[
            const SizedBox(height: AppSpacing.xxs),
            Text(helper!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.name,
    required this.phoneNumber,
    required this.neighborhood,
    required this.locationEnabled,
  });

  final String name;
  final String phoneNumber;
  final String neighborhood;
  final bool locationEnabled;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.trustBlueSurface,
                  borderRadius: AppRadii.card,
                ),
                alignment: Alignment.center,
                child: Text(
                  name.isEmpty ? 'G' : name.characters.first.toUpperCase(),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.trustBlueDark,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      phoneNumber,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: locationEnabled ? 'Location On' : 'Location Off',
                tone: locationEnabled ? StatusTone.success : StatusTone.warning,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            neighborhood.isEmpty ? 'Neighborhood not set' : neighborhood,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class EmergencyContactCard extends StatelessWidget {
  const EmergencyContactCard({
    super.key,
    required this.name,
    required this.phoneNumber,
    required this.relationship,
  });

  final String name;
  final String phoneNumber;
  final String relationship;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              color: AppColors.engagementOrangeSurface,
              borderRadius: AppRadii.card,
            ),
            child: const Icon(
              Icons.contact_phone_outlined,
              color: AppColors.engagementOrange,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  phoneNumber,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (relationship.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    relationship,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AlertCard extends StatelessWidget {
  const AlertCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.distance,
    required this.time,
    this.statusLabel = 'Active nearby',
    this.onTap,
    this.actionLabel = 'I Am Coming',
    this.onAction,
    this.tone = StatusTone.error,
  });

  final String title;
  final String subtitle;
  final String distance;
  final String time;
  final String statusLabel;
  final VoidCallback? onTap;
  final String actionLabel;
  final VoidCallback? onAction;
  final StatusTone tone;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadii.card,
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadii.card,
            border: Border.all(color: AppColors.border),
            boxShadow: AppElevation.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  StatusBadge(label: statusLabel, tone: tone),
                  const Spacer(),
                  Text(time, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  const Icon(
                    Icons.near_me_rounded,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(distance, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              if (onAction != null) ...[
                const SizedBox(height: AppSpacing.md),
                CommunityActionButton(onPressed: onAction!, label: actionLabel),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class IncidentCard extends StatelessWidget {
  const IncidentCard({
    super.key,
    required this.title,
    required this.distance,
    required this.time,
    required this.onAction,
    this.severityColor = AppColors.error,
    this.subtitle = 'Emergency reported nearby',
  });

  final String title;
  final String distance;
  final String time;
  final Color severityColor;
  final VoidCallback onAction;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final tone = severityColor == AppColors.safetyGreen
        ? StatusTone.success
        : StatusTone.error;
    return AlertCard(
      title: title,
      subtitle: subtitle,
      distance: distance,
      time: time,
      onAction: onAction,
      tone: tone,
    );
  }
}

class ResponderCard extends StatelessWidget {
  const ResponderCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.metrics,
  });

  final String title;
  final String subtitle;
  final List<StatTile> metrics;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: metrics
                .map((metric) => SizedBox(width: 110, child: metric))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class SafeZoneCard extends StatelessWidget {
  const SafeZoneCard({
    super.key,
    required this.locationName,
    required this.distance,
    this.subtitle = 'Verified assistance point',
    this.onTap,
  });

  final String locationName;
  final String distance;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: ListTile(
        dense: false,
        minVerticalPadding: 0,
        contentPadding: EdgeInsets.zero,
        onTap: onTap,
        leading: Container(
          width: 48,
          height: 48,
          decoration: const BoxDecoration(
            color: AppColors.safetyGreenSurface,
            borderRadius: AppRadii.card,
          ),
          child: const Icon(
            Icons.local_police_outlined,
            color: AppColors.safetyGreen,
          ),
        ),
        title: Text(
          locationName,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Text(
          '$subtitle • $distance',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class LocationCard extends StatelessWidget {
  const LocationCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.location_on_outlined,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: AppColors.trustBlueSurface,
              borderRadius: AppRadii.card,
            ),
            child: Icon(icon, color: AppColors.trustBlueDark),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          // ignore: use_null_aware_elements
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class CommunityUpdateCard extends StatelessWidget {
  const CommunityUpdateCard({super.key, required this.updateText});

  final String updateText;

  @override
  Widget build(BuildContext context) {
    return StatusBanner.info(message: updateText);
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadii.card,
        border: Border.all(color: AppColors.border),
        boxShadow: AppElevation.soft,
      ),
      child: child,
    );
  }
}
