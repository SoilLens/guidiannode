import 'package:flutter/material.dart';

import '../theme/colors.dart';
import '../theme/radii.dart';
import '../theme/spacing.dart';

enum StatusTone { success, warning, error, info, action }

class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.message,
    required this.tone,
    this.icon,
    this.title,
  });

  final String message;
  final StatusTone tone;
  final IconData? icon;
  final String? title;

  factory StatusBanner.success({required String message, String? title}) =>
      StatusBanner(message: message, title: title, tone: StatusTone.success);

  factory StatusBanner.warning({required String message, String? title}) =>
      StatusBanner(message: message, title: title, tone: StatusTone.warning);

  factory StatusBanner.error({required String message, String? title}) =>
      StatusBanner(message: message, title: title, tone: StatusTone.error);

  factory StatusBanner.info({required String message, String? title}) =>
      StatusBanner(message: message, title: title, tone: StatusTone.info);

  factory StatusBanner.action({required String message, String? title}) =>
      StatusBanner(message: message, title: title, tone: StatusTone.action);

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForTone(tone);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: AppRadii.card,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? palette.icon, color: palette.foreground, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
                    child: Text(
                      title!,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: palette.foreground,
                      ),
                    ),
                  ),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: palette.foreground,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SuccessBanner extends StatelessWidget {
  const SuccessBanner({super.key, required this.message, this.title});

  final String message;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return StatusBanner.success(message: message, title: title);
  }
}

class WarningBanner extends StatelessWidget {
  const WarningBanner({super.key, required this.message, this.title});

  final String message;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return StatusBanner.warning(message: message, title: title);
  }
}

class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message, this.title});

  final String message;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return StatusBanner.error(message: message, title: title);
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.message, this.title});

  final String message;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return StatusBanner.info(message: message, title: title);
  }
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.tone,
    this.icon,
  });

  final String label;
  final StatusTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = _paletteForTone(tone);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: AppRadii.pill,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon ?? palette.icon, size: 14, color: palette.foreground),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: palette.foreground,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class StatusSnackbar {
  const StatusSnackbar._();

  static void show(
    BuildContext context, {
    required String message,
    StatusTone tone = StatusTone.success,
  }) {
    final palette = _paletteForTone(tone);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: palette.foreground,
        content: Row(
          children: [
            Icon(palette.icon, color: AppColors.cleanWhite, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.cleanWhite,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPalette {
  const _StatusPalette({
    required this.background,
    required this.foreground,
    required this.border,
    required this.icon,
  });

  final Color background;
  final Color foreground;
  final Color border;
  final IconData icon;
}

_StatusPalette _paletteForTone(StatusTone tone) {
  return switch (tone) {
    StatusTone.success => const _StatusPalette(
      background: AppColors.safetyGreenSurface,
      foreground: AppColors.safetyGreen,
      border: AppColors.safetyGreen,
      icon: Icons.check_circle_outline_rounded,
    ),
    StatusTone.warning => const _StatusPalette(
      background: AppColors.communityYellowSurface,
      foreground: AppColors.textPrimary,
      border: AppColors.communityYellow,
      icon: Icons.warning_amber_rounded,
    ),
    StatusTone.error => const _StatusPalette(
      background: AppColors.errorSurface,
      foreground: AppColors.error,
      border: AppColors.error,
      icon: Icons.error_outline_rounded,
    ),
    StatusTone.info => const _StatusPalette(
      background: AppColors.trustBlueSurface,
      foreground: AppColors.trustBlueDark,
      border: AppColors.trustBlue,
      icon: Icons.info_outline_rounded,
    ),
    StatusTone.action => const _StatusPalette(
      background: AppColors.engagementOrangeSurface,
      foreground: AppColors.engagementOrange,
      border: AppColors.engagementOrange,
      icon: Icons.notifications_active_outlined,
    ),
  };
}
