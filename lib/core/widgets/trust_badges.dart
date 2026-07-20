import 'package:flutter/material.dart';

import '../theme/radii.dart';
import 'incident_taxonomy_ui.dart';

/// A small colour+icon+label pill, the same shape as [StatusBadge] but
/// driven by a raw colour so it can represent the richer urgency/
/// verification palettes without forcing them into the five generic
/// [StatusTone] buckets. Colour is never the only signal -- label and icon
/// always ship together.
class _TintedPill extends StatelessWidget {
  const _TintedPill({required this.label, required this.icon, required this.color});

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadii.pill,
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VerificationBadge extends StatelessWidget {
  const VerificationBadge({super.key, required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    return _TintedPill(
      label: VerificationUi.label(status),
      icon: VerificationUi.icon(status),
      color: VerificationUi.color(status),
    );
  }
}

class UrgencyBadge extends StatelessWidget {
  const UrgencyBadge({super.key, required this.urgency});

  final String urgency;

  @override
  Widget build(BuildContext context) {
    return _TintedPill(
      label: UrgencyUi.label(urgency),
      icon: UrgencyUi.icon(urgency),
      color: UrgencyUi.color(urgency),
    );
  }
}

class CategoryBadge extends StatelessWidget {
  const CategoryBadge({super.key, required this.category});

  final String category;

  @override
  Widget build(BuildContext context) {
    return _TintedPill(
      label: IncidentCategoryUi.label(category),
      icon: IncidentCategoryUi.icon(category),
      color: IncidentCategoryUi.color(category),
    );
  }
}

/// The confirm / dispute / false-report row shown on an expanded alert. A
/// user's own prior confirmation (if any) is reflected by disabling the
/// matching button, mirroring the backend's one-confirmation-per-user rule.
class AlertConfirmationActions extends StatelessWidget {
  const AlertConfirmationActions({
    super.key,
    required this.communityConfirmations,
    this.myConfirmationType,
    this.onConfirm,
    this.onDispute,
    this.onFalseReport,
    this.isOwnAlert = false,
  });

  final int communityConfirmations;
  final String? myConfirmationType;
  final VoidCallback? onConfirm;
  final VoidCallback? onDispute;
  final VoidCallback? onFalseReport;
  final bool isOwnAlert;

  @override
  Widget build(BuildContext context) {
    if (isOwnAlert) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(Icons.groups_rounded, size: 15, color: colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            communityConfirmations == 1
                ? '1 person confirmed this'
                : '$communityConfirmations people confirmed this',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _ConfirmationChip(
          label: 'Confirm',
          icon: Icons.check_rounded,
          active: myConfirmationType == 'community_confirm',
          onTap: myConfirmationType == null ? onConfirm : null,
        ),
        const SizedBox(width: 6),
        _ConfirmationChip(
          label: 'Dispute',
          icon: Icons.flag_outlined,
          active: myConfirmationType == 'dispute' || myConfirmationType == 'false_report',
          onTap: myConfirmationType == null ? onDispute : null,
        ),
      ],
    );
  }
}

class _ConfirmationChip extends StatelessWidget {
  const _ConfirmationChip({
    required this.label,
    required this.icon,
    required this.active,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = active ? colors.primary : colors.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: AppRadii.pill,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: active ? colors.primary.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: AppRadii.pill,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
